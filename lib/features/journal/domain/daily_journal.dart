import 'package:cloud_firestore/cloud_firestore.dart';

import 'journal_time_block.dart';

class DailyJournal {
  const DailyJournal({
    required this.id,
    required this.date,
    required this.timeBlocks,
    required this.markdown,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final List<JournalTimeBlock> timeBlocks;
  final String markdown;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DailyJournal.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final blocks = data['timeBlocks'];
    final timeBlocks = blocks is List
        ? blocks
              .whereType<Map>()
              .map(
                (block) =>
                    JournalTimeBlock.fromMap(Map<String, dynamic>.from(block)),
              )
              .toList()
        : <JournalTimeBlock>[];
    timeBlocks.sort(
      (first, second) => first.startMinutes.compareTo(second.startMinutes),
    );

    return DailyJournal(
      id: document.id,
      date: _readDate(data['date']),
      timeBlocks: timeBlocks,
      markdown: data['markdown'] is String ? data['markdown'] as String : '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static DateTime _readDate(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
