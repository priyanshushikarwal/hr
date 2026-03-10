class Employee {
  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String employeeType;
  final String department;
  final String designation;
  final DateTime joiningDate;
  final String status;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? currentAddress;
  final String? currentCity;
  final String? currentState;
  final String? bankName;
  final String? bankAccountNumber;
  final String? profileImageUrl;
  final String? reportingManager;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.employeeType,
    required this.department,
    required this.designation,
    required this.joiningDate,
    required this.status,
    this.dateOfBirth,
    this.gender,
    this.currentAddress,
    this.currentCity,
    this.currentState,
    this.bankName,
    this.bankAccountNumber,
    this.profileImageUrl,
    this.reportingManager,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory Employee.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Employee(
      id: docId ?? json['\$id'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      employeeType: json['employeeType'] ?? 'office',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      joiningDate:
          DateTime.tryParse(json['joiningDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      currentAddress: json['currentAddress'],
      currentCity: json['currentCity'],
      currentState: json['currentState'],
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      profileImageUrl: json['profileImageUrl'],
      reportingManager: json['reportingManager'],
    );
  }
}
