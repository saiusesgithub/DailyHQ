import 'package:cloud_firestore/cloud_firestore.dart';

import 'todo_priority.dart';
import 'todo_subtask.dart';

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.notes,
    required this.priority,
    required this.deadline,
    required this.isImportant,
    required this.isUrgent,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.subtasks = const [],
    this.isPinned = false,
    this.movedToDailyDate,
    this.sortOrder,
  });

  final String id;
  final String title;
  final String notes;
  final TodoPriority priority;
  final DateTime? deadline;
  final bool isImportant;
  final bool isUrgent;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TodoSubtask> subtasks;
  final bool isPinned;
  final DateTime? movedToDailyDate;
  final int? sortOrder;

  factory TodoItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawSubtasks = data['subtasks'];
    final subtasks = rawSubtasks is List
        ? rawSubtasks
              .whereType<Map>()
              .map(
                (subtask) =>
                    TodoSubtask.fromMap(Map<String, dynamic>.from(subtask)),
              )
              .toList()
        : <TodoSubtask>[];
    return TodoItem(
      id: document.id,
      title: data['title'] is String ? data['title'] as String : '',
      notes: data['notes'] is String ? data['notes'] as String : '',
      priority: TodoPriority.fromFirestore(data['priority']),
      deadline: data['deadline'] is Timestamp
          ? (data['deadline'] as Timestamp).toDate()
          : null,
      isImportant: data['isImportant'] == true,
      isUrgent: data['isUrgent'] == true,
      isCompleted: data['isCompleted'] == true,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
      subtasks: subtasks,
      isPinned: data['isPinned'] == true,
      movedToDailyDate: data['movedToDailyDate'] is Timestamp
          ? (data['movedToDailyDate'] as Timestamp).toDate()
          : null,
      sortOrder: data['sortOrder'] is num
          ? (data['sortOrder'] as num).toInt()
          : null,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'title': title,
      'notes': notes,
      'priority': priority.name,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
      'isImportant': isImportant,
      'isUrgent': isUrgent,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((subtask) => subtask.toFirestore()).toList(),
      'isPinned': isPinned,
      'movedToDailyDate': movedToDailyDate == null
          ? null
          : Timestamp.fromDate(movedToDailyDate!),
      'sortOrder': sortOrder,
    };
  }

  static DateTime _readDate(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
