part of '../lightcore_controller.dart';

extension LightcoreControllerCombatEnemies on LightcoreController {
  void _advanceImpacts(double dt) {
    final nextImpacts = <ImpactState>[];
    final fieldKills =
        <
          ({
            EnemyState enemy,
            PrototypeAffinity affinity,
            PrototypeAffinity? secondaryAffinity,
            ProjectileType projectileType,
            PayloadType payloadType,
            int? sourceSlotIndex,
          })
        >[];
    final removedEnemyIds = <String>{};
    for (final impact in _impacts) {
      if (impact.hasLingeringField) {
        _applyLingeringFieldDamage(impact, dt, fieldKills, removedEnemyIds);
      }
      final progress =
          impact.progress + (dt * _impactSpeed * impact.progressRate);
      if (progress < 1) {
        nextImpacts.add(impact.copyWith(progress: progress));
      }
    }
    _impacts
      ..clear()
      ..addAll(nextImpacts);
    for (final kill in fieldKills) {
      _killEnemy(
        kill.enemy,
        kill.affinity,
        secondaryAffinity: kill.secondaryAffinity,
        sourceSlotIndex: kill.sourceSlotIndex,
        projectileType: kill.projectileType,
        payloadType: kill.payloadType,
      );
    }
  }

  void _advanceEnemies(double dt) {
    final nextEnemies = <EnemyState>[];
    final dotKills = <EnemyState>[];
    for (final enemy in _enemies) {
      final burnRemaining = max(0.0, enemy.burnRemaining - dt);
      final slowRemaining = max(0.0, enemy.slowRemaining - dt);
      final shockRemaining = max(0.0, enemy.shockRemaining - dt);
      final bountyRemaining = max(0.0, enemy.bountyRemaining - dt);
      final burnDamage = enemy.burnRemaining > 0
          ? enemy.burnDamagePerSecond * dt
          : 0.0;
      final regenAmount = enemy.config.hasRegen
          ? enemy.maxHealth * enemy.config.regenFractionPerSecond * dt
          : 0.0;
      final health =
          min(enemy.maxHealth, enemy.health + regenAmount) - burnDamage;
      if (health <= 0) {
        dotKills.add(
          enemy.copyWith(
            burnRemaining: burnRemaining,
            slowRemaining: slowRemaining,
            shockRemaining: shockRemaining,
            bountyRemaining: bountyRemaining,
          ),
        );
        continue;
      }

      final movementSlowFactor = enemy.slowRemaining > 0 ? enemy.slowFactor : 1;
      final slowedSpeed = enemy.speed * movementSlowFactor;
      final progressFactor = (enemy.radius / spawnRadius).clamp(0.22, 1.0);
      final radius = enemy.radius - (slowedSpeed * dt);
      final angle =
          enemy.angle + (enemy.angularVelocity * dt * (1.4 - progressFactor));
      final nextAge = enemy.age + dt;
      if (radius <= _relayImpactRadius) {
        _registerRelayHit(enemy.copyWith(health: health));
      } else {
        final advancedEnemy = enemy.copyWith(
          radius: radius,
          angle: angle,
          health: health,
          burnRemaining: burnRemaining,
          slowRemaining: slowRemaining,
          slowFactor: slowRemaining > 0 ? enemy.slowFactor : 1.0,
          shockRemaining: shockRemaining,
          bountyRemaining: bountyRemaining,
          age: nextAge,
        );
        nextEnemies.add(advancedEnemy);
        _maybeSpawnBossMinions(
          advancedEnemy,
          previousAge: enemy.age,
          nextEnemies: nextEnemies,
        );
      }
    }

    _resolveEnemyCollisions(nextEnemies);
    _enemies
      ..clear()
      ..addAll(nextEnemies);
    for (final enemy in dotKills) {
      _killEnemy(
        enemy,
        PrototypeAffinity.ember,
        sourceSlotIndex: null,
        projectileType: ProjectileType.coreBomb,
        payloadType: PayloadType.overheat,
      );
    }
  }

  void _maybeSpawnBossMinions(
    EnemyState enemy, {
    required double previousAge,
    required List<EnemyState> nextEnemies,
  }) {
    if (!enemy.config.isBoss ||
        !enemy.config.hasSpawnAbility ||
        enemy.config.spawnIntervalSeconds <= 0) {
      return;
    }

    final previousWave = (previousAge / enemy.config.spawnIntervalSeconds)
        .floor();
    final currentWave = (enemy.age / enemy.config.spawnIntervalSeconds).floor();
    if (currentWave <= previousWave) {
      return;
    }

    final source = _bossMinionCardFor(enemy);
    if (source == null) {
      return;
    }

    final availableSlots = max(0, enemyTargetCount - _enemies.length);
    final spawnCount = min(enemy.config.spawnCount, availableSlots);
    for (var index = 0; index < spawnCount; index++) {
      final offset = spawnCount == 1
          ? 0.0
          : (index - ((spawnCount - 1) / 2)) * 0.18;
      nextEnemies.add(
        _buildEnemyFromCard(
          source,
          angle: enemy.angle + offset,
          radius: enemy.radius + 16 + (index * 6),
        ),
      );
    }
  }

  EnemyCardState? _bossMinionCardFor(EnemyState boss) {
    final bossAffinities = boss.config.affinities.toSet();
    final minionRarity = switch (boss.config.rarity) {
      EnemyCardRarity.basic ||
      EnemyCardRarity.uncommon => EnemyCardRarity.basic,
      EnemyCardRarity.rare || EnemyCardRarity.epic => EnemyCardRarity.uncommon,
      EnemyCardRarity.legendary => EnemyCardRarity.rare,
    };

    final candidates = _enemyCards
        .where((card) {
          return card.isOwned &&
              card.config.rarity == minionRarity &&
              bossAffinities.contains(card.config.affinity);
        })
        .toList(growable: false);
    if (candidates.isNotEmpty) {
      final source = candidates[_packRandom.nextInt(candidates.length)];
      return source.copyWith(level: max(1, min(source.level, boss.cardLevel)));
    }

    final configCandidates = EnemyLibrary.byRarity[minionRarity]!
        .where((config) => bossAffinities.contains(config.affinity))
        .toList(growable: false);
    if (configCandidates.isEmpty) {
      return null;
    }
    final config =
        configCandidates[_packRandom.nextInt(configCandidates.length)];
    return EnemyCardState(
      config: config,
      unlocked: true,
      copies: 1,
      level: max(1, min(boss.cardLevel, config.rarity.levelCap)),
    );
  }

  void _spawnEnemy() {
    if (_enemies.length >= enemyTargetCount) {
      return;
    }
    final shouldSpawnBoss =
        activeLayer.bossReady && !_enemies.any((enemy) => enemy.config.isBoss);
    if (shouldSpawnBoss) {
      final bossCard = activeBossEnemyCard;
      if (bossCard != null) {
        final spawnedBoss = _buildEnemyFromCard(
          bossCard,
          angle: _randomSpawnAngle(),
          radius: _randomSpawnRadius(),
        );
        _enemies.add(spawnedBoss);
        activeLayer.bossReady = false;
        activeLayer.normalKillsSinceBoss = 0;
        _spawnSequence += 1;
        if (_tutorialIntroBossPending) {
          _tutorialIntroBossPending = false;
          _tutorialTrackedBossEnemyId = spawnedBoss.id;
        }
        _showBanner('${bossCard.config.name} breached the shell perimeter.');
        return;
      }
    }
    final deck = activeEnemyDeck;
    final source = deck.isEmpty
        ? _enemyCards.firstWhere(
            (card) => card.config.id == EnemyLibrary.basicWhite.id,
          )
        : _pickEnemyCardForSpawn(deck);
    final clusterIndex = _spawnSequence ~/ _spawnClusterSize;
    final clusterOffsetIndex =
        (_spawnSequence % _spawnClusterSize) - ((_spawnClusterSize - 1) / 2);
    _prepareRandomSpawnCluster(clusterIndex);
    final baseAngle =
        _activeSpawnClusterAngle +
        (clusterOffsetIndex * _spawnClusterAngleStep) +
        _randomCentered(_spawnClusterAngleJitter);
    final spawnRadius = _spawnRadiusWithJitter(
      _activeSpawnClusterRadius + (clusterOffsetIndex * 4),
      _spawnClusterRadiusJitter,
    );
    _enemies.add(
      _buildEnemyFromCard(source, angle: baseAngle, radius: spawnRadius),
    );
    _spawnSequence += 1;
  }

  void _prepareRandomSpawnCluster(int clusterIndex) {
    if (_activeSpawnClusterIndex == clusterIndex) {
      return;
    }
    _activeSpawnClusterIndex = clusterIndex;
    _activeSpawnClusterAngle = _randomSpawnAngle();
    _activeSpawnClusterRadius = _randomSpawnRadius();
  }

  double _randomSpawnAngle() => _spawnRandom.nextDouble() * pi * 2;

  double _randomSpawnRadius() {
    return (spawnRadius +
            (_spawnRandom.nextDouble() * _spawnRadiusBandVariance))
        .clamp(spawnRadius, spawnCeilingRadius)
        .toDouble();
  }

  double _spawnRadiusWithJitter(double radius, double jitter) {
    return (radius + _randomCentered(jitter))
        .clamp(spawnRadius, spawnCeilingRadius)
        .toDouble();
  }

  double _randomCentered(double maximumMagnitude) {
    return ((_spawnRandom.nextDouble() * 2) - 1) * maximumMagnitude;
  }

  EnemyState _buildEnemyFromCard(
    EnemyCardState source, {
    required double angle,
    required double radius,
    int splitDepth = 0,
    double angularJitter = 0,
  }) {
    final config = source.config;
    final manager = enemyManagerForCard(source.config.id);
    final managerEffect = _enemyManagerEffectMultiplier(source, manager);
    final levelHealthScale = _enemyCardLevelHealthScale(source.level);
    final levelLumenScale = _enemyCardLevelLumenScale(source.level);
    final levelSpeedScale = _enemyCardLevelSpeedScale(source.level);
    final layerScale = 1 + ((activeLayer.tier - 1) * 0.42);
    final worldPressureScale = config.isBoss
        ? 1 +
              min(
                _bossWorldPressureCap,
                (_spawnSequence * _bossWorldPressurePerSpawn) +
                    (builtTowerCount * _bossWorldPressurePerBuiltTower),
              )
        : 1 + min(2.4, (_spawnSequence * 0.045) + (builtTowerCount * 0.05));
    final bossHealthScale = config.isBoss
        ? _bossBaseHealthScale +
              ((activeLayer.tier - 1) * _bossTierHealthScaleStep)
        : 1.0;
    final worldHealthScale = layerScale * worldPressureScale * bossHealthScale;
    final splitScale = splitDepth == 0 ? 1.0 : 0.46;
    final tutorialIntroBoss =
        config.isBoss &&
        _tutorialIntroBossPending &&
        _tutorialTrackedBossEnemyId == null &&
        config.id == BossEnemyLibrary.starterWhiteWarden.id;
    final tutorialHealthMultiplier = tutorialIntroBoss ? 0.6 : 1.0;
    final tutorialDefenseMultiplier = tutorialIntroBoss ? 0.55 : 1.0;
    final maxHealth =
        _balancedEnemyStat(config, 'baseHealth', config.baseHealth) *
        levelHealthScale *
        worldHealthScale *
        splitScale *
        tutorialHealthMultiplier *
        _managerValue(1, manager?.healthMultiplier ?? 1, managerEffect);
    final defense =
        _balancedEnemyStat(config, 'baseDefense', config.baseDefense) *
        (1 + ((source.level - 1) * 0.16)) *
        layerScale *
        (config.isBoss
            ? _bossBaseDefenseScale +
                  ((activeLayer.tier - 1) * _bossTierDefenseScaleStep)
            : 1.0) *
        tutorialDefenseMultiplier *
        (splitDepth > 0 ? 0.68 : 1.0);
    final speed =
        _balancedEnemyStat(config, 'baseSpeed', config.baseSpeed) *
        levelSpeedScale *
        (splitDepth > 0 ? 1.18 : 1.0) *
        (config.isBoss ? _bossSpeedScale : 1.0) *
        _managerValue(1, manager?.speedMultiplier ?? 1, managerEffect);
    final reward = max(
      1,
      (_balancedEnemyStat(config, 'reward', config.reward.toDouble()) *
              levelLumenScale *
              (splitDepth > 0 ? 0.58 : 1) *
              (config.isBoss ? 2.4 + ((activeLayer.tier - 1) * 0.5) : 1.0) *
              _managerValue(1, manager?.rewardMultiplier ?? 1, managerEffect))
          .round(),
    );
    final experienceReward = _experienceRewardForEnemyCard(
      source,
      splitDepth: splitDepth,
      manager: manager,
      managerEffect: managerEffect,
    );
    final jamStrength =
        _balancedEnemyStat(config, 'jamStrength', config.jamStrength) *
        (1 + ((source.level - 1) * 0.08));
    final angularVelocity =
        max(
          0.12,
          _balancedEnemyStat(
                config,
                'baseSpiralDrift',
                config.baseSpiralDrift,
              ) +
              angularJitter,
        ) *
        (splitDepth > 0 ? 1.18 : 1) *
        (config.isBoss ? 0.82 : 1.0);

    return EnemyState(
      id: 'enemy_${_enemyCounter++}',
      sourceCardId: source.config.id,
      cardLevel: source.level,
      config: config,
      spawnRadius: radius,
      angle: angle,
      radius: radius,
      health: maxHealth,
      maxHealth: maxHealth,
      defense: defense,
      speed: speed,
      reward: reward,
      experienceReward: experienceReward,
      jamStrength: jamStrength,
      angularVelocity: angularVelocity,
      splitDepth: splitDepth,
      sizeScale: config.isBoss
          ? 1.16 + ((activeLayer.tier - 1) * 0.06)
          : splitDepth == 0
          ? 0.62
          : 0.36,
    );
  }

  double _sampleDamageRangeMultiplier(
    double minMultiplier,
    double maxMultiplier,
  ) {
    final low = min(minMultiplier, maxMultiplier);
    final high = max(minMultiplier, maxMultiplier);
    if ((high - low).abs() < 0.0001) {
      return high;
    }
    return low + (_traitRandom.nextDouble() * (high - low));
  }

  double _enemyTypeDamageMultiplier({
    required EnemyState target,
    required double normalDamageMultiplier,
    required double bossDamageMultiplier,
  }) => target.config.isBoss ? bossDamageMultiplier : normalDamageMultiplier;
}
