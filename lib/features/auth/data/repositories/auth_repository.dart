import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/user_model.dart';

/// Authentication Repository
/// Handles login, logout, session management, and user role verification
class AuthRepository {
  final Account _account;
  final Databases _databases;

  AuthRepository()
    : _account = AppwriteService.instance.account,
      _databases = AppwriteService.instance.databases;

  /// Login with email and password
  Future<AppUser> login(String email, String password) async {
    try {
      // Create email session
      try {
        await _account.createEmailPasswordSession(
          email: email,
          password: password,
        );
      } on AppwriteException catch (e) {
        if (e.type == 'user_session_already_exists') {
          // Session already exists, we can proceed
          print('Session already exists, proceeding to fetch user...');
        } else {
          rethrow;
        }
      }

      // Get current user
      final user = await _account.get();

      // Fetch user document from users collection
      final appUser = await _getUserDocument(user.$id);

      if (appUser == null) {
        // If they authenticated but have no valid user document, we should sign them out
        await logout();
        throw Exception('User profile not found. Contact administrator.');
      }

      return appUser;
    } on AppwriteException catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  /// Get current authenticated user
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return await _getUserDocument(user.$id);
    } on AppwriteException {
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      await _account.get();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Logout - delete current session
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  /// Get Appwrite User model
  Future<models.User> getAccountUser() async {
    return await _account.get();
  }

  /// Fetch user document from users collection by auth userId
  Future<AppUser?> _getUserDocument(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );

      if (response.documents.isEmpty) {
        return null;
      }

      final doc = response.documents.first;
      return AppUser.fromJson(doc.data, docId: doc.$id);
    } on AppwriteException {
      return null;
    }
  }

  /// Validate that the user has an allowed desktop role
  Future<bool> validateDesktopAccess(String userId) async {
    final user = await _getUserDocument(userId);
    if (user == null) return false;
    return user.role.isDesktopAllowed;
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String documentId, String fcmToken) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: documentId,
        data: {'fcmToken': fcmToken},
      );
    } on AppwriteException catch (e) {
      throw _handleAppwriteError(e);
    }
  }

  /// Handle Appwrite errors with user-friendly messages
  Exception _handleAppwriteError(AppwriteException e) {
    print("🔥 APPWRITE RAW ERROR: [${e.code}] ${e.message} ${e.type}");
    switch (e.code) {
      case 401:
        return Exception('Invalid email or password.');
      case 404:
        return Exception('User not found.');
      case 409:
        return Exception('User already exists.');
      case 429:
        return Exception('Too many requests. Please try again later.');
      default:
        return Exception(e.message ?? 'An unexpected error occurred.');
    }
  }
}
