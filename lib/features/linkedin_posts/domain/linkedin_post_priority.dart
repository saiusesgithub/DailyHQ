enum LinkedInPostPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    LinkedInPostPriority.low => 'Low',
    LinkedInPostPriority.medium => 'Medium',
    LinkedInPostPriority.high => 'High',
  };

  static LinkedInPostPriority fromFirestore(Object? value) {
    return LinkedInPostPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => LinkedInPostPriority.medium,
    );
  }
}
