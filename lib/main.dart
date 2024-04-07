import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:attendly/ml_service.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imglib;

// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:attendly/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();

  CameraDescription? firstCamera;
  firstCamera = cameras.last;

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: StartAttendanceScreen(camera: firstCamera),
  ));
}

class StartAttendanceScreen extends StatelessWidget {
  final CameraDescription camera;

  const StartAttendanceScreen({Key? key, required this.camera})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Attendance')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TakePictureScreen(camera: camera)),
            );
          },
          child: Text('Start Attendance'),
        ),
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({Key? key, required this.camera}) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;

  late Future<void> _initializeControllerFuture;
  List<Face> _detectedFaces = [];
  ui.Size? _currentImage;
  final MLService _mlService = MLService(); // Initialize MLService

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    bool canProcess = false;
    _initializeControllerFuture = _controller.initialize().then((_) {
      _controller.startImageStream((CameraImage image) {
        if (canProcess) return;
        canProcess = true;
        _processCameraImage(image, widget.camera);
        canProcess = false;
      });
      return null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processCameraImage(
      CameraImage image, CameraDescription camera) async {
    List<Face> faces = await _processFaces(image, camera);
    // Call recognizeFaces function here

    setState(() {
      _currentImage = ui.Size(
        _controller.value.previewSize!.height,
        _controller.value.previewSize!.width,
      );
      if (faces != null) {
        _mlService.recognizeFaces(faces);

        _detectedFaces = faces;
      }
    });
  }

  Future<List<Face>> _processFaces(
      CameraImage image, CameraDescription camera) async {
    InputImage? inputImage = _inputImageFromCameraImage(image, camera);
    final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions());
    return await faceDetector.processImage(inputImage!);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(
      CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;

    var rotationCompensation =
        _orientations[_controller.value.deviceOrientation];

    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }

    rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ??
        InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final inputImageData = InputImageMetadata(
      size: ui.Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );
    final plane = image.planes.first;

    final inputImage = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: inputImageData,
    );

    return inputImage;
  }

  @override
  Widget build(BuildContext context) {
    print(_detectedFaces.isNotEmpty ? _detectedFaces[0] : 'No faces detected');
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
        body: Stack(
      alignment: Alignment.bottomCenter, // Align children to the bottom center
      children: [
        Transform.scale(
          scale: 1.0,
          child: AspectRatio(
            aspectRatio: MediaQuery.of(context).size.aspectRatio,
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.fitHeight,
                child: Container(
                  width: width,
                  height: width * _controller.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CameraPreview(_controller),
                      if (_detectedFaces
                          .isNotEmpty) // Check if _detectedFaces is not empty
                        CustomPaint(
                          painter: FacePainter(
                            face: _detectedFaces[0],
                            imageSize: _currentImage!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.only(bottom: 20.0), // Add some bottom padding
          child: ElevatedButton(
            onPressed: () async {
              try {
                final image = await _controller.takePicture();

                if (!context.mounted) return;

                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        DisplayPictureScreen(imagePath: image.path)));
              } catch (e) {
                print(e);
              }
            },
            child: Text('Capture Image'),
          ),
        ),
      ],
    )

        // appBar: AppBar(title: const Text('Take a picture')),
        // body: FutureBuilder<void>(
        //   future: _initializeControllerFuture,
        //   builder: (context, snapshot) {
        //     if (snapshot.connectionState == ConnectionState.done) {
        //       return Stack(
        //         children: <Widget>[
        //           CameraPreview(_controller),
        //           if (_currentImage != null)
        //             CustomPaint(
        //               painter: FacePainter(
        //                 face: _detectedFaces[0],
        //                 imageSize: _currentImage!,
        //               ),
        //             ),
        //         ],
        //       );
        //     } else {
        //       return const Center(child: CircularProgressIndicator());
        //     }
        //   },
        // ),
        );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  Future<ui.Image> loadImage(String imagePath) async {
    final Uint8List bytes = File(imagePath).readAsBytesSync();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    return image;
  }

  Future<List<Face>> detectFaces(String image) async {
    try {
      final inputImage = InputImage.fromFilePath(image);
      final faceDetector =
          GoogleMlKit.vision.faceDetector(FaceDetectorOptions());
      final faces = await faceDetector.processImage(inputImage);
      return faces;
    } catch (e) {
      print('Error capturing image');
      return [];
    }
  }

  late Future<List<dynamic>> _futureImage;

  @override
  void initState() {
    super.initState();
    _futureImage = Future.wait([
      loadImage(widget.imagePath),
      detectFaces(widget.imagePath),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the picture')),
      body: FutureBuilder(
        future: _futureImage,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // final image = snapshot.data![0] as ui.Image;
            // final faces = snapshot.data![1] as List<Face>;
            return Stack(
              children: [
                Image.file(File(widget.imagePath)),
                // CustomPaint(
                //       painter: FacePainter(
                //         face: faces[0],
                //         imageSize: image,
                //       ),
                //     )

                // CustomPaint(painter: FacePainter(image, faces)),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
