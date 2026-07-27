import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/daily_task.dart';
import '../domain/daily_task_priority.dart';
import '../domain/recurring_daily_task.dart';

class DailyTasksRepository {
  DailyTasksRepository({required String userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _tasks = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('daily_tasks'),
      _recurringTasks = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('recurring_daily_tasks'),
      _todos = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('todos');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _tasks;
  final CollectionReference<Map<String, dynamic>> _recurringTasks;
  final CollectionReference<Map<String, dynamic>> _todos;

  Stream<List<DailyTask>> watchTasks() {
    return _tasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs.map(DailyTask.fromDocument).toList();
      tasks.sort((first, second) {
        final dateOrder = second.plannedDate.compareTo(first.plannedDate);
        return dateOrder != 0
            ? dateOrder
            : first.createdAt.compareTo(second.createdAt);
      });
      return tasks;
    });
  }

  Stream<List<RecurringDailyTask>> watchRecurringTasks() {
    return _recurringTasks.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map(RecurringDailyTask.fromDocument)
          .where((task) => task.title.trim().isNotEmpty)
          .toList();
      tasks.sort((first, second) {
        final frequencyOrder = first.frequency.index.compareTo(
          second.frequency.index,
        );
        return frequencyOrder != 0
            ? frequencyOrder
            : first.title.toLowerCase().compareTo(second.title.toLowerCase());
      });
      return tasks;
    });
  }

  Future<void> createTask(
    String title,
    DateTime date,
    DailyTaskPriority priority,
  ) {
    return _tasks.add({
      'title': title,
      'isCompleted': false,
      'priority': priority.name,
      'plannedDate': Timestamp.fromDate(_dateOnly(date)),
      'rolledOverAt': null,
      'recurringTaskId': null,
      'sourceTodoId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(
    String taskId,
    String title,
    DailyTaskPriority priority,
  ) {
    return _tasks.doc(taskId).update({
      'title': title,
      'priority': priority.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCompleted(DailyTask task, bool isCompleted) async {
    final sourceTodoId = task.sourceTodoId;
    if (sourceTodoId == null) {
      await _tasks.doc(task.id).update({
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final todo = _todos.doc(sourceTodoId);
    await _firestore.runTransaction((transaction) async {
      final todoSnapshot = await transaction.get(todo);
      transaction.update(_tasks.doc(task.id), {
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (todoSnapshot.exists) {
        transaction.update(todo, {
          'isCompleted': isCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();

  Future<void> createRecurringTask({
    required String title,
    required DailyTaskPriority priority,
    required RecurringTaskFrequency frequency,
    int? dayOfMonth,
  }) async {
    final today = _dateOnly(DateTime.now());
    final recurringTask = _recurringTasks.doc();
    final batch = _firestore.batch();
    final isDueToday = _isDueOnDate(frequency, dayOfMonth, today);

    batch.set(recurringTask, {
      'title': title,
      'priority': priority.name,
      'frequency': frequency.name,
      'dayOfMonth': frequency == RecurringTaskFrequency.monthly
          ? dayOfMonth
          : null,
      'lastGeneratedDate': isDueToday ? Timestamp.fromDate(today) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (isDueToday) {
      batch.set(
        _tasks.doc(_occurrenceId(recurringTask.id, today)),
        _recurringOccurrence(
          recurringTaskId: recurringTask.id,
          title: title,
          priority: priority,
          date: today,
        ),
      );
    }

    await batch.commit();
  }

  Future<void> updateRecurringTask({
    required String recurringTaskId,
    required String title,
    required DailyTaskPriority priority,
    required RecurringTaskFrequency frequency,
    int? dayOfMonth,
  }) async {
    final today = _dateOnly(DateTime.now());
    final template = _recurringTasks.doc(recurringTaskId);
    final occurrence = _tasks.doc(_occurrenceId(recurringTaskId, today));
    final occurrenceSnapshot = await occurrence.get();
    final isDueToday = _isDueOnDate(frequency, dayOfMonth, today);
    final batch = _firestore.batch();

    batch.update(template, {
      'title': title,
      'priority': priority.name,
      'frequency': frequency.name,
      'dayOfMonth': frequency == RecurringTaskFrequency.monthly
          ? dayOfMonth
          : null,
      'lastGeneratedDate': isDueToday ? Timestamp.fromDate(today) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (isDueToday) {
      if (occurrenceSnapshot.exists) {
        batch.update(occurrence, {
          'title': title,
          'priority': priority.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.set(
          occurrence,
          _recurringOccurrence(
            recurringTaskId: recurringTaskId,
            title: title,
            priority: priority,
            date: today,
          ),
        );
      }
    }

    await batch.commit();
  }

  Future<void> ensureTodayRecurringTasks() async {
    final today = _dateOnly(DateTime.now());
    final templates = await _recurringTasks.get();
    final batch = _firestore.batch();
    var hasWrites = false;

    for (final template in templates.docs) {
      final data = template.data();
      final frequency = RecurringTaskFrequency.fromFirestore(data['frequency']);
      final dayOfMonth = data['dayOfMonth'] is int
          ? data['dayOfMonth'] as int
          : null;
      if (!_isDueOnDate(frequency, dayOfMonth, today)) continue;

      final lastGenerated = data['lastGeneratedDate'];
      if (lastGenerated is Timestamp &&
          _dateOnly(lastGenerated.toDate()).isAtSameMomentAs(today)) {
        continue;
      }

      final title = data['title'] is String ? data['title'] as String : '';
      if (title.trim().isEmpty) continue;
      final priority = DailyTaskPriority.fromFirestore(data['priority']);
      batch.set(
        _tasks.doc(_occurrenceId(template.id, today)),
        _recurringOccurrence(
          recurringTaskId: template.id,
          title: title,
          priority: priority,
          date: today,
        ),
      );
      batch.update(template.reference, {
        'lastGeneratedDate': Timestamp.fromDate(today),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      hasWrites = true;
    }

    if (hasWrites) await batch.commit();
  }

  Future<void> stopRecurring(String recurringTaskId) {
    return _recurringTasks.doc(recurringTaskId).delete();
  }

  Future<void> doToday(DailyTask task) async {
    final batch = _firestore.batch();
    final newTask = _tasks.doc();

    batch.update(_tasks.doc(task.id), {
      'isCompleted': false,
      'priority': task.priority.name,
      'rolledOverAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(newTask, {
      'title': task.title,
      'isCompleted': false,
      'priority': task.priority.name,
      'plannedDate': Timestamp.fromDate(_dateOnly(DateTime.now())),
      'rolledOverAt': null,
      'recurringTaskId': null,
      'sourceTodoId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _occurrenceId(String recurringTaskId, DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${recurringTaskId}_${date.year}-$month-$day';
  }

  static bool _isDueOnDate(
    RecurringTaskFrequency frequency,
    int? dayOfMonth,
    DateTime date,
  ) {
    if (frequency == RecurringTaskFrequency.daily) return true;
    final requestedDay = (dayOfMonth ?? 1).clamp(1, 31);
    final lastDay = DateTime(date.year, date.month + 1, 0).day;
    return date.day == math.min(requestedDay, lastDay);
  }

  static Map<String, Object?> _recurringOccurrence({
    required String recurringTaskId,
    required String title,
    required DailyTaskPriority priority,
    required DateTime date,
  }) {
    return {
      'title': title,
      'isCompleted': false,
      'priority': priority.name,
      'plannedDate': Timestamp.fromDate(date),
      'rolledOverAt': null,
      'recurringTaskId': recurringTaskId,
      'sourceTodoId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
