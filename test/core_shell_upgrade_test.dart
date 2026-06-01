import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
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

  test('core energy is locked before nexus shells', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.coreEnergyUnlocked, isFalse);
    expect(controller.coreEnergyRatio, 1);
    expect(controller.upgradeCoreEnergyCapacity(), isFalse);

    expect(controller.debugSeedProgressionLayer(2), isTrue);
    expect(controller.coreEnergyUnlocked, isFalse);
    expect(controller.coreEnergyRatio, 1);
    expect(controller.upgradeCoreEnergyRecovery(), isFalse);
  });

  test('nexus energy spends, recovers, and softens core output', () {
    double firedShotPower({required double energy}) {
      final controller = LightcoreController(traitRandom: Random(5));
      addTearDown(controller.dispose);
      expect(controller.debugSeedProgressionLayer(3), isTrue);
      controller.debugSetCoreEnergy(energy);
      final enemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 260,
      );
      expect(enemy, isNotNull);
      controller.debugSetAmmoQueue([
        const AmmoPacket(
          id: 'energy_test_packet',
          sourceSlotIndex: null,
          affinity: PrototypeAffinity.aether,
          power: 6.5,
          advantageMultiplier: 1,
          projectileType: ProjectileType.lanceBeam,
          payloadType: PayloadType.none,
          targetPriority: TargetPriority.close,
          range: 320,
          critChance: 0,
          critMultiplier: 1,
          finalDamageMultiplier: 1,
          bossDamageMultiplier: 1,
          normalDamageMultiplier: 1,
          defensePenetration: 0,
          minDamageMultiplier: 1,
          maxDamageMultiplier: 1,
        ),
      ]);
      controller.selectCenter();
      expect(controller.selectBattleEnemyForManualAim(enemy!.id), isTrue);
      controller.tick(0.05);
      expect(controller.shots, isNotEmpty);
      return controller.shots.first.power;
    }

    final fullEnergyPower = firedShotPower(energy: 100);
    final lowEnergyPower = firedShotPower(energy: 0);

    expect(lowEnergyPower, lessThan(fullEnergyPower * 0.94));

    final controller = LightcoreController(traitRandom: Random(7));
    addTearDown(controller.dispose);
    expect(controller.debugSeedProgressionLayer(3), isTrue);
    expect(controller.coreEnergyUnlocked, isTrue);
    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 260,
    );
    expect(enemy, isNotNull);
    controller.handleBattleCenterTap();
    expect(controller.selectBattleEnemyForManualAim(enemy!.id), isTrue);
    controller.tick(0.7);
    final spentEnergy = controller.coreState.coreEnergy;
    expect(spentEnergy, closeTo(96, 0.001));

    controller.tick(1.0);
    expect(controller.coreState.coreEnergy, greaterThan(spentEnergy));

    final fullRecovery = LightcoreController();
    final lowRecovery = LightcoreController();
    addTearDown(fullRecovery.dispose);
    addTearDown(lowRecovery.dispose);
    expect(fullRecovery.debugSeedProgressionLayer(3), isTrue);
    expect(lowRecovery.debugSeedProgressionLayer(3), isTrue);
    fullRecovery.debugSetCoreStability(50);
    lowRecovery.debugSetCoreStability(50);
    fullRecovery.debugSetCoreEnergy(100);
    lowRecovery.debugSetCoreEnergy(0);

    fullRecovery.tick(1.0);
    lowRecovery.tick(1.0);

    expect(
      fullRecovery.coreState.coreStability - 50,
      greaterThan(lowRecovery.coreState.coreStability - 50),
    );
  });

  test('nexus energy upgrades cap and survive save restore', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    expect(controller.debugSeedProgressionLayer(3), isTrue);
    controller.lumens = 100000;

    final firstCapacityCost = controller.coreEnergyCapacityUpgradeCost;
    expect(firstCapacityCost, greaterThan(0));
    expect(controller.upgradeCoreEnergyCapacity(), isTrue);
    expect(controller.coreEnergyCapacity, 120);
    expect(controller.coreState.coreEnergy, 120);

    expect(controller.upgradeCoreEnergyRecovery(), isTrue);
    expect(controller.coreEnergyRecoveryPerSecond, closeTo(8.4, 0.001));

    while (controller.canUpgradeCoreEnergyCapacity) {
      expect(controller.upgradeCoreEnergyCapacity(), isTrue);
    }
    while (controller.canUpgradeCoreEnergyRecovery) {
      expect(controller.upgradeCoreEnergyRecovery(), isTrue);
    }
    expect(controller.canUpgradeCoreEnergyCapacity, isFalse);
    expect(controller.canUpgradeCoreEnergyRecovery, isFalse);
    expect(controller.coreEnergyCapacity, 200);
    expect(controller.coreEnergyRecoveryPerSecond, closeTo(14, 0.001));

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);
    expect(restored.coreEnergyUnlocked, isTrue);
    expect(restored.coreEnergyCapacity, 200);
    expect(restored.coreEnergyRecoveryPerSecond, closeTo(14, 0.001));
    expect(restored.coreState.coreEnergy, 200);
  });
}
