import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';

class CompanySettingsRepository {
  final Databases _databases;

  CompanySettingsRepository() : _databases = AppwriteService.instance.databases;

  static const String _collectionId = AppwriteConfig.companySettingsCollectionId;
  static const String officeWifiSsidsKey = 'office_wifi_ssids';

  Future<String> getSetting(String key) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: _collectionId,
      queries: [
        Query.equal('key', key),
        Query.limit(1),
      ],
    );

    if (response.documents.isEmpty) return '';
    return response.documents.first.data['value']?.toString() ?? '';
  }

  Future<void> upsertSetting({
    required String key,
    required String value,
    String? updatedBy,
  }) async {
    final response = await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: _collectionId,
      queries: [
        Query.equal('key', key),
        Query.limit(1),
      ],
    );

    final data = <String, dynamic>{
      'key': key,
      'value': value,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (updatedBy != null && updatedBy.isNotEmpty) {
      data['updatedBy'] = updatedBy;
    }

    if (response.documents.isEmpty) {
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: data,
      );
    } else {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _collectionId,
        documentId: response.documents.first.$id,
        data: data,
      );
    }
  }
}
