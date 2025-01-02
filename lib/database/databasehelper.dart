import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseHelper {
  static const _databaseName = 'card_items.db';
  static const _databaseVersion = 1;

  static const table = 'card_items1';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDescription = 'description';
  static const columnDate = 'date';
  static const columnIsUntilDate = 'isUntilDate';
  static const columnIsDeleted = 'isDeleted';
  static const columnIsCompleted = 'isCompleted';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDescription TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnIsUntilDate INTEGER NOT NULL,
        $columnIsDeleted INTEGER NOT NULL,
        $columnIsCompleted INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertCardItem(CardItem cardItem) async {
    Database db = await instance.database;
    return await db.insert(table, cardItem.toMap());
  }

  clearTable() async {
    Database db = await instance.database;
    db.execute('''DELETE FROM $table ''');
  }

  Future<List<CardItem>> getCardItems() async {
    Database db = await instance.database;
    var res = await db.query(table);
    List<CardItem> list =
        res.isNotEmpty ? res.map((c) => CardItem.fromMap(c)).toList() : [];
    return list;
  }

  Future<void> deleteCardItem(int id) async {
    final db = await database;
    int rowsAffected = await db
        .rawUpdate('UPDATE $table SET isDeleted = 1 WHERE id = ?', [id]);
  }

  Future<int> updateCardItem(CardItem cardItem) async {
    Database db = await instance.database;
    return await db.update(
      table,
      cardItem.toMap(),
      where: '$columnId = ?',
      whereArgs: [cardItem.id],
    );
  }
}
