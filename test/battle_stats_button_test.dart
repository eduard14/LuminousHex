import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
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
  return Offset(rect.right - 48, rect.top + 48);
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

  testWidgets('center tap generates core pulse and defers stats to wrench', (
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

    await tester.tapAt(_battleCenter(tester));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.pulses, hasLength(1));
    controller.tick(0.65);
    await tester.pump();

    expect(controller.shots, hasLength(1));
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
      tester.getRect(wrenchButton).left,
      lessThan(tester.getRect(find.byType(BattleScreen)).center.dx),
    );

    await tester.tap(wrenchButton);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Core Stats'), findsOneWidget);
  });

  testWidgets('tower tap fires packet and defers stats to wrench button', (
    tester,
  ) async {
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
    expect(controller.pulses, isNotEmpty);
    expect(find.text('Tower Stats'), findsNothing);
    expect(find.text('Hex 1'), findsNothing);
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

    await tester.tap(wrenchButton);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.selectedSlotIndex, 0);
    expect(find.text('Tower Stats'), findsOneWidget);

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

    expect(find.text('Tower Stats'), findsNothing);

    await tester.tap(selectionButton);
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.text('Tower Stats'), findsOneWidget);
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
    expect(controller.pulses, isEmpty);
    expect(find.text('Fabrication'), findsOneWidget);
    expect(find.textContaining('Fabricating Comet Mortar'), findsOneWidget);
    expect(find.text('Tower Stats'), findsNothing);
    expect(find.text('Inspect Tower'), findsNothing);
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
    expect(controller.pulses, hasLength(1));
    expect(controller.pulses.single.sourceSlotIndex, 1);
    expect(find.text('Tower Stats'), findsNothing);
  });

  testWidgets('center tap keeps core stats open until blank map tap', (
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

    await tester.tapAt(_battleCenter(tester));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isTrue);
    expect(find.text('Core Stats'), findsOneWidget);

    await tester.tapAt(_blankMapPoint(tester));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.outerRingRevealed, isFalse);
    expect(find.text('Core Stats'), findsNothing);
  });
}
