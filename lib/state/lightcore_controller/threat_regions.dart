part of '../lightcore_controller.dart';

extension LightcoreControllerThreatRegions on LightcoreController {
  static const double threatRegionChallengeSeconds = 300;
  static const double threatRegionMinimumStabilityPercent = 70;

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
    return max(0, threatRegionChallengeSeconds - challenge.elapsedSeconds);
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
        _threatRegionChallenge?.regionId ?? _selectedThreatRegionId;
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

  bool get canScanThreatMap =>
      enemyTickets > 0 && (fullThreatMapUnlocked || threatRegionsUnlocked);

  bool canStartThreatRegionChallenge(String regionId) {
    if (_threatRegionChallenge != null) {
      return false;
    }
    final state = threatRegionStateById(regionId);
    final config = threatRegionConfigById(regionId);
    if (state == null || config == null || !state.revealed) {
      return false;
    }
    if (state.stabilizedLevel >= config.stabilizationLayers) {
      return false;
    }
    if (fullThreatMapUnlocked) {
      return true;
    }
    return threatRegionsUnlocked && config.ring <= 1;
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
    final regionId = _offlineRegionId;
    final config = regionId == null ? null : threatRegionConfigById(regionId);
    final state = regionId == null ? null : threatRegionStateById(regionId);
    if (config == null || state == null || _offlineRegionStabilizedLevel <= 0) {
      return 0;
    }
    if (state.assignedThreatDirectorId != state.validatedThreatDirectorId ||
        state.validatedThreatDirectorId !=
            _offlineRegionValidatedThreatDirectorId) {
      return 0;
    }
    final layerRatio =
        (_offlineRegionStabilizedLevel / config.stabilizationLayers).clamp(
          0.0,
          1.0,
        );
    final base = 18 + (config.ring * 18) + (config.rarity.index * 12);
    final bossPressure = config.hasDoubleBoss ? 1.28 : 1.0;
    final manager = _offlineRegionValidatedThreatDirectorId == null
        ? null
        : enemyManagerById(_offlineRegionValidatedThreatDirectorId!);
    final managerScale = manager == null
        ? 1.0
        : (manager.rewardMultiplier / manager.stabilityDamageMultiplier).clamp(
            0.65,
            1.45,
          );
    return base * (0.4 + (layerRatio * 0.6)) * bossPressure * managerScale;
  }

  String get threatScanRateInfo =>
      'Threat Scans roll rarity first from the fixed rarity table. Current-region and adjacent-hex weighting only changes which matching region is hit, and scans can hit already revealed or fully stabilized regions to create Region Echoes.';

  int regionEchoCount(String regionId) => _regionEchoes[regionId] ?? 0;

  int regionEchoMergeCostForRing(int ring) =>
      ThreatRegionLibrary.stabilizationLayersForRing(ring);

  ThreatRegionState? threatRegionStateById(String regionId) {
    final match = _threatRegions.where((state) => state.regionId == regionId);
    return match.isEmpty ? null : match.first;
  }

  ThreatRegionConfig? threatRegionConfigById(String regionId) =>
      ThreatRegionLibrary.byId[regionId];

  bool selectThreatRegion(String regionId) {
    final state = threatRegionStateById(regionId);
    if (state == null || !state.revealed) {
      return false;
    }
    _selectedThreatRegionId = regionId;
    _notifyNow();
    return true;
  }

  ThreatRegionScanResult? scanThreatMap({int count = 1}) {
    if (count <= 0 ||
        enemyTickets < count ||
        !(fullThreatMapUnlocked || threatRegionsUnlocked)) {
      return null;
    }
    ThreatRegionScanResult? lastResult;
    for (var index = 0; index < count; index += 1) {
      enemyTickets -= 1;
      enemyPullCount += 1;
      lastResult = fullThreatMapUnlocked
          ? _resolveSingleThreatMapScan()
          : _resolveFirstRingThreatMapScan();
    }
    _advanceBattlePass(BattlePassType.enemyPulls, count);
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return lastResult;
  }

  ThreatRegionScanResult _resolveFirstRingThreatMapScan() {
    final starter = ThreatRegionLibrary.all.first;
    final unrevealedRingOne = ThreatRegionLibrary.all
        .where((region) => region.ring == 1)
        .where((region) => threatRegionStateById(region.id)?.revealed != true)
        .toList(growable: false);
    if (unrevealedRingOne.isNotEmpty) {
      final region = unrevealedRingOne.first;
      final state = threatRegionStateById(region.id)!;
      _replaceThreatRegionState(state.copyWith(revealed: true));
      _selectedThreatRegionId = region.id;
      _showBanner('${region.name} revealed on the threat map.');
      return ThreatRegionScanResult(
        region: region,
        revealedNewRegion: true,
        echoGranted: 0,
        rarityRolled: region.rarity,
      );
    }

    final origin = selectedThreatRegionConfig ?? starter;
    final echoRegion = origin.ring <= 1 ? origin : starter;
    _regionEchoes[echoRegion.id] = regionEchoCount(echoRegion.id) + 1;
    _showBanner(
      '${echoRegion.name} echoed. Region Echoes: ${regionEchoCount(echoRegion.id)}.',
    );
    return ThreatRegionScanResult(
      region: echoRegion,
      revealedNewRegion: false,
      echoGranted: 1,
      rarityRolled: echoRegion.rarity,
    );
  }

  ThreatRegionScanResult _resolveSingleThreatMapScan() {
    final rarity = _rollPackRarity();
    var candidates = ThreatRegionLibrary.all
        .where((region) => region.rarity == rarity)
        .toList(growable: false);
    if (candidates.isEmpty) {
      candidates = ThreatRegionLibrary.all;
    }
    final region = _weightedScanRegion(candidates);
    final state = threatRegionStateById(region.id)!;
    final revealedNew = !state.revealed;
    if (revealedNew) {
      _replaceThreatRegionState(state.copyWith(revealed: true));
      _selectedThreatRegionId = region.id;
      _showBanner('${region.name} revealed on the threat map.');
      return ThreatRegionScanResult(
        region: region,
        revealedNewRegion: true,
        echoGranted: 0,
        rarityRolled: rarity,
      );
    }

    _regionEchoes[region.id] = regionEchoCount(region.id) + 1;
    _showBanner(
      '${region.name} echoed. Region Echoes: ${regionEchoCount(region.id)}.',
    );
    return ThreatRegionScanResult(
      region: region,
      revealedNewRegion: false,
      echoGranted: 1,
      rarityRolled: rarity,
    );
  }

  ThreatRegionConfig _weightedScanRegion(List<ThreatRegionConfig> candidates) {
    final origin = selectedThreatRegionConfig ?? ThreatRegionLibrary.all.first;
    final weighted = <({ThreatRegionConfig region, double weight})>[];
    for (final region in candidates) {
      var weight = 1.0;
      if (region.id == origin.id) {
        weight += 5;
      }
      final distance = ThreatRegionLibrary.hexDistance(
        region.q - origin.q,
        region.r - origin.r,
      );
      if (distance == 1) {
        weight += 4;
      } else if (distance == 2) {
        weight += 1.5;
      }
      if (!(threatRegionStateById(region.id)?.revealed ?? false)) {
        weight += max(0, 3 - region.ring);
      }
      weighted.add((region: region, weight: weight));
    }
    final total = weighted.fold<double>(0, (sum, item) => sum + item.weight);
    var roll = _packRandom.nextDouble() * total;
    for (final item in weighted) {
      roll -= item.weight;
      if (roll <= 0) {
        return item.region;
      }
    }
    return weighted.last.region;
  }

  bool mergeRegionEchoesToReveal({
    required String sourceRegionId,
    required String targetRegionId,
  }) {
    final source = threatRegionStateById(sourceRegionId);
    final target = threatRegionStateById(targetRegionId);
    final targetConfig = threatRegionConfigById(targetRegionId);
    if (source == null ||
        target == null ||
        targetConfig == null ||
        !source.revealed ||
        target.revealed) {
      return false;
    }
    final sourceConfig = threatRegionConfigById(sourceRegionId);
    if (sourceConfig == null ||
        source.stabilizedLevel < sourceConfig.stabilizationLayers) {
      return false;
    }
    final cost = regionEchoMergeCostForRing(targetConfig.ring);
    if (regionEchoCount(sourceRegionId) < cost) {
      return false;
    }
    _regionEchoes[sourceRegionId] = regionEchoCount(sourceRegionId) - cost;
    _replaceThreatRegionState(target.copyWith(revealed: true));
    _selectedThreatRegionId = targetRegionId;
    _showBanner('${targetConfig.name} revealed by Region Echo beacon.');
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
    if (_tutorialStep == LightcoreTutorialStep.assignEnemyManager) {
      _tutorialEnemyManagerAssigned = true;
      _syncTutorialStep(showBanner: false);
    }
    _showBanner(
      'Threat Director assigned. Restabilize ${ThreatRegionLibrary.byId[regionId]?.name ?? 'region'} to validate offline output.',
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
          config != null && config.ring > 1 && !fullThreatMapUnlocked
          ? 'Ring 2+ region challenges unlock after the Prism Shell is online.'
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
    _threatRegionDefeatedBossIds.clear();
    if (_threatRegionChallenge!.finalLayer) {
      activeLayer.bossReady = true;
      activeLayer.normalKillsSinceBoss = bossSpawnKillRequirement;
      _spawnTimer = min(_spawnTimer, 0.01);
    } else {
      activeLayer.bossReady = false;
      activeLayer.normalKillsSinceBoss = 0;
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
      validatedThreatDirectorId: state.assignedThreatDirectorId,
      fullyStabilizedAtMillis: fullyStabilized
          ? state.fullyStabilizedAtMillis ?? now
          : state.fullyStabilizedAtMillis,
    );
    _replaceThreatRegionState(nextState);
    _offlineRegionId = config.id;
    _offlineRegionStabilizedLevel = nextState.stabilizedLevel;
    _offlineRegionValidatedThreatDirectorId =
        nextState.validatedThreatDirectorId;
    _threatRegionChallenge = null;
    _threatRegionDefeatedBossIds.clear();
    if (challenge.finalLayer) {
      _grantRegionBossRewards(config, resolvedDefeatedBossIds);
    }
    _syncTutorialStep(showBanner: false);
    _showBanner(
      '${config.name} stabilized Lv ${nextState.stabilizedLevel}/${config.stabilizationLayers}.',
    );
    _notifyNow();
    return true;
  }

  bool failThreatRegionChallenge() {
    final challenge = _threatRegionChallenge;
    if (challenge == null) {
      return false;
    }
    final config = threatRegionConfigById(challenge.regionId);
    _threatRegionChallenge = null;
    _showBanner(
      '${config?.name ?? 'Region'} challenge failed. Stabilization unchanged.',
    );
    _threatRegionDefeatedBossIds.clear();
    _notifyNow();
    return false;
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
    final nextElapsed = challenge.elapsedSeconds + battleDt;
    _threatRegionChallenge = challenge.copyWith(elapsedSeconds: nextElapsed);
    if (nextElapsed < threatRegionChallengeSeconds) {
      return;
    }
    completeThreatRegionChallenge(endingStabilityPercent: _core.coreStability);
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
    if (challenge == null) {
      return const <EnemyCardState>[];
    }
    final config = threatRegionConfigById(challenge.regionId);
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
            level: max(
              1,
              min(enemy.rarity.levelCap, challenge.targetStabilizationLevel),
            ),
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
    if (stabilizedLevel > 0) {
      _offlineRegionId = regionId;
      _offlineRegionStabilizedLevel = stabilizedLevel.clamp(
        0,
        config.stabilizationLayers,
      );
      _offlineRegionValidatedThreatDirectorId = state.validatedThreatDirectorId;
    }
  }

  @visibleForTesting
  void debugGrantRegionEcho(String regionId, int count) {
    _regionEchoes[regionId] = regionEchoCount(regionId) + max(0, count);
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
      'offlineRegionId': _offlineRegionId,
      'offlineRegionStabilizedLevel': _offlineRegionStabilizedLevel,
      'offlineRegionValidatedThreatDirectorId':
          _offlineRegionValidatedThreatDirectorId,
      'regions': _threatRegions
          .map(_serializeThreatRegionState)
          .toList(growable: false),
      'regionEchoes': <String, int>{..._regionEchoes},
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
    _regionEchoes = <String, int>{
      for (final entry in _coerceMap(data['regionEchoes']).entries)
        if (_stringOrNull(entry.key) != null)
          _stringOrNull(entry.key)!: _intValue(entry.value),
    };
    _selectedThreatRegionId =
        _stringOrNull(data['selectedRegionId']) ?? _selectedThreatRegionId;
    if (threatRegionStateById(_selectedThreatRegionId ?? '')?.revealed !=
        true) {
      _selectedThreatRegionId = ThreatRegionLibrary.all.first.id;
    }
    _offlineRegionId = _stringOrNull(data['offlineRegionId']);
    _offlineRegionStabilizedLevel = _intValue(
      data['offlineRegionStabilizedLevel'],
      fallback: _offlineRegionStabilizedLevel,
    );
    _offlineRegionValidatedThreatDirectorId = _stringOrNull(
      data['offlineRegionValidatedThreatDirectorId'],
    );
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
