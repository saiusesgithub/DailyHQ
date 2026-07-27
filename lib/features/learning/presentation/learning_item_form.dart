import 'dart:async';

import 'package:flutter/material.dart';

import '../data/learning_repository.dart';
import '../domain/learning_item.dart';
import '../domain/learning_rating.dart';
import '../domain/learning_resource.dart';
import '../domain/learning_status.dart';

Future<bool?> showLearningItemForm({
  required BuildContext context,
  required LearningRepository repository,
  LearningItem? item,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _LearningItemForm(repository: repository, item: item),
  );
}

class _LearningItemForm extends StatefulWidget {
  const _LearningItemForm({required this.repository, this.item});

  final LearningRepository repository;
  final LearningItem? item;

  @override
  State<_LearningItemForm> createState() => _LearningItemFormState();
}

class _LearningItemFormState extends State<_LearningItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _areaController;
  late final TextEditingController _notesController;
  late final TextEditingController _planController;
  late LearningStatus _status;
  late LearningRating _priority;
  late LearningRating _usefulness;
  late List<_ResourceControllers> _resources;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _areaController = TextEditingController(text: item?.area ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _planController = TextEditingController(text: item?.plan ?? '');
    _status = item?.status ?? LearningStatus.toLearn;
    _priority = item?.priority ?? LearningRating.medium;
    _usefulness = item?.usefulness ?? LearningRating.medium;
    _resources = [
      for (final resource in item?.resources ?? const <LearningResource>[])
        _ResourceControllers(resource: resource),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    _planController.dispose();
    for (final resource in _resources) {
      resource.dispose();
    }
    super.dispose();
  }

  void _addResource() {
    setState(() => _resources.add(_ResourceControllers()));
  }

  void _removeResource(int index) {
    final resource = _resources.removeAt(index);
    resource.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final existing = widget.item;
    final now = DateTime.now();
    final resources = [
      for (final resource in _resources)
        LearningResource(
          label: resource.label.text.trim().isEmpty
              ? Uri.parse(resource.url.text.trim()).host
              : resource.label.text.trim(),
          url: resource.url.text.trim(),
        ),
    ];
    final item = LearningItem(
      id: existing?.id ?? '',
      title: _titleController.text.trim(),
      area: _areaController.text.trim(),
      notes: _notesController.text.trim(),
      plan: _planController.text.trim(),
      status: _status,
      priority: _priority,
      usefulness: _usefulness,
      resources: resources,
      createdAt: existing?.createdAt ?? now,
      updatedAt: existing?.updatedAt ?? now,
    );

    try {
      final operation = existing == null
          ? widget.repository.createItem(item)
          : widget.repository.updateItem(item);
      await operation.timeout(const Duration(seconds: 20));
      if (mounted) Navigator.pop(context, true);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError =
            'The save is taking too long. Check your connection and try again.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Could not save this learning item. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item == null
                            ? 'Add something to learn'
                            : 'Edit learning item',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'What do you want to learn? *',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a topic.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area',
                    hintText: 'DSA, German, AWS…',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    hintText: 'Why this matters or what to cover',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _planController,
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Study plan',
                    alignLabelWithHint: true,
                    hintText:
                        '1. Learn the fundamentals\n2. Build something small\n3. Review and practice',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LearningStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final status in LearningStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (status) {
                          if (status != null) _status = status;
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LearningRating>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    for (final rating in LearningRating.values)
                      DropdownMenuItem(
                        value: rating,
                        child: Text(rating.label),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (rating) {
                          if (rating != null) _priority = rating;
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LearningRating>(
                  initialValue: _usefulness,
                  decoration: const InputDecoration(labelText: 'Usefulness'),
                  items: [
                    for (final rating in LearningRating.values)
                      DropdownMenuItem(
                        value: rating,
                        child: Text(rating.label),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (rating) {
                          if (rating != null) _usefulness = rating;
                        },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Resources',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isSaving ? null : _addResource,
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('Add link'),
                    ),
                  ],
                ),
                for (var index = 0; index < _resources.length; index++) ...[
                  const SizedBox(height: 10),
                  _ResourceFields(
                    controllers: _resources[index],
                    enabled: !_isSaving,
                    onRemove: () => _removeResource(index),
                  ),
                ],
                if (_saveError != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.item == null ? 'Add topic' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceControllers {
  _ResourceControllers({LearningResource? resource})
    : label = TextEditingController(text: resource?.label ?? ''),
      url = TextEditingController(text: resource?.url ?? '');

  final TextEditingController label;
  final TextEditingController url;

  void dispose() {
    label.dispose();
    url.dispose();
  }
}

class _ResourceFields extends StatelessWidget {
  const _ResourceFields({
    required this.controllers,
    required this.enabled,
    required this.onRemove,
  });

  final _ResourceControllers controllers;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers.label,
                    enabled: enabled,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      hintText: 'Course, documentation…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: enabled ? onRemove : null,
                  tooltip: 'Remove resource',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: controllers.url,
              enabled: enabled,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL *',
                hintText: 'https://…',
              ),
              validator: (value) {
                final uri = Uri.tryParse(value?.trim() ?? '');
                if (uri == null ||
                    !uri.hasAuthority ||
                    (uri.scheme != 'http' && uri.scheme != 'https')) {
                  return 'Enter a valid http or https URL.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
