import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('first inactive battle screen shows play button', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    await _pumpBattleScreen(tester, controller);

    final playButton = find.byKey(const ValueKey<String>('battle-play-button'));
    expect(playButton, findsOneWidget);
    expect(controller.swarmActivated, isFalse);

    await tester.tap(playButton);
    await tester.pump();

    expect(controller.swarmActivated, isTrue);
    expect(controller.outerRingRevealed, isTrue);
    expect(playButton, findsNothing);
    expect(tester.takeException(), isNull);
  });

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
    expect(firstGame.viewScale, closeTo(0.72, 0.001));

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

  testWidgets('battle screen does not show tutorial guide chrome', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    expect(controller.hasActiveTutorial, isFalse);
    expect(controller.tutorialCompactPrompt, isNull);

    await _pumpBattleScreen(tester, controller);

    expect(find.text('Click Hex 1'), findsNothing);
    expect(find.text('View guide'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('battle no longer hides overdrive behind tutorial state', (
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
    expect(controller.showManualOverdriveHud, isTrue);

    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('manual-overdrive-hud')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('core panel exposes persistent queue controls without tutorial', (
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
    await tester.tap(find.byType(GameWidget<LightcoreBattleGame>));
    await tester.pump();

    expect(controller.tutorialUsesBattleOnlyNavigation, isFalse);
    expect(find.textContaining('Root Shell Core'), findsOneWidget);
    expect(find.textContaining('Buffer'), findsWidgets);
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Core Stat Board'), findsNothing);
    expect(find.text('Ring'), findsNothing);
    expect(find.text('Slots'), findsNothing);
    expect(find.text('Crit'), findsNothing);
    expect(find.text('Final'), findsNothing);
    expect(find.text('Normal'), findsNothing);
    expect(find.text('Pen'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core stat board is reserved for Layer 2 and higher', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = createDeterministicController();
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.selectCenter();
    await _pumpBattleScreen(tester, controller);
    await tester.tap(find.byType(GameWidget<LightcoreBattleGame>));
    await tester.pump();

    expect(controller.activeLayer.tier, 1);
    expect(find.textContaining('Root Shell Core'), findsOneWidget);
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Core Stat Board'), findsNothing);

    forgeLayer2(controller);
    controller.debugDisableTutorial();
    controller.selectCenter();
    await _pumpBattleScreen(tester, controller);
    await tester.tap(find.byType(GameWidget<LightcoreBattleGame>));
    await tester.pump();

    expect(controller.activeLayer.tier, 2);
    expect(find.textContaining('Prism Shell Core'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Core Stat Board'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening challenge does not show lower start prompt', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _prepareOpeningChallengePrompt(controller);
    expect(controller.tutorialStep, LightcoreTutorialStep.none);

    await _pumpBattleScreen(tester, controller);

    final prompt = find.byKey(
      const ValueKey<String>('battle-raise-threat-prompt'),
    );
    expect(prompt, findsNothing);
    expect(find.text('Challenge ready'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active wave hides lower start prompt', (tester) async {
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

    expect(
      find.byKey(const ValueKey<String>('battle-raise-threat-prompt')),
      findsNothing,
    );
    expect(find.text('Challenge ready'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('battle surface shows wave and selected tower upgrades', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.selectCenter();
    controller.lumens = 10000;
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    controller.tick(controller.slots[0].fabricationRemainingSeconds + 0.1);
    controller.activeLayer.bestWaveReached = 10;
    controller.selectSlot(0);

    await _pumpBattleScreen(tester, controller);

    expect(find.byKey(const ValueKey<String>('battle-wave-hud')), findsNothing);
    expect(find.text('Best Wave'), findsNothing);
    expect(find.textContaining('Stats 0/'), findsOneWidget);
    expect(find.textContaining('Layer 2 Lv 1'), findsOneWidget);
    expect(find.text('Tower Health'), findsOneWidget);
    expect(find.text('Persistent Stat Upgrades'), findsNothing);
    expect(find.textContaining('Layer 1 Tower Level'), findsNothing);
    expect(find.textContaining('Charge Rate'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tower hit zone does not steal taps at the core edge', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.selectCenter();
    controller.lumens = 10000;
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    await _pumpBattleScreen(tester, controller);

    final game = tester
        .widget<GameWidget<LightcoreBattleGame>>(
          find.byType(GameWidget<LightcoreBattleGame>),
        )
        .game!;
    final coreCenter = game.debugCoreCenter;
    final slotCenter = game.debugSlotCenter(0);
    expect(coreCenter, isNotNull);
    expect(slotCenter, isNotNull);

    final delta = slotCenter! - coreCenter!;
    final distance = delta.distance;
    final direction = Offset(delta.dx / distance, delta.dy / distance);
    final coreSidePoint =
        coreCenter + (direction * (game.debugTowerCoreGuardRadius * 0.98));

    expect(game.debugWouldHitAnySlotAt(slotCenter), isTrue);
    expect(game.debugWouldHitAnySlotAt(coreSidePoint), isFalse);
    expect(game.debugWouldHitTowerAt(coreSidePoint), isFalse);
    expect(tester.takeException(), isNull);
  });
}

void _prepareOpeningChallengePrompt(LightcoreController controller) {
  controller.selectCenter();
  expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
  final upgradeCost = controller.upgradeCost(controller.slots[0]);
  if (controller.lumens < upgradeCost) {
    controller.lumens = upgradeCost;
  }
  expect(controller.upgradeTower(0), isTrue);
  controller.selectCenter();
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
