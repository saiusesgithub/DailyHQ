import 'package:cloud_firestore/cloud_firestore.dart';

import 'linkedin_post_priority.dart';
import 'linkedin_post_status.dart';

class LinkedInPost {
  const LinkedInPost({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.plannedDate,
    required this.postedDate,
    required this.priority,
    required this.imageIdeas,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final LinkedInPostStatus status;
  final DateTime? plannedDate;
  final DateTime? postedDate;
  final LinkedInPostPriority priority;
  final String imageIdeas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? sortOrder;

  factory LinkedInPost.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final fallbackDate = DateTime.fromMillisecondsSinceEpoch(0);

    return LinkedInPost(
      id: document.id,
      title: _readString(data['title']),
      description: _readString(data['description']),
      status: LinkedInPostStatus.fromFirestore(data['status']),
      plannedDate: _readDate(data['plannedDate']),
      postedDate: _readDate(data['postedDate']),
      priority: LinkedInPostPriority.fromFirestore(data['priority']),
      imageIdeas: _readString(data['imageIdeas']),
      createdAt: _readDate(data['createdAt']) ?? fallbackDate,
      updatedAt: _readDate(data['updatedAt']) ?? fallbackDate,
      sortOrder: data['sortOrder'] is num
          ? (data['sortOrder'] as num).toInt()
          : null,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'plannedDate': _toTimestamp(plannedDate),
      'postedDate': _toTimestamp(postedDate),
      'priority': priority.name,
      'imageIdeas': imageIdeas,
      'sortOrder': sortOrder,
    };
  }

  static String _readString(Object? value) {
    return value is String ? value : '';
  }

  static DateTime? _readDate(Object? value) {
    return switch (value) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime date => date,
      _ => null,
    };
  }

  static Timestamp? _toTimestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}
