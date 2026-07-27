import 'package:daily_hq/app/daily_hq_app.dart';
import 'package:daily_hq/app/firebase_startup_error_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop sidebar navigates between modules', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DailyHqApp());

    expect(find.text('DailyHQ'), findsOneWidget);
    expect(find.text('Your personal headquarters'), findsOneWidget);
    expect(find.text('Nothing planned for today.'), findsOneWidget);

    await tester.tap(find.text('Projects'));
    await tester.pump();

    expect(_placeholderText(tester), 'Projects');
  });

  testWidgets('mobile drawer navigates between modules', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DailyHqApp());
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

    await tester.pumpWidget(const DailyHqApp());

    expect(find.text('Quick capture'), findsOneWidget);
    expect(find.text('Nothing planned for today.'), findsOneWidget);
    expect(find.text('Your inbox is clear.'), findsOneWidget);
    expect(find.text('No active projects yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open inbox action navigates to the inbox page', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DailyHqApp());
    await tester.tap(find.text('Open inbox'));
    await tester.pump();

    expect(_placeholderText(tester), 'Inbox');
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
}

String _placeholderText(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const ValueKey('module-placeholder')))
      .data!;
}
