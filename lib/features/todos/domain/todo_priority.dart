enum TodoPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    TodoPriority.low => 'Low',
    TodoPriority.medium => 'Medium',
    TodoPriority.high => 'High',
  };

  static TodoPriority fromFirestore(Object? value) {
    return TodoPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => TodoPriority.medium,
    );
  }
}
