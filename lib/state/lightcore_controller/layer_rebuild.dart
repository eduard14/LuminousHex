part of '../lightcore_controller.dart';

// L1L2_REBUILD_SAFE: Rebuild-facing controller API for the Layer 1 active loop and Layer 2 shell board.
extension LightcoreControllerLayerRebuild on LightcoreController {
  bool get layerRebuildEnabled => true;

  LayerRunState get layerRunState => _layerRun;

  LayerPersistentProgress get layerPersistentProgress =>
      _layerPersistentProgress;

  Layer2BaseBoard get layer2BaseBoard => _layer2BaseBoard;

  CompletedLayer1Shell? get latestCompletedLayer1Shell {
    // L1L2_REBUILD_SAFE: Wave 10 completion UI reads the newest shell without exposing Layer 2 as playable.
    final shells = <CompletedLayer1Shell>[
      ..._layer2BaseBoard.slots.whereType<CompletedLayer1Shell>(),
      ..._layer2BaseBoard.storage,
    ];
    if (shells.isEmpty) {
      return null;
    }
    shells.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return shells.first;
  }

  String get latestCompletedLayer1ShellLocationLabel {
    // L1L2_REBUILD_SAFE: Completion copy explains whether the manually completed shell installed or entered storage.
    final shell = latestCompletedLayer1Shell;
    if (shell == null) {
      return 'No completed shell yet';
    }
    final slotIndex = _layer2BaseBoard.slots.indexWhere(
      (candidate) => candidate?.id == shell.id,
    );
    if (slotIndex != -1) {
      return 'Installed into Layer 2 slot ${slotIndex + 1}';
    }
    return 'Stored for Layer 2 replacement';
  }

  int get sparks => _layerRun.sparks;

  int get starBolts => _layerPersistentProgress.starBolts;

  String get sparksLabel => 'Sparks';

  String get starBoltsLabel => 'Nova Shards';

  bool get layer1Wave10Ready =>
      _layerRun.wave >= LightcoreController.layer1CompletionWave;

  int get layer1ShellHexCount => 1 + layer1BuiltFeederCount;

  int get layer1RequiredShellHexCount => 1 + LightcoreController.slotCount;

  String get layer1ShellCoverageLabel =>
      '$layer1ShellHexCount/$layer1RequiredShellHexCount hexes';

  bool get layer1CanCompleteShell =>
      !_layerRun.shellReady &&
      layer1Wave10Ready &&
      layer1BuiltFeederCount >= LightcoreController.slotCount;

  String get layer1ShellMergeStatusLabel {
    if (_layerRun.shellReady) {
      return 'Layer 1 shell installed. Start a new run for another roll.';
    }
    if (!layer1Wave10Ready) {
      return 'Reach Wave ${LightcoreController.layer1CompletionWave} and complete all 7 hexes before merging.';
    }
    if (layer1BuiltFeederCount < LightcoreController.slotCount) {
      final remaining = LightcoreController.slotCount - layer1BuiltFeederCount;
      return 'Wave ${LightcoreController.layer1CompletionWave} reached. Build $remaining more relay hex${remaining == 1 ? '' : 'es'} to complete the shell.';
    }
    return 'Shell complete. Choose when to install this Layer 1 shell into Layer 2.';
  }

  int get layer1ShellProgressWave => _layerRun.shellReady
      ? LightcoreController.layer1CompletionWave
      : min(_layerRun.wave, LightcoreController.layer1CompletionWave);

  String get layer1ShellProgressLabel => _layerRun.shellReady
      ? 'Complete Layer 1 Shell'
      : 'Shell $layer1ShellProgressWave/${LightcoreController.layer1CompletionWave}';

  bool get layer2BoardVisible =>
      _layer2BaseBoard.hasAnyShell ||
      _layerPersistentProgress.bestWave >=
          LightcoreController.layer1CompletionWave;

  bool get layer1PersistentUpgradeWindowVisible =>
      !_layerRun.active &&
      (_layerRun.completedWave > 0 ||
          _layerRun.shellReady ||
          _layerPersistentProgress.bestWave > 1);

  String get layer1PostRunPersistentUpgradeLabel {
    if (_layerRun.shellReady) {
      return 'Shell complete. Nova Shard upgrades persist into every new run.';
    }
    final completed = max(0, _layerRun.completedWave);
    if (completed <= 0) {
      return 'Start a run to earn Nova Shards for permanent upgrades.';
    }
    return 'Run ended after Wave $completed. Nova Shard upgrades persist into every new run.';
  }

  int layerRunUpgradeCost(LayerRunUpgradeType type) {
    final rank = _layerRun.rankFor(type);
    return switch (type) {
      LayerRunUpgradeType.damage => 18 + (rank * 11),
      LayerRunUpgradeType.fireRate => 22 + (rank * 13),
      LayerRunUpgradeType.multishot => 30 + (rank * 34),
      LayerRunUpgradeType.queueSize => 34 + (rank * 24),
    };
  }

  int layerPersistentUpgradeCost(LayerPersistentUpgradeType type) {
    final rank = _layerPersistentProgress.rankFor(type);
    return switch (type) {
      LayerPersistentUpgradeType.feederSlots => 20 + (rank * 18),
      LayerPersistentUpgradeType.towerColors => 24 + (rank * 22),
      LayerPersistentUpgradeType.startingSparks => 16 + (rank * 14),
      LayerPersistentUpgradeType.baseCoreDamage => 28 + (rank * 24),
      LayerPersistentUpgradeType.baseCoreFireRate => 32 + (rank * 28),
      LayerPersistentUpgradeType.baseQueueSize => 36 + (rank * 30),
    };
  }

  int layer1FeederBuildCost(int slotIndex) => 24 + (slotIndex * 12);

  List<TowerConfig> get layer1FeederBuildChoices {
    // L1L2_REBUILD_SAFE: Feeder color is an explicit player choice in the rebuilt Layer 1 loop.
    return const <TowerConfig>[
      TowerLibrary.whitePrism,
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.greenPrism,
      TowerLibrary.bluePrism,
      TowerLibrary.purplePrism,
    ];
  }

  bool canBuyRunUpgrade(LayerRunUpgradeType type) =>
      _layerRun.active && _layerRun.sparks >= layerRunUpgradeCost(type);

  bool canBuyPersistentUpgrade(LayerPersistentUpgradeType type) =>
      !_layerRun.active &&
      _layerPersistentProgress.starBolts >= layerPersistentUpgradeCost(type);

  int get layer1StartingSparks =>
      LightcoreController.layer1BaseStartingSparks +
      (_layerPersistentProgress.rankFor(
            LayerPersistentUpgradeType.startingSparks,
          ) *
          20);

  int get layer1UnlockedFeederSlots {
    final persistent =
        1 +
        _layerPersistentProgress.rankFor(
          LayerPersistentUpgradeType.feederSlots,
        );
    final waveOpened = _unlockedOuterSlotCountForWaveProgress(
      max(activeLayer.bestWaveReached, _layerRun.wave),
    );
    return max(
      1,
      min(LightcoreController.slotCount, max(persistent, waveOpened)),
    );
  }

  int get layer1BuiltFeederCount =>
      _slots.where((tower) => tower.isBuilt).length;

  bool get canBuildNextLayer1Feeder =>
      _nextBuildableLayer1FeederSlotIndex() != null;

  void startLayer1Run() {
    // L1L2_REBUILD_SAFE: New runs reset only run currency/upgrades and preserve Nova Shards, unlocks, shells, and visuals.
    _layerRun = LayerRunState.initial(
      startingSparks: layer1StartingSparks,
    ).copyWith(active: true, wave: 1);
    activeLayer.bestWaveReached = 1;
    activeLayer.normalKillsSinceBoss = 0;
    activeLayer.bossReady = false;
    activeLayer.roundCurrency = 0;
    _enemies = <EnemyState>[];
    _shots = <CoreShotState>[];
    _pulses = <EnergyPulseState>[];
    _impacts = <ImpactState>[];
    _ammoQueue = <AmmoPacket>[];
    _spawnSequence = 0;
    _spawnTimer = 0.8;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _battleSpawnPolicy = LightcoreBattleSpawnPolicy.automatic;
    _slots = _slots
        .map(
          (slot) =>
              slot.copyWith(charge: 0, cooldownRemaining: 0, disruption: 0),
        )
        .toList();
    _core = _core.copyWith(
      coreStability: _maxCoreStability,
      flowEfficiency: _maxFlowEfficiency,
    );
    _applyLayerRebuildCoreUpgrades();
    _showBanner(
      'Layer 1 run started. Spend Sparks on Damage, Fire Rate, Multishot, and Queue Size before Wave 10.',
      category: LightcoreNotificationCategory.battle,
    );
    _notifyNow();
  }

  void resetLayer1Run() {
    // L1L2_REBUILD_SAFE: Explicit reset restarts the active Layer 1 run at
    // Wave 1, clearing only Sparks purchases and active-wave state.
    _layerRun = LayerRunState.initial(
      startingSparks: layer1StartingSparks,
    ).copyWith(active: true, wave: 1);
    activeLayer.bestWaveReached = 1;
    activeLayer.normalKillsSinceBoss = 0;
    activeLayer.bossReady = false;
    activeLayer.roundCurrency = 0;
    _enemies = <EnemyState>[];
    _shots = <CoreShotState>[];
    _pulses = <EnergyPulseState>[];
    _impacts = <ImpactState>[];
    _ammoQueue = <AmmoPacket>[];
    _spawnSequence = 0;
    _spawnTimer = 0.8;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _battleSpawnPolicy = LightcoreBattleSpawnPolicy.automatic;
    _slots = _slots
        .map(
          (slot) =>
              slot.copyWith(charge: 0, cooldownRemaining: 0, disruption: 0),
        )
        .toList();
    _core = _core.copyWith(
      coreStability: _maxCoreStability,
      flowEfficiency: _maxFlowEfficiency,
    );
    _applyLayerRebuildCoreUpgrades();
    _showBanner(
      'Layer 1 restarted at Wave 1. Nova Shards and shells are kept.',
    );
    _notifyNow();
  }

  bool buyRunUpgrade(LayerRunUpgradeType type) {
    // L1L2_REBUILD_SAFE: Sparks are the only per-run spend for rebuilt core combat buttons.
    final cost = layerRunUpgradeCost(type);
    if (!_layerRun.active || _layerRun.sparks < cost) {
      return false;
    }
    final ranks = Map<LayerRunUpgradeType, int>.from(_layerRun.upgradeRanks);
    ranks[type] = (ranks[type] ?? 0) + 1;
    _layerRun = _layerRun.copyWith(
      sparks: _layerRun.sparks - cost,
      upgradeRanks: ranks,
    );
    _applyLayerRebuildCoreUpgrades();
    _showBanner('${type.label} upgraded with Sparks.');
    _notifyNow();
    return true;
  }

  bool buyPersistentUpgrade(LayerPersistentUpgradeType type) {
    // L1L2_REBUILD_SAFE: Nova Shards are the only persistent spend exposed in the rebuilt Layer 1/2 loop.
    final cost = layerPersistentUpgradeCost(type);
    if (_layerRun.active || _layerPersistentProgress.starBolts < cost) {
      return false;
    }
    final ranks = Map<LayerPersistentUpgradeType, int>.from(
      _layerPersistentProgress.upgradeRanks,
    );
    ranks[type] = (ranks[type] ?? 0) + 1;
    _layerPersistentProgress = _layerPersistentProgress.copyWith(
      starBolts: _layerPersistentProgress.starBolts - cost,
      upgradeRanks: ranks,
    );
    _applyLayerRebuildCoreUpgrades();
    _showBanner('${type.label} improved with Nova Shards.');
    _notifyNow();
    return true;
  }

  bool endLayer1RunFromCoreBreak() {
    // L1L2_REBUILD_SAFE: Death ends the run and opens the persistent Nova Shard upgrade window.
    if (!_layerRun.active || _layerRun.shellReady) {
      return false;
    }
    final completedWave = max(0, _layerRun.completedWave);
    final payoutWave = max(completedWave, max(0, _layerRun.wave - 1));
    final reachedWave = max(_layerRun.wave, completedWave);
    final starBoltsEarned = max(
      1,
      payoutWave * LightcoreController.layer1StarBoltsPerCompletedWave,
    );
    _layerRun = _layerRun.copyWith(
      active: false,
      wave: 0,
      completedWave: completedWave,
    );
    _layerPersistentProgress = _layerPersistentProgress.copyWith(
      starBolts: _layerPersistentProgress.starBolts + starBoltsEarned,
      bestWave: max(_layerPersistentProgress.bestWave, reachedWave),
    );
    activeLayer.bestWaveReached = 0;
    activeLayer.normalKillsSinceBoss = 0;
    activeLayer.bossReady = false;
    _enemies = <EnemyState>[];
    _shots = <CoreShotState>[];
    _pulses = <EnergyPulseState>[];
    _impacts = <ImpactState>[];
    _ammoQueue = <AmmoPacket>[];
    _spawnSequence = 0;
    _spawnTimer = 0.8;
    _swarmActivated = false;
    _slots = _slots
        .map(
          (slot) =>
              slot.copyWith(charge: 0, cooldownRemaining: 0, disruption: 0),
        )
        .toList();
    _core = _core.copyWith(
      coreStability: 0,
      flowEfficiency: _maxFlowEfficiency,
    );
    _showBanner(
      'Layer 1 run ended. Earned $starBoltsEarned Nova Shards for permanent upgrades.',
      category: LightcoreNotificationCategory.battle,
    );
    _notifyNow();
    return true;
  }

  bool buildNextLayer1Feeder() {
    // L1L2_REBUILD_SAFE: Feeder construction uses current tower visuals but is paid from rebuilt run currency.
    final slotIndex = _nextBuildableLayer1FeederSlotIndex();
    if (slotIndex == null) {
      return false;
    }
    return buildLayer1FeederAt(slotIndex);
  }

  bool buildLayer1FeederAt(int slotIndex, {TowerConfig? config}) {
    // L1L2_REBUILD_SAFE: Empty hex taps open color choice; this action spends Sparks on the selected feeder.
    if (!_layerRun.active ||
        slotIndex < 0 ||
        slotIndex >= LightcoreController.slotCount ||
        slotIndex >= layer1UnlockedFeederSlots) {
      _showBanner('Start Layer 1 or unlock this relay hex first.');
      _notifyNow();
      return false;
    }
    final current = _slots[slotIndex];
    if (current.isBuilt || current.isFabricating) {
      selectedSlotIndex = slotIndex;
      _towerRangePreviewSlotIndex = slotIndex;
      _notifyNow();
      return true;
    }
    final selectedConfig =
        config ?? _defaultLayer1FeederConfigForSlot(slotIndex);
    final cost = layer1FeederBuildCost(slotIndex);
    if (_layerRun.sparks < cost) {
      _showBanner('Need $cost Sparks to build the next relay.');
      _notifyNow();
      return false;
    }
    _layerRun = _layerRun.copyWith(sparks: _layerRun.sparks - cost);
    _slots[slotIndex] = _buildRolledTowerState(
      slotIndex: slotIndex,
      config: selectedConfig,
      investedLumens: 0,
    );
    selectedSlotIndex = slotIndex;
    _towerRangePreviewSlotIndex = slotIndex;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _totalTowersBuilt += 1;
    _updateFlowEfficiency();
    _showBanner(
      '${selectedConfig.name} installed in Relay Hex ${slotIndex + 1}.',
    );
    _notifyNow();
    return true;
  }

  bool claimCompletedLayer1Shell() {
    // L1L2_REBUILD_SAFE: Player-controlled shell completion requires Wave 10 plus the full center+six-feeder hex.
    if (!layer1CanCompleteShell) {
      _showBanner(layer1ShellMergeStatusLabel);
      _notifyNow();
      return false;
    }
    return _completeLayer1ShellIfNeeded();
  }

  bool installShellIntoLayer2Slot(String shellId, int slotIndex) {
    // L1L2_REBUILD_SAFE: Manual storage placement keeps Layer 2 visible without making it playable yet.
    if (slotIndex < 0 || slotIndex >= _layer2BaseBoard.slots.length) {
      return false;
    }
    final storage = List<CompletedLayer1Shell>.from(_layer2BaseBoard.storage);
    final shellIndex = storage.indexWhere((shell) => shell.id == shellId);
    if (shellIndex == -1 || _layer2BaseBoard.slots[slotIndex] != null) {
      return false;
    }
    final shell = storage.removeAt(shellIndex);
    final slots = List<CompletedLayer1Shell?>.from(_layer2BaseBoard.slots);
    slots[slotIndex] = shell;
    _layer2BaseBoard = _layer2BaseBoard.copyWith(
      slots: slots,
      storage: storage,
    );
    _notifyNow();
    return true;
  }

  bool replaceLayer2Slot(int slotIndex, String shellId) {
    // L1L2_REBUILD_SAFE: Replacement swaps an installed shell with storage instead of deleting player progress.
    if (slotIndex < 0 || slotIndex >= _layer2BaseBoard.slots.length) {
      return false;
    }
    final storage = List<CompletedLayer1Shell>.from(_layer2BaseBoard.storage);
    final shellIndex = storage.indexWhere((shell) => shell.id == shellId);
    if (shellIndex == -1) {
      return false;
    }
    final slots = List<CompletedLayer1Shell?>.from(_layer2BaseBoard.slots);
    final incoming = storage.removeAt(shellIndex);
    final outgoing = slots[slotIndex];
    slots[slotIndex] = incoming;
    if (outgoing != null) {
      storage.add(outgoing);
    }
    _layer2BaseBoard = _layer2BaseBoard.copyWith(
      slots: slots,
      storage: storage,
    );
    _notifyNow();
    return true;
  }

  bool discardStoredShell(String shellId) {
    // L1L2_REBUILD_SAFE: Storage discard is intentionally limited to uninstalled shells.
    final storage = List<CompletedLayer1Shell>.from(_layer2BaseBoard.storage)
      ..removeWhere((shell) => shell.id == shellId);
    if (storage.length == _layer2BaseBoard.storage.length) {
      return false;
    }
    _layer2BaseBoard = _layer2BaseBoard.copyWith(storage: storage);
    _notifyNow();
    return true;
  }

  void clearLayerRebuildBattleSelection({bool notify = true}) {
    // L1L2_REBUILD_SAFE: Rebuilt battle opens on the tower field; tower panels appear only after a player taps a hex.
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;
    if (notify) {
      _notifyNow();
    }
  }

  @visibleForTesting
  void debugSetLayer1WaveForTest(int wave) {
    // L1L2_REBUILD_SAFE: Test hook exercises Wave 10 completion without relying on frame timing.
    _syncLayerRebuildWaveProgress(wave);
  }

  @visibleForTesting
  void debugSetLayer1SparksForTest(int sparks) {
    // L1L2_REBUILD_SAFE: Test hook avoids coupling shell-completion tests to temporary economy numbers.
    _layerRun = _layerRun.copyWith(sparks: max(0, sparks));
    _notifyNow();
  }

  void _syncLayerRebuildWaveProgress(int reachedWave) {
    // L1L2_REBUILD_SAFE: Bridges existing combat wave progression into the rebuilt run state.
    final clampedWave = max(
      1,
      min(LightcoreController.layer1CompletionWave, reachedWave),
    );
    final previousCompleted = _layerRun.completedWave;
    final completedWave = max(previousCompleted, max(0, clampedWave - 1));
    final earnedSparks =
        max(0, completedWave - previousCompleted) *
        LightcoreController.layer1SparksPerWave;
    _layerRun = _layerRun.copyWith(
      wave: max(_layerRun.wave, clampedWave),
      completedWave: completedWave,
      sparks: _layerRun.sparks + earnedSparks,
    );
    _layerPersistentProgress = _layerPersistentProgress.copyWith(
      bestWave: max(_layerPersistentProgress.bestWave, clampedWave),
    );
    final runUpgradeTotal = LayerRunUpgradeType.values.fold<int>(
      0,
      (sum, type) => sum + _layerRun.rankFor(type),
    );
    if (_layerRun.active &&
        clampedWave == 2 &&
        previousCompleted == 0 &&
        runUpgradeTotal == 0) {
      // L1L2_REBUILD_SAFE: Untouched Layer 1 runs should hit the first wall at Wave 2, teaching Sparks upgrades before Wave 10.
      endLayer1RunFromCoreBreak();
      return;
    }
  }

  ({int sparks, int novaShards}) _grantLayer1EnemyCurrencyDrop(
    EnemyState enemy,
  ) {
    // L1L2_REBUILD_SAFE: Every Layer 1 enemy kill drops run Sparks; Nova Shards
    // are rarer persistent drops using the existing persistent balance bucket.
    if (!_layerRun.active) {
      return (sparks: 0, novaShards: 0);
    }
    final sparkReward =
        (LightcoreController.layer1SparksPerEnemy *
                max(1, enemy.config.isBoss ? 4 : enemy.sizeScale.round()))
            .toInt();
    final novaShardReward =
        enemy.config.isBoss ||
            _spawnRandom.nextDouble() <
                LightcoreController.layer1NovaShardDropChance
        ? 1
        : 0;
    _layerRun = _layerRun.copyWith(sparks: _layerRun.sparks + sparkReward);
    if (novaShardReward > 0) {
      _layerPersistentProgress = _layerPersistentProgress.copyWith(
        starBolts: _layerPersistentProgress.starBolts + novaShardReward,
      );
    }
    return (sparks: sparkReward, novaShards: novaShardReward);
  }

  bool _completeLayer1ShellIfNeeded() {
    if (_layerRun.shellReady) {
      return false;
    }
    final shell = _buildCompletedLayer1Shell();
    final slots = List<CompletedLayer1Shell?>.from(_layer2BaseBoard.slots);
    final storage = List<CompletedLayer1Shell>.from(_layer2BaseBoard.storage);
    final openIndex = slots.indexWhere((entry) => entry == null);
    if (openIndex == -1) {
      storage.add(shell);
    } else {
      slots[openIndex] = shell;
    }
    _layer2BaseBoard = _layer2BaseBoard.copyWith(
      slots: slots,
      storage: storage,
    );
    _layerPersistentProgress = _layerPersistentProgress.copyWith(
      starBolts:
          _layerPersistentProgress.starBolts +
          LightcoreController.layer1CompletionStarBolts,
      bestWave: max(
        _layerPersistentProgress.bestWave,
        LightcoreController.layer1CompletionWave,
      ),
    );
    _layerRun = _layerRun.copyWith(
      active: false,
      wave: LightcoreController.layer1CompletionWave,
      completedWave: LightcoreController.layer1CompletionWave,
      shellReady: true,
    );
    _showBanner(
      openIndex == -1
          ? 'Layer 1 Shell completed and stored. Layer 2 is full.'
          : 'Layer 1 Shell completed and installed into Layer 2 slot ${openIndex + 1}.',
      category: LightcoreNotificationCategory.battle,
    );
    return true;
  }

  CompletedLayer1Shell _buildCompletedLayer1Shell() {
    _layer1ShellSequence += 1;
    final feederAffinities = <PrototypeAffinity>[
      for (final tower in _slots)
        tower.isBuilt
            ? tower.config?.affinity ?? PrototypeAffinity.neutral
            : PrototypeAffinity.neutral,
    ];
    final allAffinities = <PrototypeAffinity>[
      _core.affinity,
      ...feederAffinities,
    ];
    final distribution = <PrototypeAffinity, double>{};
    for (final affinity in allAffinities) {
      distribution[affinity] =
          (distribution[affinity] ?? 0) + (1 / allAffinities.length);
    }
    final projectileLabels = <String>{
      _core.projectileType.label,
      for (final tower in _slots)
        if (tower.isBuilt)
          tower.config?.defaultProjectileType.label ??
              ProjectileType.starBolt.label,
    }.join(' / ');
    final payloadLabels = <String>{
      _core.payloadType.label,
      for (final tower in _slots)
        if (tower.isBuilt)
          tower.config?.defaultPayloadType.label ?? PayloadType.none.label,
    }.join(' / ');
    return CompletedLayer1Shell(
      id: 'layer1-shell-$_layer1ShellSequence',
      bestWave: LightcoreController.layer1CompletionWave,
      coreAffinity: _core.affinity,
      feederAffinities: List<PrototypeAffinity>.unmodifiable(feederAffinities),
      colorDistribution: Map<PrototypeAffinity, double>.unmodifiable(
        distribution,
      ),
      projectileOddsLabel: projectileLabels,
      payloadOddsLabel: payloadLabels,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
  }

  int? _nextBuildableLayer1FeederSlotIndex() {
    if (!_layerRun.active) {
      return null;
    }
    for (
      var index = 0;
      index < min(LightcoreController.slotCount, layer1UnlockedFeederSlots);
      index += 1
    ) {
      final tower = _slots[index];
      if (!tower.isBuilt && !tower.isFabricating) {
        return index;
      }
    }
    return null;
  }

  TowerConfig _defaultLayer1FeederConfigForSlot(int slotIndex) {
    // L1L2_REBUILD_SAFE: Non-UI callers retain the old deterministic fallback; player builds pass an explicit choice.
    const feederConfigs = <TowerConfig>[
      TowerLibrary.greenPrism,
      TowerLibrary.bluePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.purplePrism,
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
    ];
    return feederConfigs[slotIndex % feederConfigs.length];
  }

  void _applyLayerRebuildCoreUpgrades() {
    // L1L2_REBUILD_SAFE: Reuses existing core combat stats for rebuilt Damage, Fire Rate, Multishot, and Queue Size.
    final damageRank =
        _layerRun.rankFor(LayerRunUpgradeType.damage) +
        _layerPersistentProgress.rankFor(
          LayerPersistentUpgradeType.baseCoreDamage,
        );
    final fireRateRank =
        _layerRun.rankFor(LayerRunUpgradeType.fireRate) +
        _layerPersistentProgress.rankFor(
          LayerPersistentUpgradeType.baseCoreFireRate,
        );
    final multishotRank = _layerRun.rankFor(LayerRunUpgradeType.multishot);
    final queueRank =
        _layerRun.rankFor(LayerRunUpgradeType.queueSize) +
        _layerPersistentProgress.rankFor(
          LayerPersistentUpgradeType.baseQueueSize,
        );
    _core = _core.copyWith(
      level: max(1, 1 + damageRank),
      fireSpeedUpgradeLevel: fireRateRank,
      multiShotUpgradeLevel: multishotRank,
      queueLimitUpgradeLevel: queueRank,
    );
    activeLayer.core = _core;
  }
}
