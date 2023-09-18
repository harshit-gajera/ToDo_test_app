import 'package:flutter_riverpod_todo_app/data/data.dart';
import 'package:flutter_riverpod_todo_app/utils/utils.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TaskDatasource {
  static final TaskDatasource _instance = TaskDatasource._();

  factory TaskDatasource() => _instance;

  TaskDatasource._() {
    _initDb();
  }

  static Database? _database;

  // CRUD operation counters
  int createCount = 0;
  int readCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppKeys.dbTable} (
        ${TaskKeys.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${TaskKeys.title} TEXT,
        ${TaskKeys.note} TEXT,
        ${TaskKeys.date} TEXT,
        ${TaskKeys.time} TEXT,
        ${TaskKeys.category} TEXT,
        ${TaskKeys.isCompleted} INTEGER
      )
    ''');
  }

  Future<int> addTask(Task task) async {
    final db = await database;
    return db.transaction((txn) async {
      final count = await txn.insert(
        AppKeys.dbTable,
        task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (count > 0) {
        createCount++; // Increment the create count
      }

      return count;
    });
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppKeys.dbTable,
      orderBy: "id DESC",
    );

    // Increment the read count
    readCount++;

    return List.generate(
      maps.length,
          (index) {
        return Task.fromJson(maps[index]);
      },
    );
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.transaction((txn) async {
      final count = await txn.update(
        AppKeys.dbTable,
        task.toJson(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      if (count > 0) {
        updateCount++; // Increment the update count
      }

      return count;
    });
  }

  Future<int> deleteTask(Task task) async {
    final db = await database;
    return db.transaction(
          (txn) async {
        final count = await txn.delete(
          AppKeys.dbTable,
          where: 'id = ?',
          whereArgs: [task.id],
        );

        if (count > 0) {
          deleteCount++; // Increment the delete count
        }

        return count;
      },
    );
  }
}
