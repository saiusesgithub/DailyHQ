import 'package:flutter/material.dart';

import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';

Future<bool?> showMarkAsPostedDialog({
  required BuildContext context,
  required LinkedInPostsRepository repository,
  required LinkedInPost post,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) =>
        _MarkAsPostedDialog(repository: repository, post: post),
  );
}

Future<bool?> showMoveBackToPlannedDialog({
  required BuildContext context,
  required LinkedInPostsRepository repository,
  required LinkedInPost post,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) =>
        _MoveBackToPlannedDialog(repository: repository, post: post),
  );
}

class _MarkAsPostedDialog extends StatefulWidget {
  const _MarkAsPostedDialog({required this.repository, required this.post});

  final LinkedInPostsRepository repository;
  final LinkedInPost post;

  @override
  State<_MarkAsPostedDialog> createState() => _MarkAsPostedDialogState();
}

class _MarkAsPostedDialogState extends State<_MarkAsPostedDialog> {
  DateTime _postedDate = DateTime.now();
  bool _isSaving = false;
  String? _error;

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _postedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) setState(() => _postedDate = selected);
  }

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.markAsPosted(widget.post.id, _postedDate);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not update this post. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_postedDate);

    return AlertDialog(
      title: const Text('Mark as posted'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose the published date for "${widget.post.title}".'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(dateLabel),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _confirm,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark as posted'),
        ),
      ],
    );
  }
}

class _MoveBackToPlannedDialog extends StatefulWidget {
  const _MoveBackToPlannedDialog({
    required this.repository,
    required this.post,
  });

  final LinkedInPostsRepository repository;
  final LinkedInPost post;

  @override
  State<_MoveBackToPlannedDialog> createState() =>
      _MoveBackToPlannedDialogState();
}

class _MoveBackToPlannedDialogState extends State<_MoveBackToPlannedDialog> {
  bool _isSaving = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.moveBackToPlanned(widget.post.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Could not move this post. $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move back to planned?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The posted date will be cleared.'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _confirm,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Move to planned'),
        ),
      ],
    );
  }
}
