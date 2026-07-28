import 'package:daily_hq/features/projects/domain/project.dart';
import 'package:daily_hq/features/projects/domain/project_ordering.dart';
import 'package:daily_hq/features/projects/domain/project_priority.dart';
import 'package:daily_hq/features/projects/domain/project_status.dart';
import 'package:daily_hq/features/projects/domain/project_subtask.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project completion is absent without subtasks', () {
    expect(_project(id: 'empty').completion, isNull);
  });

  test('project completion is calculated from checked subtasks', () {
    final project = _project(
      id: 'tracked',
      subtasks: [
        _subtask('one', completed: true),
        _subtask('two'),
        _subtask('three', completed: true),
        _subtask('four'),
      ],
    );

    expect(project.completedSubtaskCount, 2);
    expect(project.completion, 0.5);
  });

  test('active projects put earlier deadlines before undated projects', () {
    final projects = [
      _project(id: 'undated', updatedDay: 20),
      _project(id: 'later', deadlineDay: 25),
      _project(id: 'earlier', deadlineDay: 10),
    ];

    expect(orderActiveProjects(projects).map((project) => project.id), [
      'earlier',
      'later',
      'undated',
    ]);
  });
}

Project _project({
  required String id,
  int? deadlineDay,
  int updatedDay = 1,
  List<ProjectSubtask> subtasks = const [],
}) {
  return Project(
    id: id,
    name: id,
    description: '',
    status: ProjectStatus.started,
    priority: ProjectPriority.medium,
    deadline: deadlineDay == null ? null : DateTime(2026, 7, deadlineDay),
    subtasks: subtasks,
    createdAt: DateTime(2026, 7),
    updatedAt: DateTime(2026, 7, updatedDay),
  );
}

ProjectSubtask _subtask(String id, {bool completed = false}) {
  return ProjectSubtask(
    id: id,
    title: id,
    isCompleted: completed,
    createdAt: DateTime(2026, 7),
  );
}
