import 'package:cloud_firestore/cloud_firestore.dart';

import 'learning_rating.dart';
import 'learning_resource.dart';
import 'learning_status.dart';

class LearningItem {
  const LearningItem({
    required this.id,
    required this.title,
    required this.area,
    required this.notes,
    required this.status,
    required this.priority,
    required this.usefulness,
    required this.resources,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String area;
  final String notes;
  final LearningStatus status;
  final LearningRating priority;
  final LearningRating usefulness;
  final List<LearningResource> resources;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LearningItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawResources = data['resources'];
    final resources = rawResources is List
        ? rawResources
              .whereType<Map>()
              .map(
                (resource) => LearningResource.fromMap(
                  Map<String, dynamic>.from(resource),
                ),
              )
              .where((resource) => resource.url.isNotEmpty)
              .toList()
        : <LearningResource>[];

    return LearningItem(
      id: document.id,
      title: data['title'] is String ? data['title'] as String : '',
      area: data['area'] is String ? data['area'] as String : '',
      notes: data['notes'] is String ? data['notes'] as String : '',
      status: LearningStatus.fromFirestore(data['status']),
      priority: LearningRating.fromFirestore(data['priority']),
      usefulness: LearningRating.fromFirestore(data['usefulness']),
      resources: resources,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'title': title,
      'area': area,
      'notes': notes,
      'status': status.name,
      'priority': priority.name,
      'usefulness': usefulness.name,
      'resources': resources.map((resource) => resource.toFirestore()).toList(),
    };
  }

  static DateTime _readDate(Object? value) {
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }
}
