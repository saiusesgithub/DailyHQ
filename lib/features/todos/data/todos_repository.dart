import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/todo_item.dart';
import '../domain/todo_subtask.dart';

class TodosRepository {
  TodosRepository({required String userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _todos = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('todos'),
      _dailyTasks = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('daily_tasks');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _todos;
  final CollectionReference<Map<String, dynamic>> _dailyTasks;

  Stream<List<TodoItem>> watchTodos() {
    return _todos.snapshots().map((snapshot) {
      final todos = snapshot.docs.map(TodoItem.fromDocument).toList();
      todos.sort(_compareTodos);
      return todos;
    });
  }

  Future<void> createTodo(TodoItem todo) {
    return _todos.add({
      ...todo.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTodo(TodoItem todo) {
    return _todos.doc(todo.id).update({
      ...todo.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCompleted(TodoItem todo, bool isCompleted) async {
    final movedDate = todo.movedToDailyDate;
    if (movedDate == null) {
      await _todos.doc(todo.id).update({
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final dailyTask = _dailyTasks.doc(_dailyTaskId(todo.id, movedDate));
    await _firestore.runTransaction((transaction) async {
      final dailySnapshot = await transaction.get(dailyTask);
      transaction.update(_todos.doc(todo.id), {
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (dailySnapshot.exists) {
        transaction.update(dailyTask, {
          'isCompleted': isCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteTodo(String todoId) => _todos.doc(todoId).delete();

  Future<void> setPinned(String todoId, bool isPinned) {
    return _todos.doc(todoId).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSubtasks(String todoId, List<TodoSubtask> subtasks) {
    return _todos.doc(todoId).update({
      'subtasks': subtasks.map((subtask) => subtask.toFirestore()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> moveToToday(TodoItem todo) async {
    final today = _dateOnly(DateTime.now());
    final dailyTask = _dailyTasks.doc(_dailyTaskId(todo.id, today));
    await _firestore.runTransaction((transaction) async {
      final dailySnapshot = await transaction.get(dailyTask);
      if (!dailySnapshot.exists) {
        transaction.set(dailyTask, {
          'title': todo.title,
          'isCompleted': false,
          'priority': todo.priority.name,
          'plannedDate': Timestamp.fromDate(today),
          'rolledOverAt': null,
          'recurringTaskId': null,
          'sourceTodoId': todo.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(_todos.doc(todo.id), {
        'movedToDailyDate': Timestamp.fromDate(today),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dailyTaskId(String todoId, DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'todo_${todoId}_${date.year}-$month-$day';
  }

  static int _compareTodos(TodoItem first, TodoItem second) {
    if (first.isCompleted != second.isCompleted) {
      return first.isCompleted ? 1 : -1;
    }
    if (first.isPinned != second.isPinned) {
      return first.isPinned ? -1 : 1;
    }

    final firstDeadline = first.deadline;
    final secondDeadline = second.deadline;
    if (firstDeadline != null && secondDeadline != null) {
      final deadlineOrder = firstDeadline.compareTo(secondDeadline);
      if (deadlineOrder != 0) return deadlineOrder;
    } else if (firstDeadline != null) {
      return -1;
    } else if (secondDeadline != null) {
      return 1;
    }

    final priorityOrder = second.priority.index.compareTo(first.priority.index);
    return priorityOrder != 0
        ? priorityOrder
        : second.createdAt.compareTo(first.createdAt);
  }
}
