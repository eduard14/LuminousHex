part of '../lightcore_controller.dart';

extension LightcoreControllerBattleEnemyActions on LightcoreController {
  List<PackPullResult> openEnemyTickets(int count) {
    if (count <= 0 || enemyTickets < count) {
      return const <PackPullResult>[];
    }

    final previousSummoningLevel = summoningLevel;
    enemyTickets -= count;
    final pulls = <PackPullResult>[];
    for (var draw = 0; draw < count; draw++) {
      final scriptedConfig = _scriptedEnemyPullForTutorial();
      final config =
          scriptedConfig ??
          (() {
            final rarity = _rollPackRarity();
            final pool = EnemyLibrary.byRarity[rarity]!;
            return pool[_packRandom.nextInt(pool.length)];
          })();
      enemyPullCount += 1;
      final cardIndex = _enemyCards.indexWhere(
        (card) => card.config.id == config.id,
      );
      final current = _enemyCards[cardIndex];
      final wasNew = !current.unlocked;
      _enemyCards[cardIndex] = current.copyWith(
        unlocked: true,
        copies: current.copies + 1,
      );
      pulls.add(PackPullResult(config: config, isNew: wasNew));
      if (wasNew && _activeEnemyCardIds.length < enemyDeckLimit) {
        _activeEnemyCardIds.add(config.id);
      }
    }

    _grantSummoningLevelTicketRewards(
      previousLevel: previousSummoningLevel,
      currentLevel: summoningLevel,
    );
    _advanceBattlePass(BattlePassType.enemyPulls, count);
    _lastEnemyPackPulls = pulls;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return List<PackPullResult>.unmodifiable(pulls);
  }

  List<PackPullResult> tutorialOpenEnemyTickets(int count) {
    if ((_tutorialStep == LightcoreTutorialStep.pullFirstWhiteEnemy ||
            _tutorialStep == LightcoreTutorialStep.pullFirstRedEnemy) &&
        count != 1) {
      _showBanner('Resolve exactly 1 threat scan for this lesson.');
      _notifyNow();
      return const <PackPullResult>[];
    }
    return openEnemyTickets(count);
  }

  List<PackPullResult> openBossTickets(int count) {
    if (!bossHuntsUnlocked || count <= 0 || bossTickets < count) {
      return const <PackPullResult>[];
    }

    final previousSummoningLevel = bossSummoningLevel;
    bossTickets -= count;
    final pulls = <PackPullResult>[];
    for (var draw = 0; draw < count; draw++) {
      final scriptedConfig = _scriptedBossPull();
      final config =
          scriptedConfig ??
          (() {
            final rarity = _rollBossPackRarity();
            final pool = BossEnemyLibrary.byRarity[rarity]!;
            return pool[_packRandom.nextInt(pool.length)];
          })();
      bossPullCount += 1;
      final cardIndex = _bossEnemyCards.indexWhere(
        (card) => card.config.id == config.id,
      );
      final current = _bossEnemyCards[cardIndex];
      final wasNew = !current.unlocked;
      _bossEnemyCards[cardIndex] = current.copyWith(
        unlocked: true,
        copies: current.copies + 1,
      );
      pulls.add(PackPullResult(config: config, isNew: wasNew));
    }

    _grantBossSummoningLevelTicketRewards(
      previousLevel: previousSummoningLevel,
      currentLevel: bossSummoningLevel,
    );
    _lastBossPackPulls = pulls;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return List<PackPullResult>.unmodifiable(pulls);
  }

  List<PackPullResult> tutorialOpenBossTickets(int count) {
    if (_tutorialStep == LightcoreTutorialStep.openBossPulls && count != 1) {
      _showBanner(
        'Resolve exactly 1 apex scan so the first Apex lesson stays readable.',
      );
      _notifyNow();
      return const <PackPullResult>[];
    }
    return openBossTickets(count);
  }

  bool tutorialArmBossEnemyCard(String cardId) {
    if (_tutorialStep == LightcoreTutorialStep.armFirstBoss &&
        cardId != BossEnemyLibrary.starterWhiteWarden.id) {
      _showBanner(
        'Arm White Warden first so the tutorial can script the opening Apex win.',
      );
      _notifyNow();
      return false;
    }
    final before = activeBossEnemyCard?.config.id;
    setActiveBossEnemyCard(cardId);
    return activeBossEnemyCard?.config.id != before;
  }

  void markTutorialPlayerManagerOpened() {
    if (_tutorialStep != LightcoreTutorialStep.openEquipment) {
      return;
    }
    _tutorialFirstEquipmentOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialTowerMatrixOpened() {
    if (_tutorialTowerMatrixOpened) {
      return;
    }
    _tutorialTowerMatrixOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialFirstTowerStatsOpened() {
    if (_tutorialFirstTowerStatsOpened) {
      return;
    }
    _tutorialFirstTowerStatsOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialStabilityPanelOpened() {
    if (_tutorialStabilityPanelOpened) {
      return;
    }
    _tutorialStabilityPanelOpened = true;
    _ensureStarterCoreManagerForTutorial();
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialStoreOpened() {
    if (_tutorialStoreOpened) {
      return;
    }
    _tutorialStoreOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialManagersOpened() {
    if (!managersUnlocked || _tutorialFirstManagersOpened) {
      return;
    }
    _tutorialFirstManagersOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialFriendsOpened() {
    if (_tutorialFriendsOpened) {
      return;
    }
    _tutorialFriendsOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialMenteesOpened() {
    markTutorialMentorshipOpened();
  }

  void markTutorialMentorshipOpened() {
    if (!mentorshipUnlocked) {
      return;
    }
    if (_tutorialMenteesOpened && _tutorialMentorsOpened) {
      return;
    }
    _tutorialMenteesOpened = true;
    _tutorialMentorsOpened = true;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void markTutorialMentorsOpened() {
    markTutorialMentorshipOpened();
  }

  void markTutorialTournamentModeReviewed(LightcoreTournamentModeId mode) {
    final targetMode = tutorialTournamentModeTarget;
    if (targetMode != mode || _reviewedTournamentTutorialModes.contains(mode)) {
      return;
    }
    _reviewedTournamentTutorialModes.add(mode);
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void debugAddEnemyTickets(int count) {
    if (!kDebugMode || count <= 0) {
      return;
    }
    enemyTickets += count;
    _showBanner('Debug: ${LightcoreCurrencyLabels.rewardThreatScans(count)}.');
    _notifyNow();
  }

  void debugSetSummoningLevel(int level) {
    if (!kDebugMode) {
      return;
    }
    final normalizedLevel = min(maxSummoningLevel, max(1, level));
    enemyPullCount = summoningLevelPullTargetForLevel(normalizedLevel);
    _showBanner(
      'Debug: Summoning Level $summoningLevel • Peak ${highestAvailableEnemyPullRarity.label} anomaly.',
    );
    _notifyNow();
  }

  void selectEnemyCard(String cardId) {
    final card = enemyCardById(cardId);
    if (card == null || !card.isOwned) {
      return;
    }
    selectedEnemyCardId = cardId;
    if (_tutorialStep == LightcoreTutorialStep.setFirstEnemyTarget &&
        cardId == EnemyLibrary.basicRed.id) {
      _tutorialFirstEnemyTargetSet = true;
      _syncTutorialStep(showBanner: false);
    }
    _notifyNow();
  }

  void toggleEnemyCardSelection(String cardId) {
    final card = enemyCardById(cardId);
    if (card == null || !card.isOwned) {
      return;
    }

    if (_activeEnemyCardIds.contains(cardId)) {
      if (_activeEnemyCardIds.length == 1) {
        _showBanner('Keep at least one anomaly card active in the deck.');
        _notifyNow();
        return;
      }
      _activeEnemyCardIds.remove(cardId);
      if (selectedEnemyCardId == cardId) {
        selectedEnemyCardId = _activeEnemyCardIds.isEmpty
            ? null
            : _activeEnemyCardIds.first;
      }
      _showBanner('${card.config.name} removed from the active anomaly deck.');
      _notifyNow();
      return;
    }

    if (_activeEnemyCardIds.length >= enemyDeckLimit) {
      _showBanner('Anomaly deck is full. Remove a card before adding another.');
      _notifyNow();
      return;
    }

    _activeEnemyCardIds.add(cardId);
    selectedEnemyCardId ??= cardId;
    _showBanner('${card.config.name} added to the active anomaly deck.');
    _notifyNow();
  }

  ThreatAssignmentPresetState? threatAssignmentPresetById(String presetId) {
    final match = activeLayer.threatAssignmentPresets.where(
      (preset) => preset.id == presetId,
    );
    return match.isEmpty ? null : match.first;
  }

  ThreatAssignmentGroupStatsSnapshot get activeThreatAssignmentGroupStats =>
      _threatAssignmentGroupStatsForCards(activeEnemyDeck);

  ThreatAssignmentGroupStatsSnapshot threatAssignmentGroupStatsForPreset(
    ThreatAssignmentPresetState preset,
  ) {
    final seen = <String>{};
    final cards = <EnemyCardState>[];
    var ignoredAnomalyCount = 0;
    for (final cardId in preset.enemyCardIds) {
      final unique = seen.add(cardId);
      final card = unique ? enemyCardById(cardId) : null;
      if (!unique || card == null || !card.isOwned) {
        ignoredAnomalyCount += 1;
        continue;
      }
      if (cards.length >= enemyDeckLimit) {
        ignoredAnomalyCount += 1;
        continue;
      }
      cards.add(card);
    }
    return _threatAssignmentGroupStatsForCards(
      cards,
      ignoredAnomalyCount: ignoredAnomalyCount,
    );
  }

  String? createThreatAssignmentPreset({String? name}) {
    final presetName = _normalizeThreatAssignmentPresetName(name);
    final sequence = activeLayer.threatAssignmentPresets.length + 1;
    final resolvedName = presetName ?? 'Preset $sequence';
    final preset = ThreatAssignmentPresetState(
      id: 'threat_preset_${activeLayer.id}_${DateTime.now().microsecondsSinceEpoch}',
      name: resolvedName,
      enemyCardIds: _currentThreatPresetEnemyIds(),
      bossCardId: _activeBossEnemyCardId,
    );
    activeLayer.threatAssignmentPresets = <ThreatAssignmentPresetState>[
      ...activeLayer.threatAssignmentPresets,
      preset,
    ];
    activeLayer.selectedThreatAssignmentPresetId = preset.id;
    _showBanner('$resolvedName saved for ${activeLayer.label}.');
    _notifyNow();
    return preset.id;
  }

  bool updateThreatAssignmentPreset(String presetId) {
    final index = activeLayer.threatAssignmentPresets.indexWhere(
      (preset) => preset.id == presetId,
    );
    if (index == -1) {
      return false;
    }
    final presets = activeLayer.threatAssignmentPresets.toList(growable: false);
    final current = presets[index];
    presets[index] = current.copyWith(
      enemyCardIds: _currentThreatPresetEnemyIds(),
      bossCardId: _activeBossEnemyCardId,
      clearBossCard: _activeBossEnemyCardId == null,
    );
    activeLayer.threatAssignmentPresets = presets;
    activeLayer.selectedThreatAssignmentPresetId = presetId;
    _showBanner('${current.name} updated for ${activeLayer.label}.');
    _notifyNow();
    return true;
  }

  bool renameThreatAssignmentPreset(String presetId, String name) {
    final normalizedName = _normalizeThreatAssignmentPresetName(name);
    if (normalizedName == null) {
      return false;
    }
    final index = activeLayer.threatAssignmentPresets.indexWhere(
      (preset) => preset.id == presetId,
    );
    if (index == -1) {
      return false;
    }
    final presets = activeLayer.threatAssignmentPresets.toList(growable: false);
    presets[index] = presets[index].copyWith(name: normalizedName);
    activeLayer.threatAssignmentPresets = presets;
    activeLayer.selectedThreatAssignmentPresetId = presetId;
    _showBanner('Preset renamed to $normalizedName.');
    _notifyNow();
    return true;
  }

  bool selectThreatAssignmentPreset(String presetId) {
    final exists = activeLayer.threatAssignmentPresets.any(
      (preset) => preset.id == presetId,
    );
    if (!exists) {
      return false;
    }
    activeLayer.selectedThreatAssignmentPresetId = presetId;
    _notifyNow();
    return true;
  }

  bool applyThreatAssignmentPreset(String presetId) {
    final preset = threatAssignmentPresetById(presetId);
    if (preset == null) {
      return false;
    }
    final nextEnemyIds = preset.enemyCardIds
        .where((cardId) => enemyCardById(cardId)?.isOwned ?? false)
        .take(enemyDeckLimit)
        .toList(growable: false);
    if (nextEnemyIds.isEmpty) {
      _showBanner('${preset.name} has no owned anomalies to apply.');
      _notifyNow();
      return false;
    }

    _activeEnemyCardIds
      ..clear()
      ..addAll(nextEnemyIds);
    activeLayer.activeEnemyCardIds = _activeEnemyCardIds;
    selectedEnemyCardId = _activeEnemyCardIds.first;

    final bossId = preset.bossCardId;
    _activeBossEnemyCardId =
        bossId != null && (bossEnemyCardById(bossId)?.isOwned ?? false)
        ? bossId
        : null;
    activeLayer.activeBossEnemyCardId = _activeBossEnemyCardId;
    activeLayer.selectedThreatAssignmentPresetId = presetId;
    _showBanner('${preset.name} applied to ${activeLayer.label}.');
    _notifyNow();
    return true;
  }

  List<String> _currentThreatPresetEnemyIds() {
    final seen = <String>{};
    return _activeEnemyCardIds
        .where((cardId) => enemyCardById(cardId)?.isOwned ?? false)
        .where(seen.add)
        .take(enemyDeckLimit)
        .toList(growable: false);
  }

  ThreatAssignmentGroupStatsSnapshot _threatAssignmentGroupStatsForCards(
    List<EnemyCardState> cards, {
    int ignoredAnomalyCount = 0,
  }) {
    final spawnIntervalSeconds = _spawnIntervalForDeck(cards);
    final spawnsPerMinute =
        cards.isEmpty ||
            spawnIntervalSeconds <= 0 ||
            !spawnIntervalSeconds.isFinite
        ? 0.0
        : 60 / spawnIntervalSeconds;
    if (cards.isEmpty) {
      return ThreatAssignmentGroupStatsSnapshot(
        anomalyCount: 0,
        ignoredAnomalyCount: ignoredAnomalyCount,
        spawnIntervalSeconds: spawnIntervalSeconds,
        spawnsPerMinute: spawnsPerMinute,
        clearsPerMinute: 0,
        averageLumensPerClear: 0,
        averageExperiencePerClear: 0,
        lumensPerMinute: 0,
        experiencePerMinute: 0,
      );
    }

    final averageLumensPerClear =
        cards.fold<double>(
          0,
          (sum, card) => sum + _projectedLumenRewardForCard(card),
        ) /
        cards.length;
    final averageExperiencePerClear =
        cards.fold<double>(
          0,
          (sum, card) => sum + _projectedExperienceRewardForCard(card),
        ) /
        cards.length;
    final clearSeconds = cards
        .map(enemyCardPreviewClearSeconds)
        .where((value) => value.isFinite && value > 0)
        .toList(growable: false);
    final averageClearSeconds = clearSeconds.length == cards.length
        ? clearSeconds.fold<double>(0, (sum, value) => sum + value) /
              clearSeconds.length
        : double.infinity;
    final dpsLimitedClearsPerMinute = averageClearSeconds.isFinite
        ? (60 * max(1, enemyTargetCount)) / averageClearSeconds
        : 0.0;
    final clearsPerMinute = min(spawnsPerMinute, dpsLimitedClearsPerMinute);

    return ThreatAssignmentGroupStatsSnapshot(
      anomalyCount: cards.length,
      ignoredAnomalyCount: ignoredAnomalyCount,
      spawnIntervalSeconds: spawnIntervalSeconds,
      spawnsPerMinute: spawnsPerMinute,
      clearsPerMinute: clearsPerMinute,
      averageLumensPerClear: averageLumensPerClear,
      averageExperiencePerClear: averageExperiencePerClear,
      lumensPerMinute: averageLumensPerClear * clearsPerMinute,
      experiencePerMinute: averageExperiencePerClear * clearsPerMinute,
    );
  }

  double _projectedLumenRewardForCard(EnemyCardState card) {
    return max(
      1,
      (enemyCardPreviewReward(card) *
              outputEfficiencyMultiplier *
              lumenTierMultiplier *
              friendAllianceRewardMultiplier *
              _gearLumenMultiplier *
              _economyBalanceMultiplier('lumenReward'))
          .round(),
    ).toDouble();
  }

  double _projectedExperienceRewardForCard(EnemyCardState card) {
    final baseExperience = enemyCardPreviewExperience(card);
    final scaledExperience =
        (baseExperience *
                sharedRelayExperienceMultiplier *
                effectiveExperienceEfficiencyMultiplier)
            .round();
    return _boostedExperienceReward(
      max(baseExperience, scaledExperience),
    ).toDouble();
  }

  String? _normalizeThreatAssignmentPresetName(String? name) {
    final normalized = name?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized.length <= 28 ? normalized : normalized.substring(0, 28);
  }

  void _normalizeThreatAssignmentPresetSelection(TowerLayerSnapshot layer) {
    if (layer.threatAssignmentPresets.isEmpty) {
      layer.selectedThreatAssignmentPresetId = null;
      return;
    }
    final selectedId = layer.selectedThreatAssignmentPresetId;
    final selectedExists =
        selectedId != null &&
        layer.threatAssignmentPresets.any((preset) => preset.id == selectedId);
    if (!selectedExists) {
      layer.selectedThreatAssignmentPresetId =
          layer.threatAssignmentPresets.first.id;
    }
  }

  void setActiveBossEnemyCard(String cardId) {
    if (!bossHuntsUnlocked &&
        cardId != BossEnemyLibrary.starterWhiteWarden.id) {
      _showBanner('Changing Apex Anomalies unlocks in the Prism Shell.');
      _notifyNow();
      return;
    }
    final card = bossEnemyCardById(cardId);
    if (card == null || !card.isOwned || _activeBossEnemyCardId == cardId) {
      return;
    }

    _activeBossEnemyCardId = cardId;
    activeLayer.activeBossEnemyCardId = cardId;
    if (_tutorialStep == LightcoreTutorialStep.armFirstBoss) {
      _tutorialIntroBossPending = true;
      _tutorialTrackedBossEnemyId = null;
      if (activeLayer.normalKillsSinceBoss >= bossSpawnKillRequirement) {
        activeLayer.bossReady = true;
        _spawnTimer = min(_spawnTimer, 0.01);
      }
      _syncTutorialStep(showBanner: false);
    }
    _showBanner('${card.config.name} armed as the next Apex spawn.');
    _notifyNow();
  }

  bool setEnemyTargetCount(int value) {
    final nextValue = _normalizeEnemyTargetCount(value);
    if (nextValue == _enemyTargetCount) {
      return false;
    }

    _enemyTargetCount = nextValue;
    if (_tutorialStep == LightcoreTutorialStep.adjustEnemyCount &&
        nextValue > enemyTargetFloor) {
      _tutorialEnemyCountAdjusted = true;
      _syncTutorialStep(showBanner: false);
    }
    _notifyNow();
    return true;
  }

  bool upgradeEnemyTargetMax() {
    if (!canUpgradeEnemyTargetMax) {
      return false;
    }

    final cost = enemyTargetUpgradeCost;
    if (lumens < cost) {
      return false;
    }

    final previousMax = enemyTargetMax;
    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    _enemyTargetUpgradeLevel = _normalizeEnemyTargetUpgradeLevel(
      _enemyTargetUpgradeLevel + 1,
    );
    final nextMax = enemyTargetMax;
    if (_enemyTargetCount == previousMax) {
      _enemyTargetCount = nextMax;
    } else {
      _enemyTargetCount = _normalizeEnemyTargetCount(_enemyTargetCount);
    }
    _showBanner('Swarm ceiling raised to $nextMax anomalies.');
    _notifyNow();
    return true;
  }

  bool upgradeManagerPower() {
    if (managerPowerLevel >= maxManagerPowerLevel) {
      _showBanner('Manager Power is already at Lv $maxManagerPowerLevel.');
      _notifyNow();
      return false;
    }
    final cost = managerPowerUpgradeCost;
    if (managerShards < cost) {
      _showBanner(
        'Need ${LightcoreCurrencyLabels.managerShardCount(cost)} to upgrade Manager Power.',
      );
      _notifyNow();
      return false;
    }

    managerShards -= cost;
    managerPowerLevel += 1;
    _showBanner(
      'Manager Power Lv $managerPowerLevel online: $managerPowerEffectLabel.',
    );
    _notifyNow();
    return true;
  }

  bool forgeTowerManager() => forgeTowerManagerBatch(1);

  bool forgeTowerManagerBatch(int count) {
    final packCount = max(1, count);
    if (!managersUnlocked) {
      _showBanner(
        'Managers unlock at Core Lv $managerCoreLevelRequirement or Account Radiance Lv $managerUnlockLevel.',
      );
      _notifyNow();
      return false;
    }
    final cost = towerManagerFluxCost * packCount;
    if (flux < cost) {
      return false;
    }

    flux -= cost;
    _recordFluxSpend(cost);
    final managers = <InventoryCard>[];
    for (var index = 0; index < packCount; index += 1) {
      managers.add(
        _generateTowerManager(
          forgeCost: towerManagerFluxCost,
          forcedRarity: _rollManagerRarityWithFloor(
            _bulkForgeRarityFloor(index, packCount),
          ),
        ),
      );
    }
    _cards.addAll(managers);
    final bonusShards = _managerBulkForgeBonusShards(packCount);
    managerShards += bonusShards;
    _totalManagersForged += packCount;
    towerManagerPullCount += packCount;
    _advanceBattlePass(BattlePassType.towerManagerPulls, packCount);
    _syncTutorialStep(showBanner: false);
    _showBanner(_managerForgeBanner('Core Manager', managers, bonusShards));
    _notifyNow();
    return true;
  }

  bool forgeEnemyManager() => forgeEnemyManagerBatch(1);

  bool forgeEnemyManagerBatch(int count) {
    final packCount = max(1, count);
    if (!managersUnlocked) {
      _showBanner(
        'Managers unlock at Core Lv $managerCoreLevelRequirement or Account Radiance Lv $managerUnlockLevel.',
      );
      _notifyNow();
      return false;
    }
    final cost = enemyManagerFluxCost * packCount;
    if (flux < cost) {
      return false;
    }

    flux -= cost;
    _recordFluxSpend(cost);
    final managers = <EnemyManagerState>[];
    for (var index = 0; index < packCount; index += 1) {
      managers.add(
        _generateEnemyManager(
          forgeCost: enemyManagerFluxCost,
          forcedRarity: _rollManagerRarityWithFloor(
            _bulkForgeRarityFloor(index, packCount),
          ),
        ),
      );
    }
    _enemyManagers.addAll(managers);
    final bonusShards = _managerBulkForgeBonusShards(packCount);
    managerShards += bonusShards;
    _totalManagersForged += packCount;
    enemyManagerPullCount += packCount;
    _advanceBattlePass(BattlePassType.enemyManagerPulls, packCount);
    _syncTutorialStep(showBanner: false);
    _showBanner(_managerForgeBanner('Threat Director', managers, bonusShards));
    _notifyNow();
    return true;
  }

  ManagerRarity? _bulkForgeRarityFloor(int index, int count) {
    if (index != count - 1) {
      return null;
    }
    if (count >= 10) {
      return ManagerRarity.rare;
    }
    if (count >= 5) {
      return ManagerRarity.uncommon;
    }
    return null;
  }

  ManagerRarity? _rollManagerRarityWithFloor(ManagerRarity? floor) {
    if (floor == null) {
      return null;
    }
    final rolled = _rollManagerRarity();
    return rolled.score >= floor.score ? rolled : floor;
  }

  int _managerBulkForgeBonusShards(int count) {
    if (count >= 10) {
      return managerBulkForgeTenBonusShards;
    }
    if (count >= 5) {
      return managerBulkForgeFiveBonusShards;
    }
    return 0;
  }

  String _managerForgeBanner(
    String label,
    Iterable<dynamic> managers,
    int bonusShards,
  ) {
    final forged = managers.toList(growable: false);
    final highest = forged
        .map((manager) => manager.rarity as ManagerRarity)
        .reduce((a, b) => a.score >= b.score ? a : b);
    final bonus = bonusShards > 0
        ? ' ${LightcoreCurrencyLabels.rewardManagerShards(bonusShards)} bulk bonus.'
        : '';
    if (forged.length == 1) {
      return '${forged.first.name} forged in the $label foundry.$bonus';
    }
    return '${forged.length} $label rolls forged. Best roll: ${highest.label}.$bonus';
  }

  bool dismantleTowerManager(String managerId) {
    final index = _cards.indexWhere((card) => card.instanceId == managerId);
    if (index == -1) {
      return false;
    }

    final manager = _cards[index];
    for (final layer in _layers) {
      for (var slotIndex = 0; slotIndex < layer.slots.length; slotIndex++) {
        final slot = layer.slots[slotIndex];
        if (slot.equippedCardInstanceId == manager.instanceId) {
          layer.slots[slotIndex] = slot.copyWith(
            automationCooldownRemaining: 0,
            clearEquippedCard: true,
          );
        }
      }
    }
    flux += max(1, manager.dismantleFlux);
    _cards.removeAt(index);
    _showBanner(
      '${manager.name} dismantled for ${LightcoreCurrencyLabels.fluxCount(manager.dismantleFlux)}.',
    );
    _notifyNow();
    return true;
  }

  bool dismantleEnemyManager(String managerId) {
    final index = _enemyManagers.indexWhere(
      (manager) => manager.instanceId == managerId,
    );
    if (index == -1) {
      return false;
    }

    final manager = _enemyManagers[index];
    flux += max(1, manager.dismantleFlux);
    _enemyManagers.removeAt(index);
    _showBanner(
      '${manager.name} dismantled for ${LightcoreCurrencyLabels.fluxCount(manager.dismantleFlux)}.',
    );
    _notifyNow();
    return true;
  }

  void assignEnemyManagerToSelected(String managerId) {
    assignEnemyManagerToCore(managerId);
  }

  void assignEnemyManagerToCore(String managerId) {
    if (!managerAssignmentUnlocked) {
      _showBanner(
        'Manager assignment unlocks at Core Lv $managerCoreLevelRequirement or Account Radiance Lv $managerUnlockLevel.',
      );
      _notifyNow();
      return;
    }
    final managerIndex = _enemyManagers.indexWhere(
      (manager) => manager.instanceId == managerId,
    );
    if (managerIndex == -1) {
      return;
    }

    for (var index = 0; index < _enemyManagers.length; index++) {
      final manager = _enemyManagers[index];
      if (index != managerIndex && manager.assignedLayerId == activeLayer.id) {
        _enemyManagers[index] = manager.copyWith(clearAssignment: true);
      }
    }

    _enemyManagers[managerIndex] = _enemyManagers[managerIndex].copyWith(
      assignedLayerId: activeLayer.id,
      clearAssignedEnemyCard: true,
    );
    if (_tutorialStep == LightcoreTutorialStep.assignEnemyManager) {
      _tutorialEnemyManagerAssigned = true;
      _syncTutorialStep(showBanner: false);
    }
    _showBanner(
      '${_enemyManagers[managerIndex].name} assigned to the Tower Core for all enemies.',
    );
    _notifyNow();
  }

  void assignEnemyManagerToCard(String managerId, String enemyCardId) {
    final enemyCard = enemyCardById(enemyCardId);
    if (enemyCard != null && enemyCard.isOwned) {
      selectedEnemyCardId = enemyCardId;
    }
    assignEnemyManagerToCore(managerId);
  }

  void clearEnemyCoreManager() {
    final manager = _enemyCoreManagerForLayer(activeLayer);
    if (manager == null) {
      return;
    }
    for (var index = 0; index < _enemyManagers.length; index++) {
      final candidate = _enemyManagers[index];
      if (candidate.assignedLayerId == activeLayer.id) {
        _enemyManagers[index] = candidate.copyWith(clearAssignment: true);
      }
    }
    _showBanner('Threat Director removed from the Tower Core.');
    _notifyNow();
  }

  void clearEnemyManagerFromCard(String enemyCardId) {
    final enemyCard = enemyCardById(enemyCardId);
    if (enemyCard != null && enemyCard.isOwned) {
      selectedEnemyCardId = enemyCardId;
    }
    clearEnemyCoreManager();
  }

  int enemyLevelCap(EnemyCardState card) => card.config.rarity.levelCap;

  int enemyUpgradeRequirement(EnemyCardState card) {
    final interval = switch (card.config.rarity) {
      EnemyCardRarity.basic => 8,
      EnemyCardRarity.uncommon => 6,
      EnemyCardRarity.rare => 5,
      EnemyCardRarity.epic => 3,
      EnemyCardRarity.legendary => 2,
    };
    final base = switch (card.config.rarity) {
      EnemyCardRarity.basic => 1,
      EnemyCardRarity.uncommon => 2,
      EnemyCardRarity.rare => 3,
      EnemyCardRarity.epic => 4,
      EnemyCardRarity.legendary => 5,
    };
    return base + ((card.level - 1) ~/ interval);
  }

  int enemyMergeRequirement(EnemyCardState card) =>
      switch (card.config.rarity) {
        EnemyCardRarity.basic => 20,
        EnemyCardRarity.uncommon => 15,
        EnemyCardRarity.rare => 10,
        EnemyCardRarity.epic => 6,
        EnemyCardRarity.legendary => 0,
      };

  bool canUpgradeEnemyCard(EnemyCardState card) =>
      card.isOwned &&
      card.level < enemyLevelCap(card) &&
      card.copies >= enemyUpgradeRequirement(card);

  bool canMergeEnemyCard(EnemyCardState card) =>
      card.isOwned &&
      card.level >= enemyLevelCap(card) &&
      card.config.rarity.nextRarity != null &&
      card.copies >= enemyMergeRequirement(card);

  // TODO(full-game): Enemy-card upgrades should be a transactional inventory
  // write on the server. The client should request an upgrade and reconcile the
  // returned profile state instead of consuming copies locally.
  bool upgradeEnemyCard(String cardId) {
    final cardIndex = _enemyCards.indexWhere(
      (card) => card.config.id == cardId,
    );
    if (cardIndex == -1) {
      return false;
    }

    final card = _enemyCards[cardIndex];
    final requirement = enemyUpgradeRequirement(card);
    if (!card.isOwned ||
        card.level >= enemyLevelCap(card) ||
        card.copies < requirement) {
      return false;
    }

    _enemyCards[cardIndex] = card.copyWith(
      copies: card.copies - requirement,
      level: card.level + 1,
    );
    _recordUpgradePurchase();
    _showBanner('${card.config.name} upgraded to level ${card.level + 1}.');
    _notifyNow();
    return true;
  }

  int upgradeAllReadyEnemyCards() {
    var upgradedCount = 0;

    while (true) {
      final readyCards = _enemyCards
          .where(canUpgradeEnemyCard)
          .toList(growable: false);
      if (readyCards.isEmpty) {
        break;
      }

      readyCards.sort((left, right) {
        final rarityCompare = left.config.rarity.index.compareTo(
          right.config.rarity.index,
        );
        if (rarityCompare != 0) {
          return rarityCompare;
        }
        final levelCompare = left.level.compareTo(right.level);
        if (levelCompare != 0) {
          return levelCompare;
        }
        return left.config.id.compareTo(right.config.id);
      });

      final nextCardId = readyCards.first.config.id;
      final nextIndex = _enemyCards.indexWhere(
        (card) => card.config.id == nextCardId,
      );
      if (nextIndex == -1) {
        break;
      }

      final card = _enemyCards[nextIndex];
      final requirement = enemyUpgradeRequirement(card);
      if (!card.isOwned ||
          card.level >= enemyLevelCap(card) ||
          card.copies < requirement) {
        break;
      }

      _enemyCards[nextIndex] = card.copyWith(
        copies: card.copies - requirement,
        level: card.level + 1,
      );
      _recordUpgradePurchase();
      upgradedCount++;
    }

    if (upgradedCount == 0) {
      return 0;
    }

    _showBanner(
      upgradedCount == 1
          ? 'Bulk leveled 1 anomaly card.'
          : 'Bulk leveled $upgradedCount anomaly levels.',
    );
    _notifyNow();
    return upgradedCount;
  }

  bool mergeEnemyCard(String cardId) {
    final cardIndex = _enemyCards.indexWhere(
      (card) => card.config.id == cardId,
    );
    if (cardIndex == -1) {
      return false;
    }

    return _mergeEnemyCardAtIndex(cardIndex);
  }

  int mergeAllReadyEnemyCards() {
    var mergedCount = 0;

    while (true) {
      final readyCards = _enemyCards
          .where(canMergeEnemyCard)
          .toList(growable: false);
      if (readyCards.isEmpty) {
        break;
      }

      readyCards.sort((left, right) {
        final rarityCompare = left.config.rarity.index.compareTo(
          right.config.rarity.index,
        );
        if (rarityCompare != 0) {
          return rarityCompare;
        }
        return left.config.id.compareTo(right.config.id);
      });
      final nextCardId = readyCards.first.config.id;
      final nextIndex = _enemyCards.indexWhere(
        (card) => card.config.id == nextCardId,
      );
      if (nextIndex == -1 ||
          !_mergeEnemyCardAtIndex(
            nextIndex,
            showBanner: false,
            notify: false,
          )) {
        break;
      }
      mergedCount++;
    }

    if (mergedCount == 0) {
      return 0;
    }

    _showBanner(
      mergedCount == 1
          ? 'Mass fused 1 anomaly card.'
          : 'Mass fused $mergedCount anomaly cards.',
    );
    _notifyNow();
    return mergedCount;
  }

  bool rerollTowerProjectile(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    if (activeLayerPassiveOnly) {
      return false;
    }
    final tower = _slots[slotIndex];
    final rerollCost = currentTraitRefreshCost;
    if (!tower.isBuilt || tower.isChildLayerNode || lumens < rerollCost) {
      return false;
    }

    lumens -= rerollCost;
    final nextType = _rollProjectileTrait(tower.config!);
    _slots[slotIndex] = tower.copyWith(projectileType: nextType);
    _showBanner('${towerDisplayName(tower)} rerolled to ${nextType.label}.');
    _notifyNow();
    return true;
  }

  bool rerollTowerPayload(int slotIndex) {
    if (!payloadsUnlocked) {
      _showBanner('Payloads unlock in the Prism Shell.');
      _notifyNow();
      return false;
    }
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    if (activeLayerPassiveOnly) {
      return false;
    }
    final tower = _slots[slotIndex];
    final rerollCost = currentTraitRefreshCost;
    if (!tower.isBuilt || tower.isChildLayerNode || lumens < rerollCost) {
      return false;
    }

    lumens -= rerollCost;
    final nextType = _rollPayloadTrait(tower.config!);
    _slots[slotIndex] = tower.copyWith(payloadType: nextType);
    _showBanner(
      '${towerDisplayName(tower)} payload rerolled to ${nextType.label}.',
    );
    _notifyNow();
    return true;
  }

  bool rerollPromotedChildTower(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    final tower = _slots[slotIndex];
    final childLayerId = tower.childLayerId;
    if (!tower.isPromotedChildTower || childLayerId == null || echoSeeds <= 0) {
      return false;
    }
    if (promotedChildTowerRerollsRemaining(tower) <= 0) {
      _showBanner(
        '${towerDisplayName(tower)} cannot stabilize another Echo Seed recalibration.',
      );
      _notifyNow();
      return false;
    }

    final childLayer = _layerById(childLayerId);
    childLayer.promotionTraitRoll += 1;
    echoSeeds -= 1;
    _syncParentSlotFromLayer(childLayer);
    final rerolledTower = _slots[slotIndex];
    _showBanner(
      'Echo Seed spent on ${towerDisplayName(rerolledTower)}. ${towerProjectileLabel(rerolledTower)} projectile • ${towerPayloadLabel(rerolledTower)} payload.',
    );
    _notifyNow();
    return true;
  }

  double enemyCardPreviewHealth(EnemyCardState card) {
    return _balancedEnemyStat(
          card.config,
          'baseHealth',
          card.config.baseHealth,
        ) *
        _enemyCardThreatScale(card);
  }

  int enemyCardPreviewReward(EnemyCardState card) {
    return max(
      1,
      (_balancedEnemyStat(
                card.config,
                'reward',
                card.config.reward.toDouble(),
              ) *
              _enemyCardLumenScale(card))
          .round(),
    );
  }

  String enemyCardPreviewHealthLabel(EnemyCardState card) =>
      _compactNumber(enemyCardPreviewHealth(card).round());

  String enemyCardPreviewRewardLabel(EnemyCardState card) =>
      _compactNumber(enemyCardPreviewReward(card));

  double enemyCardPreviewClearSeconds(EnemyCardState card) {
    final damageBudget = card.config.isBoss
        ? activeLayerMaxDpsEstimate
        : activeLayerMaxDpsPerEnemyEstimate;
    if (damageBudget <= 0) {
      return double.infinity;
    }
    return enemyCardPreviewHealth(card) / damageBudget;
  }

  String enemyCardThreatRatingLabel(EnemyCardState card) {
    final clearSeconds = enemyCardPreviewClearSeconds(card);
    if (clearSeconds <= 4) {
      return 'Farmable';
    }
    if (clearSeconds <= 14) {
      return 'Stable';
    }
    if (clearSeconds <= 40) {
      return 'Hard';
    }
    return 'Overwhelming';
  }

  double _enemyCardDungeonThreatRatio(EnemyCardState card) {
    final baseHealth = max(
      1.0,
      _balancedEnemyStat(card.config, 'baseHealth', card.config.baseHealth),
    );
    return max(1.0, enemyCardPreviewHealth(card) / baseHealth);
  }

  double _enemyCardDungeonEconomyRatio(EnemyCardState card) {
    final baseEconomy = max(
      1.0,
      _balancedEnemyStat(card.config, 'reward', card.config.reward.toDouble()) +
          _balancedEnemyStat(
            card.config,
            'baseExperience',
            card.config.baseExperience.toDouble(),
          ),
    );
    return max(
      1.0,
      (enemyCardPreviewReward(card) + enemyCardPreviewExperience(card)) /
          baseEconomy,
    );
  }

  double dailyDungeonRaidDamagePerSecond(
    EnemyCardState card, {
    bool apex = false,
  }) {
    final config = card.config;
    final manager = apex ? null : enemyManagerForCard(config.id);
    final levelMultiplier = 1 + ((card.level - 1) * (apex ? 0.075 : 0.055));
    final rarityMultiplier = 1 + (config.rarity.index * (apex ? 0.28 : 0.18));
    final splitBonus = config.splitsOnDeath ? 1.12 : 1.0;
    final managerMultiplier = manager == null
        ? 1.0
        : ((managerPowerAdjustedMultiplier(manager.spawnRateMultiplier) +
                      managerPowerAdjustedMultiplier(manager.healthMultiplier) +
                      managerPowerAdjustedMultiplier(manager.speedMultiplier) +
                      managerPowerAdjustedMultiplier(
                        manager.experienceMultiplier,
                      )) /
                  4)
              .clamp(0.82, 1.42)
              .toDouble();
    final bodyPressure =
        16 +
        (config.baseHealth * (apex ? 0.12 : 0.3)) +
        (config.baseDefense * (apex ? 0.34 : 0.2)) +
        (config.baseSpeed * (apex ? 1.35 : 0.9)) +
        (config.jamStrength * (apex ? 44 : 28));
    final threatMultiplier = pow(
      _enemyCardDungeonThreatRatio(card),
      apex ? 0.10 : 0.13,
    ).toDouble();
    final economyMultiplier = pow(
      _enemyCardDungeonEconomyRatio(card),
      apex ? 0.06 : 0.08,
    ).toDouble();
    return bodyPressure *
        levelMultiplier *
        rarityMultiplier *
        splitBonus *
        managerMultiplier *
        threatMultiplier *
        economyMultiplier *
        (apex ? 0.72 : 1.0);
  }

  double dailyDungeonRaidMaxHealth(
    EnemyCardState card,
    LightcoreDailyDungeonTowerProfile towerProfile, {
    bool apex = false,
  }) {
    final config = card.config;
    final manager = apex ? null : enemyManagerForCard(config.id);
    final managerMultiplier = manager == null
        ? 1.0
        : ((managerPowerAdjustedMultiplier(manager.healthMultiplier) +
                      managerPowerAdjustedMultiplier(manager.speedMultiplier)) /
                  2)
              .clamp(0.86, 1.36)
              .toDouble();
    final levelMultiplier = 1 + ((card.level - 1) * (apex ? 0.1 : 0.075));
    final rarityMultiplier = 1 + (config.rarity.index * (apex ? 0.42 : 0.24));
    final towerPressure =
        1 + ((towerProfile.towerLevel - 1) * 0.018).clamp(0.0, 0.75);
    final body =
        58 +
        (config.baseHealth * (apex ? 7.5 : 4.2)) +
        (config.baseDefense * (apex ? 3.8 : 2.4)) +
        (config.baseSpeed * (apex ? 1.9 : 1.1)) +
        (config.jamStrength * (apex ? 72 : 38));
    final threatMultiplier = pow(
      _enemyCardDungeonThreatRatio(card),
      apex ? 0.12 : 0.16,
    ).toDouble();
    return body *
        levelMultiplier *
        rarityMultiplier *
        managerMultiplier *
        towerPressure *
        threatMultiplier *
        (apex ? 1.85 : 1.0);
  }

  double dailyDungeonRaidLifetime(EnemyCardState card, {bool apex = false}) {
    final speedFactor = (card.config.baseSpeed / 28)
        .clamp(0.62, 1.18)
        .toDouble();
    final rarityBonus = card.config.rarity.index * (apex ? 0.24 : 0.16);
    final threatBonus = log(_enemyCardDungeonThreatRatio(card)) / ln10;
    return (apex ? 6.4 : 4.9) +
        speedFactor +
        rarityBonus +
        threatBonus.clamp(0.0, apex ? 1.4 : 1.8);
  }

  double dailyDungeonRaidTotalDamage(EnemyCardState card, {bool apex = false}) {
    return dailyDungeonRaidDamagePerSecond(card, apex: apex) *
        dailyDungeonRaidLifetime(card, apex: apex);
  }

  int enemyCardPreviewExperience(EnemyCardState card) =>
      _experienceRewardForEnemyCard(card);

  int enemyCardPreviewKillCredit(EnemyCardState card) =>
      _killCreditForConfig(card.config);
}
