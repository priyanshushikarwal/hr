import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../auth/domain/providers/auth_providers.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AppNotification(
      id: docId ?? json['\$id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class NotificationState {
  final List<AppNotification> items;
  final bool isLoading;
  const NotificationState({this.items = const [], this.isLoading = false});
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  final _db = AppwriteService.instance.databases;

  NotificationNotifier(this._ref) : super(const NotificationState()) {
    load();
  }

  String? get _userId => _ref.read(authProvider).user?.userId;

  Future<void> load() async {
    if (_userId == null) return;
    state = NotificationState(isLoading: true, items: state.items);
    try {
      final docs = await _db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        queries: [
          Query.equal('userId', _userId!),
          Query.orderDesc('createdAt'),
          Query.limit(50),
        ],
      );
      final items = docs.documents
          .map((d) => AppNotification.fromJson(d.data, docId: d.$id))
          .toList();
      state = NotificationState(items: items);
    } catch (_) {
      state = NotificationState(items: state.items);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: id,
        data: {'isRead': true, 'readAt': DateTime.now().toIso8601String()},
      );
      await load();
    } catch (_) {}
  }

  int get unreadCount => state.items.where((n) => !n.isRead).length;
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(ref);
    });
