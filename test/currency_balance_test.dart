import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_currency_labels.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _completeLayer1Coverage(LightcoreController controller) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    final config = TowerLibrary.all[index % TowerLibrary.all.length];
    expect(controller.buildTowerAt(index, config), isTrue);
    final remaining = controller.slots[index].fabricationRemainingSeconds;
    if (remaining > 0) {
      controller.tick(remaining + 0.1);
    }
  }
  expect(controller.managerAssignmentUnlocked, isTrue);
}

void _fundNextTowerUpgrade(LightcoreController controller, int slotIndex) {
  final cost = controller.upgradeCost(controller.slots[slotIndex]);
  if (controller.lumens < cost) {
    controller.lumens = cost;
  }
}

double _advanceUntil(
  LightcoreController controller,
  bool Function() condition, {
  String reason = 'condition was not reached',
  int steps = 160,
  double dt = 0.5,
}) {
  var elapsed = 0.0;
  for (var i = 0; i < steps; i++) {
    if (condition()) {
      return elapsed;
    }
    controller.tick(dt);
    elapsed += dt;
  }
  fail(reason);
}

double _advanceActiveOpeningChallenge(LightcoreController controller) {
  return _advanceUntil(
    controller,
    () => controller.activeThreatRegionChallenge == null,
    reason: 'opening challenge did not resolve',
    steps: 280,
    dt: 0.5,
  );
}

void main() {
  test('retired apex scan labels display as threat scans', () {
    expect(LightcoreCurrencyLabels.bossScanCount(1), '1 Threat Scan');
    expect(LightcoreCurrencyLabels.bossScanCount(2), '2 Threat Scans');
    expect(LightcoreCurrencyLabels.rewardBossScans(3), '+3 Threat Scans');
  });

  test('manager shard labels match manager power currency naming', () {
    expect(LightcoreCurrencyLabels.managerShardCount(1), '1 Manager Shard');
    expect(LightcoreCurrencyLabels.managerShardCount(8), '8 Manager Shards');
    expect(
      LightcoreCurrencyLabels.rewardManagerShards(12),
      '+12 Manager Shards',
    );
  });

  test('daily dungeon rewards include manager shards', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final reward = controller.dailyDungeonRewardForLevel(6);
    final quickReward = controller.dailyDungeonQuickClearRewardForLevel(6);

    expect(reward.managerShards, greaterThan(0));
    expect(quickReward.managerShards, greaterThan(0));
    expect(quickReward.managerShards, lessThan(reward.managerShards));
    expect(reward.label, contains('Manager Shards'));
  });

  test('starter challenge prompt previews lumen reward', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.firstThreatChallengeLumenRewardPreview, greaterThan(0));
    expect(
      controller.firstThreatChallengeRewardLabel,
      LightcoreCurrencyLabels.rewardLumens(
        controller.firstThreatChallengeLumenRewardPreview,
      ),
    );
  });

  test('opening loop pressures upgrade and repeats before Hex 2', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    var guidedElapsedSeconds = 0.0;

    void recordGuidedClick([double seconds = 2.0]) {
      guidedElapsedSeconds += seconds;
    }

    controller.selectSlot(0);
    recordGuidedClick();
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    recordGuidedClick();
    expect(controller.builtTowerCount, 1);

    final starter = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.starterDefault.id,
      angle: 0,
      radius: 120,
      healthFraction: 1,
    );
    expect(starter, isNotNull);
    expect(
      controller.debugSetTowerCharge(0, charge: 1, cooldownRemaining: 0),
      isTrue,
    );
    expect(controller.queuedCorePackets, 0);
    expect(controller.focusBattleEnemyForNextShot(starter!.id), isTrue);
    recordGuidedClick();
    expect(controller.focusedEnemyId, starter.id);
    guidedElapsedSeconds += _advanceUntil(
      controller,
      () =>
          controller.tutorialStep ==
          LightcoreTutorialStep.upgradeFirstTowerToLevel3,
      reason: 'opening focus click did not auto-fire the next generated shot',
    );
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.upgradeFirstTowerToLevel3,
    );
    expect(controller.queuedCorePackets, 0);
    expect(controller.outputEfficiencyMultiplier, lessThan(0.95));

    _fundNextTowerUpgrade(controller, 0);
    expect(controller.upgradeTower(0), isTrue);
    recordGuidedClick();
    expect(controller.slots[0].level, 2);
    expect(controller.outputEfficiencyMultiplier, greaterThanOrEqualTo(0.98));
    expect(controller.canStartFirstThreatChallenge, isTrue);
    expect(
      controller.firstThreatChallengePressurePreviewLabel,
      contains('Enemy Lv 2'),
    );
    expect(
      controller.firstThreatChallengePressurePreviewLabel,
      contains('8 active'),
    );
    expect(controller.startFirstThreatChallenge(), isTrue);
    recordGuidedClick();
    expect(controller.bannerMessage, contains('Threat raised'));
    expect(controller.bannerMessage, isNot(contains('stabilization')));
    expect(controller.activeThreatRegionChallenge?.targetStabilizationLevel, 1);
    expect(
      controller.enemyTargetCount,
      LightcoreController.initialEnemyTarget + 2,
    );
    expect(
      controller.activeEnemyDeck.map((card) => card.level),
      everyElement(2),
    );

    guidedElapsedSeconds += _advanceActiveOpeningChallenge(controller);
    expect(controller.bannerMessage, contains('Challenge Lv 1 cleared'));
    expect(controller.bannerMessage, contains('upgrade the tower'));
    expect(controller.bannerMessage, isNot(contains('Live farm unlocked')));
    final starterRegion = controller.threatRegionConfigs.first;
    expect(
      controller.threatRegionStateById(starterRegion.id)?.stabilizedLevel,
      1,
    );
    expect(controller.outputEfficiencyMultiplier, lessThan(0.9));
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.upgradeFirstTowerToLevel4,
    );

    _fundNextTowerUpgrade(controller, 0);
    expect(controller.upgradeTower(0), isTrue);
    recordGuidedClick();
    expect(controller.slots[0].level, 3);
    expect(controller.outputEfficiencyMultiplier, greaterThanOrEqualTo(0.98));
    expect(controller.canStartFirstThreatChallenge, isTrue);
    expect(
      controller.firstThreatChallengePressurePreviewLabel,
      contains('Enemy Lv 3'),
    );
    expect(
      controller.firstThreatChallengePressurePreviewLabel,
      contains('10 active'),
    );
    expect(controller.startFirstThreatChallenge(), isTrue);
    recordGuidedClick();
    expect(controller.bannerMessage, contains('Challenge Lv 2 started'));
    expect(controller.bannerMessage, isNot(contains('stabilization')));
    expect(controller.activeThreatRegionChallenge?.targetStabilizationLevel, 2);
    expect(
      controller.enemyTargetCount,
      LightcoreController.initialEnemyTarget + 4,
    );
    expect(
      controller.activeEnemyDeck.map((card) => card.level),
      everyElement(3),
    );

    guidedElapsedSeconds += _advanceActiveOpeningChallenge(controller);
    expect(controller.bannerMessage, contains('Challenge Lv 2 cleared'));
    expect(controller.bannerMessage, contains('open Hex 2'));
    expect(controller.bannerMessage, isNot(contains('Live farm unlocked')));
    expect(
      controller.threatRegionStateById(starterRegion.id)?.stabilizedLevel,
      2,
    );
    expect(controller.outputEfficiencyMultiplier, lessThan(0.9));
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.upgradeFirstTowerToLevel5,
    );

    _fundNextTowerUpgrade(controller, 0);
    expect(controller.upgradeTower(0), isTrue);
    recordGuidedClick();
    expect(controller.slots[0].level, 4);
    expect(controller.isOuterSlotUnlocked(1), isTrue);
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.buildSecondStarterTower,
    );

    controller.selectSlot(1);
    recordGuidedClick();
    expect(controller.buildTowerAt(1, TowerLibrary.cyanPrism), isTrue);
    recordGuidedClick();
    expect(controller.builtTowerCount, 2);
    expect(controller.tutorialStep, LightcoreTutorialStep.none);
    expect(controller.tutorialPromptsEnabled, isTrue);
    expect(controller.tutorialUsesBattleOnlyNavigation, isFalse);
    expect(controller.tutorialNeedsTowerPaletteGate, isFalse);
    expect(
      guidedElapsedSeconds,
      lessThanOrEqualTo(300),
      reason:
          'The guided pressure-upgrade-repeat loop should reach Hex 2 inside the first five minutes.',
    );
  });

  test('bulk manager forging grants pack bonuses and a rarity floor', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _completeLayer1Coverage(controller);
    controller.flux = LightcoreController.towerManagerFluxCost * 10;

    expect(controller.forgeTowerManagerBatch(10), isTrue);

    expect(controller.cards, hasLength(10));
    expect(controller.towerManagerPullCount, 10);
    expect(controller.managerShards, 16);
    expect(
      controller.cards.fold<int>(
        0,
        (highest, card) =>
            card.rarity.score > highest ? card.rarity.score : highest,
      ),
      greaterThanOrEqualTo(ManagerRarity.rare.score),
    );
  });

  test('manager power upgrade spends shards and survives cloud restore', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.managerShards = controller.managerPowerUpgradeCost;
    expect(controller.upgradeManagerPower(), isTrue);
    expect(controller.managerPowerLevel, 1);
    expect(controller.managerShards, 0);
    expect(controller.managerPowerEffectMultiplier, closeTo(1.01, 0.0001));

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.managerPowerLevel, 1);
    expect(restored.managerPowerEffectMultiplier, closeTo(1.01, 0.0001));
  });

  test('enemy level reward preview grows on an exponential lumen curve', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(
      controller.debugSetEnemyCardLevel(
        EnemyLibrary.basicWhite.id,
        level: 1,
        copies: 1,
      ),
      isTrue,
    );
    final level1 = controller.enemyCardPreviewReward(
      controller.enemyCardById(EnemyLibrary.basicWhite.id)!,
    );

    expect(
      controller.debugSetEnemyCardLevel(
        EnemyLibrary.basicWhite.id,
        level: 25,
        copies: 1,
      ),
      isTrue,
    );
    final level25 = controller.enemyCardPreviewReward(
      controller.enemyCardById(EnemyLibrary.basicWhite.id)!,
    );

    expect(
      controller.debugSetEnemyCardLevel(
        EnemyLibrary.basicWhite.id,
        level: 50,
        copies: 1,
      ),
      isTrue,
    );
    final level50 = controller.enemyCardPreviewReward(
      controller.enemyCardById(EnemyLibrary.basicWhite.id)!,
    );

    expect(level25, greaterThan(level1 * 3));
    expect(level50, greaterThan(level25 * 3));
  });

  test('enemy rarity health curve creates late-layer threat walls', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final basic = EnemyLibrary.basicWhite;
    final epic = EnemyLibrary.byRarity[EnemyCardRarity.epic]!.first;
    final legendary = EnemyLibrary.byRarity[EnemyCardRarity.legendary]!.first;

    expect(
      controller.debugSetEnemyCardLevel(
        basic.id,
        level: basic.rarity.levelCap,
        copies: 1,
      ),
      isTrue,
    );
    expect(
      controller.debugSetEnemyCardLevel(
        epic.id,
        level: epic.rarity.levelCap,
        copies: 1,
      ),
      isTrue,
    );
    expect(
      controller.debugSetEnemyCardLevel(legendary.id, level: 1, copies: 1),
      isTrue,
    );

    final maxBasicHealth = controller.enemyCardPreviewHealth(
      controller.enemyCardById(basic.id)!,
    );
    final maxEpicHealth = controller.enemyCardPreviewHealth(
      controller.enemyCardById(epic.id)!,
    );
    final legendaryLevel1Health = controller.enemyCardPreviewHealth(
      controller.enemyCardById(legendary.id)!,
    );

    expect(maxBasicHealth, greaterThan(200000));
    expect(maxEpicHealth, greaterThan(75000000));
    expect(legendaryLevel1Health, greaterThan(900000000));
    expect(legendaryLevel1Health, greaterThan(maxEpicHealth * 8));
    expect(
      controller.enemyCardThreatRatingLabel(
        controller.enemyCardById(legendary.id)!,
      ),
      'Overwhelming',
    );
  });

  test('enemy color economy can lean toward Lumens or EXP', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final red = controller.enemyCardById(EnemyLibrary.basicRed.id)!;
    final orange = controller.enemyCardsByRarity[EnemyCardRarity.basic]!
        .firstWhere((card) => card.config.affinity == PrototypeAffinity.flare);

    final redRewardToExp =
        controller.enemyCardPreviewReward(red) /
        controller.enemyCardPreviewExperience(red);
    final orangeRewardToExp =
        controller.enemyCardPreviewReward(orange) /
        controller.enemyCardPreviewExperience(orange);

    expect(redRewardToExp, greaterThan(orangeRewardToExp * 2));
    expect(
      controller.enemyCardPreviewExperience(orange),
      greaterThan(controller.enemyCardPreviewExperience(red)),
    );
    expect(
      controller.enemyCardPreviewReward(red),
      greaterThan(controller.enemyCardPreviewReward(orange)),
    );
  });

  test('enemy EXP preview varies while kills stay per clear', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final white = controller.enemyCardById(EnemyLibrary.basicWhite.id)!;
    final red = controller.enemyCardById(EnemyLibrary.basicRed.id)!;

    expect(controller.enemyCardPreviewKillCredit(white), 1);
    expect(controller.enemyCardPreviewKillCredit(red), 1);
    expect(controller.enemyCardPreviewExperience(white), greaterThan(1));
    expect(
      controller.enemyCardPreviewExperience(red),
      greaterThan(controller.enemyCardPreviewExperience(white)),
    );
  });

  test('enemy clears award one kill and card-specific EXP', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final white = controller.enemyCardById(EnemyLibrary.basicWhite.id)!;
    final red = controller.enemyCardById(EnemyLibrary.basicRed.id)!;
    final whiteExperience = controller.enemyCardPreviewExperience(white);
    final redExperience = controller.enemyCardPreviewExperience(red);

    final whiteEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: controller.spawnRadius,
    )!;
    expect(controller.debugDefeatEnemy(whiteEnemy.id), isTrue);

    expect(controller.kills, 1);
    expect(controller.experience, whiteExperience);

    final redEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicRed.id,
      angle: 0,
      radius: controller.spawnRadius,
    )!;
    expect(controller.debugDefeatEnemy(redEnemy.id), isTrue);

    expect(controller.kills, 2);
    expect(controller.experience, whiteExperience + redExperience);
    expect(redExperience, greaterThan(whiteExperience));
  });

  test('enemy target ceiling upgrades one at a time into trillion costs', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(LightcoreController.enemyTargetUpgradeStep, 1);
    expect(controller.enemyTargetMax, LightcoreController.baseEnemyTargetMax);
    expect(controller.setEnemyTargetCount(controller.enemyTargetMax), isTrue);

    var upgrades = 0;
    var previousCost = 0;
    var finalPaidCost = 0;
    while (controller.canUpgradeEnemyTargetMax) {
      final cost = controller.enemyTargetUpgradeCost;
      final previousMax = controller.enemyTargetMax;
      expect(cost, greaterThan(previousCost));

      controller.lumens = cost;
      expect(controller.upgradeEnemyTargetMax(), isTrue);
      expect(controller.enemyTargetMax, previousMax + 1);
      expect(controller.enemyTargetCount, controller.enemyTargetMax);

      upgrades += 1;
      previousCost = cost;
      finalPaidCost = cost;
    }

    expect(
      upgrades,
      LightcoreController.maxActiveEnemies -
          LightcoreController.baseEnemyTargetMax,
    );
    expect(controller.enemyTargetMax, LightcoreController.maxActiveEnemies);
    expect(finalPaidCost, greaterThanOrEqualTo(1000000000000));
  });

  test(
    'legacy enemy target upgrade levels migrate to one-at-a-time ceiling',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      final payload = controller.buildCloudSavePayload();
      final layerData = payload['layers'] as Map<String, dynamic>;
      final layers = layerData['items'] as List<dynamic>;
      final rootLayer = layers.first as Map<String, dynamic>;

      rootLayer
        ..remove('enemyTargetUpgradeStep')
        ..['enemyTargetUpgradeLevel'] = 8
        ..['enemyTargetCount'] = LightcoreController.maxActiveEnemies;

      final restored = LightcoreController.fromCloudSavePayload(payload);
      addTearDown(restored.dispose);

      expect(restored.enemyTargetMax, LightcoreController.maxActiveEnemies);
      expect(restored.enemyTargetCount, LightcoreController.maxActiveEnemies);

      final restoredPayload = restored.buildCloudSavePayload();
      final restoredLayerData =
          restoredPayload['layers'] as Map<String, dynamic>;
      final restoredLayers = restoredLayerData['items'] as List<dynamic>;
      final restoredRootLayer = restoredLayers.first as Map<String, dynamic>;
      expect(
        restoredRootLayer['enemyTargetUpgradeStep'],
        LightcoreController.enemyTargetUpgradeStep,
      );
    },
  );

  test('premium time warps spend shards and enforce weekly caps', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final offer = controller.timeWarpOfferById(
      LightcoreController.timeWarpPrismTwelveHoursId,
    )!;
    controller.prismShards = offer.cost * offer.weeklyLimit;

    for (var index = 0; index < offer.weeklyLimit; index += 1) {
      expect(controller.purchaseTimeWarp(offer.id), isTrue);
    }

    expect(controller.prismShards, 0);
    expect(controller.totalPrismShardsSpent, offer.cost * offer.weeklyLimit);
    expect(
      controller.totalTimeWarpSecondsClaimed,
      offer.durationSeconds * offer.weeklyLimit,
    );
    expect(controller.timeWarpPurchasesRemaining(offer.id), 0);
    expect(controller.purchaseTimeWarp(offer.id), isFalse);
  });

  test('flux time warp cap state survives cloud save restore', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final offer = controller.timeWarpOfferById(
      LightcoreController.timeWarpFluxThirtyMinutesId,
    )!;
    controller.flux = offer.cost * offer.weeklyLimit;

    for (var index = 0; index < offer.weeklyLimit; index += 1) {
      expect(controller.purchaseTimeWarp(offer.id), isTrue);
    }

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.timeWarpPurchasesRemaining(offer.id), 0);
    expect(
      restored.totalTimeWarpSecondsClaimed,
      offer.durationSeconds * offer.weeklyLimit,
    );
    expect(restored.purchaseTimeWarp(offer.id), isFalse);
  });

  test('server date keys drive daily and weekly reset state', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final offer = controller.timeWarpOfferById(
      LightcoreController.timeWarpFluxThirtyMinutesId,
    )!;
    const storeOfferId = 'test_weekly_store_offer';
    const storeOfferWeeklyLimit = 2;
    controller.syncServerDateKeys(dayKey: '2026-04-20', weekKey: '2026-04-20');
    controller.flux = offer.cost * offer.weeklyLimit;
    controller.prismShards = 20;

    for (var index = 0; index < offer.weeklyLimit; index += 1) {
      expect(controller.purchaseTimeWarp(offer.id), isTrue);
    }
    expect(controller.timeWarpPurchasesRemaining(offer.id), 0);
    for (var index = 0; index < storeOfferWeeklyLimit; index += 1) {
      expect(
        controller.spendPrismShardsForStoreOffer(
          offerId: storeOfferId,
          amount: 5,
          weeklyLimit: storeOfferWeeklyLimit,
          reasonLabel: 'Test Weekly Store Offer',
        ),
        isTrue,
      );
    }
    expect(
      controller.storeOfferPurchasesRemaining(
        storeOfferId,
        weeklyLimit: storeOfferWeeklyLimit,
      ),
      0,
    );

    controller.syncServerDateKeys(dayKey: '2026-04-21', weekKey: '2026-04-27');

    expect(controller.timeWarpPurchasesRemaining(offer.id), offer.weeklyLimit);
    expect(
      controller.storeOfferPurchasesRemaining(
        storeOfferId,
        weeklyLimit: storeOfferWeeklyLimit,
      ),
      storeOfferWeeklyLimit,
    );
    final payload = controller.buildCloudSavePayload();
    final dailyPass =
        (payload['battlePasses'] as List<dynamic>).firstWhere(
              (item) => (item as Map<String, dynamic>)['type'] == 'dailyKills',
            )
            as Map<String, dynamic>;
    expect(dailyPass['seasonKey'], '2026-04-21');
    expect(
      (payload['store'] as Map<String, dynamic>)['timeWarpWeekKey'],
      '2026-04-27',
    );
    expect(
      (payload['store'] as Map<String, dynamic>)['storeOfferWeekKey'],
      '2026-04-27',
    );
  });
}
