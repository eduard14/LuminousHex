import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('first battle screen shows rebuilt Layer 1 action dock', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    await _pumpBattleScreen(tester, controller);

    final startButton = find.text('Start Run');
    expect(startButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('layer-rebuild-queue-orbit')),
      findsOneWidget,
    );
    expect(find.text('Damage Lv. 0\n18 Sparks'), findsNothing);
    expect(find.textContaining('Fire Rate Lv. 0'), findsNothing);
    expect(find.textContaining('Multishot Lv. 0'), findsNothing);
    expect(find.textContaining('Queue Size Lv. 0'), findsNothing);
    expect(find.textContaining('Build Feeder'), findsNothing);
    expect(find.text('Layer 1 Run'), findsOneWidget);
    expect(controller.swarmActivated, isFalse);

    await tester.tap(startButton);
    await tester.pump();

    expect(controller.swarmActivated, isTrue);
    expect(controller.outerRingRevealed, isTrue);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Global Tower Upgrades'), findsOneWidget);
    expect(find.text('Damage Lv. 0\n18 Sparks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuilt HUD visualizes queued projectiles and ready state', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.startLayer1Run();
    controller.debugSetAmmoQueue([
      _testAmmoPacket(
        id: 'queued-star',
        affinity: PrototypeAffinity.solar,
        projectileType: ProjectileType.chainArc,
      ),
      _testAmmoPacket(
        id: 'queued-blue',
        affinity: PrototypeAffinity.aether,
        projectileType: ProjectileType.threadBeam,
      ),
    ]);

    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('layer-rebuild-queue-orbit')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Shot Queue 2/8 Ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuilt battle keeps shell visible for seven-hex readability', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.startLayer1Run();

    await _pumpBattleScreen(tester, controller);

    expect(controller.swarmActivated, isTrue);
    expect(controller.outerRingRevealed, isTrue);
    expect(
      find.byKey(const ValueKey<String>('battle-shell-collapse-button')),
      findsNothing,
    );

    controller.toggleShellVisibility();
    await tester.pump();

    expect(controller.outerRingRevealed, isFalse);
    expect(
      find.byKey(const ValueKey<String>('battle-shell-collapse-button')),
      findsNothing,
    );
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

    secondController.startLayer1Run();
    await tester.pump();

    expect(firstController.outerRingRevealed, isFalse);
    expect(secondController.outerRingRevealed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mouse wheel zooms the battle canvas like pinch zoom', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    await _pumpBattleScreen(tester, controller);

    final gameFinder = find.byType(GameWidget<LightcoreBattleGame>);
    final game = tester
        .widget<GameWidget<LightcoreBattleGame>>(gameFinder)
        .game!;
    final startScale = game.viewScale;

    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: tester.getCenter(gameFinder),
        scrollDelta: const Offset(0, -240),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    expect(game.viewScale, greaterThan(startScale));
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

  testWidgets('battle hides overdrive while upgrade dock is open', (
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
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rebuilt dock exposes Layer 1 run upgrades without legacy labels',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(430, 780));
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.startLayer1Run();
      await _pumpBattleScreen(tester, controller);

      expect(controller.tutorialUsesBattleOnlyNavigation, isFalse);
      expect(find.text('Damage Lv. 0\n18 Sparks'), findsOneWidget);
      expect(find.textContaining('Fire Rate Lv. 0'), findsOneWidget);
      expect(find.textContaining('Multishot Lv. 0'), findsOneWidget);
      expect(find.textContaining('Queue Size Lv. 0'), findsOneWidget);
      expect(find.textContaining('Build Feeder'), findsNothing);
      expect(find.textContaining('Star Bolt Upgrades'), findsNothing);
      expect(find.textContaining('Feeder Slots Lv. 0'), findsNothing);
      expect(find.text('Global Tower Upgrades'), findsOneWidget);
      expect(find.textContaining('Buffer'), findsNothing);
      expect(find.textContaining('Wave Marks'), findsNothing);
      expect(find.textContaining('Lumens'), findsNothing);
      expect(find.textContaining('Flux'), findsNothing);
      expect(find.text('Stats'), findsNothing);
      expect(find.text('Core Stat Board'), findsNothing);
      expect(find.text('Crit'), findsNothing);
      expect(find.text('Final'), findsNothing);
      expect(find.text('Normal'), findsNothing);
      expect(find.text('Pen'), findsNothing);

      await tester.tap(find.text('Damage Lv. 0\n18 Sparks'));
      await tester.pump();

      expect(controller.layerRunState.rankFor(LayerRunUpgradeType.damage), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'rebuilt dock shows persistent Star Bolt upgrades after run ends',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(430, 780));
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.startLayer1Run();
      controller.debugSetLayer1WaveForTest(6);
      expect(controller.endLayer1RunFromCoreBreak(), isTrue);
      await _pumpBattleScreen(tester, controller);

      expect(controller.layerRunState.active, isFalse);
      expect(controller.starBolts, greaterThan(0));
      expect(find.text('Permanent Upgrades'), findsOneWidget);
      expect(
        find.textContaining('Star Bolt upgrades persist into every new run'),
        findsOneWidget,
      );
      expect(find.textContaining('Feeder Slots Lv. 0'), findsOneWidget);
      expect(find.textContaining('Starting Sparks Lv. 0'), findsOneWidget);
      expect(find.text('Damage Lv. 0\n18 Sparks'), findsNothing);
      expect(find.text('Fire Rate Lv. 0\n22 Sparks'), findsNothing);

      await tester.tap(find.textContaining('Feeder Slots Lv. 0'));
      await tester.pump();

      expect(
        controller.layerPersistentProgress.rankFor(
          LayerPersistentUpgradeType.feederSlots,
        ),
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty feeder hex opens player color choice in rebuild mode', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.startLayer1Run();
    await _pumpBattleScreen(tester, controller);

    final game = tester
        .widget<GameWidget<LightcoreBattleGame>>(
          find.byType(GameWidget<LightcoreBattleGame>),
        )
        .game!;
    final slotCenter = game.debugSlotCenter(0);
    expect(slotCenter, isNotNull);
    expect(controller.slots[0].isBuilt, isFalse);

    await tester.tapAt(slotCenter!);
    await tester.pump();

    expect(controller.slots[0].isBuilt, isFalse);
    expect(find.text('Choose Feeder 1'), findsOneWidget);
    expect(find.text('Comet Mortar'), findsOneWidget);
    expect(find.textContaining('Build Feeder'), findsNothing);

    await tester.tap(find.text('Comet Mortar'));
    await tester.pump();

    expect(find.text('Install Red'), findsOneWidget);

    await tester.tap(find.text('Install Red'));
    await tester.pump();

    expect(controller.slots[0].isBuilt, isTrue);
    expect(controller.slots[0].config?.id, TowerLibrary.redPrism.id);
    expect(controller.sparks, 51);
    expect(find.textContaining('Feeder Slot 1'), findsOneWidget);
    expect(find.textContaining('24 Sparks'), findsNothing);
    expect(find.textContaining('Lumens'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy core stat board is hidden during Layer 1/2 rebuild', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = createDeterministicController();
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.startLayer1Run();
    await _pumpBattleScreen(tester, controller);

    expect(controller.activeLayer.tier, 1);
    expect(find.text('Start Run'), findsNothing);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Full Stats'), findsNothing);
    expect(find.text('Core Stat Board'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wave 10 shell completion is explicit without Layer 2 board', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(10);
    controller.debugSetLayer1SparksForTest(1000);
    for (var index = 0; index < LightcoreController.slotCount; index += 1) {
      expect(
        controller.buildLayer1FeederAt(index, config: TowerLibrary.greenPrism),
        isTrue,
      );
    }

    await _pumpBattleScreen(tester, controller);

    expect(find.text('Layer 1 Shell Complete'), findsNothing);
    expect(find.text('Complete Shell'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('layer-rebuild-complete-shell-button')),
      findsOneWidget,
    );
    expect(find.text('Layer 2 Base'), findsNothing);

    await tester.tap(find.text('Complete Shell'));
    await tester.pump();

    expect(controller.layerRunState.shellReady, isTrue);
    expect(controller.layer2BaseBoard.filledSlotCount, 1);
    expect(find.text('Layer 1 Shell Complete'), findsNothing);
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
    await _pumpBattleScreen(tester, controller);

    expect(find.byKey(const ValueKey<String>('battle-wave-hud')), findsNothing);
    expect(find.text('Best Wave'), findsNothing);
    expect(find.textContaining('Stats 0/'), findsNothing);
    expect(find.textContaining('Layer 2 Lv 1'), findsNothing);
    expect(find.textContaining('Feeder Slot 1'), findsNothing);

    final game = tester
        .widget<GameWidget<LightcoreBattleGame>>(
          find.byType(GameWidget<LightcoreBattleGame>),
        )
        .game!;
    final slotCenter = game.debugSlotCenter(0);
    expect(slotCenter, isNotNull);
    await tester.tapAt(slotCenter!);
    await tester.pump();

    expect(find.textContaining('Feeder Slot 1'), findsOneWidget);
    expect(find.text('Feeder Integrity'), findsOneWidget);
    expect(find.text('Full Stats'), findsNothing);
    expect(find.text('Persistent Stat Upgrades'), findsNothing);
    expect(find.textContaining('Layer 1 Tower Level'), findsNothing);
    expect(find.textContaining('Wave Marks'), findsNothing);
    expect(find.textContaining('Lumens'), findsNothing);
    expect(find.textContaining('Damage'), findsWidgets);
    expect(find.textContaining('Fire Rate'), findsWidgets);
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

    final hexCornerMiss =
        slotCenter + const Offset(0.70, 0.50) * game.debugSlotRadius;
    expect(
      (hexCornerMiss - slotCenter).distance,
      lessThan(game.debugSlotRadius),
    );
    expect(game.debugWouldHitAnySlotAt(hexCornerMiss), isFalse);
    expect(game.debugWouldHitTowerAt(hexCornerMiss), isFalse);
    expect(tester.takeException(), isNull);
  });
}

void _prepareOpeningChallengePrompt(LightcoreController controller) {
  controller.selectCenter();
  expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
  controller.activeLayer.roundCurrency = 1;
  expect(controller.upgradeTower(0), isTrue);
  controller.selectCenter();
}

AmmoPacket _testAmmoPacket({
  required String id,
  required PrototypeAffinity affinity,
  required ProjectileType projectileType,
}) {
  return AmmoPacket(
    id: id,
    sourceSlotIndex: null,
    affinity: affinity,
    power: 12,
    advantageMultiplier: 1,
    projectileType: projectileType,
    payloadType: PayloadType.none,
    range: 420,
    critChance: 0.05,
    critMultiplier: 1.5,
    finalDamageMultiplier: 1,
    bossDamageMultiplier: 1,
    normalDamageMultiplier: 1,
    defensePenetration: 0,
    minDamageMultiplier: 1,
    maxDamageMultiplier: 1,
  );
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
