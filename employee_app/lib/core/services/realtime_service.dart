import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_config.dart';
import 'appwrite_service.dart';

/// Realtime event types
enum RealtimeEventType { create, update, delete }

/// Parsed realtime event
class RealtimeEvent {
  final RealtimeEventType type;
  final String collectionId;
  final Map<String, dynamic> data;
  final String documentId;

  const RealtimeEvent({
    required this.type,
    required this.collectionId,
    required this.data,
    required this.documentId,
  });
}

/// Callback type for realtime events
typedef RealtimeEventCallback = void Function(RealtimeEvent event);

/// Realtime Service - Subscribe to Appwrite collection changes
class RealtimeService {
  RealtimeService._internal();

  static final RealtimeService _instance = RealtimeService._internal();
  static RealtimeService get instance => _instance;

  Realtime get _realtime => AppwriteService.instance.realtime;

  RealtimeSubscription? _attendanceSubscription;
  RealtimeSubscription? _notificationSubscription;
  RealtimeSubscription? _leaveSubscription;

  final _attendanceController = StreamController<RealtimeEvent>.broadcast();
  final _notificationController = StreamController<RealtimeEvent>.broadcast();
  final _leaveController = StreamController<RealtimeEvent>.broadcast();

  /// Stream of attendance realtime events
  Stream<RealtimeEvent> get attendanceStream => _attendanceController.stream;

  /// Stream of notification realtime events
  Stream<RealtimeEvent> get notificationStream =>
      _notificationController.stream;

  /// Stream of leave request realtime events
  Stream<RealtimeEvent> get leaveStream => _leaveController.stream;

  /// Subscribe to all relevant collections
  void subscribeAll() {
    subscribeToAttendance();
    subscribeToNotifications();
    subscribeToLeaveRequests();
  }

  /// Subscribe to attendance collection changes
  void subscribeToAttendance() {
    try {
      _attendanceSubscription?.close();
      final channel =
          'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.attendanceCollectionId}.documents';

      _attendanceSubscription = _realtime.subscribe([channel]);
      _attendanceSubscription!.stream.listen(
        (response) {
          final event = _parseEvent(
            response,
            AppwriteConfig.attendanceCollectionId,
          );
          if (event != null) {
            _attendanceController.add(event);
          }
        },
        onError: (error) {
          debugPrint('Attendance realtime error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to attendance: $e');
    }
  }

  /// Subscribe to notifications collection changes
  void subscribeToNotifications() {
    try {
      _notificationSubscription?.close();
      final channel =
          'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.notificationsCollectionId}.documents';

      _notificationSubscription = _realtime.subscribe([channel]);
      _notificationSubscription!.stream.listen(
        (response) {
          final event = _parseEvent(
            response,
            AppwriteConfig.notificationsCollectionId,
          );
          if (event != null) {
            _notificationController.add(event);
          }
        },
        onError: (error) {
          debugPrint('Notification realtime error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to notifications: $e');
    }
  }

  /// Subscribe to leave requests collection changes
  void subscribeToLeaveRequests() {
    try {
      _leaveSubscription?.close();
      final channel =
          'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.leaveRequestsCollectionId}.documents';

      _leaveSubscription = _realtime.subscribe([channel]);
      _leaveSubscription!.stream.listen(
        (response) {
          final event = _parseEvent(
            response,
            AppwriteConfig.leaveRequestsCollectionId,
          );
          if (event != null) {
            _leaveController.add(event);
          }
        },
        onError: (error) {
          debugPrint('Leave realtime error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to leave requests: $e');
    }
  }

  /// Parse a realtime response into a RealtimeEvent
  RealtimeEvent? _parseEvent(RealtimeMessage response, String collectionId) {
    try {
      RealtimeEventType? type;

      for (final event in response.events) {
        if (event.contains('.create')) {
          type = RealtimeEventType.create;
        } else if (event.contains('.update')) {
          type = RealtimeEventType.update;
        } else if (event.contains('.delete')) {
          type = RealtimeEventType.delete;
        }
      }

      if (type == null) return null;

      return RealtimeEvent(
        type: type,
        collectionId: collectionId,
        data: response.payload,
        documentId: response.payload['\$id'] ?? '',
      );
    } catch (e) {
      debugPrint('Failed to parse realtime event: $e');
      return null;
    }
  }

  /// Unsubscribe from all collections
  void unsubscribeAll() {
    _attendanceSubscription?.close();
    _notificationSubscription?.close();
    _leaveSubscription?.close();
    _attendanceSubscription = null;
    _notificationSubscription = null;
    _leaveSubscription = null;
  }

  /// Dispose all resources
  void dispose() {
    unsubscribeAll();
    _attendanceController.close();
    _notificationController.close();
    _leaveController.close();
  }
}
