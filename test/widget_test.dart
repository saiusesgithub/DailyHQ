import 'package:daily_hq/app/firebase_startup_error_app.dart';
import 'package:daily_hq/features/auth/presentation/auth_page.dart';
import 'package:daily_hq/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop sidebar navigates between modules', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpShell(tester);

    expect(find.text('DailyHQ'), findsOneWidget);
    expect(find.text('Your personal headquarters'), findsOneWidget);
    expect(find.text('Nothing planned for today.'), findsOneWidget);

    await tester.tap(find.text('Thoughts').first);
    await tester.pump();

    expect(_placeholderText(tester), 'Thoughts');
  });

  testWidgets('mobile drawer navigates between modules', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpShell(tester);
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thoughts'));
    await tester.pumpAndSettle();

    expect(_placeholderText(tester), 'Thoughts');
  });

  testWidgets('dashboard sections stack without overflow on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpShell(tester);

    expect(find.text('Quick capture'), findsOneWidget);
    expect(find.text('Nothing planned for today.'), findsOneWidget);
    expect(find.text('No active projects yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Firebase startup failures show a readable error screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FirebaseStartupErrorApp(error: 'Test initialization failure'),
    );

    expect(find.text('DailyHQ couldn\'t start'), findsOneWidget);
    expect(
      find.textContaining('Firebase initialization failed'),
      findsOneWidget,
    );
  });

  testWidgets('device connection screen only offers sign in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));

    expect(find.text('Connect DailyHQ'), findsOneWidget);
    expect(
      find.text(
        'Sign in once to connect this device to your personal DailyHQ data.',
      ),
      findsOneWidget,
    );
    expect(find.text('Connect device'), findsOneWidget);
    expect(find.textContaining('Create account'), findsNothing);

    await tester.tap(find.text('Connect device'));
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });
}

Future<void> _pumpShell(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(home: AppShell(userId: 'test-user')),
  );
}

String _placeholderText(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const ValueKey('module-placeholder')))
      .data!;
}
