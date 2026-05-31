part of '../lightcore_controller.dart';

const double _persistentShieldRingDamagePerSecondMultiplier = 0.28;
const double _shieldHaloGuardRadiusOffset = 20;
const double _shieldHaloGuardBandHalfWidth = 12;

double _shieldHaloGuardRadiusForMaxRange(double maxRange) =>
    min(maxRange, _relayImpactRadius + _shieldHaloGuardRadiusOffset);

extension LightcoreControllerCombatLoop on LightcoreController {
  ({bool busy, bool fabricationAdvanced}) _advanceRuntimeLayer(
    double dt,
    double battleDt, {
    required bool foreground,
  }) {
    final previousBannerSuppression = _suppressRuntimeBanners;
    _suppressRuntimeBanners = previousBannerSuppression || !foreground;
    try {
      if (activeLayerPassiveOnly) {
        return (
          busy:
              _enemies.isNotEmpty ||
              _pulses.isNotEmpty ||
              _shots.isNotEmpty ||
              _impacts.isNotEmpty,
          fabricationAdvanced: false,
        );
      }
      if (foreground) {
        _prepareLocalhostAutoTapper();
      }
      _recoverCoreEnergy(dt);
      _recoverLumenHarvest(dt);
      elapsed += battleDt;
      _advanceShots(battleDt);
      _advanceImpacts(battleDt);

      _core = _core.copyWith(
        fireCooldownRemaining: max(0.0, _core.fireCooldownRemaining - battleDt),
        packetCooldownRemaining: max(
          0.0,
          _core.packetCooldownRemaining - battleDt,
        ),
      );
      if (coreAutoGenerationUnlocked) {
        _advanceCorePayloadFeed(battleDt);
      }
      if (_layer2.unlocked) {
        _layer2 = _layer2.copyWith(
          fireCooldownRemaining: max(
            0.0,
            _layer2.fireCooldownRemaining - battleDt,
          ),
        );
      }

      if (activeLayer.layer3TrialActive) {
        _advanceLayer3Trial(battleDt);
      } else if (_swarmActivated &&
          _battleSpawnPolicy == LightcoreBattleSpawnPolicy.automatic) {
        _spawnTimer -= battleDt;
        while (_spawnTimer <= 0) {
          if (_enemies.length >= enemyTargetCount) {
            _spawnTimer = 0.12;
            break;
          }
          _spawnEnemy();
          _spawnTimer += _spawnInterval;
        }
      }
      _primeThreatChallengeFocusTarget();

      final fabricationAdvanced = _advanceTowerFabrication(dt);
      _advanceTowers(battleDt);
      _advancePersistentShieldRings(battleDt);
      if (foreground) {
        _activateLocalhostReadyTowers();
      }
      _advancePulses(battleDt);
      _advanceFocusTarget(battleDt);
      _advanceEnemies(battleDt);
      _advanceThreatRegionChallenge(battleDt);
      _advanceThreatRegionFarmValidation(battleDt);
      if (_focusedEnemyId != null || coreAutoFireUnlocked) {
        _fireCoreIfPossible(allowDefaultShot: false);
      }
      _fireLayer2IfPossible();
      _updateFlowEfficiency();
      if (foreground) {
        _syncTutorialStep(showBanner: false);
      }

      final runtimeIsBusy =
          builtTowerCount > 0 ||
          _slots.any((tower) => tower.isFabricating) ||
          _enemies.isNotEmpty ||
          _pulses.isNotEmpty ||
          _shots.isNotEmpty ||
          _impacts.isNotEmpty;

      return (busy: runtimeIsBusy, fabricationAdvanced: fabricationAdvanced);
    } finally {
      _suppressRuntimeBanners = previousBannerSuppression;
    }
  }

  void _prepareLocalhostAutoTapper() {
    if (!_localhostAutoTapperEnabled || _outerRingRevealed) {
      return;
    }
    _outerRingRevealed = true;
    _swarmActivated = true;
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;
    _needsNotify = true;
  }

  void _activateLocalhostReadyTowers() {
    if (!_localhostAutoTapperEnabled || !_outerRingRevealed) {
      return;
    }
    for (var index = 0; index < _slots.length; index++) {
      final tower = _slots[index];
      if (cardForSlot(tower) != null) {
        continue;
      }
      final activatedTower = _towerAfterActivation(tower);
      if (activatedTower == null) {
        continue;
      }
      final completesSecondShellShotTutorial =
          _tutorialStep == LightcoreTutorialStep.tapSecondShellTower &&
          _secondShellShotTutorialSlotIndex() == index;
      _slots[index] = activatedTower;
      if (completesSecondShellShotTutorial) {
        _tutorialSecondShellShotTapLearned = true;
      }
      _swarmActivated = true;
      _needsNotify = true;
    }
  }

  void _advanceCorePayloadFeed(double dt) {
    if (dt <= 0) {
      return;
    }
    final interval = corePayloadFeedInterval();
    var feedCooldown = _core.automationCooldownRemaining - dt;
    if (feedCooldown <= 0 &&
        _floatingPulseCountForSource(null) < _maxFloatingPayloadsPerSource) {
      _queueCoreBasicAttack(showBanner: false);
      feedCooldown = interval;
    }
    _core = _core.copyWith(automationCooldownRemaining: feedCooldown);
  }

  double get _spawnInterval => _spawnIntervalForDeck(activeEnemyDeck);

  double _spawnIntervalForDeck(List<EnemyCardState> deck) {
    final pressure = min(1.0, elapsed / 115);
    final ringBoost = builtTowerCount * 0.018;
    final tierBoost = (activeLayer.tier - 1) * 0.09;
    final layer2Boost = _layer2.unlocked ? 0.08 : 0;
    final managerBoost = _enemySpawnPressureMultiplier(deck: deck);
    final targetSpan = enemyTargetMax - minEnemyTarget;
    final targetPressure = targetSpan <= 0
        ? 1.0
        : ((enemyTargetCount - minEnemyTarget) / targetSpan).clamp(0.0, 1.0);
    final targetSlowdown = 1.22 - (0.32 * targetPressure);
    final openingSlowdown = activeLayer.tier == 1
        ? (_earlyTutorialComplete ? 1.08 : 1.22)
        : 1.0;
    return max(
          0.36,
          ((1.68 - (pressure * 0.62) - ringBoost - tierBoost - layer2Boost) /
                  managerBoost) *
              openingSlowdown,
        ) *
        targetSlowdown;
  }

  double get _spawnRadiusBandVariance =>
      (_spawnRadiusBandCount - 1) * _spawnRadiusBandSpacing;

  double get _spawnCrowdRadiusBonus {
    final crowdCount = max(enemyTargetCount, _enemies.length);
    return max(0, crowdCount - initialEnemyTarget) * _spawnCrowdRadiusPerEnemy;
  }

  double get _currentSpawnBaseRadius {
    final crowdBufferedSpawn = _minimumSpawnRadius + _spawnCrowdRadiusBonus;
    final existingEnemyFloor = _enemies.fold<double>(
      0,
      (furthest, enemy) =>
          max(furthest, enemy.radius - _spawnRadiusBandVariance),
    );
    return max(crowdBufferedSpawn, existingEnemyFloor);
  }

  bool _advanceTowerFabrication(
    double dt, {
    bool showCompletionBanners = true,
  }) {
    final serverNowMillis = _trustedServerNowMillis;
    if (dt <= 0 && serverNowMillis == null) {
      return false;
    }
    var changed = false;
    for (var index = 0; index < _slots.length; index++) {
      final tower = _slots[index];
      if (!tower.isFabricating) {
        continue;
      }
      final remaining =
          _serverAnchoredFabricationRemainingSeconds(tower, serverNowMillis) ??
          max(0.0, tower.fabricationRemainingSeconds - dt);
      if (remaining == tower.fabricationRemainingSeconds) {
        continue;
      }
      final completed = remaining == 0;
      _slots[index] = tower.copyWith(
        fabricationRemainingSeconds: remaining,
        charge: completed ? 0.12 : tower.charge,
      );
      if (completed) {
        _totalTowersBuilt += 1;
        if (selectedSlotIndex == index) {
          _towerRangePreviewSlotIndex = index;
        }
        if (showCompletionBanners) {
          _showBanner(
            '${towerDisplayName(tower)} fabrication complete on hex ${index + 1}.',
            category: LightcoreNotificationCategory.battle,
          );
        }
        _syncTutorialStep(showBanner: false);
      }
      changed = true;
    }
    return changed;
  }

  int? get _trustedServerNowMillis {
    final anchor = _serverClockAnchorMillis;
    if (anchor == null) {
      return null;
    }
    return anchor + _serverClockElapsed.elapsedMilliseconds;
  }

  double? _serverAnchoredFabricationRemainingSeconds(
    OuterTowerState tower,
    int? serverNowMillis,
  ) {
    final completesAt = tower.fabricationCompletesAtServerMillis;
    if (serverNowMillis == null || completesAt == null) {
      return null;
    }
    return max(0.0, (completesAt - serverNowMillis) / 1000);
  }

  bool _reconcileServerAnchoredTowerFabrication({
    bool showCompletionBanners = true,
  }) {
    if (_trustedServerNowMillis == null || _layers.isEmpty) {
      return false;
    }

    _storeActiveLayer();
    final viewedLayerId = _viewLayerId;
    var changed = false;
    for (final layer in List<TowerLayerSnapshot>.from(_layers)) {
      _runtimeLayerId = layer.id;
      if (_activeLayerId != layer.id) {
        _loadLayer(layer);
      }
      changed =
          _advanceTowerFabrication(
            0,
            showCompletionBanners: showCompletionBanners,
          ) ||
          changed;
      _storeActiveLayer();
    }

    if (_activeLayerId != viewedLayerId) {
      _loadLayer(_layerById(viewedLayerId));
    }
    _runtimeLayerId = _liveLayerForLayer(_layerById(viewedLayerId)).id;
    return changed;
  }

  bool _advanceOfflineTowerFabrication(
    double seconds, {
    bool showCompletionBanners = true,
  }) {
    if (seconds <= 0 || _layers.isEmpty) {
      return false;
    }

    _storeActiveLayer();
    final viewedLayerId = _viewLayerId;
    var changed = false;
    for (final layer in List<TowerLayerSnapshot>.from(_layers)) {
      _runtimeLayerId = layer.id;
      if (_activeLayerId != layer.id) {
        _loadLayer(layer);
      }
      changed =
          _advanceTowerFabrication(
            seconds,
            showCompletionBanners: showCompletionBanners,
          ) ||
          changed;
      _storeActiveLayer();
    }

    if (_activeLayerId != viewedLayerId) {
      _loadLayer(_layerById(viewedLayerId));
    }
    _runtimeLayerId = _liveLayerForLayer(_layerById(viewedLayerId)).id;
    return changed;
  }

  void _advanceTowers(double dt) {
    for (var index = 0; index < _slots.length; index++) {
      final tower = _slots[index];
      if (!_slotCountsTowardRing(tower)) {
        continue;
      }

      final cooledDown = max(0.0, tower.cooldownRemaining - dt);
      final reducedDisruption = max(
        0.0,
        tower.disruption - (dt * _towerDisruptionRecovery(tower)),
      );
      final liveTower = tower.copyWith(
        cooldownRemaining: cooledDown,
        disruption: reducedDisruption,
      );
      if (towerUsesPersistentShieldRing(liveTower)) {
        _slots[index] = liveTower.copyWith(
          charge: 0,
          automationCooldownRemaining: 0,
        );
        continue;
      }
      final charge = min(
        1.35,
        tower.charge + (towerLiveChargeRate(liveTower) * dt),
      );
      var nextTower = liveTower.copyWith(charge: charge);

      final feedInterval = coreAutoGenerationUnlocked
          ? towerPayloadFeedInterval(nextTower)
          : null;
      if (feedInterval == null) {
        nextTower = nextTower.copyWith(automationCooldownRemaining: 0);
      } else {
        var feedCooldown = nextTower.automationCooldownRemaining - dt;
        if (feedCooldown <= 0) {
          final activatedTower = _towerAfterActivation(nextTower);
          if (activatedTower != null) {
            nextTower = activatedTower;
            if (_tutorialStep == LightcoreTutorialStep.autoQueueCheck &&
                _tutorialAutoQueuedPulses < 5) {
              _tutorialAutoQueuedPulses += 1;
            }
          }
          feedCooldown = feedInterval;
        }
        nextTower = nextTower.copyWith(
          automationCooldownRemaining: feedCooldown,
        );
      }

      _slots[index] = nextTower;
    }
  }

  void _advancePersistentShieldRings(double dt) {
    if (dt <= 0 || _enemies.isEmpty) {
      return;
    }
    for (final tower in _slots) {
      if (!towerUsesPersistentShieldRing(tower)) {
        continue;
      }
      final ringRadius = towerShieldRingRadius(tower);
      const bandHalfWidth = _shieldHaloGuardBandHalfWidth;
      final targets = _enemies
          .where((enemy) {
            final collisionRadius = _enemyCollisionRadius(enemy);
            return (enemy.radius - ringRadius).abs() <=
                bandHalfWidth + collisionRadius;
          })
          .toList(growable: false);
      for (final enemy in targets) {
        final damage = _persistentShieldRingDamageAgainstEnemy(
          tower,
          enemy,
          dt,
        );
        _applyDamage(
          enemy.id,
          damage,
          _slotAffinity(tower),
          layer2: false,
          secondaryAffinity: _slotSecondaryAffinity(tower),
          sourceSlotIndex: tower.slotIndex,
          projectileType: ProjectileType.shieldHalo,
          payloadType: _slotPayloadType(tower),
          applyPayloadEffects: false,
          applyProjectileFollowUp: false,
          spawnImpact: false,
          impactAngle: enemy.angle,
          impactRadius: enemy.radius,
        );
      }
    }
  }

  double _persistentShieldRingDamageAgainstEnemy(
    OuterTowerState tower,
    EnemyState enemy,
    double dt,
  ) {
    final affinity = _slotAffinity(tower);
    final affinityScale = _affinityMultiplierAgainstEnemy(affinity, enemy);
    if (affinityScale <= 0) {
      return 0;
    }
    final towerAffinityScale = affinityScale > 1
        ? _slotAffinityBonusMultiplier(tower)
        : 1.0;
    final averageDamageRange =
        (towerMinDamageMultiplier(tower) + towerMaxDamageMultiplier(tower)) / 2;
    final damagePerSecond =
        towerPower(tower) *
        towerFinalDamageMultiplier(tower) *
        towerDotDamageMultiplier(tower) *
        averageDamageRange *
        _enemyTypeDamageMultiplier(
          target: enemy,
          normalDamageMultiplier: towerNormalDamageMultiplier(tower),
          bossDamageMultiplier: towerBossDamageMultiplier(tower),
        ) *
        _projectileDamageMultiplier(ProjectileType.shieldHalo) *
        affinityScale *
        (affinityScale > 1 ? towerAdvantageMultiplier(tower) : 1.0) *
        towerAffinityScale *
        _persistentShieldRingDamagePerSecondMultiplier;
    return _applyDefenseReduction(
      damagePerSecond * dt,
      enemy,
      defensePenetration: towerDefensePenetration(tower),
    );
  }

  OuterTowerState? _towerAfterActivation(OuterTowerState tower) {
    if (!canActivateTower(tower)) {
      return null;
    }
    final projectileType = _slotProjectileType(tower);
    final payloadType = _slotPayloadType(tower);
    final pulseId = 'pulse_${_pulseCounter++}';
    _pulses.add(
      EnergyPulseState(
        id: pulseId,
        sourceSlotIndex: tower.slotIndex,
        affinity: _slotAffinityForProjectile(tower, projectileType),
        secondaryAffinity: _slotSecondaryAffinityForPayload(tower, payloadType),
        power: towerPower(tower),
        advantageMultiplier: towerAdvantageMultiplier(tower),
        projectileType: projectileType,
        payloadType: payloadType,
        targetPriority: towerTargetPriorityForProjectile(tower, projectileType),
        range: towerEffectiveRangeForProjectile(tower, projectileType),
        generationSpeed: towerGenerationSpeed(tower),
        critChance: towerCritChance(tower),
        critMultiplier: towerCritMultiplier(tower),
        finalDamageMultiplier: towerFinalDamageMultiplier(tower),
        bossDamageMultiplier: towerBossDamageMultiplier(tower),
        normalDamageMultiplier: towerNormalDamageMultiplier(tower),
        defensePenetration: towerDefensePenetration(tower),
        minDamageMultiplier: towerMinDamageMultiplier(tower),
        maxDamageMultiplier: towerMaxDamageMultiplier(tower),
        progress: 0,
      ),
    );
    return tower.copyWith(
      charge: 0,
      cooldownRemaining: towerLiveCooldownForProjectile(tower, projectileType),
      fireSequence: tower.fireSequence + 1,
    );
  }

  void _advancePulses(double dt) {
    final nextPulses = <EnergyPulseState>[];
    for (final pulse in _pulses) {
      final startingProgress = max(0.0, pulse.progress);
      final progress =
          startingProgress +
          (dt *
              _pulseSpeed *
              pulse.generationSpeed *
              _projectilePulseSpeedMultiplier(pulse.projectileType));
      if (progress >= 1) {
        if (_ammoQueue.length < coreQueueCapacity) {
          _ammoQueue.add(
            AmmoPacket(
              id: pulse.id,
              sourceSlotIndex: pulse.sourceSlotIndex,
              affinity: pulse.affinity,
              secondaryAffinity: pulse.secondaryAffinity,
              power: pulse.power,
              advantageMultiplier: pulse.advantageMultiplier,
              projectileType: pulse.projectileType,
              payloadType: pulse.payloadType,
              targetPriority: pulse.targetPriority,
              range: pulse.range,
              critChance: pulse.critChance,
              critMultiplier: pulse.critMultiplier,
              finalDamageMultiplier: pulse.finalDamageMultiplier,
              bossDamageMultiplier: pulse.bossDamageMultiplier,
              normalDamageMultiplier: pulse.normalDamageMultiplier,
              defensePenetration: pulse.defensePenetration,
              minDamageMultiplier: pulse.minDamageMultiplier,
              maxDamageMultiplier: pulse.maxDamageMultiplier,
              criticalBoosted: pulse.criticalBoosted,
            ),
          );
        } else {
          nextPulses.add(pulse.copyWith(progress: 0.985));
        }
      } else {
        nextPulses.add(
          pulse.copyWith(
            progress: progress,
            inboundStartedAtElapsed: pulse.inboundStartedAtElapsed,
          ),
        );
      }
    }
    _pulses
      ..clear()
      ..addAll(nextPulses);
  }

  double _applyDefenseReduction(
    double damage,
    EnemyState target, {
    required double defensePenetration,
  }) {
    final effectiveDefense =
        target.defense * (1 - defensePenetration).clamp(0.0, 1.0);
    return damage * (100 / (100 + effectiveDefense));
  }

  void tick(double dt) {
    final battleDt =
        dt * _baseBattleSpeedMultiplier * _advanceManualOverdrive(dt);
    _notifyAccumulator += dt;
    _refreshBattlePassesForToday(showBanner: true);
    _drainBanner(dt);
    _advanceLevelUpRadiance(dt);
    _storeActiveLayer();

    final viewedLayerId = _viewLayerId;
    final startingLumens = lumens;
    final startingFlux = flux;
    final startingEnemyTickets = enemyTickets;
    final startingBossTickets = bossTickets;
    final startingThreatShards = threatShards;
    final startingExperience = experience;
    final startingKills = kills;
    var runtimeIsBusy = false;
    var fabricationAdvanced = false;
    _totalBattleSeconds += battleDt;

    for (final layer in List<TowerLayerSnapshot>.from(_layers)) {
      _runtimeLayerId = layer.id;
      if (_activeLayerId != layer.id) {
        _loadLayer(layer);
      }
      final result = _advanceRuntimeLayer(
        dt,
        battleDt,
        foreground: layer.id == viewedLayerId,
      );
      runtimeIsBusy = runtimeIsBusy || result.busy;
      fabricationAdvanced = fabricationAdvanced || result.fabricationAdvanced;
      _storeActiveLayer();
    }

    if (_activeLayerId != viewedLayerId) {
      _loadLayer(_layerById(viewedLayerId));
    }
    _runtimeLayerId = _liveLayerForLayer(_layerById(viewedLayerId)).id;

    final resourcesChanged =
        lumens != startingLumens ||
        flux != startingFlux ||
        enemyTickets != startingEnemyTickets ||
        bossTickets != startingBossTickets ||
        threatShards != startingThreatShards ||
        experience != startingExperience ||
        kills != startingKills;

    _maybeNotify(
      force:
          runtimeIsBusy ||
          fabricationAdvanced ||
          resourcesChanged ||
          levelUpRadianceActive ||
          _bannerTimer > 0,
    );
  }

  @visibleForTesting
  PlayerEquipmentItem debugGrantEquipmentDropForEnemy(
    EnemyState enemy, {
    EquipmentInventorySlot? slotType,
    ManagerRarity? rarity,
    int? level,
  }) {
    final item = _buildEquipmentDrop(
      enemy,
      slotType: slotType,
      rarity: rarity,
      level: level,
    );
    _equipmentInventory.add(item);
    _trackNewEquipmentItem(item);
    _enforceEquipmentInventoryCap();
    _notifyNow();
    return item;
  }

  @visibleForTesting
  void debugApplyLumenHarvestDamage(double damage) {
    _applyLumenHarvestDamage(damage);
  }

  @visibleForTesting
  void debugAdvanceLumenHarvestRecovery(double dt) {
    _recoverLumenHarvest(dt);
  }
}
