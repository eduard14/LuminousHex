import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
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
      ? controller.towerPower(tower) * 31
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

void _buildMaxedSourceShell(LightcoreController controller) {
  controller.lumens = 1000000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
}

Map<String, dynamic> _towerStrengthSavePayload(int tier) {
  final layerId = 'tower-strength-layer-$tier';
  return <String, dynamic>{
    'player': <String, dynamic>{'playerId': 'TS-L$tier'},
    'layers': <String, dynamic>{
      'activeLayerId': layerId,
      'viewLayerId': layerId,
      'runtimeLayerId': layerId,
      'items': <Map<String, dynamic>>[
        _towerStrengthLayerPayload(layerId, tier),
      ],
    },
  };
}

Map<String, dynamic> _towerStrengthMultiLayerSavePayload({
  required int activeTier,
  required int highestTier,
}) {
  final activeLayerId = 'tower-strength-layer-$activeTier';
  final highestLayerId = 'tower-strength-layer-$highestTier';
  return <String, dynamic>{
    'player': <String, dynamic>{'playerId': 'TS-L$activeTier-L$highestTier'},
    'layers': <String, dynamic>{
      'activeLayerId': activeLayerId,
      'viewLayerId': activeLayerId,
      'runtimeLayerId': activeLayerId,
      'items': <Map<String, dynamic>>[
        _towerStrengthLayerPayload(activeLayerId, activeTier),
        _towerStrengthLayerPayload(highestLayerId, highestTier),
      ],
    },
  };
}

Map<String, dynamic> _towerStrengthLayerPayload(String layerId, int tier) {
  return <String, dynamic>{
    'id': layerId,
    'tier': tier,
    'label': LightcoreController.shellNameForTier(tier),
    'slots': _towerStrengthTowerSlots(),
    'core': <String, dynamic>{
      'coreStability': 100,
      'flowEfficiency': 100,
      'level': tier,
      'projectileType': ProjectileType.threadBeam.name,
      'payloadType': PayloadType.none.name,
      'affinity': PrototypeAffinity.aether.name,
    },
    'layer2': <String, dynamic>{
      'unlocked': tier > 1,
      'count': LightcoreController.slotCount,
      'projectileType': ProjectileType.threadBeam.name,
      'payloadType': PayloadType.none.name,
      'affinity': PrototypeAffinity.aether.name,
    },
    'activeEnemyCardIds': const <String>[],
    'enemyTargetCount': 1,
    'enemyTargetUpgradeLevel': 0,
    'outerRingRevealed': true,
    'swarmActivated': true,
    'childTowerUpgrades': const <Map<String, dynamic>>[],
  };
}

List<Map<String, dynamic>> _towerStrengthTowerSlots() {
  return List<Map<String, dynamic>>.generate(LightcoreController.slotCount, (
    index,
  ) {
    final config = TowerLibrary.all[index];
    return <String, dynamic>{
      'slotIndex': index,
      'configId': config.id,
      'level': LightcoreController.maxTowerLevel,
      'projectileType': config.defaultProjectileType.name,
      'payloadType': PayloadType.none.name,
    };
  });
}

EnemyConfig _basicEnemyForAffinity(PrototypeAffinity affinity) {
  return EnemyLibrary.all.firstWhere(
    (config) =>
        config.rarity == EnemyCardRarity.basic && config.affinity == affinity,
  );
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

  test('tower strength compounds into quadrillions by ascendant shell', () {
    final root = LightcoreController.fromCloudSavePayload(
      _towerStrengthSavePayload(1),
    );
    final ascendant = LightcoreController.fromCloudSavePayload(
      _towerStrengthSavePayload(4),
    );
    addTearDown(root.dispose);
    addTearDown(ascendant.dispose);

    expect(root.activeLayer.tier, 1);
    expect(ascendant.activeLayer.tier, 4);
    expect(root.towerStrength, lessThan(1000000));
    expect(ascendant.towerStrength, greaterThanOrEqualTo(1000000000000000));
    expect(
      ascendant.towerStrength,
      greaterThan(root.towerStrength * 100000000000),
    );
    expect(ascendant.towerStrengthCompactLabel, endsWith('Q'));
  });

  test('global ranking tower strength uses best current layer', () {
    final controller = LightcoreController.fromCloudSavePayload(
      _towerStrengthMultiLayerSavePayload(activeTier: 1, highestTier: 4),
    );
    addTearDown(controller.dispose);

    expect(controller.activeLayer.tier, 1);
    expect(controller.towerStrength, lessThan(1000000));
    expect(
      controller.globalRankingTowerStrength,
      greaterThanOrEqualTo(1000000000000000),
    );
    expect(
      controller.globalRankingTowerStrength,
      greaterThan(controller.towerStrength * 100000000000),
    );

    final payload = controller.buildCloudSavePayload();
    final socialSnapshot = payload['socialSnapshot'] as Map<String, dynamic>;
    expect(
      socialSnapshot['towerStrength'],
      controller.globalRankingTowerStrength,
    );
  });

  test('DPS budget scales down per active enemy target', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _buildMaxedSourceShell(controller);
    final fullShellDps = controller.activeLayerMaxDpsEstimate;
    final sixTargetBudget = controller.activeLayerMaxDpsPerEnemyEstimate;

    expect(fullShellDps, greaterThan(0));
    expect(
      sixTargetBudget,
      closeTo(fullShellDps / controller.enemyTargetCount, 0.001),
    );

    expect(controller.setEnemyTargetCount(controller.enemyTargetMax), isTrue);
    expect(
      controller.activeLayerMaxDpsPerEnemyEstimate,
      lessThan(sixTargetBudget),
    );
  });

  test('promoted core starts near a completed source shell DPS budget', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _buildMaxedSourceShell(controller);
    final fullSourceShellDps = controller.activeLayerMaxDpsEstimate;
    expect(controller.isPromotionReady, isTrue);

    controller.unlockLayer2Tower();

    expect(controller.activeLayer.tier, 2);
    expect(
      controller.activeLayerMaxDpsEstimate,
      greaterThan(fullSourceShellDps * 0.85),
    );
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
    final spawnRadii = firstCluster.map((enemy) => enemy.spawnRadius).toList();
    expect(
      spawnRadii.every(
        (radius) =>
            radius > controller.defaultTowerBaseRange &&
            radius < controller.spawnRadius,
      ),
      isTrue,
    );
    expect(
      spawnRadii
          .map((radius) => radius - controller.defaultTowerBaseRange)
          .reduce(max),
      lessThanOrEqualTo(140),
    );
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

  test('basic anomalies pressure the relay faster while still spiraling', () {
    final relayHits = <EnemyState>[];
    final controller = LightcoreController(
      relayHitListener: relayHits.add,
      spawnRandom: Random(4),
    );
    addTearDown(controller.dispose);

    final spawned = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: controller.spawnRadius,
    )!;

    controller.tick(8);
    final advanced = controller.enemies.single;
    expect((advanced.angle - spawned.angle).abs(), greaterThan(0.5));
    expect(relayHits, isEmpty);

    controller.tick(34);
    expect(relayHits, hasLength(1));
    expect(controller.enemies, isEmpty);
  });

  test('yellow anomalies blink inward unless shocked', () {
    final yellow = _basicEnemyForAffinity(PrototypeAffinity.solar);
    final blinking = LightcoreController(spawnRandom: Random(9));
    final shocked = LightcoreController(spawnRandom: Random(9));
    addTearDown(blinking.dispose);
    addTearDown(shocked.dispose);

    blinking.debugSpawnEnemyFromCard(
      yellow.id,
      angle: 0,
      radius: blinking.spawnRadius,
    );
    shocked.debugSpawnEnemyFromCard(
      yellow.id,
      angle: 0,
      radius: shocked.spawnRadius,
      shockRemaining: 5,
    );

    blinking.tick(2.2);
    shocked.tick(2.2);

    expect(
      blinking.enemies.single.radius,
      lessThan(shocked.enemies.single.radius - 45),
    );
  });

  test('purple split children spawn inward from the defeated parent', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final purple = _basicEnemyForAffinity(PrototypeAffinity.violet);

    final parent = controller.debugSpawnEnemyFromCard(
      purple.id,
      angle: 0,
      radius: 320,
    )!;

    expect(controller.debugDefeatEnemy(parent.id), isTrue);
    expect(controller.enemies, hasLength(2));
    expect(
      controller.enemies.every((enemy) => enemy.radius < parent.radius),
      isTrue,
    );
  });

  test('relay stability damage scales with remaining enemy health', () {
    double leakDamageForHealth(double healthFraction) {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: -pi / 2,
        radius: controller.relayImpactRadius + 1,
        healthFraction: healthFraction,
      );
      controller.tick(0.1);
      return controller.coreDamageAmount;
    }

    final fullHealthDamage = leakDamageForHealth(1);
    final lowHealthDamage = leakDamageForHealth(0.1);

    expect(fullHealthDamage, greaterThan(lowHealthDamage * 2));
  });

  test('empty lane leaks remain harsher than occupied lane leaks', () {
    final emptyLane = LightcoreController();
    final occupiedLane = LightcoreController();
    addTearDown(emptyLane.dispose);
    addTearDown(occupiedLane.dispose);

    occupiedLane.lumens = 10000;
    expect(occupiedLane.buildTowerAt(0, TowerLibrary.bluePrism), isTrue);

    for (final controller in <LightcoreController>[emptyLane, occupiedLane]) {
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: -pi / 2,
        radius: controller.relayImpactRadius + 1,
      );
      controller.tick(0.1);
    }

    expect(
      emptyLane.coreDamageAmount,
      greaterThan(occupiedLane.coreDamageAmount),
    );
  });
}
