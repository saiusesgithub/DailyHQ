import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/todos_repository.dart';
import '../domain/todo_item.dart';
import '../domain/todo_priority.dart';
import 'todo_form.dart';
import 'todo_subtasks_panel.dart';

enum _TodosView { list, matrix }

class TodosPage extends StatefulWidget {
  const TodosPage({required this.userId, super.key});

  final String userId;

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late final TodosRepository _repository;
  _TodosView _selectedView = _TodosView.list;

  @override
  void initState() {
    super.initState();
    _repository = TodosRepository(userId: widget.userId);
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
                  title: 'To-do list',
                  subtitle: 'Keep track of work without assigning it to a day.',
                  action: FilledButton.icon(
                    onPressed: () =>
                        showTodoForm(context: context, repository: _repository),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add to-do'),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<_TodosView>(
                    segments: const [
                      ButtonSegment(
                        value: _TodosView.list,
                        icon: Icon(Icons.view_list_outlined),
                        label: Text('List'),
                      ),
                      ButtonSegment(
                        value: _TodosView.matrix,
                        icon: Icon(Icons.grid_view_outlined),
                        label: Text('Eisenhower matrix'),
                      ),
                    ],
                    selected: {_selectedView},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedView = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<TodoItem>>(
                    stream: _repository.watchTodos(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _LoadError(error: snapshot.error);
                      }

                      final todos = snapshot.data ?? const [];
                      return switch (_selectedView) {
                        _TodosView.list => _TodosList(
                          todos: todos,
                          repository: _repository,
                        ),
                        _TodosView.matrix => _EisenhowerMatrix(
                          todos: todos,
                          repository: _repository,
                        ),
                      };
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

class _TodosList extends StatefulWidget {
  const _TodosList({required this.todos, required this.repository});

  final List<TodoItem> todos;
  final TodosRepository repository;

  @override
  State<_TodosList> createState() => _TodosListState();
}

class _TodosListState extends State<_TodosList> {
  bool _showCompleted = false;
  late List<TodoItem> _active;

  @override
  void initState() {
    super.initState();
    _syncActive();
  }

  @override
  void didUpdateWidget(_TodosList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncActive();
  }

  void _syncActive() {
    _active = widget.todos.where((todo) => !todo.isCompleted).toList();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final todo = _active.removeAt(oldIndex);
      _active.insert(newIndex, todo);
    });
    try {
      await widget.repository.reorderTodos(_active);
    } catch (error) {
      if (!mounted) return;
      _syncActive();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the new order. $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todos = widget.todos;
    if (todos.isEmpty) {
      return const _EmptyTodos(
        icon: Icons.checklist_outlined,
        message: 'No to-dos yet.',
      );
    }

    final active = _active;
    final completed = todos.where((todo) => todo.isCompleted).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${active.length} remaining · ${todos.length} total',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: active.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No active to-dos.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: _reorder,
                  itemCount: active.length,
                  itemBuilder: (context, index) => Column(
                    key: ValueKey(active[index].id),
                    children: [
                      _TodoRow(
                        todo: active[index],
                        repository: widget.repository,
                        reorderIndex: index,
                      ),
                      if (index != active.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ),
                ),
        ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _showCompleted = !_showCompleted),
                  leading: Icon(
                    _showCompleted ? Icons.expand_more : Icons.chevron_right,
                  ),
                  title: const Text(
                    'Completed',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text('${completed.length}'),
                ),
                if (_showCompleted) ...[
                  const Divider(height: 1),
                  for (var index = 0; index < completed.length; index++) ...[
                    _TodoRow(
                      todo: completed[index],
                      repository: widget.repository,
                    ),
                    if (index != completed.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EisenhowerMatrix extends StatelessWidget {
  const _EisenhowerMatrix({required this.todos, required this.repository});

  final List<TodoItem> todos;
  final TodosRepository repository;

  @override
  Widget build(BuildContext context) {
    final quadrants = [
      _Quadrant(
        title: 'Important · Urgent',
        guidance: 'Do first',
        icon: Icons.priority_high,
        todos: _matching(important: true, urgent: true),
      ),
      _Quadrant(
        title: 'Important · Not urgent',
        guidance: 'Schedule',
        icon: Icons.event_outlined,
        todos: _matching(important: true, urgent: false),
      ),
      _Quadrant(
        title: 'Not important · Urgent',
        guidance: 'Handle or delegate',
        icon: Icons.forward_to_inbox_outlined,
        todos: _matching(important: false, urgent: true),
      ),
      _Quadrant(
        title: 'Not important · Not urgent',
        guidance: 'Later',
        icon: Icons.low_priority_outlined,
        todos: _matching(important: false, urgent: false),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth >= 760;
        final width = useColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final quadrant in quadrants)
                  SizedBox(
                    width: width,
                    child: _QuadrantPanel(
                      quadrant: quadrant,
                      repository: repository,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<TodoItem> _matching({required bool important, required bool urgent}) {
    return todos
        .where(
          (todo) =>
              !todo.isCompleted &&
              todo.isImportant == important &&
              todo.isUrgent == urgent,
        )
        .toList();
  }
}

class _Quadrant {
  const _Quadrant({
    required this.title,
    required this.guidance,
    required this.icon,
    required this.todos,
  });

  final String title;
  final String guidance;
  final IconData icon;
  final List<TodoItem> todos;
}

class _QuadrantPanel extends StatelessWidget {
  const _QuadrantPanel({required this.quadrant, required this.repository});

  final _Quadrant quadrant;
  final TodosRepository repository;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(quadrant.icon, size: 19, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quadrant.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${quadrant.todos.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              quadrant.guidance,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (quadrant.todos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'No to-dos here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              for (var index = 0; index < quadrant.todos.length; index++) ...[
                _TodoRow(
                  todo: quadrant.todos[index],
                  repository: repository,
                  compact: true,
                ),
                if (index != quadrant.todos.length - 1)
                  const Divider(height: 1, indent: 48),
              ],
          ],
        ),
      ),
    );
  }
}

enum _TodoAction { edit, addToToday, addToTomorrow, togglePin, delete }

class _TodoRow extends StatefulWidget {
  const _TodoRow({
    required this.todo,
    required this.repository,
    this.compact = false,
    this.reorderIndex,
  });

  final TodoItem todo;
  final TodosRepository repository;
  final bool compact;
  final int? reorderIndex;

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> {
  bool _isWorking = false;
  bool _showSubtasks = false;

  Future<void> _setCompleted(bool value) async {
    setState(() => _isWorking = true);
    try {
      await widget.repository.setCompleted(widget.todo, value);
    } catch (error) {
      _showError('Could not update this to-do. $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _handleAction(_TodoAction action) async {
    switch (action) {
      case _TodoAction.edit:
        await showTodoForm(
          context: context,
          repository: widget.repository,
          todo: widget.todo,
        );
        return;
      case _TodoAction.addToToday:
        setState(() => _isWorking = true);
        try {
          await widget.repository.addToDailyPlan(widget.todo, DateTime.now());
          if (mounted) setState(() => _isWorking = false);
        } catch (error) {
          _showError('Could not add this to today. $error');
          if (mounted) setState(() => _isWorking = false);
        }
        return;
      case _TodoAction.addToTomorrow:
        setState(() => _isWorking = true);
        try {
          await widget.repository.addToDailyPlan(
            widget.todo,
            DateTime.now().add(const Duration(days: 1)),
          );
          if (mounted) setState(() => _isWorking = false);
        } catch (error) {
          _showError('Could not add this to tomorrow. $error');
          if (mounted) setState(() => _isWorking = false);
        }
        return;
      case _TodoAction.togglePin:
        setState(() => _isWorking = true);
        try {
          await widget.repository.setPinned(
            widget.todo.id,
            !widget.todo.isPinned,
          );
          if (mounted) setState(() => _isWorking = false);
        } catch (error) {
          _showError('Could not update the pin. $error');
          if (mounted) setState(() => _isWorking = false);
        }
        return;
      case _TodoAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete to-do?'),
            content: Text(
              '“${widget.todo.title}” will be permanently deleted.',
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
        if (confirmed != true) return;
        setState(() => _isWorking = true);
        try {
          await widget.repository.deleteTodo(widget.todo.id);
        } catch (error) {
          _showError('Could not delete this to-do. $error');
          if (mounted) setState(() => _isWorking = false);
        }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final colorScheme = Theme.of(context).colorScheme;
    final deadline = todo.deadline == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(todo.deadline!.toLocal());
    final completedSubtasks = todo.subtasks
        .where((subtask) => subtask.isCompleted)
        .length;
    final subtaskProgress = todo.subtasks.isEmpty
        ? 0.0
        : completedSubtasks / todo.subtasks.length;
    final movedToday = _isToday(todo.movedToDailyDate);
    final movedTomorrow = _isTomorrow(todo.movedToDailyDate);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 0 : 10,
        vertical: widget.compact ? 5 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: todo.isCompleted,
            onChanged: _isWorking
                ? null
                : (value) => _setCompleted(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (todo.isPinned) ...[
                        Icon(
                          Icons.push_pin,
                          size: 15,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          todo.title,
                          maxLines: widget.compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: todo.isCompleted
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (!widget.compact && todo.notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      todo.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _PriorityBadge(priority: todo.priority),
                      if (movedToday)
                        const _Metadata(
                          icon: Icons.today_outlined,
                          label: 'In today’s plan',
                        ),
                      if (movedTomorrow)
                        const _Metadata(
                          icon: Icons.event_outlined,
                          label: 'In tomorrow’s plan',
                        ),
                      if (deadline != null)
                        _Metadata(icon: Icons.event_outlined, label: deadline),
                      if (!widget.compact)
                        _Metadata(
                          icon: _matrixIcon(todo),
                          label: _matrixLabel(todo),
                        ),
                    ],
                  ),
                  if (todo.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: subtaskProgress,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(subtaskProgress * 100).round()}% · '
                          '$completedSubtasks/${todo.subtasks.length}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showSubtasks = !_showSubtasks),
                    icon: Icon(
                      _showSubtasks ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      todo.subtasks.isEmpty
                          ? 'Add subtasks'
                          : 'Subtasks (${todo.subtasks.length})',
                    ),
                  ),
                  if (_showSubtasks)
                    TodoSubtasksPanel(
                      key: ValueKey(todo.id),
                      repository: widget.repository,
                      todo: todo,
                    ),
                ],
              ),
            ),
          ),
          if (widget.reorderIndex case final index?)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: IconButton(
                  onPressed: null,
                  tooltip: 'Drag to reorder',
                  icon: Icon(Icons.drag_indicator),
                ),
              ),
            ),
          PopupMenuButton<_TodoAction>(
            enabled: !_isWorking,
            tooltip: 'To-do actions',
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: _TodoAction.edit, child: Text('Edit')),
              if (!todo.isCompleted)
                const PopupMenuItem(
                  value: _TodoAction.addToToday,
                  child: Text('Add to today'),
                ),
              if (!todo.isCompleted)
                const PopupMenuItem(
                  value: _TodoAction.addToTomorrow,
                  child: Text('Add to tomorrow'),
                ),
              PopupMenuItem(
                value: _TodoAction.togglePin,
                child: Text(todo.isPinned ? 'Unpin' : 'Pin'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _TodoAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _matrixLabel(TodoItem todo) {
    if (todo.isImportant && todo.isUrgent) return 'Important · Urgent';
    if (todo.isImportant) return 'Important · Not urgent';
    if (todo.isUrgent) return 'Not important · Urgent';
    return 'Not important · Not urgent';
  }

  static IconData _matrixIcon(TodoItem todo) {
    if (todo.isImportant && todo.isUrgent) return Icons.priority_high;
    if (todo.isImportant) return Icons.star_outline;
    if (todo.isUrgent) return Icons.schedule;
    return Icons.low_priority_outlined;
  }

  static bool _isToday(DateTime? date) {
    if (date == null) return false;
    final local = date.toLocal();
    final today = DateTime.now();
    return local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
  }

  static bool _isTomorrow(DateTime? date) {
    if (date == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final local = date.toLocal();
    return local.year == tomorrow.year &&
        local.month == tomorrow.month &&
        local.day == tomorrow.day;
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      TodoPriority.low => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      TodoPriority.medium => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      TodoPriority.high => (
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

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _EmptyTodos extends StatelessWidget {
  const _EmptyTodos({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
              'Could not load to-dos.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
