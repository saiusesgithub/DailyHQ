import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectSubtask {
  const ProjectSubtask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  ProjectSubtask copyWith({bool? isCompleted}) {
    return ProjectSubtask(
      id: id,
      title: title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  factory ProjectSubtask.fromMap(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return ProjectSubtask(
      id: data['id'] is String ? data['id'] as String : '',
      title: data['title'] is String ? data['title'] as String : '',
      isCompleted: data['isCompleted'] == true,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object> toFirestore() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
