import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/daily_task.dart';
import '../domain/daily_task_priority.dart';

class DailyTasksRepository {
  DailyTasksRepository({required String userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _tasks = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('daily_tasks');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _tasks;

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

  Future<void> setCompleted(String taskId, bool isCompleted) {
    return _tasks.doc(taskId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String taskId) => _tasks.doc(taskId).delete();

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
      'plannedDate': Timestamp.fromDate(_dateOnly(DateTime.now())),
      'rolledOverAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
