part of '../lightcore_controller.dart';

const int _coreBlueFocusTargetKey = -1;

extension LightcoreControllerCombatFiring on LightcoreController {
  bool get canFirePrismRiftAimedShot =>
      !activeLayerPassiveOnly &&
      _core.fireCooldownRemaining <= 0 &&
      _enemies.isNotEmpty;

  double get prismRiftAimedShotCharge {
    final projectileType = _coreProjectileType;
    final cooldown = coreShotCooldownForUpgradeLevel(
      _core.fireSpeedUpgradeLevel,
      projectileType: projectileType,
    );
    if (cooldown <= 0) {
      return 1;
    }
    return (1 - (_core.fireCooldownRemaining / cooldown))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  bool firePrismRiftAimedShot({required double aimDx, required double aimDy}) {
    if (!canFirePrismRiftAimedShot) {
      return false;
    }

    final aimAngle = _prismRiftAimAngle(aimDx: aimDx, aimDy: aimDy);
    final volleyCount = coreMultiShotCountForUpgradeLevel(
      _core.multiShotUpgradeLevel,
    );
    var nextFireSequence = _core.fireSequence;
    var cooldownAfterVolley = 0.0;
    var firedShots = 0;
    final volleyTargetIds = <String>{};

    for (var shotIndex = 0; shotIndex < volleyCount; shotIndex += 1) {
      final projectileType = _coreProjectileTypeForSequence(nextFireSequence);
      final payloadType = _corePayloadTypeForSequence(nextFireSequence);
      final shotMaxRange = coreEffectiveRangeForUpgradeLevel(
        _core.rangeUpgradeLevel,
        projectileType: projectileType,
      );
      final target =
          _targetForPrismRiftAim(
            aimAngle,
            preferredMaxRadius: shotMaxRange,
            excludedEnemyIds: volleyTargetIds,
          ) ??
          _nearestEnemy(excludedEnemyIds: volleyTargetIds);
      if (target == null) {
        break;
      }

      final affinity = _coreAffinityForProjectile(projectileType);
      final secondaryAffinity = _coreSecondaryAffinityForPayload(payloadType);
      final basicImpact = _shotUsesCoreBasicImpact(
        layer2: false,
        projectileType: projectileType,
        sourceSlotIndex: null,
      );
      _shots.add(
        CoreShotState(
          id: 'shot_${_shotCounter++}',
          enemyId: target.id,
          affinity: affinity,
          secondaryAffinity: secondaryAffinity,
          power:
              _coreBasicShotPower() *
              friendAllianceCombatMultiplier *
              _projectileDamageMultiplier(projectileType) *
              _gearPowerMultiplier,
          projectileType: projectileType,
          payloadType: payloadType,
          progress: 0,
          layer2: false,
          critChance: (_coreBaseCritChance + _gearCritChanceBonus).clamp(
            0.02,
            0.55,
          ),
          critMultiplier: _coreBaseCritMultiplier * _gearCritDamageMultiplier,
          critical: false,
          aimAngle: aimAngle,
          travelRadius: _shotTravelRadiusForProjectile(
            projectileType,
            targetRadius: target.radius,
            maxRange: shotMaxRange,
            basicImpact: basicImpact,
          ),
          bossDamageMultiplier: _gearBossDamageMultiplier,
        ),
      );

      cooldownAfterVolley = max(
        cooldownAfterVolley,
        coreShotCooldownForUpgradeLevel(
          _core.fireSpeedUpgradeLevel,
          projectileType: projectileType,
        ),
      );
      nextFireSequence += 1;
      volleyTargetIds.add(target.id);
      firedShots += 1;
    }

    if (firedShots == 0) {
      return false;
    }

    _core = _core.copyWith(
      fireCooldownRemaining: cooldownAfterVolley,
      fireSequence: nextFireSequence,
    );
    _needsNotify = true;
    _notifyNow();
    return true;
  }

  double _prismRiftAimAngle({required double aimDx, required double aimDy}) {
    final magnitude = sqrt((aimDx * aimDx) + (aimDy * aimDy));
    if (magnitude <= 0.001) {
      return _normalizeAngle(-pi / 2);
    }
    return _normalizeAngle(atan2(aimDy / magnitude, aimDx / magnitude));
  }

  EnemyState? _targetForPrismRiftAim(
    double aimAngle, {
    required double preferredMaxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    EnemyState? bestTarget;
    var bestScore = double.infinity;
    for (final enemy in _enemies) {
      if (excludedEnemyIds.contains(enemy.id)) {
        continue;
      }
      final distance = _angleDistance(enemy.angle, aimAngle);
      if (distance > pi * 0.55) {
        continue;
      }
      final lateralOffset = sin(distance).abs() * enemy.radius;
      final rangePenalty = max(0.0, enemy.radius - preferredMaxRadius) * 0.12;
      final score =
          lateralOffset +
          (distance * 10) +
          rangePenalty +
          (enemy.radius * 0.01) -
          (enemy.config.isBoss ? 8 : 0);
      if (score < bestScore) {
        bestScore = score;
        bestTarget = enemy;
      }
    }
    return bestTarget;
  }

  double _angleDistance(double first, double second) {
    final delta = (_normalizeAngle(first - second) + pi) % (pi * 2) - pi;
    return delta.abs();
  }

  bool _fireCoreIfPossible({bool allowDefaultShot = true}) {
    if (_core.fireCooldownRemaining > 0 || _enemies.isEmpty) {
      return false;
    }

    final volleyCount = coreMultiShotCountForUpgradeLevel(
      _core.multiShotUpgradeLevel,
    );
    var nextFireSequence = _core.fireSequence;
    var cooldownAfterVolley = 0.0;
    var firedShots = 0;
    final volleyTargetIds = <String>{};

    for (var shotIndex = 0; shotIndex < volleyCount; shotIndex++) {
      if (_enemies.isEmpty) {
        break;
      }

      PrototypeAffinity affinity;
      PrototypeAffinity? secondaryAffinity;
      ProjectileType projectileType;
      PayloadType payloadType;
      double shotPower;
      double energySpend;
      int? sourceSlotIndex;
      double cooldownMultiplier = 1.0;
      double critChance;
      double critMultiplier;
      EnemyState? target;
      double advantageMultiplier = 1.0;
      double bossDamageMultiplier = 1.0;
      double normalDamageMultiplier = 1.0;
      double defensePenetration = 0;
      double shotMaxRange;
      var advancesCoreSequence = false;

      if (_ammoQueue.isNotEmpty) {
        final ammoIndex = _bestAmmoIndex(excludedTargetIds: volleyTargetIds);
        if (ammoIndex == null) {
          break;
        }
        final ammo = _ammoQueue.removeAt(ammoIndex);
        final coreRoutedRange = coreEffectiveRangeForUpgradeLevel(
          _core.rangeUpgradeLevel,
          projectileType: ammo.projectileType,
        );
        shotMaxRange = max(ammo.range, coreRoutedRange);
        target = _ammoUsesBlueFocusLaser(ammo)
            ? _targetForBlueFocusPacket(
                ammo,
                maxRadius: shotMaxRange,
                excludedEnemyIds: volleyTargetIds,
              )
            : _targetForPriority(
                    ammo.targetPriority,
                    maxRadius: shotMaxRange,
                    sourceSlotIndex: ammo.sourceSlotIndex,
                    excludedEnemyIds: volleyTargetIds,
                  ) ??
                  _nearestEnemyForSource(
                    maxRadius: shotMaxRange,
                    sourceSlotIndex: ammo.sourceSlotIndex,
                    excludedEnemyIds: volleyTargetIds,
                  );
        if (target == null) {
          break;
        }
        final sourceTower = ammo.sourceSlotIndex == null
            ? null
            : _slots[ammo.sourceSlotIndex!];
        affinity = ammo.affinity;
        secondaryAffinity = ammo.secondaryAffinity;
        projectileType = ammo.projectileType;
        payloadType = ammo.payloadType;
        sourceSlotIndex = ammo.sourceSlotIndex;
        advantageMultiplier = ammo.advantageMultiplier;
        bossDamageMultiplier = ammo.bossDamageMultiplier;
        normalDamageMultiplier = ammo.normalDamageMultiplier;
        defensePenetration = ammo.defensePenetration;
        critChance = ammo.critChance;
        critMultiplier = ammo.critMultiplier;
        cooldownMultiplier =
            sourceTower != null && _slotCountsTowardRing(sourceTower)
            ? _slotCoreCooldownMultiplier(sourceTower)
            : 1.0;
        shotPower =
            ammo.power *
            ammo.finalDamageMultiplier *
            _sampleDamageRangeMultiplier(
              ammo.minDamageMultiplier,
              ammo.maxDamageMultiplier,
            ) *
            _projectileDamageMultiplier(projectileType) *
            _coreEnergyOutputMultiplier;
        if (_ammoUsesBlueFocusLaser(ammo)) {
          shotPower *= _blueFocusLaserDamageMultiplier;
        }
        energySpend = 3 + (payloadType == PayloadType.none ? 0 : 1);
      } else {
        if (!allowDefaultShot) {
          break;
        }
        projectileType = _coreProjectileTypeForSequence(nextFireSequence);
        payloadType = _corePayloadTypeForSequence(nextFireSequence);
        shotMaxRange = coreEffectiveRangeForUpgradeLevel(
          _core.rangeUpgradeLevel,
          projectileType: projectileType,
        );
        target = _nearestEnemy(
          maxRadius: shotMaxRange,
          excludedEnemyIds: volleyTargetIds,
        );
        if (target == null) {
          break;
        }
        affinity = _coreAffinityForProjectile(projectileType);
        secondaryAffinity = _coreSecondaryAffinityForPayload(payloadType);
        sourceSlotIndex = null;
        bossDamageMultiplier = coreBossDamageMultiplier;
        normalDamageMultiplier = coreNormalDamageMultiplier;
        defensePenetration = coreDefensePenetration;
        critChance = coreCritChance;
        critMultiplier = coreCritMultiplier;
        shotPower =
            coreBasicShotPower *
            friendAllianceCombatMultiplier *
            coreFinalDamageMultiplier *
            _sampleDamageRangeMultiplier(
              coreMinDamageMultiplier,
              coreMaxDamageMultiplier,
            ) *
            _projectileDamageMultiplier(projectileType) *
            _gearPowerMultiplier *
            _coreEnergyOutputMultiplier;
        energySpend = 5 + (payloadType == PayloadType.none ? 0 : 1);
        advancesCoreSequence = true;
      }

      final aimPoint = _leadShotAimPoint(
        target,
        projectileType: projectileType,
        layer2: false,
        affinity: affinity,
        maxRange: shotMaxRange,
        sourceSlotIndex: sourceSlotIndex,
      );
      _shots.add(
        CoreShotState(
          id: 'shot_${_shotCounter++}',
          enemyId: target.id,
          affinity: affinity,
          secondaryAffinity: secondaryAffinity,
          power: shotPower,
          projectileType: projectileType,
          payloadType: payloadType,
          progress: 0,
          layer2: false,
          critChance: critChance,
          critMultiplier: critMultiplier,
          critical: false,
          aimAngle: aimPoint.angle,
          travelRadius: _shotTravelRadiusForProjectile(
            projectileType,
            targetRadius: aimPoint.radius,
            maxRange: shotMaxRange,
            basicImpact: _shotUsesCoreBasicImpact(
              layer2: false,
              projectileType: projectileType,
              sourceSlotIndex: sourceSlotIndex,
            ),
          ),
          sourceSlotIndex: sourceSlotIndex,
          advantageMultiplier: advantageMultiplier,
          bossDamageMultiplier: bossDamageMultiplier,
          normalDamageMultiplier: normalDamageMultiplier,
          defensePenetration: defensePenetration,
        ),
      );

      final shotCooldown =
          coreShotCooldownForUpgradeLevel(
            _core.fireSpeedUpgradeLevel,
            projectileType: projectileType,
          ) *
          cooldownMultiplier;
      cooldownAfterVolley = max(cooldownAfterVolley, shotCooldown);
      if (advancesCoreSequence) {
        nextFireSequence += 1;
      }
      _spendCoreEnergy(energySpend);
      volleyTargetIds.add(target.id);
      firedShots += 1;
    }

    if (firedShots == 0) {
      return false;
    }

    _core = _core.copyWith(
      fireCooldownRemaining: cooldownAfterVolley,
      fireSequence: nextFireSequence,
    );
    return true;
  }

  void _fireLayer2IfPossible() {
    if (!_layer2.unlocked ||
        _layer2.fireCooldownRemaining > 0 ||
        _enemies.isEmpty) {
      return;
    }

    final layerRange =
        _averageRangeForLayer(activeLayer) *
        _projectileRangeMultiplier(_layer2.projectileType);
    final target = _nearestEnemy(maxRadius: layerRange);
    if (target == null) {
      return;
    }

    var shotPower =
        (8 + (_layer2.count * 2.4) + (builtTowerCount * 1.2)) *
        _towerDamageOutputMultiplier *
        friendAllianceCombatMultiplier *
        _averageFinalDamageForLayer(activeLayer) *
        _sampleDamageRangeMultiplier(
          _averageMinDamageForLayer(activeLayer),
          _averageMaxDamageForLayer(activeLayer),
        ) *
        _projectileDamageMultiplier(_layer2.projectileType);
    final critChance = _averageCritChanceForLayer(activeLayer);
    final critMultiplier = _averageCritMultiplierForLayer(activeLayer);
    final aimPoint = _leadShotAimPoint(
      target,
      projectileType: _layer2.projectileType,
      layer2: true,
      affinity: _layer2.affinity,
      maxRange: layerRange,
    );
    _shots.add(
      CoreShotState(
        id: 'shot_${_shotCounter++}',
        enemyId: target.id,
        affinity: _layer2.affinity,
        power: shotPower,
        projectileType: _layer2.projectileType,
        payloadType: _layer2.payloadType,
        progress: 0,
        layer2: true,
        critChance: critChance,
        critMultiplier: critMultiplier,
        critical: false,
        aimAngle: aimPoint.angle,
        travelRadius: _shotTravelRadiusForProjectile(
          _layer2.projectileType,
          targetRadius: aimPoint.radius,
          maxRange: layerRange,
        ),
        bossDamageMultiplier: _averageBossDamageForLayer(activeLayer),
        normalDamageMultiplier: _averageNormalDamageForLayer(activeLayer),
        defensePenetration: _averageDefensePenetrationForLayer(activeLayer),
      ),
    );
    _layer2 = _layer2.copyWith(
      fireCooldownRemaining:
          0.78 * _projectileCooldownMultiplier(_layer2.projectileType),
    );
  }

  EnemyState? _nearestEnemy({
    double? maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    if (_enemies.isEmpty) {
      return null;
    }

    final boss = _priorityBossTarget(
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
    );
    if (boss != null) {
      return boss;
    }

    EnemyState? closest;
    for (final enemy in _enemies) {
      if (excludedEnemyIds.contains(enemy.id)) {
        continue;
      }
      if (maxRadius != null && enemy.radius > maxRadius) {
        continue;
      }
      if (closest == null || enemy.radius < closest.radius) {
        closest = enemy;
      }
    }
    return closest;
  }

  EnemyState? _priorityBossTarget({
    double? maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    EnemyState? closestBoss;
    for (final enemy in _enemies) {
      if (excludedEnemyIds.contains(enemy.id)) {
        continue;
      }
      if (!enemy.config.isBoss) {
        continue;
      }
      if (maxRadius != null && enemy.radius > maxRadius) {
        continue;
      }
      if (closestBoss == null || enemy.radius < closestBoss.radius) {
        closestBoss = enemy;
      }
    }
    return closestBoss;
  }

  int? _bestAmmoIndex({Set<String> excludedTargetIds = const <String>{}}) {
    int? bestIndex;
    var bestScore = -double.infinity;
    for (var index = 0; index < _ammoQueue.length; index++) {
      final packet = _ammoQueue[index];
      final target =
          _targetForPriority(
            packet.targetPriority,
            maxRadius: packet.range,
            sourceSlotIndex: packet.sourceSlotIndex,
            excludedEnemyIds: excludedTargetIds,
          ) ??
          _nearestEnemyForSource(
            maxRadius: packet.range,
            sourceSlotIndex: packet.sourceSlotIndex,
            excludedEnemyIds: excludedTargetIds,
          );
      if (target == null) {
        continue;
      }
      final affinityScale = _affinityMultiplierAgainstEnemy(
        packet.affinity,
        target,
      );
      final sourceTower = packet.sourceSlotIndex == null
          ? null
          : _slots[packet.sourceSlotIndex!];
      final towerAffinityScale =
          affinityScale > 1 &&
              sourceTower != null &&
              _slotCountsTowardRing(sourceTower)
          ? _slotAffinityBonusMultiplier(sourceTower)
          : 1.0;
      final score =
          packet.power *
          packet.finalDamageMultiplier *
          _enemyTypeDamageMultiplier(
            target: target,
            normalDamageMultiplier: packet.normalDamageMultiplier,
            bossDamageMultiplier: packet.bossDamageMultiplier,
          ) *
          affinityScale *
          (affinityScale > 1 ? packet.advantageMultiplier : 1) *
          towerAffinityScale *
          (1 - (target.defense * (1 - packet.defensePenetration)) / 300).clamp(
            0.2,
            1.0,
          );
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  EnemyState? _targetForPriority(
    TargetPriority priority, {
    double? maxRadius,
    int? sourceSlotIndex,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    if (_enemies.isEmpty) {
      return null;
    }
    final boss = _priorityBossTarget(
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
    );
    if (boss != null) {
      return boss;
    }
    switch (priority) {
      case TargetPriority.close:
        return _nearestEnemyForSource(
          maxRadius: maxRadius,
          sourceSlotIndex: sourceSlotIndex,
          excludedEnemyIds: excludedEnemyIds,
        );
      case TargetPriority.strong:
        EnemyState? strongest;
        for (final enemy in _enemies) {
          if (excludedEnemyIds.contains(enemy.id)) {
            continue;
          }
          if (maxRadius != null && enemy.radius > maxRadius) {
            continue;
          }
          if (strongest == null || enemy.health > strongest.health) {
            strongest = enemy;
          }
        }
        return strongest;
      case TargetPriority.weak:
        EnemyState? weakest;
        for (final enemy in _enemies) {
          if (excludedEnemyIds.contains(enemy.id)) {
            continue;
          }
          if (maxRadius != null && enemy.radius > maxRadius) {
            continue;
          }
          if (weakest == null || enemy.health < weakest.health) {
            weakest = enemy;
          }
        }
        return weakest;
    }
  }

  EnemyState? _targetForBlueFocusPacket(
    AmmoPacket packet, {
    required double maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    final sourceSlotIndex = packet.sourceSlotIndex;
    final focusTargetKey = sourceSlotIndex ?? _coreBlueFocusTargetKey;
    final lockedEnemyId = _blueFocusTargetEnemyIdBySlot[focusTargetKey];
    if (lockedEnemyId != null) {
      final lockedEnemy = _enemyById(lockedEnemyId);
      if (lockedEnemy != null &&
          lockedEnemy.radius <= maxRadius &&
          !excludedEnemyIds.contains(lockedEnemy.id)) {
        return lockedEnemy;
      }
      if (lockedEnemy == null || lockedEnemy.radius > maxRadius) {
        _blueFocusTargetEnemyIdBySlot.remove(focusTargetKey);
      }
    }

    final target =
        _targetForPriority(
          packet.targetPriority,
          maxRadius: maxRadius,
          sourceSlotIndex: sourceSlotIndex,
          excludedEnemyIds: excludedEnemyIds,
        ) ??
        _nearestEnemyForSource(
          maxRadius: maxRadius,
          sourceSlotIndex: sourceSlotIndex,
          excludedEnemyIds: excludedEnemyIds,
        );
    if (target != null) {
      _blueFocusTargetEnemyIdBySlot[focusTargetKey] = target.id;
    }
    return target;
  }

  EnemyState? _nearestSecondaryEnemy(EnemyState origin, {double? maxRadius}) {
    EnemyState? closest;
    var closestDistance = double.infinity;
    for (final enemy in _enemies) {
      if (enemy.id == origin.id) {
        continue;
      }
      if (maxRadius != null && enemy.radius > maxRadius) {
        continue;
      }
      final distance = _enemyDistance(origin, enemy);
      if (distance < closestDistance ||
          (distance == closestDistance &&
              (closest == null || enemy.radius < closest.radius))) {
        closest = enemy;
        closestDistance = distance;
      }
    }
    return closest;
  }

  EnemyState? _nearestEnemyForSource({
    double? maxRadius,
    int? sourceSlotIndex,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    if (sourceSlotIndex == null) {
      return _nearestEnemy(
        maxRadius: maxRadius,
        excludedEnemyIds: excludedEnemyIds,
      );
    }
    return _nearestEnemyToSlot(
      sourceSlotIndex,
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
    );
  }

  EnemyState? _nearestEnemyToSlot(
    int sourceSlotIndex, {
    double? maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    if (_enemies.isEmpty) {
      return null;
    }

    EnemyState? closest;
    var closestDistance = double.infinity;
    for (final enemy in _enemies) {
      if (excludedEnemyIds.contains(enemy.id)) {
        continue;
      }
      if (maxRadius != null && enemy.radius > maxRadius) {
        continue;
      }
      final distance = _enemyDistanceToSlot(enemy, sourceSlotIndex);
      if (distance < closestDistance ||
          (distance == closestDistance &&
              (closest == null || enemy.radius < closest.radius))) {
        closest = enemy;
        closestDistance = distance;
      }
    }
    return closest;
  }

  double _enemyDistanceToSlot(EnemyState enemy, int sourceSlotIndex) {
    final slot = _slotModelPosition(sourceSlotIndex);
    final enemyX = cos(enemy.angle) * enemy.radius;
    final enemyY = sin(enemy.angle) * enemy.radius;
    final dx = enemyX - slot.x;
    final dy = enemyY - slot.y;
    return sqrt((dx * dx) + (dy * dy));
  }

  ({double x, double y}) _slotModelPosition(int sourceSlotIndex) {
    final slotIndex = sourceSlotIndex % slotCount;
    final (q, r) = switch (slotIndex) {
      0 => (1.0, 0.0),
      1 => (1.0, -1.0),
      2 => (0.0, -1.0),
      3 => (-1.0, 0.0),
      4 => (-1.0, 1.0),
      _ => (0.0, 1.0),
    };
    return (
      x: _relayImpactRadius * (q + (r / 2)),
      y: _relayImpactRadius * ((sqrt(3) / 2) * r),
    );
  }

  Iterable<EnemyState> _nearbyEnemies(
    EnemyState origin, {
    required double within,
  }) {
    return _enemies.where((enemy) {
      if (enemy.id == origin.id) {
        return false;
      }
      final distance = _enemyDistance(origin, enemy);
      return distance <= within;
    });
  }
}
