import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/sync_queue_item.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL,
        priority TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        entityId TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        timestamp TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN updatedAt TEXT');
      await db.execute('UPDATE tasks SET updatedAt = createdAt');
    }
  }

  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    
    await createSyncItem(
      SyncQueueItem(
        entityId: task.id,
        action: SyncAction.create,
        data: jsonEncode(task.toMap()),
      ),
    );
    return task;
  }

  Future<Task?> read(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Task>> readAll() async {
    final db = await database;
    const orderBy = 'createdAt DESC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> update(Task task) async {
    final db = await database;
    // Ensure updatedAt is refreshed if not already handled by the object
    // But Task object usually has it. 
    // We should make sure the Task object passed here has a new updatedAt?
    // The UI usually handles "copywith" which updates it. 
    // Let's assume task has the correct updatedAt.
    
    final rowsAffected = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    if (rowsAffected > 0) {
      await createSyncItem(
        SyncQueueItem(
          entityId: task.id,
          action: SyncAction.update,
          data: jsonEncode(task.toMap()),
        ),
      );
    }
    return rowsAffected;
  }

  Future<int> delete(String id) async {
    final db = await database;
    final rowsAffected = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);

    if (rowsAffected > 0) {
      await createSyncItem(
        SyncQueueItem(
          entityId: id,
          action: SyncAction.delete,
          data: null,
        ),
      );
    }
    return rowsAffected;
  }

  // SyncQueueItem operations
  Future<SyncQueueItem> createSyncItem(SyncQueueItem item) async {
    final db = await database;
    await db.insert('sync_queue', item.toMap());
    return item;
  }

  Future<List<SyncQueueItem>> readAllSyncItems() async {
    final db = await database;
    const orderBy = 'timestamp ASC';
    final result = await db.query('sync_queue', orderBy: orderBy);
    return result.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  Future<int> updateSyncItem(SyncQueueItem item) async {
    final db = await database;
    return db.update(
      'sync_queue',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteSyncItem(String id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSyncedItems() async {
    final db = await database;
    return await db.delete('sync_queue', where: 'isSynced = ?', whereArgs: [1]);
  }

  // Save a task from the server (bypass sync queue)
  Future<void> saveSyncedTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}