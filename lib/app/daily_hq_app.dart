import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../shell/navigation_destination.dart';
import 'app_theme.dart';

class DailyHqApp extends StatelessWidget {
  const DailyHqApp({
    this.initialDestination = AppDestination.dashboard,
    this.focusThoughtCapture = false,
    this.openJournalCapture = false,
    super.key,
  });

  final AppDestination initialDestination;
  final bool focusThoughtCapture;
  final bool openJournalCapture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyHQ',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: AuthGate(
        initialDestination: initialDestination,
        focusThoughtCapture: focusThoughtCapture,
        openJournalCapture: openJournalCapture,
      ),
    );
  }
}
