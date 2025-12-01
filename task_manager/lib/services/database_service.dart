import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert'; // Import for JSON encoding
import '../models/task.dart';
import '../models/sync_queue_item.dart';

// ... (rest of the class remains the same until create method)

  Future<Task> create(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    // Add to sync queue
    await createSyncItem(
      SyncQueueItem(
        entityId: task.id,
        action: SyncAction.create,
        data: jsonEncode(task.toMap()), // Store task data as JSON string
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
    final rowsAffected = await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    if (rowsAffected > 0) {
      // Add to sync queue
      await createSyncItem(
        SyncQueueItem(
          entityId: task.id,
          action: SyncAction.update,
          data: jsonEncode(task.toMap()), // Store updated task data as JSON string
        ),
      );
    }
    return rowsAffected;
  }

  Future<int> delete(String id) async {
    final db = await database;
    final rowsAffected = await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    if (rowsAffected > 0) {
      // Add to sync queue
      await createSyncItem(
        SyncQueueItem(
          entityId: id,
          action: SyncAction.delete,
          data: null, // No data needed for delete
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
    const orderBy = 'timestamp ASC'; // Process oldest items first
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
}
