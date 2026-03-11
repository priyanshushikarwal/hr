import 'package:equatable/equatable.dart';

enum TaskStatus { pending, inProgress, completed }

enum TaskPriority { low, medium, high }

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String createdBy; // HR/Manager who created it
  final String? assignedTo; // Employee ID (optional - can be for general team)
  final String? completedAt;
  final String? completedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    required this.createdBy,
    this.assignedTo,
    this.completedAt,
    this.completedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == TaskStatus.pending;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !isCompleted;
  bool get isDueToday => dueDate.day == DateTime.now().day &&
      dueDate.month == DateTime.now().month &&
      dueDate.year == DateTime.now().year;

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? createdBy,
    String? assignedTo,
    String? completedAt,
    String? completedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'completedAt': completedAt,
      'completedBy': completedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Task(
      id: docId ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['dueDate'] is String
          ? DateTime.parse(json['dueDate'])
          : json['dueDate'] ?? DateTime.now(),
      status: _parseStatus(json['status']),
      priority: _parsePriority(json['priority']),
      createdBy: json['createdBy'] ?? '',
      assignedTo: json['assignedTo'],
      completedAt: json['completedAt'],
      completedBy: json['completedBy'],
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  static TaskStatus _parseStatus(dynamic value) {
    if (value == null) return TaskStatus.pending;
    if (value is TaskStatus) return value;
    if (value is String) {
      return TaskStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskStatus.pending,
      );
    }
    return TaskStatus.pending;
  }

  static TaskPriority _parsePriority(dynamic value) {
    if (value == null) return TaskPriority.medium;
    if (value is TaskPriority) return value;
    if (value is String) {
      return TaskPriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskPriority.medium,
      );
    }
    return TaskPriority.medium;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dueDate,
        status,
        priority,
        createdBy,
        assignedTo,
        completedAt,
        completedBy,
        createdAt,
        updatedAt,
      ];
}
