import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:attendly/intepreter/Recognition.dart';
import 'package:attendly/services/ml_service.dart';
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
  late dynamic _controller;
  late List<Recognition> recognitions = [];

  late Future<void> _initializeControllerFuture;
  List<Face> _detectedFaces = [];
  ui.Size? _currentImage;
  bool isBusy = false;

  late MLService _mlService;
  @override
  void initState() {
    super.initState();
    _mlService = MLService();

    initialiseCamera();
  }

  initialiseCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888);
    await _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          caught = image;
          _processCameraImage(image, widget.camera);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CameraImage? caught;
  dynamic _scanResults;

  Future<void> _processCameraImage(
      CameraImage image, CameraDescription camera) async {
    InputImage? inputImage = _inputImageFromCameraImage(image, camera);

    List<Face> faces = await _processFaces(inputImage!, camera);

    recogniseFaces(faces, inputImage);

    // setState(() {
    //   _detectedFaces = faces;
    // });
  }

  Future<List<Face>> _processFaces(
      InputImage image, CameraDescription camera) async {
    final faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions());
    return await faceDetector.processImage(image);
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

  imglib.Image decodeYUV420SP(InputImage image) {
    final width = image.metadata!.size.width.toInt();
    final height = image.metadata!.size.height.toInt();

    Uint8List yuv420sp = image.bytes!;
    //int total = width * height;
    //Uint8List rgb = Uint8List(total);
    final outImg =
        imglib.Image(width: width, height: height); // default numChannels is 3

    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0)
          r = 0;
        else if (r > 262143) r = 262143;
        if (g < 0)
          g = 0;
        else if (g > 262143) g = 262143;
        if (b < 0)
          b = 0;
        else if (b > 262143) b = 262143;

        // I don't know how these r, g, b values are defined, I'm just copying what you had bellow and
        // getting their 8-bit values.
        outImg.setPixelRgb(i, j, ((r << 6) & 0xff0000) >> 16,
            ((g >> 2) & 0xff00) >> 8, b & 0xff);

        /*rgb[yp] = 0xff000000 |
            ((r << 6) & 0xff0000) |
            ((g >> 2) & 0xff00) |
            ((b >> 10) & 0xff);*/
      }
    }
    return outImg;
  }

  bool register = false;
  CameraLensDirection camDirec = CameraLensDirection.front;
  recogniseFaces(List<Face> faces, InputImage frame) async {
    recognitions.clear();

    imglib.Image image = decodeYUV420SP(frame);

    image = imglib.copyRotate(image!,
        angle: camDirec == CameraLensDirection.front ? 10 : 10);
    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      //TODO crop face
      imglib.Image croppedFace = imglib.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());

      //TODO pass cropped face to face recognition model
      Recognition recognition = _mlService.recognise(image, faceRect);
      if (recognition.distance > 1.25) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);

      //TODO show face registration dialogue
      if (register) {
        showFaceRegistrationDialogue(croppedFace!, recognition);
        register = false;
      }
    }
    setState(() {
      isBusy = false;
      _scanResults = recognitions;
    });

    // imglib.Image croppedFace = imglib.copyCrop(image!,
    //     x: faceRect.left.toInt(),
    //     y: faceRect.top.toInt(),
    //     width: faceRect.width.toInt(),
    //     height: faceRect.height.toInt());
    // Returns the embedding of the face
    // afterwards store the embedding with the name
  }

  TextEditingController textEditingController = TextEditingController();
  showFaceRegistrationDialogue(
      imglib.Image croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Image.memory(
                Uint8List.fromList(imglib.encodePng(croppedFace)),
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter Name")),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    _mlService.registerFaceInDB(
                        textEditingController.text, recognition.embedding);
                    textEditingController.text = "";
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Face Registered"),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      minimumSize: const ui.Size(200, 40)),
                  child: const Text("Register"))
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget buildResult() {
    if (_scanResults == null ||
        _controller == null ||
        !_controller.value.isInitialized) {
      return const Center(child: Text('Camera is not initialized'));
    }

    final ui.Size imageSize = ui.Size(
      _controller.value.previewSize!.height,
      _controller.value.previewSize!.width,
    );

    CustomPainter painter =
        FaceDetectorPainter(imageSize, _scanResults, camDirec);
    return CustomPaint(
      painter: painter,
    );
  }

  @override
  Widget build(BuildContext context) {
    print(_detectedFaces.isNotEmpty ? _detectedFaces[0] : 'No faces detected');
    List<Widget> stackChildren = [];
    final size = MediaQuery.sizeOf(context);
    if (_controller != null) {
      stackChildren.add(Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: Container(
            child: (_controller.value.isInitialized)
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  )
                : Container(),
          )));

      stackChildren.add(
        Positioned(
            top: 0.0,
            left: 0.0,
            width: size.width,
            height: size.height,
            child: buildResult()),
      );
    }

    stackChildren.add(Positioned(
      top: size.height - 140,
      left: 0,
      width: size.width,
      height: 80,
      child: Card(
        margin: const EdgeInsets.only(left: 20, right: 20),
        color: Colors.blue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.face_retouching_natural,
                      color: Colors.white,
                    ),
                    iconSize: 20,
                    color: Colors.black,
                    onPressed: () {
                      setState(() {
                        register = true;
                      });
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    ));

    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        margin: const EdgeInsets.only(top: 0),
        color: Colors.black,
        child: Stack(
          children: stackChildren,
        ),
      ),
    ));
  }
}
