enum ProjectPriority {
  low,
  medium,
  high;

  String get label => switch (this) {
    ProjectPriority.low => 'Low',
    ProjectPriority.medium => 'Medium',
    ProjectPriority.high => 'High',
  };

  static ProjectPriority fromFirestore(Object? value) {
    return ProjectPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => ProjectPriority.medium,
    );
  }
}
