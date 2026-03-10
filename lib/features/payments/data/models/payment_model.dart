import 'package:equatable/equatable.dart';

/// Payment Record Model
class PaymentRecord extends Equatable {
  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final int month;
  final int year;
  final double grossSalary;
  final double totalDeductions;
  final double netSalary;
  final String paymentMode; // 'bank_transfer', 'cash', 'cheque', 'upi'
  final String? transactionNumber;
  final DateTime? paymentDate;
  final String status; // 'pending', 'processed', 'paid', 'failed'
  final bool isLocked;
  final String? salarySlipPath;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const PaymentRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netSalary,
    this.paymentMode = 'bank_transfer',
    this.transactionNumber,
    this.paymentDate,
    this.status = 'pending',
    this.isLocked = false,
    this.salarySlipPath,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  PaymentRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    String? employeeName,
    int? month,
    int? year,
    double? grossSalary,
    double? totalDeductions,
    double? netSalary,
    String? paymentMode,
    String? transactionNumber,
    DateTime? paymentDate,
    String? status,
    bool? isLocked,
    String? salarySlipPath,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      month: month ?? this.month,
      year: year ?? this.year,
      grossSalary: grossSalary ?? this.grossSalary,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netSalary: netSalary ?? this.netSalary,
      paymentMode: paymentMode ?? this.paymentMode,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      isLocked: isLocked ?? this.isLocked,
      salarySlipPath: salarySlipPath ?? this.salarySlipPath,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'employeeName': employeeName,
      'month': month,
      'year': year,
      'grossSalary': grossSalary,
      'totalDeductions': totalDeductions,
      'netSalary': netSalary,
      'paymentMode': paymentMode,
      'transactionNumber': transactionNumber,
      'paymentDate': paymentDate?.toIso8601String(),
      'status': status,
      'isLocked': isLocked,
      'salarySlipPath': salarySlipPath,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? DateTime.now().year,
      grossSalary: (json['grossSalary'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] as String? ?? 'bank_transfer',
      transactionNumber: json['transactionNumber'] as String?,
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      isLocked: json['isLocked'] as bool? ?? false,
      salarySlipPath: json['salarySlipPath'] as String?,
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

  @override
  List<Object?> get props => [id, employeeId, month, year, status, netSalary];
}
