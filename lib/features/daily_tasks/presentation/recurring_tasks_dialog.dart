import 'package:flutter/material.dart';

import '../data/daily_tasks_repository.dart';
import '../domain/daily_task_priority.dart';
import '../domain/recurring_daily_task.dart';

Future<void> showAddRecurringTaskDialog({
  required BuildContext context,
  required DailyTasksRepository repository,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _RecurringTaskForm(repository: repository),
  );
}

Future<void> showRecurringTasksDialog({
  required BuildContext context,
  required DailyTasksRepository repository,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _RecurringTasksManager(repository: repository),
  );
}

Future<void> showEditRecurringTaskDialog({
  required BuildContext context,
  required DailyTasksRepository repository,
  required RecurringDailyTask task,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _RecurringTaskForm(repository: repository, task: task),
  );
}

class _RecurringTaskForm extends StatefulWidget {
  const _RecurringTaskForm({required this.repository, this.task});

  final DailyTasksRepository repository;
  final RecurringDailyTask? task;

  @override
  State<_RecurringTaskForm> createState() => _RecurringTaskFormState();
}

class _RecurringTaskFormState extends State<_RecurringTaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DailyTaskPriority _priority;
  late RecurringTaskFrequency _frequency;
  late int _dayOfMonth;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _priority = task?.priority ?? DailyTaskPriority.medium;
    _frequency = task?.frequency ?? RecurringTaskFrequency.daily;
    _dayOfMonth = task?.dayOfMonth ?? DateTime.now().day;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final task = widget.task;
      if (task == null) {
        await widget.repository.createRecurringTask(
          title: _titleController.text.trim(),
          priority: _priority,
          frequency: _frequency,
          dayOfMonth: _frequency == RecurringTaskFrequency.monthly
              ? _dayOfMonth
              : null,
        );
      } else {
        await widget.repository.updateRecurringTask(
          recurringTaskId: task.id,
          title: _titleController.text.trim(),
          priority: _priority,
          frequency: _frequency,
          dayOfMonth: _frequency == RecurringTaskFrequency.monthly
              ? _dayOfMonth
              : null,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not save the recurring task. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.task == null ? 'Add recurring task' : 'Edit recurring task',
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Task *',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task.'
                      : null,
                ),
                const SizedBox(height: 14),
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
                  onChanged: _isSaving
                      ? null
                      : (priority) {
                          if (priority != null) _priority = priority;
                        },
                ),
                const SizedBox(height: 14),
                SegmentedButton<RecurringTaskFrequency>(
                  segments: const [
                    ButtonSegment(
                      value: RecurringTaskFrequency.daily,
                      label: Text('Daily'),
                      icon: Icon(Icons.today_outlined),
                    ),
                    ButtonSegment(
                      value: RecurringTaskFrequency.monthly,
                      label: Text('Monthly'),
                      icon: Icon(Icons.calendar_month_outlined),
                    ),
                  ],
                  selected: {_frequency},
                  onSelectionChanged: _isSaving
                      ? null
                      : (selection) =>
                            setState(() => _frequency = selection.single),
                ),
                if (_frequency == RecurringTaskFrequency.monthly) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _dayOfMonth,
                    decoration: const InputDecoration(
                      labelText: 'Day of month',
                      helperText:
                          'Days 29–31 use the last day of shorter months.',
                    ),
                    items: [
                      for (var day = 1; day <= 31; day++)
                        DropdownMenuItem(value: day, child: Text('Day $day')),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (day) {
                            if (day != null) _dayOfMonth = day;
                          },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
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
              : Text(widget.task == null ? 'Add recurring task' : 'Save'),
        ),
      ],
    );
  }
}

class _RecurringTasksManager extends StatelessWidget {
  const _RecurringTasksManager({required this.repository});

  final DailyTasksRepository repository;

  Future<void> _stop(BuildContext context, RecurringDailyTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop recurring task?'),
        content: Text(
          '“${task.title}” will no longer be added to future daily plans. '
          'Existing daily tasks will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop recurring'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await repository.stopRecurring(task.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not stop the recurring task. $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recurring tasks'),
      content: SizedBox(
        width: 520,
        height: 380,
        child: StreamBuilder<List<RecurringDailyTask>>(
          stream: repository.watchRecurringTasks(),
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load recurring tasks. ${snapshot.error}',
                ),
              );
            }

            final tasks = snapshot.data ?? const [];
            if (tasks.isEmpty) {
              return Center(
                child: Text(
                  'No recurring tasks yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    task.frequency == RecurringTaskFrequency.daily
                        ? Icons.today_outlined
                        : Icons.calendar_month_outlined,
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.scheduleLabel} · ${task.priority.label} priority',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => showEditRecurringTaskDialog(
                          context: context,
                          repository: repository,
                          task: task,
                        ),
                        tooltip: 'Edit recurring task',
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _stop(context, task),
                        tooltip: 'Stop recurring',
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => showAddRecurringTaskDialog(
            context: context,
            repository: repository,
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add recurring task'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
