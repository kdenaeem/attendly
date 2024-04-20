import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class AttendanceBase {
  static const _databaseName = "attendanceSheet.db";
  static const _databaseVersion = 1;

  static const table = "face_table";

  static const columnId = "id";
  static const columnName = "name";
  static const columnEmbedding = "marked";
}
