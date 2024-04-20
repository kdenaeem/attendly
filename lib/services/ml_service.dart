import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:attendly/services/db_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../intepreter/Recognition.dart';

class MLService {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;
  static const int WIDTH = 160;
  static const int HEIGHT = 160;

  // initialising our database
  final dbHelper = DatabaseHelper();

  Map<String, Recognition> registered = Map();

  @override
  String get modelName => 'assets/facenet.tflite';

  MLService({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    loadModel().then((_) {
      // Model loaded, now initialize other components
      initDB();
    });
  }

  // passing input to the model
  Future<void> loadModel() async {
    try {
      // an interpreter is used to convert a model into a tflite format
      // load the mobile into the mobile applicaiton
      interpreter =
          await Interpreter.fromAsset(modelName, options: _interpreterOptions);
    } catch (e) {
      print("Cannot create interpreter");
    }
  }

  initDB() async {
    await dbHelper.init();
    loadRegisteredFaces();
  }

  void loadRegisteredFaces() async {
    final allRows = await dbHelper.queryAllRows();
    // debugPrint('query all rows: ');
    for (final row in allRows) {
      //  debugPrint(row.toString());
      print(row[DatabaseHelper.columnName]);
      String name = row[DatabaseHelper.columnName];
      int id = row[DatabaseHelper.columnId];
      // emb is list of double
      // converting String to Double from db
      List<double> embd = row[DatabaseHelper.columnEmbedding]
          .split(',')
          .map((e) => double.parse(e))
          .toList()
          .cast<double>();
      Recognition recognition =
          Recognition(row[DatabaseHelper.columnName], Rect.zero, embd, 0);
      // adding the new face if its not registered already
      // all the registered faces is loaded and we used the registered map to compare
      registered.putIfAbsent(name, () => recognition);
      print("R=${id}");
    }
  }

  void registerFaceInDB(String name, List<double> embedding) async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnEmbedding: embedding.join(",")
    };
    // insert the new row in the db with name and embedding
    final id = await dbHelper.insert(row);
    print('inserted row $row');
  }

  // Cropped Image -> Array
  // for Model usage
  // https://shorturl.at/KMRV7
  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage =
        img.copyResize(inputImage!, width: WIDTH, height: HEIGHT);
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    int channels = 3;
    int height = HEIGHT;
    int width = WIDTH;
    Float32List reshapedArray = Float32List(1 * height * width * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) /
                  127.5;
        }
      }
    }
    return reshapedArray.reshape([1, 160, 160, 3]);
  }

  Recognition recognise(img.Image image, Rect location) {
    // conver tto float array for input to model
    var input = imageToArray(image);

    // reshape to 2d array for output the model will return
    List output = List.filled(1 * 512, 0).reshape([1, 512]);

    // final runs = DateTime.now().millisecondsSinceEpoch;
    // pass image to the model and store the output into the OUTPUT array
    interpreter.run(input, output);
    // final run = DateTime.now().microsecondsSinceEpoch - runs;
    // time taken for the model
    // print('Time to run $runs ms$output');

    // convert list of 192 to double list
    List<double> outputArray = output.first.cast<double>();

    // pass embedding and compare embedding with registered faces
    // now we have pair of the closest neighbourt
    Pair pair = findNearest(outputArray);
    // outputarray is embedding
    // distance is the distance between embedding and registered faces
    return Recognition(pair.name, location, outputArray, pair.distance);
  }

  findNearest(List<double> embedding) {
    // set the distance to -5 as a max
    // later we store the recognised face in pair and embedding
    Pair pair = Pair('Unknown', -5);
    // iterate through all the registered faces
    for (MapEntry<String, Recognition> item in registered.entries) {
      final String name = item.key;
      List<double> knownEmb = item.value.embedding;
      double distance = 0;
      // subtract the embedding of registered faces
      for (int i = 0; i < embedding.length; i++) {
        double diff = embedding[i] - knownEmb[i];
        // the difference between the embedding and the first registered face
        distance += diff * diff;
      }
      // the actual distance .
      distance = sqrt(distance);
      // compare this with the distance in the pair object
      // if the distance is less than the old distanec
      // update the new distance
      if (pair.distance == -5 || distance < pair.distance) {
        pair.distance = distance;
        pair.name = name;
      }
      // tldr : finds the minimum distance and finds the closest face
    }
    return pair;
  }

  void close() {
    interpreter.close();
  }
}

class Pair {
  String name;
  double distance;
  Pair(this.name, this.distance);
}
