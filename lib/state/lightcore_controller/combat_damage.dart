part of '../lightcore_controller.dart';

extension LightcoreControllerCombatDamage on LightcoreController {
  double _enemyDistance(EnemyState a, EnemyState b) {
    final ax = cos(a.angle) * a.radius;
    final ay = sin(a.angle) * a.radius;
    final bx = cos(b.angle) * b.radius;
    final by = sin(b.angle) * b.radius;
    return sqrt(pow(ax - bx, 2) + pow(ay - by, 2));
  }

  double _polarDistanceToEnemy(
    EnemyState enemy, {
    required double angle,
    required double radius,
  }) {
    final ex = cos(enemy.angle) * enemy.radius;
    final ey = sin(enemy.angle) * enemy.radius;
    final tx = cos(angle) * radius;
    final ty = sin(angle) * radius;
    return sqrt(pow(ex - tx, 2) + pow(ey - ty, 2));
  }

  void _applyLingeringFieldDamage(
    ImpactState impact,
    double dt,
    List<
      ({
        EnemyState enemy,
        PrototypeAffinity affinity,
        PrototypeAffinity? secondaryAffinity,
        ProjectileType projectileType,
        PayloadType payloadType,
        int? sourceSlotIndex,
      })
    >
    fieldKills,
    Set<String> removedEnemyIds,
  ) {
    final tickDamage = impact.fieldDamagePerSecond * dt;
    if (tickDamage <= 0 || _enemies.isEmpty) {
      return;
    }
    for (var index = _enemies.length - 1; index >= 0; index--) {
      final enemy = _enemies[index];
      if (removedEnemyIds.contains(enemy.id)) {
        continue;
      }
      final distance = _polarDistanceToEnemy(
        enemy,
        angle: impact.angle,
        radius: impact.radius,
      );
      if (distance > impact.fieldRadius) {
        continue;
      }
      final remaining = enemy.health - tickDamage;
      if (remaining <= 0) {
        removedEnemyIds.add(enemy.id);
        _enemies.removeAt(index);
        fieldKills.add((
          enemy: enemy,
          affinity: impact.affinity,
          secondaryAffinity: impact.secondaryAffinity,
          projectileType: impact.projectileType,
          payloadType: impact.payloadType,
          sourceSlotIndex: impact.sourceSlotIndex,
        ));
      } else {
        _enemies[index] = enemy.copyWith(health: remaining);
      }
    }
  }

  ImpactState _applyImpactSweepDamage(
    ImpactState impact, {
    required double previousProgress,
    required double progress,
  }) {
    if (!impact.hasImpactSweep || _enemies.isEmpty) {
      return impact;
    }

    final startRadius =
        impact.fieldRadius * _impactSweepProgress(impact, previousProgress);
    final endRadius =
        impact.fieldRadius * _impactSweepProgress(impact, progress);
    if (endRadius <= startRadius) {
      return impact;
    }

    final hitEnemyIds = impact.hitEnemyIds.toSet();
    final bandHalfWidth = impact.sweepBandWidth / 2;
    final newlyHit =
        _enemies.where((enemy) {
          if (hitEnemyIds.contains(enemy.id)) {
            return false;
          }
          final distance = _polarDistanceToEnemy(
            enemy,
            angle: impact.angle,
            radius: impact.radius,
          );
          final bufferedHalfWidth =
              bandHalfWidth + _enemyCollisionRadius(enemy);
          return distance >= startRadius - bufferedHalfWidth &&
              distance <= endRadius + bufferedHalfWidth;
        }).toList()..sort((a, b) {
          final distanceA = _polarDistanceToEnemy(
            a,
            angle: impact.angle,
            radius: impact.radius,
          );
          final distanceB = _polarDistanceToEnemy(
            b,
            angle: impact.angle,
            radius: impact.radius,
          );
          return distanceA.compareTo(distanceB);
        });

    for (final enemy in newlyHit) {
      _applyDamage(
        enemy.id,
        _impactSweepDamageAgainstEnemy(impact, enemy),
        impact.affinity,
        layer2: false,
        secondaryAffinity: impact.secondaryAffinity,
        sourceSlotIndex: impact.sourceSlotIndex,
        projectileType: impact.projectileType,
        payloadType: impact.payloadType,
        critical: impact.critical,
        critChance: impact.critChance,
        critMultiplier: impact.critMultiplier,
        applyPayloadEffects: false,
        applyProjectileFollowUp: false,
        spawnImpact: false,
      );
      hitEnemyIds.add(enemy.id);
    }

    return impact.copyWith(hitEnemyIds: hitEnemyIds.toList(growable: false));
  }

  double _impactSweepProgress(ImpactState impact, double progress) {
    if (impact.projectileType == ProjectileType.coreBomb) {
      return (progress / 0.28).clamp(0.0, 1.0).toDouble();
    }
    return progress.clamp(0.0, 1.0).toDouble();
  }

  double _impactSweepDamageAgainstEnemy(ImpactState impact, EnemyState enemy) {
    var damage =
        impact.sweepDamage *
        _enemyTypeDamageMultiplier(
          target: enemy,
          normalDamageMultiplier: impact.normalDamageMultiplier,
          bossDamageMultiplier: impact.bossDamageMultiplier,
        );
    if (impact.sourceSlotIndex != null) {
      final affinityScale = _affinityMultiplierAgainstEnemy(
        impact.affinity,
        enemy,
      );
      final sourceTower = _slots[impact.sourceSlotIndex!];
      final towerAffinityScale =
          affinityScale > 1 && _slotCountsTowardRing(sourceTower)
          ? _slotAffinityBonusMultiplier(sourceTower)
          : 1.0;
      damage *=
          affinityScale *
          (affinityScale > 1 ? impact.advantageMultiplier : 1.0) *
          towerAffinityScale;
    }
    return _applyDefenseReduction(
      damage,
      enemy,
      defensePenetration: impact.defensePenetration,
    );
  }

  double _projectileDamageMultiplier(ProjectileType projectileType) {
    if (projectileType == ProjectileType.pulseRing) {
      return 0.56;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => 1.0,
      ProjectileBehaviorProfile.pulse => 0.82,
      ProjectileBehaviorProfile.burst => 0.78,
      ProjectileBehaviorProfile.chain => 0.9,
      ProjectileBehaviorProfile.split => 0.88,
      ProjectileBehaviorProfile.lance => 1.16,
      ProjectileBehaviorProfile.explosion => 0.94,
      ProjectileBehaviorProfile.wave => 0.96,
      ProjectileBehaviorProfile.nova => 1.08,
    };
  }

  double _projectileRangeMultiplier(ProjectileType projectileType) {
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => 0.9,
      ProjectileBehaviorProfile.pulse => 1.18,
      ProjectileBehaviorProfile.burst => 0.96,
      ProjectileBehaviorProfile.chain => 0.92,
      ProjectileBehaviorProfile.split => 1.08,
      ProjectileBehaviorProfile.lance => 1.16,
      ProjectileBehaviorProfile.explosion => 0.84,
      ProjectileBehaviorProfile.wave => 1.02,
      ProjectileBehaviorProfile.nova => 1.04,
    };
  }

  double _projectilePulseSpeedMultiplier(ProjectileType projectileType) {
    if (projectileType == ProjectileType.pulseRing) {
      return 1.08;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => 1.0,
      ProjectileBehaviorProfile.pulse => 1.16,
      ProjectileBehaviorProfile.burst => 1.14,
      ProjectileBehaviorProfile.chain => 1.04,
      ProjectileBehaviorProfile.split => 1.05,
      ProjectileBehaviorProfile.lance => 1.08,
      ProjectileBehaviorProfile.explosion => 0.92,
      ProjectileBehaviorProfile.wave => 0.98,
      ProjectileBehaviorProfile.nova => 0.9,
    };
  }

  double _projectileCooldownMultiplier(ProjectileType projectileType) {
    if (projectileType == ProjectileType.pulseRing) {
      return 0.72;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => 1.22,
      ProjectileBehaviorProfile.pulse => 0.88,
      ProjectileBehaviorProfile.burst => 0.84,
      ProjectileBehaviorProfile.chain => 1.04,
      ProjectileBehaviorProfile.split => 0.94,
      ProjectileBehaviorProfile.lance => 1.12,
      ProjectileBehaviorProfile.explosion => 1.08,
      ProjectileBehaviorProfile.wave => 1.32,
      ProjectileBehaviorProfile.nova => 1.28,
    };
  }

  double _impactProgressRateForProjectile(
    ProjectileType projectileType, {
    required bool lethal,
  }) {
    if (projectileType == ProjectileType.chainArc) {
      return 1 / (_impactSpeed * _chainArcImpactLingerSeconds);
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.explosion => lethal ? 0.24 : 0.28,
      ProjectileBehaviorProfile.wave => lethal ? 0.4 : 0.46,
      ProjectileBehaviorProfile.nova => lethal ? 0.2 : 0.24,
      ProjectileBehaviorProfile.lance => 1.08,
      _ => 1.0,
    };
  }

  double _impactFieldRadiusForProjectile(
    ProjectileType projectileType, {
    required bool lethal,
  }) {
    if (_projectileUsesInstantBlastOnly(projectileType)) {
      return 0;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.explosion => lethal ? 80 : 72,
      ProjectileBehaviorProfile.nova => lethal ? 124 : 108,
      _ => 0,
    };
  }

  double _impactFieldDamageMultiplierForProjectile(
    ProjectileType projectileType, {
    required bool lethal,
  }) {
    if (_projectileUsesInstantBlastOnly(projectileType)) {
      return 0;
    }
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.explosion => lethal ? 0.18 : 0.16,
      ProjectileBehaviorProfile.nova => lethal ? 0.24 : 0.2,
      _ => 0,
    };
  }

  void _resolveEnemyCollisions(List<EnemyState> enemies) {
    for (var i = 0; i < enemies.length; i++) {
      for (var j = i + 1; j < enemies.length; j++) {
        final a = enemies[i];
        final b = enemies[j];
        var ax = cos(a.angle) * a.radius;
        var ay = sin(a.angle) * a.radius;
        var bx = cos(b.angle) * b.radius;
        var by = sin(b.angle) * b.radius;
        final dx = bx - ax;
        final dy = by - ay;
        final distance = max(0.001, sqrt((dx * dx) + (dy * dy)));
        final minimumDistance =
            _enemyCollisionRadius(a) + _enemyCollisionRadius(b) + 4;
        if (distance >= minimumDistance) {
          continue;
        }

        final overlap = minimumDistance - distance;
        final nx = dx / distance;
        final ny = dy / distance;
        ax -= nx * overlap * 0.5;
        ay -= ny * overlap * 0.5;
        bx += nx * overlap * 0.5;
        by += ny * overlap * 0.5;
        enemies[i] = a.copyWith(
          radius: max(_relayImpactRadius + 4, sqrt((ax * ax) + (ay * ay))),
          angle: atan2(ay, ax),
        );
        enemies[j] = b.copyWith(
          radius: max(_relayImpactRadius + 4, sqrt((bx * bx) + (by * by))),
          angle: atan2(by, bx),
        );
      }
    }
  }

  double _enemyCollisionRadius(EnemyState enemy) => 11 * enemy.sizeScale;

  double _sourceTowerDotDamageMultiplier(int? sourceSlotIndex) {
    if (sourceSlotIndex == null ||
        sourceSlotIndex < 0 ||
        sourceSlotIndex >= _slots.length) {
      return 1;
    }
    return towerDotDamageMultiplier(_slots[sourceSlotIndex]);
  }

  EnemyState _applyProjectileHitStatus(
    EnemyState enemy,
    ProjectileType projectileType,
  ) {
    return switch (projectileType) {
      ProjectileType.chainArc => enemy.copyWith(
        slowRemaining: max(enemy.slowRemaining, 0.22),
        slowFactor: min(enemy.slowFactor, 0.02),
        shockRemaining: max(enemy.shockRemaining, 0.34),
      ),
      _ => enemy,
    };
  }

  void _applyDamage(
    String enemyId,
    double damage,
    PrototypeAffinity affinity, {
    required bool layer2,
    PrototypeAffinity? secondaryAffinity,
    int? sourceSlotIndex,
    ProjectileType projectileType = ProjectileType.threadBeam,
    PayloadType payloadType = PayloadType.none,
    bool critical = false,
    double critChance = 0,
    double critMultiplier = 1,
    bool applyPayloadEffects = true,
    bool applyProjectileFollowUp = true,
    bool spawnImpact = true,
    double? impactAngle,
    double? impactRadius,
    double? chainSourceAngle,
    double? chainSourceRadius,
  }) {
    final enemyIndex = _enemies.indexWhere((enemy) => enemy.id == enemyId);
    if (enemyIndex == -1) {
      return;
    }

    final enemy = _enemies[enemyIndex];
    if (damage <= 0 || _enemyIsImmuneToAffinity(enemy, affinity)) {
      return;
    }

    var resolvedDamage =
        damage * _knowledgeBookDamageMultiplierAgainstEnemy(enemy);
    var resolvedCritical = critical;
    final resolvedCritChance = critChance.clamp(0.0, 1.0).toDouble();
    if (!resolvedCritical &&
        resolvedCritChance > 0 &&
        _traitRandom.nextDouble() < resolvedCritChance) {
      resolvedCritical = true;
      resolvedDamage *= critMultiplier;
    }
    if (enemy.bountyRemaining > 0) {
      resolvedDamage *= 1 + enemy.bountyMultiplier.clamp(0.0, 1.5);
    }

    final remainingHealth = enemy.health - resolvedDamage;
    if (remainingHealth <= 0) {
      _enemies.removeAt(enemyIndex);
      _killEnemy(
        enemy,
        affinity,
        secondaryAffinity: secondaryAffinity,
        sourceSlotIndex: sourceSlotIndex,
        projectileType: projectileType,
        payloadType: payloadType,
        impactPower: resolvedDamage,
        critical: resolvedCritical,
        impactAngle: impactAngle,
        impactRadius: impactRadius,
        chainSourceAngle: chainSourceAngle,
        chainSourceRadius: chainSourceRadius,
      );
      if (applyProjectileFollowUp &&
          projectileType.behaviorProfile == ProjectileBehaviorProfile.chain) {
        _applyProjectileFollowUp(
          origin: enemy,
          damage: resolvedDamage,
          affinity: affinity,
          secondaryAffinity: secondaryAffinity,
          projectileType: projectileType,
          payloadType: payloadType,
          sourceSlotIndex: sourceSlotIndex,
        );
      }
    } else {
      var nextEnemy = enemy.copyWith(health: remainingHealth);
      if (applyPayloadEffects) {
        nextEnemy = _applyPayloadEffect(
          nextEnemy,
          payloadType,
          resolvedDamage,
          affinity,
          secondaryAffinity,
          sourceSlotIndex,
        );
      }
      nextEnemy = _applyProjectileHitStatus(nextEnemy, projectileType);
      _enemies[enemyIndex] = nextEnemy;
      if (spawnImpact) {
        _impacts.add(
          ImpactState(
            id: 'impact_${_impactCounter++}',
            affinity: affinity,
            secondaryAffinity: secondaryAffinity,
            projectileType: projectileType,
            payloadType: payloadType,
            angle: impactAngle ?? enemy.angle,
            radius: impactRadius ?? enemy.radius,
            progress: 0,
            lethal: false,
            towerHit: false,
            critical: resolvedCritical,
            progressRate: _impactProgressRateForProjectile(
              projectileType,
              lethal: false,
            ),
            fieldRadius: _impactFieldRadiusForProjectile(
              projectileType,
              lethal: false,
            ),
            fieldDamagePerSecond:
                resolvedDamage *
                _sourceTowerDotDamageMultiplier(sourceSlotIndex) *
                _impactFieldDamageMultiplierForProjectile(
                  projectileType,
                  lethal: false,
                ),
            sourceSlotIndex: sourceSlotIndex,
            chainSourceAngle: chainSourceAngle,
            chainSourceRadius: chainSourceRadius,
          ),
        );
      }
      if (applyProjectileFollowUp) {
        _applyProjectileFollowUp(
          origin: nextEnemy,
          damage: resolvedDamage,
          affinity: affinity,
          secondaryAffinity: secondaryAffinity,
          projectileType: projectileType,
          payloadType: payloadType,
          sourceSlotIndex: sourceSlotIndex,
        );
      }
    }

    if (layer2 &&
        _enemies.isEmpty &&
        canUnlockLayer2 &&
        !activeLayer.layer3TrialActive) {
      _showBanner(
        'Cluster stabilized. Open Advancement to align a Prism Shell.',
        category: LightcoreNotificationCategory.battle,
      );
    }
  }

  void _killEnemy(
    EnemyState enemy,
    PrototypeAffinity affinity, {
    PrototypeAffinity? secondaryAffinity,
    int? sourceSlotIndex,
    ProjectileType projectileType = ProjectileType.threadBeam,
    PayloadType payloadType = PayloadType.none,
    double impactPower = 0,
    bool critical = false,
    double? impactAngle,
    double? impactRadius,
    double? chainSourceAngle,
    double? chainSourceRadius,
  }) {
    _blueFocusTargetEnemyIdBySlot.removeWhere(
      (_, lockedEnemyId) => lockedEnemyId == enemy.id,
    );

    void addDefeatImpact() {
      _impacts.add(
        ImpactState(
          id: 'impact_${_impactCounter++}',
          affinity: affinity,
          secondaryAffinity: secondaryAffinity,
          projectileType: projectileType,
          payloadType: payloadType,
          angle: impactAngle ?? enemy.angle,
          radius: impactRadius ?? enemy.radius,
          progress: 0,
          lethal: true,
          towerHit: false,
          critical: critical,
          progressRate: _impactProgressRateForProjectile(
            projectileType,
            lethal: true,
          ),
          fieldRadius: _impactFieldRadiusForProjectile(
            projectileType,
            lethal: true,
          ),
          fieldDamagePerSecond:
              impactPower *
              _sourceTowerDotDamageMultiplier(sourceSlotIndex) *
              _impactFieldDamageMultiplierForProjectile(
                projectileType,
                lethal: true,
              ),
          sourceSlotIndex: sourceSlotIndex,
          chainSourceAngle: chainSourceAngle,
          chainSourceRadius: chainSourceRadius,
          defeatedEnemyAffinity: enemy.config.affinity,
          defeatedEnemySizeScale: enemy.sizeScale,
        ),
      );
    }

    if (!_battleKillRewardsEnabled) {
      addDefeatImpact();
      if (enemy.config.splitsOnDeath && enemy.splitDepth == 0) {
        _spawnSplitChildren(enemy);
      }
      _syncTutorialStep(showBanner: false);
      return;
    }

    final challengeActive = _threatRegionChallenge != null;
    final previousExperience = progressionExperience;
    final killCredit = _killCreditForEnemy(enemy);
    final scaledExperienceReward =
        (enemy.experienceReward *
                sharedRelayExperienceMultiplier *
                effectiveExperienceEfficiencyMultiplier)
            .round();
    final experienceReward = max(
      enemy.experienceReward,
      scaledExperienceReward,
    );
    if (enemy.config.isBoss) {
      _totalBossesDefeated += 1;
      _recordThreatRegionBossDefeat(enemy.config);
    }
    if (enemy.config.id == EnemyLibrary.basicWhite.id &&
        _tutorialSafeScanDefeats < 5) {
      _tutorialSafeScanDefeats += 1;
    }
    String? bossUnlockBanner;
    String? tournamentUnlockBanner;
    String? managerUnlockBanner;
    String? dailyDungeonUnlockBanner;
    String? mentorshipUnlockBanner;
    String? unlockBanner;
    if (!challengeActive) {
      kills += killCredit;
      experience += _boostedExperienceReward(experienceReward);
      _advanceBattlePass(BattlePassType.dailyKills, killCredit);
      bossUnlockBanner = _grantBossUnlockIfNeeded();
      tournamentUnlockBanner = _tournamentUnlockBannerFragment(
        previousExperience: previousExperience,
        currentExperience: progressionExperience,
      );
      managerUnlockBanner = _managerUnlockBannerFragment(
        previousExperience: previousExperience,
        currentExperience: progressionExperience,
      );
      dailyDungeonUnlockBanner = _dailyDungeonUnlockBannerFragment(
        previousExperience: previousExperience,
        currentExperience: progressionExperience,
      );
      mentorshipUnlockBanner = _mentorshipUnlockBannerFragment(
        previousExperience: previousExperience,
        currentExperience: progressionExperience,
      );
      unlockBanner = _towerUnlockBannerFragment(
        previousExperience,
        progressionExperience,
      );
    }
    if (!challengeActive &&
        !enemy.config.isBoss &&
        !bossAlive &&
        !activeLayer.bossReady) {
      activeLayer.normalKillsSinceBoss += 1;
      activeLayer.bestWaveReached = max(
        activeLayer.bestWaveReached,
        1 + (_spawnSequence ~/ max(1, initialEnemyTarget)),
      );
      _grantRoundCurrencyForReachedWave();
      if (activeLayer.normalKillsSinceBoss >= bossSpawnKillRequirement) {
        activeLayer.bossReady = true;
        _showBanner(
          ownedBossEnemyCardCount == 0
              ? 'Apex lane primed. Clear a regional boss to arm the next spawn.'
              : '${activeBossEnemyCard?.config.name ?? 'Apex Anomaly'} is approaching. The next spawn is an Apex Anomaly.',
          category: LightcoreNotificationCategory.battle,
        );
      }
    }
    addDefeatImpact();
    if (enemy.config.splitsOnDeath && enemy.splitDepth == 0) {
      _spawnSplitChildren(enemy);
      return;
    }

    final lumenDrop = scaledReward(
      enemy,
      currentEnemyCount: _enemies.length + 1,
      sourceSlotIndex: sourceSlotIndex,
    );
    lumens += lumenDrop;
    var bountyLumenDrop = 0;
    if (enemy.bountyRemaining > 0) {
      bountyLumenDrop = max(
        1,
        (enemy.reward *
                enemy.bountyMultiplier *
                outputEfficiencyMultiplier *
                lumenTierMultiplier *
                friendAllianceRewardMultiplier *
                _gearLumenMultiplier *
                _economyBalanceMultiplier('lumenReward'))
            .round(),
      );
      lumens += bountyLumenDrop;
    }
    final fluxDrop = _rollFluxDropForEnemy(enemy);
    if (fluxDrop > 0) {
      flux += fluxDrop;
    }
    final threatScanDrop = _rollThreatScanDropForEnemy(enemy);
    if (threatScanDrop > 0) {
      enemyTickets += threatScanDrop;
    }
    var droppedItem = _awardEquipmentDropIfRolled(enemy);
    final defeatedTutorialIntroBoss =
        enemy.id == _tutorialTrackedBossEnemyId &&
        enemy.config.id == BossEnemyLibrary.starterWhiteWarden.id;
    if (LightcoreController.equipmentReleaseEnabled &&
        defeatedTutorialIntroBoss &&
        droppedItem == null) {
      droppedItem = _grantEquipmentEventCache(rarity: ManagerRarity.common);
    }
    if (defeatedTutorialIntroBoss) {
      _tutorialFirstBossDefeated = true;
      _tutorialTrackedBossEnemyId = null;
      _showBanner(
        'White Warden broken. ${bossSpawnStatusLabel[0].toUpperCase()}${bossSpawnStatusLabel.substring(1)}',
      );
      _syncTutorialStep(showBanner: false);
    }
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final progressionBanner = [
      levelUpBanner,
      unlockBanner,
      bossUnlockBanner,
      managerUnlockBanner,
      dailyDungeonUnlockBanner,
      tournamentUnlockBanner,
      mentorshipUnlockBanner,
    ].whereType<String>().join(' ');
    if (enemy.config.isBoss) {
      final gainedThreatScans = max(
        1,
        activeLayer.tier + (enemy.config.rarity.index ~/ 2),
      );
      enemyTickets += gainedThreatScans;
      final gainedComponentScrolls = _awardLayer2ComponentScrollsForBoss(enemy);
      final bossRewardParts = <String>[
        LightcoreCurrencyLabels.rewardLumens(lumenDrop + bountyLumenDrop),
        LightcoreCurrencyLabels.rewardThreatScans(gainedThreatScans),
        if (gainedComponentScrolls > 0)
          '$gainedComponentScrolls Component Scroll${gainedComponentScrolls == 1 ? '' : 's'}',
        if (fluxDrop > 0) LightcoreCurrencyLabels.rewardFlux(fluxDrop),
        if (threatScanDrop > 0)
          LightcoreCurrencyLabels.rewardThreatScans(threatScanDrop),
      ];
      _showBanner(
        '${enemy.config.name} defeated: ${bossRewardParts.join(', ')}.${progressionBanner.isEmpty ? '' : ' $progressionBanner'}',
      );
    } else {
      if (progressionBanner.isNotEmpty) {
        _showBanner(progressionBanner);
      }
    }
    _syncTutorialStep(showBanner: false);
  }

  int _awardLayer2ComponentScrollsForBoss(EnemyState enemy) {
    if (!enemy.config.isBoss || activeLayer.tier < 2) {
      return 0;
    }
    final amount = max(
      1,
      activeLayer.tier + enemy.config.rarity.index + (enemy.cardLevel ~/ 4),
    );
    componentScrolls += amount;
    return amount;
  }

  PlayerEquipmentItem? _awardEquipmentDropIfRolled(EnemyState enemy) {
    final chance = equipmentDropChanceForEnemy(enemy);
    if (chance <= 0 || _packRandom.nextDouble() >= chance) {
      return null;
    }
    final item = _buildEquipmentDrop(enemy);
    _equipmentInventory.add(item);
    _trackNewEquipmentItem(item);
    _enforceEquipmentInventoryCap();
    return item;
  }

  PlayerEquipmentItem _grantEquipmentEventCache({ManagerRarity? rarity}) {
    final item = _buildEquipmentEventCache(rarity: rarity);
    _equipmentInventory.add(item);
    _trackNewEquipmentItem(item);
    _enforceEquipmentInventoryCap();
    return item;
  }

  PlayerEquipmentItem _buildEquipmentDrop(
    EnemyState enemy, {
    EquipmentInventorySlot? slotType,
    ManagerRarity? rarity,
    int? level,
  }) {
    final set = EquipmentLibrary.forEnemy(enemy.config);
    final resolvedSlot =
        slotType ??
        EquipmentInventorySlot.values[_packRandom.nextInt(
          EquipmentInventorySlot.values.length,
        )];
    final resolvedRarity = rarity ?? _rollEquipmentRarity(enemy);
    final resolvedLevel = max(1, level ?? _rollEquipmentLevel(enemy));
    final scale =
        _equipmentRarityScale(resolvedRarity) *
        (1 + ((resolvedLevel - 1) * 0.045));
    final order = _equipmentDropCounter++;
    return PlayerEquipmentItem(
      instanceId: 'gear_${order}_${_packRandom.nextInt(99999)}',
      setId: set.id,
      setName: set.name,
      slotType: resolvedSlot,
      name: set.pieceNameFor(resolvedSlot),
      rarity: resolvedRarity,
      level: resolvedLevel,
      affinity: set.affinity,
      sourceEnemyId: enemy.config.id,
      sourceEnemyName: enemy.config.name,
      bonuses: set.slotBonusFor(resolvedSlot).scale(scale),
      dropOrder: order,
    );
  }

  PlayerEquipmentItem _buildEquipmentEventCache({ManagerRarity? rarity}) {
    final set =
        EquipmentLibrary.all[_packRandom.nextInt(EquipmentLibrary.all.length)];
    final slot = EquipmentInventorySlot
        .values[_packRandom.nextInt(EquipmentInventorySlot.values.length)];
    final resolvedRarity = rarity ?? _rollEquipmentEventCacheRarity();
    final resolvedLevel = _rollEquipmentEventCacheLevel();
    final scale =
        _equipmentRarityScale(resolvedRarity) *
        (1 + ((resolvedLevel - 1) * 0.045));
    final order = _equipmentDropCounter++;
    return PlayerEquipmentItem(
      instanceId: 'gear_${order}_${_packRandom.nextInt(99999)}',
      setId: set.id,
      setName: set.name,
      slotType: slot,
      name: set.pieceNameFor(slot),
      rarity: resolvedRarity,
      level: resolvedLevel,
      affinity: set.affinity,
      sourceEnemyId: 'weekly_equipment_event',
      sourceEnemyName: 'Weekly Equipment Event',
      bonuses: set.slotBonusFor(slot).scale(scale),
      dropOrder: order,
    );
  }

  ManagerRarity _rollEquipmentEventCacheRarity() {
    final roll = _packRandom.nextDouble();
    if (roll < 0.06) {
      return ManagerRarity.legendary;
    }
    if (roll < 0.22) {
      return ManagerRarity.epic;
    }
    if (roll < 0.62) {
      return ManagerRarity.rare;
    }
    return ManagerRarity.uncommon;
  }
}
