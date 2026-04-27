import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('storm chain boosts blue and green tower throughput', () {
    final controller = LightcoreController(traitRandom: Random(21));
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(1);

    controller.buildTowerAt(0, TowerLibrary.bluePrism);

    final baselineTower = controller.slots[0];
    final baselineCharge = controller.towerChargeRate(baselineTower);
    final baselineGeneration = controller.towerGenerationSpeed(baselineTower);

    controller.buildTowerAt(1, TowerLibrary.greenPrism);

    final stormTower = controller.slots[0];
    expect(
      controller.activeTowerAchievements.map((achievement) => achievement.name),
      contains('Storm Chain'),
    );
    expect(controller.towerPatternAchievementLabel(stormTower), 'Storm Chain');
    expect(controller.towerChargeRate(stormTower), greaterThan(baselineCharge));
    expect(
      controller.towerGenerationSpeed(stormTower),
      greaterThan(baselineGeneration),
    );
  });

  test('monochrome focus increases power and trims cooldown', () {
    final controller = LightcoreController(traitRandom: Random(31));
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(1);

    controller.buildTowerAt(0, TowerLibrary.redPrism);

    final baselineTower = controller.slots[0];
    final baselinePower = controller.towerPower(baselineTower);
    final baselineCooldown = controller.towerCooldown(baselineTower);

    controller.buildTowerAt(1, TowerLibrary.redPrism);

    final focusedTower = controller.slots[0];
    expect(
      controller.activeTowerAchievements.map((achievement) => achievement.name),
      contains('Monochrome Focus'),
    );
    expect(controller.towerPower(focusedTower), greaterThan(baselinePower));
    expect(controller.towerCooldown(focusedTower), lessThan(baselineCooldown));
  });

  test('rainbow relay activates on a full six-color shell', () {
    final controller = LightcoreController(traitRandom: Random(41));
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 5000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(
      LightcoreController.slotCount - 1,
    );

    const sixBandShell = <TowerConfig>[
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.greenPrism,
      TowerLibrary.bluePrism,
      TowerLibrary.purplePrism,
    ];

    for (var index = 0; index < LightcoreController.slotCount - 1; index++) {
      controller.buildTowerAt(index, sixBandShell[index]);
    }

    final baselineTower = controller.slots[0];
    final baselineRange = controller.towerEffectiveRange(baselineTower);
    final baselineCritChance = controller.towerCritChance(baselineTower);

    controller.buildTowerAt(
      LightcoreController.slotCount - 1,
      sixBandShell.last,
    );

    final rainbowTower = controller.slots[0];
    expect(
      controller.activeTowerAchievements.map((achievement) => achievement.name),
      contains('Rainbow Relay'),
    );
    expect(
      controller.towerEffectiveRange(rainbowTower),
      greaterThan(baselineRange),
    );
    expect(
      controller.towerCritChance(rainbowTower),
      greaterThan(baselineCritChance),
    );
  });
}
