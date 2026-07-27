import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/daily_hq_app.dart';
import 'app/firebase_startup_error_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    runApp(const DailyHqApp());
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
