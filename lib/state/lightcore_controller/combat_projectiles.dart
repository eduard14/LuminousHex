part of '../lightcore_controller.dart';

extension LightcoreControllerCombatProjectiles on LightcoreController {
  void _advanceShots(double dt) {
    final nextShots = <CoreShotState>[];
    for (final shot in _shots) {
      final previousProgress = shot.progress;
      final progress = min(1.0, shot.progress + (dt * _shotSpeedForShot(shot)));
      final nextShot = _shotUsesShieldHalo(shot)
          ? _resolveShieldHaloShotAdvance(shot, progress: progress)
          : _shotUsesOrbitNode(shot)
          ? _resolveOrbitShotAdvance(
              shot,
              previousProgress: previousProgress,
              progress: progress,
            )
          : _shotUsesBlueFocusLaser(shot)
          ? _resolveBlueFocusLaserShotAdvance(shot, progress: progress)
          : _coreShotUsesBasicImpact(shot)
          ? _resolveImpactShotAdvance(
              shot,
              previousProgress: previousProgress,
              progress: progress,
            )
          : shot.projectileType.usesBeamPath
          ? _resolveBeamShotAdvance(
              shot,
              previousProgress: previousProgress,
              progress: progress,
            )
          : shot.projectileType.usesRadialWave
          ? _resolveWaveShotAdvance(
              shot,
              previousProgress: previousProgress,
              progress: progress,
            )
          : _resolveImpactShotAdvance(
              shot,
              previousProgress: previousProgress,
              progress: progress,
            );
      if (progress < 1) {
        nextShots.add(nextShot);
      }
    }
    _shots
      ..clear()
      ..addAll(nextShots);
  }

  bool _shotUsesOrbitNode(CoreShotState shot) =>
      !shot.layer2 &&
      shot.sourceSlotIndex != null &&
      shot.projectileType == ProjectileType.orbitNode;

  bool _shotUsesShieldHalo(CoreShotState shot) =>
      !shot.layer2 &&
      shot.sourceSlotIndex != null &&
      shot.projectileType == ProjectileType.shieldHalo;

  bool _coreShotUsesBasicImpact(CoreShotState shot) => _shotUsesCoreBasicImpact(
    layer2: shot.layer2,
    sourceSlotIndex: shot.sourceSlotIndex,
  );

  bool _shotUsesCoreBasicImpact({
    required bool layer2,
    required int? sourceSlotIndex,
  }) => !layer2 && sourceSlotIndex == null;

  bool _shotUsesBlueFocusLaser(CoreShotState shot) =>
      !shot.layer2 &&
      shot.projectileType == ProjectileType.threadBeam &&
      shot.sourceSlotIndex != null &&
      shot.affinity == PrototypeAffinity.aether;

  bool _ammoUsesBlueFocusLaser(AmmoPacket ammo) =>
      ammo.projectileType == ProjectileType.threadBeam &&
      ammo.sourceSlotIndex != null &&
      ammo.affinity == PrototypeAffinity.aether;

  double _shotSpeedForProjectile(
    ProjectileType projectileType, {
    required bool layer2,
    required PrototypeAffinity affinity,
    int? sourceSlotIndex,
  }) {
    if (!layer2 &&
        sourceSlotIndex != null &&
        projectileType == ProjectileType.orbitNode) {
      return 1.12;
    }
    if (!layer2 &&
        sourceSlotIndex != null &&
        projectileType == ProjectileType.shieldHalo) {
      return 0.9;
    }
    if (!layer2 &&
        projectileType == ProjectileType.threadBeam &&
        sourceSlotIndex != null &&
        affinity == PrototypeAffinity.aether) {
      return 2.08;
    }
    if (projectileType == ProjectileType.pulseRing) {
      return 3.0;
    }
    if (projectileType == ProjectileType.heavyShot) {
      return 2.25;
    }
    return _shotSpeed;
  }

  double _shotSpeedForShot(CoreShotState shot) => _shotSpeedForProjectile(
    shot.projectileType,
    layer2: shot.layer2,
    affinity: shot.affinity,
    sourceSlotIndex: shot.sourceSlotIndex,
  );

  double _orbitNodeAngleForProgress(CoreShotState shot, double progress) =>
      shot.aimAngle + (progress * pi * 2);

  double _orbitNodeTravelRadiusForMaxRange(double maxRange) =>
      min(maxRange, max(120.0, maxRange * 0.72));

  double _orbitNodeRadiusForShot(CoreShotState shot) => shot.travelRadius;

  double _orbitNodeHitRadiusForShot(CoreShotState shot) =>
      max(18.0, shot.travelRadius * 0.075);

  double _shieldHaloTravelRadiusForMaxRange(double maxRange) =>
      _shieldHaloGuardRadiusForMaxRange(maxRange);

  double _shieldHaloBandHalfWidthForShot(CoreShotState shot) =>
      _shieldHaloGuardBandHalfWidth;

  List<double> _sampleAnglesAlongMotion(
    double startAngle,
    double endAngle, {
    double maxStep = pi / 22,
  }) {
    final steps = max(1, ((endAngle - startAngle).abs() / maxStep).ceil());
    return List<double>.generate(
      steps + 1,
      (index) => startAngle + ((endAngle - startAngle) * (index / steps)),
      growable: false,
    );
  }

  CoreShotState _resolveOrbitShotAdvance(
    CoreShotState shot, {
    required double previousProgress,
    required double progress,
  }) {
    final hitEnemyIds = shot.hitEnemyIds.toSet();
    final orbitRadius = _orbitNodeRadiusForShot(shot);
    final hitRadius = _orbitNodeHitRadiusForShot(shot);
    final sampledAngles = _sampleAnglesAlongMotion(
      _orbitNodeAngleForProgress(shot, previousProgress),
      _orbitNodeAngleForProgress(shot, progress),
    );
    final newlyHit = _enemies.where((enemy) {
      if (hitEnemyIds.contains(enemy.id)) {
        return false;
      }
      final collisionRadius = _enemyCollisionRadius(enemy) + hitRadius;
      for (final angle in sampledAngles) {
        if (_polarDistanceToEnemy(enemy, angle: angle, radius: orbitRadius) <=
            collisionRadius) {
          return true;
        }
      }
      return false;
    }).toList();

    for (final enemy in newlyHit) {
      _applyShotDamageToEnemy(
        shot,
        enemy,
        damageMultiplier: 0.92,
        applyProjectileFollowUp: false,
      );
      hitEnemyIds.add(enemy.id);
    }

    return shot.copyWith(
      progress: progress,
      hitEnemyIds: hitEnemyIds.toList(growable: false),
    );
  }

  CoreShotState _resolveShieldHaloShotAdvance(
    CoreShotState shot, {
    required double progress,
  }) {
    final hitEnemyIds = shot.hitEnemyIds.toSet();
    final shieldRadius = shot.travelRadius;
    final bandHalfWidth = _shieldHaloBandHalfWidthForShot(shot);
    final newlyHit = _enemies.where((enemy) {
      if (hitEnemyIds.contains(enemy.id)) {
        return false;
      }
      final collisionRadius = _enemyCollisionRadius(enemy);
      return (enemy.radius - shieldRadius).abs() <=
          bandHalfWidth + collisionRadius;
    }).toList()..sort((a, b) => a.radius.compareTo(b.radius));

    for (final enemy in newlyHit) {
      _applyShotDamageToEnemy(
        shot,
        enemy,
        damageMultiplier: 0.66,
        applyProjectileFollowUp: false,
        impactAngle: enemy.angle,
        impactRadius: enemy.radius,
      );
      hitEnemyIds.add(enemy.id);
    }

    return shot.copyWith(
      progress: progress,
      hitEnemyIds: hitEnemyIds.toList(growable: false),
    );
  }

  CoreShotState _resolveBlueFocusLaserShotAdvance(
    CoreShotState shot, {
    required double progress,
  }) {
    final hitEnemyIds = shot.hitEnemyIds.toSet();
    final target = _enemyById(shot.enemyId);
    if (target == null || hitEnemyIds.contains(target.id)) {
      return shot.copyWith(progress: progress);
    }

    _applyShotDamageToEnemy(
      shot,
      target,
      applyProjectileFollowUp: false,
      impactAngle: target.angle,
      impactRadius: target.radius,
    );
    hitEnemyIds.add(target.id);

    return shot.copyWith(
      progress: progress,
      hitEnemyIds: hitEnemyIds.toList(growable: false),
    );
  }

  CoreShotState _resolveBeamShotAdvance(
    CoreShotState shot, {
    required double previousProgress,
    required double progress,
  }) {
    final startRadius = shot.travelRadius * previousProgress;
    final endRadius = shot.travelRadius * progress;
    final hitEnemyIds = shot.hitEnemyIds.toSet();
    final newlyHit =
        _enemies
            .where(
              (enemy) =>
                  !hitEnemyIds.contains(enemy.id) &&
                  _enemyIntersectsBeamWindow(
                    enemy,
                    angle: shot.aimAngle,
                    startRadius: startRadius,
                    endRadius: endRadius,
                    width: _beamWidthForProjectile(shot.projectileType),
                  ),
            )
            .toList()
          ..sort(
            (a, b) => _enemyProjectionAlongAngle(
              a,
              angle: shot.aimAngle,
            ).compareTo(_enemyProjectionAlongAngle(b, angle: shot.aimAngle)),
          );

    var hitIndex = shot.hitEnemyIds.length;
    for (final enemy in newlyHit) {
      _applyShotDamageToEnemy(
        shot,
        enemy,
        damageMultiplier: _beamPierceDamageMultiplier(
          shot.projectileType,
          hitIndex,
        ),
        applyProjectileFollowUp: false,
      );
      hitEnemyIds.add(enemy.id);
      hitIndex += 1;
    }

    return shot.copyWith(
      progress: progress,
      hitEnemyIds: hitEnemyIds.toList(growable: false),
    );
  }

  CoreShotState _resolveWaveShotAdvance(
    CoreShotState shot, {
    required double previousProgress,
    required double progress,
  }) {
    final startRadius = shot.travelRadius * previousProgress;
    final endRadius = shot.travelRadius * progress;
    final hitEnemyIds = shot.hitEnemyIds.toSet();
    final bandHalfWidth = _waveBandWidthForProjectile(shot.projectileType) / 2;
    final newlyHit = _enemies.where((enemy) {
      if (hitEnemyIds.contains(enemy.id)) {
        return false;
      }
      final collisionRadius = _enemyCollisionRadius(enemy);
      final bufferedHalfWidth = bandHalfWidth + collisionRadius;
      return enemy.radius >= startRadius - bufferedHalfWidth &&
          enemy.radius <= endRadius + bufferedHalfWidth &&
          enemy.radius <= shot.travelRadius + bufferedHalfWidth;
    }).toList()..sort((a, b) => a.radius.compareTo(b.radius));

    for (final enemy in newlyHit) {
      _applyShotDamageToEnemy(
        shot,
        enemy,
        damageMultiplier: _waveSweepDamageMultiplier(shot.projectileType),
        applyProjectileFollowUp: false,
      );
      hitEnemyIds.add(enemy.id);
    }

    return shot.copyWith(
      progress: progress,
      hitEnemyIds: hitEnemyIds.toList(growable: false),
    );
  }

  CoreShotState _resolveImpactShotAdvance(
    CoreShotState shot, {
    required double previousProgress,
    required double progress,
  }) {
    final nextShot = shot.copyWith(progress: progress);
    if (previousProgress < 1 && progress >= 1) {
      _resolveImpactShot(nextShot);
    }
    return nextShot;
  }

  double _shotTravelRadiusForProjectile(
    ProjectileType projectileType, {
    required double targetRadius,
    required double maxRange,
    bool basicImpact = false,
  }) {
    if (!basicImpact && projectileType == ProjectileType.orbitNode) {
      return min(targetRadius, _orbitNodeTravelRadiusForMaxRange(maxRange));
    }
    if (!basicImpact && projectileType == ProjectileType.shieldHalo) {
      return min(targetRadius, _shieldHaloTravelRadiusForMaxRange(maxRange));
    }
    if (!basicImpact &&
        (projectileType.usesBeamPath || projectileType.usesRadialWave)) {
      return maxRange;
    }
    return min(targetRadius, maxRange);
  }

  double _shotLeadTimeForTarget(
    EnemyState target, {
    required ProjectileType projectileType,
    required bool layer2,
    required PrototypeAffinity affinity,
    required double travelRadius,
    int? sourceSlotIndex,
  }) {
    final basicImpact = _shotUsesCoreBasicImpact(
      layer2: layer2,
      sourceSlotIndex: sourceSlotIndex,
    );
    if (!basicImpact &&
        (projectileType.usesRadialWave ||
            (!layer2 && projectileType == ProjectileType.orbitNode))) {
      return 0;
    }

    final shotSpeed = _shotSpeedForProjectile(
      projectileType,
      layer2: layer2,
      affinity: affinity,
      sourceSlotIndex: sourceSlotIndex,
    );
    if (shotSpeed <= 0) {
      return 0;
    }

    if (!basicImpact && projectileType.usesBeamPath) {
      final movementSlowFactor = target.slowRemaining > 0
          ? target.slowFactor
          : 1.0;
      final radialSpeed = target.speed * movementSlowFactor;
      final radialTravelPerSecond = max(1.0, travelRadius * shotSpeed);
      return (target.radius / (radialTravelPerSecond + radialSpeed)).clamp(
        0.0,
        0.75,
      );
    }

    return (1.0 / shotSpeed).clamp(0.0, 0.75);
  }

  ({double angle, double radius}) _predictEnemyPosition(
    EnemyState enemy,
    double seconds,
  ) {
    if (seconds <= 0) {
      return (angle: enemy.angle, radius: enemy.radius);
    }

    var angle = enemy.angle;
    var radius = enemy.radius;
    var slowRemaining = enemy.slowRemaining;
    var remaining = seconds;
    while (remaining > 0) {
      final step = min(remaining, 0.05);
      final movementSlowFactor = slowRemaining > 0 ? enemy.slowFactor : 1.0;
      final progressFactor = (radius / spawnRadius).clamp(0.22, 1.0);
      radius = max(
        _relayImpactRadius,
        radius - (enemy.speed * movementSlowFactor * step),
      );
      angle += enemy.angularVelocity * step * (1.4 - progressFactor);
      slowRemaining = max(0.0, slowRemaining - step);
      remaining -= step;
      if (radius <= _relayImpactRadius) {
        break;
      }
    }

    return (angle: _normalizeAngle(angle), radius: radius);
  }

  ({double angle, double radius}) _leadShotAimPoint(
    EnemyState target, {
    required ProjectileType projectileType,
    required bool layer2,
    required PrototypeAffinity affinity,
    required double maxRange,
    int? sourceSlotIndex,
  }) {
    final travelRadius = _shotTravelRadiusForProjectile(
      projectileType,
      targetRadius: target.radius,
      maxRange: maxRange,
      basicImpact: _shotUsesCoreBasicImpact(
        layer2: layer2,
        sourceSlotIndex: sourceSlotIndex,
      ),
    );
    final leadTime = _shotLeadTimeForTarget(
      target,
      projectileType: projectileType,
      layer2: layer2,
      affinity: affinity,
      travelRadius: travelRadius,
      sourceSlotIndex: sourceSlotIndex,
    );
    return _predictEnemyPosition(target, leadTime);
  }

  double _shotDamageAgainstEnemy(CoreShotState shot, EnemyState enemy) {
    var damage =
        shot.power *
        _enemyTypeDamageMultiplier(
          target: enemy,
          normalDamageMultiplier: shot.normalDamageMultiplier,
          bossDamageMultiplier: shot.bossDamageMultiplier,
        );
    if (shot.sourceSlotIndex != null) {
      final affinityScale = _affinityMultiplierAgainstEnemy(
        shot.affinity,
        enemy,
      );
      final sourceTower = _slots[shot.sourceSlotIndex!];
      final towerAffinityScale =
          affinityScale > 1 && _slotCountsTowardRing(sourceTower)
          ? _slotAffinityBonusMultiplier(sourceTower)
          : 1.0;
      damage *=
          affinityScale *
          (affinityScale > 1 ? shot.advantageMultiplier : 1.0) *
          towerAffinityScale;
    }
    return _applyDefenseReduction(
      damage,
      enemy,
      defensePenetration: shot.defensePenetration,
    );
  }

  void _applyShotDamageToEnemy(
    CoreShotState shot,
    EnemyState enemy, {
    double damageMultiplier = 1,
    ProjectileType? projectileType,
    PayloadType? payloadType,
    bool applyPayloadEffects = true,
    bool applyProjectileFollowUp = true,
    bool spawnImpact = true,
    double? impactAngle,
    double? impactRadius,
  }) {
    _applyDamage(
      enemy.id,
      _shotDamageAgainstEnemy(shot, enemy) * damageMultiplier,
      shot.affinity,
      layer2: shot.layer2,
      secondaryAffinity: shot.secondaryAffinity,
      sourceSlotIndex: shot.sourceSlotIndex,
      projectileType: projectileType ?? shot.projectileType,
      payloadType: payloadType ?? shot.payloadType,
      critical: shot.critical,
      applyPayloadEffects: applyPayloadEffects,
      applyProjectileFollowUp: applyProjectileFollowUp,
      spawnImpact: spawnImpact,
      impactAngle: impactAngle,
      impactRadius: impactRadius,
    );
  }

  void _resolveImpactShot(CoreShotState shot) {
    final basicImpact = _coreShotUsesBasicImpact(shot);
    if (shot.projectileType.behaviorProfile ==
            ProjectileBehaviorProfile.explosion ||
        shot.projectileType.behaviorProfile == ProjectileBehaviorProfile.nova) {
      _resolveBlastShot(shot);
      return;
    }

    final target = _targetNearImpactPoint(shot);
    if (target == null) {
      return;
    }
    _applyShotDamageToEnemy(
      shot,
      target,
      applyProjectileFollowUp: !basicImpact,
      impactAngle: shot.aimAngle,
      impactRadius: shot.travelRadius,
    );
  }

  void _resolveBlastShot(CoreShotState shot) {
    final target = _targetNearImpactPoint(shot);
    final splashRadius = _projectileSplashRadius(shot.projectileType);
    final splashTargets = _enemies
        .where(
          (enemy) =>
              enemy.id != target?.id &&
              _polarDistanceToEnemy(
                    enemy,
                    angle: shot.aimAngle,
                    radius: shot.travelRadius,
                  ) <=
                  splashRadius,
        )
        .toList();
    var spawnedPrimaryImpact = false;
    if (target != null) {
      _applyShotDamageToEnemy(
        shot,
        target,
        applyProjectileFollowUp: false,
        impactAngle: shot.aimAngle,
        impactRadius: shot.travelRadius,
      );
      spawnedPrimaryImpact = true;
    }

    final splashDamageMultiplier = _blastSplashDamageMultiplier(
      shot.projectileType,
    );

    for (final enemy in splashTargets) {
      _applyShotDamageToEnemy(
        shot,
        enemy,
        damageMultiplier: splashDamageMultiplier,
        projectileType: ProjectileType.threadBeam,
        payloadType: PayloadType.none,
        applyPayloadEffects: false,
        applyProjectileFollowUp: false,
        spawnImpact: false,
      );
    }

    if (spawnedPrimaryImpact) {
      return;
    }

    _impacts.add(
      ImpactState(
        id: 'impact_${_impactCounter++}',
        affinity: shot.affinity,
        secondaryAffinity: shot.secondaryAffinity,
        projectileType: shot.projectileType,
        payloadType: shot.payloadType,
        angle: shot.aimAngle,
        radius: shot.travelRadius,
        progress: 0,
        lethal: false,
        towerHit: false,
        critical: shot.critical,
        progressRate: _impactProgressRateForProjectile(
          shot.projectileType,
          lethal: false,
        ),
        fieldRadius: _impactFieldRadiusForProjectile(
          shot.projectileType,
          lethal: false,
        ),
        fieldDamagePerSecond:
            shot.power *
            _sourceTowerDotDamageMultiplier(shot.sourceSlotIndex) *
            _impactFieldDamageMultiplierForProjectile(
              shot.projectileType,
              lethal: false,
            ),
        sourceSlotIndex: shot.sourceSlotIndex,
      ),
    );
  }

  EnemyState? _targetNearImpactPoint(CoreShotState shot) {
    final maxDistance = _impactSearchRadiusForProjectile(shot.projectileType);
    final directTarget = _enemyById(shot.enemyId);
    if (directTarget != null &&
        _polarDistanceToEnemy(
              directTarget,
              angle: shot.aimAngle,
              radius: shot.travelRadius,
            ) <=
            maxDistance) {
      return directTarget;
    }
    return _nearestEnemyToImpactPoint(
      angle: shot.aimAngle,
      radius: shot.travelRadius,
      maxDistance: maxDistance,
    );
  }

  EnemyState? _enemyById(String enemyId) {
    for (final enemy in _enemies) {
      if (enemy.id == enemyId) {
        return enemy;
      }
    }
    return null;
  }

  EnemyState? _nearestEnemyToImpactPoint({
    required double angle,
    required double radius,
    required double maxDistance,
  }) {
    EnemyState? closest;
    var closestDistance = maxDistance;
    for (final enemy in _enemies) {
      final distance = _polarDistanceToEnemy(
        enemy,
        angle: angle,
        radius: radius,
      );
      if (distance > closestDistance) {
        continue;
      }
      closest = enemy;
      closestDistance = distance;
    }
    return closest;
  }

  double _enemyProjectionAlongAngle(EnemyState enemy, {required double angle}) {
    final positionX = cos(enemy.angle) * enemy.radius;
    final positionY = sin(enemy.angle) * enemy.radius;
    return (positionX * cos(angle)) + (positionY * sin(angle));
  }

  double _enemyPerpendicularDistanceToAngle(
    EnemyState enemy, {
    required double angle,
  }) {
    final positionX = cos(enemy.angle) * enemy.radius;
    final positionY = sin(enemy.angle) * enemy.radius;
    return ((positionX * -sin(angle)) + (positionY * cos(angle))).abs();
  }

  bool _enemyIntersectsBeamWindow(
    EnemyState enemy, {
    required double angle,
    required double startRadius,
    required double endRadius,
    required double width,
  }) {
    final collisionRadius = _enemyCollisionRadius(enemy);
    final projectedDistance = _enemyProjectionAlongAngle(enemy, angle: angle);
    if (projectedDistance < startRadius - collisionRadius ||
        projectedDistance > endRadius + collisionRadius) {
      return false;
    }
    return _enemyPerpendicularDistanceToAngle(enemy, angle: angle) <=
        width + collisionRadius;
  }

  double _beamWidthForProjectile(ProjectileType projectileType) {
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => 18,
      ProjectileBehaviorProfile.pulse => 20,
      ProjectileBehaviorProfile.split => 22,
      ProjectileBehaviorProfile.wave => 24,
      ProjectileBehaviorProfile.lance => 28,
      ProjectileBehaviorProfile.chain => 24,
      ProjectileBehaviorProfile.nova => 30,
      _ => 20,
    };
  }

  double _beamPierceDamageMultiplier(
    ProjectileType projectileType,
    int hitIndex,
  ) {
    if (hitIndex == 0) {
      return 1.0;
    }
    final secondaryStart = switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => 0.56,
      ProjectileBehaviorProfile.pulse => 0.44,
      ProjectileBehaviorProfile.split => 0.48,
      ProjectileBehaviorProfile.wave => 0.5,
      ProjectileBehaviorProfile.lance => 0.72,
      ProjectileBehaviorProfile.chain => 0.6,
      ProjectileBehaviorProfile.nova => 0.68,
      _ => 0.52,
    };
    return max(0.18, secondaryStart - ((hitIndex - 1) * 0.1));
  }

  double _waveBandWidthForProjectile(ProjectileType projectileType) {
    if (projectileType == ProjectileType.pulseRing) {
      return 26;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.wave => 30,
      _ => 24,
    };
  }

  double _waveSweepDamageMultiplier(ProjectileType projectileType) {
    if (projectileType == ProjectileType.pulseRing) {
      return 0.3;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.wave => 0.42,
      _ => 0.36,
    };
  }

  double _projectileSplashRadius(ProjectileType projectileType) {
    if (projectileType == ProjectileType.coreBomb) {
      return _coreBombSplashRadius;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.explosion => 52,
      ProjectileBehaviorProfile.nova => 112,
      _ => 0,
    };
  }

  double _blastSplashDamageMultiplier(ProjectileType projectileType) {
    if (projectileType == ProjectileType.coreBomb) {
      return 1;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.nova => 0.34,
      ProjectileBehaviorProfile.explosion => 0.28,
      _ => 0,
    };
  }

  double _impactSearchRadiusForProjectile(ProjectileType projectileType) {
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.explosion => 40,
      ProjectileBehaviorProfile.nova => 52,
      ProjectileBehaviorProfile.lance => 30,
      _ => 28,
    };
  }
}
