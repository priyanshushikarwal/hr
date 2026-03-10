import 'package:equatable/equatable.dart';

enum UserRole {
  hr,
  manager,
  accountant,
  employee;

  String get value {
    switch (this) {
      case UserRole.hr:
        return 'hr';
      case UserRole.manager:
        return 'manager';
      case UserRole.accountant:
        return 'accountant';
      case UserRole.employee:
        return 'employee';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'hr':
        return UserRole.hr;
      case 'manager':
        return UserRole.manager;
      case 'accountant':
        return UserRole.accountant;
      default:
        return UserRole.employee;
    }
  }

  bool get isMobileAllowed => this == UserRole.employee;
}

class AppUser extends Equatable {
  final String userId;
  final String email;
  final UserRole role;
  final String? employeeId;
  final String? name;
  final String? documentId;
  final DateTime createdAt;

  const AppUser({
    required this.userId,
    required this.email,
    required this.role,
    this.employeeId,
    this.name,
    this.documentId,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AppUser(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'employee'),
      employeeId: json['employeeId']?.toString(),
      name: json['name']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      documentId: docId,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    email,
    role,
    employeeId,
    name,
    documentId,
    createdAt,
  ];
}
