import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/todo_item.dart';

class TodosRepository {
  TodosRepository({required String userId, FirebaseFirestore? firestore})
    : _todos = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('todos');

  final CollectionReference<Map<String, dynamic>> _todos;

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

  Future<void> setCompleted(String todoId, bool isCompleted) {
    return _todos.doc(todoId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTodo(String todoId) => _todos.doc(todoId).delete();

  static int _compareTodos(TodoItem first, TodoItem second) {
    if (first.isCompleted != second.isCompleted) {
      return first.isCompleted ? 1 : -1;
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
