import 'package:flutter/material.dart';

import '../shared/widgets/empty_state.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/section_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({required this.onOpenInbox, super.key});

  final VoidCallback onOpenInbox;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Dashboard',
                  subtitle: 'Your personal headquarters',
                  action: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Quick capture'),
                  ),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 20.0;
                    final useColumns = constraints.maxWidth >= 760;
                    final sectionWidth = useColumns
                        ? (constraints.maxWidth - spacing * 2) / 3
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 24,
                      children: [
                        SizedBox(
                          width: sectionWidth,
                          child: _DashboardSection(
                            title: 'Today',
                            child: EmptyState(
                              message: 'Nothing planned for today.',
                              actionLabel: 'Add a task',
                              onAction: () {},
                            ),
                          ),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: _DashboardSection(
                            title: 'Inbox',
                            child: EmptyState(
                              message: 'Your inbox is clear.',
                              description:
                                  'Quickly captured thoughts and tasks will '
                                  'appear here.',
                              actionLabel: 'Open inbox',
                              onAction: onOpenInbox,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: sectionWidth,
                          child: _DashboardSection(
                            title: 'Active projects',
                            child: EmptyState(
                              message: 'No active projects yet.',
                              actionLabel: 'Create project',
                              onAction: () {},
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
