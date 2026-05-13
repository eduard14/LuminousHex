import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/threat_region_configs.dart';
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
      expect(controller.offlineRegionId, starter.id);
      expect(controller.offlineRegionStabilizedLevel, 1);
    },
  );

  test('starter and ring one regions can be worked before layer 2', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final starter = ThreatRegionLibrary.all.first;
    final ringOne = ThreatRegionLibrary.all
        .where((region) => region.ring == 1)
        .toList(growable: false);
    final ringTwo = ThreatRegionLibrary.all.firstWhere(
      (region) => region.ring == 2,
    );

    expect(controller.bossHuntsUnlocked, isFalse);
    expect(controller.canStartThreatRegionChallenge(starter.id), isFalse);

    controller
      ..kills = LightcoreController.unlockKillsForOuterSlot(0)
      ..lumens = 1000;
    expect(controller.buildTowerAt(0, controller.towerConfigs.first), isTrue);
    expect(controller.canStartThreatRegionChallenge(starter.id), isTrue);
    expect(controller.startThreatRegionChallenge(starter.id), isTrue);
    expect(controller.failThreatRegionChallenge(), isFalse);

    controller.enemyTickets = ringOne.length;
    for (var index = 0; index < ringOne.length; index += 1) {
      final result = controller.scanThreatMap();
      expect(result, isNotNull);
      expect(result!.revealedNewRegion, isTrue);
      expect(result.region.ring, 1);
    }
    expect(
      ringOne.every(
        (region) => controller.threatRegionStateById(region.id)!.revealed,
      ),
      isTrue,
    );

    controller.debugRevealThreatRegion(ringTwo.id);
    expect(controller.canStartThreatRegionChallenge(ringTwo.id), isFalse);
    expect(controller.startThreatRegionChallenge(ringTwo.id), isFalse);
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

  test(
    'region echoes merge from stabilized regions into higher-ring reveal',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      _unlockRegionChallenges(controller);

      final starter = ThreatRegionLibrary.all.first;
      final ringOne = ThreatRegionLibrary.all.firstWhere(
        (region) => region.ring == 1,
      );
      controller.debugRevealThreatRegion(
        starter.id,
        stabilizedLevel: starter.stabilizationLayers,
      );
      controller.debugGrantRegionEcho(starter.id, 5);

      expect(
        controller.mergeRegionEchoesToReveal(
          sourceRegionId: starter.id,
          targetRegionId: ringOne.id,
        ),
        isTrue,
      );
      expect(controller.threatRegionStateById(ringOne.id)!.revealed, isTrue);
      expect(controller.regionEchoCount(starter.id), 0);

      final ringTwo = ThreatRegionLibrary.all.firstWhere(
        (region) => region.ring == 2,
      );
      controller.debugRevealThreatRegion(
        ringOne.id,
        stabilizedLevel: ringOne.stabilizationLayers,
      );
      controller.debugGrantRegionEcho(ringOne.id, 8);
      expect(
        controller.mergeRegionEchoesToReveal(
          sourceRegionId: ringOne.id,
          targetRegionId: ringTwo.id,
        ),
        isTrue,
      );
      expect(controller.regionEchoCount(ringOne.id), 0);

      final ringThree = ThreatRegionLibrary.all.firstWhere(
        (region) => region.ring == 3,
      );
      controller.debugRevealThreatRegion(
        ringTwo.id,
        stabilizedLevel: ringTwo.stabilizationLayers,
      );
      controller.debugGrantRegionEcho(ringTwo.id, 13);
      expect(
        controller.mergeRegionEchoesToReveal(
          sourceRegionId: ringTwo.id,
          targetRegionId: ringThree.id,
        ),
        isTrue,
      );
      expect(controller.regionEchoCount(ringTwo.id), 0);
    },
  );

  test('scans can hit revealed regions and award region echoes', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    _unlockFullThreatMap(controller);

    for (final region in ThreatRegionLibrary.all) {
      controller.debugRevealThreatRegion(region.id);
    }
    controller.enemyTickets = 20;

    controller.scanThreatMap(count: 20);

    final echoTotal = ThreatRegionLibrary.all.fold<int>(
      0,
      (sum, region) => sum + controller.regionEchoCount(region.id),
    );
    expect(echoTotal, 20);
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
    'manager swaps invalidate offline region validation until restabilized',
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
      expect(controller.threatRegionOfflineKillsPerHour, greaterThan(0));

      expect(
        controller.assignThreatDirectorToRegion(
          regionId: starter.id,
          managerId: secondManager.instanceId,
        ),
        isTrue,
      );
      expect(controller.threatRegionOfflineKillsPerHour, 0);

      expect(controller.startThreatRegionChallenge(starter.id), isTrue);
      expect(
        controller.completeThreatRegionChallenge(endingStabilityPercent: 100),
        isTrue,
      );
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
