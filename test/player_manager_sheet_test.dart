import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/screens/lightcore_shell.dart';
import 'package:lightcore/services/lightcore_firebase_backend.dart';
import 'package:lightcore/services/lightcore_firebase_runtime_config.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';
import 'package:lightcore/widgets/guided_focus_frame.dart';

void main() {
  testWidgets('top-left profile button opens the main manager sheet', (
    tester,
  ) async {
    final controller = LightcoreController(
      packRandom: Random(7),
      traitRandom: Random(8),
      managerRandom: Random(9),
    );
    addTearDown(controller.dispose);

    final backend = FirebaseLightcoreBackend(
      runtimeConfig: lightcoreFirebaseRuntimeConfig,
    );
    controller.debugDisableTutorial();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: LightcoreShell(controller: controller, backend: backend),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    controller.dismissBanner();
    await tester.pump();

    expect(find.byTooltip('Open Main Manager'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Main Manager'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Main Manager'), findsOneWidget);
    expect(find.text('Pilot Identity'), findsNothing);
    expect(find.text('Equipment'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('player-screen-name-field')),
      findsNothing,
    );
    expect(find.textContaining('Tap a slot to filter'), findsOneWidget);
    expect(find.textContaining('Lumens'), findsNothing);
    expect(find.textContaining('Flux'), findsNothing);
  });

  testWidgets(
    'main manager shows and clears new equipment notification badge',
    (tester) async {
      final controller = LightcoreController(
        packRandom: Random(10),
        traitRandom: Random(11),
        managerRandom: Random(12),
      );
      addTearDown(controller.dispose);

      final backend = FirebaseLightcoreBackend(
        runtimeConfig: lightcoreFirebaseRuntimeConfig,
      );
      controller.debugDisableTutorial();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightcoreTheme(),
          home: LightcoreShell(controller: controller, backend: backend),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      controller.dismissBanner();
      await tester.pump();

      controller.debugGrantEquipmentDropForEnemy(
        EnemyState(
          id: 'test_enemy',
          sourceCardId: EnemyLibrary.basicWhite.id,
          cardLevel: 5,
          config: EnemyLibrary.basicWhite,
          spawnRadius: 900,
          angle: 0,
          radius: 900,
          health: EnemyLibrary.basicWhite.baseHealth,
          maxHealth: EnemyLibrary.basicWhite.baseHealth,
          defense: EnemyLibrary.basicWhite.baseDefense,
          speed: EnemyLibrary.basicWhite.baseSpeed,
          reward: EnemyLibrary.basicWhite.reward,
          experienceReward: EnemyLibrary.basicWhite.baseExperience,
          jamStrength: EnemyLibrary.basicWhite.jamStrength,
          angularVelocity: EnemyLibrary.basicWhite.baseSpiralDrift,
          splitDepth: 0,
          sizeScale: 1,
        ),
      );
      await tester.pump();
      controller.dismissBanner();
      await tester.pump();

      expect(
        find.byTooltip('Open Main Manager (1 new equipment piece)'),
        findsOneWidget,
      );
      expect(controller.newEquipmentNotificationCount, 1);

      await tester.tap(
        find.byTooltip('Open Main Manager (1 new equipment piece)'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(controller.newEquipmentNotificationCount, 0);
      expect(find.text('Main Manager'), findsOneWidget);
    },
  );

  testWidgets('main manager hosts global attributes after level up', (
    tester,
  ) async {
    final controller = LightcoreController(
      packRandom: Random(22),
      traitRandom: Random(23),
      managerRandom: Random(24),
    );
    addTearDown(controller.dispose);

    final backend = FirebaseLightcoreBackend(
      runtimeConfig: lightcoreFirebaseRuntimeConfig,
    );
    controller.debugDisableTutorial();
    controller.experience = LightcoreController.experienceForOverallLevel(2);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: LightcoreShell(controller: controller, backend: backend),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byTooltip('Open Main Manager (1 Radiance point ready)'),
      findsOneWidget,
    );

    await tester.tap(
      find.byTooltip('Open Main Manager (1 Radiance point ready)'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Main Manager'), findsOneWidget);
    expect(find.text('Global Attributes'), findsOneWidget);
    expect(find.text('Radiance Attributes'), findsNothing);
    expect(find.text('MGT 0'), findsOneWidget);

    await tester.tap(find.text('Add Point').first);
    await tester.pump();

    expect(controller.radianceStatRank(LightcoreRadianceStat.might), 1);
    expect(controller.unspentRadianceStatPoints, 0);
    expect(find.text('MGT 1'), findsOneWidget);
  });

  testWidgets(
    'global attributes tutorial focus has compact manager clearance',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = LightcoreController(
        packRandom: Random(25),
        traitRandom: Random(26),
        managerRandom: Random(27),
      );
      addTearDown(controller.dispose);

      final backend = FirebaseLightcoreBackend(
        runtimeConfig: lightcoreFirebaseRuntimeConfig,
      );
      controller.debugDisableTutorial();
      controller.experience = LightcoreController.experienceForOverallLevel(2);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightcoreTheme(),
          home: LightcoreShell(controller: controller, backend: backend),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(
        find.byTooltip('Open Main Manager (1 Radiance point ready)'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final dialog = find.byType(Dialog);
      final listView = find.descendant(
        of: dialog,
        matching: find.byType(ListView),
      );
      final focusFrame = find.descendant(
        of: dialog,
        matching: find.byType(GuidedFocusFrame),
      );

      expect(focusFrame, findsOneWidget);

      final listRect = tester.getRect(listView);
      final focusRect = tester.getRect(focusFrame);

      expect(focusRect.top - listRect.top, greaterThanOrEqualTo(7));
      expect(listRect.right - focusRect.right, greaterThanOrEqualTo(34));
    },
  );

  testWidgets('slot selection filters inventory and equips from the grid', (
    tester,
  ) async {
    final controller = LightcoreController(
      packRandom: Random(13),
      traitRandom: Random(14),
      managerRandom: Random(15),
    );
    addTearDown(controller.dispose);

    final backend = FirebaseLightcoreBackend(
      runtimeConfig: lightcoreFirebaseRuntimeConfig,
    );
    controller.debugDisableTutorial();

    final hat = controller.debugGrantEquipmentDropForEnemy(
      _testEnemy(),
      slotType: EquipmentInventorySlot.hat,
      rarity: ManagerRarity.rare,
      level: 5,
    );
    final shoes = controller.debugGrantEquipmentDropForEnemy(
      _testEnemy(),
      slotType: EquipmentInventorySlot.shoes,
      rarity: ManagerRarity.rare,
      level: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: LightcoreShell(controller: controller, backend: backend),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    controller.dismissBanner();
    await tester.pump();

    await tester.tap(
      find.byTooltip('Open Main Manager (2 new equipment pieces)'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(hat.name), findsOneWidget);
    expect(find.text(shoes.name), findsOneWidget);

    await tester.tap(find.byTooltip('Hat: empty. Tap to filter inventory.'));
    await tester.pump();

    expect(find.text('Hat Inventory'), findsOneWidget);
    expect(find.text(hat.name), findsOneWidget);
    expect(find.text(shoes.name), findsNothing);

    await tester.tap(find.text('Equip'));
    await tester.pump();

    expect(
      controller
          .equippedPlayerItemForSlot(EquipmentLoadoutSlot.hat)
          ?.instanceId,
      hat.instanceId,
    );
  });
}

EnemyState _testEnemy() {
  return EnemyState(
    id: 'test_enemy',
    sourceCardId: EnemyLibrary.basicWhite.id,
    cardLevel: 5,
    config: EnemyLibrary.basicWhite,
    spawnRadius: 900,
    angle: 0,
    radius: 900,
    health: EnemyLibrary.basicWhite.baseHealth,
    maxHealth: EnemyLibrary.basicWhite.baseHealth,
    defense: EnemyLibrary.basicWhite.baseDefense,
    speed: EnemyLibrary.basicWhite.baseSpeed,
    reward: EnemyLibrary.basicWhite.reward,
    experienceReward: EnemyLibrary.basicWhite.baseExperience,
    jamStrength: EnemyLibrary.basicWhite.jamStrength,
    angularVelocity: EnemyLibrary.basicWhite.baseSpiralDrift,
    splitDepth: 0,
    sizeScale: 1,
  );
}
