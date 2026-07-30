import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/linkedin_post.dart';
import '../domain/linkedin_post_priority.dart';
import '../domain/linkedin_post_status.dart';

class LinkedInPostsRepository {
  LinkedInPostsRepository({
    required String userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _posts = (firestore ?? FirebaseFirestore.instance)
           .collection('users')
           .doc(userId)
           .collection('linkedin_posts');

  final FirebaseFirestore _firestore;
  final CollectionReference<Map<String, dynamic>> _posts;

  Stream<List<LinkedInPost>> watchPosts() {
    return _posts.snapshots().map(
      (snapshot) => snapshot.docs.map(LinkedInPost.fromDocument).toList(),
    );
  }

  Future<void> createPost({
    required String title,
    required String description,
    required DateTime? plannedDate,
    required LinkedInPostPriority priority,
    required String imageIdeas,
  }) async {
    await _posts.add({
      'title': title,
      'description': description,
      'status': LinkedInPostStatus.planned.name,
      'plannedDate': _timestampOrNull(plannedDate),
      'postedDate': null,
      'priority': priority.name,
      'imageIdeas': imageIdeas,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost(LinkedInPost post) async {
    await _posts.doc(post.id).update({
      ...post.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsPosted(String postId, DateTime postedDate) async {
    await _posts.doc(postId).update({
      'status': LinkedInPostStatus.posted.name,
      'postedDate': Timestamp.fromDate(postedDate),
      'sortOrder': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> moveBackToPlanned(String postId) async {
    await _posts.doc(postId).update({
      'status': LinkedInPostStatus.planned.name,
      'postedDate': null,
      'sortOrder': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) {
    return _posts.doc(postId).delete();
  }

  Future<void> reorderPosts(List<LinkedInPost> posts) async {
    final batch = _firestore.batch();
    for (var index = 0; index < posts.length; index++) {
      batch.update(_posts.doc(posts[index].id), {
        'sortOrder': index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Timestamp? _timestampOrNull(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}
