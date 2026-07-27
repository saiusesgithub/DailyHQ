import 'package:flutter/material.dart';

import '../data/todos_repository.dart';
import '../domain/todo_item.dart';
import '../domain/todo_subtask.dart';

class TodoSubtasksPanel extends StatefulWidget {
  const TodoSubtasksPanel({
    required this.repository,
    required this.todo,
    super.key,
  });

  final TodosRepository repository;
  final TodoItem todo;

  @override
  State<TodoSubtasksPanel> createState() => _TodoSubtasksPanelState();
}

class _TodoSubtasksPanelState extends State<TodoSubtasksPanel> {
  final _controller = TextEditingController();
  late List<TodoSubtask> _subtasks;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subtasks = [...widget.todo.subtasks];
  }

  @override
  void didUpdateWidget(TodoSubtasksPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSaving && oldWidget.todo.updatedAt != widget.todo.updatedAt) {
      _subtasks = [...widget.todo.subtasks];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _persist(List<TodoSubtask> subtasks) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.updateSubtasks(widget.todo.id, subtasks);
      if (!mounted) return;
      setState(() {
        _subtasks = subtasks;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not update subtasks. $error';
      });
    }
  }

  Future<void> _addSubtask() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _isSaving) return;
    final now = DateTime.now();
    await _persist([
      ..._subtasks,
      TodoSubtask(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        isCompleted: false,
        createdAt: now,
      ),
    ]);
    if (mounted && _error == null) _controller.clear();
  }

  Future<void> _toggle(TodoSubtask subtask) {
    return _persist(
      _subtasks
          .map(
            (item) => item.id == subtask.id
                ? item.copyWith(isCompleted: !item.isCompleted)
                : item,
          )
          .toList(),
    );
  }

  Future<void> _delete(TodoSubtask subtask) {
    return _persist(_subtasks.where((item) => item.id != subtask.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No subtasks yet.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final subtask in _subtasks)
              Row(
                children: [
                  SizedBox.square(
                    dimension: 36,
                    child: Checkbox(
                      value: subtask.isCompleted,
                      onChanged: _isSaving ? null : (_) => _toggle(subtask),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: subtask.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _isSaving ? null : () => _delete(subtask),
                    tooltip: 'Delete subtask',
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_isSaving,
                  maxLength: 160,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubtask(),
                  decoration: const InputDecoration(
                    hintText: 'Add a subtask',
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _isSaving ? null : _addSubtask,
                tooltip: 'Add subtask',
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 18),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
