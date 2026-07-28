import 'package:cloud_firestore/cloud_firestore.dart';

class ThoughtDay {
  const ThoughtDay({
    required this.id,
    required this.date,
    required this.markdown,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String markdown;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ThoughtDay.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ThoughtDay(
      id: document.id,
      date: _dateFromId(document.id),
      markdown: data['markdown'] is String ? data['markdown'] as String : '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static DateTime _dateFromId(String id) {
    final parts = id.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime _readDate(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
