import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/medal_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/screens/lightcore_shell.dart';
import 'package:lightcore/services/lightcore_firebase_backend.dart';
import 'package:lightcore/services/lightcore_firebase_runtime_config.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

void main() {
  test('profile medals unlock, equip, apply bonuses, and persist', () {
    final controller = LightcoreController(
      packRandom: Random(41),
      traitRandom: Random(42),
      managerRandom: Random(43),
    );
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    final firstPrism = controller.profileMedalStatusById(
      MedalLibrary.firstPrism.id,
    );
    expect(firstPrism, isNotNull);
    expect(firstPrism!.unlocked, isTrue);

    final powerBefore = controller.towerPower(controller.slots[0]);
    expect(controller.equipProfileMedal(MedalLibrary.firstPrism.id), isTrue);
    expect(controller.equippedProfileMedal?.id, MedalLibrary.firstPrism.id);
    expect(controller.profileMedalBonuses.towerPower, 0.03);
    expect(
      controller.towerPower(controller.slots[0]),
      greaterThan(powerBefore),
    );

    final payload = controller.buildCloudSavePayload();
    final playerPayload = payload['player'] as Map<String, dynamic>;
    expect(playerPayload['equippedProfileMedalId'], MedalLibrary.firstPrism.id);
    expect(
      playerPayload['unlockedProfileMedalIds'],
      contains(MedalLibrary.firstPrism.id),
    );

    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    expect(restored.equippedProfileMedal?.id, MedalLibrary.firstPrism.id);
    expect(restored.isProfileMedalUnlocked(MedalLibrary.firstPrism.id), isTrue);
    expect(restored.profileMedalBonuses.towerPower, 0.03);
  });

  testWidgets('hamburger menu opens the profile medals section', (
    tester,
  ) async {
    final controller = LightcoreController(
      packRandom: Random(51),
      traitRandom: Random(52),
      managerRandom: Random(53),
    );
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    final backend = FirebaseLightcoreBackend(
      runtimeConfig: lightcoreFirebaseRuntimeConfig,
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

    await tester.tap(find.byTooltip('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Medals'), findsOneWidget);

    await tester.tap(find.text('Medals'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Profile Medals'), findsOneWidget);
    expect(find.text('No Medal Equipped'), findsOneWidget);
    expect(find.text(MedalLibrary.firstPrism.name), findsOneWidget);
  });

  testWidgets('profile medals section fits a compact shell viewport', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final controller = LightcoreController(
      packRandom: Random(61),
      traitRandom: Random(62),
      managerRandom: Random(63),
    );
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    final backend = FirebaseLightcoreBackend(
      runtimeConfig: lightcoreFirebaseRuntimeConfig,
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

    await tester.tap(find.byTooltip('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Medals'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Profile Medals'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
