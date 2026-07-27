enum LinkedInPostStatus {
  planned,
  posted;

  String get label => switch (this) {
    LinkedInPostStatus.planned => 'Planned',
    LinkedInPostStatus.posted => 'Posted',
  };

  static LinkedInPostStatus fromFirestore(Object? value) {
    return LinkedInPostStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LinkedInPostStatus.planned,
    );
  }
}
