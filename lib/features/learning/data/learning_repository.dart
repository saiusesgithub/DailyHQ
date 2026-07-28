import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/learning_item.dart';
import '../domain/learning_status.dart';

class LearningRepository {
  LearningRepository({required String userId, FirebaseFirestore? firestore})
    : _items = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('learning_items');

  final CollectionReference<Map<String, dynamic>> _items;

  Stream<List<LearningItem>> watchItems() {
    return _items.snapshots().map((snapshot) {
      final items = snapshot.docs.map(LearningItem.fromDocument).toList();
      items.sort((first, second) {
        final priority = second.priority.index.compareTo(first.priority.index);
        if (priority != 0) return priority;
        final usefulness = second.usefulness.index.compareTo(
          first.usefulness.index,
        );
        return usefulness != 0
            ? usefulness
            : second.createdAt.compareTo(first.createdAt);
      });
      return items;
    });
  }

  Future<void> createItem(LearningItem item) {
    return _items.add({
      ...item.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(LearningItem item) {
    return _items.doc(item.id).update({
      ...item.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String itemId, LearningStatus status) {
    return _items.doc(itemId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String itemId) => _items.doc(itemId).delete();
}
