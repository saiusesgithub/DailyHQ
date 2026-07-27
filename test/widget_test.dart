import 'package:daily_hq/app/daily_hq_app.dart';
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
    expect(_placeholderText(tester), 'Dashboard');

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
}

String _placeholderText(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const ValueKey('module-placeholder')))
      .data!;
}
