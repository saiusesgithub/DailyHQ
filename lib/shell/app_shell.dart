import 'package:flutter/material.dart';

import '../features/daily_tasks/presentation/daily_tasks_page.dart';
import '../features/linkedin_posts/presentation/linkedin_posts_page.dart';
import '../features/projects/presentation/projects_page.dart';
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
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget get _selectedPage => switch (_selectedIndex) {
    0 => DashboardPage(onOpenInbox: () => _selectDestination(1)),
    1 => const InboxPage(),
    2 => DailyTasksPage(userId: widget.userId),
    3 => const ThoughtsPage(),
    4 => ProjectsPage(userId: widget.userId),
    5 => LinkedInPostsPage(userId: widget.userId),
    6 => const SettingsPage(),
    _ => DashboardPage(onOpenInbox: () => _selectDestination(1)),
  };

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _selectedPage),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(navigationDestinations[_selectedIndex].label)),
      drawer: _MobileDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
      ),
      body: _selectedPage,
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

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
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: navigationDestinations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final destination = navigationDestinations[index];
                      return _SidebarDestination(
                        destination: destination,
                        selected: selectedIndex == index,
                        onTap: () => onDestinationSelected(index),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        Navigator.pop(context);
        onDestinationSelected(index);
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
        for (final destination in navigationDestinations)
          NavigationDrawerDestination(
            icon: Icon(destination.icon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}
