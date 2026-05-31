import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

Future<void> _pumpBattleScreen(
  WidgetTester tester,
  LightcoreController controller,
) async {
  await _pumpBattleScreenWithActive(tester, controller, isActive: true);
}

Future<void> _pumpBattleScreenWithActive(
  WidgetTester tester,
  LightcoreController controller, {
  required bool isActive,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightcoreTheme(),
      home: Scaffold(
        body: BattleScreen(controller: controller, isActive: isActive),
      ),
    ),
  );
  await tester.pump();
}

Offset _battleCenter(WidgetTester tester) {
  final rect = tester.getRect(find.byType(BattleScreen));
  return Offset(rect.left + (rect.width / 2), rect.top + (rect.height * 0.46));
}

Offset _blankMapPoint(WidgetTester tester) {
  final rect = tester.getRect(find.byType(BattleScreen));
  return Offset(rect.left + 48, rect.top + 120);
}

Offset _slotCenter(WidgetTester tester, int slotIndex) {
  const axialNeighbors = <(int, int)>[
    (1, 0),
    (1, -1),
    (0, -1),
    (-1, 0),
    (-1, 1),
    (0, 1),
  ];
  final rect = tester.getRect(find.byType(BattleScreen));
  final center = _battleCenter(tester);
  final shortest = math.min(rect.width, rect.height);
  final hexRadius = shortest * 0.108;
  final coord = axialNeighbors[slotIndex];
  final x = hexRadius * math.sqrt(3) * (coord.$1 + (coord.$2 / 2));
  final y = hexRadius * 1.5 * coord.$2;
  return Offset(center.dx + x, center.dy + y);
}

AmmoPacket _testAmmoPacket(int id) {
  return AmmoPacket(
    id: 'battle_stats_packet_$id',
    sourceSlotIndex: null,
    affinity: PrototypeAffinity.neutral,
    power: 12,
    advantageMultiplier: 1,
    projectileType: ProjectileType.starBolt,
    payloadType: PayloadType.none,
    targetPriority: TargetPriority.close,
    range: 300,
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

void main() {
  testWidgets('battle canvas stays mounted while shell overlays are active', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    await _pumpBattleScreenWithActive(tester, controller, isActive: true);

    final gameWidgetFinder = find.byType(
      GameWidget<LightcoreBattleGame>,
      skipOffstage: false,
    );
    expect(gameWidgetFinder, findsOneWidget);
    final initialGameElement = tester.element(gameWidgetFinder);

    await _pumpBattleScreenWithActive(tester, controller, isActive: false);
    expect(tester.element(gameWidgetFinder), same(initialGameElement));
    expect(tester.takeException(), isNull);

    await _pumpBattleScreenWithActive(tester, controller, isActive: true);
    expect(tester.element(gameWidgetFinder), same(initialGameElement));
    expect(tester.takeException(), isNull);

    await tester.tapAt(_battleCenter(tester));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isTrue);
  });

  testWidgets('center tap opens core controls without queuing a pulse', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.selectCenter();
    controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
    );

    await _pumpBattleScreen(tester, controller);

    final pulsesBeforeTap = controller.pulses.length;
    await tester.tapAt(_battleCenter(tester));
    await tester.pump();

    expect(controller.pulses.length, pulsesBeforeTap);
    expect(find.text('Core Stats'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('battle-side-stats-button')),
      findsNothing,
    );

    final wrenchButton = find.byKey(
      const ValueKey<String>('battle-tower-selection-button'),
    );
    expect(wrenchButton, findsOneWidget);
    expect(
      find.descendant(
        of: wrenchButton,
        matching: find.byIcon(Icons.build_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(wrenchButton).left,
      lessThan(tester.getRect(find.byType(BattleScreen)).center.dx),
    );

    await tester.tap(wrenchButton);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Core Stats'), findsOneWidget);
  });

  testWidgets('ready shot indicator stays hidden while empty', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('battle-ready-shot-indicator')),
      findsNothing,
    );
  });

  testWidgets(
    'ready shot indicator shows available shots without empty slots',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();
      controller.debugSetAmmoQueue(
        List<AmmoPacket>.generate(
          controller.coreQueueCapacity,
          _testAmmoPacket,
        ),
      );

      await _pumpBattleScreen(tester, controller);

      expect(
        find.byKey(const ValueKey<String>('battle-ready-shot-indicator')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('battle-ready-shot-indicator')),
          matching: find.byIcon(Icons.bolt_rounded),
        ),
        findsOneWidget,
      );
      expect(find.byType(Scrollable), findsNothing);
      expect(find.byType(Scrollbar), findsNothing);
    },
  );

  testWidgets(
    'tower tap reserves tower controls instead of firing ready shots',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();
      controller.lumens = 1000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
      expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
      controller.selectCenter();

      await _pumpBattleScreen(tester, controller);
      await tester.tapAt(_slotCenter(tester, 0));
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.selectedSlotIndex, isNull);
      expect(find.text('Tower Stats'), findsNothing);
      expect(find.text('Live Projectile Target'), findsNothing);
      expect(
        controller.towerTargetPriority(controller.slots[0]),
        TargetPriority.close,
      );
      expect(
        find.byKey(const ValueKey<String>('battle-side-stats-button')),
        findsNothing,
      );

      final wrenchButton = find.byKey(
        const ValueKey<String>('battle-tower-selection-button'),
      );
      expect(wrenchButton, findsOneWidget);
      expect(
        tester.getRect(wrenchButton).left,
        lessThan(tester.getRect(find.byType(BattleScreen)).center.dx),
      );

      final selectionButton = find.byKey(
        const ValueKey<String>('battle-tower-selection-button'),
      );
      final overdriveButton = find.byKey(
        const ValueKey<String>('battle-overdrive-button'),
      );
      expect(selectionButton, findsOneWidget);
      expect(overdriveButton, findsOneWidget);

      final screenRect = tester.getRect(find.byType(BattleScreen));
      expect(
        tester.getRect(selectionButton).center.dx,
        lessThan(screenRect.center.dx),
      );
      expect(
        tester.getRect(overdriveButton).center.dx,
        greaterThan(screenRect.center.dx),
      );

      await tester.tap(selectionButton);
      await tester.pump(const Duration(milliseconds: 180));

      expect(controller.selectedSlotIndex, 0);
      expect(find.text('Tower Detail'), findsOneWidget);
      expect(find.text('Projectile Targeting'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Projectile Targeting')).dy,
        lessThan(tester.getTopLeft(find.text('HEX 1')).dy),
      );

      final strongTargetChip = find.widgetWithText(ChoiceChip, 'Strong');
      await tester.tap(strongTargetChip);
      await tester.pump();
      expect(
        controller.towerTargetPriority(controller.slots[0]),
        TargetPriority.strong,
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.text('Tower Detail'), findsNothing);
    },
  );

  testWidgets('building a tower closes controls until the wrench is tapped', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.selectCenter();

    await _pumpBattleScreen(tester, controller);

    await tester.tapAt(_slotCenter(tester, 0));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Empty Hex 1'), findsOneWidget);

    await tester.tap(find.text(TowerLibrary.redPrism.name));
    await tester.pump(const Duration(milliseconds: 180));

    expect(controller.slots[0].isFabricating, isTrue);
    expect(find.text('Tower Stats'), findsNothing);
    expect(find.text('Fabrication'), findsNothing);

    final wrenchButton = find.byKey(
      const ValueKey<String>('battle-tower-selection-button'),
    );
    expect(wrenchButton, findsOneWidget);

    await tester.tap(wrenchButton);
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.text('Fabrication'), findsOneWidget);
    expect(find.text('Tower Stats'), findsNothing);
  });

  testWidgets('green shield tower shows wrench icon in selection hud', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.greenPrism), isTrue);
    controller.selectCenter();

    await _pumpBattleScreen(tester, controller);

    await tester.tapAt(_slotCenter(tester, 0));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.selectedSlotIndex, isNull);
    expect(find.text('Tower Stats'), findsNothing);

    final selectionButton = find.byKey(
      const ValueKey<String>('battle-tower-selection-button'),
    );
    expect(selectionButton, findsOneWidget);
    expect(
      find.descendant(
        of: selectionButton,
        matching: find.byIcon(Icons.build_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fabricating tower shows fabrication panel instead of stats', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(
      controller.startTowerFabricationAt(0, TowerLibrary.redPrism),
      isTrue,
    );
    controller.selectCenter();

    await _pumpBattleScreen(tester, controller);

    await tester.tapAt(_slotCenter(tester, 0));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.selectedSlotIndex, 0);
    expect(
      controller.pulses.where((pulse) => pulse.sourceSlotIndex == 0),
      isEmpty,
    );
    expect(find.text('Fabrication'), findsOneWidget);
    expect(find.textContaining('Fabricating Comet Mortar'), findsOneWidget);
    expect(find.text('Tower Stats'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Stats'), findsNothing);
  });

  testWidgets('number key taps the matching hex', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(1);
    expect(controller.buildTowerAt(1, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(1, charge: 1.2), isTrue);
    controller.selectCenter();

    await _pumpBattleScreen(tester, controller);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.selectedSlotIndex, isNull);
    expect(find.text('Tower Stats'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-tower-selection-button')),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.selectedSlotIndex, 1);
    expect(find.text('Tower Detail'), findsOneWidget);
    expect(find.text('Projectile Targeting'), findsOneWidget);
  });

  testWidgets('blank map tap closes core stats without folding shell', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.selectCenter();

    await _pumpBattleScreen(tester, controller);

    await tester.tapAt(_battleCenter(tester));
    await tester.pump(const Duration(milliseconds: 50));

    final wrenchButton = find.byKey(
      const ValueKey<String>('battle-tower-selection-button'),
    );
    expect(wrenchButton, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('battle-side-stats-button')),
      findsNothing,
    );

    await tester.tap(wrenchButton);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isTrue);
    expect(find.text('Core Stats'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('battle-shell-collapse-button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.unfold_less_double_rounded), findsOneWidget);

    await tester.tapAt(_battleCenter(tester));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isTrue);
    expect(find.text('Core Stats'), findsOneWidget);

    await tester.tapAt(_blankMapPoint(tester));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isTrue);
    expect(find.text('Core Stats'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-shell-collapse-button')),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isFalse);
    expect(
      find.byKey(const ValueKey<String>('battle-shell-collapse-button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.unfold_more_double_rounded), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-shell-collapse-button')),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isTrue);
    expect(find.byIcon(Icons.unfold_less_double_rounded), findsOneWidget);
  });
}
