import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/projects_repository.dart';
import '../domain/project.dart';
import '../domain/project_idea.dart';
import '../domain/project_priority.dart';
import '../domain/project_status.dart';

Future<bool?> showProjectForm({
  required BuildContext context,
  required ProjectsRepository repository,
  ProjectIdea? idea,
  Project? project,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 800;
  final form = ProjectForm(
    repository: repository,
    idea: idea,
    project: project,
  );

  if (!isWide) {
    return Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => form));
  }

  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 620,
        height: math.min(MediaQuery.sizeOf(context).height * 0.88, 700),
        child: form,
      ),
    ),
  );
}

class ProjectForm extends StatefulWidget {
  const ProjectForm({
    required this.repository,
    this.idea,
    this.project,
    super.key,
  });

  final ProjectsRepository repository;
  final ProjectIdea? idea;
  final Project? project;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late ProjectStatus _status;
  late ProjectPriority _priority;
  DateTime? _deadline;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.project != null;
  bool get _isStartingIdea => widget.idea != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.project?.name ?? widget.idea?.name,
    );
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? widget.idea?.description,
    );
    _status = widget.project?.status ?? ProjectStatus.started;
    _priority = widget.project?.priority ?? ProjectPriority.medium;
    _deadline = widget.project?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) setState(() => _deadline = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      final existing = widget.project;
      final idea = widget.idea;
      if (existing != null) {
        await widget.repository.updateProject(
          existing.copyWith(
            name: name,
            description: description,
            status: _status,
            priority: _priority,
            deadline: _deadline,
            clearDeadline: _deadline == null,
          ),
        );
      } else if (idea != null) {
        await widget.repository.startBuilding(
          ideaId: idea.id,
          name: name,
          description: description,
          status: _status,
          priority: _priority,
          deadline: _deadline,
        );
      } else {
        await widget.repository.createProject(
          name: name,
          description: description,
          status: _status,
          priority: _priority,
          deadline: _deadline,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not save this project. $error';
      });
    }
  }

  String get _title {
    if (_isEditing) return 'Edit project';
    if (_isStartingIdea) return 'Start building';
    return 'Add project';
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_isSaving,
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a project name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProjectStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final status in ProjectStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: _isSaving
                  ? null
                  : (status) {
                      if (status != null) setState(() => _status = status);
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProjectPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final priority in ProjectPriority.values)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (priority) {
                      if (priority != null) {
                        setState(() => _priority = priority);
                      }
                    },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isSaving ? null : _pickDeadline,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Deadline',
                  border: const OutlineInputBorder(),
                  suffixIcon: _deadline == null
                      ? const Icon(Icons.calendar_today_outlined, size: 20)
                      : IconButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _deadline = null),
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Clear deadline',
                        ),
                ),
                child: Text(
                  _deadline == null ? 'Not set' : _formatDate(_deadline!),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colorScheme.error)),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isStartingIdea ? 'Start building' : 'Save project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
