import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/threat_region_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _unlockRegionChallenges(LightcoreController controller) {
  expect(controller.debugSeedProgressionLayer(2), isTrue);
}

void _unlockFullThreatMap(LightcoreController controller) {
  _unlockRegionChallenges(controller);
  final starter = ThreatRegionLibrary.all.first;
  controller.debugRevealThreatRegion(
    starter.id,
    stabilizedLevel: starter.stabilizationLayers,
  );
  controller.debugGrantApexCore(starter.primaryBossId);
}

void _debugStabilizeRouteBefore(
  LightcoreController controller,
  ThreatRegionConfig target,
) {
  final targetIndex = ThreatRegionLibrary.all.indexWhere(
    (region) => region.id == target.id,
  );
  for (var index = 0; index < targetIndex; index += 1) {
    final region = ThreatRegionLibrary.all[index];
    controller.debugRevealThreatRegion(
      region.id,
      stabilizedLevel: region.stabilizationLayers,
    );
  }
}

void main() {
  test('threat map has 37 fixed axial hexes across three complete rings', () {
    final regions = ThreatRegionLibrary.all;

    expect(regions, hasLength(37));
    for (var ring = 0; ring <= 3; ring += 1) {
      final ringRegions = regions.where((region) => region.ring == ring);
      expect(ringRegions, hasLength(ring == 0 ? 1 : ring * 6));
      for (final region in ringRegions) {
        expect(ThreatRegionLibrary.hexDistance(region.q, region.r), ring);
      }
    }

    expect(
      regions.where((region) => region.ring == 0).single.stabilizationLayers,
      3,
    );
    expect(
      regions.where((region) => region.ring == 1).first.stabilizationLayers,
      5,
    );
    expect(
      regions.where((region) => region.ring == 2).first.stabilizationLayers,
      8,
    );
    expect(
      regions.where((region) => region.ring == 3).first.stabilizationLayers,
      13,
    );
    expect(
      regions.where((region) => region.ring == 3 && region.hasDoubleBoss),
      hasLength(3),
    );
    for (var index = 1; index < regions.length; index += 1) {
      final previous = regions[index - 1];
      final current = regions[index];
      expect(
        ThreatRegionLibrary.hexDistance(
          current.q - previous.q,
          current.r - previous.r,
        ),
        1,
      );
    }
  });

  test('rarer threat combinations live farther from center', () {
    final maxByRing = <int, int>{
      for (var ring = 0; ring <= 3; ring += 1)
        ring: ThreatRegionLibrary.all
            .where((region) => region.ring == ring)
            .map((region) => region.rarity.index)
            .reduce((left, right) => left > right ? left : right),
    };

    expect(maxByRing[0], EnemyCardRarity.basic.index);
    expect(maxByRing[1]! >= EnemyCardRarity.uncommon.index, isTrue);
    expect(maxByRing[2]! >= EnemyCardRarity.epic.index, isTrue);
    expect(maxByRing[3], EnemyCardRarity.legendary.index);
  });

  test(
    'failed and successful stabilization challenges preserve state rules',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      _unlockRegionChallenges(controller);

      final starter = ThreatRegionLibrary.all.first;
      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(controller.failThreatRegionChallenge(), isFalse);
      expect(controller.threatRegionStateById(starter.id)!.stabilizedLevel, 0);

      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(
        controller.completeThreatRegionChallenge(endingStabilityPercent: 100),
        isTrue,
      );
      expect(controller.threatRegionStateById(starter.id)!.stabilizedLevel, 1);
      expect(controller.offlineRegionId, isNull);
      expect(controller.offlineRegionStabilizedLevel, 0);
    },
  );

  test('linear route reveals one next region at a time', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final starter = ThreatRegionLibrary.all.first;
    final nextRegion = ThreatRegionLibrary.all[1];
    final ringTwo = ThreatRegionLibrary.all.firstWhere(
      (region) => region.ring == 2,
    );

    expect(controller.bossHuntsUnlocked, isFalse);
    expect(controller.canStartThreatRegionChallenge(starter.id), isFalse);
    expect(controller.threatRegionStateById(nextRegion.id)!.revealed, isFalse);

    controller
      ..kills = LightcoreController.unlockKillsForOuterSlot(0)
      ..lumens = 1000;
    expect(controller.buildTowerAt(0, controller.towerConfigs.first), isTrue);
    expect(controller.canStartThreatRegionChallenge(starter.id), isTrue);
    expect(controller.canStartThreatRegionChallenge(nextRegion.id), isFalse);

    for (var level = 1; level <= starter.stabilizationLayers; level += 1) {
      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(
        controller.completeThreatRegionChallenge(
          endingStabilityPercent: 100,
          defeatedBossIds: level == starter.stabilizationLayers
              ? {starter.primaryBossId}
              : null,
        ),
        isTrue,
      );
    }

    expect(controller.threatRegionStateById(nextRegion.id)!.revealed, isTrue);
    expect(controller.canStartThreatRegionChallenge(nextRegion.id), isTrue);

    controller.debugRevealThreatRegion(ringTwo.id);
    expect(controller.canStartThreatRegionChallenge(ringTwo.id), isFalse);
  });

  test('starter challenge uses standard swarm and rewards the next push', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final starter = ThreatRegionLibrary.all.first;
    controller
      ..kills = LightcoreController.unlockKillsForOuterSlot(0)
      ..lumens = 1000;
    expect(controller.buildTowerAt(0, controller.towerConfigs.first), isTrue);

    final baselineTargetCount = controller.enemyTargetCount;
    final baselineStats = controller.activeThreatAssignmentGroupStats;
    final startingLumens = controller.lumens;

    expect(controller.startThreatRegionChallenge(starter.id), isTrue);

    expect(controller.enemyTargetCount, baselineTargetCount);
    expect(
      controller.activeThreatAssignmentGroupStats.anomalyCount,
      greaterThan(baselineStats.anomalyCount),
    );

    expect(
      controller.completeThreatRegionChallenge(endingStabilityPercent: 100),
      isTrue,
    );
    expect(controller.lumens, greaterThan(startingLumens));
    expect(controller.threatRegionStateById(starter.id)!.stabilizedLevel, 1);
    expect(controller.enemyTargetCount, baselineTargetCount);
  });

  test(
    'stabilization challenges use waves without exp or upgrade progress',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      final starter = ThreatRegionLibrary.all.first;
      controller
        ..kills = LightcoreController.unlockKillsForOuterSlot(0)
        ..lumens = 1000;
      expect(controller.buildTowerAt(0, controller.towerConfigs.first), isTrue);
      final startingLevel = controller.slots[0].level;
      final startingExperience = controller.experience;
      final startingKills = controller.kills;

      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(controller.bannerMessage, isEmpty);
      expect(controller.activeThreatRegionChallenge!.waveIndex, 0);
      expect(
        controller.activeThreatRegionChallengeWaveRemainingSeconds,
        closeTo(30, 0.001),
      );

      controller.tick(41);

      expect(controller.activeThreatRegionChallenge, isNotNull);
      expect(controller.activeThreatRegionChallenge!.waveIndex, 1);
      expect(
        controller.activeThreatRegionChallengeWaveRemainingSeconds,
        lessThan(30),
      );

      final enemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 140,
      );
      expect(enemy, isNotNull);
      expect(controller.debugDefeatEnemy(enemy!.id), isTrue);
      expect(controller.experience, startingExperience);
      expect(controller.kills, startingKills);

      controller.pushNotification('Hidden while the challenge runs.');
      expect(controller.bannerMessage, isEmpty);

      controller.lumens = controller.upgradeCost(controller.slots[0]);
      expect(controller.upgradeTower(0), isFalse);
      expect(controller.slots[0].level, startingLevel);
    },
  );

  test('farm validation stores offline snapshot with account swarm', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final starter = ThreatRegionLibrary.all.first;
    controller
      ..kills = LightcoreController.unlockKillsForOuterSlot(0)
      ..lumens = 1000;
    expect(controller.buildTowerAt(0, controller.towerConfigs.first), isTrue);
    controller.setEnemyTargetCount(12);

    expect(controller.startThreatRegionChallenge(starter.id), isTrue);
    expect(
      controller.completeThreatRegionChallenge(endingStabilityPercent: 100),
      isTrue,
    );
    expect(controller.threatRegionOfflineKillsPerHour, 0);
    expect(controller.canStartThreatRegionFarmValidation(starter.id), isTrue);

    controller.debugValidateThreatRegionFarm(starter.id);

    expect(controller.offlineRegionId, starter.id);
    expect(controller.offlineRegionStabilizedLevel, 1);
    expect(controller.validatedFarmSwarmSize, 12);
    expect(controller.threatRegionOfflineKillsPerHour, greaterThan(0));
    expect(controller.threatRegionOfflineLumensPerHour, greaterThan(0));
    final snapshot = controller.buildOfflineProgressSnapshot();
    expect(snapshot.killsPerHour, controller.threatRegionOfflineKillsPerHour);
    expect(
      snapshot.passiveLumensPerHour,
      controller.threatRegionOfflineLumensPerHour,
    );

    controller.debugGrantSwarmMagnets(1);
    expect(controller.rerollFarmSwarmSize(), isTrue);
    expect(controller.threatRegionOfflineKillsPerHour, 0);
    expect(controller.threatRegionOfflineLumensPerHour, 0);
    expect(controller.offlineRegionId, isNull);
  });

  test(
    'final stabilization grants boss-driven suite pieces and anomaly cards',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      _unlockRegionChallenges(controller);

      final starter = ThreatRegionLibrary.all.first;
      controller.debugRevealThreatRegion(
        starter.id,
        stabilizedLevel: starter.stabilizationLayers - 1,
      );

      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(
        controller.completeThreatRegionChallenge(
          endingStabilityPercent: 100,
          defeatedBossIds: {starter.primaryBossId},
        ),
        isTrue,
      );

      expect(
        controller.threatRegionStateById(starter.id)!.stabilizedLevel,
        starter.stabilizationLayers,
      );
      expect(
        controller.apexCores
            .singleWhere((core) => core.bossConfig.id == starter.primaryBossId)
            .isOwned,
        isTrue,
      );
      expect(
        controller.bossTraits
            .singleWhere(
              (trait) => trait.config.sourceBossId == starter.primaryBossId,
            )
            .isOwned,
        isTrue,
      );
      expect(
        starter.anomalyCardIds
            .map(controller.enemyCardById)
            .every((card) => card?.isOwned ?? false),
        isTrue,
      );
      expect(controller.hasCompleteEnemySuite, isTrue);
      expect(controller.activeEnemySuite.apexCoreBossId, starter.primaryBossId);
      expect(controller.activeEnemySuite.bossTraitIds, <String>[
        'trait_${starter.primaryBossId}',
        'trait_${starter.primaryBossId}',
      ]);
    },
  );

  test('double-boss final layers require both bosses defeated', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    _unlockFullThreatMap(controller);

    final doubleBossRegion = ThreatRegionLibrary.all.firstWhere(
      (region) => region.hasDoubleBoss,
    );
    _debugStabilizeRouteBefore(controller, doubleBossRegion);
    controller.debugRevealThreatRegion(
      doubleBossRegion.id,
      stabilizedLevel: doubleBossRegion.stabilizationLayers - 1,
    );

    expect(controller.startThreatRegionChallenge(doubleBossRegion.id), isTrue);
    expect(
      controller.completeThreatRegionChallenge(
        endingStabilityPercent: 100,
        defeatedBossIds: {doubleBossRegion.primaryBossId},
      ),
      isFalse,
    );
    expect(
      controller.threatRegionStateById(doubleBossRegion.id)!.stabilizedLevel,
      doubleBossRegion.stabilizationLayers - 1,
    );

    expect(controller.startThreatRegionChallenge(doubleBossRegion.id), isTrue);
    expect(
      controller.completeThreatRegionChallenge(
        endingStabilityPercent: 100,
        defeatedBossIds: {
          doubleBossRegion.primaryBossId,
          doubleBossRegion.secondaryBossId!,
        },
      ),
      isTrue,
    );
    expect(
      controller.threatRegionStateById(doubleBossRegion.id)!.stabilizedLevel,
      doubleBossRegion.stabilizationLayers,
    );
    expect(
      controller.apexCores
          .singleWhere(
            (core) => core.bossConfig.id == doubleBossRegion.primaryBossId,
          )
          .isOwned,
      isTrue,
    );
    expect(
      controller.apexCores
          .singleWhere(
            (core) => core.bossConfig.id == doubleBossRegion.secondaryBossId,
          )
          .isOwned,
      isTrue,
    );
  });

  test('arena suite gate requires 1 apex core, 2 traits, and 3 anomalies', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final starter = ThreatRegionLibrary.all.first;
    final secondBoss = ThreatRegionLibrary.all[1].primaryBossId;
    controller.debugRevealThreatRegion(
      starter.id,
      stabilizedLevel: starter.stabilizationLayers,
    );
    controller.debugGrantApexCore(starter.primaryBossId);
    controller.debugGrantBossTraitForBoss(starter.primaryBossId);
    controller.debugGrantBossTraitForBoss(secondBoss);
    for (final anomalyId in starter.anomalyCardIds) {
      controller.debugGrantEnemyCardById(anomalyId);
    }

    expect(
      controller.setActiveEnemySuite(
        apexCoreBossId: starter.primaryBossId,
        bossTraitIds: ['trait_${starter.primaryBossId}', 'trait_$secondBoss'],
        anomalyCardIds: starter.anomalyCardIds,
      ),
      isTrue,
    );
    expect(controller.hasCompleteEnemySuite, isTrue);
    expect(controller.arenaEnemySuiteReady, isTrue);
  });

  test(
    'manager swaps invalidate offline farm validation until revalidated',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      _unlockRegionChallenges(controller);

      controller
        ..experience = LightcoreController.experienceForOverallLevel(
          LightcoreController.managerUnlockLevel,
        )
        ..kills = LightcoreController.killsForOverallLevel(
          LightcoreController.managerUnlockLevel,
        )
        ..flux = 100000;
      expect(controller.forgeEnemyManagerBatch(2), isTrue);

      final starter = ThreatRegionLibrary.all.first;
      final firstManager = controller.enemyManagers[0];
      final secondManager = controller.enemyManagers[1];
      expect(
        controller.assignThreatDirectorToRegion(
          regionId: starter.id,
          managerId: firstManager.instanceId,
        ),
        isTrue,
      );
      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(
        controller.completeThreatRegionChallenge(endingStabilityPercent: 100),
        isTrue,
      );
      expect(controller.threatRegionOfflineKillsPerHour, 0);
      controller.debugValidateThreatRegionFarm(starter.id);
      expect(controller.threatRegionOfflineKillsPerHour, greaterThan(0));

      expect(
        controller.assignThreatDirectorToRegion(
          regionId: starter.id,
          managerId: secondManager.instanceId,
        ),
        isTrue,
      );
      expect(controller.threatRegionOfflineKillsPerHour, 0);

      controller.debugValidateThreatRegionFarm(starter.id);
      expect(controller.threatRegionOfflineKillsPerHour, greaterThan(0));
    },
  );

  test('fully stabilized regions grant permanent inventory effects', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    _unlockRegionChallenges(controller);

    final starter = ThreatRegionLibrary.all.first;
    expect(controller.regionInventoryBonuses.isEmpty, isTrue);

    controller.debugRevealThreatRegion(
      starter.id,
      stabilizedLevel: starter.stabilizationLayers,
    );

    expect(controller.regionInventoryBonuses.isEmpty, isFalse);
    expect(
      controller.regionInventoryBonuses.power,
      starter.inventoryEffect.power,
    );
  });
}
