import 'package:flutter/material.dart';

class AppNavigationDestination {
  const AppNavigationDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}

const navigationDestinations = [
  AppNavigationDestination('Dashboard', Icons.space_dashboard_outlined),
  AppNavigationDestination('Inbox', Icons.inbox_outlined),
  AppNavigationDestination('Tasks', Icons.check_circle_outline),
  AppNavigationDestination('Thoughts', Icons.lightbulb_outline),
  AppNavigationDestination('Projects', Icons.folder_outlined),
  AppNavigationDestination('LinkedIn Posts', Icons.post_add_outlined),
  AppNavigationDestination('Settings', Icons.settings_outlined),
];
