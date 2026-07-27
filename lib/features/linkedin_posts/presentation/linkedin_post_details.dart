import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';
import 'linkedin_post_form.dart';

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
          height: math.min(MediaQuery.sizeOf(context).height * 0.85, 680),
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
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _DetailValue(label: 'Status', value: post.status.label),
              _DetailValue(label: 'Priority', value: post.priority.label),
              if (post.plannedDate != null)
                _DetailValue(
                  label: 'Planned date',
                  value: _formatDate(context, post.plannedDate!),
                ),
              if (post.postedDate != null)
                _DetailValue(
                  label: 'Posted date',
                  value: _formatDate(context, post.postedDate!),
                ),
            ],
          ),
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 28),
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

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
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
