part of '../lightcore_controller.dart';

const double _persistentShieldRingDamagePerSecondMultiplier = 0.28;

extension LightcoreControllerCombatLoop on LightcoreController {
  ({bool busy, bool fabricationAdvanced}) _advanceRuntimeLayer(
    double dt,
    double battleDt, {
    required bool foreground,
  }) {
    final previousBannerSuppression = _suppressRuntimeBanners;
    _suppressRuntimeBanners = previousBannerSuppression || !foreground;
    try {
      if (foreground) {
        _prepareLocalhostAutoTapper();
      }
      _recoverLumenHarvest(dt);
      elapsed += battleDt;
      _advanceShots(battleDt);
      _advanceImpacts(battleDt);

      _core = _core.copyWith(
        fireCooldownRemaining: max(0.0, _core.fireCooldownRemaining - battleDt),
      );
      if (_layer2.unlocked) {
        _layer2 = _layer2.copyWith(
          fireCooldownRemaining: max(
            0.0,
            _layer2.fireCooldownRemaining - battleDt,
          ),
        );
      }

      if (_swarmActivated) {
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

      final fabricationAdvanced = _advanceTowerFabrication(dt);
      _advanceTowers(battleDt);
      _advancePersistentShieldRings(battleDt);
      if (foreground) {
        _activateLocalhostReadyTowers();
      }
      _advancePulses(battleDt);
      if (foreground) {
        _queueLocalhostCoreTap(battleDt);
      }
      _advanceEnemies(battleDt);
      _fireCoreIfPossible(allowDefaultShot: false);
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

  void _queueLocalhostCoreTap(double dt) {
    if (!_localhostAutoTapperEnabled || !_outerRingRevealed) {
      _localhostAutoTapperCoreCooldown = 0;
      return;
    }
    _localhostAutoTapperCoreCooldown = max(
      0.0,
      _localhostAutoTapperCoreCooldown - dt,
    );
    if (_localhostAutoTapperCoreCooldown > 0 ||
        _enemies.isEmpty ||
        (_ammoQueue.length + _pulses.length) >= coreQueueCapacity) {
      return;
    }
    if (_queueCoreBasicAttack(showBanner: false)) {
      _swarmActivated = true;
      _localhostAutoTapperCoreCooldown = _localhostAutoTapperCoreInterval;
      _needsNotify = true;
    }
  }

  double get _spawnInterval {
    final pressure = min(1.0, elapsed / 115);
    final ringBoost = builtTowerCount * 0.018;
    final tierBoost = (activeLayer.tier - 1) * 0.09;
    final layer2Boost = _layer2.unlocked ? 0.08 : 0;
    final managerBoost = _enemySpawnPressureMultiplier();
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

  bool _advanceTowerFabrication(double dt) {
    if (dt <= 0) {
      return false;
    }
    var changed = false;
    for (var index = 0; index < _slots.length; index++) {
      final tower = _slots[index];
      if (!tower.isFabricating) {
        continue;
      }
      final remaining = max(0.0, tower.fabricationRemainingSeconds - dt);
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
        _showBanner(
          '${towerDisplayName(tower)} fabrication complete on hex ${index + 1}.',
        );
        _syncTutorialStep(showBanner: false);
      }
      changed = true;
    }
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

      final automationInterval = towerAutomationInterval(nextTower);
      if (automationInterval == null) {
        nextTower = nextTower.copyWith(automationCooldownRemaining: 0);
      } else {
        var automationCooldown = nextTower.automationCooldownRemaining - dt;
        if (automationCooldown <= 0) {
          final activatedTower = _towerAfterActivation(nextTower);
          if (activatedTower != null) {
            nextTower = activatedTower;
            if (_tutorialStep == LightcoreTutorialStep.autoQueueCheck &&
                _tutorialAutoQueuedPulses < 5) {
              _tutorialAutoQueuedPulses += 1;
            }
          }
          automationCooldown = automationInterval;
        }
        nextTower = nextTower.copyWith(
          automationCooldownRemaining: automationCooldown,
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
      final bandHalfWidth = max(24.0, ringRadius * 0.1);
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
    _pulses.add(
      EnergyPulseState(
        id: 'pulse_${_pulseCounter++}',
        sourceSlotIndex: tower.slotIndex,
        affinity: _slotAffinity(tower),
        secondaryAffinity: _slotSecondaryAffinity(tower),
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
      final progress =
          pulse.progress +
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
            ),
          );
        }
      } else {
        nextPulses.add(pulse.copyWith(progress: progress));
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
    final startingBossCores = bossCores;
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
    _runtimeLayerId = viewedLayerId;

    final resourcesChanged =
        lumens != startingLumens ||
        flux != startingFlux ||
        enemyTickets != startingEnemyTickets ||
        bossTickets != startingBossTickets ||
        bossCores != startingBossCores ||
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
