enum DailyTaskPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    DailyTaskPriority.low => 'Low',
    DailyTaskPriority.medium => 'Medium',
    DailyTaskPriority.high => 'High',
  };

  static DailyTaskPriority fromFirestore(Object? value) {
    return DailyTaskPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => DailyTaskPriority.medium,
    );
  }
}
