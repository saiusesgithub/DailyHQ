import 'package:flutter/material.dart';

class ThoughtsPage extends StatelessWidget {
  const ThoughtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Thoughts',
        key: const ValueKey('module-placeholder'),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
