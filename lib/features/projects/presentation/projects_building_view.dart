import 'package:flutter/material.dart';

import '../data/projects_repository.dart';
import '../domain/project.dart';
import '../domain/project_ordering.dart';
import '../domain/project_priority.dart';
import '../domain/project_status.dart';
import 'project_details.dart';
import 'project_form.dart';

class ProjectsBuildingView extends StatefulWidget {
  const ProjectsBuildingView({
    required this.projects,
    required this.repository,
    super.key,
  });

  final List<Project> projects;
  final ProjectsRepository repository;

  @override
  State<ProjectsBuildingView> createState() => _ProjectsBuildingViewState();
}

class _ProjectsBuildingViewState extends State<ProjectsBuildingView> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final active = orderActiveProjects(
      widget.projects.where(
        (project) => project.status != ProjectStatus.completed,
      ),
    );
    final completed = orderCompletedProjects(
      widget.projects.where(
        (project) => project.status == ProjectStatus.completed,
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _ProjectSection(
          title: 'Building',
          emptyMessage: 'No projects are being built yet.',
          projects: active,
          repository: widget.repository,
        ),
        const SizedBox(height: 24),
        _ProjectSection(
          title: 'Completed',
          emptyMessage: 'No completed projects yet.',
          projects: completed,
          repository: widget.repository,
          collapsible: true,
          expanded: _showCompleted,
          onToggle: () => setState(() => _showCompleted = !_showCompleted),
        ),
      ],
    );
  }
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({
    required this.title,
    required this.emptyMessage,
    required this.projects,
    required this.repository,
    this.collapsible = false,
    this.expanded = true,
    this.onToggle,
  });

  final String title;
  final String emptyMessage;
  final List<Project> projects;
  final ProjectsRepository repository;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${projects.length}'),
                  ),
                  if (collapsible) ...[
                    const SizedBox(width: 8),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          if (projects.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emptyMessage,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProjectPreview(
                  project: project,
                  repository: repository,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

enum _ProjectAction { edit, delete }

class _ProjectPreview extends StatelessWidget {
  const _ProjectPreview({required this.project, required this.repository});

  final Project project;
  final ProjectsRepository repository;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this project?'),
        content: Text(
          'This permanently deletes “${project.name}” and its subtasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await repository.deleteProject(project.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete this project. $error')),
      );
    }
  }

  void _handleAction(BuildContext context, _ProjectAction action) {
    switch (action) {
      case _ProjectAction.edit:
        showProjectForm(
          context: context,
          repository: repository,
          project: project,
        );
      case _ProjectAction.delete:
        _delete(context);
    }
  }

  String? _deadlineLabel(BuildContext context) {
    final deadline = project.deadline;
    if (deadline == null) return null;
    return MaterialLocalizations.of(
      context,
    ).formatMediumDate(deadline.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deadline = _deadlineLabel(context);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showProjectDetails(
          context: context,
          repository: repository,
          project: project,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetadataLabel(
                          icon: project.status == ProjectStatus.completed
                              ? Icons.check_circle_outline
                              : Icons.construction_outlined,
                          text: project.status.label,
                        ),
                        if (deadline != null)
                          _MetadataLabel(
                            icon: Icons.calendar_today_outlined,
                            text: deadline,
                          ),
                        _PriorityBadge(priority: project.priority),
                      ],
                    ),
                    if (project.completion != null) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: project.completion,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${project.completedSubtaskCount} of '
                        '${project.subtasks.length} subtasks completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_ProjectAction>(
                tooltip: 'Project actions',
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ProjectAction.edit,
                    child: Text('Open / edit'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ProjectAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataLabel extends StatelessWidget {
  const _MetadataLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final ProjectPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      ProjectPriority.low => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      ProjectPriority.medium => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      ProjectPriority.high => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
