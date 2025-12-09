import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/sync_queue_item.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService.instance;
  bool _isSyncing = false;

  final StreamController<void> _syncCompleteController =
      StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncCompleteController.stream;

  void initialize() {
    ConnectivityService().connectionStatus.listen((status) {
      if (status == ConnectionStatus.online) {
        sync();
      }
    });
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint('Starting Sync...');

    try {
      final serverTasks = await _apiService.getTasks();
      final localTasks = await _dbService.readAll();
      final syncItems = await _dbService.readAllSyncItems();

      final serverTaskMap = {for (var t in serverTasks) t.id: t};
      final localTaskMap = {for (var t in localTasks) t.id: t};

      // 1. Process Queue (Creates and Deletes)
      for (final item in syncItems) {
        try {
          if (item.action == SyncAction.create) {
            if (item.data != null) {
              final task = Task.fromMap(jsonDecode(item.data!));
              if (!serverTaskMap.containsKey(task.id)) {
                await _apiService.createTask(task);
              }
              await _dbService.deleteSyncItem(item.id);
            }
          } else if (item.action == SyncAction.delete) {
            await _apiService.deleteTask(item.entityId);
            await _dbService.deleteSyncItem(item.id);
          }
        } catch (e) {
          debugPrint('Error processing sync item ${item.id}: $e');
        }
      }

      // 2. LWW Resolution
      final allIds = {...serverTaskMap.keys, ...localTaskMap.keys};

      for (final id in allIds) {
        final serverTask = serverTaskMap[id];
        final localTask = localTaskMap[id];

        if (serverTask != null && localTask != null) {
          bool isPendingUpdate = syncItems.any(
            (i) => i.entityId == id && i.action == SyncAction.update,
          );

          if (isPendingUpdate) {
            if (localTask.updatedAt.isAfter(serverTask.updatedAt)) {
              debugPrint('Conflict: Client Wins ($id)');
              await _apiService.updateTask(localTask);
              final itemsToRemove = syncItems.where((i) => i.entityId == id);
              for (var i in itemsToRemove) {
                await _dbService.deleteSyncItem(i.id);
              }
            } else {
              debugPrint('Conflict: Server Wins/Equal ($id)');
              await _dbService.saveSyncedTask(serverTask);
              final itemsToRemove = syncItems.where((i) => i.entityId == id);
              for (var i in itemsToRemove) {
                await _dbService.deleteSyncItem(i.id);
              }
            }
          } else {
            if (serverTask.updatedAt.isAfter(localTask.updatedAt)) {
              await _dbService.saveSyncedTask(serverTask);
            }
          }
        } else if (serverTask != null && localTask == null) {
          bool isPendingDelete = syncItems.any(
            (i) => i.entityId == id && i.action == SyncAction.delete,
          );
          if (!isPendingDelete) {
            await _dbService.saveSyncedTask(serverTask);
          }
        }
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
      _syncCompleteController.add(null);
      debugPrint('Sync finished');
    }
  }
}
