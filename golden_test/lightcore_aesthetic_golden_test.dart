import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/screens/lightcore_main_menu_screen.dart';

import '../test/helpers/golden_fonts.dart';
import '../test/helpers/lightcore_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadGoldenTestFonts);

  testWidgets('main menu desktop aesthetic stays intentional', (tester) async {
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(lightcoreGoldenDesktopSize);

    await tester.pumpWidget(buildReadyMainMenu());
    await pumpFixedFrame(tester);

    expect(find.text('LumiHex'), findsOneWidget);
    await expectLater(
      find.byType(LightcoreMainMenuScreen),
      matchesGoldenFile('goldens/lightcore_main_menu_desktop.png'),
    );

    await tester.pumpWidget(Container());
    await tester.pump();
  });

  testWidgets('early compact battle HUD remains composed', (tester) async {
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);

    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    stageBattleActivity(controller, frames: 30);

    await tester.pumpWidget(buildTestBattle(controller));
    await pumpFixedFrame(tester);

    expect(find.byType(BattleScreen), findsOneWidget);
    await expectLater(
      find.byType(BattleScreen),
      matchesGoldenFile('goldens/lightcore_battle_compact_early.png'),
    );

    await tester.pumpWidget(Container());
    await tester.pump();
  });

  testWidgets('Prism Shell battle state keeps promoted UI polish', (
    tester,
  ) async {
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);

    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    forgeLayer2(controller);
    stageBattleActivity(controller, frames: 90);

    await tester.pumpWidget(buildTestBattle(controller));
    await pumpFixedFrame(tester);

    expect(find.byType(BattleScreen), findsOneWidget);
    expect(controller.progressionLayer, greaterThanOrEqualTo(2));
    await expectLater(
      find.byType(BattleScreen),
      matchesGoldenFile('goldens/lightcore_battle_compact_layer2.png'),
    );

    await tester.pumpWidget(Container());
    await tester.pump();
  });
}
