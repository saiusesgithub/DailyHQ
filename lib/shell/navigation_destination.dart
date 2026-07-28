import 'package:flutter/material.dart';

enum AppDestination {
  dashboard,
  dailyTasks,
  todos,
  journal,
  learning,
  thoughts,
  projects,
  linkedinPosts,
  settings,
}

class AppNavigationDestination {
  const AppNavigationDestination(this.id, this.label, this.icon);

  final AppDestination id;
  final String label;
  final IconData icon;
}

const navigationDestinations = [
  AppNavigationDestination(
    AppDestination.dashboard,
    'Dashboard',
    Icons.space_dashboard_outlined,
  ),
  AppNavigationDestination(
    AppDestination.dailyTasks,
    'Daily Tasks',
    Icons.check_circle_outline,
  ),
  AppNavigationDestination(
    AppDestination.todos,
    'To-do list',
    Icons.checklist_outlined,
  ),
  AppNavigationDestination(
    AppDestination.journal,
    'Journal',
    Icons.auto_stories_outlined,
  ),
  AppNavigationDestination(
    AppDestination.learning,
    'Learning',
    Icons.school_outlined,
  ),
  AppNavigationDestination(
    AppDestination.thoughts,
    'Thoughts',
    Icons.lightbulb_outline,
  ),
  AppNavigationDestination(
    AppDestination.projects,
    'Projects',
    Icons.folder_outlined,
  ),
  AppNavigationDestination(
    AppDestination.linkedinPosts,
    'LinkedIn Posts',
    Icons.post_add_outlined,
  ),
  AppNavigationDestination(
    AppDestination.settings,
    'Settings',
    Icons.settings_outlined,
  ),
];
