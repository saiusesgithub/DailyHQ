import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';
import 'linkedin_post_form.dart';
import 'linkedin_posts_calendar_view.dart';
import 'linkedin_posts_list_view.dart';

enum _LinkedInPostsView { list, calendar }

class LinkedInPostsPage extends StatefulWidget {
  const LinkedInPostsPage({required this.userId, super.key});

  final String userId;

  @override
  State<LinkedInPostsPage> createState() => _LinkedInPostsPageState();
}

class _LinkedInPostsPageState extends State<LinkedInPostsPage> {
  late final LinkedInPostsRepository _repository;
  _LinkedInPostsView _selectedView = _LinkedInPostsView.list;

  @override
  void initState() {
    super.initState();
    _repository = LinkedInPostsRepository(userId: widget.userId);
  }

  Future<void> _addPost() {
    return showLinkedInPostForm(context: context, repository: _repository);
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
                  title: 'LinkedIn Posts',
                  subtitle: 'Plan, organize, and track your LinkedIn content.',
                  action: FilledButton.icon(
                    onPressed: _addPost,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add post'),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<_LinkedInPostsView>(
                    segments: const [
                      ButtonSegment(
                        value: _LinkedInPostsView.list,
                        icon: Icon(Icons.view_list_outlined),
                        label: Text('List'),
                      ),
                      ButtonSegment(
                        value: _LinkedInPostsView.calendar,
                        icon: Icon(Icons.calendar_month_outlined),
                        label: Text('Calendar'),
                      ),
                    ],
                    selected: {_selectedView},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedView = selection.first);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: StreamBuilder<List<LinkedInPost>>(
                    stream: _repository.watchPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _PostsLoadError(error: snapshot.error);
                      }

                      final posts = snapshot.data ?? const <LinkedInPost>[];
                      return switch (_selectedView) {
                        _LinkedInPostsView.list => LinkedInPostsListView(
                          posts: posts,
                          repository: _repository,
                        ),
                        _LinkedInPostsView.calendar =>
                          LinkedInPostsCalendarView(
                            posts: posts,
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

class _PostsLoadError extends StatelessWidget {
  const _PostsLoadError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: colorScheme.error, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Could not load LinkedIn posts.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
