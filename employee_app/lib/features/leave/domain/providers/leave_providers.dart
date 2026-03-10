import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import 'dart:async';
import '../../../../core/services/realtime_service.dart';
import '../../../auth/domain/providers/auth_providers.dart';
import '../../../profile/domain/providers/profile_providers.dart';

class LeaveRequest {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final String? rejectionReason;
  final String createdAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json, {String? docId}) {
    return LeaveRequest(
      id: docId ?? json['\$id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'],
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class LeaveState {
  final List<LeaveRequest> requests;
  final bool isLoading;
  final String? error;
  const LeaveState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  final Ref _ref;
  final _db = AppwriteService.instance.databases;
  StreamSubscription? _sub;

  LeaveNotifier(this._ref) : super(const LeaveState()) {
    loadRequests();
    
    // Subscribe to realtime updates for leaves
    RealtimeService.instance.subscribeToLeaveRequests();
    _sub = RealtimeService.instance.leaveStream.listen((event) async {
       // Since leave requests update globally (e.g. HR approves),
       // we should simply reload our cache.
       await loadRequests();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<String?> _resolveEmployeeId() async {
    final profile = await _ref.read(employeeProfileProvider.future);
    return profile?.id ?? _ref.read(authProvider).user?.employeeId;
  }

  Future<void> loadRequests() async {
    final empId = await _resolveEmployeeId();
    if (empId == null) return;
    
    state = LeaveState(isLoading: true, requests: state.requests);
    try {
      final docs = await _db.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.leaveRequestsCollectionId,
        queries: [
          Query.equal('employeeId', empId),
          Query.orderDesc('createdAt'),
          Query.limit(50),
        ],
      );
      final reqs = docs.documents
          .map((d) => LeaveRequest.fromJson(d.data, docId: d.$id))
          .toList();
      state = LeaveState(requests: reqs);
    } catch (e) {
      state = LeaveState(error: e.toString(), requests: state.requests);
    }
  }

  Future<void> submitLeave({
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final empId = await _resolveEmployeeId();
    if (empId == null) throw Exception('Not logged in');
    
    final auth = _ref.read(authProvider);
    final profile = await _ref.read(employeeProfileProvider.future);

    await _db.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.leaveRequestsCollectionId,
      documentId: ID.unique(),
      data: {
        'employeeId': empId,
        'employeeName': profile != null ? '${profile.firstName} ${profile.lastName}' : auth.user?.name ?? '',
        'employeeCode': profile?.employeeCode ?? '',
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
    await loadRequests();
  }
}

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>((ref) {
  return LeaveNotifier(ref);
});
