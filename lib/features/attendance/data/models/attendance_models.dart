import 'package:equatable/equatable.dart';

/// Attendance Record Model
class AttendanceRecord extends Equatable {
  final String id;
  final String employeeId;
  final String employeeCode;
  final DateTime date;
  final String
  status; // 'present', 'absent', 'half_day', 'leave', 'holiday', 'weekend'
  final String? leaveType;

  // Time tracking
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double hoursWorked;
  final double overtimeHours;

  // Shift info
  final String? shiftType;
  final DateTime? shiftStartTime;
  final DateTime? shiftEndTime;

  // Remarks
  final String? remarks;

  // Approval
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.date,
    required this.status,
    this.leaveType,
    this.checkIn,
    this.checkOut,
    this.hoursWorked = 0,
    this.overtimeHours = 0,
    this.shiftType,
    this.shiftStartTime,
    this.shiftEndTime,
    this.remarks,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isOnLeave => status == 'leave';
  bool get isHalfDay => status == 'half_day';
  bool get isHoliday => status == 'holiday';
  bool get isWeekend => status == 'weekend';
  bool get hasOvertime => overtimeHours > 0;

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeCode,
    DateTime? date,
    String? status,
    String? leaveType,
    DateTime? checkIn,
    DateTime? checkOut,
    double? hoursWorked,
    double? overtimeHours,
    String? shiftType,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    String? remarks,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      date: date ?? this.date,
      status: status ?? this.status,
      leaveType: leaveType ?? this.leaveType,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      shiftType: shiftType ?? this.shiftType,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      remarks: remarks ?? this.remarks,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
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
      'date': date.toIso8601String(),
      'status': status,
      'leaveType': leaveType,
      'checkIn': checkIn?.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'hoursWorked': hoursWorked,
      'overtimeHours': overtimeHours,
      'shiftType': shiftType,
      'shiftStartTime': shiftStartTime?.toIso8601String(),
      'shiftEndTime': shiftEndTime?.toIso8601String(),
      'remarks': remarks,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      employeeCode: json['employeeCode'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      leaveType: json['leaveType'] as String?,
      checkIn: json['checkIn'] != null
          ? DateTime.parse(json['checkIn'] as String)
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String)
          : null,
      hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
      overtimeHours: (json['overtimeHours'] as num?)?.toDouble() ?? 0,
      shiftType: json['shiftType'] as String?,
      shiftStartTime: json['shiftStartTime'] != null
          ? DateTime.parse(json['shiftStartTime'] as String)
          : null,
      shiftEndTime: json['shiftEndTime'] != null
          ? DateTime.parse(json['shiftEndTime'] as String)
          : null,
      remarks: json['remarks'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeCode,
    date,
    status,
    leaveType,
    checkIn,
    checkOut,
    hoursWorked,
    overtimeHours,
    shiftType,
    shiftStartTime,
    shiftEndTime,
    remarks,
    isApproved,
    approvedBy,
    approvedAt,
    createdAt,
    updatedAt,
    createdBy,
  ];
}

/// Monthly Attendance Summary
class AttendanceSummary extends Equatable {
  final String employeeId;
  final String employeeCode;
  final int month;
  final int year;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final int leaveDays;
  final int holidays;
  final int weekends;
  final double totalHoursWorked;
  final double totalOvertimeHours;
  final Map<String, int> leaveBreakdown;

  const AttendanceSummary({
    required this.employeeId,
    required this.employeeCode,
    required this.month,
    required this.year,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    this.halfDays = 0,
    this.leaveDays = 0,
    this.holidays = 0,
    this.weekends = 0,
    this.totalHoursWorked = 0,
    this.totalOvertimeHours = 0,
    this.leaveBreakdown = const {},
  });

  double get attendancePercentage {
    final workingDays = totalDays - holidays - weekends;
    if (workingDays == 0) return 0;
    return ((presentDays + (halfDays * 0.5)) / workingDays) * 100;
  }

  int get workingDays => totalDays - holidays - weekends;

  double get effectivePresentDays => presentDays + (halfDays * 0.5);

  @override
  List<Object?> get props => [
    employeeId,
    employeeCode,
    month,
    year,
    totalDays,
    presentDays,
    absentDays,
    halfDays,
    leaveDays,
    holidays,
    weekends,
    totalHoursWorked,
    totalOvertimeHours,
    leaveBreakdown,
  ];
}
