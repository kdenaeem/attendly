// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:attendly/main.dart';
import 'package:camera/camera.dart';

import 'package:flutter/material.dart';

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
a