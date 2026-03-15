import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/experience_model.dart';

/// Repository for managing Employee Work Experience
class ExperienceRepository {
  final Databases _databases;

  ExperienceRepository() : _databases = AppwriteService.instance.databases;

  /// Fetch all experience records for a specific employee
  Future<List<WorkExperience>> getEmployeeExperience(String employeeId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.experienceCollectionId,
        queries: [
          Query.equal('employeeId', employeeId),
          Query.orderDesc('startDate'),
        ],
      );
      
      return response.documents
          .map((doc) => WorkExperience.fromJson({
                ...doc.data,
                'id': doc.$id,
              }))
          .toList();
    } catch (e) {
      print('Error fetching experience: $e');
      rethrow;
    }
  }

  /// Get total count of 'present' attendance records for an employee
  Future<int> getTotalPresentDays(String employeeId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.attendanceCollectionId,
        queries: [
          Query.equal('employeeId', employeeId),
          Query.equal('status', 'present'),
          Query.limit(1), // We only need the total count from the response
        ],
      );
      return response.total;
    } catch (e) {
      print('Error counting attendance: $e');
      return 0;
    }
  }

  /// Create a new experience record
  Future<WorkExperience> createExperience(WorkExperience experience) async {
    try {
      final data = experience.toJson();
      // Remove id from data as it's passed separately
      data.remove('id');
      
      final response = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.experienceCollectionId,
        documentId: ID.unique(),
        data: data,
      );
      
      return WorkExperience.fromJson({
        ...response.data,
        'id': response.$id,
      });
    } catch (e) {
      print('Error creating experience: $e');
      rethrow;
    }
  }

  /// Update an existing experience record
  Future<WorkExperience> updateExperience(WorkExperience experience) async {
    try {
      final data = experience.toJson();
      data.remove('id');
      
      final response = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.experienceCollectionId,
        documentId: experience.id,
        data: data,
      );
      
      return WorkExperience.fromJson({
        ...response.data,
        'id': response.$id,
      });
    } catch (e) {
      print('Error updating experience: $e');
      rethrow;
    }
  }

  /// Delete an experience record
  Future<void> deleteExperience(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.experienceCollectionId,
        documentId: id,
      );
    } catch (e) {
      print('Error deleting experience: $e');
      rethrow;
    }
  }
}
