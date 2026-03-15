import 'package:equatable/equatable.dart';

/// Salary Structure for Office Employees
class OfficeSalaryStructure extends Equatable {
  final String id;
  final String employeeId;
  final String employeeCode;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  // Basic Components
  final double basicSalary;
  final double hra; // House Rent Allowance
  final double da; // Dearness Allowance
  final double conveyanceAllowance;
  final double medicalAllowance;
  final double specialAllowance;
  final double otherAllowances;

  // Gross Salary
  final double grossSalary;

  // Deductions
  final double pfEmployee; // 12% of basic
  final double pfEmployer; // 12% of basic
  final double esicEmployee; // 0.75% of gross
  final double esicEmployer; // 3.25% of gross
  final double professionalTax;
  final double tds; // Tax Deducted at Source
  final double otherDeductions;

  // Statutory Applicability
  final bool isPfApplicable;
  final bool isEsicApplicable;
  final DateTime? pfActivationDate;
  final DateTime? esicActivationDate;

  // Net Salary
  final double totalDeductions;
  final double netSalary;

  // CTC (Cost to Company)
  final double ctc;

  // Advances & Loans
  final double advanceBalance;
  final double loanBalance;

  // Remarks
  final String? remarks;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? status; // 'active', 'revised', 'inactive'

  const OfficeSalaryStructure({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.basicSalary,
    required this.hra,
    this.da = 0,
    this.conveyanceAllowance = 0,
    this.medicalAllowance = 0,
    this.specialAllowance = 0,
    this.otherAllowances = 0,
    required this.grossSalary,
    this.pfEmployee = 0,
    this.pfEmployer = 0,
    this.esicEmployee = 0,
    this.esicEmployer = 0,
    this.professionalTax = 0,
    this.tds = 0,
    this.otherDeductions = 0,
    this.isPfApplicable = false,
    this.isEsicApplicable = false,
    this.pfActivationDate,
    this.esicActivationDate,
    required this.totalDeductions,
    required this.netSalary,
    required this.ctc,
    this.advanceBalance = 0,
    this.loanBalance = 0,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.status = 'active',
  });

  /// Calculate PF amount (employee contribution - 12% of basic)
  static double calculatePfEmployee(double basic) => basic * 0.12;

  /// Calculate PF amount (employer contribution - 12% of basic)
  static double calculatePfEmployer(double basic) => basic * 0.12;

  /// Calculate ESIC amount (employee contribution - 0.75% of gross)
  static double calculateEsicEmployee(double gross) => gross * 0.0075;

  /// Calculate ESIC amount (employer contribution - 3.25% of gross)
  static double calculateEsicEmployer(double gross) => gross * 0.0325;

  OfficeSalaryStructure copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    double? basicSalary,
    double? hra,
    double? da,
    double? conveyanceAllowance,
    double? medicalAllowance,
    double? specialAllowance,
    double? otherAllowances,
    double? grossSalary,
    double? pfEmployee,
    double? pfEmployer,
    double? esicEmployee,
    double? esicEmployer,
    double? professionalTax,
    double? tds,
    double? otherDeductions,
    bool? isPfApplicable,
    bool? isEsicApplicable,
    DateTime? pfActivationDate,
    DateTime? esicActivationDate,
    double? totalDeductions,
    double? netSalary,
    double? ctc,
    double? advanceBalance,
    double? loanBalance,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? status,
  }) {
    return OfficeSalaryStructure(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      basicSalary: basicSalary ?? this.basicSalary,
      hra: hra ?? this.hra,
      da: da ?? this.da,
      conveyanceAllowance: conveyanceAllowance ?? this.conveyanceAllowance,
      medicalAllowance: medicalAllowance ?? this.medicalAllowance,
      specialAllowance: specialAllowance ?? this.specialAllowance,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      grossSalary: grossSalary ?? this.grossSalary,
      pfEmployee: pfEmployee ?? this.pfEmployee,
      pfEmployer: pfEmployer ?? this.pfEmployer,
      esicEmployee: esicEmployee ?? this.esicEmployee,
      esicEmployer: esicEmployer ?? this.esicEmployer,
      professionalTax: professionalTax ?? this.professionalTax,
      tds: tds ?? this.tds,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      isPfApplicable: isPfApplicable ?? this.isPfApplicable,
      isEsicApplicable: isEsicApplicable ?? this.isEsicApplicable,
      pfActivationDate: pfActivationDate ?? this.pfActivationDate,
      esicActivationDate: esicActivationDate ?? this.esicActivationDate,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netSalary: netSalary ?? this.netSalary,
      ctc: ctc ?? this.ctc,
      advanceBalance: advanceBalance ?? this.advanceBalance,
      loanBalance: loanBalance ?? this.loanBalance,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'basicSalary': basicSalary,
      'hra': hra,
      'da': da,
      'conveyanceAllowance': conveyanceAllowance,
      'medicalAllowance': medicalAllowance,
      'specialAllowance': specialAllowance,
      'otherAllowances': otherAllowances,
      'grossSalary': grossSalary,
      'pfEmployee': pfEmployee,
      'pfEmployer': pfEmployer,
      'esicEmployee': esicEmployee,
      'esicEmployer': esicEmployer,
      'professionalTax': professionalTax,
      'tds': tds,
      'otherDeductions': otherDeductions,
      'isPfApplicable': isPfApplicable,
      'isEsicApplicable': isEsicApplicable,
      'totalDeductions': totalDeductions,
      'netSalary': netSalary,
      'ctc': ctc,
      'advanceBalance': advanceBalance,
      'loanBalance': loanBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (effectiveTo != null)
      data['effectiveTo'] = effectiveTo!.toIso8601String();
    if (pfActivationDate != null)
      data['pfActivationDate'] = pfActivationDate!.toIso8601String();
    if (esicActivationDate != null)
      data['esicActivationDate'] = esicActivationDate!.toIso8601String();
    if (remarks != null) data['remarks'] = remarks;
    if (createdBy != null) data['createdBy'] = createdBy;
    if (status != null) data['status'] = status;

    return data;
  }

  factory OfficeSalaryStructure.fromJson(Map<String, dynamic> json) {
    return OfficeSalaryStructure(
      id: json['id'] as String? ?? json[r'$id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String? ?? DateTime.now().toIso8601String()),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
      basicSalary: (json['basicSalary'] as num).toDouble(),
      hra: (json['hra'] as num).toDouble(),
      da: (json['da'] as num?)?.toDouble() ?? 0,
      conveyanceAllowance:
          (json['conveyanceAllowance'] as num?)?.toDouble() ?? 0,
      medicalAllowance: (json['medicalAllowance'] as num?)?.toDouble() ?? 0,
      specialAllowance: (json['specialAllowance'] as num?)?.toDouble() ?? 0,
      otherAllowances: (json['otherAllowances'] as num?)?.toDouble() ?? 0,
      grossSalary: (json['grossSalary'] as num).toDouble(),
      pfEmployee: (json['pfEmployee'] as num?)?.toDouble() ?? 0,
      pfEmployer: (json['pfEmployer'] as num?)?.toDouble() ?? 0,
      esicEmployee: (json['esicEmployee'] as num?)?.toDouble() ?? 0,
      esicEmployer: (json['esicEmployer'] as num?)?.toDouble() ?? 0,
      professionalTax: (json['professionalTax'] as num?)?.toDouble() ?? 0,
      tds: (json['tds'] as num?)?.toDouble() ?? 0,
      otherDeductions: (json['otherDeductions'] as num?)?.toDouble() ?? 0,
      isPfApplicable: json['isPfApplicable'] as bool? ?? false,
      isEsicApplicable: json['isEsicApplicable'] as bool? ?? false,
      pfActivationDate: json['pfActivationDate'] != null
          ? DateTime.parse(json['pfActivationDate'] as String)
          : null,
      esicActivationDate: json['esicActivationDate'] != null
          ? DateTime.parse(json['esicActivationDate'] as String)
          : null,
      totalDeductions: (json['totalDeductions'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      ctc: (json['ctc'] as num).toDouble(),
      advanceBalance: (json['advanceBalance'] as num?)?.toDouble() ?? 0,
      loanBalance: (json['loanBalance'] as num?)?.toDouble() ?? 0,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String?,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeCode,
    effectiveFrom,
    effectiveTo,
    basicSalary,
    hra,
    da,
    conveyanceAllowance,
    medicalAllowance,
    specialAllowance,
    otherAllowances,
    grossSalary,
    pfEmployee,
    pfEmployer,
    esicEmployee,
    esicEmployer,
    professionalTax,
    tds,
    otherDeductions,
    isPfApplicable,
    isEsicApplicable,
    pfActivationDate,
    esicActivationDate,
    totalDeductions,
    netSalary,
    ctc,
    advanceBalance,
    loanBalance,
    remarks,
    createdAt,
    updatedAt,
    createdBy,
    status,
  ];
}

/// Factory Salary Entry - Daily/Lot-wise entries
class FactorySalaryEntry extends Equatable {
  final String id;
  final String employeeId;
  final String employeeCode;
  final DateTime date;
  final String shiftType; // 'General', 'Morning', 'Night', etc.

  // Work Details
  final double hoursWorked;
  final double overtimeHours;
  final double kva; // KVA/Units/Pieces
  final double rate; // Rate per KVA/piece

  // Calculations
  final double basicAmount; // kva * rate
  final double overtimeAmount;
  final double incentive;
  final double deductions;
  final double totalAmount;

  // Remarks
  final String? remarks;

  // Metadata
  final DateTime createdAt;
  final String? createdBy;
  final String? status; // 'pending', 'approved', 'paid'

  const FactorySalaryEntry({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.date,
    required this.shiftType,
    required this.hoursWorked,
    this.overtimeHours = 0,
    required this.kva,
    required this.rate,
    required this.basicAmount,
    this.overtimeAmount = 0,
    this.incentive = 0,
    this.deductions = 0,
    required this.totalAmount,
    this.remarks,
    required this.createdAt,
    this.createdBy,
    this.status = 'pending',
  });

  FactorySalaryEntry copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    DateTime? date,
    String? shiftType,
    double? hoursWorked,
    double? overtimeHours,
    double? kva,
    double? rate,
    double? basicAmount,
    double? overtimeAmount,
    double? incentive,
    double? deductions,
    double? totalAmount,
    String? remarks,
    DateTime? createdAt,
    String? createdBy,
    String? status,
  }) {
    return FactorySalaryEntry(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      kva: kva ?? this.kva,
      rate: rate ?? this.rate,
      basicAmount: basicAmount ?? this.basicAmount,
      overtimeAmount: overtimeAmount ?? this.overtimeAmount,
      incentive: incentive ?? this.incentive,
      deductions: deductions ?? this.deductions,
      totalAmount: totalAmount ?? this.totalAmount,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'date': date.toIso8601String(),
      'shiftType': shiftType,
      'hoursWorked': hoursWorked,
      'overtimeHours': overtimeHours,
      'kva': kva,
      'rate': rate,
      'basicAmount': basicAmount,
      'overtimeAmount': overtimeAmount,
      'incentive': incentive,
      'deductions': deductions,
      'totalAmount': totalAmount,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'status': status,
    };
  }

  factory FactorySalaryEntry.fromJson(Map<String, dynamic> json) {
    return FactorySalaryEntry(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeCode: json['employeeCode'] as String,
      date: DateTime.parse(json['date'] as String),
      shiftType: json['shiftType'] as String,
      hoursWorked: (json['hoursWorked'] as num).toDouble(),
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      kva: (json['kva'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      basicAmount: (json['basicAmount'] as num).toDouble(),
      overtimeAmount: (json['overtimeAmount'] as num?)?.toDouble() ?? 0,
      incentive: (json['incentive'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeCode,
    date,
    shiftType,
    hoursWorked,
    overtimeHours,
    kva,
    rate,
    basicAmount,
    overtimeAmount,
    incentive,
    deductions,
    totalAmount,
    remarks,
    createdAt,
    createdBy,
    status,
  ];
}

/// Advance Salary Model - Track salary advances given to employees
class AdvanceSalary extends Equatable {
  final String id;
  final String employeeId;
  final String employeeCode;
  final double advanceAmount;
  final String reason; // Reason for advance request
  final String status; // 'pending', 'approved', 'rejected', 'cleared', 'partial'
  
  // Repayment tracking
  final double repaidAmount; // Amount repaid so far
  final double pendingAmount; // Amount still pending (advanceAmount - repaidAmount)
  final int installments; // Number of installments for repayment
  final int installmentsCleared; // Number of cleared installments
  
  // Dates
  final DateTime requestDate;
  final DateTime? approvalDate;
  final DateTime? clearanceDate; // When fully cleared
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Metadata
  final String? remarks;
  final String? approvedBy;
  final String? createdBy;
  final String? updatedBy;

  const AdvanceSalary({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.advanceAmount,
    required this.reason,
    this.status = 'pending',
    this.repaidAmount = 0,
    this.pendingAmount = 0,
    this.installments = 1,
    this.installmentsCleared = 0,
    required this.requestDate,
    this.approvalDate,
    this.clearanceDate,
    required this.createdAt,
    required this.updatedAt,
    this.remarks,
    this.approvedBy,
    this.createdBy,
    this.updatedBy,
  });

  /// Calculate pending amount
  static double calculatePendingAmount(double advance, double repaid) {
    return (advance - repaid).clamp(0.0, double.infinity);
  }

  /// Check if advance is fully cleared
  bool get isCleared => status == 'cleared' || pendingAmount <= 0;

  /// Get repayment percentage
  double get repaymentPercentage {
    if (advanceAmount == 0) return 0;
    return (repaidAmount / advanceAmount * 100).clamp(0.0, 100.0);
  }

  AdvanceSalary copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    double? advanceAmount,
    String? reason,
    String? status,
    double? repaidAmount,
    double? pendingAmount,
    int? installments,
    int? installmentsCleared,
    DateTime? requestDate,
    DateTime? approvalDate,
    DateTime? clearanceDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? remarks,
    String? approvedBy,
    String? createdBy,
    String? updatedBy,
  }) {
    return AdvanceSalary(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      repaidAmount: repaidAmount ?? this.repaidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      installments: installments ?? this.installments,
      installmentsCleared: installmentsCleared ?? this.installmentsCleared,
      requestDate: requestDate ?? this.requestDate,
      approvalDate: approvalDate ?? this.approvalDate,
      clearanceDate: clearanceDate ?? this.clearanceDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      remarks: remarks ?? this.remarks,
      approvedBy: approvedBy ?? this.approvedBy,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeCode': employeeCode,
      'advanceAmount': advanceAmount,
      'reason': reason,
      'status': status,
      'repaidAmount': repaidAmount,
      'pendingAmount': pendingAmount,
      'installments': installments,
      'installmentsCleared': installmentsCleared,
      'requestDate': requestDate.toIso8601String(),
      'approvalDate': approvalDate?.toIso8601String(),
      'clearanceDate': clearanceDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'remarks': remarks,
      'approvedBy': approvedBy,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory AdvanceSalary.fromJson(Map<String, dynamic> json) {
    return AdvanceSalary(
      id: json['id'] as String? ?? json[r'$id'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String? ?? 'Not specified',
      status: json['status'] as String? ?? 'pending',
      repaidAmount: (json['repaidAmount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0,
      installments: json['installments'] as int? ?? 1,
      installmentsCleared: json['installmentsCleared'] as int? ?? 0,
      requestDate: DateTime.parse(json['requestDate'] as String),
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'] as String)
          : null,
      clearanceDate: json['clearanceDate'] != null
          ? DateTime.parse(json['clearanceDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      remarks: json['remarks'] as String?,
      approvedBy: json['approvedBy'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeCode,
    advanceAmount,
    reason,
    status,
    repaidAmount,
    pendingAmount,
    installments,
    installmentsCleared,
    requestDate,
    approvalDate,
    clearanceDate,
    createdAt,
    updatedAt,
    remarks,
    approvedBy,
    createdBy,
    updatedBy,
  ];
}
