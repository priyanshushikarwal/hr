import 'package:equatable/equatable.dart';

/// User roles enum
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
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }

  bool get isDesktopAllowed =>
      this == UserRole.hr ||
      this == UserRole.manager ||
      this == UserRole.accountant;

  bool get isMobileAllowed => this == UserRole.employee;
}

/// App User Model
class AppUser extends Equatable {
  final String userId;
  final String email;
  final UserRole role;
  final String? employeeId;
  final String? fcmToken;
  final String? name;
  final DateTime createdAt;

  /// Appwrite document ID (may differ from userId)
  final String? documentId;

  const AppUser({
    required this.userId,
    required this.email,
    required this.role,
    this.employeeId,
    this.fcmToken,
    this.name,
    required this.createdAt,
    this.documentId,
  });

  bool get isHR => role == UserRole.hr;
  bool get isManager => role == UserRole.manager;
  bool get isAccountant => role == UserRole.accountant;
  bool get isEmployee => role == UserRole.employee;
  bool get canApproveLeave => isHR || isManager;
  bool get canMarkAttendance => isHR || isManager;
  bool get canManageEmployees => isHR;

  AppUser copyWith({
    String? userId,
    String? email,
    UserRole? role,
    String? employeeId,
    String? fcmToken,
    String? name,
    DateTime? createdAt,
    String? documentId,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      fcmToken: fcmToken ?? this.fcmToken,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      documentId: documentId ?? this.documentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'role': role.value,
      'employeeId': employeeId,
      'fcmToken': fcmToken,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json, {String? docId}) {
    return AppUser(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'employee'),
      employeeId: json['employeeId']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
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
    fcmToken,
    name,
    createdAt,
    documentId,
  ];
}
