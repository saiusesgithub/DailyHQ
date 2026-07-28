import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';
import '../domain/linkedin_post_priority.dart';
import '../domain/linkedin_post_status.dart';
import 'linkedin_post_form.dart';
import 'linkedin_post_status_actions.dart';

Future<void> showLinkedInPostDetails({
  required BuildContext context,
  required LinkedInPostsRepository repository,
  required LinkedInPost post,
}) async {
  final isWide = MediaQuery.sizeOf(context).width >= 800;

  if (!isWide) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LinkedInPostDetails(repository: repository, post: post),
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 620,
          height: math.min(MediaQuery.sizeOf(context).height * 0.8, 560),
          child: LinkedInPostDetails(repository: repository, post: post),
        ),
      );
    },
  );
}

class LinkedInPostDetails extends StatelessWidget {
  const LinkedInPostDetails({
    required this.repository,
    required this.post,
    super.key,
  });

  final LinkedInPostsRepository repository;
  final LinkedInPost post;

  Future<void> _edit(BuildContext context) async {
    final changed = await showLinkedInPostForm(
      context: context,
      repository: repository,
      post: post,
    );
    if (changed == true && context.mounted) Navigator.of(context).pop();
  }

  Future<void> _changeStatus(BuildContext context) async {
    final bool? changed;
    if (post.status == LinkedInPostStatus.planned) {
      changed = await showMarkAsPostedDialog(
        context: context,
        repository: repository,
        post: post,
      );
    } else {
      changed = await showMoveBackToPlannedDialog(
        context: context,
        repository: repository,
        post: post,
      );
    }
    if (changed == true && context.mounted) Navigator.of(context).pop();
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post details'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            post.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(status: post.status),
              _PriorityBadge(priority: post.priority),
            ],
          ),
          if (post.plannedDate != null || post.postedDate != null) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                if (post.plannedDate != null)
                  _DateMetadata(
                    label: 'Planned',
                    value: _formatDate(context, post.plannedDate!),
                  ),
                if (post.postedDate != null)
                  _DateMetadata(
                    label: 'Posted',
                    value: _formatDate(context, post.postedDate!),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: post.status == LinkedInPostStatus.planned
                ? FilledButton.tonalIcon(
                    onPressed: () => _changeStatus(context),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark as posted'),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _changeStatus(context),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Move back to planned'),
                  ),
          ),
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _DetailSection(label: 'Description', value: post.description),
          ],
          if (post.imageIdeas.isNotEmpty) ...[
            const SizedBox(height: 28),
            _DetailSection(label: 'Image ideas', value: post.imageIdeas),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final LinkedInPostStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPosted = status == LinkedInPostStatus.posted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPosted
            ? colorScheme.primaryContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPosted ? Icons.check_circle_outline : Icons.schedule,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: priority == LinkedInPostPriority.high
            ? colorScheme.errorContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '${priority.label} priority',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DateMetadata extends StatelessWidget {
  const _DateMetadata({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SelectableText(value, style: const TextStyle(height: 1.5)),
      ],
    );
  }
}
