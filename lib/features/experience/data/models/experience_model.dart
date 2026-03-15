import 'package:equatable/equatable.dart';

/// Work Experience Model
class WorkExperience extends Equatable {
  final String id;
  final String employeeId;
  final String companyName;
  final String designation;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? location;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkExperience({
    required this.id,
    required this.employeeId,
    required this.companyName,
    required this.designation,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.location,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'] as String? ?? json['\$id'] as String,
      employeeId: json['employeeId'] as String,
      companyName: json['companyName'] as String,
      designation: json['designation'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      isCurrent: json['isCurrent'] as bool? ?? false,
      location: json['location'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'companyName': companyName,
      'designation': designation,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCurrent': isCurrent,
      'location': location,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WorkExperience copyWith({
    String? id,
    String? employeeId,
    String? companyName,
    String? designation,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? location,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkExperience(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      companyName: companyName ?? this.companyName,
      designation: designation ?? this.designation,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        companyName,
        designation,
        startDate,
        endDate,
        isCurrent,
        location,
        description,
        createdAt,
        updatedAt,
      ];
}
