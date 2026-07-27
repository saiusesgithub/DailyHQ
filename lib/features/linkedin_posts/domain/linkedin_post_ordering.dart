import 'linkedin_post.dart';

List<LinkedInPost> orderPlannedPosts(Iterable<LinkedInPost> posts) {
  final ordered = posts.toList();
  ordered.sort((first, second) {
    final firstDate = first.plannedDate;
    final secondDate = second.plannedDate;

    if (firstDate != null && secondDate == null) return -1;
    if (firstDate == null && secondDate != null) return 1;

    if (firstDate != null && secondDate != null) {
      final dateComparison = firstDate.compareTo(secondDate);
      if (dateComparison != 0) return dateComparison;
    }

    return second.createdAt.compareTo(first.createdAt);
  });
  return ordered;
}

List<LinkedInPost> orderPostedPosts(Iterable<LinkedInPost> posts) {
  final ordered = posts.toList();
  ordered.sort((first, second) {
    final firstDate = first.postedDate;
    final secondDate = second.postedDate;

    if (firstDate != null && secondDate == null) return -1;
    if (firstDate == null && secondDate != null) return 1;
    if (firstDate != null && secondDate != null) {
      final dateComparison = secondDate.compareTo(firstDate);
      if (dateComparison != 0) return dateComparison;
    }

    return second.createdAt.compareTo(first.createdAt);
  });
  return ordered;
}
