import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/journal_repository.dart';
import '../domain/daily_journal.dart';
import '../domain/journal_time_block.dart';
import 'time_block_form.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({
    required this.userId,
    this.openCaptureOnLaunch = false,
    super.key,
  });

  final String userId;
  final bool openCaptureOnLaunch;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late final JournalRepository _repository;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  bool _didOpenCaptureOnLaunch = false;

  @override
  void initState() {
    super.initState();
    _repository = JournalRepository(userId: widget.userId);
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _dateOnly(_selectedDate.add(Duration(days: offset)));
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = _dateOnly(selected));
    }
  }

  Future<void> _addTimeBlock(DailyJournal? journal) async {
    final block = await showTimeBlockForm(
      context: context,
      initialStartMinutes: _latestEndMinutes(journal?.timeBlocks),
    );
    if (block == null) return;
    await _save(
      journal: journal,
      timeBlocks: [...?journal?.timeBlocks, block],
      errorMessage: 'Could not add the time block.',
    );
  }

  Future<void> _save({
    required DailyJournal? journal,
    required List<JournalTimeBlock> timeBlocks,
    required String errorMessage,
  }) async {
    try {
      await _repository.saveJournal(
        date: _selectedDate,
        timeBlocks: timeBlocks,
        exists: journal != null,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$errorMessage $error')));
    }
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
            child: StreamBuilder<DailyJournal?>(
              stream: _repository.watchJournal(_selectedDate),
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final journal = snapshot.data;
                if (widget.openCaptureOnLaunch &&
                    !_didOpenCaptureOnLaunch &&
                    !isLoading &&
                    !snapshot.hasError) {
                  _didOpenCaptureOnLaunch = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _addTimeBlock(journal);
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      title: 'Journal',
                      subtitle: 'Record your day and understand where it went.',
                      action: FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => _addTimeBlock(journal),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add time block'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DateNavigator(
                      date: _selectedDate,
                      onPrevious: () => _changeDay(-1),
                      onNext: () => _changeDay(1),
                      onPickDate: _pickDate,
                      onToday: () => setState(
                        () => _selectedDate = _dateOnly(DateTime.now()),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : snapshot.hasError
                          ? _LoadError(error: snapshot.error)
                          : _JournalDayView(
                              key: ValueKey(
                                '${_selectedDate.toIso8601String()}-'
                                '${journal?.updatedAt.microsecondsSinceEpoch}',
                              ),
                              journal: journal,
                              date: _selectedDate,
                              repository: _repository,
                              onSave: _save,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int? _latestEndMinutes(List<JournalTimeBlock>? blocks) {
    if (blocks == null || blocks.isEmpty) return null;

    return blocks
        .map((block) => block.endMinutes)
        .reduce((latest, end) => end > latest ? end : latest);
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
    required this.onToday,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).formatFullDate(date);
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Previous day',
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 17),
            label: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Next day',
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: onToday, child: const Text('Today')),
      ],
    );
  }
}

class _JournalDayView extends StatefulWidget {
  const _JournalDayView({
    required this.journal,
    required this.date,
    required this.repository,
    required this.onSave,
    super.key,
  });

  final DailyJournal? journal;
  final DateTime date;
  final JournalRepository repository;
  final Future<void> Function({
    required DailyJournal? journal,
    required List<JournalTimeBlock> timeBlocks,
    required String errorMessage,
  })
  onSave;

  @override
  State<_JournalDayView> createState() => _JournalDayViewState();
}

class _JournalDayViewState extends State<_JournalDayView> {
  Future<void> _editBlock(JournalTimeBlock block) async {
    final edited = await showTimeBlockForm(context: context, timeBlock: block);
    if (edited == null) return;
    final blocks =
        widget.journal?.timeBlocks
            .map((item) => item.id == block.id ? edited : item)
            .toList() ??
        [];
    await widget.onSave(
      journal: widget.journal,
      timeBlocks: blocks,
      errorMessage: 'Could not edit the time block.',
    );
  }

  Future<void> _deleteBlock(JournalTimeBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete time block?'),
        content: Text('“${block.activity}” will be removed from this journal.'),
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
    await widget.onSave(
      journal: widget.journal,
      timeBlocks:
          widget.journal?.timeBlocks
              .where((item) => item.id != block.id)
              .toList() ??
          [],
      errorMessage: 'Could not delete the time block.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.journal?.timeBlocks ?? const <JournalTimeBlock>[];
    return ListView(
      padding: const EdgeInsets.only(bottom: 36),
      children: [
        _Section(
          title: 'Time blocks',
          trailing: Text(
            '${blocks.length}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          child: blocks.isEmpty
              ? const _EmptyMessage(
                  icon: Icons.schedule_outlined,
                  message: 'No time blocks recorded for this day.',
                )
              : Column(
                  children: [
                    for (var index = 0; index < blocks.length; index++) ...[
                      _TimeBlockRow(
                        block: blocks[index],
                        onEdit: () => _editBlock(blocks[index]),
                        onDelete: () => _deleteBlock(blocks[index]),
                      ),
                      if (index != blocks.length - 1)
                        const Divider(height: 1, indent: 20),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 22),
        Text(
          'Time summary',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _CategoryCharts(blocks: blocks),
        if (widget.journal?.markdown.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _MarkdownPreview(markdown: widget.journal!.markdown),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _TimeBlockRow extends StatelessWidget {
  const _TimeBlockRow({
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalTimeBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatMinutes(block.startMinutes)}–'
                  '${_formatMinutes(block.endMinutes)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDuration(block.durationMinutes),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.activity,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (block.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    block.details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    block.category,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Time block actions',
            onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCharts extends StatelessWidget {
  const _CategoryCharts({required this.blocks});

  final List<JournalTimeBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final totals = <String, int>{};
    for (final block in blocks) {
      totals.update(
        block.category,
        (minutes) => minutes + block.durationMinutes,
        ifAbsent: () => block.durationMinutes,
      );
    }

    if (totals.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.pie_chart_outline,
        message: 'Charts will appear after you add time blocks.',
      );
    }

    final entries = totals.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final colors = _chartColors(Theme.of(context).colorScheme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final panels = [
          _PieChartPanel(entries: entries, colors: colors),
          _BarChartPanel(entries: entries, colors: colors),
        ];
        if (constraints.maxWidth < 760) {
          return Column(
            children: [panels.first, const SizedBox(height: 12), panels.last],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: panels.first),
            const SizedBox(width: 12),
            Expanded(child: panels.last),
          ],
        );
      },
    );
  }
}

class _PieChartPanel extends StatelessWidget {
  const _PieChartPanel({required this.entries, required this.colors});

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    return _ChartPanel(
      title: 'Share of recorded time',
      chart: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            centerSpaceRadius: 38,
            sectionsSpace: 2,
            sections: [
              for (var index = 0; index < entries.length; index++)
                PieChartSectionData(
                  value: entries[index].value.toDouble(),
                  color: colors[index % colors.length],
                  radius: 58,
                  title: '${(entries[index].value / total * 100).round()}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
      legend: _ChartLegend(entries: entries, colors: colors),
    );
  }
}

class _BarChartPanel extends StatelessWidget {
  const _BarChartPanel({required this.entries, required this.colors});

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = entries
        .map((entry) => entry.value)
        .reduce((first, second) => first > second ? first : second);
    final maxHours = (maxMinutes / 60).ceilToDouble().clamp(1, 24);

    return _ChartPanel(
      title: 'Hours by type',
      chart: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxHours.toDouble(),
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toStringAsFixed(0)}h',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var index = 0; index < entries.length; index++)
                BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entries[index].value / 60,
                      width: 20,
                      color: colors[index % colors.length],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      legend: _ChartLegend(entries: entries, colors: colors),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.chart,
    required this.legend,
  });

  final String title;
  final Widget chart;
  final Widget legend;

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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            chart,
            const SizedBox(height: 12),
            legend,
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.entries, required this.colors});

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 7,
      children: [
        for (var index = 0; index < entries.length; index++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${entries[index].key} · '
                '${_formatDuration(entries[index].value)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Formatted journal',
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: const Text('Show Markdown snapshot'),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(
              markdown,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
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
    return Center(child: Text('Could not load this journal. $error'));
  }
}

String _formatMinutes(int totalMinutes) {
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

List<Color> _chartColors(ColorScheme colorScheme) {
  return [
    colorScheme.primary,
    colorScheme.tertiary,
    const Color(0xFF3D8B79),
    const Color(0xFFC27A3A),
    const Color(0xFF8B67A8),
    const Color(0xFFB85450),
    const Color(0xFF4E7DA6),
    const Color(0xFF7C8744),
  ];
}
