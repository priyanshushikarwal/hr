import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../data/models/employee_model.dart';

final employeeProfileProvider = FutureProvider<Employee?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.user == null) return null;

  final db = AppwriteService.instance.databases;
  try {
    // First attempt to get by employeeId if present
    if (auth.user!.employeeId != null) {
      final doc = await db.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        documentId: auth.user!.employeeId!,
      );
      return Employee.fromJson(doc.data, docId: doc.$id);
    }
    throw AppwriteException('No direct employee ID configured');
  } catch (e) {
    // Attempt 2: Search by User Auth Email
    try {
      final docs = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        queries: [
          Query.equal('email', auth.user!.email),
          Query.limit(1),
        ],
      );
      if (docs.documents.isNotEmpty) {
        return Employee.fromJson(
          docs.documents.first.data,
          docId: docs.documents.first.$id,
        );
      }
    } catch (_) {}

    // Attempt 3: Search by User ID string in the field
    try {
      final docs2 = await db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.employeesCollectionId,
        queries: [
          Query.equal('employeeId', auth.user!.userId),
          Query.limit(1),
        ],
      );
      if (docs2.documents.isNotEmpty) {
        return Employee.fromJson(
          docs2.documents.first.data,
          docId: docs2.documents.first.$id,
        );
      }
    } catch (_) {}
  }
  return null;
});


