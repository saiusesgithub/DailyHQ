import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/daily_journal.dart';
import '../domain/journal_time_block.dart';

class JournalRepository {
  JournalRepository({required String userId, FirebaseFirestore? firestore})
    : _journals = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('daily_journals');

  final CollectionReference<Map<String, dynamic>> _journals;

  Stream<DailyJournal?> watchJournal(DateTime date) {
    return _journals.doc(_dateKey(date)).snapshots().map((document) {
      return document.exists ? DailyJournal.fromDocument(document) : null;
    });
  }

  Future<void> saveJournal({
    required DateTime date,
    required String journalText,
    required List<JournalTimeBlock> timeBlocks,
    required bool exists,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final sortedBlocks = [...timeBlocks]
      ..sort(
        (first, second) => first.startMinutes.compareTo(second.startMinutes),
      );
    final data = <String, Object?>{
      'date': Timestamp.fromDate(normalizedDate),
      'journalText': journalText,
      'timeBlocks': sortedBlocks.map((block) => block.toFirestore()).toList(),
      'markdown': _buildMarkdown(normalizedDate, journalText, sortedBlocks),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!exists) data['createdAt'] = FieldValue.serverTimestamp();

    return _journals.doc(_dateKey(date)).set(data, SetOptions(merge: true));
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _buildMarkdown(
    DateTime date,
    String journalText,
    List<JournalTimeBlock> blocks,
  ) {
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final buffer = StringBuffer('# Journal — $dateLabel\n');

    if (blocks.isNotEmpty) {
      buffer.writeln('\n## Time blocks');
      for (final block in blocks) {
        buffer.writeln(
          '\n### ${_formatMinutes(block.startMinutes)}–'
          '${_formatMinutes(block.endMinutes)} · ${block.activity}',
        );
        buffer.writeln('**Type:** ${block.category}');
        if (block.details.isNotEmpty) buffer.writeln('\n${block.details}');
      }
    }

    if (journalText.isNotEmpty) {
      buffer.writeln('\n## Journal\n');
      buffer.writeln(journalText);
    }

    return buffer.toString().trim();
  }

  static String _formatMinutes(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}
