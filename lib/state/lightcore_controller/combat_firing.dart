part of '../lightcore_controller.dart';

const int _coreBlueFocusTargetKey = -1;

extension LightcoreControllerCombatFiring on LightcoreController {
  void _advanceFocusTarget(double dt) {
    _focusTargetCooldownRemaining = max(0, _focusTargetCooldownRemaining - dt);
    final focusedId = _focusedEnemyId;
    if (focusedId == null) {
      return;
    }
    final stillAlive = _enemies.any((enemy) => enemy.id == focusedId);
    if (!stillAlive) {
      _clearFocusTarget();
      return;
    }
    _focusTargetRemainingSeconds = max(0, _focusTargetRemainingSeconds - dt);
    if (_focusTargetRemainingSeconds <= 0) {
      _clearFocusTarget();
    }
  }

  void _clearFocusTarget() {
    _focusedEnemyId = null;
    _focusTargetRemainingSeconds = 0;
  }

  void _primeThreatChallengeFocusTarget() {
    final challenge = _threatRegionChallenge;
    if (challenge == null ||
        coreAutoFireUnlocked ||
        _focusedEnemyId != null ||
        _enemies.isEmpty ||
        _threatChallengeAutoFocusedWaveIndex == challenge.waveIndex) {
      return;
    }
    final target = _enemies.reduce(
      (closest, enemy) => enemy.radius < closest.radius ? enemy : closest,
    );
    _focusedEnemyId = target.id;
    _focusTargetRemainingSeconds = focusTargetDurationSeconds;
    _threatChallengeAutoFocusedWaveIndex = challenge.waveIndex;
    _needsNotify = true;
  }

  EnemyState? _focusedEnemyTarget({
    double? maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    final focusedId = _focusedEnemyId;
    if (focusedId == null || excludedEnemyIds.contains(focusedId)) {
      return null;
    }
    final enemy = _enemyById(focusedId);
    if (enemy == null) {
      _clearFocusTarget();
      return null;
    }
    if (maxRadius != null && enemy.radius > maxRadius) {
      return null;
    }
    return enemy;
  }

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
              _gearPowerMultiplier *
              _coreEnergyOutputMultiplier,
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
      var criticalBoosted = false;
      var advancesCoreSequence = false;

      final firedQueuedPacket = _ammoQueue.isNotEmpty;
      if (firedQueuedPacket) {
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
            : _automaticTargetForPacket(
                ammo,
                maxRadius: shotMaxRange,
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
        if (ammo.criticalBoosted) {
          critChance = 1.0;
          criticalBoosted = true;
        }
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
        target = _automaticTarget(
          maxRadius: shotMaxRange,
          excludedEnemyIds: volleyTargetIds,
          affinity: affinity,
          sourceSlotIndex: sourceSlotIndex,
          power: shotPower,
          advantageMultiplier: advantageMultiplier,
          bossDamageMultiplier: bossDamageMultiplier,
          normalDamageMultiplier: normalDamageMultiplier,
          defensePenetration: defensePenetration,
        );
        if (target == null) {
          break;
        }
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
          criticalBoosted: criticalBoosted,
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
    if (!_tutorialFocusFireLearned) {
      _tutorialFocusFireLearned = true;
      _applyOpeningPressureLessonIfNeeded();
    }
    return true;
  }

  EnemyState? _nearestEnemy({
    double? maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    if (_enemies.isEmpty) {
      return null;
    }

    final focused = _focusedEnemyTarget(
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
    );
    if (focused != null) {
      return focused;
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
      final coreRoutedRange = coreEffectiveRangeForUpgradeLevel(
        _core.rangeUpgradeLevel,
        projectileType: packet.projectileType,
      );
      final target = _automaticTargetForPacket(
        packet,
        maxRadius: max(packet.range, coreRoutedRange),
        excludedEnemyIds: excludedTargetIds,
      );
      if (target == null) {
        continue;
      }
      final score = _automaticTargetScoreForPacket(packet, target);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  EnemyState? _automaticTargetForPacket(
    AmmoPacket packet, {
    required double maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    return _automaticTarget(
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
      affinity: packet.affinity,
      sourceSlotIndex: packet.sourceSlotIndex,
      power: packet.power * packet.finalDamageMultiplier,
      advantageMultiplier: packet.advantageMultiplier,
      bossDamageMultiplier: packet.bossDamageMultiplier,
      normalDamageMultiplier: packet.normalDamageMultiplier,
      defensePenetration: packet.defensePenetration,
    );
  }

  EnemyState? _automaticTarget({
    required double maxRadius,
    required PrototypeAffinity affinity,
    required double power,
    double advantageMultiplier = 1,
    double bossDamageMultiplier = 1,
    double normalDamageMultiplier = 1,
    double defensePenetration = 0,
    int? sourceSlotIndex,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    if (_enemies.isEmpty) {
      return null;
    }
    final focused = _focusedEnemyTarget(
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
    );
    if (focused != null) {
      return focused;
    }

    EnemyState? best;
    var bestScore = -double.infinity;
    for (final enemy in _enemies) {
      if (excludedEnemyIds.contains(enemy.id) || enemy.radius > maxRadius) {
        continue;
      }
      final score = _automaticTargetScore(
        enemy,
        affinity: affinity,
        power: power,
        advantageMultiplier: advantageMultiplier,
        bossDamageMultiplier: bossDamageMultiplier,
        normalDamageMultiplier: normalDamageMultiplier,
        defensePenetration: defensePenetration,
        sourceSlotIndex: sourceSlotIndex,
        maxRadius: maxRadius,
      );
      if (score > bestScore ||
          (score == bestScore &&
              (best == null || enemy.radius < best.radius))) {
        bestScore = score;
        best = enemy;
      }
    }
    return best;
  }

  double _automaticTargetScoreForPacket(AmmoPacket packet, EnemyState target) {
    return _automaticTargetScore(
      target,
      affinity: packet.affinity,
      power: packet.power * packet.finalDamageMultiplier,
      advantageMultiplier: packet.advantageMultiplier,
      bossDamageMultiplier: packet.bossDamageMultiplier,
      normalDamageMultiplier: packet.normalDamageMultiplier,
      defensePenetration: packet.defensePenetration,
      sourceSlotIndex: packet.sourceSlotIndex,
      maxRadius: packet.range,
    );
  }

  double _automaticTargetScore(
    EnemyState enemy, {
    required PrototypeAffinity affinity,
    required double power,
    required double advantageMultiplier,
    required double bossDamageMultiplier,
    required double normalDamageMultiplier,
    required double defensePenetration,
    required double maxRadius,
    int? sourceSlotIndex,
  }) {
    final affinityScale = _affinityMultiplierAgainstEnemy(affinity, enemy);
    final sourceTower = sourceSlotIndex == null
        ? null
        : _slots[sourceSlotIndex];
    final towerAffinityScale =
        affinityScale > 1 &&
            sourceTower != null &&
            _slotCountsTowardRing(sourceTower)
        ? _slotAffinityBonusMultiplier(sourceTower)
        : 1.0;
    final effectiveDamage =
        power *
        _enemyTypeDamageMultiplier(
          target: enemy,
          normalDamageMultiplier: normalDamageMultiplier,
          bossDamageMultiplier: bossDamageMultiplier,
        ) *
        affinityScale *
        (affinityScale > 1 ? advantageMultiplier : 1) *
        towerAffinityScale *
        (1 - (enemy.defense * (1 - defensePenetration)) / 300).clamp(0.2, 1.0);
    final killPressure = effectiveDamage / max(1.0, enemy.health);
    final lanePressure = (1 - (enemy.radius / max(1.0, maxRadius))).clamp(
      0.0,
      1.0,
    );
    final sourcePressure = sourceSlotIndex == null
        ? 0.0
        : (1 -
                  (_enemyDistanceToSlot(enemy, sourceSlotIndex) /
                      max(1.0, maxRadius)))
              .clamp(0.0, 1.0)
              .toDouble();
    final bossPressure = enemy.config.isBoss ? 1.35 : 1.0;
    return (killPressure * 2.2 + lanePressure + sourcePressure) * bossPressure;
  }

  EnemyState? _targetForBlueFocusPacket(
    AmmoPacket packet, {
    required double maxRadius,
    Set<String> excludedEnemyIds = const <String>{},
  }) {
    final focused = _focusedEnemyTarget(
      maxRadius: maxRadius,
      excludedEnemyIds: excludedEnemyIds,
    );
    if (focused != null) {
      return focused;
    }
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

    final target = _automaticTargetForPacket(
      packet,
      maxRadius: maxRadius,
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
