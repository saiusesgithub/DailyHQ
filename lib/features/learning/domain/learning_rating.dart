enum LearningRating {
  low,
  medium,
  high;

  String get label => switch (this) {
    LearningRating.low => 'Low',
    LearningRating.medium => 'Medium',
    LearningRating.high => 'High',
  };

  static LearningRating fromFirestore(Object? value) {
    return LearningRating.values.firstWhere(
      (rating) => rating.name == value,
      orElse: () => LearningRating.medium,
    );
  }
}
