import 'package:cloud_firestore/cloud_firestore.dart';

import 'daily_task_priority.dart';

class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priority,
    required this.plannedDate,
    required this.createdAt,
    required this.updatedAt,
    this.rolledOverAt,
    this.recurringTaskId,
    this.sourceTodoId,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DailyTaskPriority priority;
  final DateTime plannedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? rolledOverAt;
  final String? recurringTaskId;
  final String? sourceTodoId;

  factory DailyTask.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return DailyTask(
      id: document.id,
      title: data['title'] is String ? data['title'] as String : '',
      isCompleted: data['isCompleted'] == true,
      priority: DailyTaskPriority.fromFirestore(data['priority']),
      plannedDate: _readDate(data['plannedDate']),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      rolledOverAt: data['rolledOverAt'] is Timestamp
          ? (data['rolledOverAt'] as Timestamp).toDate()
          : null,
      recurringTaskId: data['recurringTaskId'] is String
          ? data['recurringTaskId'] as String
          : null,
      sourceTodoId: data['sourceTodoId'] is String
          ? data['sourceTodoId'] as String
          : null,
    );
  }

  static DateTime _readDate(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
