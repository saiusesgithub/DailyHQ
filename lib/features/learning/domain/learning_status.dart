enum LearningStatus {
  toLearn,
  learning,
  completed;

  String get label => switch (this) {
    LearningStatus.toLearn => 'To learn',
    LearningStatus.learning => 'Learning',
    LearningStatus.completed => 'Completed',
  };

  static LearningStatus fromFirestore(Object? value) {
    return LearningStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LearningStatus.toLearn,
    );
  }
}
