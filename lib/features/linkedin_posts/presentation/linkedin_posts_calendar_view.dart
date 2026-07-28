import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/linkedin_posts_repository.dart';
import '../domain/linkedin_post.dart';
import '../domain/linkedin_post_status.dart';
import 'linkedin_post_details.dart';

class LinkedInPostsCalendarView extends StatefulWidget {
  const LinkedInPostsCalendarView({
    required this.posts,
    required this.repository,
    super.key,
  });

  final List<LinkedInPost> posts;
  final LinkedInPostsRepository repository;

  @override
  State<LinkedInPostsCalendarView> createState() =>
      _LinkedInPostsCalendarViewState();
}

class _LinkedInPostsCalendarViewState extends State<LinkedInPostsCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<LinkedInPost> _eventsForDay(DateTime day) {
    return widget.posts.where((post) {
      final eventDate = post.status == LinkedInPostStatus.planned
          ? post.plannedDate
          : post.postedDate;
      return eventDate != null && isSameDay(eventDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPosts = _eventsForDay(_selectedDay);
    final selectedDateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_selectedDay);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TableCalendar<LinkedInPost>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            rowHeight: 56,
            daysOfWeekHeight: 30,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            eventLoader: _eventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              headerPadding: EdgeInsets.symmetric(vertical: 12),
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              todayDecoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(),
              markersMaxCount: 1,
            ),
            calendarBuilders: CalendarBuilders<LinkedInPost>(
              markerBuilder: (context, day, posts) {
                if (posts.isEmpty) return null;
                final hasPlanned = posts.any(
                  (post) => post.status == LinkedInPostStatus.planned,
                );
                final hasPosted = posts.any(
                  (post) => post.status == LinkedInPostStatus.posted,
                );

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasPlanned)
                        Icon(
                          Icons.schedule,
                          size: 11,
                          color: colorScheme.tertiary,
                        ),
                      if (hasPosted)
                        Icon(
                          Icons.check_circle,
                          size: 11,
                          color: colorScheme.primary,
                        ),
                      if (posts.length > 2)
                        Text(
                          '+${posts.length - 2}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendItem(
              icon: Icons.schedule,
              label: 'Planned',
              color: colorScheme.tertiary,
            ),
            _LegendItem(
              icon: Icons.check_circle,
              label: 'Posted',
              color: colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                selectedDateLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${selectedPosts.length} ${selectedPosts.length == 1 ? 'post' : 'posts'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (selectedPosts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No LinkedIn posts on this day.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var index = 0; index < selectedPosts.length; index++) ...[
                  _CalendarPostTile(
                    post: selectedPosts[index],
                    repository: widget.repository,
                  ),
                  if (index != selectedPosts.length - 1)
                    Divider(height: 1, color: colorScheme.outlineVariant),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CalendarPostTile extends StatelessWidget {
  const _CalendarPostTile({required this.post, required this.repository});

  final LinkedInPost post;
  final LinkedInPostsRepository repository;

  @override
  Widget build(BuildContext context) {
    final isPosted = post.status == LinkedInPostStatus.posted;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: () => showLinkedInPostDetails(
        context: context,
        repository: repository,
        post: post,
      ),
      leading: Icon(
        isPosted ? Icons.check_circle_outline : Icons.schedule,
        color: isPosted ? colorScheme.primary : colorScheme.tertiary,
      ),
      title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${post.status.label} · ${post.priority.label} priority'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
