import 'dart:ui';

// data class to store the recognised faces
class Recognition {
  String name;
  // location of the face
  Rect location;
  // embedding for face
  List<double> embedding;
  // store distance between two faces
  double distance;
  Recognition(this.name, this.location, this.embedding, this.distance);
}
