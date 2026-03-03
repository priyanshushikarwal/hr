import 'package:appwrite/appwrite.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../models/leave_request_model.dart';

/// Leave Repository - CRUD via Appwrite
class LeaveRepository {
  final Databases _databases;

  LeaveRepository() : _databases = AppwriteService.instance.databases;

  /// Get all leave requests (optionally filtered by status)
  Future<List<LeaveRequest>> getLeaveRequests({
    String? status,
    String? employeeId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queries = <String>[
        Query.limit(limit),
        Query.offset(offset),
        Query.orderDesc('createdAt'),
      ];

      if (status != null && status.isNotEmpty) {
        queries.add(Query.equal('status', status));
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        queries.add(Query.equal('employeeId', employeeId));
      }

      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        queries: queries,
      );

      return response.documents
          .map((doc) => LeaveRequest.fromJson(doc.data, docId: doc.$id))
          .toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch leave requests: ${e.message}');
    }
  }

  /// Get pending leave requests count
  Future<int> getPendingCount() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        queries: [Query.equal('status', 'pending'), Query.limit(1)],
      );
      return response.total;
    } on AppwriteException {
      return 0;
    }
  }

  /// Create leave request (employee action)
  Future<LeaveRequest> createLeaveRequest({
    required String employeeId,
    String? employeeName,
    String? employeeCode,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    try {
      // Check for overlapping leave requests
      final existing = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        queries: [
          Query.equal('employeeId', employeeId),
          Query.notEqual('status', 'rejected'),
          Query.lessThanEqual('fromDate', toDate.toIso8601String()),
          Query.greaterThanEqual('toDate', fromDate.toIso8601String()),
          Query.limit(1),
        ],
      );

      if (existing.documents.isNotEmpty) {
        throw Exception('Leave request overlaps with an existing request.');
      }

      final data = {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeCode': employeeCode,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'reason': reason,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        documentId: ID.unique(),
        data: data,
      );

      return LeaveRequest.fromJson(doc.data, docId: doc.$id);
    } on AppwriteException catch (e) {
      throw Exception('Failed to create leave request: ${e.message}');
    }
  }

  /// Approve leave request (HR action)
  Future<LeaveRequest> approveLeave({
    required String documentId,
    required String approvedBy,
  }) async {
    try {
      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        documentId: documentId,
        data: {'status': 'approved', 'approvedBy': approvedBy},
      );
      return LeaveRequest.fromJson(doc.data, docId: doc.$id);
    } on AppwriteException catch (e) {
      throw Exception('Failed to approve leave: ${e.message}');
    }
  }

  /// Reject leave request (HR action)
  Future<LeaveRequest> rejectLeave({
    required String documentId,
    required String rejectedBy,
    String? reason,
  }) async {
    try {
      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        documentId: documentId,
        data: {
          'status': 'rejected',
          'approvedBy': rejectedBy,
          'rejectionReason': reason,
        },
      );
      return LeaveRequest.fromJson(doc.data, docId: doc.$id);
    } on AppwriteException catch (e) {
      throw Exception('Failed to reject leave: ${e.message}');
    }
  }
}
