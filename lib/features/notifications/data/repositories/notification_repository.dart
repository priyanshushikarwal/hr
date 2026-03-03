import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/notification_model.dart';

/// Notification Repository - CRUD via Appwrite
class NotificationRepository {
  final Databases _databases;

  NotificationRepository() : _databases = AppwriteService.instance.databases;

  /// Get notifications for a user
  Future<List<AppNotification>> getNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
    bool? isRead,
  }) async {
    try {
      final queries = <String>[
        Query.equal('userId', userId),
        Query.limit(limit),
        Query.offset(offset),
        Query.orderDesc('createdAt'),
      ];

      if (isRead != null) {
        queries.add(Query.equal('isRead', isRead));
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => AppNotification.fromJson(doc.data, docId: doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch notifications: ${e.message}');
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('isRead', false),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException {
      return 0;
    }
  }

  /// Create a notification
  Future<AppNotification> createNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'title': title,
          'message': message,
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      return AppNotification.fromJson(doc.data, docId: doc.$id);
    } on AppwriteException catch (e) {
      throw Exception('Failed to create notification: ${e.message}');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String documentId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: documentId,
        data: {'isRead': true},
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to mark notification: ${e.message}');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await getNotifications(userId: userId, isRead: false);
      for (final notif in unread) {
        await markAsRead(notif.id);
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to mark all notifications: ${e.message}');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String documentId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: documentId,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to delete notification: ${e.message}');
    }
  }
}
