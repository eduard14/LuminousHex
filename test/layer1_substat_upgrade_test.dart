import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('layer 1 towers roll 2-4 unique substats and lock the rest', () {
    final controller = LightcoreController(traitRandom: Random(3));
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);

    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    final tower = controller.slots[0];
    final rolledTypes = tower.towerUpgradeOptions.map(
      (upgrade) => upgrade.type,
    );
    final lockedTypes = controller.towerLockedUpgradeTypesFor(tower);

    expect(
      tower.towerUpgradeOptions.length,
      inInclusiveRange(
        LightcoreController.minTowerUpgradeOptions,
        LightcoreController.maxTowerUpgradeOptions,
      ),
    );
    expect(rolledTypes.toSet(), hasLength(tower.towerUpgradeOptions.length));
    expect(lockedTypes, isNotEmpty);
    expect(<TowerUpgradeStatType>{...rolledTypes, ...lockedTypes}.length, 13);
    expect(
      rolledTypes.contains(TowerUpgradeStatType.dotDamage) ||
          lockedTypes.contains(TowerUpgradeStatType.dotDamage),
      isFalse,
    );
  });

  test(
    'targeted layer 1 upgrades only rank rolled stats and leave locked stats unchanged',
    () {
      final controller = LightcoreController(traitRandom: Random(9));
      addTearDown(controller.dispose);

      controller.lumens = 1000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(0);

      expect(controller.buildTowerAt(0, TowerLibrary.bluePrism), isTrue);

      final before = controller.slots[0];
      final chosenUpgrade = before.towerUpgradeOptions.first;
      final lockedType = controller.towerLockedUpgradeTypesFor(before).first;
      final lockedValueBefore = controller.towerSubstatValueLabel(
        before,
        lockedType,
      );

      expect(controller.upgradeTowerStat(0, chosenUpgrade.type), isTrue);

      final after = controller.slots[0];
      final upgraded = after.towerUpgradeOptions.firstWhere(
        (upgrade) => upgrade.type == chosenUpgrade.type,
      );
      final unchangedRanks = after.towerUpgradeOptions
          .where((upgrade) => upgrade.type != chosenUpgrade.type)
          .every(
            (upgrade) =>
                before.towerUpgradeOptions
                    .firstWhere((previous) => previous.type == upgrade.type)
                    .rank ==
                upgrade.rank,
          );

      expect(after.level, before.level);
      expect(upgraded.rank, chosenUpgrade.rank + 1);
      expect(unchangedRanks, isTrue);
      expect(
        controller.towerSubstatValueLabel(after, lockedType),
        lockedValueBefore,
      );
      expect(
        controller.towerUpgradePointsRemaining(after),
        controller.towerUpgradePointsRemaining(before) - 1,
      );
    },
  );

  test('tower level upgrades are separate and improve live stats lightly', () {
    final controller = LightcoreController(traitRandom: Random(11));
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);

    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    final before = controller.slots[0];
    final powerBefore = controller.towerPower(before);
    final chargeBefore = controller.towerChargeRate(before);
    final cooldownBefore = controller.towerCooldown(before);
    final ranksBefore = before.towerUpgradeOptions.map(
      (upgrade) => upgrade.rank,
    );

    expect(controller.upgradeTower(0), isTrue);

    final after = controller.slots[0];
    expect(after.level, before.level + 1);
    expect(
      after.towerUpgradeOptions.map((upgrade) => upgrade.rank),
      orderedEquals(ranksBefore),
    );
    expect(controller.towerPower(after), greaterThan(powerBefore));
    expect(controller.towerChargeRate(after), greaterThan(chargeBefore));
    expect(controller.towerCooldown(after), lessThan(cooldownBefore));
  });
}
