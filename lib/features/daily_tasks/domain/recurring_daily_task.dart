import 'package:cloud_firestore/cloud_firestore.dart';

import 'daily_task_priority.dart';

enum RecurringTaskFrequency {
  daily,
  monthly;

  String get label => switch (this) {
    RecurringTaskFrequency.daily => 'Daily',
    RecurringTaskFrequency.monthly => 'Monthly',
  };

  static RecurringTaskFrequency fromFirestore(Object? value) {
    return values.where((frequency) => frequency.name == value).firstOrNull ??
        RecurringTaskFrequency.daily;
  }
}

class RecurringDailyTask {
  const RecurringDailyTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.frequency,
    required this.dayOfMonth,
  });

  final String id;
  final String title;
  final DailyTaskPriority priority;
  final RecurringTaskFrequency frequency;
  final int? dayOfMonth;

  String get scheduleLabel => switch (frequency) {
    RecurringTaskFrequency.daily => 'Every day',
    RecurringTaskFrequency.monthly => 'Monthly on day ${dayOfMonth ?? 1}',
  };

  factory RecurringDailyTask.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return RecurringDailyTask(
      id: document.id,
      title: data['title'] is String ? data['title'] as String : '',
      priority: DailyTaskPriority.fromFirestore(data['priority']),
      frequency: RecurringTaskFrequency.fromFirestore(data['frequency']),
      dayOfMonth: data['dayOfMonth'] is int ? data['dayOfMonth'] as int : null,
    );
  }
}
