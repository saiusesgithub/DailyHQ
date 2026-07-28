import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/thought_day.dart';

class ThoughtsRepository {
  ThoughtsRepository({required String userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _thoughtDays = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('thought_days');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _thoughtDays;

  Stream<List<ThoughtDay>> watchThoughtDays() {
    return _thoughtDays.snapshots().map((snapshot) {
      final days = snapshot.docs.map(ThoughtDay.fromDocument).toList();
      days.sort((first, second) => second.date.compareTo(first.date));
      return days;
    });
  }

  Future<void> appendThought({
    required DateTime date,
    required String thought,
  }) async {
    final normalizedDate = _dateOnly(date);
    final document = _thoughtDays.doc(_dateKey(normalizedDate));
    final trimmedThought = thought.trim();
    if (trimmedThought.isEmpty) return;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final existing = snapshot.data()?['markdown'];
      final currentMarkdown = existing is String ? existing.trimRight() : '';
      final entry = _markdownEntry(trimmedThought, DateTime.now());
      final markdown = currentMarkdown.isEmpty
          ? entry
          : '$currentMarkdown\n$entry';

      transaction.set(document, {
        'date': Timestamp.fromDate(normalizedDate),
        'markdown': markdown,
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> saveMarkdown({
    required DateTime date,
    required String markdown,
  }) async {
    final normalizedDate = _dateOnly(date);
    final document = _thoughtDays.doc(_dateKey(normalizedDate));
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      transaction.set(document, {
        'date': Timestamp.fromDate(normalizedDate),
        'markdown': markdown.trimRight(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static String _markdownEntry(String thought, DateTime capturedAt) {
    final lines = thought.split('\n');
    final continuation = lines.skip(1).map((line) => '  $line').join('\n');
    final firstLine = '- ${_formatTime(capturedAt)} — ${lines.first}';
    return continuation.isEmpty ? firstLine : '$firstLine\n$continuation';
  }

  static String _formatTime(DateTime date) {
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
