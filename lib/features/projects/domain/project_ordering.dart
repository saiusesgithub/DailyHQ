import 'project.dart';

List<Project> orderActiveProjects(Iterable<Project> projects) {
  final ordered = projects.toList();
  ordered.sort((first, second) {
    if (first.deadline != null && second.deadline == null) return -1;
    if (first.deadline == null && second.deadline != null) return 1;
    if (first.deadline != null && second.deadline != null) {
      final comparison = first.deadline!.compareTo(second.deadline!);
      if (comparison != 0) return comparison;
    }
    return second.updatedAt.compareTo(first.updatedAt);
  });
  return ordered;
}

List<Project> orderCompletedProjects(Iterable<Project> projects) {
  final ordered = projects.toList();
  ordered.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
  return ordered;
}
