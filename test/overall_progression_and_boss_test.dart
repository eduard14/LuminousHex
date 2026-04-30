import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _buildMaxedRing(LightcoreController controller) {
  controller.applyOfflineClaim(
    const LightcoreOfflineClaimResult(
      secondsClaimed: 3600,
      lumensGranted: 0,
      fluxGranted: 0,
      enemyTicketsGranted: 0,
      killsGranted: 2000,
      serverValidated: true,
    ),
    showBanner: false,
  );
  controller.lumens = 200000;
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  controller.setEnemyTargetCount(controller.enemyTargetMax);
}

void _assignManagersToActiveRing(LightcoreController controller) {
  expect(controller.managersUnlocked, isTrue);
  controller.flux +=
      LightcoreController.towerManagerFluxCost * LightcoreController.slotCount;
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    expect(controller.forgeTowerManager(), isTrue);
    controller.equipCardToSlot(controller.cards.last.instanceId, index);
  }
}

void _unlockBossHunts(LightcoreController controller) {
  if (!controller.isPromotionReady) {
    _buildMaxedRing(controller);
  }
  if (!controller.bossHuntsUnlocked) {
    controller.unlockLayer2Tower();
  }
}

void main() {
  test('overall kill level progress tracks cumulative kills', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final level3Floor = LightcoreController.killsForOverallLevel(3);
    final level4Floor = LightcoreController.killsForOverallLevel(4);

    controller.applyOfflineClaim(
      LightcoreOfflineClaimResult(
        secondsClaimed: 7200,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: level3Floor + 5,
        serverValidated: true,
      ),
      showBanner: false,
    );

    expect(controller.overallLevel, 3);
    expect(controller.killsIntoCurrentOverallLevel, 5);
    expect(
      controller.overallLevelProgress,
      closeTo(5 / (level4Floor - level3Floor), 0.0001),
    );
  });

  test('overall level curve compounds each level requirement', () {
    var previousGap =
        LightcoreController.experienceForOverallLevel(2) -
        LightcoreController.experienceForOverallLevel(1);
    expect(previousGap, 40);

    for (var level = 3; level <= 100; level++) {
      final gap =
          LightcoreController.experienceForOverallLevel(level) -
          LightcoreController.experienceForOverallLevel(level - 1);
      expect(gap, greaterThan(previousGap));
      previousGap = gap;
    }

    expect(
      LightcoreController.experienceForOverallLevel(101),
      greaterThan(LightcoreController.experienceForOverallLevel(100)),
    );
  });

  test('account radiance points are player allocated into tower stats', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.applyOfflineClaim(
      LightcoreOfflineClaimResult(
        secondsClaimed: 1,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: LightcoreController.unlockKillsForOuterSlot(0),
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.lumens = 5000;
    controller.buildTowerAt(0, TowerLibrary.redPrism);
    final powerBefore = controller.towerPower(controller.slots[0]);

    controller.experience = LightcoreController.experienceForOverallLevel(60);

    expect(controller.unspentRadianceStatPoints, 59);
    expect(controller.globalLevelBonuses.towerPower, 0);
    expect(controller.globalLevelStatsSummaryLabel, contains('Might 0'));
    final powerWithoutAllocatedStats = controller.towerPower(
      controller.slots[0],
    );

    expect(controller.upgradeRadianceStat(LightcoreRadianceStat.might), isTrue);

    expect(controller.unspentRadianceStatPoints, 58);
    expect(controller.globalLevelBonuses.towerPower, greaterThan(0));
    expect(controller.globalLevelStatsSummaryLabel, contains('Might 1'));
    expect(
      controller.towerPower(controller.slots[0]),
      greaterThan(powerWithoutAllocatedStats),
    );
    expect(
      controller.towerPower(controller.slots[0]),
      greaterThan(powerBefore),
    );
  });

  test(
    'global radiance stat reset spends premium currency and refunds points',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      const resetCost = LightcoreController.radianceStatResetPrismShardCost;

      controller.experience = LightcoreController.experienceForOverallLevel(4);
      expect(
        controller.upgradeRadianceStat(LightcoreRadianceStat.might),
        isTrue,
      );
      expect(
        controller.upgradeRadianceStat(LightcoreRadianceStat.focus),
        isTrue,
      );
      expect(controller.totalRadianceStatPointsSpent, 2);
      expect(controller.unspentRadianceStatPoints, 1);

      controller.prismShards = resetCost - 1;
      expect(controller.purchaseRadianceStatReset(), isFalse);
      expect(controller.radianceStatRank(LightcoreRadianceStat.might), 1);

      controller.prismShards = resetCost;
      expect(controller.purchaseRadianceStatReset(), isTrue);

      expect(controller.prismShards, 0);
      expect(controller.totalPrismShardsSpent, resetCost);
      expect(controller.totalRadianceStatPointsSpent, 0);
      expect(controller.unspentRadianceStatPoints, 3);
      expect(controller.radianceStatRank(LightcoreRadianceStat.might), 0);
      expect(controller.radianceStatRank(LightcoreRadianceStat.focus), 0);
      expect(controller.bannerMessage, contains('Global Attributes reset'));
    },
  );

  test('level up radiance clears live enemies and raises a notification', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.experience =
        LightcoreController.experienceForOverallLevel(2) - 1;
    controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: controller.spawnRadius,
    );
    controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicRed.id,
      angle: 0.8,
      radius: controller.spawnRadius,
    );

    controller.grantRewardedResources(
      experienceGranted: 1,
      sourceLabel: 'Test reward',
    );

    expect(controller.overallLevel, 2);
    expect(controller.unspentRadianceStatPoints, 1);
    expect(controller.globalLevelBonuses.isEmpty, isTrue);
    expect(controller.enemyCount, 0);
    expect(controller.lastLevelUpRadianceDestroyedEnemies, 2);
    expect(controller.levelUpRadianceActive, isTrue);
    expect(controller.bannerMessage, contains('Radiance point ready'));
    expect(controller.bannerMessage, contains('Main Manager'));
    expect(controller.bannerMessage, contains('Global Attributes'));
  });

  test('level up radiance skips live apex enemies', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.experience =
        LightcoreController.experienceForOverallLevel(2) - 1;
    controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: controller.spawnRadius,
    );
    final apex = controller.debugSpawnEnemyFromCard(
      BossEnemyLibrary.starterWhiteWarden.id,
      angle: 0.8,
      radius: controller.spawnRadius,
      boss: true,
    );

    expect(apex, isNotNull);
    final apexHealth = apex!.health;

    controller.grantRewardedResources(
      experienceGranted: 1,
      sourceLabel: 'Test reward',
    );

    expect(controller.overallLevel, 2);
    expect(controller.enemyCount, 1);
    expect(controller.bossAlive, isTrue);
    expect(controller.enemies.single.id, apex.id);
    expect(controller.enemies.single.health, apexHealth);
    expect(controller.lastLevelUpRadianceDestroyedEnemies, 1);
    expect(controller.levelUpRadianceActive, isTrue);
  });

  test(
    'apex scans unlock at layer two after starter White Warden is active',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      expect(controller.bossHuntsUnlocked, isFalse);
      expect(controller.ownedBossEnemyCardCount, 1);
      expect(
        controller.activeBossEnemyCard?.config.id,
        BossEnemyLibrary.starterWhiteWarden.id,
      );
      expect(controller.activeLayer.bossReady, isTrue);

      _unlockBossHunts(controller);

      expect(controller.bossHuntsUnlocked, isTrue);
      expect(controller.bossTickets, LightcoreController.bossUnlockTicketGrant);
      expect(controller.ownedBossEnemyCardCount, 1);
      expect(
        controller.activeBossEnemyCard?.config.id,
        BossEnemyLibrary.starterWhiteWarden.id,
      );
    },
  );

  test('apex selection swaps the active Apex Anomaly card', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _unlockBossHunts(controller);
    final nextBoss = controller.bossEnemyCards[3];
    expect(
      controller.debugSetEnemyCardLevel(
        nextBoss.config.id,
        level: 1,
        copies: 1,
        boss: true,
      ),
      isTrue,
    );

    controller.setActiveBossEnemyCard(nextBoss.config.id);

    expect(controller.activeBossEnemyCard?.config.id, nextBoss.config.id);
    expect(controller.isBossEnemyCardActive(nextBoss.config.id), isTrue);
  });

  test('anomaly inventory levels feed TS and tower combat bonuses', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 1800,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 200,
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.lumens = 5000;
    controller.buildTowerAt(0, TowerLibrary.redPrism);

    final powerBefore = controller.towerPower(controller.slots[0]);
    final tsBefore = controller.towerStrength;

    expect(
      controller.debugSetEnemyCardLevel(
        EnemyLibrary.basicWhite.id,
        level: 25,
        copies: 0,
      ),
      isTrue,
    );

    final leveledCard = controller.enemyCardById(EnemyLibrary.basicWhite.id)!;
    final effect = controller.enemyInventoryEffectForCard(leveledCard);

    expect(effect.power, greaterThan(0));
    expect(
      controller.towerPower(controller.slots[0]),
      greaterThan(powerBefore),
    );
    expect(controller.towerStrength, greaterThan(tsBefore));
  });

  test('heartcores upgrade apex inventory effects and TS', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _unlockBossHunts(controller);
    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 1800,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 200,
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.lumens = 5000;
    controller.buildTowerAt(0, TowerLibrary.redPrism);

    final bossCardId = controller.bossEnemyCards.first.config.id;
    expect(
      controller.debugSetEnemyCardLevel(
        bossCardId,
        level: 1,
        copies: 1,
        boss: true,
      ),
      isTrue,
    );
    final bossCard = controller.bossEnemyCardById(bossCardId)!;
    final bonusBefore = controller.bossInventoryEffectForCard(bossCard);
    final tsBefore = controller.towerStrength;

    controller.debugAddBossCores(12);

    expect(controller.upgradeBossEnemyCard(bossCardId), isTrue);

    final after = controller.bossEnemyCardById(bossCardId)!;
    final bonusAfter = controller.bossInventoryEffectForCard(after);

    expect(after.level, bossCard.level + 1);
    expect(bonusAfter.bossDamage, greaterThan(bonusBefore.bossDamage));
    expect(controller.towerStrength, greaterThan(tsBefore));
  });

  test('found apex inventory effects apply without arming the card', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _unlockBossHunts(controller);
    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 1800,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 200,
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.lumens = 5000;
    controller.buildTowerAt(0, TowerLibrary.redPrism);

    final tsBefore = controller.towerStrength;

    final pulls = controller.openBossTickets(1);

    expect(pulls, hasLength(1));
    expect(
      controller.activeBossEnemyCard?.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );
    expect(controller.ownedBossEnemyCardCount, greaterThan(1));
    expect(controller.bossInventoryBonuses.isEmpty, isFalse);
    expect(controller.towerStrength, greaterThan(tsBefore));
  });

  test('apex inventory effects are positive bonuses only', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    for (final card in controller.bossEnemyCards) {
      expect(
        controller.debugSetEnemyCardLevel(
          card.config.id,
          level: 1,
          copies: 1,
          boss: true,
        ),
        isTrue,
      );
      final effect = controller.bossInventoryEffectForCard(
        controller.bossEnemyCardById(card.config.id)!,
      );

      expect(effect.power, greaterThanOrEqualTo(0));
      expect(effect.chargeRate, greaterThanOrEqualTo(0));
      expect(effect.cooldownReduction, greaterThanOrEqualTo(0));
      expect(effect.range, greaterThanOrEqualTo(0));
      expect(effect.generationSpeed, greaterThanOrEqualTo(0));
      expect(effect.critChance, greaterThanOrEqualTo(0));
      expect(effect.critDamage, greaterThanOrEqualTo(0));
      expect(effect.finalDamage, greaterThanOrEqualTo(0));
      expect(effect.bossDamage, greaterThanOrEqualTo(0));
      expect(effect.normalDamage, greaterThanOrEqualTo(0));
      expect(effect.defensePenetration, greaterThanOrEqualTo(0));
      expect(effect.isEmpty, isFalse);
    }
  });

  test(
    'upgradeAllReadyBossEnemyCards spends Heartcores across ready bosses',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      final bosses = controller.bossEnemyCards.take(2).toList(growable: false);
      for (final boss in bosses) {
        expect(
          controller.debugSetEnemyCardLevel(
            boss.config.id,
            level: 1,
            copies: 1,
            boss: true,
          ),
          isTrue,
        );
      }
      controller.debugAddBossCores(4);

      expect(controller.upgradableBossEnemyCardCount, 2);

      final upgradedCount = controller.upgradeAllReadyBossEnemyCards();

      expect(upgradedCount, 4);
      expect(controller.bossCores, 0);
      expect(controller.upgradableBossEnemyCardCount, 0);
      for (final boss in bosses) {
        expect(controller.bossEnemyCardById(boss.config.id)?.level, 3);
      }
    },
  );

  test('apex scans create stacks that raise apex level caps', () {
    final controller = LightcoreController(packRandom: Random(13));
    addTearDown(controller.dispose);

    _unlockBossHunts(controller);
    controller.debugAddBossTickets(40);
    final pulls = controller.openBossTickets(50);
    PackPullResult? duplicatePull;
    for (final pull in pulls) {
      if (!pull.isNew) {
        duplicatePull = pull;
        break;
      }
    }

    expect(duplicatePull, isNotNull);
    final stackedCard = controller.bossEnemyCardById(duplicatePull!.config.id)!;

    expect(controller.bossPullCount, 50);
    expect(stackedCard.copies, greaterThan(1));
    expect(
      controller.bossLevelCap(stackedCard),
      greaterThan(controller.bossBaseLevelCap(stackedCard)),
    );
  });

  test('damage slows passive lumen harvest but recovers within four hours', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _buildMaxedRing(controller);
    _assignManagersToActiveRing(controller);
    controller.unlockLayer2Tower();

    final baseline = controller.passiveLumenPerSecond;
    expect(baseline, greaterThan(0));

    controller.debugApplyLumenHarvestDamage(12);
    final expectedEfficiency = pow(0.88, 1.10).toDouble();

    expect(controller.hasLumenHarvestPressure, isTrue);
    expect(
      controller.lumenHarvestEfficiency,
      closeTo(expectedEfficiency, 0.0001),
    );
    expect(
      controller.passiveLumenPerSecond,
      closeTo(baseline * expectedEfficiency, 0.001),
    );

    controller.debugAdvanceLumenHarvestRecovery(
      LightcoreController.maxOfflineProgressSeconds.toDouble(),
    );

    expect(controller.hasLumenHarvestPressure, isFalse);
    expect(controller.lumenHarvestEfficiency, closeTo(1.0, 0.0001));
    expect(controller.passiveLumenPerSecond, closeTo(baseline, 0.001));
  });

  test('promoted source shells contribute reduced passive lumens', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _buildMaxedRing(controller);
    _assignManagersToActiveRing(controller);
    controller.unlockLayer2Tower();

    final expectedArchivedSourceOutput =
        ((LightcoreController.slotCount * 0.18) + 0.04) /
        LightcoreController.slotCount;

    expect(
      controller.passiveLumenBasePerSecond,
      closeTo(expectedArchivedSourceOutput, 0.001),
    );
    expect(
      controller.passiveLumenPerSecond,
      closeTo(expectedArchivedSourceOutput, 0.001),
    );
  });

  test(
    'damage slowdown stays capped so it does not zero out lumen harvest',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      _buildMaxedRing(controller);
      _assignManagersToActiveRing(controller);
      controller.unlockLayer2Tower();

      controller.debugApplyLumenHarvestDamage(10);

      expect(controller.hasLumenHarvestPressure, isTrue);
      expect(controller.lumenHarvestEfficiency, greaterThanOrEqualTo(0.75));
    },
  );

  test('a built shell eventually reaches the first live boss spawn', () {
    final controller = LightcoreController(
      packRandom: Random(5),
      traitRandom: Random(7),
      managerRandom: Random(11),
    );
    addTearDown(controller.dispose);

    _buildMaxedRing(controller);
    _assignManagersToActiveRing(controller);
    expect(
      controller.activeBossEnemyCard?.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );

    for (var step = 0; step < 20000 && !controller.bossAlive; step++) {
      controller.tick(0.2);
    }

    expect(
      controller.bossAlive,
      isTrue,
      reason:
          'bossAlive=${controller.bossAlive}, bossReady=${controller.activeLayer.bossReady}, normalKills=${controller.activeLayer.normalKillsSinceBoss}, enemies=${controller.enemyCount}, kills=${controller.kills}',
    );
    expect(controller.enemies.single.config.isBoss, isTrue);
  });
}
