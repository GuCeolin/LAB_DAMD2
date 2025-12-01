import 'package:uuid/uuid.dart';

enum SyncAction {
  create,
  update,
  delete,
}

class SyncQueueItem {
  final String id;
  final String entityId; // ID of the Task being acted upon
  final SyncAction action;
  final String? data; // JSON string of the Task object for CREATE/UPDATE
  final DateTime timestamp;
  final bool isSynced;

  SyncQueueItem({
    String? id,
    required this.entityId,
    required this.action,
    this.data,
    DateTime? timestamp,
    this.isSynced = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  // Convert a SyncQueueItem into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'action': action.toString().split('.').last, // 'create', 'update', 'delete'
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Convert a Map into a SyncQueueItem.
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      entityId: map['entityId'],
      action: SyncAction.values.firstWhere(
            (e) => e.toString().split('.').last == map['action'],
        orElse: () => SyncAction.create, // Default value, handle errors gracefully
      ),
      data: map['data'],
      timestamp: DateTime.parse(map['timestamp']),
      isSynced: map['isSynced'] == 1,
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? entityId,
    SyncAction? action,
    String? data,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
