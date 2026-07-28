import 'package:flutter/material.dart';

import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';
import '../domain/linkedin_post_ordering.dart';
import '../domain/linkedin_post_priority.dart';
import '../domain/linkedin_post_status.dart';
import 'linkedin_post_details.dart';
import 'linkedin_post_form.dart';
import 'linkedin_post_status_actions.dart';

class LinkedInPostsListView extends StatefulWidget {
  const LinkedInPostsListView({
    required this.posts,
    required this.repository,
    super.key,
  });

  final List<LinkedInPost> posts;
  final LinkedInPostsRepository repository;

  @override
  State<LinkedInPostsListView> createState() => _LinkedInPostsListViewState();
}

class _LinkedInPostsListViewState extends State<LinkedInPostsListView> {
  bool _showPosted = false;

  @override
  Widget build(BuildContext context) {
    final planned = orderPlannedPosts(
      widget.posts.where((post) => post.status == LinkedInPostStatus.planned),
    );
    final posted = orderPostedPosts(
      widget.posts.where((post) => post.status == LinkedInPostStatus.posted),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _PostSection(
          title: 'Planned posts',
          count: planned.length,
          emptyMessage: 'No posts planned yet.',
          posts: planned,
          repository: widget.repository,
        ),
        const SizedBox(height: 24),
        _PostSection(
          title: 'Already posted',
          count: posted.length,
          emptyMessage: 'No published posts yet.',
          posts: posted,
          repository: widget.repository,
          collapsible: true,
          expanded: _showPosted,
          onToggle: () => setState(() => _showPosted = !_showPosted),
        ),
      ],
    );
  }
}

class _PostSection extends StatelessWidget {
  const _PostSection({
    required this.title,
    required this.count,
    required this.emptyMessage,
    required this.posts,
    required this.repository,
    this.collapsible = false,
    this.expanded = true,
    this.onToggle,
  });

  final String title;
  final int count;
  final String emptyMessage;
  final List<LinkedInPost> posts;
  final LinkedInPostsRepository repository;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  if (collapsible) ...[
                    const SizedBox(width: 8),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: posts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      emptyMessage,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: [
                      for (var index = 0; index < posts.length; index++) ...[
                        _PostPreview(
                          post: posts[index],
                          repository: repository,
                        ),
                        if (index != posts.length - 1)
                          Divider(height: 1, color: colorScheme.outlineVariant),
                      ],
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

enum _PostAction { edit, changeStatus, delete }

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.post, required this.repository});

  final LinkedInPost post;
  final LinkedInPostsRepository repository;

  bool get _isPosted => post.status == LinkedInPostStatus.posted;

  String? _dateLabel(BuildContext context) {
    final date = _isPosted ? post.postedDate : post.plannedDate;
    if (date == null) return null;
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  Future<void> _open(BuildContext context) {
    return showLinkedInPostDetails(
      context: context,
      repository: repository,
      post: post,
    );
  }

  Future<void> _handleAction(BuildContext context, _PostAction action) async {
    switch (action) {
      case _PostAction.edit:
        await showLinkedInPostForm(
          context: context,
          repository: repository,
          post: post,
        );
      case _PostAction.changeStatus:
        if (_isPosted) {
          await _moveBackToPlanned(context);
        } else {
          await showMarkAsPostedDialog(
            context: context,
            repository: repository,
            post: post,
          );
        }
      case _PostAction.delete:
        await _delete(context);
    }
  }

  Future<void> _moveBackToPlanned(BuildContext context) async {
    final confirmed = await _confirm(
      context: context,
      title: 'Move back to planned?',
      message: 'The posted date will be cleared.',
      confirmLabel: 'Move to planned',
    );
    if (!confirmed || !context.mounted) return;

    await _runMutation(
      context,
      () => repository.moveBackToPlanned(post.id),
      failureMessage: 'Could not move this post back to planned.',
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await _confirm(
      context: context,
      title: 'Delete this post?',
      message: 'This permanently deletes “${post.title}”.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await _runMutation(
      context,
      () => repository.deletePost(post.id),
      failureMessage: 'Could not delete this post.',
    );
  }

  Future<bool> _confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        )
                      : null,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _runMutation(
    BuildContext context,
    Future<void> Function() mutation, {
    required String failureMessage,
  }) async {
    try {
      await mutation();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failureMessage $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateLabel(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (dateLabel != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPosted
                                    ? Icons.check_circle_outline
                                    : Icons.calendar_today_outlined,
                                size: 15,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                dateLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        _PriorityBadge(priority: post.priority),
                      ],
                    ),
                    if (!_isPosted) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => showMarkAsPostedDialog(
                            context: context,
                            repository: repository,
                            post: post,
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Mark as posted'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_PostAction>(
                tooltip: 'Post actions',
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _PostAction.edit,
                    child: Text('Open / edit'),
                  ),
                  PopupMenuItem(
                    value: _PostAction.changeStatus,
                    child: Text(
                      _isPosted ? 'Move back to planned' : 'Mark as posted',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _PostAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final LinkedInPostPriority priority;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (priority) {
      LinkedInPostPriority.low => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      LinkedInPostPriority.medium => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      LinkedInPostPriority.high => (
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
