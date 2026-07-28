import 'package:flutter/material.dart';

import '../data/projects_repository.dart';
import '../domain/project_idea.dart';
import 'project_form.dart';

class ProjectIdeasView extends StatelessWidget {
  const ProjectIdeasView({
    required this.ideas,
    required this.repository,
    required this.onStartedBuilding,
    super.key,
  });

  final List<ProjectIdea> ideas;
  final ProjectsRepository repository;
  final VoidCallback onStartedBuilding;

  Future<void> _startBuilding(BuildContext context, ProjectIdea idea) async {
    final started = await showProjectForm(
      context: context,
      repository: repository,
      idea: idea,
    );
    if (started == true) onStartedBuilding();
  }

  Future<void> _delete(BuildContext context, ProjectIdea idea) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this idea?'),
        content: Text('This permanently deletes “${idea.name}”.'),
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
      await repository.deleteIdea(idea.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete this idea. $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (ideas.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 32,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No project ideas captured yet.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capture an idea now and decide when it is ready to build.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: ideas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final idea = ideas[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (idea.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        idea.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _startBuilding(context, idea),
                      icon: const Icon(Icons.construction_outlined, size: 18),
                      label: const Text('Start building'),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _delete(context, idea),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete idea',
              ),
            ],
          ),
        );
      },
    );
  }
}
