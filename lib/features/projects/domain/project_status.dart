enum ProjectStatus {
  started('started', 'Started'),
  inProgress('in_progress', 'In progress'),
  almostCompleted('almost_completed', 'Almost completed'),
  completed('completed', 'Completed');

  const ProjectStatus(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static ProjectStatus fromFirestore(Object? value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.firestoreValue == value,
      orElse: () => ProjectStatus.started,
    );
  }
}
