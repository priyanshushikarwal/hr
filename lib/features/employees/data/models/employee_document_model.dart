import 'package:equatable/equatable.dart';

class EmployeeDocument extends Equatable {
  final String id;
  final String employeeId;
  final String documentName;
  final String documentType;
  final String fileId;
  final String fileUrl;
  final DateTime uploadedAt;

  const EmployeeDocument({
    required this.id,
    required this.employeeId,
    required this.documentName,
    required this.documentType,
    required this.fileId,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['\$id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      documentName: json['documentName'] ?? '',
      documentType: json['documentType'] ?? '',
      fileId: json['fileId'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'documentName': documentName,
      'documentType': documentType,
      'fileId': fileId,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    documentName,
    documentType,
    fileId,
    fileUrl,
    uploadedAt,
  ];
}
