import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectIdea {
  const ProjectIdea({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProjectIdea.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final fallback = DateTime.fromMillisecondsSinceEpoch(0);

    return ProjectIdea(
      id: document.id,
      name: data['name'] is String ? data['name'] as String : '',
      description: data['description'] is String
          ? data['description'] as String
          : '',
      createdAt: _readDate(data['createdAt']) ?? fallback,
      updatedAt: _readDate(data['updatedAt']) ?? fallback,
    );
  }

  static DateTime? _readDate(Object? value) {
    return value is Timestamp ? value.toDate() : null;
  }
}
