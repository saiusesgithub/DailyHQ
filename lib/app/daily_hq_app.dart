import 'package:flutter/material.dart';

import '../shell/app_shell.dart';
import 'app_theme.dart';

class DailyHqApp extends StatelessWidget {
  const DailyHqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyHQ',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
