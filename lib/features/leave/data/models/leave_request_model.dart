import 'package:equatable/equatable.dart';

/// Leave Request Status
enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get value {
    switch (this) {
      case LeaveStatus.pending:
        return 'pending';
      case LeaveStatus.approved:
        return 'approved';
      case LeaveStatus.rejected:
        return 'rejected';
    }
  }

  static LeaveStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }
}

/// Leave Request Model
class LeaveRequest extends Equatable {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveStatus status;
  final String? approvedBy;
  final String? rejectionReason;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = LeaveStatus.pending,
    this.approvedBy,
    this.rejectionReason,
    required this.createdAt,
  });

  int get totalDays => toDate.difference(fromDate).inDays + 1;

  bool get isPending => status == LeaveStatus.pending;
  bool get isApproved => status == LeaveStatus.approved;
  bool get isRejected => status == LeaveStatus.rejected;

  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    LeaveStatus? status,
    String? approvedBy,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'employeeCode': employeeCode,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'reason': reason,
      'status': status.value,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json, {String? docId}) {
    return LeaveRequest(
      id: docId ?? json['id'] ?? '',
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      reason: json['reason'] as String,
      status: LeaveStatus.fromString(json['status'] as String? ?? 'pending'),
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    employeeCode,
    fromDate,
    toDate,
    reason,
    status,
    approvedBy,
    rejectionReason,
    createdAt,
  ];
}
