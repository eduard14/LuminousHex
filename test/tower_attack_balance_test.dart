import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

double _sourceTowerBalanceScore(
  LightcoreController controller,
  TowerConfig config,
) {
  final tower = OuterTowerState(
    slotIndex: 0,
    config: config,
    payloadType: PayloadType.none,
  );
  final passiveShieldScore = controller.towerUsesPersistentShieldRing(tower)
      ? controller.towerPower(tower) * 24
      : 0.0;
  return (controller.towerPower(tower) * 2.8) +
      (controller.towerChargeRate(tower) * 90) +
      ((1 / max(0.1, controller.towerLiveCooldown(tower))) * 60) +
      (controller.towerEffectiveRange(tower) * 0.16) +
      (controller.towerGenerationSpeed(tower) * 70) +
      passiveShieldScore +
      (controller.towerCritChance(tower) * 260) +
      (controller.towerCritMultiplier(tower) * 38) +
      (controller.towerFinalDamageMultiplier(tower) * 54) +
      (controller.towerBossDamageMultiplier(tower) * 44) +
      (controller.towerNormalDamageMultiplier(tower) * 36) +
      (controller.towerDefensePenetration(tower) * 240) +
      (tower.level * 24) +
      18;
}

void main() {
  test('tower damage output is globally halved', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    const redTower = OuterTowerState(
      slotIndex: 0,
      config: TowerLibrary.redPrism,
      payloadType: PayloadType.none,
    );
    const promotedTower = OuterTowerState(
      slotIndex: 1,
      childLayerId: 'child-shell',
      childLayerTier: 1,
      childCoreLevel: 1,
      childPromoted: true,
    );
    final inventoryPowerMultiplier = 1 + controller.towerInventoryBonuses.power;
    final profilePowerMultiplier =
        1 +
        controller.profileLoadoutBonuses.towerPower +
        controller.globalLevelBonuses.towerPower;

    expect(
      controller.towerPower(redTower),
      closeTo(
        TowerLibrary.redPrism.basePower *
            0.5 *
            inventoryPowerMultiplier *
            profilePowerMultiplier *
            controller.friendAllianceCombatMultiplier,
        0.001,
      ),
    );
    expect(
      controller.towerPower(promotedTower),
      closeTo(
        11.4 *
            0.5 *
            inventoryPowerMultiplier *
            profilePowerMultiplier *
            controller.friendAllianceCombatMultiplier,
        0.001,
      ),
    );
  });

  test('source tower opening strengths stay evenly distributed', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final scores = <String, double>{
      for (final config in TowerLibrary.all)
        config.id: _sourceTowerBalanceScore(controller, config),
    };
    final lowestScore = scores.values.reduce(min);
    final highestScore = scores.values.reduce(max);

    expect(highestScore / lowestScore, lessThanOrEqualTo(1.16));
  });

  test(
    'core baseline starts slow enough and uses the shared midpoint range',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      final midpointRange =
          controller.relayImpactRadius +
          ((controller.spawnRadius - controller.relayImpactRadius) * (2 / 3));

      expect(controller.coreShotCooldown, greaterThan(0.7));
      expect(controller.coreBaseRange, closeTo(midpointRange, 0.001));
      expect(
        controller.coreEffectiveRange,
        closeTo(midpointRange * 0.9, 0.001),
      );
      expect(
        controller.coreEffectiveRange,
        lessThan(controller.spawnCeilingRadius),
      );

      expect(
        controller.coreShotCooldownForUpgradeLevel(1),
        lessThan(controller.coreShotCooldown),
      );
      expect(
        controller.coreEffectiveRangeForUpgradeLevel(
          1,
          projectileType: ProjectileType.threadBeam,
        ),
        greaterThan(controller.coreEffectiveRange),
      );
    },
  );

  test(
    'thread and purple wave towers keep manual cadence with midpoint default range',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      const threadTower = OuterTowerState(
        slotIndex: 0,
        config: TowerLibrary.bluePrism,
        payloadType: PayloadType.none,
      );
      const purpleWaveTower = OuterTowerState(
        slotIndex: 1,
        config: TowerLibrary.purplePrism,
        payloadType: PayloadType.none,
      );
      const redTower = OuterTowerState(
        slotIndex: 2,
        config: TowerLibrary.redPrism,
        payloadType: PayloadType.none,
      );
      final threadBaseRange = controller.towerBaseRange(threadTower);
      final purpleBaseRange = controller.towerBaseRange(purpleWaveTower);

      expect(
        controller.defaultTowerBaseRange,
        closeTo(
          controller.relayImpactRadius +
              ((controller.spawnRadius - controller.relayImpactRadius) *
                  (2 / 3)),
          0.001,
        ),
      );

      expect(
        controller.towerLiveCooldownForProjectile(
          threadTower,
          ProjectileType.threadBeam,
        ),
        greaterThan(1.18),
      );
      expect(threadBaseRange, closeTo(controller.defaultTowerBaseRange, 0.001));
      final threadEffectiveRange = controller.towerEffectiveRangeForProjectile(
        threadTower,
        ProjectileType.threadBeam,
      );
      expect(threadEffectiveRange, greaterThan(threadBaseRange * 0.9));
      expect(threadEffectiveRange, lessThan(threadBaseRange * 0.91));

      expect(
        controller.towerLiveCooldownForProjectile(
          purpleWaveTower,
          ProjectileType.pulseRing,
        ),
        greaterThan(1.0),
      );
      expect(controller.towerGenerationSpeed(redTower), lessThan(0.7));
      expect(purpleBaseRange, closeTo(controller.defaultTowerBaseRange, 0.001));
      final purpleEffectiveRange = controller.towerEffectiveRangeForProjectile(
        purpleWaveTower,
        ProjectileType.pulseRing,
      );
      expect(purpleEffectiveRange, greaterThan(purpleBaseRange * 1.02));
      expect(purpleEffectiveRange, lessThan(purpleBaseRange * 1.03));
    },
  );

  test('layer 1 tower base range follows core range upgrades', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    const tower = OuterTowerState(
      slotIndex: 0,
      config: TowerLibrary.redPrism,
      payloadType: PayloadType.none,
    );

    expect(
      controller.towerBaseRange(tower),
      closeTo(controller.coreBaseRange, 0.001),
    );

    controller.lumens = 1000;
    expect(controller.upgradeCoreRange(), isTrue);
    expect(
      controller.towerBaseRange(tower),
      closeTo(controller.coreBaseRange, 0.001),
    );
  });

  test('promoted child towers keep their inherited range bump', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final inheritedRange = controller.defaultTowerBaseRange;
    final promotedTower = OuterTowerState(
      slotIndex: 0,
      fireSequence: 1,
      childLayerId: 'child-shell',
      childProjectileType: ProjectileType.threadBeam,
      childProjectileLoadout: const <ProjectileType>[ProjectileType.threadBeam],
      childPayloadType: PayloadType.none,
      childPayloadLoadout: const <PayloadType>[PayloadType.none],
      childRange: inheritedRange,
      childCoreLevel: 1,
      childPromoted: true,
    );

    expect(
      controller.towerBaseRange(promotedTower),
      closeTo(inheritedRange * 1.15, 0.001),
    );

    controller.lumens = 1000;
    expect(controller.upgradeCoreRange(), isTrue);
    expect(
      controller.towerBaseRange(promotedTower),
      closeTo(inheritedRange * 1.15, 0.001),
    );
  });

  test('spawn radius grows once the swarm target climbs', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final idleSpawnRadius = controller.spawnRadius;

    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.bluePrism), isTrue);

    final baselineSpawnRadius = controller.spawnRadius;
    expect(baselineSpawnRadius, closeTo(idleSpawnRadius, 0.001));

    expect(controller.setEnemyTargetCount(controller.enemyTargetMax), isTrue);

    expect(controller.spawnRadius, greaterThan(baselineSpawnRadius));
  });

  test('baseline swarm pressure starts denser and spawns in clusters', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.enemyTargetFloor, 6);
    expect(controller.enemyTargetMax, 20);

    controller.selectCenter();
    controller.tick(8);

    expect(controller.enemyCount, greaterThanOrEqualTo(3));
    final firstCluster = controller.enemies.take(3).toList();
    final angles = firstCluster.map((enemy) => enemy.angle).toList()..sort();
    expect(angles.last - angles.first, lessThan(0.14));
  });

  test('spawn random seed changes entry points while preserving clusters', () {
    final firstController = LightcoreController(spawnRandom: Random(1));
    final secondController = LightcoreController(spawnRandom: Random(2));
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);

    for (final controller in <LightcoreController>[
      firstController,
      secondController,
    ]) {
      controller.selectCenter();
      controller.tick(8);
      expect(controller.enemyCount, greaterThanOrEqualTo(3));
    }

    expect(
      firstController.enemies.first.angle,
      isNot(equals(secondController.enemies.first.angle)),
    );

    final firstClusterAngles =
        firstController.enemies.take(3).map((enemy) => enemy.angle).toList()
          ..sort();
    expect(firstClusterAngles.last - firstClusterAngles.first, lessThan(0.14));
  });
}
