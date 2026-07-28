import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/projects_repository.dart';
import '../domain/project.dart';
import '../domain/project_idea.dart';
import 'project_form.dart';
import 'project_idea_form.dart';
import 'project_ideas_view.dart';
import 'projects_building_view.dart';

enum _ProjectsView { building, ideas }

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({required this.userId, super.key});

  final String userId;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final ProjectsRepository _repository;
  _ProjectsView _selectedView = _ProjectsView.building;

  @override
  void initState() {
    super.initState();
    _repository = ProjectsRepository(userId: widget.userId);
  }

  Future<void> _primaryAction() {
    return switch (_selectedView) {
      _ProjectsView.ideas => showProjectIdeaForm(
        context: context,
        repository: _repository,
      ),
      _ProjectsView.building => showProjectForm(
        context: context,
        repository: _repository,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Projects',
                  subtitle: 'Capture ideas and track what you are building.',
                  action: FilledButton.icon(
                    onPressed: _primaryAction,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      _selectedView == _ProjectsView.ideas
                          ? 'Capture idea'
                          : 'Add project',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<_ProjectsView>(
                    segments: const [
                      ButtonSegment(
                        value: _ProjectsView.building,
                        icon: Icon(Icons.construction_outlined),
                        label: Text('Building'),
                      ),
                      ButtonSegment(
                        value: _ProjectsView.ideas,
                        icon: Icon(Icons.lightbulb_outline),
                        label: Text('Ideas'),
                      ),
                    ],
                    selected: {_selectedView},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedView = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: switch (_selectedView) {
                    _ProjectsView.ideas => StreamBuilder<List<ProjectIdea>>(
                      stream: _repository.watchIdeas(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _LoadError(
                            message: 'Could not load project ideas.',
                            error: snapshot.error,
                          );
                        }
                        return ProjectIdeasView(
                          ideas: snapshot.data ?? const [],
                          repository: _repository,
                          onStartedBuilding: () {
                            setState(
                              () => _selectedView = _ProjectsView.building,
                            );
                          },
                        );
                      },
                    ),
                    _ProjectsView.building => StreamBuilder<List<Project>>(
                      stream: _repository.watchProjects(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _LoadError(
                            message: 'Could not load projects.',
                            error: snapshot.error,
                          );
                        }
                        return ProjectsBuildingView(
                          projects: snapshot.data ?? const [],
                          repository: _repository,
                        );
                      },
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.error});

  final String message;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
