import 'dart:async';

import 'package:flutter/material.dart';

import '../data/todos_repository.dart';
import '../domain/todo_item.dart';
import '../domain/todo_priority.dart';

Future<bool?> showTodoForm({
  required BuildContext context,
  required TodosRepository repository,
  TodoItem? todo,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _TodoForm(repository: repository, todo: todo),
  );
}

class _TodoForm extends StatefulWidget {
  const _TodoForm({required this.repository, this.todo});

  final TodosRepository repository;
  final TodoItem? todo;

  @override
  State<_TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<_TodoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late TodoPriority _priority;
  DateTime? _deadline;
  late bool _isImportant;
  late bool _isUrgent;
  bool _isSaving = false;
  String? _saveError;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _notesController = TextEditingController(text: todo?.notes ?? '');
    _priority = todo?.priority ?? TodoPriority.medium;
    _deadline = todo?.deadline;
    _isImportant = todo?.isImportant ?? false;
    _isUrgent = todo?.isUrgent ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) setState(() => _deadline = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final existing = widget.todo;
    final now = DateTime.now();
    final todo = TodoItem(
      id: existing?.id ?? '',
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      priority: _priority,
      deadline: _deadline,
      isImportant: _isImportant,
      isUrgent: _isUrgent,
      isCompleted: existing?.isCompleted ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: existing?.updatedAt ?? now,
      subtasks: existing?.subtasks ?? const [],
      isPinned: existing?.isPinned ?? false,
      movedToDailyDate: existing?.movedToDailyDate,
    );

    try {
      final save = existing == null
          ? widget.repository.createTodo(todo)
          : widget.repository.updateTodo(todo);
      await save.timeout(const Duration(seconds: 20));
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
        _saveError = 'Could not save this to-do. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _deadline == null
        ? ''
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(_deadline!.toLocal());

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                        _isEditing ? 'Edit to-do' : 'Add to-do',
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
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a title.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TodoPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    for (final priority in TodoPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(priority.label),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (priority) {
                          if (priority != null) _priority = priority;
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(dateText),
                  initialValue: dateText,
                  readOnly: true,
                  onTap: _isSaving ? null : _pickDeadline,
                  decoration: InputDecoration(
                    labelText: 'Deadline',
                    hintText: 'No deadline',
                    suffixIcon: _deadline == null
                        ? const Icon(Icons.calendar_today_outlined)
                        : IconButton(
                            onPressed: _isSaving
                                ? null
                                : () => setState(() => _deadline = null),
                            tooltip: 'Clear deadline',
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Important'),
                  subtitle: const Text('Meaningful impact or consequence'),
                  value: _isImportant,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _isImportant = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Urgent'),
                  subtitle: const Text('Needs attention soon'),
                  value: _isUrgent,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _isUrgent = value),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Add to-do'),
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
