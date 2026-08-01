import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/daily_hq_app.dart';
import 'app/firebase_startup_error_app.dart';
import 'firebase_options.dart';
import 'shell/navigation_destination.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();

  final quickThought = arguments.contains('--quick-thought');
  final quickJournal = arguments.contains('--quick-journal');
  final initialDestination = quickThought
      ? AppDestination.thoughts
      : quickJournal || arguments.contains('--open=journal')
      ? AppDestination.journal
      : AppDestination.dashboard;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      debugPrint(
        'DailyHQ: Firebase initialized for project '
        '${Firebase.app().options.projectId}.',
      );
    }

    runApp(
      DailyHqApp(
        initialDestination: initialDestination,
        focusThoughtCapture: quickThought,
        openJournalCapture: quickJournal,
      ),
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'DailyHQ startup',
        context: ErrorDescription('while initializing Firebase'),
      ),
    );

    runApp(FirebaseStartupErrorApp(error: error));
  }
}
