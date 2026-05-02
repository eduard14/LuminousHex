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

void _maxOutActiveShell(LightcoreController controller) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    if (!controller.slots[index].isBuilt) {
      controller.buildTowerAt(index, TowerLibrary.all[index]);
    }
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  expect(controller.isPromotionReady, isTrue);
}

void _promoteChildShellIntoParent(
  LightcoreController controller,
  int slotIndex,
) {
  final parentLayerId = controller.activeLayer.parentLayerId;
  expect(parentLayerId, isNotNull);
  _maxOutActiveShell(controller);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.id, parentLayerId);
  expect(controller.slots[slotIndex].isPromotedChildTower, isTrue);
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
    controller.shellCores = 100000;

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
    controller.shellCores = 100000;

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

  test('promoted layer 2 towers get a fresh tower level and upgrade board', () {
    final controller = LightcoreController(traitRandom: Random(17));
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    final childLayerId = controller.activeLayer.id;
    _promoteChildShellIntoParent(controller, 0);

    final promotedTower = controller.slots[0];
    expect(promotedTower.isPromotedChildTower, isTrue);
    expect(promotedTower.level, 1);
    expect(promotedTower.childCoreLevel, 1);
    expect(promotedTower.towerUpgradeOptions, isNotEmpty);
    expect(promotedTower.towerUpgradeOptions.map((upgrade) => upgrade.rank), [
      for (
        var index = 0;
        index < promotedTower.towerUpgradeOptions.length;
        index++
      )
        0,
    ]);

    final powerBeforeLevel = controller.towerPower(promotedTower);
    controller.lumens = controller.upgradeCost(promotedTower);
    expect(controller.upgradeTower(0), isTrue);
    expect(controller.slots[0].level, 2);
    expect(
      controller.towerPower(controller.slots[0]),
      greaterThan(powerBeforeLevel),
    );

    final upgrade = controller.slots[0].towerUpgradeOptions.first;
    final statCost = controller.towerStatUpgradeCost(
      controller.slots[0],
      upgrade,
    );
    controller.lumens = statCost;
    expect(controller.upgradeTowerStat(0, upgrade.type), isTrue);
    expect(
      controller.slots[0].towerUpgradeOptions
          .firstWhere((candidate) => candidate.type == upgrade.type)
          .rank,
      1,
    );

    controller.enterChildLayer(0);
    expect(controller.activeLayer.id, childLayerId);
    expect(controller.activeLayerPassiveOnly, isTrue);
    expect(controller.activeLayerHasParentSlot, isTrue);
    controller.shellCores = 100000;
    expect(
      controller.upgradeActiveChildTowerStat(
        controller.activeChildTowerUpgrades.first.type,
      ),
      isFalse,
    );
    expect(controller.activeChildTowerProjection!.childCoreLevel, 1);
  });

  test('promoted layer 1 child cores keep core upgrades', () {
    final controller = LightcoreController(traitRandom: Random(19));
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    _promoteChildShellIntoParent(controller, 0);
    controller.enterChildLayer(0);

    expect(controller.activeLayerPassiveOnly, isTrue);
    expect(controller.canUpgradeCoreRange, isTrue);

    final rangeBefore = controller.towerEffectiveRange(
      controller.activeChildTowerProjection!,
    );
    controller.lumens = controller.coreRangeUpgradeCost;

    expect(controller.upgradeCoreRange(), isTrue);
    expect(controller.coreState.rangeUpgradeLevel, 1);
    expect(
      controller.towerEffectiveRange(controller.activeChildTowerProjection!),
      greaterThan(rangeBefore),
    );
  });
}
