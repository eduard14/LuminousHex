part of '../lightcore_controller.dart';

extension LightcoreControllerThreatRegions on LightcoreController {
  static const double threatRegionChallengeSeconds = 90;
  static const int threatRegionChallengeWaveCount =
      LightcoreController.threatRegionChallengeWaveCount;
  static const double threatRegionMinimumStabilityPercent = 70;
  static const double _threatRegionChallengeWaveSeconds =
      threatRegionChallengeSeconds / threatRegionChallengeWaveCount;

  List<ThreatRegionState> _createThreatRegionStates() {
    final starterId = ThreatRegionLibrary.all.first.id;
    return ThreatRegionLibrary.all
        .map(
          (region) => ThreatRegionState(
            regionId: region.id,
            revealed: region.id == starterId,
          ),
        )
        .toList(growable: false);
  }

  List<BossTraitState> _createBossTraitInventory() {
    return ThreatRegionLibrary.bossTraits
        .map((config) => BossTraitState(config: config))
        .toList(growable: false);
  }

  List<ApexCoreState> _createApexCoreInventory() {
    return BossEnemyLibrary.all
        .map((boss) => ApexCoreState(bossConfig: boss))
        .toList(growable: false);
  }

  UnmodifiableListView<ThreatRegionConfig> get threatRegionConfigs =>
      UnmodifiableListView(ThreatRegionLibrary.all);

  UnmodifiableListView<ThreatRegionState> get threatRegions =>
      UnmodifiableListView(_threatRegions);

  UnmodifiableListView<BossTraitState> get bossTraits =>
      UnmodifiableListView(_bossTraits);

  UnmodifiableListView<ApexCoreState> get apexCores =>
      UnmodifiableListView(_apexCores);

  EnemySuiteState get activeEnemySuite => _activeEnemySuite;

  ThreatRegionChallengeState? get activeThreatRegionChallenge =>
      _threatRegionChallenge;

  ThreatRegionFarmValidationState? get activeThreatRegionFarmValidation =>
      _threatRegionFarmValidation;

  int get farmSwarmSize => _farmSwarmSize;

  int get validatedFarmSwarmSize => _validatedFarmSwarmSize;

  String? get validatedFarmRegionId => _validatedFarmRegionId;

  int get validatedFarmStabilizedLevel => _validatedFarmStabilizedLevel;

  String? get validatedFarmThreatDirectorId => _validatedFarmThreatDirectorId;

  double get validatedFarmEfficiency => _validatedFarmEfficiency;

  double get validatedFarmKillsPerHour => _validatedFarmKillsPerHour;

  double get validatedFarmLumensPerHour => _validatedFarmLumensPerHour;

  bool get canRerollFarmSwarmSize =>
      swarmMagnets >= swarmMagnetRerollCost && !activeLayerPassiveOnly;

  double get activeThreatRegionFarmValidationWaveProgress {
    final validation = _threatRegionFarmValidation;
    if (validation == null) {
      return 0;
    }
    return (validation.waveElapsedSeconds /
            _farmValidationWaveSeconds(validation))
        .clamp(0.0, 1.0);
  }

  double get activeThreatRegionFarmValidationRemainingSeconds {
    final validation = _threatRegionFarmValidation;
    if (validation == null) {
      return 0;
    }
    final waveRemaining = max(
      0.0,
      _farmValidationWaveSeconds(validation) - validation.waveElapsedSeconds,
    );
    final remainingFullWaves =
        farmValidationWaveCount - validation.waveIndex - 1;
    return waveRemaining +
        (remainingFullWaves * _farmValidationWaveSeconds(validation));
  }

  double get activeThreatRegionChallengeProgress {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return 0;
    }
    return (challenge.elapsedSeconds / threatRegionChallengeSeconds).clamp(
      0.0,
      1.0,
    );
  }

  double get activeThreatRegionChallengeRemainingSeconds {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return 0;
    }
    return max(
      0,
      _threatRegionChallengeWaveSeconds - challenge.waveElapsedSeconds,
    );
  }

  double get activeThreatRegionChallengeTotalRemainingSeconds {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return 0;
    }
    return max(0, threatRegionChallengeSeconds - challenge.elapsedSeconds);
  }

  double get activeThreatRegionChallengeWaveProgress {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return 0;
    }
    return (challenge.waveElapsedSeconds / _threatRegionChallengeWaveSeconds)
        .clamp(0.0, 1.0);
  }

  double get activeThreatRegionChallengeWaveRemainingSeconds {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return 0;
    }
    return max(
      0,
      _threatRegionChallengeWaveSeconds - challenge.waveElapsedSeconds,
    );
  }

  String get activeThreatRegionChallengeRewardLabel {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return '';
    }
    final config = threatRegionConfigById(challenge.regionId);
    if (config == null) {
      return '';
    }
    return LightcoreCurrencyLabels.rewardLumens(
      _threatRegionChallengeLumenReward(
        config,
        challenge.targetStabilizationLevel,
      ),
    );
  }

  int get activeThreatRegionRequiredBossCount {
    final challenge = _threatRegionChallenge;
    if (challenge == null || !challenge.finalLayer) {
      return 0;
    }
    final config = threatRegionConfigById(challenge.regionId);
    if (config == null) {
      return 0;
    }
    return config.secondaryBossId == null ? 1 : 2;
  }

  int get activeThreatRegionDefeatedBossCount =>
      _threatRegionDefeatedBossIds.length;

  String? get selectedThreatRegionId => _selectedThreatRegionId;

  ThreatRegionConfig? get selectedThreatRegionConfig =>
      _selectedThreatRegionId == null
      ? null
      : ThreatRegionLibrary.byId[_selectedThreatRegionId!];

  ThreatRegionState? get selectedThreatRegionState =>
      _selectedThreatRegionId == null
      ? null
      : threatRegionStateById(_selectedThreatRegionId!);

  String? get offlineRegionId => _offlineRegionId;

  int get offlineRegionStabilizedLevel => _offlineRegionStabilizedLevel;

  EnemyManagerState? get activeRegionThreatDirector {
    final regionId =
        _threatRegionFarmValidation?.regionId ??
        _threatRegionChallenge?.regionId ??
        _selectedThreatRegionId;
    final managerId = regionId == null
        ? null
        : threatRegionStateById(regionId)?.assignedThreatDirectorId;
    return managerId == null ? null : enemyManagerById(managerId);
  }

  int get fullyStabilizedRegionCount => _threatRegions.where((state) {
    final config = ThreatRegionLibrary.byId[state.regionId];
    return config != null &&
        state.stabilizedLevel >= config.stabilizationLayers;
  }).length;

  bool get fullThreatMapUnlocked {
    final starter = _threatRegions.firstWhere(
      (state) => state.regionId == ThreatRegionLibrary.all.first.id,
    );
    return bossHuntsUnlocked &&
        starter.fullyStabilizedAtMillis != null &&
        _apexCoreByBossId(
              ThreatRegionLibrary.all.first.primaryBossId,
            )?.isOwned ==
            true;
  }

  bool get threatRegionsUnlocked =>
      builtTowerCount > 0 || bossHuntsUnlocked || fullThreatMapUnlocked;

  bool get firstRegionalBossCleared => _apexCores.any((core) => core.isOwned);

  int get fullyStabilizedFirstRingRegionCount => ThreatRegionLibrary.all
      .where((region) => region.ring <= 1)
      .where((region) {
        final state = threatRegionStateById(region.id);
        return state != null &&
            state.stabilizedLevel >= region.stabilizationLayers;
      })
      .length;

  bool get firstThreatRingFullyStabilized =>
      fullyStabilizedFirstRingRegionCount ==
      ThreatRegionLibrary.all.where((region) => region.ring <= 1).length;

  ThreatRegionConfig? get nextThreatRegionConfig {
    for (final region in ThreatRegionLibrary.all) {
      final state = threatRegionStateById(region.id);
      if (state == null ||
          state.revealed ||
          !_previousThreatRegionFullyStabilized(region.id)) {
        continue;
      }
      return region;
    }
    return null;
  }

  int threatRegionSpiralIndex(String regionId) =>
      ThreatRegionLibrary.all.indexWhere((region) => region.id == regionId);

  bool canStartThreatRegionChallenge(String regionId) {
    if (_threatRegionChallenge != null || _threatRegionFarmValidation != null) {
      return false;
    }
    final state = threatRegionStateById(regionId);
    final config = threatRegionConfigById(regionId);
    if (state == null || config == null || !state.revealed) {
      return false;
    }
    if (!_previousThreatRegionFullyStabilized(regionId)) {
      return false;
    }
    if (state.stabilizedLevel >= config.stabilizationLayers) {
      return false;
    }
    return threatRegionsUnlocked;
  }

  bool get canStartFirstThreatChallenge =>
      canStartThreatRegionChallenge(ThreatRegionLibrary.all.first.id);

  String get firstThreatChallengeLabel {
    final starter = ThreatRegionLibrary.all.first;
    final state = threatRegionStateById(starter.id);
    final nextLevel = (state?.stabilizedLevel ?? 0) + 1;
    return nextLevel > starter.stabilizationLayers
        ? 'Stable'
        : 'Challenge Lv $nextLevel';
  }

  bool startFirstThreatChallenge() =>
      startThreatRegionChallenge(ThreatRegionLibrary.all.first.id);

  bool canStartThreatRegionFarmValidation(String regionId) {
    if (_threatRegionChallenge != null || _threatRegionFarmValidation != null) {
      return false;
    }
    final state = threatRegionStateById(regionId);
    final config = threatRegionConfigById(regionId);
    if (state == null || config == null || !state.revealed) {
      return false;
    }
    return state.stabilizedLevel > 0;
  }

  bool get enemySuiteBuilderUnlocked =>
      overallLevel >= dailyDungeonUnlockLevel ||
      overallLevel >= tournamentUnlockLevel ||
      fullyStabilizedRegionCount > 0 ||
      _apexCores.any((core) => core.isOwned) ||
      _bossTraits.any((trait) => trait.isOwned);

  bool get hasCompleteEnemySuite {
    final apexId = _activeEnemySuite.apexCoreBossId;
    if (apexId == null || _apexCoreByBossId(apexId)?.isOwned != true) {
      return false;
    }
    if (_activeEnemySuite.bossTraitIds.length != 2 ||
        _activeEnemySuite.anomalyCardIds.length != 3) {
      return false;
    }
    final traitCounts = <String, int>{};
    for (final traitId in _activeEnemySuite.bossTraitIds) {
      traitCounts[traitId] = (traitCounts[traitId] ?? 0) + 1;
    }
    for (final entry in traitCounts.entries) {
      final trait = _bossTraitById(entry.key);
      if (trait == null || !trait.isOwned || trait.copies < entry.value) {
        return false;
      }
    }
    final counts = <String, int>{};
    for (final cardId in _activeEnemySuite.anomalyCardIds) {
      counts[cardId] = (counts[cardId] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      final card = enemyCardById(entry.key);
      if (card == null || !card.isOwned || card.copies < entry.value) {
        return false;
      }
    }
    return true;
  }

  bool get arenaEnemySuiteReady =>
      fullyStabilizedRegionCount > 0 && hasCompleteEnemySuite;

  double get threatRegionOfflineKillsPerHour {
    final regionId = _validatedFarmRegionId ?? _offlineRegionId;
    final config = regionId == null ? null : threatRegionConfigById(regionId);
    final state = regionId == null ? null : threatRegionStateById(regionId);
    final stabilizedLevel = _validatedFarmStabilizedLevel > 0
        ? _validatedFarmStabilizedLevel
        : _offlineRegionStabilizedLevel;
    final directorId =
        _validatedFarmThreatDirectorId ??
        _offlineRegionValidatedThreatDirectorId;
    if (config == null || state == null || stabilizedLevel <= 0) {
      return 0;
    }
    if (state.assignedThreatDirectorId != directorId) {
      return 0;
    }
    if (_validatedFarmKillsPerHour > 0) {
      return min(maxOfflineKillsPerHour, _validatedFarmKillsPerHour);
    }
    return _estimateThreatRegionFarmKillsPerHour(
      config: config,
      stabilizedLevel: stabilizedLevel,
      farmSwarmSize: _validatedFarmSwarmSize,
      threatDirectorId: directorId,
      efficiency: _validatedFarmEfficiency <= 0 ? 1 : _validatedFarmEfficiency,
    );
  }

  double get threatRegionOfflineLumensPerHour {
    final regionId = _validatedFarmRegionId ?? _offlineRegionId;
    final config = regionId == null ? null : threatRegionConfigById(regionId);
    final state = regionId == null ? null : threatRegionStateById(regionId);
    final stabilizedLevel = _validatedFarmStabilizedLevel > 0
        ? _validatedFarmStabilizedLevel
        : _offlineRegionStabilizedLevel;
    final directorId =
        _validatedFarmThreatDirectorId ??
        _offlineRegionValidatedThreatDirectorId;
    if (config == null || state == null || stabilizedLevel <= 0) {
      return 0;
    }
    if (state.assignedThreatDirectorId != directorId) {
      return 0;
    }
    if (_validatedFarmLumensPerHour > 0) {
      return _validatedFarmLumensPerHour;
    }
    return _estimateThreatRegionFarmLumensPerHour(
      config: config,
      stabilizedLevel: stabilizedLevel,
      farmSwarmSize: _validatedFarmSwarmSize,
      threatDirectorId: directorId,
      efficiency: _validatedFarmEfficiency <= 0 ? 1 : _validatedFarmEfficiency,
    );
  }

  String get threatScanRateInfo =>
      'Threat Scans resolve Knowledge Cards. Threat Map progression follows the fixed route and opens only after the previous region is fully stabilized.';

  ThreatRegionState? threatRegionStateById(String regionId) {
    final match = _threatRegions.where((state) => state.regionId == regionId);
    return match.isEmpty ? null : match.first;
  }

  ThreatRegionConfig? threatRegionConfigById(String regionId) =>
      ThreatRegionLibrary.byId[regionId];

  bool _previousThreatRegionFullyStabilized(String regionId) {
    final index = threatRegionSpiralIndex(regionId);
    if (index <= 0) {
      return index == 0;
    }
    final previous = ThreatRegionLibrary.all[index - 1];
    final previousState = threatRegionStateById(previous.id);
    return previousState != null &&
        previousState.stabilizedLevel >= previous.stabilizationLayers;
  }

  bool selectThreatRegion(String regionId) {
    final state = threatRegionStateById(regionId);
    if (state == null || !state.revealed) {
      return false;
    }
    _selectedThreatRegionId = regionId;
    _notifyNow();
    return true;
  }

  bool assignThreatDirectorToRegion({
    required String regionId,
    required String managerId,
  }) {
    final state = threatRegionStateById(regionId);
    final manager = enemyManagerById(managerId);
    if (state == null || manager == null || !state.revealed) {
      return false;
    }
    _replaceThreatRegionState(
      state.copyWith(
        assignedThreatDirectorId: managerId,
        clearValidatedThreatDirector: true,
      ),
    );
    _invalidateValidatedFarmForRegion(regionId);
    if (_tutorialStep == LightcoreTutorialStep.assignEnemyManager) {
      _tutorialEnemyManagerAssigned = true;
      _syncTutorialStep(showBanner: false);
    }
    _showBanner(
      'Threat Director assigned. Run Farm Validation in ${ThreatRegionLibrary.byId[regionId]?.name ?? 'region'} to validate offline output.',
    );
    _notifyNow();
    return true;
  }

  bool clearThreatDirectorFromRegion(String regionId) {
    final state = threatRegionStateById(regionId);
    if (state == null || state.assignedThreatDirectorId == null) {
      return false;
    }
    _replaceThreatRegionState(
      state.copyWith(
        clearAssignedThreatDirector: true,
        clearValidatedThreatDirector: true,
      ),
    );
    _invalidateValidatedFarmForRegion(regionId);
    _showBanner(
      'Threat Director removed from ${ThreatRegionLibrary.byId[regionId]?.name ?? 'region'}.',
    );
    _notifyNow();
    return true;
  }

  bool startThreatRegionChallenge(String regionId) {
    if (!canStartThreatRegionChallenge(regionId)) {
      final config = threatRegionConfigById(regionId);
      final message =
          config != null && !_previousThreatRegionFullyStabilized(config.id)
          ? 'Finish the previous route region at all stabilization levels before starting ${config.name}.'
          : 'Region challenges unlock after the first tower is online.';
      _showBanner(message);
      _notifyNow();
      return false;
    }
    final state = threatRegionStateById(regionId);
    final config = threatRegionConfigById(regionId);
    if (state == null || config == null) {
      return false;
    }
    final targetLevel = state.stabilizedLevel + 1;
    if (targetLevel > config.stabilizationLayers) {
      return false;
    }
    _selectedThreatRegionId = regionId;
    _activateThreatRegionLoadout(config);
    _threatRegionChallenge = ThreatRegionChallengeState(
      regionId: regionId,
      targetStabilizationLevel: targetLevel,
      finalLayer: targetLevel == config.stabilizationLayers,
      startedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    bannerMessage = '';
    _bannerTimer = 0;
    _applyChallengeSwarmPressure();
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _blueFocusTargetEnemyIdBySlot.clear();
    _clearFocusTarget();
    _threatChallengeAutoFocusedWaveIndex = -1;
    _swarmActivated = true;
    _spawnTimer = min(_spawnTimer, 0.01);
    _threatRegionDefeatedBossIds.clear();
    if (_threatRegionChallenge!.finalLayer) {
      activeLayer.bossReady = true;
      activeLayer.normalKillsSinceBoss = bossSpawnKillRequirement;
      _spawnTimer = min(_spawnTimer, 0.01);
    } else {
      activeLayer.bossReady = false;
      activeLayer.normalKillsSinceBoss = 0;
    }
    if (_tutorialStep == LightcoreTutorialStep.raiseThreat ||
        _tutorialStep == LightcoreTutorialStep.pushNextArea) {
      _syncTutorialStep(showBanner: false);
    }
    _showBanner('${config.name} stabilization challenge started.');
    _notifyNow();
    return true;
  }

  bool completeThreatRegionChallenge({
    double endingStabilityPercent = 100,
    Set<String>? defeatedBossIds,
  }) {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return false;
    }
    final config = threatRegionConfigById(challenge.regionId);
    final state = threatRegionStateById(challenge.regionId);
    if (config == null || state == null) {
      _threatRegionChallenge = null;
      return false;
    }
    final resolvedDefeatedBossIds =
        defeatedBossIds ?? Set<String>.from(_threatRegionDefeatedBossIds);
    final requiredBosses = challenge.finalLayer
        ? {
            config.primaryBossId,
            if (config.secondaryBossId != null) config.secondaryBossId!,
          }
        : const <String>{};
    final stableEnough =
        endingStabilityPercent >= threatRegionMinimumStabilityPercent;
    final bossClear = requiredBosses.every(resolvedDefeatedBossIds.contains);
    if (!stableEnough || !bossClear) {
      return failThreatRegionChallenge();
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final fullyStabilized =
        challenge.targetStabilizationLevel >= config.stabilizationLayers;
    final nextState = state.copyWith(
      stabilizedLevel: challenge.targetStabilizationLevel,
      bestStabilityPercent: max(
        state.bestStabilityPercent,
        endingStabilityPercent,
      ),
      fullyStabilizedAtMillis: fullyStabilized
          ? state.fullyStabilizedAtMillis ?? now
          : state.fullyStabilizedAtMillis,
    );
    _replaceThreatRegionState(nextState);
    final revealedNext = fullyStabilized
        ? _revealNextSpiralRegionAfter(config)
        : null;
    _threatRegionChallenge = null;
    _threatChallengeAutoFocusedWaveIndex = -1;
    _threatRegionDefeatedBossIds.clear();
    _applyFarmSwarmPressure();
    if (challenge.finalLayer) {
      _grantRegionBossRewards(config, resolvedDefeatedBossIds);
    }
    final baseLumenReward = _threatRegionChallengeLumenReward(
      config,
      challenge.targetStabilizationLevel,
    );
    final lumenReward =
        baseLumenReward +
        _openingChallengeUpgradeTopUp(
          challenge: challenge,
          baseLumenReward: baseLumenReward,
        );
    lumens += lumenReward;
    final openingProgressReward = _grantOpeningChallengeHex2Progress(challenge);
    _applyOpeningChallengePressureLessonIfNeeded(challenge);
    _syncTutorialStep(showBanner: false);
    final rewardParts = <String>[
      LightcoreCurrencyLabels.rewardLumens(lumenReward),
      if (openingProgressReward.experienceGranted > 0)
        '+${openingProgressReward.experienceGranted} EXP',
      if (openingProgressReward.killsGranted > 0)
        '+${openingProgressReward.killsGranted} Kills',
    ];
    final revealText = revealedNext == null
        ? ''
        : ' Next route region: ${revealedNext.name}.';
    _showBanner(
      '${config.name} stabilized Lv ${nextState.stabilizedLevel}/${config.stabilizationLayers}. Live farm unlocked.$revealText Reward: ${rewardParts.join(', ')}.',
    );
    _notifyNow();
    return true;
  }

  void _applyChallengeSwarmPressure() {
    _enemyTargetCount = _normalizeEnemyTargetCount(initialEnemyTarget);
    activeLayer.enemyTargetCount = _enemyTargetCount;
  }

  void _applyFarmSwarmPressure() {
    _enemyTargetCount = _normalizeEnemyTargetCount(_farmSwarmSize);
    activeLayer.enemyTargetCount = _enemyTargetCount;
  }

  ThreatRegionConfig? _revealNextSpiralRegionAfter(ThreatRegionConfig region) {
    final currentIndex = threatRegionSpiralIndex(region.id);
    if (currentIndex < 0 ||
        currentIndex + 1 >= ThreatRegionLibrary.all.length) {
      return null;
    }
    final nextRegion = ThreatRegionLibrary.all[currentIndex + 1];
    final nextState = threatRegionStateById(nextRegion.id);
    if (nextState == null || nextState.revealed) {
      return null;
    }
    _replaceThreatRegionState(nextState.copyWith(revealed: true));
    _selectedThreatRegionId = nextRegion.id;
    return nextRegion;
  }

  int _threatRegionChallengeLumenReward(
    ThreatRegionConfig config,
    int targetLevel,
  ) {
    return 28 + (targetLevel * 12) + (config.ring * 18);
  }

  int _openingChallengeUpgradeTopUp({
    required ThreatRegionChallengeState challenge,
    required int baseLumenReward,
  }) {
    if (_earlyTutorialComplete ||
        challenge.regionId != ThreatRegionLibrary.all.first.id) {
      return 0;
    }
    final firstTower = _firstTutorialTower;
    final targetLevel = challenge.targetStabilizationLevel;
    if (firstTower == null ||
        !_isOpeningStarterTower(firstTower.config) ||
        !((targetLevel == 1 && firstTower.level == 2) ||
            (targetLevel == 2 && firstTower.level == 3))) {
      return 0;
    }
    final nextUpgradeCost = upgradeCost(firstTower);
    if (nextUpgradeCost <= 0) {
      return 0;
    }
    return max(0, nextUpgradeCost - (lumens + baseLumenReward));
  }

  ({int experienceGranted, int killsGranted})
  _grantOpeningChallengeHex2Progress(ThreatRegionChallengeState challenge) {
    if (_earlyTutorialComplete ||
        challenge.regionId != ThreatRegionLibrary.all.first.id ||
        challenge.targetStabilizationLevel != 2) {
      return (experienceGranted: 0, killsGranted: 0);
    }
    final firstTower = _firstTutorialTower;
    if (firstTower == null ||
        !_isOpeningStarterTower(firstTower.config) ||
        firstTower.level != 4) {
      return (experienceGranted: 0, killsGranted: 0);
    }
    final targetProgress = unlockKillsForOuterSlot(1);
    final experienceGranted = max(0, targetProgress - experience);
    final killsGranted = max(0, targetProgress - kills);
    if (experienceGranted > 0) {
      experience += experienceGranted;
    }
    if (killsGranted > 0) {
      kills += killsGranted;
    }
    return (experienceGranted: experienceGranted, killsGranted: killsGranted);
  }

  bool failThreatRegionChallenge() {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return false;
    }
    final config = threatRegionConfigById(challenge.regionId);
    _threatRegionChallenge = null;
    _threatChallengeAutoFocusedWaveIndex = -1;
    _applyFarmSwarmPressure();
    _showBanner(
      '${config?.name ?? 'Region'} challenge failed. Stabilization unchanged.',
    );
    _threatRegionDefeatedBossIds.clear();
    _notifyNow();
    return false;
  }

  bool rerollFarmSwarmSize() {
    if (!canRerollFarmSwarmSize) {
      _showBanner('Swarm Magnet rerolls need a Swarm Magnet charge.');
      _notifyNow();
      return false;
    }
    swarmMagnets -= swarmMagnetRerollCost;
    final progressRatio =
        fullyStabilizedRegionCount / max(1, ThreatRegionLibrary.all.length);
    final dynamicMax =
        (baseEnemyTargetMax +
                ((maxActiveEnemies - baseEnemyTargetMax) * progressRatio))
            .round();
    final rollMax = max(
      baseEnemyTargetMax,
      dynamicMax,
    ).clamp(initialEnemyTarget, maxActiveEnemies);
    final nextSize =
        initialEnemyTarget +
        _packRandom.nextInt(rollMax - initialEnemyTarget + 1);
    _farmSwarmSize = _normalizeEnemyTargetCount(nextSize);
    _invalidateValidatedFarm();
    if (_threatRegionChallenge == null && _threatRegionFarmValidation == null) {
      _applyFarmSwarmPressure();
    }
    _showBanner('Swarm Magnet retuned to $_farmSwarmSize active anomalies.');
    _notifyNow();
    return true;
  }

  bool startThreatRegionFarmValidation(String regionId) {
    if (!canStartThreatRegionFarmValidation(regionId)) {
      _showBanner(
        'Clear at least one stabilization level before Farm Validation.',
      );
      _notifyNow();
      return false;
    }
    final config = threatRegionConfigById(regionId);
    final state = threatRegionStateById(regionId);
    if (config == null || state == null) {
      return false;
    }
    _selectedThreatRegionId = regionId;
    _activateThreatRegionLoadout(config);
    _threatRegionFarmValidation = ThreatRegionFarmValidationState(
      regionId: regionId,
      targetStabilizationLevel: state.stabilizedLevel,
      startedAtMillis: DateTime.now().millisecondsSinceEpoch,
      farmSwarmSize: _farmSwarmSize,
      threatDirectorId: state.assignedThreatDirectorId,
      lowestStabilityPercent: _core.coreStability,
    );
    _applyFarmSwarmPressure();
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _blueFocusTargetEnemyIdBySlot.clear();
    _clearFocusTarget();
    activeLayer.bossReady = false;
    activeLayer.normalKillsSinceBoss = 0;
    _swarmActivated = true;
    _spawnTimer = min(_spawnTimer, 0.01);
    _showBanner(
      '${config.name} Farm Validation started: survive $farmValidationWaveCount waves at this level with its Threat Director.',
    );
    _notifyNow();
    return true;
  }

  bool failThreatRegionFarmValidation() {
    final validation = _threatRegionFarmValidation;
    if (validation == null) {
      return false;
    }
    final config = threatRegionConfigById(validation.regionId);
    _threatRegionFarmValidation = null;
    _applyFarmSwarmPressure();
    _showBanner(
      '${config?.name ?? 'Region'} Farm Validation failed. Offline farm unchanged.',
    );
    _notifyNow();
    return false;
  }

  bool completeThreatRegionFarmValidation({double? endingStabilityPercent}) {
    final validation = _threatRegionFarmValidation;
    if (validation == null) {
      return false;
    }
    final config = threatRegionConfigById(validation.regionId);
    final state = threatRegionStateById(validation.regionId);
    if (config == null || state == null) {
      _threatRegionFarmValidation = null;
      return false;
    }
    final endingStability = endingStabilityPercent ?? _core.coreStability;
    if (endingStability < threatRegionMinimumStabilityPercent) {
      return failThreatRegionFarmValidation();
    }
    final efficiency =
        min(validation.lowestStabilityPercent, endingStability) / 100;
    final killsPerHour = _estimateThreatRegionFarmKillsPerHour(
      config: config,
      stabilizedLevel: validation.targetStabilizationLevel,
      farmSwarmSize: validation.farmSwarmSize,
      threatDirectorId: validation.threatDirectorId,
      efficiency: efficiency,
    );
    final lumensPerHour = _estimateThreatRegionFarmLumensPerHour(
      config: config,
      stabilizedLevel: validation.targetStabilizationLevel,
      farmSwarmSize: validation.farmSwarmSize,
      threatDirectorId: validation.threatDirectorId,
      efficiency: efficiency,
    );
    _validatedFarmRegionId = config.id;
    _validatedFarmSwarmSize = validation.farmSwarmSize;
    _validatedFarmThreatDirectorId = validation.threatDirectorId;
    _validatedFarmStabilizedLevel = validation.targetStabilizationLevel;
    _validatedFarmEfficiency = efficiency.clamp(0.0, 1.0);
    _validatedFarmKillsPerHour = killsPerHour;
    _validatedFarmLumensPerHour = lumensPerHour;
    _syncLegacyOfflineFarmFields();
    _replaceThreatRegionState(
      validation.threatDirectorId == null
          ? state.copyWith(clearValidatedThreatDirector: true)
          : state.copyWith(
              validatedThreatDirectorId: validation.threatDirectorId,
            ),
    );
    _threatRegionFarmValidation = null;
    _applyFarmSwarmPressure();
    _showBanner(
      '${config.name} offline farm validated: ${killsPerHour.toStringAsFixed(0)} kills/hr • ${lumensPerHour.toStringAsFixed(0)} Lumens/hr.',
    );
    _notifyNow();
    return true;
  }

  void _recordThreatRegionBossDefeat(EnemyConfig boss) {
    final challenge = _threatRegionChallenge;
    if (challenge == null || !challenge.finalLayer) {
      return;
    }
    final config = threatRegionConfigById(challenge.regionId);
    if (config == null) {
      return;
    }
    if (boss.id == config.primaryBossId || boss.id == config.secondaryBossId) {
      _threatRegionDefeatedBossIds.add(boss.id);
    }
  }

  void _advanceThreatRegionChallenge(double battleDt) {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return;
    }
    final nextElapsed = min(
      threatRegionChallengeSeconds,
      challenge.elapsedSeconds + battleDt,
    );
    if (nextElapsed >= threatRegionChallengeSeconds) {
      _threatRegionChallenge = challenge.copyWith(
        elapsedSeconds: threatRegionChallengeSeconds,
        waveIndex: threatRegionChallengeWaveCount - 1,
        waveElapsedSeconds: _threatRegionChallengeWaveSeconds,
      );
      completeThreatRegionChallenge(
        endingStabilityPercent: _core.coreStability,
      );
      return;
    }
    final nextWaveIndex = min(
      threatRegionChallengeWaveCount - 1,
      (nextElapsed / _threatRegionChallengeWaveSeconds).floor(),
    );
    final nextWaveElapsed =
        nextElapsed - (nextWaveIndex * _threatRegionChallengeWaveSeconds);
    _threatRegionChallenge = challenge.copyWith(
      elapsedSeconds: nextElapsed,
      waveIndex: nextWaveIndex,
      waveElapsedSeconds: nextWaveElapsed,
    );
    if (nextWaveIndex <= challenge.waveIndex) {
      return;
    }
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _blueFocusTargetEnemyIdBySlot.clear();
    _clearFocusTarget();
    _threatChallengeAutoFocusedWaveIndex = -1;
    _spawnTimer = 0.01;
  }

  void _advanceThreatRegionFarmValidation(double battleDt) {
    final validation = _threatRegionFarmValidation;
    if (validation == null) {
      return;
    }
    final lowestStability = min(
      validation.lowestStabilityPercent,
      _core.coreStability,
    );
    if (lowestStability < threatRegionMinimumStabilityPercent) {
      failThreatRegionFarmValidation();
      return;
    }
    final nextElapsed = validation.waveElapsedSeconds + battleDt;
    final waveSeconds = _farmValidationWaveSeconds(validation);
    if (nextElapsed < waveSeconds) {
      _threatRegionFarmValidation = validation.copyWith(
        waveElapsedSeconds: nextElapsed,
        lowestStabilityPercent: lowestStability,
      );
      return;
    }
    final nextWaveIndex = validation.waveIndex + 1;
    if (nextWaveIndex >= farmValidationWaveCount) {
      _threatRegionFarmValidation = validation.copyWith(
        waveElapsedSeconds: waveSeconds,
        lowestStabilityPercent: lowestStability,
      );
      completeThreatRegionFarmValidation(
        endingStabilityPercent: _core.coreStability,
      );
      return;
    }
    _threatRegionFarmValidation = validation.copyWith(
      waveIndex: nextWaveIndex,
      waveElapsedSeconds: 0,
      lowestStabilityPercent: lowestStability,
    );
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _blueFocusTargetEnemyIdBySlot.clear();
    _clearFocusTarget();
    _spawnTimer = 0.01;
    _showBanner(
      'Farm Validation wave ${nextWaveIndex + 1}/$farmValidationWaveCount.',
      category: LightcoreNotificationCategory.battle,
    );
  }

  double _farmValidationWaveSeconds(
    ThreatRegionFarmValidationState validation,
  ) {
    final manager = validation.threatDirectorId == null
        ? null
        : enemyManagerById(validation.threatDirectorId!);
    final frequency = _threatDirectorWaveFrequencyMultiplier(manager);
    return (_farmValidationBaseWaveSeconds / frequency).clamp(18.0, 42.0);
  }

  double _threatDirectorWaveFrequencyMultiplier(EnemyManagerState? manager) {
    return (manager?.spawnRateMultiplier ?? 1).clamp(0.65, 1.75);
  }

  double _estimateThreatRegionFarmKillsPerHour({
    required ThreatRegionConfig config,
    required int stabilizedLevel,
    required int farmSwarmSize,
    required String? threatDirectorId,
    required double efficiency,
  }) {
    final levelRatio = (stabilizedLevel / config.stabilizationLayers).clamp(
      0.0,
      1.0,
    );
    final base = 18 + (config.ring * 18) + (config.rarity.index * 12);
    final bossPressure = config.hasDoubleBoss ? 1.28 : 1.0;
    final swarmScale = (farmSwarmSize / initialEnemyTarget).clamp(1.0, 8.0);
    final manager = threatDirectorId == null
        ? null
        : enemyManagerById(threatDirectorId);
    final waveFrequencyScale = _threatDirectorWaveFrequencyMultiplier(manager);
    final stabilityScale = efficiency.clamp(0.7, 1.0);
    final strengthRiskScale = manager == null
        ? 1.0
        : (2 / (manager.healthMultiplier + manager.speedMultiplier)).clamp(
            0.7,
            1.2,
          );
    return min(
      maxOfflineKillsPerHour,
      base *
          (0.4 + (levelRatio * 0.6)) *
          bossPressure *
          swarmScale *
          waveFrequencyScale *
          strengthRiskScale *
          stabilityScale,
    );
  }

  double _estimateThreatRegionFarmLumensPerHour({
    required ThreatRegionConfig config,
    required int stabilizedLevel,
    required int farmSwarmSize,
    required String? threatDirectorId,
    required double efficiency,
  }) {
    final killsPerHour = _estimateThreatRegionFarmKillsPerHour(
      config: config,
      stabilizedLevel: stabilizedLevel,
      farmSwarmSize: farmSwarmSize,
      threatDirectorId: threatDirectorId,
      efficiency: efficiency,
    );
    if (killsPerHour <= 0) {
      return 0;
    }
    final levelRatio = (stabilizedLevel / config.stabilizationLayers).clamp(
      0.0,
      1.0,
    );
    final manager = threatDirectorId == null
        ? null
        : enemyManagerById(threatDirectorId);
    final directorRewardScale = manager == null
        ? 1.0
        : manager.rewardMultiplier.clamp(0.75, 1.65);
    final doubleBossScale = config.hasDoubleBoss ? 1.18 : 1.0;
    final enemyOutputPerKill =
        (10 + (config.ring * 7) + (config.rarity.index * 5)) *
        (0.7 + (levelRatio * 0.3)) *
        doubleBossScale;
    return killsPerHour * enemyOutputPerKill * directorRewardScale;
  }

  void _invalidateValidatedFarmForRegion(String regionId) {
    if (_validatedFarmRegionId == regionId || _offlineRegionId == regionId) {
      _invalidateValidatedFarm();
    }
  }

  void _invalidateValidatedFarm() {
    _validatedFarmRegionId = null;
    _validatedFarmSwarmSize = _farmSwarmSize;
    _validatedFarmThreatDirectorId = null;
    _validatedFarmStabilizedLevel = 0;
    _validatedFarmEfficiency = 0;
    _validatedFarmKillsPerHour = 0;
    _validatedFarmLumensPerHour = 0;
    _offlineRegionId = null;
    _offlineRegionStabilizedLevel = 0;
    _offlineRegionValidatedThreatDirectorId = null;
    for (final state in _threatRegions) {
      if (state.validatedThreatDirectorId != null) {
        _replaceThreatRegionState(
          state.copyWith(clearValidatedThreatDirector: true),
        );
      }
    }
  }

  void _syncLegacyOfflineFarmFields() {
    _offlineRegionId = _validatedFarmRegionId;
    _offlineRegionStabilizedLevel = _validatedFarmStabilizedLevel;
    _offlineRegionValidatedThreatDirectorId = _validatedFarmThreatDirectorId;
  }

  void _activateThreatRegionLoadout(ThreatRegionConfig config) {
    _activeEnemyCardIds = List<String>.from(config.anomalyCardIds);
    activeLayer.activeEnemyCardIds = _activeEnemyCardIds;
    selectedEnemyCardId = _activeEnemyCardIds.first;
    _activeBossEnemyCardId = config.primaryBossId;
    activeLayer.activeBossEnemyCardId = config.primaryBossId;
  }

  List<EnemyCardState> get activeThreatRegionEnemyDeck {
    final challenge = _threatRegionChallenge;
    final validation = _threatRegionFarmValidation;
    if (challenge == null && validation == null) {
      return const <EnemyCardState>[];
    }
    final regionId = challenge?.regionId ?? validation!.regionId;
    final targetLevel =
        challenge?.targetStabilizationLevel ??
        validation!.targetStabilizationLevel;
    final config = threatRegionConfigById(regionId);
    if (config == null) {
      return const <EnemyCardState>[];
    }
    return config.anomalyCardIds
        .map(_enemyConfigById)
        .whereType<EnemyConfig>()
        .map(
          (enemy) => EnemyCardState(
            config: enemy,
            unlocked: true,
            copies: 1,
            level: max(1, min(enemy.rarity.levelCap, targetLevel)),
          ),
        )
        .toList(growable: false);
  }

  List<EnemyCardState> get activeThreatRegionBossCards {
    final challenge = _threatRegionChallenge;
    if (challenge == null || !challenge.finalLayer) {
      return const <EnemyCardState>[];
    }
    final config = threatRegionConfigById(challenge.regionId);
    if (config == null) {
      return const <EnemyCardState>[];
    }
    return <String>[
          config.primaryBossId,
          if (config.secondaryBossId != null) config.secondaryBossId!,
        ]
        .map(_bossConfigById)
        .whereType<EnemyConfig>()
        .map(
          (boss) => EnemyCardState(
            config: boss,
            unlocked: true,
            copies: 1,
            level: max(
              1,
              min(maxBossCardLevel, challenge.targetStabilizationLevel),
            ),
          ),
        )
        .toList(growable: false);
  }

  bool setActiveEnemySuite({
    required String apexCoreBossId,
    required List<String> bossTraitIds,
    required List<String> anomalyCardIds,
  }) {
    final suite = EnemySuiteState(
      apexCoreBossId: apexCoreBossId,
      bossTraitIds: bossTraitIds.take(2).toList(growable: false),
      anomalyCardIds: anomalyCardIds.take(3).toList(growable: false),
    );
    _activeEnemySuite = suite;
    _notifyNow();
    return hasCompleteEnemySuite;
  }

  bool dismantleBossTrait(String traitId) {
    final index = _bossTraits.indexWhere((trait) => trait.config.id == traitId);
    if (index == -1 || _bossTraits[index].copies <= 0) {
      return false;
    }
    final current = _bossTraits[index];
    _bossTraits[index] = current.copyWith(
      copies: current.copies - 1,
      unlocked: current.copies > 1,
    );
    threatShards += _threatShardValue(current.config.rarity);
    _notifyNow();
    return true;
  }

  bool dismantleEnemyCardCopy(String cardId) {
    final index = _enemyCards.indexWhere((card) => card.config.id == cardId);
    if (index == -1 || _enemyCards[index].copies <= 0) {
      return false;
    }
    final current = _enemyCards[index];
    _enemyCards[index] = current.copyWith(
      copies: current.copies - 1,
      unlocked: current.copies > 1,
    );
    threatShards += _threatShardValue(current.config.rarity);
    _notifyNow();
    return true;
  }

  @visibleForTesting
  void debugRevealThreatRegion(String regionId, {int stabilizedLevel = 0}) {
    final state = threatRegionStateById(regionId);
    final config = threatRegionConfigById(regionId);
    if (state == null || config == null) {
      return;
    }
    _replaceThreatRegionState(
      state.copyWith(
        revealed: true,
        stabilizedLevel: stabilizedLevel.clamp(0, config.stabilizationLayers),
        fullyStabilizedAtMillis: stabilizedLevel >= config.stabilizationLayers
            ? DateTime.now().millisecondsSinceEpoch
            : state.fullyStabilizedAtMillis,
      ),
    );
  }

  @visibleForTesting
  void debugValidateThreatRegionFarm(
    String regionId, {
    int? swarmSize,
    double stabilityPercent = 100,
  }) {
    final config = threatRegionConfigById(regionId);
    final state = threatRegionStateById(regionId);
    if (config == null || state == null || state.stabilizedLevel <= 0) {
      return;
    }
    _threatRegionFarmValidation = ThreatRegionFarmValidationState(
      regionId: regionId,
      targetStabilizationLevel: state.stabilizedLevel,
      startedAtMillis: DateTime.now().millisecondsSinceEpoch,
      farmSwarmSize: _normalizeEnemyTargetCount(swarmSize ?? _farmSwarmSize),
      threatDirectorId: state.assignedThreatDirectorId,
      waveIndex: farmValidationWaveCount - 1,
      waveElapsedSeconds: _farmValidationBaseWaveSeconds,
      lowestStabilityPercent: stabilityPercent,
    );
    completeThreatRegionFarmValidation(
      endingStabilityPercent: stabilityPercent,
    );
  }

  @visibleForTesting
  void debugGrantSwarmMagnets(int count) {
    swarmMagnets += max(0, count);
  }

  @visibleForTesting
  void debugGrantApexCore(String bossId) => _grantApexCore(bossId);

  @visibleForTesting
  void debugGrantBossTraitForBoss(String bossId) =>
      _grantBossTraitForBoss(bossId);

  @visibleForTesting
  void debugGrantEnemyCardById(String cardId, {int copies = 1}) {
    for (var index = 0; index < max(0, copies); index += 1) {
      _grantEnemyCardById(cardId);
    }
  }

  void _grantRegionBossRewards(
    ThreatRegionConfig region,
    Set<String> defeatedBossIds,
  ) {
    for (final bossId in defeatedBossIds) {
      _grantApexCore(bossId);
      _grantBossTraitForBoss(bossId);
    }
    final bossCount = max(1, defeatedBossIds.length);
    if (defeatedBossIds.length == 1) {
      _grantBossTraitForBoss(defeatedBossIds.single);
    }
    for (final anomalyId in region.anomalyCardIds) {
      _grantEnemyCardById(anomalyId);
    }
    _seedEnemySuiteFromRegionRewards(region, defeatedBossIds);
    enemyTickets += max(1, region.ring + bossCount);
  }

  void _seedEnemySuiteFromRegionRewards(
    ThreatRegionConfig region,
    Set<String> defeatedBossIds,
  ) {
    if (hasCompleteEnemySuite || defeatedBossIds.isEmpty) {
      return;
    }
    final apexBossId = defeatedBossIds.first;
    final traitIds = defeatedBossIds
        .map((bossId) => ThreatRegionLibrary.traitForBoss(bossId)?.id)
        .whereType<String>()
        .toList(growable: true);
    if (traitIds.isEmpty) {
      return;
    }
    while (traitIds.length < 2) {
      traitIds.add(traitIds.first);
    }
    _activeEnemySuite = EnemySuiteState(
      apexCoreBossId: apexBossId,
      bossTraitIds: traitIds.take(2).toList(growable: false),
      anomalyCardIds: region.anomalyCardIds.take(3).toList(growable: false),
    );
  }

  void _grantEnemyCardById(String cardId) {
    final index = _enemyCards.indexWhere((card) => card.config.id == cardId);
    if (index == -1) {
      return;
    }
    final current = _enemyCards[index];
    _enemyCards[index] = current.copyWith(
      unlocked: true,
      copies: current.copies + 1,
    );
  }

  void _grantApexCore(String bossId) {
    final index = _apexCores.indexWhere((core) => core.bossConfig.id == bossId);
    if (index == -1) {
      return;
    }
    final current = _apexCores[index];
    _apexCores[index] = current.copyWith(
      unlocked: true,
      copies: current.copies + 1,
    );
  }

  void _grantBossTraitForBoss(String bossId) {
    final trait = ThreatRegionLibrary.traitForBoss(bossId);
    if (trait == null) {
      return;
    }
    final index = _bossTraits.indexWhere(
      (state) => state.config.id == trait.id,
    );
    if (index == -1) {
      return;
    }
    final current = _bossTraits[index];
    _bossTraits[index] = current.copyWith(
      unlocked: true,
      copies: current.copies + 1,
    );
  }

  int _threatShardValue(EnemyCardRarity rarity) => switch (rarity) {
    EnemyCardRarity.basic => 1,
    EnemyCardRarity.uncommon => 2,
    EnemyCardRarity.rare => 4,
    EnemyCardRarity.epic => 8,
    EnemyCardRarity.legendary => 16,
  };

  ApexCoreState? _apexCoreByBossId(String bossId) {
    final match = _apexCores.where((core) => core.bossConfig.id == bossId);
    return match.isEmpty ? null : match.first;
  }

  BossTraitState? _bossTraitById(String traitId) {
    final match = _bossTraits.where((trait) => trait.config.id == traitId);
    return match.isEmpty ? null : match.first;
  }

  EnemyConfig? _enemyConfigById(String id) {
    final match = EnemyLibrary.all.where((enemy) => enemy.id == id);
    return match.isEmpty ? null : match.first;
  }

  EnemyConfig? _bossConfigById(String id) {
    final match = BossEnemyLibrary.all.where((boss) => boss.id == id);
    return match.isEmpty ? null : match.first;
  }

  void _replaceThreatRegionState(ThreatRegionState nextState) {
    final index = _threatRegions.indexWhere(
      (state) => state.regionId == nextState.regionId,
    );
    if (index == -1) {
      return;
    }
    final next = _threatRegions.toList(growable: false);
    next[index] = nextState;
    _threatRegions = next;
  }

  Map<String, dynamic> _serializeThreatMapState() {
    return <String, dynamic>{
      'selectedRegionId': _selectedThreatRegionId,
      'farmSwarmSize': _farmSwarmSize,
      'validatedFarmRegionId': _validatedFarmRegionId,
      'validatedFarmSwarmSize': _validatedFarmSwarmSize,
      'validatedFarmThreatDirectorId': _validatedFarmThreatDirectorId,
      'validatedFarmStabilizedLevel': _validatedFarmStabilizedLevel,
      'validatedFarmEfficiency': _validatedFarmEfficiency,
      'validatedFarmKillsPerHour': _validatedFarmKillsPerHour,
      'validatedFarmLumensPerHour': _validatedFarmLumensPerHour,
      'offlineRegionId': _offlineRegionId,
      'offlineRegionStabilizedLevel': _offlineRegionStabilizedLevel,
      'offlineRegionValidatedThreatDirectorId':
          _offlineRegionValidatedThreatDirectorId,
      'regions': _threatRegions
          .map(_serializeThreatRegionState)
          .toList(growable: false),
      'activeEnemySuite': _serializeEnemySuiteState(_activeEnemySuite),
    };
  }

  Map<String, dynamic> _serializeThreatRegionState(ThreatRegionState state) {
    return <String, dynamic>{
      'regionId': state.regionId,
      'revealed': state.revealed,
      'stabilizedLevel': state.stabilizedLevel,
      'assignedThreatDirectorId': state.assignedThreatDirectorId,
      'validatedThreatDirectorId': state.validatedThreatDirectorId,
      'bestStabilityPercent': state.bestStabilityPercent,
      'fullyStabilizedAtMillis': state.fullyStabilizedAtMillis,
    };
  }

  Map<String, dynamic> _serializeEnemySuiteState(EnemySuiteState suite) {
    return <String, dynamic>{
      'apexCoreBossId': suite.apexCoreBossId,
      'bossTraitIds': List<String>.from(suite.bossTraitIds),
      'anomalyCardIds': List<String>.from(suite.anomalyCardIds),
    };
  }

  Map<String, dynamic> _serializeBossTraitState(BossTraitState state) {
    return <String, dynamic>{
      'id': state.config.id,
      'unlocked': state.unlocked,
      'copies': state.copies,
    };
  }

  Map<String, dynamic> _serializeApexCoreState(ApexCoreState state) {
    return <String, dynamic>{
      'bossId': state.bossConfig.id,
      'unlocked': state.unlocked,
      'copies': state.copies,
    };
  }

  void _restoreThreatMapState(Map<String, dynamic> data) {
    final savedRegions = _coerceList(data['regions']);
    if (savedRegions.isNotEmpty) {
      final byId = <String, ThreatRegionState>{
        for (final state in _createThreatRegionStates()) state.regionId: state,
      };
      for (final raw in savedRegions) {
        final restored = _deserializeThreatRegionState(_coerceMap(raw));
        if (restored != null && byId.containsKey(restored.regionId)) {
          byId[restored.regionId] = restored;
        }
      }
      _threatRegions = ThreatRegionLibrary.all
          .map((region) => byId[region.id]!)
          .toList(growable: false);
    }
    _selectedThreatRegionId =
        _stringOrNull(data['selectedRegionId']) ?? _selectedThreatRegionId;
    if (threatRegionStateById(_selectedThreatRegionId ?? '')?.revealed !=
        true) {
      _selectedThreatRegionId = ThreatRegionLibrary.all.first.id;
    }
    _farmSwarmSize = _normalizeEnemyTargetCount(
      _intValue(data['farmSwarmSize'], fallback: _enemyTargetCount),
    );
    _validatedFarmRegionId =
        _stringOrNull(data['validatedFarmRegionId']) ??
        _stringOrNull(data['offlineRegionId']);
    _validatedFarmSwarmSize = _normalizeEnemyTargetCount(
      _intValue(data['validatedFarmSwarmSize'], fallback: _farmSwarmSize),
    );
    _validatedFarmThreatDirectorId =
        _stringOrNull(data['validatedFarmThreatDirectorId']) ??
        _stringOrNull(data['offlineRegionValidatedThreatDirectorId']);
    _validatedFarmStabilizedLevel = _intValue(
      data['validatedFarmStabilizedLevel'],
      fallback: _intValue(data['offlineRegionStabilizedLevel']),
    );
    _validatedFarmEfficiency = _doubleValue(
      data['validatedFarmEfficiency'],
      fallback: 1,
    ).clamp(0.0, 1.0);
    _validatedFarmKillsPerHour = _doubleValue(
      data['validatedFarmKillsPerHour'],
    ).clamp(0.0, maxOfflineKillsPerHour);
    _validatedFarmLumensPerHour = _doubleValue(
      data['validatedFarmLumensPerHour'],
    ).clamp(0.0, double.infinity);
    final validatedConfig = _validatedFarmRegionId == null
        ? null
        : threatRegionConfigById(_validatedFarmRegionId!);
    if (validatedConfig == null || _validatedFarmStabilizedLevel <= 0) {
      _validatedFarmRegionId = null;
      _validatedFarmStabilizedLevel = 0;
      _validatedFarmThreatDirectorId = null;
      _validatedFarmEfficiency = 0;
      _validatedFarmKillsPerHour = 0;
      _validatedFarmLumensPerHour = 0;
    } else {
      _validatedFarmStabilizedLevel = _validatedFarmStabilizedLevel.clamp(
        0,
        validatedConfig.stabilizationLayers,
      );
      if (_validatedFarmKillsPerHour <= 0) {
        _validatedFarmKillsPerHour = _estimateThreatRegionFarmKillsPerHour(
          config: validatedConfig,
          stabilizedLevel: _validatedFarmStabilizedLevel,
          farmSwarmSize: _validatedFarmSwarmSize,
          threatDirectorId: _validatedFarmThreatDirectorId,
          efficiency: _validatedFarmEfficiency <= 0
              ? 1
              : _validatedFarmEfficiency,
        );
      }
      if (_validatedFarmLumensPerHour <= 0) {
        _validatedFarmLumensPerHour = _estimateThreatRegionFarmLumensPerHour(
          config: validatedConfig,
          stabilizedLevel: _validatedFarmStabilizedLevel,
          farmSwarmSize: _validatedFarmSwarmSize,
          threatDirectorId: _validatedFarmThreatDirectorId,
          efficiency: _validatedFarmEfficiency <= 0
              ? 1
              : _validatedFarmEfficiency,
        );
      }
    }
    _syncLegacyOfflineFarmFields();
    _activeEnemySuite = _deserializeEnemySuiteState(
      _coerceMap(data['activeEnemySuite']),
    );
  }

  ThreatRegionState? _deserializeThreatRegionState(Map<String, dynamic> data) {
    final regionId = _stringOrNull(data['regionId']);
    final config = regionId == null ? null : threatRegionConfigById(regionId);
    if (regionId == null || config == null) {
      return null;
    }
    return ThreatRegionState(
      regionId: regionId,
      revealed: _boolValue(data['revealed']),
      stabilizedLevel: _intValue(
        data['stabilizedLevel'],
      ).clamp(0, config.stabilizationLayers),
      assignedThreatDirectorId: _stringOrNull(data['assignedThreatDirectorId']),
      validatedThreatDirectorId: _stringOrNull(
        data['validatedThreatDirectorId'],
      ),
      bestStabilityPercent: _doubleValue(
        data['bestStabilityPercent'],
      ).clamp(0, 100),
      fullyStabilizedAtMillis: _intOrNull(data['fullyStabilizedAtMillis']),
    );
  }

  EnemySuiteState _deserializeEnemySuiteState(Map<String, dynamic> data) {
    return EnemySuiteState(
      apexCoreBossId: _stringOrNull(data['apexCoreBossId']),
      bossTraitIds: _coerceList(
        data['bossTraitIds'],
      ).map(_stringOrNull).whereType<String>().take(2).toList(growable: false),
      anomalyCardIds: _coerceList(
        data['anomalyCardIds'],
      ).map(_stringOrNull).whereType<String>().take(3).toList(growable: false),
    );
  }

  void _restoreBossTraits(List<dynamic> saved) {
    final defaults = _createBossTraitInventory();
    final byId = <String, BossTraitState>{
      for (final trait in defaults) trait.config.id: trait,
    };
    for (final raw in saved) {
      final data = _coerceMap(raw);
      final id = _stringOrNull(data['id']);
      final current = id == null ? null : byId[id];
      if (id == null || current == null) {
        continue;
      }
      byId[id] = current.copyWith(
        unlocked: _boolValue(data['unlocked']),
        copies: _intValue(data['copies']),
      );
    }
    _bossTraits = defaults.map((trait) => byId[trait.config.id]!).toList();
  }

  void _restoreApexCores(List<dynamic> saved) {
    final defaults = _createApexCoreInventory();
    final byId = <String, ApexCoreState>{
      for (final core in defaults) core.bossConfig.id: core,
    };
    for (final raw in saved) {
      final data = _coerceMap(raw);
      final id = _stringOrNull(data['bossId']);
      final current = id == null ? null : byId[id];
      if (id == null || current == null) {
        continue;
      }
      byId[id] = current.copyWith(
        unlocked: _boolValue(data['unlocked']),
        copies: _intValue(data['copies']),
      );
    }
    _apexCores = defaults.map((core) => byId[core.bossConfig.id]!).toList();
  }
}
