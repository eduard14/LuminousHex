part of '../lightcore_controller.dart';

extension LightcoreControllerBattleResetActions on LightcoreController {
  double enemyCardPreviewSpeed(EnemyCardState card) {
    return _balancedEnemyStat(card.config, 'baseSpeed', card.config.baseSpeed) *
        _enemyCardLevelSpeedScale(card.level);
  }

  void rebootEncounter({bool showBanner = true}) {
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _ammoQueue.clear();
    _blueFocusTargetEnemyIdBySlot.clear();
    elapsed = 0;
    _spawnTimer = 1.0;
    _spawnSequence = 0;
    _activeSpawnClusterIndex = null;
    _enemyCounter = 0;
    _pulseCounter = 0;
    _shotCounter = 0;
    _impactCounter = 0;
    _enemyTicketBuffer = 0;
    _resetLevelUpRadiance();
    activeLayer.normalKillsSinceBoss = 0;
    activeLayer.bossReady = false;
    if (activeLayer.layer3TrialActive) {
      activeLayer.layer3TrialActive = false;
      activeLayer.layer3TrialCleared = false;
      activeLayer.layer3TrialSpawnIndex = 0;
    }
    _resetManualOverdrive();
    _core = _core.copyWith(
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      packetCooldownRemaining: 0,
    );
    _layer2 = _layer2.copyWith(fireCooldownRemaining: 0);
    _slots = _slots
        .map(
          (slot) =>
              slot.copyWith(charge: 0, cooldownRemaining: 0, disruption: 0),
        )
        .toList();
    if (showBanner) {
      _showBanner('Swarm field reset. Built towers remain online.');
    }
    _notifyNow();
  }

  void scrapActiveLayer() {
    if (!canScrapActiveLayer) {
      _showBanner(
        'Only child shells without deeper descendants can be scrapped right now.',
      );
      _notifyNow();
      return;
    }

    for (var index = 0; index < _cards.length; index++) {
      final card = _cards[index];
      if (card.equippedLayerId == activeLayer.id) {
        _cards[index] = card.copyWith(clearEquippedSlot: true);
      }
    }
    for (var index = 0; index < _enemyManagers.length; index++) {
      final manager = _enemyManagers[index];
      if (manager.assignedLayerId == activeLayer.id) {
        _enemyManagers[index] = manager.copyWith(clearAssignment: true);
      }
    }

    final reset = _freshLayerSnapshot(
      label: activeLayer.label,
      tier: activeLayer.tier,
      initialEnemyDeck: List<String>.from(activeLayer.activeEnemyCardIds),
      parentLayerId: activeLayer.parentLayerId,
      parentSlotIndex: activeLayer.parentSlotIndex,
      sourceLayerId: activeLayer.sourceLayerId,
    );

    activeLayer.slots = reset.slots;
    activeLayer.core = reset.core;
    activeLayer.layer2 = reset.layer2;
    activeLayer.enemies = reset.enemies;
    activeLayer.pulses = reset.pulses;
    activeLayer.shots = reset.shots;
    activeLayer.impacts = reset.impacts;
    activeLayer.ammoQueue = reset.ammoQueue;
    activeLayer.activeEnemyCardIds = reset.activeEnemyCardIds;
    activeLayer.enemyTargetCount = reset.enemyTargetCount;
    activeLayer.enemyTargetUpgradeLevel = reset.enemyTargetUpgradeLevel;
    activeLayer.outerRingRevealed = false;
    activeLayer.swarmActivated = false;
    activeLayer.selectedSlotIndex = null;
    activeLayer.selectedEnemyCardId = reset.selectedEnemyCardId;
    activeLayer.elapsed = 0;
    activeLayer.spawnTimer = 1.35;
    activeLayer.spawnSequence = 0;
    _activeSpawnClusterIndex = null;
    activeLayer.enemyCounter = 0;
    activeLayer.pulseCounter = 0;
    activeLayer.shotCounter = 0;
    activeLayer.impactCounter = 0;
    activeLayer.childTowerUpgrades = reset.childTowerUpgrades;
    activeLayer.promotedIntoParentSlot = false;
    activeLayer.promotionTraitRoll = 0;
    activeLayer.layer3TrialActive = false;
    activeLayer.layer3TrialCleared = false;
    activeLayer.layer3TrialSpawnIndex = 0;

    _syncParentSlotFromLayer(activeLayer);
    _loadLayer(activeLayer);
    _showBanner(
      'Shell deconstructed. Rebuild it to align a different ${shellBadgeForTier(activeLayerTargetTier)} tower.',
    );
    _notifyNow();
  }

  void hardResetGame() {
    _resetManualOverdrive();
    _cards = <InventoryCard>[];
    _enemyManagers = <EnemyManagerState>[];
    _equipmentInventory = <PlayerEquipmentItem>[];
    _newEquipmentItemIds.clear();
    _equippedPlayerItems = <EquipmentLoadoutSlot, String?>{
      for (final slot in EquipmentLoadoutSlot.values) slot: null,
    };
    _equippedProfileMedalId = null;
    _unlockedProfileMedalIds.clear();
    _equipmentDropCounter = 0;
    _enemyCards = _createEnemyCardInventory();
    _bossEnemyCards = _createBossEnemyCardInventory();
    _activeBossEnemyCardId = BossEnemyLibrary.starterWhiteWarden.id;
    _activeEnemyCardIds.clear();
    _lastEnemyPackPulls = <PackPullResult>[];
    _lastBossPackPulls = <PackPullResult>[];
    _seedStarterEnemyCards();
    _seedStarterManagers();
    _layers = <TowerLayerSnapshot>[];
    final rootLayer = _freshLayerSnapshot(label: shellNameForTier(1), tier: 1);
    _layers.add(rootLayer);
    _viewLayerId = rootLayer.id;
    _runtimeLayerId = rootLayer.id;
    _loadLayer(rootLayer);
    _armStarterBossForOpening();
    lumens = 44;
    flux = 96;
    prismShards = 0;
    managerShards = 0;
    managerPowerLevel = 0;
    shellCores = 0;
    enemyTickets = 18;
    bossTickets = 0;
    bossCores = 0;
    enemyPullCount = 0;
    bossPullCount = 0;
    towerManagerPullCount = 0;
    enemyManagerPullCount = 0;
    kills = 0;
    experience = 0;
    echoSeeds = 0;
    _resetRadianceStats();
    _resetLevelUpRadiance();
    totalHelpSectionsRead = 0;
    _lumenHarvestSlowdown = 0;
    _enemyTicketBuffer = 0;
    _bossUnlockGrantClaimed = false;
    _readHelpSections.clear();
    _outerRingRevealed = false;
    _swarmActivated = false;
    _battleSpawnPolicy = LightcoreBattleSpawnPolicy.automatic;
    _enemySpiralMovementEnabled = true;
    _enemyMovementSpeedMultiplier = 1.0;
    _battleKillRewardsEnabled = true;
    _lastEnemyPackPulls = <PackPullResult>[];
    _lastBossPackPulls = <PackPullResult>[];
    _battlePasses = _createBattlePassMap();
    _sharedRelayCenterPieceId = null;
    _sharedRelayOuterPieceIds = List<String?>.filled(slotCount, null);
    _totalBattleSeconds = 0;
    _totalOfflineSecondsClaimed = 0;
    _totalUpgradesBought = 0;
    _totalTowersBuilt = 0;
    _totalManagersForged = 0;
    _totalBossesDefeated = 0;
    _totalLumensSpent = 0;
    _totalFluxSpent = 0;
    _totalPrismShardsSpent = 0;
    _totalTimeWarpSecondsClaimed = 0;
    _timeWarpPurchaseWeekKey = _currentWeekKey();
    _timeWarpWeeklyPurchases.clear();
    _storeOfferPurchaseWeekKey = _currentWeekKey();
    _storeOfferWeeklyPurchases.clear();
    _dailyDungeonHighestUnlockedTowerLevel = dailyDungeonStartingTowerLevel;
    _dailyDungeonHighestClearedTowerLevel = 0;
    _dailyDungeonQuickClearDayKey = _currentDayKey();
    _dailyDungeonQuickClearsUsed = 0;
    _completedTowerShells.clear();
    _initializeSharedRelayLoadout();
    _activeGuild = null;
    _guildChatCounter = 0;
    _tutorialEarlyQuestChainCompleted = false;
    _tutorialFirstBossDefeated = false;
    _tutorialFirstEquipmentOpened = false;
    _tutorialFirstManagersOpened = false;
    _tutorialFirstEnemyTargetSet = false;
    _tutorialEnemyCountAdjusted = false;
    _tutorialFirstTowerStatsOpened = false;
    _tutorialStabilityPanelOpened = false;
    _tutorialTowerMatrixOpened = false;
    _tutorialStoreOpened = false;
    _tutorialBattlePassRewardClaimed = false;
    _tutorialTowerManagerAssigned = false;
    _tutorialEnemyManagerAssigned = false;
    _tutorialFriendsOpened = false;
    _tutorialMenteesOpened = false;
    _tutorialMentorsOpened = false;
    _tutorialCoreShotTapLearned = false;
    _tutorialSecondShellShotTapLearned = false;
    _tutorialOverdriveLearned = false;
    _tutorialStep = LightcoreTutorialStep.none;
    _tutorialIntroBossPending = true;
    _tutorialSafeScanDefeats = 0;
    _tutorialAutoQueuedPulses = 0;
    _tutorialTrackedBossEnemyId = null;
    _tutorialPulseTarget = null;
    _tutorialPulseSignal = 0;
    _rewardedTutorialSteps.clear();
    _armStarterBossForOpening();
    _showBanner(
      'Cycle reset. Tap the main tower to unfold a new shell.',
      duration: 3.4,
    );
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }
}
