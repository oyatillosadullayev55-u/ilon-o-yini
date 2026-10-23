import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/screens/game_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> startGame(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('B O S H L A S H'));
    await tester.pump();
  }

  testWidgets('pauza pardasi chiqadi va davom ettiriladi', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await startGame(tester);

    await tester.tap(find.byIcon(Icons.pause_circle_filled));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PAUZA'), findsOneWidget);
    expect(find.text('DAVOM ETISH'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('DAVOM ETISH'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PAUZA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('klaviatura yo\'nalishi ilonni buradi', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await startGame(tester);

    // Yuqoriga burilib, klassik rejimda devorga uriladi
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    for (int i = 0; i < 20 && find.text("O'YIN TUGADI").evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 210));
    }
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text("O'YIN TUGADI"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
