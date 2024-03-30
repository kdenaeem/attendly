import 'package:flutter/material.dart'; // Import Flutter's Image class
import 'dart:io'; // Import File class if not already imported
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:google_ml_kit/google_ml_kit.dart';

// class FacePainter extends CustomPainter {
//   final ui.Image imagePath;
//   final List<Face> faces;

//   FacePainter(this.imagePath, this.faces);

//   @override
//   Future<void> paint(Canvas canvas, Size size) async {
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..color = Colors.red;

//     final double scaleX = size.width / (imagePath.width?.toDouble() ?? 1);
//     final double scaleY = size.height / (imagePath.height?.toDouble() ?? 1);

//     // Draw the image
//     canvas.drawImage(imagePath, Offset.zero, Paint());

//     // Draw bounding boxes around detected faces
//     for (final face in faces) {
//       final offset = Offset(
//         face.boundingBox.left * scaleX,
//         face.boundingBox.top * scaleY,
//       );
//       final boundingBoxSize = Size(
//         face.boundingBox.width * scaleX,
//         face.boundingBox.height * scaleY,
//       );
//       canvas.drawRect(offset & boundingBoxSize, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(FacePainter oldDelegate) {
//     return imagePath != oldDelegate.imagePath || faces != oldDelegate.faces;
//   }
// }

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.red;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
