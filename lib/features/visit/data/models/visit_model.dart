import 'package:equatable/equatable.dart';

/// Visit Status
enum VisitStatus {
  pending,
  approved,
  rejected;

  String get value {
    switch (this) {
      case VisitStatus.pending:
        return 'pending';
      case VisitStatus.approved:
        return 'approved';
      case VisitStatus.rejected:
        return 'rejected';
    }
  }

  static VisitStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return VisitStatus.approved;
      case 'rejected':
        return VisitStatus.rejected;
      default:
        return VisitStatus.pending;
    }
  }
}

/// Visit Record Model
class VisitRecord extends Equatable {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;

  // Visit details
  final String purpose;
  final String? clientName;
  final String? visitAddress;
  final DateTime visitDate;

  // Selfie & Location verification
  final String? selfieFileId;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;
  final DateTime? selfieTimestamp;

  // Status & Approval
  final VisitStatus status;
  final String? remarks;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const VisitRecord({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.purpose,
    this.clientName,
    this.visitAddress,
    required this.visitDate,
    this.selfieFileId,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.selfieTimestamp,
    this.status = VisitStatus.pending,
    this.remarks,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == VisitStatus.pending;
  bool get isApproved => status == VisitStatus.approved;
  bool get isRejected => status == VisitStatus.rejected;
  bool get hasSelfie => selfieFileId != null && selfieFileId!.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  VisitRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeCode,
    String? purpose,
    String? clientName,
    String? visitAddress,
    DateTime? visitDate,
    String? selfieFileId,
    double? latitude,
    double? longitude,
    String? locationAddress,
    DateTime? selfieTimestamp,
    VisitStatus? status,
    String? remarks,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeCode: employeeCode ?? this.employeeCode,
      purpose: purpose ?? this.purpose,
      clientName: clientName ?? this.clientName,
      visitAddress: visitAddress ?? this.visitAddress,
      visitDate: visitDate ?? this.visitDate,
      selfieFileId: selfieFileId ?? this.selfieFileId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      selfieTimestamp: selfieTimestamp ?? this.selfieTimestamp,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'employeeId': employeeId,
      'purpose': purpose,
      'visitDate': visitDate.toIso8601String(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (employeeName != null) data['employeeName'] = employeeName;
    if (employeeCode != null) data['employeeCode'] = employeeCode;
    if (clientName != null) data['clientName'] = clientName;
    if (visitAddress != null) data['visitAddress'] = visitAddress;
    if (selfieFileId != null) data['selfieFileId'] = selfieFileId;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (locationAddress != null) data['locationAddress'] = locationAddress;
    if (selfieTimestamp != null) {
      data['selfieTimestamp'] = selfieTimestamp!.toIso8601String();
    }
    if (remarks != null) data['remarks'] = remarks;
    if (approvedBy != null) data['approvedBy'] = approvedBy;
    if (approvedAt != null) {
      data['approvedAt'] = approvedAt!.toIso8601String();
    }
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;

    return data;
  }

  factory VisitRecord.fromJson(Map<String, dynamic> json) {
    return VisitRecord(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      purpose: json['purpose'] as String? ?? '',
      clientName: json['clientName'] as String?,
      visitAddress: json['visitAddress'] as String?,
      visitDate: DateTime.parse(json['visitDate'] as String),
      selfieFileId: json['selfieFileId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAddress: json['locationAddress'] as String?,
      selfieTimestamp: json['selfieTimestamp'] != null
          ? DateTime.parse(json['selfieTimestamp'] as String)
          : null,
      status: VisitStatus.fromString(json['status'] as String? ?? 'pending'),
      remarks: json['remarks'] as String?,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        employeeName,
        employeeCode,
        purpose,
        clientName,
        visitAddress,
        visitDate,
        selfieFileId,
        latitude,
        longitude,
        locationAddress,
        selfieTimestamp,
        status,
        remarks,
        approvedBy,
        approvedAt,
        rejectionReason,
        createdAt,
        updatedAt,
      ];
}
