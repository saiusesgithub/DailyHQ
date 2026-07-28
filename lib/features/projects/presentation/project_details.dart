import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/projects_repository.dart';
import '../domain/project.dart';
import '../domain/project_subtask.dart';
import 'project_form.dart';

Future<void> showProjectDetails({
  required BuildContext context,
  required ProjectsRepository repository,
  required Project project,
}) async {
  final details = ProjectDetails(
    repository: repository,
    projectId: project.id,
    initialProject: project,
  );

  if (MediaQuery.sizeOf(context).width < 800) {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => details));
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 680,
        height: math.min(MediaQuery.sizeOf(context).height * 0.9, 760),
        child: details,
      ),
    ),
  );
}

class ProjectDetails extends StatelessWidget {
  const ProjectDetails({
    required this.repository,
    required this.projectId,
    required this.initialProject,
    super.key,
  });

  final ProjectsRepository repository;
  final String projectId;
  final Project initialProject;

  Future<void> _addSubtask(BuildContext context, Project project) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              saving = true;
              error = null;
            });
            try {
              await repository.addSubtask(project, controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            } catch (exception) {
              setDialogState(() {
                saving = false;
                error = 'Could not add this subtask. $exception';
              });
            }
          }

          return AlertDialog(
            title: const Text('Add subtask'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    enabled: !saving,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Subtask *',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) {
                      if (!saving) save();
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a subtask.';
                      }
                      return null;
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  Future<void> _runMutation(
    BuildContext context,
    Future<void> Function() mutation,
    String failureMessage,
  ) async {
    try {
      await mutation();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failureMessage $error')));
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Project?>(
      stream: repository.watchProject(projectId),
      initialData: initialProject,
      builder: (context, snapshot) {
        final project = snapshot.data;
        if (project == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Project details'),
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            body: const Center(child: Text('This project no longer exists.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Project details'),
            automaticallyImplyLeading: false,
            actions: [
              TextButton.icon(
                onPressed: () => showProjectForm(
                  context: context,
                  repository: repository,
                  project: project,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Text(
                project.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _DetailValue(label: 'Status', value: project.status.label),
                  _DetailValue(
                    label: 'Priority',
                    value: project.priority.label,
                  ),
                  if (project.deadline != null)
                    _DetailValue(
                      label: 'Deadline',
                      value: _formatDate(context, project.deadline!),
                    ),
                  _DetailValue(
                    label: 'Created',
                    value: _formatDate(context, project.createdAt),
                  ),
                  _DetailValue(
                    label: 'Updated',
                    value: _formatDate(context, project.updatedAt),
                  ),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'Description',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  project.description,
                  style: const TextStyle(height: 1.5),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subtasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addSubtask(context, project),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add subtask'),
                  ),
                ],
              ),
              if (project.completion != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: project.completion,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 6),
                Text(
                  '${project.completedSubtaskCount} of '
                  '${project.subtasks.length} completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (project.subtasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No subtasks. Add them only when this project needs them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < project.subtasks.length;
                        index++
                      ) ...[
                        _SubtaskTile(
                          subtask: project.subtasks[index],
                          onToggle: () => _runMutation(
                            context,
                            () => repository.toggleSubtask(
                              project,
                              project.subtasks[index].id,
                            ),
                            'Could not update this subtask.',
                          ),
                          onDelete: () => _runMutation(
                            context,
                            () => repository.deleteSubtask(
                              project,
                              project.subtasks[index].id,
                            ),
                            'Could not delete this subtask.',
                          ),
                        ),
                        if (index != project.subtasks.length - 1)
                          Divider(
                            height: 1,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  const _SubtaskTile({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  final ProjectSubtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: subtask.isCompleted,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        subtask.title,
        style: TextStyle(
          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
          color: subtask.isCompleted
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      secondary: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline, size: 20),
        tooltip: 'Delete subtask',
      ),
    );
  }
}
