import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/enemy_configs.dart';
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

  testWidgets('opening core panel hides ready-shot capacity controls', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    await _pumpBattleScreen(tester, controller);
    await tester.pump();

    expect(controller.tutorialUsesBattleOnlyNavigation, isTrue);
    expect(find.textContaining('Ready Shots'), findsNothing);
    expect(find.text('Ready'), findsNothing);
    expect(find.text('Ring'), findsNothing);
    expect(find.text('Slots'), findsNothing);
    expect(find.text('TS'), findsNothing);
    expect(find.text('EXP'), findsNothing);
    expect(find.text('Crit'), findsNothing);
    expect(find.text('Final'), findsNothing);
    expect(find.text('Normal'), findsNothing);
    expect(find.text('Pen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('challenge prompt does not reserve hidden overdrive space', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _prepareOpeningChallengePrompt(controller);
    expect(controller.tutorialStep, LightcoreTutorialStep.raiseThreat);
    expect(controller.showManualOverdriveHud, isFalse);

    await _pumpBattleScreen(tester, controller);

    final prompt = find.byKey(
      const ValueKey<String>('battle-raise-threat-prompt'),
    );
    expect(prompt, findsOneWidget);
    expect(tester.getBottomLeft(prompt).dy, greaterThan(730));
    expect(tester.takeException(), isNull);
  });

  testWidgets('active opening challenge explains the pressure upgrade loop', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _prepareOpeningChallengePrompt(controller);
    expect(controller.startFirstThreatChallenge(), isTrue);
    expect(controller.activeThreatRegionChallenge, isNotNull);

    await _pumpBattleScreen(tester, controller);

    expect(find.text('Challenge live'), findsOneWidget);
    expect(find.text('Push Wave 5'), findsOneWidget);
    expect(find.textContaining('Enemy Lv 2'), findsOneWidget);
    expect(find.textContaining('upgrade Hex 1'), findsOneWidget);
    expect(find.text('Challenge ready'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _prepareOpeningChallengePrompt(LightcoreController controller) {
  controller.selectCenter();
  expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
  final starter = controller.debugSpawnEnemyFromCard(
    EnemyLibrary.starterDefault.id,
    angle: 0,
    radius: 120,
    healthFraction: 1,
  );
  expect(starter, isNotNull);
  expect(
    controller.debugSetTowerCharge(0, charge: 1, cooldownRemaining: 0),
    isTrue,
  );
  expect(controller.queuedCorePackets, 0);
  expect(controller.focusBattleEnemyForNextShot(starter!.id), isTrue);
  _advanceUntil(
    controller,
    () =>
        controller.tutorialStep ==
        LightcoreTutorialStep.upgradeFirstTowerToLevel3,
    reason: 'opening focus click did not auto-fire the next generated shot',
  );
  expect(controller.queuedCorePackets, 0);
  final upgradeCost = controller.upgradeCost(controller.slots[0]);
  if (controller.lumens < upgradeCost) {
    controller.lumens = upgradeCost;
  }
  expect(controller.upgradeTower(0), isTrue);
}

void _advanceUntil(
  LightcoreController controller,
  bool Function() condition, {
  required String reason,
  int steps = 160,
  double dt = 0.5,
}) {
  for (var index = 0; index < steps; index++) {
    if (condition()) {
      return;
    }
    controller.tick(dt);
  }
  fail(reason);
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
