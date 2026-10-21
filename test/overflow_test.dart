import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/screens/game_screen.dart';
import 'package:snake/screens/main_menu_screen.dart';
import 'package:snake/screens/shop_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'game_coins': 40}));

  testWidgets('shop kichik ekranda oqmaydi', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.text('SOTIB OLISH'), findsWidgets);
  });

  testWidgets('bosh menyu kichik ekranda oqmaydi', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.text('B O S H L A S H'), findsOneWidget);
  });

  testWidgets('game over dialog kichik ekranda sigadi', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('B O S H L A S H'));
    await tester.pump();

    for (int i = 0; i < 40 && find.text("O'YIN TUGADI").evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 210));
    }
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text("O'YIN TUGADI"), findsOneWidget);
    expect(find.text('QAYTA BOSHLASH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
