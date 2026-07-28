import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/thoughts_repository.dart';
import '../domain/thought_day.dart';

class ThoughtsPage extends StatefulWidget {
  const ThoughtsPage({required this.userId, super.key});

  final String userId;

  @override
  State<ThoughtsPage> createState() => _ThoughtsPageState();
}

class _ThoughtsPageState extends State<ThoughtsPage> {
  late final ThoughtsRepository _repository;
  final _captureController = TextEditingController();
  final _captureFocusNode = FocusNode();
  late DateTime _selectedDate;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _repository = ThoughtsRepository(userId: widget.userId);
    _selectedDate = _dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _captureController.dispose();
    _captureFocusNode.dispose();
    super.dispose();
  }

  Future<void> _captureThought() async {
    final thought = _captureController.text.trim();
    if (thought.isEmpty || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      await _repository.appendThought(date: DateTime.now(), thought: thought);
      _captureController.clear();
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _selectedDate = _dateOnly(DateTime.now());
        });
        _captureFocusNode.requestFocus();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not capture this thought. $error')),
      );
    }
  }

  Future<void> _editMarkdown(ThoughtDay? day) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _MarkdownEditorDialog(
        repository: _repository,
        date: _selectedDate,
        initialMarkdown: day?.markdown ?? '',
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
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
                const PageHeader(
                  title: 'Thoughts',
                  subtitle: 'Capture now. Organize only when you need to.',
                ),
                const SizedBox(height: 20),
                _QuickCapture(
                  controller: _captureController,
                  focusNode: _captureFocusNode,
                  isSaving: _isCapturing,
                  onCapture: _captureThought,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<ThoughtDay>>(
                    stream: _repository.watchThoughtDays(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _LoadError(error: snapshot.error);
                      }

                      final days = snapshot.data ?? const [];
                      final selectedDay = _findDay(days, _selectedDate);
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 760;
                          final viewer = _ThoughtDayViewer(
                            day: selectedDay,
                            date: _selectedDate,
                            showHistoryButton: !isWide,
                            onEdit: () => _editMarkdown(selectedDay),
                            onShowHistory: () => _showHistorySheet(days),
                          );

                          if (!isWide) return viewer;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 230,
                                child: _ThoughtHistory(
                                  days: days,
                                  selectedDate: _selectedDate,
                                  onSelected: _selectDate,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: viewer),
                            ],
                          );
                        },
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

  Future<void> _showHistorySheet(List<ThoughtDay> days) async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 480,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ThoughtHistory(
              days: days,
              selectedDate: _selectedDate,
              onSelected: (date) => Navigator.pop(context, date),
            ),
          ),
        ),
      ),
    );
    if (selected != null) _selectDate(selected);
  }

  static ThoughtDay? _findDay(List<ThoughtDay> days, DateTime date) {
    for (final day in days) {
      if (_isSameDay(day.date, date)) return day;
    }
    return null;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _QuickCapture extends StatelessWidget {
  const _QuickCapture({
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.onCapture,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;
  final VoidCallback onCapture;

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
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    control: true,
                  ): onCapture,
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isSaving,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What’s on your mind?',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: isSaving ? null : onCapture,
              tooltip: 'Capture thought (Ctrl+Enter)',
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_upward, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThoughtHistory extends StatelessWidget {
  const _ThoughtHistory({
    required this.days,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<ThoughtDay> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final datedEntries = [
      _HistoryEntry(date: today, day: _findDay(today)),
      for (final day in days)
        if (!_isSameDay(day.date, today))
          _HistoryEntry(date: day.date, day: day),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Text(
            'Daily files',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: datedEntries.length,
            itemBuilder: (context, index) {
              final entry = datedEntries[index];
              final selected = _isSameDay(entry.date, selectedDate);
              return ListTile(
                selected: selected,
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: Icon(
                  entry.day == null
                      ? Icons.note_add_outlined
                      : Icons.description_outlined,
                  size: 19,
                ),
                title: Text(
                  _isSameDay(entry.date, today)
                      ? 'Today'
                      : MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(entry.date),
                ),
                subtitle: Text(_fileName(entry.date)),
                onTap: () => onSelected(entry.date),
              );
            },
          ),
        ),
      ],
    );
  }

  ThoughtDay? _findDay(DateTime date) {
    for (final day in days) {
      if (_isSameDay(day.date, date)) return day;
    }
    return null;
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.date, required this.day});

  final DateTime date;
  final ThoughtDay? day;
}

class _ThoughtDayViewer extends StatelessWidget {
  const _ThoughtDayViewer({
    required this.day,
    required this.date,
    required this.showHistoryButton,
    required this.onEdit,
    required this.onShowHistory,
  });

  final ThoughtDay? day;
  final DateTime date;
  final bool showHistoryButton;
  final VoidCallback onEdit;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MaterialLocalizations.of(context).formatFullDate(date),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fileName(date),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (showHistoryButton)
                  IconButton(
                    onPressed: onShowHistory,
                    tooltip: 'Previous days',
                    icon: const Icon(Icons.history),
                  ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Markdown'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: day == null || day!.markdown.trim().isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No thoughts captured for this day.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SelectableText(
                      day!.markdown,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.55,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownEditorDialog extends StatefulWidget {
  const _MarkdownEditorDialog({
    required this.repository,
    required this.date,
    required this.initialMarkdown,
  });

  final ThoughtsRepository repository;
  final DateTime date;
  final String initialMarkdown;

  @override
  State<_MarkdownEditorDialog> createState() => _MarkdownEditorDialogState();
}

class _MarkdownEditorDialogState extends State<_MarkdownEditorDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMarkdown);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.saveMarkdown(
        date: widget.date,
        markdown: _controller.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not save this file. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileName(widget.date),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'Write Markdown…',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ],
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
        child: Text(
          'Could not load thoughts. $error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _fileName(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day.md';
}
