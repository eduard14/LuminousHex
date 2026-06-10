part of '../lightcore_controller.dart';

extension LightcoreControllerCombatFollowups on LightcoreController {
  void _applyProjectileFollowUp({
    required EnemyState origin,
    required double damage,
    required PrototypeAffinity affinity,
    PrototypeAffinity? secondaryAffinity,
    required ProjectileType projectileType,
    required PayloadType payloadType,
    required int? sourceSlotIndex,
  }) {
    switch (projectileType.behaviorProfile) {
      case ProjectileBehaviorProfile.thread:
      case ProjectileBehaviorProfile.pulse:
      case ProjectileBehaviorProfile.lance:
        return;
      case ProjectileBehaviorProfile.burst:
        for (final enemy in <EnemyState>[
          origin,
          ..._nearbyEnemies(origin, within: 42).take(2),
        ]) {
          _applyDamage(
            enemy.id,
            damage * (enemy.id == origin.id ? 0.18 : 0.12),
            affinity,
            layer2: false,
            secondaryAffinity: secondaryAffinity,
            sourceSlotIndex: sourceSlotIndex,
          );
        }
      case ProjectileBehaviorProfile.chain:
        final nextTarget = _nearestSecondaryEnemy(origin);
        if (nextTarget != null) {
          if (projectileType == ProjectileType.chainArc) {
            _applyDamage(
              nextTarget.id,
              damage * 0.42,
              affinity,
              layer2: false,
              secondaryAffinity: secondaryAffinity,
              sourceSlotIndex: sourceSlotIndex,
              projectileType: projectileType,
              payloadType: payloadType,
              applyProjectileFollowUp: false,
              impactAngle: nextTarget.angle,
              impactRadius: nextTarget.radius,
              chainSourceAngle: origin.angle,
              chainSourceRadius: origin.radius,
            );
          } else {
            _applyDamage(
              nextTarget.id,
              damage * 0.42,
              affinity,
              layer2: false,
              secondaryAffinity: secondaryAffinity,
              sourceSlotIndex: sourceSlotIndex,
            );
          }
        }
      case ProjectileBehaviorProfile.split:
        for (final enemy in _nearbyEnemies(
          origin,
          within: 68,
        ).take(2).toList()) {
          _applyDamage(
            enemy.id,
            damage * 0.26,
            affinity,
            layer2: false,
            secondaryAffinity: secondaryAffinity,
            sourceSlotIndex: sourceSlotIndex,
          );
        }
      case ProjectileBehaviorProfile.explosion:
        for (final enemy in _nearbyEnemies(
          origin,
          within: _projectileSplashRadius(projectileType),
        ).toList()) {
          _applyDamage(
            enemy.id,
            damage * 0.28,
            affinity,
            layer2: false,
            secondaryAffinity: secondaryAffinity,
            sourceSlotIndex: sourceSlotIndex,
          );
        }
      case ProjectileBehaviorProfile.wave:
        for (final enemy in _nearbyEnemies(origin, within: 84).toList()) {
          _applyDamage(
            enemy.id,
            damage * 0.22,
            affinity,
            layer2: false,
            secondaryAffinity: secondaryAffinity,
            sourceSlotIndex: sourceSlotIndex,
          );
        }
      case ProjectileBehaviorProfile.nova:
        for (final enemy in _nearbyEnemies(
          origin,
          within: _projectileSplashRadius(projectileType),
        ).toList()) {
          _applyDamage(
            enemy.id,
            damage * 0.34,
            affinity,
            layer2: false,
            secondaryAffinity: secondaryAffinity,
            sourceSlotIndex: sourceSlotIndex,
          );
        }
    }
  }

  void _spawnSplitChildren(EnemyState enemy) {
    final source = enemyCardById(enemy.sourceCardId);
    if (source == null) {
      return;
    }

    final availableSlots = max(0, enemyTargetCount - _enemies.length);
    if (availableSlots == 0) {
      return;
    }

    var spawnedChildren = 0;
    for (final direction in [-1.0, 1.0].take(availableSlots)) {
      _enemies.add(
        _buildEnemyFromCard(
          source.copyWith(level: enemy.cardLevel),
          angle: enemy.angle + (0.18 * direction),
          radius: max(_relayImpactRadius + 12, enemy.radius - 14),
          splitDepth: enemy.splitDepth + 1,
          angularJitter: 0.36 * direction,
        ),
      );
      spawnedChildren += 1;
    }
    _showBanner(
      spawnedChildren == 1
          ? 'Purple Hexer split into one child body.'
          : 'Purple Hexer split into two child bodies.',
      category: LightcoreNotificationCategory.battle,
    );
  }

  void _registerRelayHit(EnemyState enemy) {
    _failLayer3Trial();
    relayHitListener?.call(enemy);
    final slotIndex = _slotIndexForAngle(enemy.angle);
    final tower = _slots[slotIndex];
    final slotAngle = _slotAngle(slotIndex);
    final occupiedLaneHitDamage =
        enemy.jamStrength *
        _relayHitLumenHarvestDamageScale *
        _relayHitHealthDamageFactor(enemy, emptyLane: false);
    final emptyLaneHitDamage =
        enemy.jamStrength *
        _emptyLaneLumenHarvestDamageScale *
        _relayHitHealthDamageFactor(enemy, emptyLane: true);
    _impacts.add(
      ImpactState(
        id: 'impact_${_impactCounter++}',
        affinity: enemy.config.affinity,
        projectileType: ProjectileType.threadBeam,
        payloadType: PayloadType.none,
        angle: slotAngle,
        radius: _relayImpactRadius,
        progress: 0,
        lethal: false,
        towerHit: true,
        critical: false,
      ),
    );

    if (_slotCountsTowardRing(tower)) {
      final jamAmount =
          enemy.jamStrength *
          _slotJamHitMultiplier(tower) *
          _queueDisruptionMultiplierForEnemy(enemy);
      final nextDisruption = min(1.25, tower.disruption + jamAmount);
      final nextCharge = max(0.0, tower.charge - (enemy.jamStrength * 0.28));
      _applyLumenHarvestDamage(occupiedLaneHitDamage, source: enemy);
      _slots[slotIndex] = tower.copyWith(
        disruption: nextDisruption,
        charge: nextCharge,
      );
      if (nextDisruption >= 0.82) {
        _showBanner(
          'Hex ${slotIndex + 1} is heavily jammed. Green recovers best while Yellow protects payout.',
          category: LightcoreNotificationCategory.battle,
        );
      }
    } else {
      if (_ammoQueue.isNotEmpty) {
        _ammoQueue.removeAt(0);
      }
      _applyLumenHarvestDamage(
        emptyLaneHitDamage,
        source: enemy,
        emptyLane: true,
      );
      _showBanner(
        'Empty lane ${slotIndex + 1} disrupted core charge and bruised Core Stability.',
        category: LightcoreNotificationCategory.battle,
      );
    }
  }

  double _relayHitHealthDamageFactor(
    EnemyState enemy, {
    required bool emptyLane,
  }) {
    final healthRatio = (enemy.health / max(0.001, enemy.maxHealth))
        .clamp(0.0, 1.0)
        .toDouble();
    return emptyLane
        ? 0.30 + (0.70 * healthRatio)
        : 0.20 + (0.80 * healthRatio);
  }

  int _slotIndexForAngle(double angle) {
    final sectorSize = (pi * 2) / slotCount;
    final shifted = _normalizeAngle(angle + (pi / 2));
    return (shifted / sectorSize).round() % slotCount;
  }

  double _slotAngle(int slotIndex) {
    return (((pi * 2) / slotCount) * slotIndex) - (pi / 2);
  }

  double _queueDisruptionMultiplierForEnemy(EnemyState enemy) {
    final manager = enemyManagerForCard(enemy.sourceCardId);
    final card =
        enemyCardById(enemy.sourceCardId) ??
        bossEnemyCardById(enemy.sourceCardId);
    final effect = card == null
        ? 1.0
        : _enemyManagerEffectMultiplier(card, manager);
    return _managerValue(1, manager?.queueDisruptionMultiplier ?? 1, effect);
  }

  double _normalizeAngle(double angle) {
    var normalized = angle % (pi * 2);
    if (normalized < 0) {
      normalized += pi * 2;
    }
    return normalized;
  }

  double _towerDisruptionRecovery(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    return 0.12 * _slotJamDecayMultiplier(tower);
  }

  void _applyLumenHarvestDamage(
    double damage, {
    EnemyState? source,
    bool emptyLane = false,
  }) {
    if (damage <= 0) {
      return;
    }
    final stabilityDamage = source == null
        ? damage
        : damage * _stabilityDamageMultiplierForEnemy(source, emptyLane);
    _registerCoreDamage(stabilityDamage);
    _setCoreStability(_core.coreStability - stabilityDamage);
  }

  void _registerCoreDamage(double stabilityDamage) {
    if (stabilityDamage <= 0) {
      return;
    }
    final layerId = _runtimeLayerId;
    _coreDamageSequencesByLayer[layerId] =
        (_coreDamageSequencesByLayer[layerId] ?? 0) + 1;
    _coreDamageAmountsByLayer[layerId] = stabilityDamage;
    _needsNotify = true;
  }

  double _stabilityDamageMultiplierForEnemy(EnemyState enemy, bool emptyLane) {
    final manager = enemyManagerForCard(enemy.sourceCardId);
    final card =
        enemyCardById(enemy.sourceCardId) ??
        bossEnemyCardById(enemy.sourceCardId);
    final managerEffect = card == null
        ? 1.0
        : _enemyManagerEffectMultiplier(card, manager);
    final directorMultiplier = _managerValue(
      1,
      manager?.stabilityDamageMultiplier ?? 1,
      managerEffect,
    );
    final apexMultiplier = enemy.config.isBoss
        ? (_apexBaseStabilityDamageMultiplier +
                  (enemy.config.rarity.index *
                      _apexRarityStabilityDamageStep)) *
              _directorApexStabilityMultiplier()
        : 1.0;
    final emptyLaneMultiplier = emptyLane ? 1.18 : 1.0;
    return enemy.config.stabilityDamageMultiplier *
        directorMultiplier *
        apexMultiplier *
        emptyLaneMultiplier *
        (1 - _stabilityGuardReduction()).clamp(0.35, 1.0);
  }

  double _stabilityGuardReduction() {
    final built = _slots.where(_slotCountsTowardRing).toList();
    if (built.isEmpty) {
      return 0;
    }
    final guardTotal = built.fold(
      0.0,
      (sum, tower) => sum + max(0, tower.config?.lumenPressureGuard ?? 0),
    );
    final managerGuard = _managedTowerCountForLayer(activeLayer) * 0.012;
    return ((guardTotal / built.length) + managerGuard).clamp(0.0, 0.55);
  }

  void _setCoreStability(double value) {
    final stability = value.clamp(0.0, _maxCoreStability).toDouble();
    final outputEfficiency = _outputEfficiencyPercentForStability(stability);
    _core = _core.copyWith(
      coreStability: stability,
      flowEfficiency: outputEfficiency,
    );
    _lumenHarvestSlowdown = (1 - (outputEfficiency / 100)).clamp(
      0.0,
      _maxLumenHarvestSlowdown,
    );
    if (_layerRun.active && stability <= 0) {
      endLayer1RunFromCoreBreak();
    }
  }

  void _recoverLumenHarvest(double dt) {
    if (dt <= 0 || _core.coreStability >= _maxCoreStability) {
      return;
    }
    _setCoreStability(
      _core.coreStability +
          (coreStabilityRecoveryPerSecond *
              _coreEnergyStabilityRecoveryMultiplier *
              dt),
    );
  }

  void _recoverCoreEnergy(double dt) {
    if (!coreEnergyUnlocked || dt <= 0) {
      return;
    }
    final capacity = coreEnergyCapacity;
    if (_core.coreEnergy >= capacity) {
      return;
    }
    _core = _core.copyWith(
      coreEnergy: min(
        capacity,
        _core.coreEnergy + (coreEnergyRecoveryPerSecond * dt),
      ),
    );
  }

  void _spendCoreEnergy(double amount) {
    if (!coreEnergyUnlocked || amount <= 0) {
      return;
    }
    _core = _core.copyWith(coreEnergy: max(0.0, _core.coreEnergy - amount));
  }

  double _normalEnemyRarityHealthScale(EnemyCardRarity rarity) =>
      switch (rarity) {
        EnemyCardRarity.basic => 1.0,
        EnemyCardRarity.uncommon => 60.0,
        EnemyCardRarity.rare => 5000.0,
        EnemyCardRarity.epic => 150000.0,
        EnemyCardRarity.legendary => 12000000.0,
      };

  double _normalEnemyLevelHealthGrowth(EnemyCardRarity rarity) =>
      switch (rarity) {
        EnemyCardRarity.basic => 1.11,
        EnemyCardRarity.uncommon => 1.13,
        EnemyCardRarity.rare => 1.18,
        EnemyCardRarity.epic => 1.35,
        EnemyCardRarity.legendary => 2.3,
      };

  double _normalEnemyRarityDefenseScale(EnemyCardRarity rarity) =>
      switch (rarity) {
        EnemyCardRarity.basic => 1.0,
        EnemyCardRarity.uncommon => 1.8,
        EnemyCardRarity.rare => 3.6,
        EnemyCardRarity.epic => 8.0,
        EnemyCardRarity.legendary => 16.0,
      };

  double _enemyCardThreatScale(EnemyCardState source) {
    if (source.config.isBoss) {
      return 1 + ((source.level - 1) * 0.32);
    }
    return _normalEnemyRarityHealthScale(source.config.rarity) *
        pow(
          _normalEnemyLevelHealthGrowth(source.config.rarity),
          max(0, source.level - 1),
        ).toDouble();
  }

  double _enemyCardDefenseScale(EnemyCardState source) {
    if (source.config.isBoss) {
      return 1 + ((source.level - 1) * 0.16);
    }
    final rarityScale = _normalEnemyRarityDefenseScale(source.config.rarity);
    final levelScale = pow(1.035, max(0, source.level - 1)).toDouble();
    return rarityScale * levelScale;
  }

  double _enemyCardLumenScale(EnemyCardState source) {
    if (source.config.isBoss) {
      return pow(1.06, max(0, source.level - 1)).toDouble();
    }
    return pow(_enemyCardThreatScale(source), 0.68).toDouble();
  }

  double _enemyCardExperienceScale(EnemyCardState source) {
    if (source.config.isBoss) {
      return 1 + ((source.level - 1) * 0.18);
    }
    return pow(_enemyCardThreatScale(source), 0.60).toDouble();
  }

  double _enemyCardLevelSpeedScale(int level) => 1 + ((level - 1) * 0.04);

  int _experienceRewardForEnemyCard(
    EnemyCardState source, {
    int splitDepth = 0,
    EnemyManagerState? manager,
    double? managerEffect,
  }) {
    final config = source.config;
    final resolvedManager = manager ?? enemyManagerForCard(config.id);
    final resolvedManagerEffect =
        managerEffect ?? _enemyManagerEffectMultiplier(source, resolvedManager);
    return max(
      1,
      (_balancedEnemyStat(
                config,
                'baseExperience',
                config.baseExperience.toDouble(),
              ) *
              _enemyCardExperienceScale(source) *
              (splitDepth > 0 ? 0.62 : 1) *
              (config.isBoss ? 2.2 + ((activeLayer.tier - 1) * 0.45) : 1.0) *
              _managerValue(
                1,
                resolvedManager?.experienceMultiplier ?? 1,
                resolvedManagerEffect,
              ))
          .round(),
    );
  }
}
