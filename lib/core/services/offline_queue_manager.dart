import 'dart:convert';
import 'package:hive/hive.dart';
import '../config/hive_config.dart';

/// Manages offline mutations that need to be synced when connectivity is restored
class OfflineQueueManager {
  OfflineQueueManager._();
  static final OfflineQueueManager instance = OfflineQueueManager._();

  Box<Map> get _box => HiveService.offlineQueueBox;

  /// Enqueue an offline operation
  Future<void> enqueue(OfflineOperation operation) async {
    await _box.put(operation.id, operation.toMap());
  }

  /// Get all pending operations in order
  List<OfflineOperation> getPending() {
    final operations = <OfflineOperation>[];
    for (final key in _box.keys) {
      final map = _box.get(key);
      if (map != null) {
        operations.add(
          OfflineOperation.fromMap(Map<String, dynamic>.from(map)),
        );
      }
    }
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  /// Remove a completed operation
  Future<void> remove(String id) async {
    await _box.delete(id);
  }

  /// Clear all operations
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Check if there are pending operations
  bool get hasPending => _box.isNotEmpty;

  int get pendingCount => _box.length;
}

/// Represents a single offline mutation
class OfflineOperation {
  final String id;
  final String collection;
  final String type; // 'create', 'update', 'delete'
  final String? documentId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  int retryCount;

  OfflineOperation({
    required this.id,
    required this.collection,
    required this.type,
    this.documentId,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'type': type,
      'documentId': documentId,
      'data': data != null ? jsonEncode(data) : null,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory OfflineOperation.fromMap(Map<String, dynamic> map) {
    return OfflineOperation(
      id: map['id'] as String,
      collection: map['collection'] as String,
      type: map['type'] as String,
      documentId: map['documentId'] as String?,
      data: map['data'] != null
          ? jsonDecode(map['data'] as String) as Map<String, dynamic>
          : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
    );
  }
}
