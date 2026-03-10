import 'package:equatable/equatable.dart';

/// Offer Letter Model
class OfferLetter extends Equatable {
  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String designation;
  final String department;
  final String employeeType;
  final double grossSalary;
  final double ctc;
  final DateTime joiningDate;
  final String status; // 'draft', 'approved', 'sent', 'accepted', 'rejected'
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? sentAt;
  final String? pdfStorageId;
  final String? localPdfPath;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const OfferLetter({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.designation,
    required this.department,
    required this.employeeType,
    required this.grossSalary,
    required this.ctc,
    required this.joiningDate,
    this.status = 'draft',
    this.approvedBy,
    this.approvedAt,
    this.sentAt,
    this.pdfStorageId,
    this.localPdfPath,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  OfferLetter copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    String? employeeName,
    String? designation,
    String? department,
    String? employeeType,
    double? grossSalary,
    double? ctc,
    DateTime? joiningDate,
    String? status,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? sentAt,
    String? pdfStorageId,
    String? localPdfPath,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return OfferLetter(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      employeeType: employeeType ?? this.employeeType,
      grossSalary: grossSalary ?? this.grossSalary,
      ctc: ctc ?? this.ctc,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      sentAt: sentAt ?? this.sentAt,
      pdfStorageId: pdfStorageId ?? this.pdfStorageId,
      localPdfPath: localPdfPath ?? this.localPdfPath,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'employeeName': employeeName,
      'designation': designation,
      'department': department,
      'employeeType': employeeType,
      'grossSalary': grossSalary,
      'ctc': ctc,
      'joiningDate': joiningDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (approvedBy != null) data['approvedBy'] = approvedBy;
    if (approvedAt != null) data['approvedAt'] = approvedAt!.toIso8601String();
    if (sentAt != null) data['sentAt'] = sentAt!.toIso8601String();
    if (pdfStorageId != null) data['pdfStorageId'] = pdfStorageId;
    if (localPdfPath != null) data['localPdfPath'] = localPdfPath;
    if (remarks != null) data['remarks'] = remarks;
    if (createdBy != null) data['createdBy'] = createdBy;

    return data;
  }

  factory OfferLetter.fromJson(Map<String, dynamic> json) {
    return OfferLetter(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      employeeType: json['employeeType'] as String? ?? '',
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 0,
      ctc: (json['ctc'] as num?)?.toDouble() ?? 0,
      joiningDate: json['joiningDate'] != null
          ? DateTime.parse(json['joiningDate'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'draft',
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : null,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String)
          : null,
      pdfStorageId: json['pdfStorageId'] as String?,
      localPdfPath: json['localPdfPath'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      createdBy: json['createdBy'] as String?,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isApproved => status == 'approved';
  bool get isSent => status == 'sent';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [id, employeeId, status];
}
