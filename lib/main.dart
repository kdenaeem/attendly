import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:attendly/face_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  print(cameras);
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

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                ElevatedButton(
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
                )
              ],
            );

            // return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
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
            final image = snapshot.data![0] as ui.Image;
            final faces = snapshot.data![1] as List<Face>;
            return Stack(
              children: [
                Image.file(File(widget.imagePath)),
                CustomPaint(painter: FacePainter(image, faces)),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
