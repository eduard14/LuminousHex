import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _promoteRootShell(LightcoreController controller) {
  controller.lumens = 100000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  expect(controller.isPromotionReady, isTrue);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 2);
}

double _projectedMetricForType(
  LightcoreController controller,
  OuterTowerState tower,
  ChildTowerUpgradeType type,
) {
  return switch (type) {
    ChildTowerUpgradeType.power => controller.towerPower(tower),
    ChildTowerUpgradeType.chargeRate => controller.towerChargeRate(tower),
    ChildTowerUpgradeType.cooldown => controller.towerCooldown(tower),
    ChildTowerUpgradeType.range => controller.towerEffectiveRange(tower),
    ChildTowerUpgradeType.generationSpeed => controller.towerGenerationSpeed(
      tower,
    ),
    ChildTowerUpgradeType.critChance => controller.towerCritChance(tower),
    ChildTowerUpgradeType.critDamage => controller.towerCritMultiplier(tower),
    ChildTowerUpgradeType.finalDamage => controller.towerFinalDamageMultiplier(
      tower,
    ),
    ChildTowerUpgradeType.bossDamage => controller.towerBossDamageMultiplier(
      tower,
    ),
    ChildTowerUpgradeType.normalDamage =>
      controller.towerNormalDamageMultiplier(tower),
    ChildTowerUpgradeType.defensePenetration =>
      controller.towerDefensePenetration(tower),
    ChildTowerUpgradeType.minDamage => controller.towerMinDamageMultiplier(
      tower,
    ),
    ChildTowerUpgradeType.maxDamage => controller.towerMaxDamageMultiplier(
      tower,
    ),
  };
}

Matcher _expectedMetricChange(ChildTowerUpgradeType type, double before) {
  return switch (type) {
    ChildTowerUpgradeType.cooldown => lessThan(before),
    _ => greaterThan(before),
  };
}

void main() {
  test('child-shell tuning updates the projected parent tower stat', () {
    final controller = LightcoreController(traitRandom: Random(7));
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    controller.lumens = 100000;

    expect(controller.activeLayerHasParentSlot, isTrue);
    expect(controller.activeChildTowerUpgrades, hasLength(4));

    final upgrade = controller.activeChildTowerUpgrades.first;
    final before = _projectedMetricForType(
      controller,
      controller.activeChildTowerProjection!,
      upgrade.type,
    );

    expect(controller.upgradeActiveChildTowerStat(upgrade.type), isTrue);

    final after = _projectedMetricForType(
      controller,
      controller.activeChildTowerProjection!,
      upgrade.type,
    );
    expect(after, _expectedMetricChange(upgrade.type, before));
  });

  test('finishing a child-shell board levels it up and rerolls the board', () {
    final controller = LightcoreController(traitRandom: Random(11));
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    controller.lumens = 100000;

    final initialBoard = controller.activeChildTowerUpgrades.toList();
    final initialLevel = controller.coreState.level;

    expect(initialBoard.map((upgrade) => upgrade.type).toSet(), hasLength(4));

    for (final upgrade in initialBoard) {
      for (
        var rank = upgrade.rank;
        rank < LightcoreController.childTowerUpgradeMaxRank;
        rank++
      ) {
        expect(controller.upgradeActiveChildTowerStat(upgrade.type), isTrue);
      }
    }

    expect(controller.coreState.level, initialLevel + 1);
    expect(
      controller.activeChildTowerProjection!.childCoreLevel,
      initialLevel + 1,
    );
    expect(
      controller.activeChildTowerUpgrades.every((upgrade) => upgrade.rank == 0),
      isTrue,
    );
    expect(
      controller.activeChildTowerUpgrades
          .map((upgrade) => upgrade.type)
          .toSet(),
      hasLength(4),
    );
    expect(controller.activeChildTowerLevelProgress, 0);
  });
}
