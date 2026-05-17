import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_tournament.dart';
import 'package:lightcore/models/lightcore_progression.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _unlockTutorialFirstHex(LightcoreController controller) {
  controller.applyOfflineClaim(
    const LightcoreOfflineClaimResult(
      secondsClaimed: 1,
      lumensGranted: 0,
      fluxGranted: 0,
      enemyTicketsGranted: 0,
      killsGranted: LightcoreController.tutorialFirstHexUnlockExperience,
      serverValidated: true,
    ),
    showBanner: false,
  );
}

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
  controller.unlockLayer2Tower();
}

void _maxOutCurrentTier1Shell(LightcoreController controller) {
  controller.lumens = 100000000;
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
}

void _promoteChildShellIntoParent(
  LightcoreController controller,
  int parentSlotIndex,
) {
  expect(
    controller.createChildLayer(parentSlotIndex, PrototypeAffinity.aether),
    isTrue,
  );
  expect(controller.activeLayerHasParentSlot, isTrue);
  _maxOutCurrentTier1Shell(controller);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 2);
}

void _maxOutPromotedTower(LightcoreController controller, int parentSlotIndex) {
  controller.lumens = 100000000;
  while (controller.slots[parentSlotIndex].level <
      LightcoreController.maxTowerLevel) {
    expect(controller.upgradeTower(parentSlotIndex), isTrue);
  }
}

void _promoteToLayer3(LightcoreController controller) {
  _promoteRootShell(controller);
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    _promoteChildShellIntoParent(controller, index);
    _maxOutPromotedTower(controller, index);
  }
  expect(controller.isPromotionReady, isTrue);
  controller.unlockLayer2Tower();
  expect(controller.debugCompleteLayer3Trial(), isTrue);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 3);
}

void _finishBossAndEquipmentTutorial(LightcoreController controller) {
  controller.debugCompleteBossAndEquipmentTutorial();
}

void _completeSidecarTutorials(LightcoreController controller) {
  var guard = 0;
  while (guard++ < 8) {
    switch (controller.tutorialStep) {
      case LightcoreTutorialStep.openTowerMatrix:
        controller.markTutorialTowerMatrixOpened();
      case LightcoreTutorialStep.upgradeCoreRange:
        expect(
          controller.upgradeRadianceStat(LightcoreRadianceStat.might),
          isTrue,
        );
      case LightcoreTutorialStep.openStore:
        controller.markTutorialStoreOpened();
      case LightcoreTutorialStep.claimBattlePassReward:
        final claimed = BattlePassType.values.fold<int>(
          0,
          (sum, type) => sum + controller.claimUnlockedBattlePassRewards(type),
        );
        expect(claimed, greaterThan(0));
      default:
        return;
    }
  }
}

void _completeManagerTutorials(LightcoreController controller) {
  var guard = 0;
  while (guard++ < 10) {
    switch (controller.tutorialStep) {
      case LightcoreTutorialStep.openManagers:
        controller.markTutorialManagersOpened();
      case LightcoreTutorialStep.forgeTowerManager:
        controller.flux = LightcoreController.towerManagerFluxCost;
        expect(controller.forgeTowerManager(), isTrue);
      case LightcoreTutorialStep.assignTowerManager:
        expect(controller.cards, isNotEmpty);
        final slot = controller.slots.firstWhere((slot) => slot.isBuilt);
        controller.equipCardToSlot(
          controller.cards.first.instanceId,
          slot.slotIndex,
        );
      case LightcoreTutorialStep.forgeEnemyManager:
        controller.flux = LightcoreController.enemyManagerFluxCost;
        expect(controller.forgeEnemyManager(), isTrue);
      case LightcoreTutorialStep.assignEnemyManager:
        expect(controller.enemyManagers, isNotEmpty);
        expect(controller.activeEnemyDeck, isNotEmpty);
        controller.assignEnemyManagerToCard(
          controller.enemyManagers.first.instanceId,
          controller.activeEnemyDeck.first.config.id,
        );
      default:
        return;
    }
  }
}

void main() {
  test('tutorial help library covers every active guide step', () {
    expect(
      LightcoreController.tutorialQuestLibrary,
      hasLength(LightcoreTutorialStep.values.length - 1),
    );
    expect(
      LightcoreController.tutorialQuestHelpBody,
      contains('TUT-005 Read Tower Stats'),
    );
    expect(
      LightcoreController.tutorialQuestHelpBody,
      contains('TUT-037 Inspect Arena Flow'),
    );
  });

  test('starter deck defaults to White Basic and early pulls are scripted', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicWhite.id,
    );
    expect(controller.tutorialTowerChoices, const [
      TowerLibrary.redPrism,
      TowerLibrary.cyanPrism,
    ]);
    final initialThreatScans = controller.enemyTickets;

    expect(controller.tutorialStep, LightcoreTutorialStep.unfoldShell);
    controller.selectCenter();
    expect(controller.tutorialStep, LightcoreTutorialStep.tapBattleCore);
    controller.handleBattleCenterTap();
    expect(controller.tutorialStep, LightcoreTutorialStep.waitForFirstHex);
    expect(controller.isOuterSlotUnlocked(0), isFalse);
    expect(controller.tutorialBuildTowerAt(0, TowerLibrary.redPrism), isFalse);
    _unlockTutorialFirstHex(controller);
    expect(controller.isOuterSlotUnlocked(0), isTrue);
    expect(controller.tutorialStep, LightcoreTutorialStep.selectFirstHex);
    controller.selectSlot(0);
    expect(controller.tutorialStep, LightcoreTutorialStep.buildFirstRedTower);
    expect(controller.enemyTickets, initialThreatScans + 1);
    expect(controller.tutorialStep, LightcoreTutorialStep.buildFirstRedTower);
    expect(controller.tutorialBuildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.inspectFirstTowerStats,
    );
    controller.markTutorialFirstTowerStatsOpened();
    expect(controller.tutorialStep, LightcoreTutorialStep.tapFirstTower);
    for (var tap = 0; tap < 3; tap++) {
      expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
      expect(controller.activateTowerSlot(0, showBanner: false), isTrue);
    }

    controller.lumens = 1000;
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.upgradeFirstTowerToLevel3,
    );
    expect(controller.tutorialUpgradeTower(0), isTrue);
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.upgradeFirstTowerToLevel3,
    );
    controller.lumens = controller.upgradeCost(controller.slots[0]);
    expect(controller.tutorialUpgradeTower(0), isTrue);
    expect(controller.slots[0].level, 3);
    expect(controller.tutorialStep, LightcoreTutorialStep.raiseThreat);
    expect(controller.canStartFirstThreatChallenge, isTrue);
    final baselineStats = controller.activeThreatAssignmentGroupStats;
    final baselineTargetCount = controller.enemyTargetCount;
    controller.experience = LightcoreController.experienceForOverallLevel(2);
    controller.tick(0);
    expect(controller.tutorialStep, LightcoreTutorialStep.raiseThreat);
    expect(controller.startFirstThreatChallenge(), isTrue);
    expect(controller.activeThreatRegionChallenge, isNotNull);
    expect(controller.enemyTargetCount, greaterThan(baselineTargetCount));
    expect(
      controller.activeThreatAssignmentGroupStats.anomalyCount,
      greaterThan(baselineStats.anomalyCount),
    );
    expect(controller.tutorialStep, LightcoreTutorialStep.readEffectiveGain);

    controller.lumens = controller.upgradeCost(controller.slots[0]);
    controller.markTutorialStabilityPanelOpened();
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.upgradeFirstTowerToLevel4,
    );
    controller.lumens = controller.upgradeCost(controller.slots[0]);
    expect(controller.tutorialUpgradeTower(0), isTrue);
    expect(controller.slots[0].level, 4);

    controller.experience = LightcoreController.experienceForOverallLevel(2);
    controller.tick(0);
    expect(controller.tutorialStep, LightcoreTutorialStep.upgradeCoreRange);
    expect(controller.hasUnspentRadianceStatPoints, isTrue);
    expect(controller.upgradeRadianceStat(LightcoreRadianceStat.might), isTrue);
    expect(
      controller.tutorialStep,
      isNot(LightcoreTutorialStep.upgradeCoreRange),
    );
    expect(controller.tutorialTowerChoices, const [
      TowerLibrary.cyanPrism,
      TowerLibrary.greenPrism,
    ]);
  });

  test(
    'first starter tower gates the palette until the flow lesson is complete',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.selectCenter();
      controller.handleBattleCenterTap();
      controller.kills = LightcoreController.unlockKillsForOuterSlot(1);
      controller.lumens = 1000;

      expect(controller.tutorialTowerChoices, const [
        TowerLibrary.redPrism,
        TowerLibrary.cyanPrism,
      ]);
      expect(controller.tutorialBuildTowerAt(0, TowerLibrary.redPrism), isTrue);

      controller.selectSlot(1);

      expect(
        controller.tutorialBuildTowerAt(1, TowerLibrary.greenPrism),
        isFalse,
      );
      controller.markTutorialFirstTowerStatsOpened();
      for (var tap = 0; tap < 3; tap += 1) {
        expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
        expect(controller.activateTowerSlot(0, showBanner: false), isTrue);
      }
      controller.selectSlot(0);
      while (controller.slots[0].level < 3) {
        controller.lumens = controller.upgradeCost(controller.slots[0]);
        expect(controller.tutorialUpgradeTower(0), isTrue);
      }

      expect(controller.tutorialTowerChoices, const [
        TowerLibrary.redPrism,
        TowerLibrary.cyanPrism,
      ]);
      expect(
        controller.tutorialBuildTowerAt(1, TowerLibrary.greenPrism),
        isFalse,
      );

      controller.markTutorialStabilityPanelOpened();
      while (controller.slots[0].level < 4) {
        controller.lumens = controller.upgradeCost(controller.slots[0]);
        expect(controller.tutorialUpgradeTower(0), isTrue);
      }
      if (controller.hasUnspentRadianceStatPoints) {
        expect(
          controller.upgradeRadianceStat(LightcoreRadianceStat.might),
          isTrue,
        );
      }

      expect(controller.tutorialTowerChoices, const [
        TowerLibrary.cyanPrism,
        TowerLibrary.greenPrism,
      ]);
      expect(
        controller.traitBiasSummary(TowerLibrary.cyanPrism),
        contains('Thread Beam:'),
      );
      expect(
        controller.traitBiasSummary(TowerLibrary.greenPrism),
        contains('Shield Halo:'),
      );
      expect(
        controller.tutorialBuildTowerAt(1, TowerLibrary.orangePrism),
        isFalse,
      );
      controller.selectSlot(1);
      controller.lumens = 1000;
      expect(
        controller.tutorialBuildTowerAt(1, TowerLibrary.greenPrism),
        isTrue,
      );
      expect(controller.slots[1].config?.id, TowerLibrary.greenPrism.id);
      expect(controller.tutorialTowerChoices.length, TowerLibrary.all.length);
    },
  );

  test('first hex offers two starter projectile choices', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    controller.handleBattleCenterTap();
    _unlockTutorialFirstHex(controller);
    controller.selectSlot(0);

    expect(controller.tutorialTowerChoices, const [
      TowerLibrary.redPrism,
      TowerLibrary.cyanPrism,
    ]);
    expect(controller.tutorialBuildTowerAt(0, TowerLibrary.cyanPrism), isTrue);
    expect(controller.slots[0].config?.id, TowerLibrary.cyanPrism.id);
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.inspectFirstTowerStats,
    );
  });

  test('tap quest shows charge state until the tower can shoot', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    controller.handleBattleCenterTap();
    controller.applyOfflineClaim(
      LightcoreOfflineClaimResult(
        secondsClaimed: 1,
        lumensGranted: 1000,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: LightcoreController.tutorialFirstHexUnlockExperience,
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.selectSlot(0);

    final buildCost = controller.buildCostForConfig(TowerLibrary.redPrism);
    controller.lumens = buildCost;
    expect(controller.tutorialBuildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.inspectFirstTowerStats,
    );
    controller.markTutorialFirstTowerStatsOpened();
    expect(controller.tutorialStep, LightcoreTutorialStep.tapFirstTower);
    expect(controller.tutorialBattleSlotGuideLabel(0), 'CHARGING');
    expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
    expect(controller.tutorialStep, LightcoreTutorialStep.tapFirstTower);
    expect(controller.tutorialHeadline, 'Queue a Pulse');
    expect(
      controller.tutorialPrompt,
      'Tap the charged first tower to add pulses. More queued shots means faster kills, more Lumens, and earlier upgrades.',
    );
    expect(controller.tutorialBattleSlotGuideLabel(0), 'ADD TO QUEUE');
    expect(controller.activateTowerSlot(0, showBanner: false), isTrue);

    expect(controller.tutorialStep, LightcoreTutorialStep.tapFirstTower);
  });

  test(
    'first tower inspect, fire, and upgrade lessons wait for fabrication',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.selectCenter();
      controller.handleBattleCenterTap();
      controller
        ..kills = LightcoreController.tutorialFirstHexUnlockExperience
        ..lumens = controller.buildCostForConfig(TowerLibrary.redPrism);

      expect(
        controller.tutorialStartTowerFabricationAt(0, TowerLibrary.redPrism),
        isTrue,
      );
      expect(controller.slots[0].isFabricating, isTrue);
      expect(
        controller.tutorialStep,
        isNot(LightcoreTutorialStep.inspectFirstTowerStats),
      );

      controller.markTutorialFirstTowerStatsOpened();
      expect(
        controller.tutorialStep,
        isNot(LightcoreTutorialStep.tapFirstTower),
      );
      expect(controller.activateTowerSlot(0, showBanner: false), isFalse);
      expect(controller.tutorialUpgradeTower(0), isFalse);

      controller.tick(controller.slots[0].fabricationRemainingSeconds + 0.1);
      expect(controller.slots[0].isFabricating, isFalse);
      expect(
        controller.tutorialStep,
        LightcoreTutorialStep.inspectFirstTowerStats,
      );

      controller.markTutorialFirstTowerStatsOpened();
      expect(controller.tutorialStep, LightcoreTutorialStep.tapFirstTower);
    },
  );

  test('first hex stays locked during the core opening beat', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.tutorialStep, LightcoreTutorialStep.unfoldShell);

    controller.selectCenter();

    expect(controller.isOuterSlotUnlocked(0), isFalse);
    expect(controller.tutorialStep, LightcoreTutorialStep.tapBattleCore);

    controller.handleBattleCenterTap();

    expect(controller.tutorialStep, LightcoreTutorialStep.waitForFirstHex);
    expect(controller.isOuterSlotUnlocked(0), isFalse);

    _unlockTutorialFirstHex(controller);

    expect(controller.tutorialStep, LightcoreTutorialStep.selectFirstHex);
    expect(controller.isOuterSlotUnlocked(0), isTrue);
  });

  test('core shot tutorial appears immediately after the shell opens', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();

    expect(controller.tutorialStep, LightcoreTutorialStep.tapBattleCore);
    expect(controller.tutorialHighlightsBattleCore, isTrue);
    expect(controller.tutorialBattleCoreGuideLabel, 'TAP CORE');
    expect(
      controller.tutorialPrompt,
      'Tap the glowing Lightcore once. The center can create a basic shot before tower queues take over.',
    );

    controller.handleBattleCenterTap();

    expect(controller.pulses, hasLength(1));
    expect(controller.queuedCorePackets, 0);
    expect(controller.tutorialStep, LightcoreTutorialStep.waitForFirstHex);
    expect(controller.tutorialHighlightsCoreStats, isFalse);
  });

  test('same-color attacks are resisted', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(
      controller.affinityMultiplier(
        PrototypeAffinity.ember,
        PrototypeAffinity.ember,
      ),
      lessThan(1),
    );
    expect(
      controller.affinityMultiplier(
        PrototypeAffinity.ember,
        PrototypeAffinity.flare,
      ),
      greaterThan(1),
    );
  });

  test('boss tutorial waits 100 clears before spawning weak White Warden', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(
      controller.activeBossEnemyCard?.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );
    expect(controller.activeLayer.bossReady, isFalse);
    expect(controller.activeLayer.normalKillsSinceBoss, 0);

    controller.selectCenter();
    controller.debugCompleteCoreLearningTutorial();

    for (
      var kill = 0;
      kill < LightcoreController.bossSpawnKillRequirement - 1;
      kill += 1
    ) {
      final enemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: controller.spawnRadius,
      );
      expect(enemy, isNotNull);
      expect(controller.debugDefeatEnemy(enemy!.id), isTrue);
    }

    expect(
      controller.activeLayer.normalKillsSinceBoss,
      LightcoreController.bossSpawnKillRequirement - 1,
    );
    expect(controller.activeLayer.bossReady, isFalse);
    expect(controller.bossKillsRemaining, 1);

    final finalEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: controller.spawnRadius,
    );
    expect(finalEnemy, isNotNull);
    expect(controller.debugDefeatEnemy(finalEnemy!.id), isTrue);

    expect(
      controller.activeLayer.normalKillsSinceBoss,
      LightcoreController.bossSpawnKillRequirement,
    );
    expect(controller.activeLayer.bossReady, isTrue);

    for (var step = 0; step < 20 && !controller.bossAlive; step += 1) {
      controller.tick(0.2);
    }

    expect(controller.tutorialStep, LightcoreTutorialStep.defeatFirstBoss);
    expect(controller.bossAlive, isTrue);
    expect(
      controller.enemies.single.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );
    expect(controller.enemies.single.maxHealth, lessThan(1500));
    expect(controller.tutorialHighlightedEnemyId, isNotNull);
  });

  test('first child shell teaches shot generation before overdrive', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    _finishBossAndEquipmentTutorial(controller);

    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    controller.selectCenter();

    expect(controller.tutorialStep, LightcoreTutorialStep.none);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
    expect(controller.tutorialStep, LightcoreTutorialStep.tapSecondShellTower);
    expect(controller.tutorialHighlightsBattleSlot(0), isTrue);
    expect(controller.activateTowerSlot(0, showBanner: false), isTrue);
    expect(controller.tutorialHighlightsBattleSlot(0), isFalse);
    expect(
      controller.tutorialStep,
      LightcoreTutorialStep.holdOverdrive,
      reason:
          'step=${controller.tutorialStep} tier=${controller.activeLayer.tier} parent=${controller.activeLayer.parentLayerId} childLayers=${controller.layers.where((layer) => layer.parentLayerId != null).length}',
    );
    expect(
      controller.tutorialShowcaseTarget,
      LightcoreTutorialPulseTarget.overdriveButton,
    );
    expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
    expect(controller.tutorialStep, LightcoreTutorialStep.holdOverdrive);

    final beforePulse = controller.tutorialPulseSignalFor(
      LightcoreTutorialPulseTarget.overdriveButton,
    );
    expect(controller.showcaseCurrentTutorialTarget(), isTrue);
    expect(
      controller.tutorialPulseSignalFor(
        LightcoreTutorialPulseTarget.overdriveButton,
      ),
      greaterThan(beforePulse),
    );

    controller.startManualOverdrive();
    controller.tick(0.35);

    expect(controller.manualOverdriveMultiplier, greaterThan(1.1));
    expect(controller.tutorialStep, LightcoreTutorialStep.openTowerMatrix);
  });

  test(
    'manager quest appears after shell coverage and advanced assignment',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      _promoteToLayer3(controller);
      _finishBossAndEquipmentTutorial(controller);
      controller.experience = LightcoreController.experienceForOverallLevel(
        LightcoreController.managerUnlockLevel,
      );
      controller.tick(0.01);

      expect(controller.managersUnlocked, isTrue);

      if (controller.tutorialStep == LightcoreTutorialStep.holdOverdrive) {
        controller.startManualOverdrive();
        controller.tick(0.35);
      }

      expect(controller.tutorialStep, LightcoreTutorialStep.openManagers);

      controller.markTutorialManagersOpened();

      expect(controller.tutorialStep, LightcoreTutorialStep.forgeTowerManager);
      _completeManagerTutorials(controller);
      expect(controller.tutorialStep, LightcoreTutorialStep.openTowerMatrix);
    },
  );

  test(
    'level 20 unlocks screen-name setup and level 30 unlocks mentorship',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      _finishBossAndEquipmentTutorial(controller);
      controller.selectCenter();
      controller.lumens = 100000;
      controller.kills = LightcoreController.killsForOverallLevel(
        LightcoreController.tournamentUnlockLevel,
      );
      controller.buildTowerAt(0, TowerLibrary.redPrism);
      controller.buildTowerAt(1, TowerLibrary.all[1]);
      _completeManagerTutorials(controller);
      _completeSidecarTutorials(controller);
      _completeManagerTutorials(controller);
      _completeSidecarTutorials(controller);

      expect(controller.tutorialStep, LightcoreTutorialStep.setScreenName);
      expect(controller.setScreenName('Nova Relay', showBanner: false), isTrue);
      expect(controller.tutorialStep, LightcoreTutorialStep.openFriends);

      controller.markTutorialFriendsOpened();
      expect(controller.tutorialStep, LightcoreTutorialStep.inspectEnemyBlitz);

      controller.experience = LightcoreController.experienceForOverallLevel(
        LightcoreController.mentorshipUnlockLevel,
      );
      controller.tick(0.01);
      expect(controller.tutorialStep, LightcoreTutorialStep.openMentees);

      controller.markTutorialMentorshipOpened();
      expect(controller.tutorialStep, LightcoreTutorialStep.inspectEnemyBlitz);

      controller.markTutorialTournamentModeReviewed(
        LightcoreTournamentModeId.enemyBlitz,
      );
      expect(controller.tutorialStep, LightcoreTutorialStep.inspectHexGauntlet);

      controller.markTutorialTournamentModeReviewed(
        LightcoreTournamentModeId.hexGauntlet,
      );
      expect(controller.tutorialStep, LightcoreTutorialStep.inspectArenaFlow);

      controller.markTutorialTournamentModeReviewed(
        LightcoreTournamentModeId.arenaFlow,
      );
      expect(controller.tutorialStep, LightcoreTutorialStep.none);
    },
  );

  test(
    'screen-name validation counts visible characters after spacing cleanup',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.kills = LightcoreController.killsForOverallLevel(
        LightcoreController.tournamentUnlockLevel,
      );

      expect(
        controller.validateScreenName('A B'),
        'Screen names need at least 3 visible characters.',
      );
      expect(
        controller.setScreenName('  Nova   Relay  ', showBanner: false),
        isTrue,
      );
      expect(controller.screenName, 'Nova Relay');
    },
  );
}
