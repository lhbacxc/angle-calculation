import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/history_entry.dart';

/// 历史记录数据库服务
class HistoryDatabase {
  static final HistoryDatabase instance = HistoryDatabase._init();
  static Database? _database;

  HistoryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('angle_history.db');
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// 创建数据库表
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expression TEXT NOT NULL,
        result TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  /// 添加历史记录
  Future<HistoryEntry> create(HistoryEntry entry) async {
    final db = await instance.database;
    final id = await db.insert('history', entry.toMap());
    return entry.copyWith(id: id);
  }

  /// 查询所有历史记录（按时间倒序）
  Future<List<HistoryEntry>> readAll() async {
    final db = await instance.database;
    final result = await db.query(
      'history',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => HistoryEntry.fromMap(map)).toList();
  }

  /// 删除单条历史记录
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有历史记录
  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('history');
  }

  /// 关闭数据库
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
