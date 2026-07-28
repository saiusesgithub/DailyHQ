import 'package:cloud_firestore/cloud_firestore.dart';

import 'project_priority.dart';
import 'project_status.dart';
import 'project_subtask.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.priority,
    required this.deadline,
    required this.subtasks,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final ProjectStatus status;
  final ProjectPriority priority;
  final DateTime? deadline;
  final List<ProjectSubtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get completedSubtaskCount {
    return subtasks.where((subtask) => subtask.isCompleted).length;
  }

  double? get completion {
    if (subtasks.isEmpty) return null;
    return completedSubtaskCount / subtasks.length;
  }

  Project copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? deadline,
    bool clearDeadline = false,
    List<ProjectSubtask>? subtasks,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Project.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final fallback = DateTime.fromMillisecondsSinceEpoch(0);
    final rawSubtasks = data['subtasks'];

    return Project(
      id: document.id,
      name: data['name'] is String ? data['name'] as String : '',
      description: data['description'] is String
          ? data['description'] as String
          : '',
      status: ProjectStatus.fromFirestore(data['status']),
      priority: ProjectPriority.fromFirestore(data['priority']),
      deadline: _readDate(data['deadline']),
      subtasks: rawSubtasks is List
          ? rawSubtasks
                .whereType<Map>()
                .map(
                  (item) =>
                      ProjectSubtask.fromMap(Map<String, dynamic>.from(item)),
                )
                .where((subtask) => subtask.id.isNotEmpty)
                .toList()
          : const [],
      createdAt: _readDate(data['createdAt']) ?? fallback,
      updatedAt: _readDate(data['updatedAt']) ?? fallback,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'name': name,
      'description': description,
      'status': status.firestoreValue,
      'priority': priority.name,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
      'subtasks': subtasks.map((subtask) => subtask.toFirestore()).toList(),
    };
  }

  static DateTime? _readDate(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
