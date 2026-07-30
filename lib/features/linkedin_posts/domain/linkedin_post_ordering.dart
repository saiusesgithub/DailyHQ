import 'linkedin_post.dart';

List<LinkedInPost> orderPlannedPosts(Iterable<LinkedInPost> posts) {
  final ordered = posts.toList();
  ordered.sort((first, second) {
    final manualOrder = _compareManualOrder(first, second);
    if (manualOrder != null) return manualOrder;
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
    final manualOrder = _compareManualOrder(first, second);
    if (manualOrder != null) return manualOrder;
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

int? _compareManualOrder(LinkedInPost first, LinkedInPost second) {
  final firstOrder = first.sortOrder;
  final secondOrder = second.sortOrder;
  if (firstOrder == null && secondOrder == null) return null;
  if (firstOrder == null) return 1;
  if (secondOrder == null) return -1;
  return firstOrder.compareTo(secondOrder);
}
