import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "registeredStudents.db";
  static const _dataBaseVersion = 1;

  static const table = "face_table";

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnEmbedding = 'embedding';

  late Database _db;

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _dataBaseVersion,
      onCreate: _onCreate,
    );
  }

  // Future _onCreate(Database db, int version) async {
  //   await db.execute('''CREATE TABLE $table (
  //       $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
  //       $columnName TEXT NOT NULL,
  //       $columnEmbedding TEXT NOT NULL,
  //     )''');
  // }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnName TEXT NOT NULL,
            $columnEmbedding TEXT NOT NULL
          )
          ''');
  }

  // Helper methods
  // insert the row into the database
  // column name is the key in the map
  // value of the map is the column value
  // return value is then id
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  // All rows
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table);
  }

  // For row count of how database
  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    int id = row[columnId];

    return await _db
        .update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    return await _db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
