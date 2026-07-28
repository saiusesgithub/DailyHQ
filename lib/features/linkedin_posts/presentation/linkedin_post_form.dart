import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';
import '../domain/linkedin_post_priority.dart';
import '../domain/linkedin_post_status.dart';

Future<bool?> showLinkedInPostForm({
  required BuildContext context,
  required LinkedInPostsRepository repository,
  LinkedInPost? post,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 800;

  if (!isWide) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LinkedInPostForm(repository: repository, post: post),
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 620,
          height: math.min(MediaQuery.sizeOf(context).height * 0.85, 680),
          child: LinkedInPostForm(repository: repository, post: post),
        ),
      );
    },
  );
}

class LinkedInPostForm extends StatefulWidget {
  const LinkedInPostForm({required this.repository, this.post, super.key});

  final LinkedInPostsRepository repository;
  final LinkedInPost? post;

  @override
  State<LinkedInPostForm> createState() => _LinkedInPostFormState();
}

class _LinkedInPostFormState extends State<LinkedInPostForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageIdeasController;
  late LinkedInPostPriority _priority;
  DateTime? _plannedDate;
  DateTime? _postedDate;
  bool _isSaving = false;
  String? _saveError;

  bool get _isEditing => widget.post != null;
  bool get _isPosted => widget.post?.status == LinkedInPostStatus.posted;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _titleController = TextEditingController(text: post?.title);
    _descriptionController = TextEditingController(text: post?.description);
    _imageIdeasController = TextEditingController(text: post?.imageIdeas);
    _priority = post?.priority ?? LinkedInPostPriority.medium;
    _plannedDate = post?.plannedDate;
    _postedDate = post?.postedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageIdeasController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool posted}) async {
    final current = posted ? _postedDate : _plannedDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;
    setState(() {
      if (posted) {
        _postedDate = selected;
      } else {
        _plannedDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final imageIdeas = _imageIdeasController.text.trim();

    try {
      final existing = widget.post;
      if (existing == null) {
        await widget.repository
            .createPost(
              title: title,
              description: description,
              plannedDate: _plannedDate,
              priority: _priority,
              imageIdeas: imageIdeas,
            )
            .timeout(const Duration(seconds: 20));
      } else {
        await widget.repository
            .updatePost(
              LinkedInPost(
                id: existing.id,
                title: title,
                description: description,
                status: existing.status,
                plannedDate: _plannedDate,
                postedDate: _postedDate,
                priority: _priority,
                imageIdeas: imageIdeas,
                createdAt: existing.createdAt,
                updatedAt: existing.updatedAt,
              ),
            )
            .timeout(const Duration(seconds: 20));
      }

      if (mounted) Navigator.of(context).pop(true);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError =
            'The save is taking too long. Check your connection and try again.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Could not save this post. $error';
      });
    }
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit post' : 'Add post'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !_isSaving,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a title.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Planned date',
              value: _plannedDate == null ? null : _formatDate(_plannedDate!),
              enabled: !_isSaving,
              onTap: () => _pickDate(posted: false),
              onClear: _plannedDate == null
                  ? null
                  : () => setState(() => _plannedDate = null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LinkedInPostPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority *',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final priority in LinkedInPostPriority.values)
                  DropdownMenuItem(
                    value: priority,
                    child: Text(priority.label),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _priority = value);
                    },
            ),
            if (_isPosted) ...[
              const SizedBox(height: 16),
              _DateField(
                label: 'Posted date',
                value: _postedDate == null ? null : _formatDate(_postedDate!),
                enabled: !_isSaving,
                onTap: () => _pickDate(posted: true),
                onClear: null,
              ),
              if (_postedDate == null) ...[
                const SizedBox(height: 6),
                Text(
                  'A posted date is required for published posts.',
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageIdeasController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Image ideas',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 16),
              Text(_saveError!, style: TextStyle(color: colorScheme.error)),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _isSaving || (_isPosted && _postedDate == null)
                    ? null
                    : _save,
                child: _isSaving
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Saving…'),
                        ],
                      )
                    : Text(_isEditing ? 'Save changes' : 'Add post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value,
      readOnly: true,
      enabled: enabled,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Not set',
        border: const OutlineInputBorder(),
        suffixIcon: onClear == null
            ? const Icon(Icons.calendar_today_outlined, size: 20)
            : IconButton(
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Clear $label',
              ),
      ),
    );
  }
}
