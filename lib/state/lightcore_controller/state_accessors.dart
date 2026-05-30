part of '../lightcore_controller.dart';

const bool _openEventLevelWallsForTesting = false;

extension LightcoreControllerStateAccessors on LightcoreController {
  void _recordLumenSpend(int amount) {
    if (amount > 0) {
      _totalLumensSpent += amount;
    }
  }

  void _recordFluxSpend(int amount) {
    if (amount > 0) {
      _totalFluxSpent += amount;
    }
  }

  void _recordPrismShardSpend(int amount) {
    if (amount > 0) {
      _totalPrismShardsSpent += amount;
    }
  }

  void _recordUpgradePurchase() {
    _totalUpgradesBought += 1;
  }

  String _tutorialTowerShotGuideLabel(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return 'WAIT';
    }
    final tower = _slots[slotIndex];
    if (_pulses.any((pulse) => pulse.sourceSlotIndex == slotIndex)) {
      return 'TAP TOWER';
    }
    if (tower.cooldownRemaining > 0) {
      return 'COOLDOWN';
    }
    return 'CHARGING';
  }

  double get _radianceMightPowerBonus =>
      radianceStatRank(LightcoreRadianceStat.might) * 0.006;

  double get _radianceMightCritDamageBonus =>
      radianceStatRank(LightcoreRadianceStat.might) * 0.0025;

  double get _radianceMightBossDamageBonus =>
      radianceStatRank(LightcoreRadianceStat.might) * 0.0025;

  double get _radianceFocusRangeBonus =>
      radianceStatRank(LightcoreRadianceStat.focus) * 0.0035;

  double get _radianceFocusCritChanceBonus =>
      radianceStatRank(LightcoreRadianceStat.focus) * 0.001;

  double get _radianceFocusCritDamageBonus =>
      radianceStatRank(LightcoreRadianceStat.focus) * 0.001;

  double get _radianceTempoChargeBonus =>
      radianceStatRank(LightcoreRadianceStat.tempo) * 0.005;

  double get _radianceTempoCoreFireSpeedBonus =>
      radianceStatRank(LightcoreRadianceStat.tempo) * 0.003;

  double get _radianceInsightExperienceBonus =>
      radianceStatRank(LightcoreRadianceStat.insight) * 0.0025;

  double get _radianceInsightLumenBonus =>
      radianceStatRank(LightcoreRadianceStat.insight) * 0.004;

  double get _radianceInsightFluxBonus =>
      radianceStatRank(LightcoreRadianceStat.insight) * 0.003;

  double get _radianceInsightTicketBonus =>
      radianceStatRank(LightcoreRadianceStat.insight) * 0.0025;

  double get _radianceInsightDropBonus =>
      radianceStatRank(LightcoreRadianceStat.insight) * 0.0025;

  double get _radianceCoreCooldownMultiplier =>
      (1 - _radianceTempoCoreFireSpeedBonus).clamp(0.72, 1.0).toDouble();

  double get _radianceExperienceMultiplier =>
      1 + _radianceInsightExperienceBonus;

  ProfileMedalStatus _profileMedalStatusFor(ProfileMedalConfig config) {
    final progress = _profileMedalProgress(config);
    final unlocked =
        _unlockedProfileMedalIds.contains(config.id) ||
        progress >= config.requiredValue;
    return ProfileMedalStatus(
      config: config,
      unlocked: unlocked,
      equipped: _equippedProfileMedalId == config.id,
      progress: progress,
      target: config.requiredValue,
    );
  }

  int _profileMedalProgress(ProfileMedalConfig config) {
    return switch (config.id) {
      'first_prism' => max(_totalTowersBuilt, builtTowerCount),
      'ringwright' => max(_totalTowersBuilt, builtTowerCount),
      'apex_breaker' => totalBossesDefeated,
      'radiance_crest' => overallLevel,
      'signal_hunter' => ownedEnemyCardCount,
      'foundry_patron' => totalManagersForged,
      'dungeon_climber' => dailyDungeonHighestClearedTowerLevel,
      'ascendant' => prestigeLevel,
      _ => 0,
    };
  }

  void _syncProfileMedalAchievements({required bool showBanner}) {
    final newlyUnlocked = <ProfileMedalConfig>[];
    for (final config in MedalLibrary.all) {
      if (_profileMedalProgress(config) >= config.requiredValue &&
          _unlockedProfileMedalIds.add(config.id)) {
        newlyUnlocked.add(config);
      }
    }
    _normalizeEquippedProfileMedal();
    if (!showBanner || newlyUnlocked.isEmpty) {
      return;
    }
    final first = newlyUnlocked.first;
    final suffix = newlyUnlocked.length == 1
        ? ''
        : ' +${newlyUnlocked.length - 1} more';
    _showBanner('Medal unlocked: ${first.name}$suffix.');
  }

  void _normalizeEquippedProfileMedal() {
    final medalId = _equippedProfileMedalId;
    if (medalId == null) {
      return;
    }
    if (!MedalLibrary.byId.containsKey(medalId) ||
        !_unlockedProfileMedalIds.contains(medalId)) {
      _equippedProfileMedalId = null;
    }
  }

  double _passiveLumenBaseForLayer(TowerLayerSnapshot layer) {
    final managed = _managedTowerCountForLayer(layer);
    if (managed == 0) {
      return 0;
    }
    final tierScale = pow(2, layer.tier - 1).toDouble();
    final passiveOnlyScale = isLayerPassiveOnly(layer)
        ? _promotedSourcePassiveMultiplier
        : 1.0;
    return ((managed * 0.18) + (layer.core.level * 0.04)) *
        tierScale *
        passiveOnlyScale;
  }

  UnmodifiableListView<TowerConfig> get towerConfigs =>
      UnmodifiableListView(TowerLibrary.all);

  UnmodifiableListView<OuterTowerState> get slots =>
      UnmodifiableListView(_slots);

  UnmodifiableListView<InventoryCard> get cards => UnmodifiableListView(_cards);

  UnmodifiableListView<EnemyManagerState> get enemyManagers =>
      UnmodifiableListView(_enemyManagers);

  InventoryCard? get towerCoreManager =>
      managerAssignmentUnlocked ? _towerCoreManagerForLayer(activeLayer) : null;

  EnemyManagerState? get enemyCoreManager =>
      managerAssignmentUnlocked ? _enemyCoreManagerForLayer(activeLayer) : null;

  UnmodifiableListView<EnemyCardState> get enemyCards =>
      UnmodifiableListView(_enemyCards);

  UnmodifiableListView<EnemyCardState> get bossEnemyCards =>
      UnmodifiableListView(_bossEnemyCards);

  UnmodifiableListView<PlayerEquipmentItem> get equipmentInventory =>
      UnmodifiableListView(_equipmentInventory);

  UnmodifiableListView<ProfileMedalStatus> get profileMedals =>
      UnmodifiableListView(
        MedalLibrary.all.map(_profileMedalStatusFor).toList(growable: false),
      );

  UnmodifiableListView<String> get activeEnemyCardIds =>
      UnmodifiableListView(_activeEnemyCardIds);

  UnmodifiableListView<EnemyState> get enemies =>
      UnmodifiableListView(_enemies);

  String? get focusedEnemyId => _focusedEnemyId;

  double get focusTargetRemainingSeconds => _focusTargetRemainingSeconds;

  double get focusTargetCooldownRemaining => _focusTargetCooldownRemaining;

  bool get canFocusBattleEnemy => _focusTargetCooldownRemaining <= 0;

  UnmodifiableListView<EnergyPulseState> get pulses =>
      UnmodifiableListView(_pulses);

  UnmodifiableListView<CoreShotState> get shots => UnmodifiableListView(_shots);

  UnmodifiableListView<ImpactState> get impacts =>
      UnmodifiableListView(_impacts);

  UnmodifiableListView<PackPullResult> get lastEnemyPackPulls =>
      UnmodifiableListView(_lastEnemyPackPulls);

  UnmodifiableListView<PackPullResult> get lastBossPackPulls =>
      UnmodifiableListView(_lastBossPackPulls);

  LightcoreGuideProfile get guideProfile => _guideProfile;

  String get playerId => _playerId;

  String? get screenName => _screenName;

  bool get hasCustomScreenName =>
      _screenName != null &&
      _screenNameVisibleLength(_screenName!) >= minScreenNameLength;

  String get playerDisplayName =>
      hasCustomScreenName ? _screenName!.trim() : _playerId;

  LightcoreSocialOverview? get socialOverview => _socialOverview;

  bool get hasServerSocialOverview => _socialOverview != null;

  LightcoreSocialBonusProfile get socialBonusProfile =>
      _socialOverview?.bonusProfile ?? LightcoreSocialBonusProfile.zero;

  UnmodifiableListView<TowerLayerSnapshot> get layers =>
      UnmodifiableListView(_layers);

  bool isLayerPassiveOnly(TowerLayerSnapshot layer) =>
      layer.promotedParentLayerId != null || layer.promotedIntoParentSlot;

  bool get activeLayerPassiveOnly => isLayerPassiveOnly(activeLayer);

  bool get _activeLayerAllowsProgressionUpgrades =>
      _threatRegionChallenge == null &&
      (!activeLayerPassiveOnly || activeLayerHasParentSlot);

  int get newEquipmentNotificationCount => _newEquipmentItemIds.length;

  bool get hasNewEquipmentNotifications => _newEquipmentItemIds.isNotEmpty;

  LightcoreGraphicsQuality get graphicsQuality => _graphicsQuality;

  bool get notificationBannersEnabled => _notificationBannersEnabled;

  bool get battleNotificationBannersEnabled =>
      _battleNotificationBannersEnabled;

  bool get tutorialPromptsEnabled => _tutorialPromptsEnabled;

  bool get localhostAutoTapperEnabled => _localhostAutoTapperEnabled;

  bool get levelUpRadianceActive => _levelUpRadianceProgress < 1;

  double get levelUpRadianceProgress => _levelUpRadianceProgress;

  int get levelUpRadianceSequence => _levelUpRadianceSequence;

  int get lastLevelUpRadianceLevel => _lastLevelUpRadianceLevel;

  int get lastLevelUpRadianceDestroyedEnemies =>
      _lastLevelUpRadianceDestroyedEnemies;

  void pushNotification(String message, {double duration = 2.8}) {
    _showBanner(message, duration: duration);
    _notifyNow();
  }

  void setNotificationBannersEnabled(bool enabled) {
    if (_notificationBannersEnabled == enabled) {
      return;
    }
    _notificationBannersEnabled = enabled;
    _notifyNow();
  }

  void setBattleNotificationBannersEnabled(bool enabled) {
    if (_battleNotificationBannersEnabled == enabled) {
      return;
    }
    _battleNotificationBannersEnabled = enabled;
    _notifyNow();
  }

  void setGraphicsQuality(LightcoreGraphicsQuality quality) {
    if (_graphicsQuality == quality) {
      return;
    }
    _graphicsQuality = quality;
    _notifyNow();
  }

  void setTutorialPromptsEnabled(bool enabled) {
    if (_tutorialPromptsEnabled == enabled) {
      return;
    }
    _tutorialPromptsEnabled = enabled;
    _notifyNow();
  }

  void setLocalhostAutoTapperEnabled(bool enabled) {
    if (_localhostAutoTapperEnabled == enabled) {
      return;
    }
    _localhostAutoTapperEnabled = enabled;
  }

  void markNewEquipmentNotificationsSeen() {
    if (_newEquipmentItemIds.isEmpty) {
      return;
    }
    _newEquipmentItemIds.clear();
    _notifyNow();
  }

  CoreState get coreState => _core;

  int get coreDamageSequence =>
      _coreDamageSequencesByLayer[_activeLayerId] ?? 0;

  double get coreDamageAmount => _coreDamageAmountsByLayer[_activeLayerId] ?? 0;

  Layer2TowerState get layer2State => _layer2;

  double get relayImpactRadius => _relayImpactRadius;

  double get spawnRadius => _currentSpawnBaseRadius;

  double get spawnCeilingRadius => spawnRadius + _spawnRadiusBandVariance;

  int? get towerRangePreviewSlotIndex => _towerRangePreviewSlotIndex;

  double get defaultTowerBaseRange =>
      _relayImpactRadius +
      ((spawnRadius - _relayImpactRadius) * _defaultTowerLaneRangeShare);

  TowerLayerSnapshot get activeLayer => _layerById(_activeLayerId);

  TowerLayerSnapshot get viewedLayer => _layerById(_viewLayerId);

  TowerLayerSnapshot get runtimeLayer => _layerById(_runtimeLayerId);

  TowerLayerSnapshot get homeTowerLayer {
    var bestLayer = activeLayer;
    for (final layer in _layers) {
      if (layer.tier > bestLayer.tier) {
        bestLayer = layer;
      }
    }
    return bestLayer;
  }

  int get homeTowerTier => homeTowerLayer.tier;

  String get homeTowerLayerLabel => layerDisplayLabel(homeTowerLayer);

  int get homeTowerPowerIndex => max(
    evenEntryTournamentPowerIndex,
    min(tournamentPowerIndexCap, globalRankingTowerStrength),
  );

  OuterTowerState? get selectedSlotOrNull =>
      selectedSlotIndex == null ? null : _slots[selectedSlotIndex!];

  EnemyCardState? get selectedEnemyCardOrNull =>
      selectedEnemyCardId == null ? null : enemyCardById(selectedEnemyCardId!);

  EnemyCardState? get activeBossEnemyCard {
    final regionBosses = activeThreatRegionBossCards;
    if (regionBosses.isNotEmpty) {
      return regionBosses.first;
    }
    return _activeBossEnemyCardId == null
        ? null
        : (() {
            final card = bossEnemyCardById(_activeBossEnemyCardId!);
            return card != null && card.isOwned ? card : null;
          })();
  }

  OuterTowerState get selectedSlot => selectedSlotOrNull ?? _slots.first;

  bool get isCenterSelected => selectedSlotIndex == null;

  bool get outerRingRevealed => _outerRingRevealed;

  bool get swarmActivated => _swarmActivated;

  LightcoreBattleSpawnPolicy get battleSpawnPolicy => _battleSpawnPolicy;

  bool get battleUsesManualEnemySpawns =>
      _battleSpawnPolicy == LightcoreBattleSpawnPolicy.manual;

  int get builtTowerCount => _slots.where(_slotCountsTowardRing).length;

  int get enemyCount => _enemies.length;

  int get enemyTargetCount => _enemyTargetCount;

  int get enemyTargetFloor => minEnemyTarget;

  int get enemyTargetMax => _enemyTargetMaxForLevel(_enemyTargetUpgradeLevel);

  int get ownedEnemyCardCount =>
      _enemyCards.where((card) => card.isOwned).length;

  int get upgradableEnemyCardCount =>
      _enemyCards.where(canUpgradeEnemyCard).length;

  int get mergeableEnemyCardCount =>
      _enemyCards.where(canMergeEnemyCard).length;

  int get ownedBossEnemyCardCount =>
      _bossEnemyCards.where((card) => card.isOwned).length;

  int get upgradableBossEnemyCardCount =>
      _bossEnemyCards.where(canUpgradeBossEnemyCard).length;

  List<EnemyCardState> get ownedBossEnemyCards =>
      _bossEnemyCards.where((card) => card.isOwned).toList(growable: false);

  List<EnemyCardState> get availableUnresolvedBossScanCards {
    final availableRarities = availableBossPullRarities.toSet();
    final activeBossId = activeBossEnemyCard?.config.id;
    return _bossEnemyCards
        .where(
          (card) =>
              !card.isOwned &&
              card.config.id != activeBossId &&
              availableRarities.contains(card.config.rarity),
        )
        .toList(growable: false);
  }

  int get summoningLevel => summoningLevelForPullCount(enemyPullCount);

  int get bossSummoningLevel => min(
    maxBossSummoningLevel,
    1 + (bossPullCount ~/ bossPullsPerSummoningLevel),
  );

  int get prestigeLevel =>
      _layers.fold(0, (best, layer) => max(best, layer.tier - 1));

  int get progressionLayer => max(1, prestigeLevel + 1);

  int get promotionReadyTowerCount =>
      _slots.where(_slotCountsTowardRing).where(_slotReadyForPromotion).length;

  bool get layerNavigationUnlocked => payloadsUnlocked;

  bool get payloadsUnlocked => progressionLayer >= payloadUnlockLayer;

  bool get managersUnlocked =>
      _layers.any(_managerShellCoverageUnlockedForLayer) ||
      _cards.isNotEmpty ||
      _enemyManagers.isNotEmpty;

  bool get managerAssignmentUnlocked =>
      _managerAssignmentUnlockedForLayer(activeLayer);

  bool get coreAutoGenerationUnlocked =>
      _outerRingRevealed && !activeLayerPassiveOnly;

  bool get coreAutoFireUnlocked =>
      _towerCoreManagerForLayer(activeLayer) != null;

  bool get isOuterRingComplete => builtTowerCount == slotCount;

  int get progressionExperience => max(experience, kills);

  int get overallLevel => overallLevelForExperience(progressionExperience);

  int get accountRadianceLevel => overallLevel;

  String get accountRadianceLabel =>
      'Account Radiance Lv $accountRadianceLevel';

  bool get bossHuntsUnlocked => progressionLayer >= bossUnlockLayer;

  bool get dailyDungeonsUnlocked =>
      _openEventLevelWallsForTesting ||
      firstRegionalBossCleared ||
      overallLevel >= dailyDungeonUnlockLevel;

  bool get tournamentsUnlocked =>
      _openEventLevelWallsForTesting ||
      bossHuntsUnlocked ||
      firstThreatRingFullyStabilized ||
      overallLevel >= tournamentUnlockLevel;

  bool get mentorshipUnlocked => overallLevel >= mentorshipUnlockLevel;

  int get dailyDungeonHighestUnlockedTowerLevel =>
      _dailyDungeonHighestUnlockedTowerLevel;

  int get dailyDungeonHighestClearedTowerLevel =>
      _dailyDungeonHighestClearedTowerLevel;

  int get dailyDungeonQuickClearsUsed {
    _refreshDailyDungeonQuickClearsForToday();
    return _dailyDungeonQuickClearsUsed;
  }

  int get dailyDungeonQuickClearsRemaining {
    _refreshDailyDungeonQuickClearsForToday();
    return max(0, dailyDungeonQuickClearsPerDay - _dailyDungeonQuickClearsUsed);
  }

  String get dailyDungeonQuickClearLabel =>
      '$dailyDungeonQuickClearsRemaining/$dailyDungeonQuickClearsPerDay daily clears today';

  String get shellCoreLabel =>
      LightcoreCurrencyLabels.shellCoreCount(shellCores);

  bool get completedShellLibraryUnlocked =>
      progressionLayer >= payloadUnlockLayer;

  int get tournamentLevelsRemaining =>
      tournamentsUnlocked ? 0 : max(0, tournamentUnlockLevel - overallLevel);

  int get dailyDungeonLevelsRemaining => dailyDungeonsUnlocked
      ? 0
      : max(0, dailyDungeonUnlockLevel - overallLevel);

  int get managerLevelsRemaining => max(0, managerUnlockLevel - overallLevel);

  int get mentorshipLevelsRemaining =>
      max(0, mentorshipUnlockLevel - overallLevel);

  bool get canEditScreenName => tournamentsUnlocked;

  int get bossLevelsRemaining => max(0, bossUnlockLayer - progressionLayer);

  double get bossUnlockProgress =>
      bossHuntsUnlocked ? 1.0 : promotionProgress.clamp(0.0, 1.0);

  int get overallLevelFloorExperience =>
      experienceForOverallLevel(overallLevel);

  int get overallLevelFloorKills => overallLevelFloorExperience;

  int get nextOverallLevel => overallLevel + 1;

  int get nextOverallLevelTargetExperience =>
      experienceForOverallLevel(nextOverallLevel);

  int get nextOverallLevelTargetKills => nextOverallLevelTargetExperience;

  int get experienceIntoCurrentOverallLevel =>
      progressionExperience - overallLevelFloorExperience;

  int get killsIntoCurrentOverallLevel => experienceIntoCurrentOverallLevel;

  int get experienceNeededForCurrentOverallLevel =>
      max(1, nextOverallLevelTargetExperience - overallLevelFloorExperience);

  int get killsNeededForCurrentOverallLevel =>
      experienceNeededForCurrentOverallLevel;

  int get experienceToNextOverallLevel =>
      max(0, nextOverallLevelTargetExperience - progressionExperience);

  int get killsToNextOverallLevel => experienceToNextOverallLevel;

  double get totalBattleSeconds => _totalBattleSeconds;

  int get totalOfflineSecondsClaimed => _totalOfflineSecondsClaimed;

  int get totalUpgradesBought => _totalUpgradesBought;

  int get totalTowersBuilt => _totalTowersBuilt;

  int get totalManagersForged => _totalManagersForged;

  int get totalBossesDefeated => _totalBossesDefeated;

  int get totalLumensSpent => _totalLumensSpent;

  int get totalFluxSpent => _totalFluxSpent;

  int get totalPrismShardsSpent => _totalPrismShardsSpent;

  int get totalTimeWarpSecondsClaimed => _totalTimeWarpSecondsClaimed;

  int get totalPullsOpened => enemyPullCount + bossPullCount;

  double get overallLevelProgress =>
      (experienceIntoCurrentOverallLevel /
              experienceNeededForCurrentOverallLevel)
          .clamp(0.0, 1.0);

  int get unlockedOuterSlotCount {
    final unlocked = unlockedOuterSlotCountForExperience(progressionExperience);
    return _tutorialFirstHexTemporarilyLocked ? 0 : unlocked;
  }

  int get bossKillsIntoCycle => activeLayer.bossReady
      ? bossSpawnKillRequirement
      : activeLayer.normalKillsSinceBoss;

  int get bossKillsRemaining => activeLayer.bossReady
      ? 0
      : max(0, bossSpawnKillRequirement - activeLayer.normalKillsSinceBoss);

  double get bossSpawnProgress =>
      (bossKillsIntoCycle / bossSpawnKillRequirement).clamp(0.0, 1.0);

  bool get bossAlive => _enemies.any((enemy) => enemy.config.isBoss);

  LightcoreTutorialStep get tutorialStep => _tutorialStep;

  LightcoreTutorialQuestDefinition? get tutorialQuestDefinition =>
      _tutorialQuestDefinitions[_tutorialStep];

  String? get tutorialQuestId => tutorialQuestDefinition?.id;

  String? get tutorialPrimaryClickTarget =>
      tutorialQuestDefinition?.primaryClickTarget;

  String? get tutorialCompletionCondition =>
      tutorialQuestDefinition?.completionCondition;

  String? get tutorialLearningReward => tutorialQuestDefinition?.reward;

  String? get tutorialFailureHelp => tutorialQuestDefinition?.failureHelpState;

  bool get hasActiveTutorial => _tutorialStep != LightcoreTutorialStep.none;

  bool get tutorialUsesBattlefieldClickPiece =>
      _tutorialStep == LightcoreTutorialStep.unfoldShell ||
      _tutorialStep == LightcoreTutorialStep.selectFirstHex ||
      _tutorialStep == LightcoreTutorialStep.buildFirstRedTower ||
      _tutorialStep == LightcoreTutorialStep.inspectFirstTowerStats ||
      _tutorialStep == LightcoreTutorialStep.tapBattleCore ||
      _tutorialStep == LightcoreTutorialStep.tapFirstTower ||
      _tutorialStep == LightcoreTutorialStep.tapSecondShellTower ||
      _tutorialStep == LightcoreTutorialStep.upgradeFirstTowerToLevel3 ||
      _tutorialStep == LightcoreTutorialStep.upgradeFirstTowerToLevel4;

  bool get tutorialNeedsTowerPaletteGate {
    if (_earlyTutorialComplete || _currentLayerEarlyTutorialComplete) {
      return false;
    }
    return true;
  }

  bool get tutorialShowsStarterProjectileChoices =>
      _earlyTutorialComplete &&
      _totalTowersBuilt <= 1 &&
      builtTowerCount == 1 &&
      activeLayer.parentLayerId == null &&
      activeLayer.tier == 1 &&
      !_layer2.unlocked;

  bool get tutorialHighlightsBattleCore =>
      _tutorialStep == LightcoreTutorialStep.unfoldShell ||
      _tutorialStep == LightcoreTutorialStep.tapBattleCore;

  String? get tutorialBattleCoreGuideLabel =>
      _tutorialStep == LightcoreTutorialStep.tapBattleCore ? 'AUTO' : null;

  bool get tutorialHighlightsCoreStats =>
      _tutorialStep == LightcoreTutorialStep.readEffectiveGain ||
      _tutorialStep == LightcoreTutorialStep.autoQueueCheck;

  bool tutorialHighlightsTowerStatsButton(int slotIndex) =>
      _tutorialStep == LightcoreTutorialStep.inspectFirstTowerStats &&
      slotIndex == 0;

  bool tutorialHighlightsBattleSlot(int slotIndex) {
    if (slotIndex == 0 &&
        (_tutorialStep == LightcoreTutorialStep.selectFirstHex ||
            (_tutorialStep == LightcoreTutorialStep.inspectFirstTowerStats &&
                selectedSlotIndex != 0) ||
            ((_tutorialStep == LightcoreTutorialStep.buildFirstRedTower ||
                    _tutorialStep ==
                        LightcoreTutorialStep.upgradeFirstTowerToLevel3 ||
                    _tutorialStep ==
                        LightcoreTutorialStep.upgradeFirstTowerToLevel4) &&
                selectedSlotIndex != 0))) {
      return true;
    }
    final shotTutorialSlotIndex = _secondShellShotTutorialSlotIndex();
    return _tutorialStep == LightcoreTutorialStep.tapSecondShellTower &&
        shotTutorialSlotIndex == slotIndex;
  }

  String? tutorialBattleSlotGuideLabel(int slotIndex) {
    if (!tutorialHighlightsBattleSlot(slotIndex)) {
      return null;
    }
    return switch (_tutorialStep) {
      LightcoreTutorialStep.selectFirstHex => 'BUILD HERE',
      LightcoreTutorialStep.buildFirstRedTower => 'CHOOSE TOWER',
      LightcoreTutorialStep.inspectFirstTowerStats => 'OPEN STATS',
      LightcoreTutorialStep.upgradeFirstTowerToLevel3 ||
      LightcoreTutorialStep.upgradeFirstTowerToLevel4 => 'UPGRADE',
      LightcoreTutorialStep.tapSecondShellTower => _tutorialTowerShotGuideLabel(
        slotIndex,
      ),
      _ => null,
    };
  }

  bool get tutorialHighlightsPullsButton =>
      _tutorialStep == LightcoreTutorialStep.openBossPulls;

  bool get tutorialHighlightsStoreButton =>
      _tutorialStep == LightcoreTutorialStep.openStore;

  bool get tutorialHighlightsBattlePassButton =>
      _tutorialStep == LightcoreTutorialStep.claimBattlePassReward;

  bool get tutorialHighlightsFriendsButton =>
      _tutorialStep == LightcoreTutorialStep.openFriends;

  bool get tutorialHighlightsHeaderMenuButton =>
      _tutorialStep == LightcoreTutorialStep.setScreenName ||
      _tutorialStep == LightcoreTutorialStep.openFriends ||
      _tutorialStep == LightcoreTutorialStep.openMentees ||
      _tutorialStep == LightcoreTutorialStep.openMentors ||
      _tutorialStep == LightcoreTutorialStep.inspectEnemyBlitz ||
      _tutorialStep == LightcoreTutorialStep.inspectHexGauntlet ||
      _tutorialStep == LightcoreTutorialStep.inspectArenaFlow;

  bool get tutorialHighlightsEnemySinglePullButton =>
      fullThreatMapUnlocked &&
      (_tutorialStep == LightcoreTutorialStep.pullFirstWhiteEnemy ||
          _tutorialStep == LightcoreTutorialStep.pullFirstRedEnemy);

  bool get tutorialHighlightsBossSinglePullButton =>
      fullThreatMapUnlocked &&
      _tutorialStep == LightcoreTutorialStep.openBossPulls;

  bool get tutorialHighlightsThreatChallengeButton =>
      _tutorialStep == LightcoreTutorialStep.raiseThreat ||
      _tutorialStep == LightcoreTutorialStep.openBossPulls;

  bool get tutorialShowsBattleThreatPrompt =>
      _tutorialStep == LightcoreTutorialStep.raiseThreat;

  bool get tutorialHighlightsTowersNav =>
      _tutorialStep == LightcoreTutorialStep.openTowerMatrix;

  bool get tutorialHighlightsThreatMapNav =>
      _tutorialStep == LightcoreTutorialStep.pullFirstWhiteEnemy ||
      _tutorialStep == LightcoreTutorialStep.pullFirstRedEnemy ||
      _tutorialStep == LightcoreTutorialStep.adjustEnemyCount ||
      _tutorialStep == LightcoreTutorialStep.openBossPulls;

  bool get tutorialHighlightsEnemiesNav =>
      _tutorialStep == LightcoreTutorialStep.armFirstBoss;

  bool get tutorialHighlightsManagersNav =>
      _tutorialStep == LightcoreTutorialStep.openManagers ||
      _tutorialStep == LightcoreTutorialStep.forgeTowerManager ||
      _tutorialStep == LightcoreTutorialStep.assignTowerManager ||
      _tutorialStep == LightcoreTutorialStep.forgeEnemyManager ||
      _tutorialStep == LightcoreTutorialStep.assignEnemyManager;

  bool get tutorialHighlightsMenteesNav =>
      _tutorialStep == LightcoreTutorialStep.openMentees ||
      _tutorialStep == LightcoreTutorialStep.openMentors;

  bool get tutorialHighlightsMentorsNav =>
      _tutorialStep == LightcoreTutorialStep.openMentees ||
      _tutorialStep == LightcoreTutorialStep.openMentors;

  bool get tutorialHighlightsTournamentsNav =>
      _tutorialStep == LightcoreTutorialStep.inspectEnemyBlitz ||
      _tutorialStep == LightcoreTutorialStep.inspectHexGauntlet ||
      _tutorialStep == LightcoreTutorialStep.inspectArenaFlow;

  bool get tutorialHighlightsOverlayBackButton =>
      _tutorialStep == LightcoreTutorialStep.defeatFirstBoss;

  bool get tutorialHighlightsBossBar =>
      _tutorialStep == LightcoreTutorialStep.openEquipment;

  bool get tutorialHighlightsPlayerManagerButton =>
      _tutorialStep == LightcoreTutorialStep.openEquipment ||
      _tutorialStep == LightcoreTutorialStep.upgradeCoreRange ||
      _tutorialStep == LightcoreTutorialStep.setScreenName;

  bool get tutorialHighlightsOverdriveButton =>
      _tutorialStep == LightcoreTutorialStep.holdOverdrive;

  bool get tutorialHighlightsBattleBoss =>
      _tutorialStep == LightcoreTutorialStep.defeatFirstBoss &&
      _tutorialTrackedBossEnemyId != null;

  String? get tutorialHighlightedEnemyId {
    if (_tutorialStep == LightcoreTutorialStep.tapFirstTower &&
        _enemies.isNotEmpty) {
      return _enemies.first.id;
    }
    return tutorialHighlightsBattleBoss ? _tutorialTrackedBossEnemyId : null;
  }

  LightcoreTutorialPulseTarget? get tutorialShowcaseTarget =>
      switch (_tutorialStep) {
        LightcoreTutorialStep.pullFirstWhiteEnemy ||
        LightcoreTutorialStep.pullFirstRedEnemy ||
        LightcoreTutorialStep.openBossPulls =>
          LightcoreTutorialPulseTarget.pullsButton,
        LightcoreTutorialStep.openEquipment ||
        LightcoreTutorialStep.upgradeCoreRange ||
        LightcoreTutorialStep.setScreenName =>
          LightcoreTutorialPulseTarget.playerManagerButton,
        LightcoreTutorialStep.holdOverdrive =>
          LightcoreTutorialPulseTarget.overdriveButton,
        _ => null,
      };

  bool get canShowcaseCurrentTutorialTarget => tutorialShowcaseTarget != null;

  LightcoreTournamentModeId? get tutorialTournamentModeTarget =>
      switch (_tutorialStep) {
        LightcoreTutorialStep.inspectEnemyBlitz =>
          LightcoreTournamentModeId.enemyBlitz,
        LightcoreTutorialStep.inspectHexGauntlet =>
          LightcoreTournamentModeId.hexGauntlet,
        LightcoreTutorialStep.inspectArenaFlow =>
          LightcoreTournamentModeId.arenaFlow,
        _ => null,
      };

  bool tutorialHighlightsTournamentModeCard(LightcoreTournamentModeId mode) =>
      tutorialTournamentModeTarget == mode;

  int tutorialPulseSignalFor(LightcoreTutorialPulseTarget target) =>
      _tutorialPulseTarget == target ? _tutorialPulseSignal : 0;

  double get promotionProgress => promotionReadyTowerCount / slotCount;

  bool get isPromotionReady =>
      builtTowerCount == slotCount && promotionReadyTowerCount == slotCount;

  bool get canUnlockLayer2 =>
      isPromotionReady &&
      activeLayer.promotedParentLayerId == null &&
      !activeLayer.promotedIntoParentSlot &&
      (activeLayerHasParentSlot || activeLayer.tier < maxShellTier);

  bool get _requiresLayer3TrialGate =>
      activeLayer.tier == 2 &&
      !activeLayerHasParentSlot &&
      activeLayer.promotedParentLayerId == null;

  bool get layer3TrialRequired =>
      _requiresLayer3TrialGate && !activeLayer.layer3TrialCleared;

  bool get layer3TrialActive =>
      _requiresLayer3TrialGate && activeLayer.layer3TrialActive;

  bool get layer3TrialCleared =>
      _requiresLayer3TrialGate && activeLayer.layer3TrialCleared;

  String get layer3TrialStatusLabel {
    if (!_requiresLayer3TrialGate) {
      return '';
    }
    if (activeLayer.layer3TrialCleared) {
      return 'Nexus trial cleared';
    }
    if (activeLayer.layer3TrialActive) {
      return 'Nexus trial active';
    }
    return 'Nexus trial required';
  }

  String get promotionActionLabel {
    if (activeLayerHasParentSlot) {
      return 'Promote Into Parent Slot';
    }
    if (layer3TrialActive) {
      return 'Nexus Trial Running';
    }
    if (layer3TrialRequired) {
      return 'Begin Nexus Trial';
    }
    return 'Create $nextShellClassLabel';
  }

  bool get promotionRainbowEligible =>
      _layerCanRollRainbowTower(activeLayer, targetTier: activeLayerTargetTier);

  double get promotionRainbowResultChance => _rainbowChanceForPromotionLayer(
    activeLayer,
    targetTier: activeLayerTargetTier,
  );

  Map<PrototypeAffinity, double> get promotionProjectileAffinityRates {
    final rainbowChance = promotionRainbowResultChance;
    return _promotionAffinityRates(
      _projectileAffinityWeightsForLayer(activeLayer),
      rainbowChance: rainbowChance,
    );
  }

  Map<PrototypeAffinity, double> get promotionPayloadAffinityRates {
    if (activeLayerTargetTier < payloadUnlockLayer) {
      return const <PrototypeAffinity, double>{};
    }
    final rainbowChance = promotionRainbowResultChance;
    return _promotionAffinityRates(
      _payloadAffinityWeightsForLayer(activeLayer),
      rainbowChance: rainbowChance,
    );
  }

  PromotionPreviewSnapshot get promotionPreview {
    final advanced =
        activeLayer.tier > 1 || activeLayer.promotedParentLayerId != null;
    final actionLabel = canUnlockLayer2
        ? promotionActionLabel
        : activeLayerPassiveOnly
        ? 'Archive inspection only'
        : advanced
        ? 'Already advanced'
        : 'Promotion locked';
    final resultLabel = activeLayerHasParentSlot
        ? 'Parent child tower in $activeLayerTargetShellLabel'
        : '$nextShellClassLabel core';
    final anomalyBehaviorLabel = activeLayerHasParentSlot
        ? 'Anomaly deck stays with the child shell archive.'
        : 'Active anomaly deck is copied to the new live shell.';
    return PromotionPreviewSnapshot(
      canPromote: canUnlockLayer2,
      passiveArchive: activeLayerPassiveOnly,
      actionLabel: actionLabel,
      resultLabel: resultLabel,
      currentCoreLabel: '$coreProjectileLabel / $corePayloadLabel',
      projectileMixLabel: _promotionAffinityMixLabel(
        promotionProjectileAffinityRates,
      ),
      payloadMixLabel: _promotionAffinityMixLabel(
        promotionPayloadAffinityRates,
      ),
      anomalyBehaviorLabel: anomalyBehaviorLabel,
      managerBehaviorLabel: _promotionManagerBehaviorLabel(),
    );
  }

  String _promotionAffinityMixLabel(Map<PrototypeAffinity, double> rates) {
    if (rates.isEmpty) {
      return 'none at this tier';
    }
    final entries = rates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(3)
        .map(
          (entry) =>
              '${entry.key.label} ${_formatPromotionPreviewRate(entry.value)}',
        )
        .join(', ');
  }

  String _formatPromotionPreviewRate(double value) {
    final percent = value * 100;
    if ((percent - percent.round()).abs() < 0.05) {
      return '${percent.round()}%';
    }
    return '${percent.toStringAsFixed(1)}%';
  }

  String _promotionManagerBehaviorLabel() {
    final towerManager = _towerCoreManagerForLayer(activeLayer);
    final threatDirector = _enemyCoreManagerForLayer(activeLayer);
    if (towerManager == null && threatDirector == null) {
      return 'No managers assigned';
    }
    final labels = <String>[];
    if (towerManager != null) {
      labels.add('Core Manager follows the new shell');
    }
    if (threatDirector != null) {
      labels.add('Threat Director follows the selected region');
    }
    return labels.join('; ');
  }

  bool get isBattleActive => true;

  int get queuedCorePackets => _ammoQueue.length;

  int get coreQueueOccupancy => min(coreQueueCapacity, _ammoQueue.length);

  List<AmmoPacket> get queuedAmmoPackets =>
      List<AmmoPacket>.unmodifiable(_ammoQueue);

  double get ringProgress => builtTowerCount / slotCount;

  bool get canOpenEnemyTickets => enemyTickets >= enemyTicketCost;

  bool get canOpenBossTickets =>
      bossHuntsUnlocked &&
      fullThreatMapUnlocked &&
      bossTickets >= enemyTicketCost;

  bool get canForgeTowerManager =>
      managersUnlocked && flux >= towerManagerFluxCost;

  bool get canForgeEnemyManager =>
      managersUnlocked && flux >= enemyManagerFluxCost;

  double get managerPowerEffectMultiplier =>
      1 + (managerPowerLevel.clamp(0, maxManagerPowerLevel).toDouble() * 0.01);

  String get managerPowerEffectLabel =>
      '+${((managerPowerEffectMultiplier - 1) * 100).round()}% manager effect';

  int get managerPowerUpgradeCost {
    if (managerPowerLevel >= maxManagerPowerLevel) {
      return 0;
    }
    return managerPowerBaseUpgradeCost +
        (managerPowerLevel * 8) +
        (managerPowerLevel * managerPowerLevel * 2);
  }

  bool get canUpgradeManagerPower =>
      _threatRegionChallenge == null &&
      managerPowerLevel < maxManagerPowerLevel &&
      managerShards >= managerPowerUpgradeCost;

  bool canForgeTowerManagerBatch(int count) =>
      managersUnlocked && count > 0 && flux >= towerManagerFluxCost * count;

  bool canForgeEnemyManagerBatch(int count) =>
      managersUnlocked && count > 0 && flux >= enemyManagerFluxCost * count;

  String get enemyTicketCurrencyName =>
      LightcoreCurrencyLabels.threatScanName(enemyTickets);

  String get enemyTicketLabel => '$enemyTickets $enemyTicketCurrencyName';

  String get echoSeedLabel =>
      '$echoSeeds Echo Seed${echoSeeds == 1 ? '' : 's'}';

  String get bossTicketCurrencyName =>
      LightcoreCurrencyLabels.bossScanName(bossTickets);

  String get bossCoreCurrencyName =>
      threatShards == 1 ? 'Threat Shard' : 'Threat Shards';

  String get bossTicketLabel => '$bossTickets $bossTicketCurrencyName';

  String get bossCoreLabel => '$threatShards $bossCoreCurrencyName';

  int get equipmentInventoryCapacity => maxEquipmentInventorySize;

  int get equippedEquipmentCount => _equippedPlayerItems.values
      .where((instanceId) => instanceId != null)
      .length;

  int get equipmentAutoDismantleCount =>
      _equipmentAutoDismantleCandidates().length;

  bool get canAutoDismantleOldEquipment => equipmentAutoDismantleCount > 0;

  EquipmentBonusProfile get equipmentBonuses {
    var total = EquipmentBonusProfile.zero;
    for (final slot in EquipmentLoadoutSlot.values) {
      final item = equippedPlayerItemForSlot(slot);
      if (item != null) {
        total = total + item.bonuses;
      }
    }
    for (final status in activeEquipmentSets) {
      for (final bonus in status.unlockedBonuses) {
        total = total + bonus.bonuses;
      }
    }
    return total;
  }

  EquipmentBonusProfile get profileMedalBonuses =>
      equippedProfileMedal?.bonuses ?? EquipmentBonusProfile.zero;

  EquipmentBonusProfile get profileLoadoutBonuses =>
      equipmentBonuses + profileMedalBonuses;

  LightcoreAvatarProfile get publicAvatarProfile => LightcoreAvatarProfile(
    guideId: _guideProfile.storageId,
    equipmentPieces: <LightcoreAvatarEquipmentPiece>[
      for (final slot in EquipmentLoadoutSlot.values)
        if (equippedPlayerItemForSlot(slot) case final item?)
          LightcoreAvatarEquipmentPiece(
            slotType: item.slotType,
            setId: item.setId,
            affinity: item.affinity,
            rarity: item.rarity,
          ),
    ],
  );

  int get totalRadianceStatPointsEarned => max(0, overallLevel - 1);

  int get totalRadianceStatPointsSpent => LightcoreRadianceStat.values.fold(
    0,
    (sum, stat) => sum + radianceStatRank(stat),
  );

  int get unspentRadianceStatPoints =>
      max(0, totalRadianceStatPointsEarned - totalRadianceStatPointsSpent);

  bool get hasUnspentRadianceStatPoints => unspentRadianceStatPoints > 0;

  int radianceStatRank(LightcoreRadianceStat stat) =>
      max(0, _radianceStatRanks[stat] ?? 0);

  bool canUpgradeRadianceStat(LightcoreRadianceStat stat) =>
      _threatRegionChallenge == null && unspentRadianceStatPoints > 0;

  bool get canPurchaseRadianceStatReset =>
      totalRadianceStatPointsSpent > 0 &&
      prismShards >= LightcoreController.radianceStatResetPrismShardCost;

  bool upgradeRadianceStat(LightcoreRadianceStat stat) {
    if (!canUpgradeRadianceStat(stat)) {
      return false;
    }
    _radianceStatRanks[stat] = radianceStatRank(stat) + 1;
    _showBanner(
      '${radianceStatLabel(stat)} raised to ${radianceStatRank(stat)}. ${radianceStatEffectLabel(stat)}',
    );
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }

  bool purchaseRadianceStatReset({bool showBanner = true}) {
    if (_threatRegionChallenge != null) {
      return false;
    }
    final spentPoints = totalRadianceStatPointsSpent;
    const cost = LightcoreController.radianceStatResetPrismShardCost;
    if (spentPoints <= 0 || prismShards < cost) {
      return false;
    }

    prismShards -= cost;
    _recordPrismShardSpend(cost);
    _resetRadianceStats();
    if (showBanner) {
      final readyPoints = unspentRadianceStatPoints;
      _showBanner(
        'Global Attributes reset for ${LightcoreCurrencyLabels.prismShardCount(cost)}. '
        '$readyPoints Radiance point${readyPoints == 1 ? '' : 's'} ready.',
      );
    }
    _notifyNow();
    return true;
  }

  String radianceStatLabel(LightcoreRadianceStat stat) => switch (stat) {
    LightcoreRadianceStat.might => 'Might',
    LightcoreRadianceStat.focus => 'Focus',
    LightcoreRadianceStat.tempo => 'Tempo',
    LightcoreRadianceStat.insight => 'Insight',
  };

  String radianceStatShortLabel(LightcoreRadianceStat stat) => switch (stat) {
    LightcoreRadianceStat.might => 'MGT',
    LightcoreRadianceStat.focus => 'FOC',
    LightcoreRadianceStat.tempo => 'TMP',
    LightcoreRadianceStat.insight => 'INS',
  };

  String radianceStatGameplayLabel(LightcoreRadianceStat stat) =>
      switch (stat) {
        LightcoreRadianceStat.might => 'Tower power, core shots, Apex damage',
        LightcoreRadianceStat.focus => 'Range, critical chance, precision',
        LightcoreRadianceStat.tempo => 'Tower charge and core firing cadence',
        LightcoreRadianceStat.insight => 'EXP, Lumens, Flux, scans, drops',
      };

  String radianceStatEffectLabel(LightcoreRadianceStat stat) {
    final rank = radianceStatRank(stat);
    if (rank <= 0) {
      return switch (stat) {
        LightcoreRadianceStat.might =>
          '+0.6% Power per point • +0.25% Apex per point',
        LightcoreRadianceStat.focus =>
          '+0.35% Range per point • +0.10% Crit per point',
        LightcoreRadianceStat.tempo =>
          '+0.5% Charge per point • +0.3% Core fire per point',
        LightcoreRadianceStat.insight =>
          '+0.25% EXP per point • +0.4% Rewards per point',
      };
    }
    return switch (stat) {
      LightcoreRadianceStat.might =>
        'Power +${_formatPositivePercent(_radianceMightPowerBonus)}% • Apex +${_formatPositivePercent(_radianceMightBossDamageBonus)}%',
      LightcoreRadianceStat.focus =>
        'Range +${_formatPositivePercent(_radianceFocusRangeBonus)}% • Crit +${_formatPositivePercent(_radianceFocusCritChanceBonus)}%',
      LightcoreRadianceStat.tempo =>
        'Charge +${_formatPositivePercent(_radianceTempoChargeBonus)}% • Core fire +${_formatPositivePercent(_radianceTempoCoreFireSpeedBonus)}%',
      LightcoreRadianceStat.insight =>
        'EXP +${_formatPositivePercent(_radianceInsightExperienceBonus)}% • Rewards +${_formatPositivePercent(_radianceInsightLumenBonus)}%',
    };
  }

  EquipmentBonusProfile get globalLevelBonuses {
    return EquipmentBonusProfile(
      towerPower: _radianceMightPowerBonus,
      chargeRate: _radianceTempoChargeBonus,
      critChance: _radianceFocusCritChanceBonus,
      critDamage: _radianceMightCritDamageBonus + _radianceFocusCritDamageBonus,
      range: _radianceFocusRangeBonus,
      bossDamage: _radianceMightBossDamageBonus,
      lumenGain: _radianceInsightLumenBonus,
      fluxGain: _radianceInsightFluxBonus,
      ticketGain: _radianceInsightTicketBonus,
      dropRate: _radianceInsightDropBonus,
    );
  }

  String get globalLevelCombatStatsLabel {
    return 'Might ${radianceStatRank(LightcoreRadianceStat.might)} • '
        'Focus ${radianceStatRank(LightcoreRadianceStat.focus)} • '
        'Tempo ${radianceStatRank(LightcoreRadianceStat.tempo)}';
  }

  String get globalLevelEconomyStatsLabel {
    return 'Insight ${radianceStatRank(LightcoreRadianceStat.insight)} • '
        'EXP +${_formatPositivePercent(_radianceInsightExperienceBonus)}% • '
        'Rewards +${_formatPositivePercent(_radianceInsightLumenBonus)}%';
  }

  String get globalLevelStatsSummaryLabel {
    final bonuses = globalLevelBonuses;
    return [
      'Radiance stats',
      if (unspentRadianceStatPoints > 0)
        '$unspentRadianceStatPoints point${unspentRadianceStatPoints == 1 ? '' : 's'} ready',
      'Might ${radianceStatRank(LightcoreRadianceStat.might)}',
      'Focus ${radianceStatRank(LightcoreRadianceStat.focus)}',
      'Tempo ${radianceStatRank(LightcoreRadianceStat.tempo)}',
      'Insight ${radianceStatRank(LightcoreRadianceStat.insight)}',
      'Power +${_formatPositivePercent(bonuses.towerPower)}%',
      'Charge +${_formatPositivePercent(bonuses.chargeRate)}%',
      'Range +${_formatPositivePercent(bonuses.range)}%',
      'Crit +${_formatPositivePercent(bonuses.critChance)}%',
      'Apex +${_formatPositivePercent(bonuses.bossDamage)}%',
      'Rewards +${_formatPositivePercent(bonuses.lumenGain)}%',
    ].join(' • ');
  }

  String get globalLevelPowerStatLabel =>
      '+${_formatPositivePercent(globalLevelBonuses.towerPower)}%';

  String get globalLevelChargeStatLabel =>
      '+${_formatPositivePercent(globalLevelBonuses.chargeRate)}%';

  String get globalLevelRewardStatLabel =>
      '+${_formatPositivePercent(globalLevelBonuses.lumenGain)}%';

  ProfileMedalConfig? get equippedProfileMedal {
    final medalId = _equippedProfileMedalId;
    return medalId == null ? null : MedalLibrary.byId[medalId];
  }

  int get unlockedProfileMedalCount =>
      profileMedals.where((medal) => medal.unlocked).length;

  ProfileMedalStatus? profileMedalStatusById(String medalId) {
    final config = MedalLibrary.byId[medalId];
    return config == null ? null : _profileMedalStatusFor(config);
  }

  TowerPatternBonusProfile get enemyInventoryBonuses =>
      _enemyCards.fold(TowerPatternBonusProfile.zero, (total, card) {
        if (!card.isOwned) {
          return total;
        }
        return total + enemyInventoryEffectForCard(card);
      });

  TowerPatternBonusProfile get bossInventoryBonuses =>
      _bossEnemyCards.fold(TowerPatternBonusProfile.zero, (total, card) {
        if (!card.isOwned) {
          return total;
        }
        return total + bossInventoryEffectForCard(card);
      });

  TowerPatternBonusProfile get regionInventoryBonuses =>
      _threatRegions.fold(TowerPatternBonusProfile.zero, (total, state) {
        final config = ThreatRegionLibrary.byId[state.regionId];
        if (config == null ||
            state.stabilizedLevel < config.stabilizationLayers) {
          return total;
        }
        return total + config.inventoryEffect;
      });

  TowerPatternBonusProfile get towerInventoryBonuses =>
      enemyInventoryBonuses + bossInventoryBonuses + regionInventoryBonuses;

  List<String> get enemyInventoryBonusHighlights =>
      _towerBonusHighlights(enemyInventoryBonuses, maxItems: 4);

  List<String> get bossInventoryBonusHighlights =>
      _towerBonusHighlights(bossInventoryBonuses, maxItems: 4);

  List<String> get regionInventoryBonusHighlights =>
      _towerBonusHighlights(regionInventoryBonuses, maxItems: 4);

  List<String> get towerInventoryBonusHighlights =>
      _towerBonusHighlights(towerInventoryBonuses, maxItems: 5);

  String get enemyInventoryBonusSummaryLabel =>
      _towerBonusSummary(enemyInventoryBonuses);

  String get bossInventoryBonusSummaryLabel =>
      _towerBonusSummary(bossInventoryBonuses);

  String get towerInventoryBonusSummaryLabel =>
      _towerBonusSummary(towerInventoryBonuses);

  int get towerStrength => _computeTowerStrength().round();

  String get towerStrengthLabel => towerStrength.toString();

  String get towerStrengthCompactLabel => _compactNumber(towerStrength);

  int get globalRankingTowerStrength =>
      _computeGlobalRankingTowerStrength().round();

  String get globalRankingTowerStrengthLabel =>
      globalRankingTowerStrength.toString();

  bool get globalTowerStrengthRankNeedsRefresh {
    final self = _socialOverview?.self;
    return self == null ||
        self.towerStrength != globalRankingTowerStrength ||
        self.towerStrengthRank == null;
  }

  int? get serverGlobalTowerStrengthRank {
    final self = _socialOverview?.self;
    if (self == null || self.towerStrength != globalRankingTowerStrength) {
      return null;
    }
    return self.towerStrengthRank;
  }

  int? get globalTowerStrengthRank =>
      serverGlobalTowerStrengthRank ?? projectedGlobalTowerStrengthRank;

  int get globalTowerStrengthRankedPlayers {
    final overview = _socialOverview;
    if (overview == null) {
      return 0;
    }
    return max(
      overview.self.towerStrengthRankedPlayers,
      overview.globalTowerStrengthLeaderboard.length,
    );
  }

  int? get projectedGlobalTowerStrengthRank {
    final overview = _socialOverview;
    final strength = globalRankingTowerStrength;
    if (overview == null || strength <= 0) {
      return null;
    }
    final selfUid = overview.self.uid;
    final strongerCachedPlayers = overview.globalTowerStrengthLeaderboard.where(
      (player) => player.uid != selfUid && player.towerStrength > strength,
    );
    return strongerCachedPlayers.length + 1;
  }

  bool get globalTowerStrengthRankIsProjected =>
      serverGlobalTowerStrengthRank == null &&
      projectedGlobalTowerStrengthRank != null;

  String get globalTowerStrengthRankLabel {
    final rank = globalTowerStrengthRank;
    return rank == null ? '#--' : '#$rank';
  }

  String get globalTowerStrengthRankingTooltip {
    final rank = globalTowerStrengthRank;
    if (rank == null) {
      return 'Global ranking pending. Position is based on TS $globalRankingTowerStrengthLabel.';
    }
    final rankedPlayers = globalTowerStrengthRankedPlayers;
    final totalLabel = rankedPlayers > 0 ? ' of $rankedPlayers' : '';
    final source = globalTowerStrengthRankIsProjected
        ? 'local live preview'
        : 'global sync';
    return 'Global ranking #$rank$totalLabel based on TS $globalRankingTowerStrengthLabel ($source).';
  }

  String get towerStrengthSummaryLabel =>
      'TS $towerStrengthCompactLabel • $towerInventoryBonusSummaryLabel';

  List<TowerPatternAchievement> get activeTowerAchievements =>
      _resolveTowerPatternAchievements(_slots);

  String get towerAchievementHintLabel =>
      'Pattern bonuses activate from the live shell: full rainbow, all one color, blue + green for Storm Chain, or red + orange for Ember Drive.';

  TowerPatternBonusProfile towerPatternBonusesFor(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return TowerPatternBonusProfile.zero;
    }
    var total = TowerPatternBonusProfile.zero;
    for (final achievement in activeTowerAchievements) {
      total = total + achievement.bonuses;
    }
    return total;
  }

  List<EquipmentSetStatus> get activeEquipmentSets {
    final equippedBySet = <String, int>{};
    for (final slot in EquipmentLoadoutSlot.values) {
      final item = equippedPlayerItemForSlot(slot);
      if (item == null) {
        continue;
      }
      equippedBySet.update(item.setId, (count) => count + 1, ifAbsent: () => 1);
    }
    final statuses =
        equippedBySet.entries.map((entry) {
          final config = EquipmentLibrary.byId[entry.key];
          final unlocked = <EquipmentSetBonusConfig>[
            if (config != null)
              for (final bonus in config.setBonuses)
                if (entry.value >= bonus.pieceCount) bonus,
          ];
          return EquipmentSetStatus(
            config: config ?? EquipmentLibrary.all.first,
            equippedCount: entry.value,
            unlockedBonuses: unlocked,
          );
        }).toList()..sort((a, b) {
          final pieceCompare = b.equippedCount.compareTo(a.equippedCount);
          if (pieceCompare != 0) {
            return pieceCompare;
          }
          return a.config.name.compareTo(b.config.name);
        });
    return statuses;
  }

  List<PlayerEquipmentItem> get recentEquipmentDrops {
    final items = _equipmentInventory.toList()
      ..sort((a, b) => b.dropOrder.compareTo(a.dropOrder));
    return items;
  }

  bool get canUpgradeEnemyTargetMax =>
      _threatRegionChallenge == null && enemyTargetMax < maxActiveEnemies;

  bool get isCompositeLayer => activeLayer.tier > 1;

  bool get hasSourceLayer => activeLayer.sourceLayerId != null;

  bool get activeLayerHasParentSlot => activeLayer.parentLayerId != null;

  bool get activeLayerPromotedIntoParentSlot =>
      activeLayer.promotedIntoParentSlot;

  int get activeLayerTargetTier => activeLayer.parentLayerId == null
      ? activeLayer.tier + 1
      : _layerById(activeLayer.parentLayerId!).tier;

  String get activeLayerTargetShellLabel =>
      shellNameForTier(activeLayerTargetTier);

  String get nextShellClassLabel =>
      shellNameForTier(min(activeLayer.tier + 1, maxShellTier));

  String get activeLayerLabel => layerDisplayLabel(activeLayer);

  String get runtimeLayerLabel => layerDisplayLabel(runtimeLayer);

  String layerDisplayLabel(TowerLayerSnapshot layer) {
    final base = shellNameForTier(layer.tier);
    final slotIndex = layer.parentSlotIndex;
    if (layer.parentLayerId != null && slotIndex != null) {
      return '$base • Hex ${slotIndex + 1}';
    }
    return base;
  }

  bool get isViewingRuntimeLayer => _viewLayerId == _runtimeLayerId;

  double get activeLayerPriceMultiplier => _layerPriceMultiplier(activeLayer);

  bool get isChildTowerGrowthLayer => activeLayerHasParentSlot;

  OuterTowerState? get activeChildTowerProjection {
    final parentId = activeLayer.parentLayerId;
    final parentSlotIndex = activeLayer.parentSlotIndex;
    if (parentId == null || parentSlotIndex == null) {
      return null;
    }
    final parent = _layerById(parentId);
    return parent.slots[parentSlotIndex];
  }

  UnmodifiableListView<ChildTowerUpgradeState> get activeChildTowerUpgrades =>
      UnmodifiableListView(activeLayer.childTowerUpgrades);

  int get activeChildTowerUpgradeRanksSpent => activeLayer.childTowerUpgrades
      .fold(0, (sum, upgrade) => sum + upgrade.rank);

  int get activeChildTowerUpgradeRankCap =>
      activeLayer.childTowerUpgrades.length * childTowerUpgradeMaxRank;

  double get activeChildTowerLevelProgress {
    final cap = activeChildTowerUpgradeRankCap;
    if (cap <= 0) {
      return 0;
    }
    return activeChildTowerUpgradeRanksSpent / cap;
  }

  String get activeChildTowerLevelProgressLabel {
    final cap = activeChildTowerUpgradeRankCap;
    if (cap <= 0) {
      return 'No child tower growth here';
    }
    return '$activeChildTowerUpgradeRanksSpent/$cap tuned this level';
  }

  String get activeChildTowerAnchorLabel {
    final parentId = activeLayer.parentLayerId;
    final parentSlotIndex = activeLayer.parentSlotIndex;
    if (parentId == null || parentSlotIndex == null) {
      return activeLayerLabel;
    }
    final parent = _layerById(parentId);
    return 'Hex ${parentSlotIndex + 1} in ${layerDisplayLabel(parent)}';
  }

  int get childLayerTierToCreate => max(1, activeLayer.tier - 1);

  bool get showsLayerOneCoreCreation =>
      activeLayer.tier == 2 && !activeLayerHasParentSlot;

  int get layerOneCoreProjectLimit => 1;

  int get layerOneCoreProjectsInProgress => _layers
      .where(
        (layer) =>
            layer.parentLayerId == activeLayer.id &&
            layer.tier == 1 &&
            !isLayerPassiveOnly(layer),
      )
      .length;

  bool get layerOneCoreProjectLimitReached =>
      showsLayerOneCoreCreation &&
      layerOneCoreProjectsInProgress >= layerOneCoreProjectLimit;

  int? get nextLayerOneCoreSlotIndex {
    if (!showsLayerOneCoreCreation) {
      return null;
    }
    for (var index = 0; index < _slots.length; index++) {
      if (!_slots[index].isBuilt) {
        return index;
      }
    }
    return null;
  }

  bool get canCreateLayerOneCore =>
      showsLayerOneCoreCreation &&
      nextLayerOneCoreSlotIndex != null &&
      !layerOneCoreProjectLimitReached;

  String get layerOneCoreBuildStatusLabel {
    if (!showsLayerOneCoreCreation) {
      return '';
    }
    final projectCount = layerOneCoreProjectsInProgress;
    final projectLimit = layerOneCoreProjectLimit;
    if (nextLayerOneCoreSlotIndex == null) {
      return 'All Layer 1 set slots are occupied.';
    }
    if (projectCount >= projectLimit) {
      return 'Layer 1 set build cap reached: $projectCount/$projectLimit active.';
    }
    return 'Layer 1 sets building: $projectCount/$projectLimit active.';
  }

  bool get _layerOneCoreCreationCapApplies =>
      showsLayerOneCoreCreation && childLayerTierToCreate == 1;

  bool canCreateChildLayerAt(int slotIndex) =>
      childLayerCreationBlockedLabelForSlot(slotIndex) == null;

  String? childLayerCreationBlockedLabelForSlot(int slotIndex) {
    if (!isCompositeLayer || slotIndex < 0 || slotIndex >= _slots.length) {
      return 'No lower shell can be created here.';
    }
    if (activeLayerPassiveOnly) {
      return 'This static archive can only be inspected.';
    }
    if (_slots[slotIndex].isBuilt) {
      return 'This hex already has a core or tower.';
    }
    if (_layerOneCoreCreationCapApplies && layerOneCoreProjectLimitReached) {
      return 'Finish the active Layer 1 set before starting another.';
    }
    return null;
  }

  String childCoreChoiceLabel(PrototypeAffinity affinity, {int? childTier}) {
    final tier = childTier ?? childLayerTierToCreate;
    final projectile = forgedProjectilesForAffinity(
      affinity,
      targetTier: tier,
    ).first;
    final payload = forgedPayloadsForAffinity(affinity, targetTier: tier).first;
    return tier < payloadUnlockLayer
        ? '${affinity.label} • ${projectile.label}'
        : '${affinity.label} • ${projectile.label} / ${payload.label}';
  }

  int get enemyTargetUpgradeCost => canUpgradeEnemyTargetMax
      ? _enemyTargetUpgradeCost(upgradeLevel: _enemyTargetUpgradeLevel)
      : 0;

  String get enemyTargetUpgradeCostLabel =>
      _compactNumber(enemyTargetUpgradeCost);

  String get enemySpawnCadenceLabel => '${_spawnInterval.toStringAsFixed(2)}s';

  double get activeThreatRewardMultiplier {
    final deck = activeEnemyDeck;
    if (deck.isEmpty) {
      return 1;
    }
    return deck.fold(
          0.0,
          (sum, card) => sum + _threatRewardMultiplierForCard(card),
        ) /
        deck.length;
  }

  double get activeThreatStabilityMultiplier {
    final deck = activeEnemyDeck;
    if (deck.isEmpty) {
      return 1;
    }
    return deck.fold(
          0.0,
          (sum, card) => sum + _threatStabilityMultiplierForCard(card),
        ) /
        deck.length;
  }

  double get activeEffectiveGainMultiplier =>
      activeThreatRewardMultiplier * outputEfficiencyMultiplier;

  String get activeThreatRewardLabel =>
      'x${activeThreatRewardMultiplier.toStringAsFixed(2)}';

  String get activeEffectiveGainLabel =>
      'x${activeEffectiveGainMultiplier.toStringAsFixed(2)}';

  ThreatScanBundleSnapshot get activeThreatScanBundle {
    final deck = activeEnemyDeck;
    final primaryAffinity = _dominantThreatAffinity(deck);
    final directorNames = _activeThreatDirectorNames(deck);
    final threatReward = activeThreatRewardMultiplier;
    final stabilityPressure = activeThreatStabilityMultiplier;
    final outputEfficiency = outputEfficiencyMultiplier;
    return ThreatScanBundleSnapshot(
      id: _threatScanBundleId(deck),
      name: _threatScanBundleName(deck, primaryAffinity),
      summary: _threatScanBundleSummary(
        deck,
        primaryAffinity: primaryAffinity,
        directorNames: directorNames,
        targetCount: enemyTargetCount,
      ),
      primaryAffinity: primaryAffinity,
      cardNames: List<String>.unmodifiable(
        deck.map((card) => card.config.name),
      ),
      directorNames: directorNames,
      riskLabel: _threatScanRiskLabel(
        hasDeck: deck.isNotEmpty,
        threatReward: threatReward,
        stabilityPressure: stabilityPressure,
        outputEfficiency: outputEfficiency,
        targetCount: enemyTargetCount,
        targetMax: enemyTargetMax,
      ),
      counterplayLabel: _threatCounterplayLabel(primaryAffinity),
      activeCardCount: deck.length,
      liveEnemyCount: enemyCount,
      targetCount: enemyTargetCount,
      targetMax: enemyTargetMax,
      threatRewardMultiplier: threatReward,
      stabilityPressureMultiplier: stabilityPressure,
      outputEfficiencyMultiplier: outputEfficiency,
      effectiveGainMultiplier: threatReward * outputEfficiency,
    );
  }

  double get passiveLumenPerSecond =>
      passiveLumenBasePerSecond *
      lumenHarvestEfficiency *
      _economyBalanceMultiplier('passiveLumens');

  double get passiveLumenBasePerSecond => _layers
      .where((layer) => layer.id != runtimeLayer.id)
      .fold(0.0, (sum, layer) => sum + _passiveLumenBaseForLayer(layer));

  double get lumenHarvestEfficiency => outputEfficiencyMultiplier;

  bool get hasLumenHarvestPressure => _core.coreStability < 99.5;

  String get lumenHarvestEfficiencyLabel => outputEfficiencyLabel;

  String get lumenHarvestRecoveryLabel {
    if (!hasLumenHarvestPressure) {
      return 'Stable';
    }
    final remainingSeconds =
        ((_maxCoreStability - _core.coreStability) /
                max(0.001, coreStabilityRecoveryPerSecond))
            .ceil();
    final recovery = Duration(seconds: max(1, remainingSeconds));
    if (recovery.inHours >= 1) {
      return '${recovery.inHours}h ${recovery.inMinutes.remainder(60)}m';
    }
    return '${max(1, recovery.inMinutes)}m';
  }

  double get coreStabilityRecoveryPerSecond {
    final built = _slots.where(_slotCountsTowardRing).toList();
    final greenRecovery =
        built
            .where((slot) => _slotAffinity(slot) == PrototypeAffinity.verdant)
            .length *
        0.06;
    final managerRecovery = _managedTowerCountForLayer(activeLayer) * 0.025;
    final coreRecovery = max(0, _core.level - 1) * 0.02;
    return _baseCoreStabilityRecoveryPerSecond *
            (1 + greenRecovery + coreRecovery) +
        managerRecovery;
  }

  double get offlineKillsPerHour {
    return threatRegionOfflineKillsPerHour *
        _economyBalanceMultiplier('offlineKills');
  }
}
