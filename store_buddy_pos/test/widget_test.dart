import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store_buddy_pos/main.dart';

void main() {
  testWidgets('App shows activation screen on first launch', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Activate This Device'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
