import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/learning_repository.dart';
import '../domain/learning_item.dart';
import '../domain/learning_rating.dart';
import '../domain/learning_status.dart';
import 'learning_item_form.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({required this.userId, super.key});

  final String userId;

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  late final LearningRepository _repository;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _repository = LearningRepository(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Learning',
                  subtitle: 'Keep a practical list of what is worth learning.',
                  action: FilledButton.icon(
                    onPressed: () => showLearningItemForm(
                      context: context,
                      repository: _repository,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add topic'),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<List<LearningItem>>(
                    stream: _repository.watchItems(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _LoadError(error: snapshot.error);
                      }

                      final items = snapshot.data ?? const [];
                      final learning = items
                          .where(
                            (item) => item.status == LearningStatus.learning,
                          )
                          .toList();
                      final toLearn = items
                          .where(
                            (item) => item.status == LearningStatus.toLearn,
                          )
                          .toList();
                      final completed = items
                          .where(
                            (item) => item.status == LearningStatus.completed,
                          )
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          _LearningSection(
                            title: 'Learning now',
                            items: learning,
                            emptyMessage: 'Nothing actively being studied.',
                            repository: _repository,
                          ),
                          const SizedBox(height: 18),
                          _LearningSection(
                            title: 'To learn',
                            items: toLearn,
                            emptyMessage: 'Your learning list is empty.',
                            repository: _repository,
                          ),
                          if (completed.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _CompletedSection(
                              items: completed,
                              repository: _repository,
                              expanded: _showCompleted,
                              onToggle: () => setState(
                                () => _showCompleted = !_showCompleted,
                              ),
                            ),
                          ],
                        ],
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

class _LearningSection extends StatelessWidget {
  const _LearningSection({
    required this.title,
    required this.items,
    required this.emptyMessage,
    required this.repository,
  });

  final String title;
  final List<LearningItem> items;
  final String emptyMessage;
  final LearningRepository repository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${items.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _LearningItemTile(
                        item: items[index],
                        repository: repository,
                      ),
                      if (index != items.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.items,
    required this.repository,
    required this.expanded,
    required this.onToggle,
  });

  final List<LearningItem> items;
  final LearningRepository repository;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onToggle,
            leading: Icon(expanded ? Icons.expand_more : Icons.chevron_right),
            title: const Text(
              'Completed',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Text('${items.length}'),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            for (var index = 0; index < items.length; index++) ...[
              _LearningItemTile(item: items[index], repository: repository),
              if (index != items.length - 1) const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }
}

enum _LearningAction { edit, toLearn, learning, completed, delete }

class _LearningItemTile extends StatefulWidget {
  const _LearningItemTile({required this.item, required this.repository});

  final LearningItem item;
  final LearningRepository repository;

  @override
  State<_LearningItemTile> createState() => _LearningItemTileState();
}

class _LearningItemTileState extends State<_LearningItemTile> {
  bool _isWorking = false;

  Future<void> _handleAction(_LearningAction action) async {
    if (action == _LearningAction.edit) {
      await showLearningItemForm(
        context: context,
        repository: widget.repository,
        item: widget.item,
      );
      return;
    }
    if (action == _LearningAction.delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete learning item?'),
          content: Text('“${widget.item.title}” will be permanently deleted.'),
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
      await _run(() => widget.repository.deleteItem(widget.item.id));
      return;
    }

    final status = switch (action) {
      _LearningAction.toLearn => LearningStatus.toLearn,
      _LearningAction.learning => LearningStatus.learning,
      _LearningAction.completed => LearningStatus.completed,
      _ => widget.item.status,
    };
    await _run(() => widget.repository.setStatus(widget.item.id, status));
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() => _isWorking = true);
    try {
      await operation();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update this item. $error')),
      );
      setState(() => _isWorking = false);
    }
  }

  Future<void> _openResource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this resource.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.status == LearningStatus.completed
                ? Icons.check_circle_outline
                : item.status == LearningStatus.learning
                ? Icons.school_outlined
                : Icons.bookmark_border,
            size: 21,
            color: item.status == LearningStatus.completed
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: item.status == LearningStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.notes,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (item.area.isNotEmpty)
                      _Metadata(icon: Icons.folder_outlined, label: item.area),
                    _RatingBadge(label: 'Priority', rating: item.priority),
                    _RatingBadge(label: 'Usefulness', rating: item.usefulness),
                  ],
                ),
                if (item.resources.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    children: [
                      for (final resource in item.resources)
                        ActionChip(
                          avatar: const Icon(Icons.open_in_new, size: 15),
                          label: Text(resource.label),
                          onPressed: () => _openResource(resource.url),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_LearningAction>(
            enabled: !_isWorking,
            tooltip: 'Learning item actions',
            onSelected: _handleAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _LearningAction.edit,
                child: Text('Edit'),
              ),
              if (item.status != LearningStatus.learning)
                const PopupMenuItem(
                  value: _LearningAction.learning,
                  child: Text('Start learning'),
                ),
              if (item.status != LearningStatus.toLearn)
                const PopupMenuItem(
                  value: _LearningAction.toLearn,
                  child: Text('Move to To learn'),
                ),
              if (item.status != LearningStatus.completed)
                const PopupMenuItem(
                  value: _LearningAction.completed,
                  child: Text('Mark completed'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _LearningAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.label, required this.rating});

  final String label;
  final LearningRating rating;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (rating) {
      LearningRating.low => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      LearningRating.medium => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      LearningRating.high => (
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
        '$label: ${rating.label}',
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

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Could not load learning items. $error'));
  }
}
