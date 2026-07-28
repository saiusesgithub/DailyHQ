import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/project.dart';
import '../domain/project_idea.dart';
import '../domain/project_priority.dart';
import '../domain/project_status.dart';
import '../domain/project_subtask.dart';

class ProjectsRepository {
  ProjectsRepository({required String userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _ideas =>
      _firestore.collection('users').doc(_userId).collection('project_ideas');

  CollectionReference<Map<String, dynamic>> get _projects =>
      _firestore.collection('users').doc(_userId).collection('projects');

  Stream<List<ProjectIdea>> watchIdeas() {
    return _ideas.snapshots().map((snapshot) {
      final ideas = snapshot.docs.map(ProjectIdea.fromDocument).toList();
      ideas.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
      return ideas;
    });
  }

  Stream<List<Project>> watchProjects() {
    return _projects.snapshots().map(
      (snapshot) => snapshot.docs.map(Project.fromDocument).toList(),
    );
  }

  Stream<Project?> watchProject(String projectId) {
    return _projects.doc(projectId).snapshots().map((document) {
      return document.exists ? Project.fromDocument(document) : null;
    });
  }

  Future<void> createIdea({required String name, required String description}) {
    return _ideas.add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteIdea(String ideaId) {
    return _ideas.doc(ideaId).delete();
  }

  Future<void> createProject({
    required String name,
    required String description,
    required ProjectStatus status,
    required ProjectPriority priority,
    required DateTime? deadline,
  }) {
    return _projects.add({
      'name': name,
      'description': description,
      'status': status.firestoreValue,
      'priority': priority.name,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'subtasks': <Map<String, Object>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startBuilding({
    required String ideaId,
    required String name,
    required String description,
    required ProjectStatus status,
    required ProjectPriority priority,
    required DateTime? deadline,
  }) async {
    final batch = _firestore.batch();
    final project = _projects.doc();

    batch.set(project, {
      'name': name,
      'description': description,
      'status': status.firestoreValue,
      'priority': priority.name,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'subtasks': <Map<String, Object>>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_ideas.doc(ideaId));

    await batch.commit();
  }

  Future<void> updateProject(Project project) {
    return _projects.doc(project.id).update({
      ...project.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProject(String projectId) {
    return _projects.doc(projectId).delete();
  }

  Future<void> addSubtask(Project project, String title) {
    final now = DateTime.now();
    final subtask = ProjectSubtask(
      id: '${now.microsecondsSinceEpoch}',
      title: title,
      isCompleted: false,
      createdAt: now,
    );
    return _updateSubtasks(project.id, [...project.subtasks, subtask]);
  }

  Future<void> toggleSubtask(Project project, String subtaskId) {
    final subtasks = project.subtasks.map((subtask) {
      return subtask.id == subtaskId
          ? subtask.copyWith(isCompleted: !subtask.isCompleted)
          : subtask;
    }).toList();
    return _updateSubtasks(project.id, subtasks);
  }

  Future<void> deleteSubtask(Project project, String subtaskId) {
    final subtasks = project.subtasks
        .where((subtask) => subtask.id != subtaskId)
        .toList();
    return _updateSubtasks(project.id, subtasks);
  }

  Future<void> _updateSubtasks(
    String projectId,
    List<ProjectSubtask> subtasks,
  ) {
    return _projects.doc(projectId).update({
      'subtasks': subtasks.map((subtask) => subtask.toFirestore()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
