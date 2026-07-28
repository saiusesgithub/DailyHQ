import 'package:flutter/material.dart';

import '../domain/journal_time_block.dart';

Future<JournalTimeBlock?> showTimeBlockForm({
  required BuildContext context,
  JournalTimeBlock? timeBlock,
}) {
  return showDialog<JournalTimeBlock>(
    context: context,
    builder: (context) => _TimeBlockForm(timeBlock: timeBlock),
  );
}

class _TimeBlockForm extends StatefulWidget {
  const _TimeBlockForm({this.timeBlock});

  final JournalTimeBlock? timeBlock;

  @override
  State<_TimeBlockForm> createState() => _TimeBlockFormState();
}

class _TimeBlockFormState extends State<_TimeBlockForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _activityController;
  late final TextEditingController _detailsController;
  late final TextEditingController _categoryController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    final block = widget.timeBlock;
    final now = TimeOfDay.now();
    final startMinutes = block?.startMinutes ?? now.hour * 60 + now.minute;
    final defaultEnd = (startMinutes + 30).clamp(0, 1439);
    _startTime = _fromMinutes(startMinutes);
    _endTime = _fromMinutes(block?.endMinutes ?? defaultEnd);
    _activityController = TextEditingController(text: block?.activity ?? '');
    _detailsController = TextEditingController(text: block?.details ?? '');
    _categoryController = TextEditingController(text: block?.category ?? '');
  }

  @override
  void dispose() {
    _activityController.dispose();
    _detailsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
      _timeError = null;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final startMinutes = _toMinutes(_startTime);
    final endMinutes = _toMinutes(_endTime);
    if (endMinutes <= startMinutes) {
      setState(() => _timeError = 'End time must be after start time.');
      return;
    }

    Navigator.pop(
      context,
      JournalTimeBlock(
        id:
            widget.timeBlock?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        activity: _activityController.text.trim(),
        details: _detailsController.text.trim(),
        category: _categoryController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        widget.timeBlock == null
                            ? 'Add time block'
                            : 'Edit time block',
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
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Start',
                        time: _startTime,
                        onTap: () => _pickTime(start: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeField(
                        label: 'End',
                        time: _endTime,
                        onTap: () => _pickTime(start: false),
                      ),
                    ),
                  ],
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _timeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _activityController,
                  autofocus: true,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Activity *',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an activity.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    hintText: 'Coding, Productivity, Break…',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a type.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _detailsController,
                  minLines: 3,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    alignLabelWithHint: true,
                    hintText: 'What happened during this block?',
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(
                      widget.timeBlock == null ? 'Add block' : 'Save changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  static TimeOfDay _fromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-${time.hour}-${time.minute}'),
      initialValue: time.format(context),
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.schedule),
      ),
    );
  }
}
