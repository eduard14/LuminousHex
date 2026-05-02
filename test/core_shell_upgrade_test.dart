import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('root shell level upgrades spend lumens and cap at max core level', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 100000;
    final initialLumens = controller.lumens;
    final firstCost = controller.coreLevelUpgradeCost;

    expect(controller.canUpgradeCoreLevel, isTrue);
    expect(firstCost, greaterThan(0));
    expect(controller.upgradeCoreLevel(), isTrue);
    expect(controller.coreState.level, 2);
    expect(controller.lumens, initialLumens - firstCost);

    while (controller.canUpgradeCoreLevel) {
      expect(controller.upgradeCoreLevel(), isTrue);
    }

    expect(controller.coreState.level, LightcoreController.maxCoreLevel);
    expect(controller.canUpgradeCoreLevel, isFalse);
    expect(controller.upgradeCoreLevel(), isFalse);
  });

  test('root shell stat upgrades use the core stat board', () {
    final controller = LightcoreController(traitRandom: Random(21));
    addTearDown(controller.dispose);

    controller.lumens = 100000;
    final damageUpgrade = controller.coreUpgradeOptions.firstWhere(
      (upgrade) => upgrade.type == TowerUpgradeStatType.power,
    );
    final initialLumens = controller.lumens;
    final firstCost = controller.coreStatUpgradeCost(damageUpgrade);
    final initialPower = controller.coreBasicShotPower;

    expect(controller.coreUpgradePointsSpent, 0);
    expect(firstCost, greaterThan(0));
    expect(controller.upgradeCoreStat(TowerUpgradeStatType.power), isTrue);

    final upgradedDamage = controller.coreUpgradeOptions.firstWhere(
      (upgrade) => upgrade.type == TowerUpgradeStatType.power,
    );
    expect(upgradedDamage.rank, 1);
    expect(controller.coreUpgradePointsSpent, 1);
    expect(controller.coreBasicShotPower, greaterThan(initialPower));
    expect(controller.lumens, initialLumens - firstCost);
  });
}
