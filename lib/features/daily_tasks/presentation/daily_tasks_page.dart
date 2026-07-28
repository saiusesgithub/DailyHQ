import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/daily_tasks_repository.dart';
import '../domain/daily_task.dart';
import '../domain/daily_task_priority.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({required this.userId, super.key});

  final String userId;

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  late final DailyTasksRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = DailyTasksRepository(userId: widget.userId);
  }

  Future<void> _addTask() async {
    final task = await showDialog<_TaskDraft>(
      context: context,
      builder: (context) => const _TaskDialog(),
    );
    if (task == null) return;

    try {
      await _repository.createTask(task.title, DateTime.now(), task.priority);
    } catch (error) {
      if (mounted) _showError('Could not add the task.', error);
    }
  }

  void _showError(String message, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message $error')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Daily tasks',
                  subtitle: 'Plan today and keep yesterday in view.',
                  action: FilledButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add task'),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<List<DailyTask>>(
                    stream: _repository.watchTasks(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _LoadError(error: snapshot.error);
                      }

                      return _TasksTimeline(
                        tasks: snapshot.data ?? const [],
                        repository: _repository,
                        onError: _showError,
                      );
                    },
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

class _TasksTimeline extends StatelessWidget {
  const _TasksTimeline({
    required this.tasks,
    required this.repository,
    required this.onError,
  });

  final List<DailyTask> tasks;
  final DailyTasksRepository repository;
  final void Function(String message, Object error) onError;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final todayTasks = tasks
        .where((task) => _isSameDay(task.plannedDate, today))
        .toList();
    final history = <DateTime, List<DailyTask>>{};

    for (final task in tasks) {
      final taskDate = _dateOnly(task.plannedDate.toLocal());
      if (taskDate.isBefore(today)) {
        history.putIfAbsent(taskDate, () => []).add(task);
      }
    }

    final historyDates = history.keys.toList()
      ..sort((first, second) => second.compareTo(first));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _DayCard(
          date: today,
          tasks: todayTasks,
          repository: repository,
          onError: onError,
          isToday: true,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'Previous days',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Text(
              '${historyDates.length}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (historyDates.isEmpty)
          _HistoryEmptyState()
        else
          for (final date in historyDates) ...[
            _DayCard(
              date: date,
              tasks: history[date]!,
              repository: repository,
              onError: onError,
              isToday: false,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _isSameDay(DateTime first, DateTime second) {
    final local = first.toLocal();
    return local.year == second.year &&
        local.month == second.month &&
        local.day == second.day;
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.tasks,
    required this.repository,
    required this.onError,
    required this.isToday,
  });

  final DateTime date;
  final List<DailyTask> tasks;
  final DailyTasksRepository repository;
  final void Function(String message, Object error) onError;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((task) => task.isCompleted).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final percentage = (progress * 100).round();
    final colorScheme = Theme.of(context).colorScheme;
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(date);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isToday ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isToday)
                        Text(
                          'Today',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      Text(
                        dateLabel,
                        style:
                            (isToday
                                    ? Theme.of(context).textTheme.bodyMedium
                                    : Theme.of(context).textTheme.titleSmall)
                                ?.copyWith(
                                  color: isToday
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                  fontWeight: isToday
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              tasks.isEmpty
                  ? 'No tasks yet'
                  : '$completed of ${tasks.length} completed',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 4),
              for (final task in tasks)
                _TaskRow(
                  task: task,
                  repository: repository,
                  isHistory: !isToday,
                  onError: onError,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _TaskAction { edit, delete }

class _TaskRow extends StatefulWidget {
  const _TaskRow({
    required this.task,
    required this.repository,
    required this.isHistory,
    required this.onError,
  });

  final DailyTask task;
  final DailyTasksRepository repository;
  final bool isHistory;
  final void Function(String message, Object error) onError;

  @override
  State<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<_TaskRow> {
  bool _isWorking = false;

  Future<void> _run(Future<void> Function() action, String errorMessage) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    try {
      await action();
    } catch (error) {
      widget.onError(errorMessage, error);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _handleAction(_TaskAction action) async {
    switch (action) {
      case _TaskAction.edit:
        final task = await showDialog<_TaskDraft>(
          context: context,
          builder: (context) => _TaskDialog(
            initialTitle: widget.task.title,
            initialPriority: widget.task.priority,
          ),
        );
        if (task != null) {
          await _run(
            () => widget.repository.updateTask(
              widget.task.id,
              task.title,
              task.priority,
            ),
            'Could not edit the task.',
          );
        }
        return;
      case _TaskAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text(
              '“${widget.task.title}” will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _run(
            () => widget.repository.deleteTask(widget.task.id),
            'Could not delete the task.',
          );
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: _isWorking
                    ? null
                    : (value) => _run(
                        () => widget.repository.setCompleted(
                          task.id,
                          value ?? false,
                        ),
                        'Could not update the task.',
                      ),
              ),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: task.isCompleted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PriorityBadge(priority: task.priority),
              PopupMenuButton<_TaskAction>(
                enabled: !_isWorking,
                tooltip: 'Task actions',
                onSelected: _handleAction,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _TaskAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _TaskAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          if (widget.isHistory && !task.isCompleted) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Align(
                alignment: Alignment.centerLeft,
                child: task.rolledOverAt == null
                    ? TextButton.icon(
                        onPressed: _isWorking
                            ? null
                            : () => _run(
                                () => widget.repository.doToday(task),
                                'Could not move the task to today.',
                              ),
                        icon: const Icon(Icons.redo, size: 17),
                        label: const Text('Do it today'),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          'Moved to today',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final DailyTaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      DailyTaskPriority.low => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      DailyTaskPriority.medium => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      DailyTaskPriority.high => (
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

class _TaskDraft {
  const _TaskDraft({required this.title, required this.priority});

  final String title;
  final DailyTaskPriority priority;
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    this.initialTitle = '',
    this.initialPriority = DailyTaskPriority.medium,
  });

  final String initialTitle;
  final DailyTaskPriority initialPriority;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _controller;
  late DailyTaskPriority _priority;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
    _priority = widget.initialPriority;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Enter a task.');
      return;
    }
    Navigator.pop(context, _TaskDraft(title: title, priority: _priority));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle.isEmpty ? 'Add task' : 'Edit task'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 160,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(labelText: 'Task', errorText: _error),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DailyTaskPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                for (final priority in DailyTaskPriority.values)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  ),
              ],
              onChanged: (priority) {
                if (priority != null) _priority = priority;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.initialTitle.isEmpty ? 'Add task' : 'Save'),
        ),
      ],
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Previous daily plans will appear here.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

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
            const Text(
              'Could not load daily tasks.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
