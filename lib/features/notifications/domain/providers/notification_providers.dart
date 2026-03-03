import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../../auth/domain/providers/auth_providers.dart';

/// Notification Repository Provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Notification List State
class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notification Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final String? _userId;

  NotificationNotifier(this._repository, this._userId)
    : super(const NotificationState()) {
    if (_userId != null) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getNotifications(userId: _userId);
      final unreadCount = await _repository.getUnreadCount(_userId);
      state = NotificationState(
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;
    try {
      await _repository.markAllAsRead(_userId);
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Notification Provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      return NotificationNotifier(repository, userId);
    });

/// Unread Notification Count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
