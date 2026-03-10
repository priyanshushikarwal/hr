import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Account _account = AppwriteService.instance.account;
  final Databases _databases = AppwriteService.instance.databases;

  Future<AppUser> login(String email, String password) async {
    try {
      try {
        await _account.createEmailPasswordSession(
          email: email,
          password: password,
        );
      } on AppwriteException catch (e) {
        if (e.type != 'user_session_already_exists') rethrow;
      }

      final user = await _account.get();
      final appUser = await _getUserDocument(user.$id);

      if (appUser == null) {
        await logout();
        throw Exception('User profile not found. Contact HR.');
      }

      if (!appUser.role.isMobileAllowed) {
        await logout();
        throw Exception('Access denied. This app is for employees only.');
      }

      return appUser;
    } on AppwriteException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AppUser?> getCurrentUser() async {
    try {
      final user = await _account.get();
      return await _getUserDocument(user.$id);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } catch (_) {}
  }

  Future<AppUser?> _getUserDocument(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      if (response.documents.isEmpty) return null;
      final doc = response.documents.first;
      return AppUser.fromJson(doc.data, docId: doc.$id);
    } catch (_) {
      return null;
    }
  }

  Exception _handleError(AppwriteException e) {
    switch (e.code) {
      case 401:
        return Exception('Invalid email or password.');
      case 429:
        return Exception('Too many attempts. Try later.');
      default:
        return Exception(e.message ?? 'An error occurred.');
    }
  }
}
