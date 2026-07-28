import 'package:flutter/material.dart';

import '../data/todos_repository.dart';
import '../domain/todo_item.dart';
import '../domain/todo_subtask.dart';

Future<void> showTodoSubtasksDialog({
  required BuildContext context,
  required TodosRepository repository,
  required TodoItem todo,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _TodoSubtasksDialog(repository: repository, todo: todo),
  );
}

class _TodoSubtasksDialog extends StatefulWidget {
  const _TodoSubtasksDialog({required this.repository, required this.todo});

  final TodosRepository repository;
  final TodoItem todo;

  @override
  State<_TodoSubtasksDialog> createState() => _TodoSubtasksDialogState();
}

class _TodoSubtasksDialogState extends State<_TodoSubtasksDialog> {
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
    final completed = _subtasks.where((subtask) => subtask.isCompleted).length;
    final progress = _subtasks.isEmpty ? 0.0 : completed / _subtasks.length;

    return AlertDialog(
      title: Text('Subtasks · ${widget.todo.title}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_subtasks.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(progress * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Flexible(
              child: _subtasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No subtasks yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _subtasks.length,
                      itemBuilder: (context, index) {
                        final subtask = _subtasks[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: _isSaving
                                ? null
                                : (_) => _toggle(subtask),
                          ),
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: _isSaving
                                ? null
                                : () => _delete(subtask),
                            tooltip: 'Delete subtask',
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
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
                IconButton.filled(
                  onPressed: _isSaving ? null : _addSubtask,
                  tooltip: 'Add subtask',
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
