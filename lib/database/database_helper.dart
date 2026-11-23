import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tarefa.dart';

class DatabaseHelper {
  DatabaseHelper._init();

  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tarefas.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tarefas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            concluida INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> insert(Tarefa tarefa) async {
    final db = await database;
    return db.insert('tarefas', tarefa.toMap());
  }

  Future<List<Tarefa>> queryAll() async {
    final db = await database;

    final resultado = await db.query('tarefas', orderBy: 'id DESC');

    return resultado.map(Tarefa.fromMap).toList();
  }

  Future<int> update(Tarefa tarefa) async {
    final db = await database;

    return db.update(
      'tarefas',
      tarefa.toMap(),
      where: 'id = ?',
      whereArgs: [tarefa.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;

    return db.delete('tarefas', where: 'id = ?', whereArgs: [id]);
  }
}
