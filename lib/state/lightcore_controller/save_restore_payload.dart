part of '../lightcore_controller.dart';

extension LightcoreControllerSaveRestorePayload on LightcoreController {
  void _restoreFromCloudSavePayload(Map<String, dynamic> payload) {
    final playerData = _coerceMap(payload['player']);
    final settingsData = _coerceMap(payload['settings']);
    final resourceData = _coerceMap(payload['resources']);
    final metricData = _coerceMap(payload['metrics']);
    final storeData = _coerceMap(payload['store']);
    final dailyDungeonData = _coerceMap(payload['dailyDungeons']);
    final inventoryData = _coerceMap(payload['inventory']);
    final layerData = _coerceMap(payload['layers']);
    final tutorialData = _coerceMap(payload['tutorial']);

    _playerId = _stringOrNull(playerData['playerId']) ?? _playerId;
    final restoredScreenName = _normalizeOptionalScreenName(
      _stringOrNull(playerData['screenName']),
    );
    _screenName = restoredScreenName.isEmpty ? null : restoredScreenName;
    _hasPermanentOverdrive = _boolValue(playerData['hasPermanentOverdrive']);
    _hasPremiumMembership = _boolValue(playerData['hasPremiumMembership']);
    _bossUnlockGrantClaimed = _boolValue(playerData['bossUnlockGrantClaimed']);
    _equippedProfileMedalId = _stringOrNull(
      playerData['equippedProfileMedalId'],
    );
    _unlockedProfileMedalIds
      ..clear()
      ..addAll(
        _coerceList(playerData['unlockedProfileMedalIds'])
            .map(_stringOrNull)
            .whereType<String>()
            .where(MedalLibrary.byId.containsKey),
      );
    _restoreRadianceStats(_coerceMap(playerData['radianceStats']));
    _notificationBannersEnabled = _boolValue(
      settingsData['notificationBannersEnabled'],
      fallback: _notificationBannersEnabled,
    );
    _battleNotificationBannersEnabled = _boolValue(
      settingsData['battleNotificationBannersEnabled'],
      fallback: _battleNotificationBannersEnabled,
    );
    _tutorialPromptsEnabled = _boolValue(
      settingsData['tutorialPromptsEnabled'],
      fallback: _tutorialPromptsEnabled,
    );
    _sharedRelayCenterPieceId = _stringOrNull(
      playerData['sharedRelayCenterPieceId'],
    );
    _sharedRelayOuterPieceIds = List<String?>.filled(slotCount, null);
    final sharedRelayIds = _coerceList(playerData['sharedRelayOuterPieceIds']);
    for (
      var index = 0;
      index < min(slotCount, sharedRelayIds.length);
      index += 1
    ) {
      _sharedRelayOuterPieceIds[index] = _stringOrNull(sharedRelayIds[index]);
    }

    lumens = _intValue(resourceData['lumens'], fallback: lumens);
    flux = _intValue(resourceData['flux'], fallback: flux);
    prismShards = _intValue(resourceData['prismShards'], fallback: prismShards);
    managerShards = _intValue(
      resourceData['managerShards'],
      fallback: managerShards,
    );
    managerPowerLevel = _intValue(
      resourceData['managerPowerLevel'],
      fallback: managerPowerLevel,
    ).clamp(0, LightcoreController.maxManagerPowerLevel).toInt();
    shellCores = _intValue(resourceData['shellCores'], fallback: shellCores);
    enemyTickets = _intValue(
      resourceData['enemyTickets'],
      fallback: enemyTickets,
    );
    bossTickets = _intValue(resourceData['bossTickets'], fallback: bossTickets);
    final restoredBossCores = _intValue(resourceData['bossCores']);
    threatShards =
        _intValue(resourceData['threatShards'], fallback: threatShards) +
        restoredBossCores;
    bossCores = 0;
    swarmMagnets = _intValue(
      resourceData['swarmMagnets'],
      fallback: swarmMagnets,
    );
    enemyPullCount = _intValue(
      resourceData['enemyPullCount'],
      fallback: enemyPullCount,
    );
    bossPullCount = _intValue(
      resourceData['bossPullCount'],
      fallback: bossPullCount,
    );
    towerManagerPullCount = _intValue(
      resourceData['towerManagerPullCount'],
      fallback: towerManagerPullCount,
    );
    enemyManagerPullCount = _intValue(
      resourceData['enemyManagerPullCount'],
      fallback: enemyManagerPullCount,
    );
    kills = _intValue(resourceData['kills'], fallback: kills);
    experience = _intValue(resourceData['experience'], fallback: experience);
    echoSeeds = _intValue(resourceData['echoSeeds'], fallback: echoSeeds);
    totalHelpSectionsRead = _intValue(
      resourceData['totalHelpSectionsRead'],
      fallback: totalHelpSectionsRead,
    );
    _lumenHarvestSlowdown = _doubleValue(
      resourceData['lumenHarvestSlowdown'],
      fallback: _lumenHarvestSlowdown,
    );
    _enemyTicketBuffer = _doubleValue(
      resourceData['enemyTicketBuffer'],
      fallback: _enemyTicketBuffer,
    );
    _equipmentDropCounter = _intValue(
      resourceData['equipmentDropCounter'],
      fallback: _equipmentDropCounter,
    );

    _totalBattleSeconds = _doubleValue(
      metricData['totalBattleSeconds'],
      fallback: _totalBattleSeconds,
    );
    _totalOfflineSecondsClaimed = _intValue(
      metricData['totalOfflineSecondsClaimed'],
      fallback: _totalOfflineSecondsClaimed,
    );
    _totalUpgradesBought = _intValue(
      metricData['totalUpgradesBought'],
      fallback: _totalUpgradesBought,
    );
    _totalTowersBuilt = _intValue(
      metricData['totalTowersBuilt'],
      fallback: _totalTowersBuilt,
    );
    _totalManagersForged = _intValue(
      metricData['totalManagersForged'],
      fallback: _totalManagersForged,
    );
    _totalBossesDefeated = _intValue(
      metricData['totalBossesDefeated'],
      fallback: _totalBossesDefeated,
    );
    _totalLumensSpent = _intValue(
      metricData['totalLumensSpent'],
      fallback: _totalLumensSpent,
    );
    _totalFluxSpent = _intValue(
      metricData['totalFluxSpent'],
      fallback: _totalFluxSpent,
    );
    _totalPrismShardsSpent = _intValue(
      metricData['totalPrismShardsSpent'],
      fallback: _totalPrismShardsSpent,
    );
    _totalTimeWarpSecondsClaimed = _intValue(
      metricData['totalTimeWarpSecondsClaimed'],
      fallback: _totalTimeWarpSecondsClaimed,
    );
    _timeWarpPurchaseWeekKey =
        _stringOrNull(storeData['timeWarpWeekKey']) ?? _currentWeekKey();
    _timeWarpWeeklyPurchases
      ..clear()
      ..addAll(
        _coerceMap(storeData['timeWarpWeeklyPurchases']).map(
          (key, value) => MapEntry(key, _intValue(value).clamp(0, 999).toInt()),
        ),
      );
    _refreshTimeWarpPurchaseWeek();
    _storeOfferPurchaseWeekKey =
        _stringOrNull(storeData['storeOfferWeekKey']) ?? _currentWeekKey();
    _storeOfferWeeklyPurchases
      ..clear()
      ..addAll(
        _coerceMap(storeData['storeOfferWeeklyPurchases']).map(
          (key, value) => MapEntry(key, _intValue(value).clamp(0, 999).toInt()),
        ),
      );
    _refreshStoreOfferPurchaseWeek();
    final restoredDailyCleared = _intValue(
      dailyDungeonData['highestClearedTowerLevel'],
    ).clamp(0, dailyDungeonMaxTowerLevel).toInt();
    final fallbackDailyUnlocked = min(
      dailyDungeonMaxTowerLevel,
      max(dailyDungeonStartingTowerLevel, restoredDailyCleared + 1),
    );
    final restoredDailyUnlocked = _intValue(
      dailyDungeonData['highestUnlockedTowerLevel'],
      fallback: fallbackDailyUnlocked,
    ).clamp(dailyDungeonStartingTowerLevel, dailyDungeonMaxTowerLevel).toInt();
    _dailyDungeonHighestClearedTowerLevel = restoredDailyCleared;
    _dailyDungeonHighestUnlockedTowerLevel = max(
      restoredDailyUnlocked,
      fallbackDailyUnlocked,
    );
    _dailyDungeonQuickClearDayKey =
        _stringOrNull(dailyDungeonData['quickClearDayKey']) ?? '';
    _dailyDungeonQuickClearsUsed = _intValue(
      dailyDungeonData['quickClearsUsed'],
    ).clamp(0, dailyDungeonQuickClearsPerDay).toInt();
    _refreshDailyDungeonQuickClearsForToday();

    _readHelpSections
      ..clear()
      ..addAll(
        _coerceList(
          payload['readHelpSections'],
        ).map(_stringOrNull).whereType<String>(),
      );

    _cards = _coerceList(inventoryData['cards'])
        .map((item) => _deserializeInventoryCard(_coerceMap(item)))
        .whereType<InventoryCard>()
        .toList();
    _enemyManagers = _coerceList(inventoryData['enemyManagers'])
        .map((item) => _deserializeEnemyManager(_coerceMap(item)))
        .whereType<EnemyManagerState>()
        .toList();
    _enemyCards = _restoreEnemyCardInventory(
      savedCards: _coerceList(inventoryData['enemyCards']),
      defaults: _createEnemyCardInventory(),
    );
    _seedStarterEnemyCards();
    _bossEnemyCards = _restoreEnemyCardInventory(
      savedCards: _coerceList(inventoryData['bossEnemyCards']),
      defaults: _createBossEnemyCardInventory(),
    );
    _restoreBossTraits(_coerceList(inventoryData['bossTraits']));
    _restoreApexCores(_coerceList(inventoryData['apexCores']));
    _equipmentInventory = _coerceList(inventoryData['equipmentInventory'])
        .map((item) => _deserializePlayerEquipmentItem(_coerceMap(item)))
        .whereType<PlayerEquipmentItem>()
        .toList();
    _layer2Components = _coerceList(inventoryData['layer2Components'])
        .map((item) => _deserializeLayer2ComponentState(_coerceMap(item)))
        .whereType<Layer2ComponentState>()
        .toList();
    _equippedPlayerItems = <EquipmentLoadoutSlot, String?>{
      for (final slot in EquipmentLoadoutSlot.values) slot: null,
    };
    final equippedItemData = _coerceMap(inventoryData['equippedPlayerItems']);
    for (final slot in EquipmentLoadoutSlot.values) {
      _equippedPlayerItems[slot] = _stringOrNull(equippedItemData[slot.name]);
    }
    _restoreThreatMapState(_coerceMap(payload['threatMap']));

    _battlePasses = _restoreBattlePassMap(_coerceList(payload['battlePasses']));

    final restoredLayers = _coerceList(layerData['items'])
        .map((item) => _deserializeLayerSnapshot(_coerceMap(item)))
        .whereType<TowerLayerSnapshot>()
        .toList();
    if (restoredLayers.isNotEmpty) {
      _layers = restoredLayers;
      _layers
        ..sort((left, right) => left.tier.compareTo(right.tier))
        ..forEach(_syncParentSlotFromLayer);
      _normalizeCoreManagerAssignments();

      final activeLayerId =
          _stringOrNull(layerData['activeLayerId']) ?? _layers.first.id;
      final requestedActiveLayer = _layerForId(activeLayerId) ?? _layers.first;
      final resolvedActiveLayer = _liveLayerForLayer(requestedActiveLayer);
      final requestedViewLayer =
          _layerForId(_stringOrNull(layerData['viewLayerId'])) ??
          resolvedActiveLayer;
      final requestedRuntimeLayer =
          _layerForId(_stringOrNull(layerData['runtimeLayerId'])) ??
          resolvedActiveLayer;
      _viewLayerId = _liveLayerForLayer(requestedViewLayer).id;
      _runtimeLayerId = _liveLayerForLayer(requestedRuntimeLayer).id;
      final restoredEnemyTargetCount = resolvedActiveLayer.enemyTargetCount;
      _loadLayer(resolvedActiveLayer);
      _applyFarmSwarmPressure();
      if (restoredEnemyTargetCount > _enemyTargetCount) {
        _enemyTargetCount = _normalizeEnemyTargetCount(
          restoredEnemyTargetCount,
        );
        activeLayer.enemyTargetCount = _enemyTargetCount;
      }
    }
    _completedTowerShells = _coerceList(payload['completedTowerShells'])
        .map((item) => _deserializeCompletedTowerShellState(_coerceMap(item)))
        .whereType<CompletedTowerShellState>()
        .toList(growable: false);

    _activeGuild = _deserializeGuildState(_coerceMap(payload['guild']));
    _guildChatCounter = 0;
    _initializeSharedRelayLoadout();
    _syncGuildPlayerContribution();

    final hasRestoredStabilityPanelOpened = tutorialData.containsKey(
      'stabilityPanelOpened',
    );
    final hasRestoredManagerAutoAimShots =
        tutorialData.containsKey('managerAutoAimShots') ||
        tutorialData.containsKey('autoQueuedPulses');
    _tutorialEarlyQuestChainCompleted = _boolValue(
      tutorialData['earlyQuestChainCompleted'],
    );
    _tutorialFirstBossDefeated = _boolValue(tutorialData['firstBossDefeated']);
    _tutorialFirstEquipmentOpened = _boolValue(
      tutorialData['firstEquipmentOpened'],
    );
    _tutorialFirstManagersOpened = _boolValue(
      tutorialData['firstManagersOpened'],
    );
    _tutorialFirstEnemyTargetSet = _boolValue(
      tutorialData['firstEnemyTargetSet'],
    );
    _tutorialEnemyCountAdjusted = _boolValue(
      tutorialData['enemyCountAdjusted'],
    );
    _tutorialStabilityPanelOpened = _boolValue(
      tutorialData['stabilityPanelOpened'],
    );
    _tutorialTowerMatrixOpened = _boolValue(tutorialData['towerMatrixOpened']);
    _tutorialStoreOpened = _boolValue(tutorialData['storeOpened']);
    _tutorialBattlePassRewardClaimed = _boolValue(
      tutorialData['battlePassRewardClaimed'],
    );
    _tutorialTowerManagerAssigned = _boolValue(
      tutorialData['towerManagerAssigned'],
    );
    _tutorialEnemyManagerAssigned = _boolValue(
      tutorialData['enemyManagerAssigned'],
    );
    _tutorialFriendsOpened = _boolValue(tutorialData['friendsOpened']);
    _tutorialMenteesOpened = _boolValue(tutorialData['menteesOpened']);
    _tutorialMentorsOpened = _boolValue(tutorialData['mentorsOpened']);
    _tutorialFocusFireLearned = _boolValue(
      tutorialData['focusFireLearned'] ?? tutorialData['manualAimFireLearned'],
      fallback: _tutorialEarlyQuestChainCompleted,
    );
    _tutorialOpeningPressureHitApplied = _boolValue(
      tutorialData['openingPressureHitApplied'],
      fallback: _tutorialEarlyQuestChainCompleted,
    );
    _tutorialChallengePressureHitApplied = _boolValue(
      tutorialData['challengePressureHitApplied'],
      fallback: _tutorialEarlyQuestChainCompleted,
    );
    _tutorialSecondChallengePressureHitApplied = _boolValue(
      tutorialData['secondChallengePressureHitApplied'],
      fallback: _tutorialEarlyQuestChainCompleted,
    );
    _tutorialSecondShellTowerInspected = _boolValue(
      tutorialData['secondShellTowerInspected'] ??
          tutorialData['secondShellShotTapLearned'],
    );
    _tutorialOverdriveLearned = _boolValue(tutorialData['overdriveLearned']);
    _tutorialIntroBossPending = _boolValue(tutorialData['introBossPending']);
    _tutorialSafeScanDefeats = _intValue(tutorialData['safeScanDefeats']);
    _tutorialManagerAutoAimShots = _intValue(
      tutorialData['managerAutoAimShots'] ?? tutorialData['autoQueuedPulses'],
    );
    _tutorialTrackedBossEnemyId = _stringOrNull(
      tutorialData['trackedBossEnemyId'],
    );
    _reviewedTournamentTutorialModes
      ..clear()
      ..addAll(
        _coerceList(tutorialData['reviewedTournamentModes'])
            .map(_stringOrNull)
            .whereType<String>()
            .map(
              (value) => _enumByName(LightcoreTournamentModeId.values, value),
            )
            .whereType<LightcoreTournamentModeId>(),
      );
    _rewardedTutorialSteps
      ..clear()
      ..addAll(
        _coerceList(tutorialData['rewardedSteps'])
            .map(_stringOrNull)
            .whereType<String>()
            .map(_restoreTutorialStepName)
            .whereType<LightcoreTutorialStep>(),
      );

    _lastEnemyPackPulls = <PackPullResult>[];
    _lastBossPackPulls = <PackPullResult>[];
    _bannerTimer = 0;
    bannerMessage = '';
    _manualOverdriveHeld = false;
    _manualOverdriveCharge = _hasPermanentOverdrive ? 1 : 0;
    _syncProfileMedalAchievements(showBanner: false);
    _normalizeEquippedProfileMedal();
    _migrateRestoredTutorialState(
      hasStabilityPanelOpened: hasRestoredStabilityPanelOpened,
      hasManagerAutoAimShots: hasRestoredManagerAutoAimShots,
    );
    _armStarterBossForOpening();
    _tutorialStep = LightcoreTutorialStep.none;
    _syncTutorialStep(showBanner: false);
    _recoverBattleSessionRuntime(notify: false);
    _loadRecoveredActiveLayer();
    _syncTutorialStep(showBanner: false);
  }

  void recoverBattleSession() {
    if (_layerForId(_activeLayerId) != null) {
      _storeActiveLayer();
    }
    final recovered = _recoverBattleSessionRuntime(notify: false);
    _loadRecoveredActiveLayer();
    if (recovered) {
      _notifyNow();
    }
  }

  void _loadRecoveredActiveLayer() {
    final activeLayer =
        _layerForId(_activeLayerId) ??
        _layerForId(_viewLayerId) ??
        (_layers.isEmpty ? null : _layers.first);
    if (activeLayer != null) {
      _loadLayer(_liveLayerForLayer(activeLayer));
    }
  }

  bool _recoverBattleSessionRuntime({bool notify = true}) {
    if (_layers.isEmpty) {
      return false;
    }

    final fallbackLayer = _layers.first;
    final viewedLayer = _liveLayerForLayer(
      _layerForId(_viewLayerId) ?? _layerForId(_activeLayerId) ?? fallbackLayer,
    );
    final activeLayer = _liveLayerForLayer(
      _layerForId(_activeLayerId) ?? viewedLayer,
    );
    var changed = false;

    if (_viewLayerId != viewedLayer.id) {
      _viewLayerId = viewedLayer.id;
      changed = true;
    }
    if (_runtimeLayerId != viewedLayer.id) {
      _runtimeLayerId = viewedLayer.id;
      changed = true;
    }
    if (_activeLayerId != activeLayer.id) {
      _activeLayerId = activeLayer.id;
      changed = true;
    }

    for (final layer in _layers) {
      changed = _normalizeRestoredLayerRuntime(layer) || changed;
    }

    final shouldResumeViewedLayer = _shouldResumeRestoredBattle(viewedLayer);
    if (shouldResumeViewedLayer) {
      changed = _armRestoredBattleLayer(viewedLayer) || changed;
    }

    if (changed && notify) {
      _notifyNow();
    }
    return changed;
  }

  bool _normalizeRestoredLayerRuntime(TowerLayerSnapshot layer) {
    var changed = false;
    if (layer.activeEnemyCardIds.isEmpty ||
        (layer.activeEnemyCardIds.length == 1 &&
            layer.activeEnemyCardIds.single ==
                EnemyLibrary.starterDefault.id)) {
      layer.activeEnemyCardIds = <String>[EnemyLibrary.basicWhite.id];
      changed = true;
    }
    if (!layer.spawnTimer.isFinite || layer.spawnTimer < 0) {
      layer.spawnTimer = 0.05;
      changed = true;
    }
    return changed;
  }

  bool _armRestoredBattleLayer(TowerLayerSnapshot layer) {
    var changed = false;
    if (!layer.outerRingRevealed) {
      layer.outerRingRevealed = true;
      changed = true;
    }
    if (!layer.swarmActivated) {
      layer.swarmActivated = true;
      changed = true;
    }
    if (layer.enemies.isEmpty && layer.spawnTimer > 0.2) {
      layer.spawnTimer = 0.05;
      changed = true;
    }
    return changed;
  }

  bool _shouldResumeRestoredBattle(TowerLayerSnapshot layer) {
    if (layer.swarmActivated) {
      return true;
    }
    if (layer.outerRingRevealed && _layerHasBattleProgress(layer)) {
      return true;
    }
    return _layerHasBattleProgress(layer) || _saveHasBattleProgress;
  }

  bool _layerHasBattleProgress(TowerLayerSnapshot layer) {
    return layer.slots.any((slot) => slot.isBuilt || slot.isFabricating) ||
        layer.elapsed > 0 ||
        layer.spawnSequence > 0 ||
        layer.enemyCounter > 0 ||
        layer.pulseCounter > 0 ||
        layer.shotCounter > 0 ||
        layer.impactCounter > 0 ||
        layer.core.fireSequence > 0 ||
        (layer.normalKillsSinceBoss > 0 && layer.outerRingRevealed) ||
        (layer.bossReady && layer.outerRingRevealed);
  }

  bool get _saveHasBattleProgress =>
      _totalBattleSeconds > 0 ||
      _totalTowersBuilt > 0 ||
      _totalUpgradesBought > 0 ||
      kills > 0 ||
      experience > 0 ||
      enemyPullCount > 0 ||
      bossPullCount > 0;

  void _migrateRestoredTutorialState({
    required bool hasStabilityPanelOpened,
    required bool hasManagerAutoAimShots,
  }) {
    final hasDurableEarlyProgress =
        _tutorialEarlyQuestChainCompleted ||
        builtTowerCount > 1 ||
        _core.rangeUpgradeLevel > 0 ||
        enemyPullCount > 1 ||
        bossPullCount > 0 ||
        totalBossesDefeated > 0 ||
        _layers.any((layer) => layer.tier > 1 || layer.parentLayerId != null);

    if (hasDurableEarlyProgress) {
      _tutorialEarlyQuestChainCompleted = true;
    }
    if (!hasStabilityPanelOpened &&
        (hasDurableEarlyProgress ||
            _tutorialTowerManagerAssigned ||
            _tutorialManagerAutoAimShots > 0)) {
      _tutorialStabilityPanelOpened = true;
    }
    if (!hasManagerAutoAimShots && hasDurableEarlyProgress) {
      _tutorialManagerAutoAimShots = max(_tutorialManagerAutoAimShots, 5);
    }
    if (hasDurableEarlyProgress) {
      _tutorialFocusFireLearned = true;
    }
  }

  Map<String, dynamic> _serializeRadianceStats() {
    return <String, dynamic>{
      for (final stat in LightcoreRadianceStat.values)
        stat.name: radianceStatRank(stat),
    };
  }

  void _restoreRadianceStats(Map<String, dynamic> data) {
    _radianceStatRanks
      ..clear()
      ..addEntries(
        LightcoreRadianceStat.values.map(
          (stat) => MapEntry(stat, max(0, _intValue(data[stat.name]))),
        ),
      );
  }

  void _resetRadianceStats() {
    _radianceStatRanks
      ..clear()
      ..addEntries(
        LightcoreRadianceStat.values.map((stat) => MapEntry(stat, 0)),
      );
  }

  LightcoreTutorialStep? _restoreTutorialStepName(String value) {
    if (value == 'autoQueueCheck') {
      return LightcoreTutorialStep.managerAutoAim;
    }
    if (value == 'tapFirstTower') {
      return LightcoreTutorialStep.focusFirstEnemy;
    }
    if (value == 'tapSecondShellTower') {
      return LightcoreTutorialStep.inspectSecondShellTower;
    }
    return _enumByName(LightcoreTutorialStep.values, value);
  }
}
