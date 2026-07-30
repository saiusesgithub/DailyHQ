import 'package:daily_hq/features/linkedin_posts/domain/linkedin_post.dart';
import 'package:daily_hq/features/linkedin_posts/domain/linkedin_post_ordering.dart';
import 'package:daily_hq/features/linkedin_posts/domain/linkedin_post_priority.dart';
import 'package:daily_hq/features/linkedin_posts/domain/linkedin_post_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planned posts put dated entries first and order dates ascending', () {
    final posts = [
      _post(id: 'undated', createdDay: 3),
      _post(id: 'later', plannedDay: 20, createdDay: 2),
      _post(id: 'earlier', plannedDay: 10, createdDay: 1),
    ];

    expect(orderPlannedPosts(posts).map((post) => post.id), [
      'earlier',
      'later',
      'undated',
    ]);
  });

  test('posted posts order the most recently posted first', () {
    final posts = [
      _post(id: 'older', postedDay: 10, status: LinkedInPostStatus.posted),
      _post(id: 'newer', postedDay: 20, status: LinkedInPostStatus.posted),
    ];

    expect(orderPostedPosts(posts).map((post) => post.id), ['newer', 'older']);
  });

  test('saved manual order takes precedence over date order', () {
    final posts = [
      _post(id: 'earlier-date', plannedDay: 1, sortOrder: 1),
      _post(id: 'dragged-first', plannedDay: 20, sortOrder: 0),
    ];

    expect(orderPlannedPosts(posts).map((post) => post.id), [
      'dragged-first',
      'earlier-date',
    ]);
  });
}

LinkedInPost _post({
  required String id,
  LinkedInPostStatus status = LinkedInPostStatus.planned,
  int? plannedDay,
  int? postedDay,
  int createdDay = 1,
  int? sortOrder,
}) {
  return LinkedInPost(
    id: id,
    title: id,
    description: '',
    status: status,
    plannedDate: plannedDay == null ? null : DateTime(2026, 7, plannedDay),
    postedDate: postedDay == null ? null : DateTime(2026, 7, postedDay),
    priority: LinkedInPostPriority.medium,
    imageIdeas: '',
    createdAt: DateTime(2026, 7, createdDay),
    updatedAt: DateTime(2026, 7, createdDay),
    sortOrder: sortOrder,
  );
}
