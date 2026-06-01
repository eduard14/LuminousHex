import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';
import 'package:lightcore/widgets/lightcore_quest_card.dart';

void main() {
  testWidgets('battle canvas replaces its game when controller changes', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final firstController = LightcoreController();
    final secondController = LightcoreController();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    firstController.debugDisableTutorial();
    secondController.debugDisableTutorial();

    await _pumpBattleScreen(tester, firstController);

    final gameFinder = find.byType(GameWidget<LightcoreBattleGame>);
    final firstGame = tester
        .widget<GameWidget<LightcoreBattleGame>>(gameFinder)
        .game!;
    expect(firstGame.controller, same(firstController));

    await _pumpBattleScreen(tester, secondController);

    final secondGame = tester
        .widget<GameWidget<LightcoreBattleGame>>(gameFinder)
        .game!;
    expect(secondGame, isNot(same(firstGame)));
    expect(secondGame.controller, same(secondController));

    await tester.tapAt(tester.getCenter(gameFinder));
    await tester.pump();

    expect(firstController.outerRingRevealed, isFalse);
    expect(secondController.outerRingRevealed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed guide shows the next action', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    expect(controller.tutorialCompactPrompt, 'Click Hex 1');

    await _pumpBattleScreen(tester, controller);

    expect(find.text('Click Hex 1'), findsOneWidget);
    expect(find.text('View guide'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed guide stays short when detail override is long', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    const longOverride =
        'Hex 1 build controls are open. Choose Comet Mortar or Rayline Spire to bring the first tower online.';

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: LightcoreQuestCard(
            controller: controller,
            compact: true,
            instructionOverride: longOverride,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Click Hex 1'), findsOneWidget);
    expect(find.text(longOverride), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening battle hides overdrive until it is taught', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.canUseManualOverdrive, isTrue);
    expect(controller.showManualOverdriveHud, isFalse);

    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('manual-overdrive-hud')),
      findsNothing,
    );

    controller.debugDisableTutorial();
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('manual-overdrive-hud')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpBattleScreen(
  WidgetTester tester,
  LightcoreController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightcoreTheme(),
      home: Scaffold(
        body: BattleScreen(controller: controller, isActive: true),
      ),
    ),
  );
  await tester.pump();
}
