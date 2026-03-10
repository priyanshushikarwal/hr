import 'package:equatable/equatable.dart';

/// Employee Model - Core entity for HRMS
class Employee extends Equatable {
  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? alternatePhone;
  final String employeeType; // 'office' or 'factory'
  final String department;
  final String designation;
  final DateTime joiningDate;
  final DateTime? confirmationDate;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? bloodGroup;
  final String? fatherName;
  final String? motherName;
  final String? spouseName;
  final String? emergencyContact;
  final String? emergencyContactName;
  final String status; // 'active', 'inactive', 'on_leave', 'terminated'

  // Address
  final String? currentAddress;
  final String? currentCity;
  final String? currentState;
  final String? currentPincode;
  final String? permanentAddress;
  final String? permanentCity;
  final String? permanentState;
  final String? permanentPincode;

  // Bank Details
  final String? bankName;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? panNumber;

  // Statutory
  final String? aadhaarNumber;
  final String? uan; // Universal Account Number for PF
  final String? esicNumber;
  final bool isPfApplicable;
  final bool isEsicApplicable;

  // Profile
  final String? profileImageUrl;
  final String? reportingManager;
  final String? reportingManagerId;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.alternatePhone,
    required this.employeeType,
    required this.department,
    required this.designation,
    required this.joiningDate,
    this.confirmationDate,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.bloodGroup,
    this.fatherName,
    this.motherName,
    this.spouseName,
    this.emergencyContact,
    this.emergencyContactName,
    required this.status,
    this.currentAddress,
    this.currentCity,
    this.currentState,
    this.currentPincode,
    this.permanentAddress,
    this.permanentCity,
    this.permanentState,
    this.permanentPincode,
    this.bankName,
    this.bankAccountNumber,
    this.ifscCode,
    this.panNumber,
    this.aadhaarNumber,
    this.uan,
    this.esicNumber,
    this.isPfApplicable = false,
    this.isEsicApplicable = false,
    this.profileImageUrl,
    this.reportingManager,
    this.reportingManagerId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  bool get isOffice => employeeType.toLowerCase() == 'office';
  bool get isFactory => employeeType.toLowerCase() == 'factory';
  bool get isActive => status.toLowerCase() == 'active';

  Employee copyWith({
    String? id,
    String? employeeCode,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? alternatePhone,
    String? employeeType,
    String? department,
    String? designation,
    DateTime? joiningDate,
    DateTime? confirmationDate,
    DateTime? dateOfBirth,
    String? gender,
    String? maritalStatus,
    String? bloodGroup,
    String? fatherName,
    String? motherName,
    String? spouseName,
    String? emergencyContact,
    String? emergencyContactName,
    String? status,
    String? currentAddress,
    String? currentCity,
    String? currentState,
    String? currentPincode,
    String? permanentAddress,
    String? permanentCity,
    String? permanentState,
    String? permanentPincode,
    String? bankName,
    String? bankAccountNumber,
    String? ifscCode,
    String? panNumber,
    String? aadhaarNumber,
    String? uan,
    String? esicNumber,
    bool? isPfApplicable,
    bool? isEsicApplicable,
    String? profileImageUrl,
    String? reportingManager,
    String? reportingManagerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      employeeType: employeeType ?? this.employeeType,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      joiningDate: joiningDate ?? this.joiningDate,
      confirmationDate: confirmationDate ?? this.confirmationDate,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      spouseName: spouseName ?? this.spouseName,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      status: status ?? this.status,
      currentAddress: currentAddress ?? this.currentAddress,
      currentCity: currentCity ?? this.currentCity,
      currentState: currentState ?? this.currentState,
      currentPincode: currentPincode ?? this.currentPincode,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      permanentCity: permanentCity ?? this.permanentCity,
      permanentState: permanentState ?? this.permanentState,
      permanentPincode: permanentPincode ?? this.permanentPincode,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      panNumber: panNumber ?? this.panNumber,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      uan: uan ?? this.uan,
      esicNumber: esicNumber ?? this.esicNumber,
      isPfApplicable: isPfApplicable ?? this.isPfApplicable,
      isEsicApplicable: isEsicApplicable ?? this.isEsicApplicable,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      reportingManager: reportingManager ?? this.reportingManager,
      reportingManagerId: reportingManagerId ?? this.reportingManagerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'employeeType': employeeType,
      'department': department,
      'designation': designation,
      'joiningDate': joiningDate.toIso8601String(),
      'confirmationDate': confirmationDate?.toIso8601String(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'maritalStatus': maritalStatus,
      'bloodGroup': bloodGroup,
      'fatherName': fatherName,
      'motherName': motherName,
      'spouseName': spouseName,
      'emergencyContact': emergencyContact,
      'emergencyContactName': emergencyContactName,
      'status': status,
      'currentAddress': currentAddress,
      'currentCity': currentCity,
      'currentState': currentState,
      'currentPincode': currentPincode,
      'permanentAddress': permanentAddress,
      'permanentCity': permanentCity,
      'permanentState': permanentState,
      'permanentPincode': permanentPincode,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'ifscCode': ifscCode,
      'panNumber': panNumber,
      'aadhaarNumber': aadhaarNumber,
      'uan': uan,
      'esicNumber': esicNumber,
      'isPfApplicable': isPfApplicable,
      'isEsicApplicable': isEsicApplicable,
      'profileImageUrl': profileImageUrl,
      'reportingManager': reportingManager,
      'reportingManagerId': reportingManagerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      employeeCode: json['employeeCode'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      alternatePhone: json['alternatePhone'] as String?,
      employeeType: json['employeeType'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      joiningDate: DateTime.parse(json['joiningDate'] as String),
      confirmationDate: json['confirmationDate'] != null
          ? DateTime.parse(json['confirmationDate'] as String)
          : null,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      fatherName: json['fatherName'] as String?,
      motherName: json['motherName'] as String?,
      spouseName: json['spouseName'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      status: json['status'] as String,
      currentAddress: json['currentAddress'] as String?,
      currentCity: json['currentCity'] as String?,
      currentState: json['currentState'] as String?,
      currentPincode: json['currentPincode'] as String?,
      permanentAddress: json['permanentAddress'] as String?,
      permanentCity: json['permanentCity'] as String?,
      permanentState: json['permanentState'] as String?,
      permanentPincode: json['permanentPincode'] as String?,
      bankName: json['bankName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      ifscCode: json['ifscCode'] as String?,
      panNumber: json['panNumber'] as String?,
      aadhaarNumber: json['aadhaarNumber'] as String?,
      uan: json['uan'] as String?,
      esicNumber: json['esicNumber'] as String?,
      isPfApplicable: json['isPfApplicable'] as bool? ?? false,
      isEsicApplicable: json['isEsicApplicable'] as bool? ?? false,
      profileImageUrl: json['profileImageUrl'] as String?,
      reportingManager: json['reportingManager'] as String?,
      reportingManagerId: json['reportingManagerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeCode,
    firstName,
    lastName,
    email,
    phone,
    alternatePhone,
    employeeType,
    department,
    designation,
    joiningDate,
    confirmationDate,
    dateOfBirth,
    gender,
    maritalStatus,
    bloodGroup,
    fatherName,
    motherName,
    spouseName,
    emergencyContact,
    emergencyContactName,
    status,
    currentAddress,
    currentCity,
    currentState,
    currentPincode,
    permanentAddress,
    permanentCity,
    permanentState,
    permanentPincode,
    bankName,
    bankAccountNumber,
    ifscCode,
    panNumber,
    aadhaarNumber,
    uan,
    esicNumber,
    isPfApplicable,
    isEsicApplicable,
    profileImageUrl,
    reportingManager,
    reportingManagerId,
    createdAt,
    updatedAt,
    createdBy,
    updatedBy,
  ];
}
