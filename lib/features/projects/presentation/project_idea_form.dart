import 'package:flutter/material.dart';

import '../data/projects_repository.dart';

Future<bool?> showProjectIdeaForm({
  required BuildContext context,
  required ProjectsRepository repository,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _ProjectIdeaForm(repository: repository),
  );
}

class _ProjectIdeaForm extends StatefulWidget {
  const _ProjectIdeaForm({required this.repository});

  final ProjectsRepository repository;

  @override
  State<_ProjectIdeaForm> createState() => _ProjectIdeaFormState();
}

class _ProjectIdeaFormState extends State<_ProjectIdeaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.repository.createIdea(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not capture this idea. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Capture project idea'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Idea name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an idea name.';
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
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Capture idea'),
        ),
      ],
    );
  }
}
