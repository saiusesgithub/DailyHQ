import 'package:flutter/material.dart';

import '../features/daily_tasks/presentation/daily_tasks_page.dart';
import '../features/linkedin_posts/presentation/linkedin_posts_page.dart';
import '../features/projects/presentation/projects_page.dart';
import '../features/todos/presentation/todos_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/inbox_page.dart';
import '../pages/settings_page.dart';
import '../pages/thoughts_page.dart';
import 'navigation_destination.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.userId, super.key});

  final String userId;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _desktopBreakpoint = 800.0;
  late final List<AppNavigationDestination> _destinations;
  AppDestination _selectedDestination = AppDestination.dashboard;

  @override
  void initState() {
    super.initState();
    _destinations = List.of(navigationDestinations);
  }

  void _selectDestination(AppDestination destination) {
    setState(() => _selectedDestination = destination);
  }

  void _reorderDestinations(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final destination = _destinations.removeAt(oldIndex);
      _destinations.insert(newIndex, destination);
    });
  }

  Widget get _selectedPage => switch (_selectedDestination) {
    AppDestination.dashboard => DashboardPage(
      onOpenInbox: () => _selectDestination(AppDestination.inbox),
    ),
    AppDestination.inbox => const InboxPage(),
    AppDestination.dailyTasks => DailyTasksPage(userId: widget.userId),
    AppDestination.todos => TodosPage(userId: widget.userId),
    AppDestination.thoughts => const ThoughtsPage(),
    AppDestination.projects => ProjectsPage(userId: widget.userId),
    AppDestination.linkedinPosts => LinkedInPostsPage(userId: widget.userId),
    AppDestination.settings => const SettingsPage(),
  };

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              destinations: _destinations,
              selectedDestination: _selectedDestination,
              onDestinationSelected: _selectDestination,
              onReorder: _reorderDestinations,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _selectedPage),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _destinations
              .firstWhere(
                (destination) => destination.id == _selectedDestination,
              )
              .label,
        ),
      ),
      drawer: _MobileDrawer(
        destinations: _destinations,
        selectedDestination: _selectedDestination,
        onDestinationSelected: _selectDestination,
      ),
      body: _selectedPage,
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.destinations,
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.onReorder,
  });

  final List<AppNavigationDestination> destinations;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: SizedBox(
          width: 240,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'DailyHQ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    onReorder: onReorder,
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return Padding(
                        key: ValueKey(destination.id),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ReorderableDragStartListener(
                          index: index,
                          child: _SidebarDestination(
                            destination: destination,
                            selected: selectedDestination == destination.id,
                            onTap: () => onDestinationSelected(destination.id),
                          ),
                        ),
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

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: selected ? colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(destination.icon, size: 20, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.drag_indicator,
                size: 18,
                color: foregroundColor.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.destinations,
    required this.selectedDestination,
    required this.onDestinationSelected,
  });

  final List<AppNavigationDestination> destinations;
  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: destinations.indexWhere(
        (destination) => destination.id == selectedDestination,
      ),
      onDestinationSelected: (index) {
        Navigator.pop(context);
        onDestinationSelected(destinations[index].id);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Text(
            'DailyHQ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        for (final destination in destinations)
          NavigationDrawerDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}
