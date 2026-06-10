part of '../lightcore_controller.dart';

// L1L2_REBUILD_SAFE: Rebuild-facing controller API for the Layer 1 active loop and Layer 2 shell board.
extension LightcoreControllerLayerRebuild on LightcoreController {
  bool get layerRebuildEnabled => true;

  LayerRunState get layerRunState => _layerRun;

  LayerPersistentProgress get layerPersistentProgress =>
      _layerPersistentProgress;

  Layer2BaseBoard get layer2BaseBoard => _layer2BaseBoard;

  int get sparks => _layerRun.sparks;

  int get starBolts => _layerPersistentProgress.starBolts;

  String get sparksLabel => 'Sparks';

  String get starBoltsLabel => 'Star Bolts';

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

  bool canBuyRunUpgrade(LayerRunUpgradeType type) =>
      _layerRun.active && _layerRun.sparks >= layerRunUpgradeCost(type);

  bool canBuyPersistentUpgrade(LayerPersistentUpgradeType type) =>
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
    // L1L2_REBUILD_SAFE: New runs reset only run currency/upgrades and preserve Star Bolts, unlocks, shells, and visuals.
    _layerRun = LayerRunState.initial(
      startingSparks: layer1StartingSparks,
    ).copyWith(active: true, wave: 1);
    activeLayer.bestWaveReached = 1;
    activeLayer.roundCurrency = 0;
    _enemies = <EnemyState>[];
    _shots = <CoreShotState>[];
    _pulses = <EnergyPulseState>[];
    _impacts = <ImpactState>[];
    _ammoQueue = <AmmoPacket>[];
    _spawnTimer = 0.8;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _battleSpawnPolicy = LightcoreBattleSpawnPolicy.automatic;
    _applyLayerRebuildCoreUpgrades();
    _showBanner(
      'Layer 1 run started. Spend Sparks on Damage, Fire Rate, Multishot, and Queue Size before Wave 10.',
      category: LightcoreNotificationCategory.battle,
    );
    _notifyNow();
  }

  void resetLayer1Run() {
    // L1L2_REBUILD_SAFE: Explicit reset clears active run economy without touching persistent rebuild state.
    _layerRun = LayerRunState.initial(startingSparks: layer1StartingSparks);
    activeLayer.bestWaveReached = 1;
    activeLayer.roundCurrency = 0;
    _enemies = <EnemyState>[];
    _shots = <CoreShotState>[];
    _pulses = <EnergyPulseState>[];
    _impacts = <ImpactState>[];
    _ammoQueue = <AmmoPacket>[];
    _applyLayerRebuildCoreUpgrades();
    _showBanner('Layer 1 run reset. Star Bolts and Layer 2 shells are kept.');
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
    // L1L2_REBUILD_SAFE: Star Bolts are the only persistent spend exposed in the rebuilt Layer 1/2 loop.
    final cost = layerPersistentUpgradeCost(type);
    if (_layerPersistentProgress.starBolts < cost) {
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
    _showBanner('${type.label} improved with Star Bolts.');
    _notifyNow();
    return true;
  }

  bool buildNextLayer1Feeder() {
    // L1L2_REBUILD_SAFE: Feeder construction uses current tower visuals but is paid from rebuilt run currency.
    final slotIndex = _nextBuildableLayer1FeederSlotIndex();
    if (slotIndex == null) {
      return false;
    }
    const feederConfigs = <TowerConfig>[
      TowerLibrary.greenPrism,
      TowerLibrary.bluePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.purplePrism,
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
    ];
    final config = feederConfigs[slotIndex % feederConfigs.length];
    final cost = 24 + (slotIndex * 12);
    if (_layerRun.sparks < cost) {
      _showBanner('Need $cost Sparks to build the next feeder.');
      _notifyNow();
      return false;
    }
    _layerRun = _layerRun.copyWith(sparks: _layerRun.sparks - cost);
    _slots[slotIndex] = _buildRolledTowerState(
      slotIndex: slotIndex,
      config: config,
      investedLumens: 0,
    );
    selectedSlotIndex = slotIndex;
    _towerRangePreviewSlotIndex = slotIndex;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _totalTowersBuilt += 1;
    _updateFlowEfficiency();
    _showBanner('${config.name} installed as feeder ${slotIndex + 1}.');
    _notifyNow();
    return true;
  }

  bool claimCompletedLayer1Shell() {
    // L1L2_REBUILD_SAFE: Public action for tests/UI; completion is idempotent so Wave 10 creates one shell.
    if (!_layerRun.shellReady &&
        _layerRun.wave < LightcoreController.layer1CompletionWave) {
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

  @visibleForTesting
  void debugSetLayer1WaveForTest(int wave) {
    // L1L2_REBUILD_SAFE: Test hook exercises Wave 10 completion without relying on frame timing.
    _syncLayerRebuildWaveProgress(wave);
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
    if (clampedWave >= LightcoreController.layer1CompletionWave) {
      _completeLayer1ShellIfNeeded();
    }
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
          ? 'Complete Layer 1 Shell stored. Layer 2 is full.'
          : 'Complete Layer 1 Shell installed into Layer 2 slot ${openIndex + 1}.',
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
