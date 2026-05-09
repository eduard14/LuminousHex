part of '../lightcore_controller.dart';

typedef _Layer3TrialSpawn = ({
  EnemyConfig config,
  int level,
  double angleOffset,
  double radiusOffset,
  double angularJitter,
});

extension LightcoreControllerCombatEnemies on LightcoreController {
  bool canManuallySpawnBattleEnemy({
    required String cardId,
    bool boss = false,
  }) {
    if (_battleSpawnPolicy != LightcoreBattleSpawnPolicy.manual ||
        !_swarmActivated ||
        activeLayerPassiveOnly ||
        _enemies.length >= enemyTargetCount) {
      return false;
    }
    final card = boss ? bossEnemyCardById(cardId) : enemyCardById(cardId);
    if (card == null || !card.isOwned) {
      return false;
    }
    if (boss && _enemies.any((enemy) => enemy.config.isBoss)) {
      return false;
    }
    return true;
  }

  bool spawnManualBattleEnemy({
    required String cardId,
    bool boss = false,
    double speedMultiplier = 1.0,
  }) {
    if (!canManuallySpawnBattleEnemy(cardId: cardId, boss: boss)) {
      return false;
    }
    final source = boss ? bossEnemyCardById(cardId) : enemyCardById(cardId);
    if (source == null) {
      return false;
    }

    final spawnPoint = boss
        ? (angle: _randomSpawnAngle(), radius: _randomSpawnRadius())
        : _nextClusteredSpawnPoint();
    final enemy = _buildEnemyFromCard(
      source,
      angle: spawnPoint.angle,
      radius: spawnPoint.radius,
    );
    _enemies.add(
      enemy.copyWith(speed: enemy.speed * speedMultiplier.clamp(0.25, 3.0)),
    );
    _spawnSequence += 1;
    _swarmActivated = true;
    if (boss) {
      activeLayer.bossReady = false;
      activeLayer.normalKillsSinceBoss = 0;
      _showBanner(
        '${source.config.name} manually released into the battle lane.',
        category: LightcoreNotificationCategory.battle,
      );
    }
    _needsNotify = true;
    _notifyNow();
    return true;
  }

  void _advanceImpacts(double dt) {
    final activeImpacts = List<ImpactState>.from(_impacts);
    _impacts.clear();
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
    for (final impact in activeImpacts) {
      final previousProgress = impact.progress;
      final progress =
          impact.progress + (dt * _impactSpeed * impact.progressRate);
      var nextImpact = impact;
      if (impact.hasLingeringField) {
        _applyLingeringFieldDamage(impact, dt, fieldKills, removedEnemyIds);
      }
      if (impact.hasImpactSweep) {
        nextImpact = _applyImpactSweepDamage(
          nextImpact,
          previousProgress: previousProgress,
          progress: progress,
        );
      }
      if (progress < 1) {
        nextImpacts.add(nextImpact.copyWith(progress: progress));
      }
    }
    final spawnedImpacts = List<ImpactState>.from(_impacts);
    _impacts
      ..clear()
      ..addAll(nextImpacts)
      ..addAll(spawnedImpacts);
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
      final regionBossCards = activeThreatRegionBossCards;
      if (regionBossCards.isNotEmpty) {
        for (var index = 0; index < regionBossCards.length; index += 1) {
          final bossCard = regionBossCards[index];
          final spawnedBoss = _buildEnemyFromCard(
            bossCard,
            angle: _randomSpawnAngle() + (index * 0.28),
            radius: _randomSpawnRadius() + (index * 18),
          );
          _enemies.add(spawnedBoss);
          _spawnSequence += 1;
        }
        activeLayer.bossReady = false;
        activeLayer.normalKillsSinceBoss = 0;
        _showBanner(
          regionBossCards.length == 1
              ? '${regionBossCards.first.config.name} breached the shell perimeter.'
              : '${regionBossCards.length} regional Apex bosses breached the shell perimeter.',
          category: LightcoreNotificationCategory.battle,
        );
        return;
      }
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
        _showBanner(
          '${bossCard.config.name} breached the shell perimeter.',
          category: LightcoreNotificationCategory.battle,
        );
        return;
      }
    }
    final deck = activeEnemyDeck;
    final source = deck.isEmpty
        ? _enemyCards.firstWhere(
            (card) => card.config.id == EnemyLibrary.basicWhite.id,
          )
        : _pickEnemyCardForSpawn(deck);
    final spawnPoint = _nextClusteredSpawnPoint();
    _enemies.add(
      _buildEnemyFromCard(
        source,
        angle: spawnPoint.angle,
        radius: spawnPoint.radius,
      ),
    );
    _spawnSequence += 1;
  }

  ({double angle, double radius}) _nextClusteredSpawnPoint() {
    final clusterIndex = _spawnSequence ~/ _spawnClusterSize;
    final clusterOffsetIndex =
        (_spawnSequence % _spawnClusterSize) - ((_spawnClusterSize - 1) / 2);
    _prepareRandomSpawnCluster(clusterIndex);
    final angle =
        _activeSpawnClusterAngle +
        (clusterOffsetIndex * _spawnClusterAngleStep) +
        _randomCentered(_spawnClusterAngleJitter);
    final radius = _spawnRadiusWithJitter(
      _activeSpawnClusterRadius + (clusterOffsetIndex * 4),
      _spawnClusterRadiusJitter,
    );
    return (angle: angle, radius: radius);
  }

  void _advanceLayer3Trial(double dt) {
    if (!activeLayer.layer3TrialActive || activeLayer.layer3TrialCleared) {
      return;
    }

    final plan = _layer3TrialPlan();
    if (activeLayer.layer3TrialSpawnIndex >= plan.length) {
      if (_enemies.isEmpty) {
        _completeLayer3Trial();
      }
      return;
    }

    _spawnTimer -= dt;
    final trialCap = min(
      maxActiveEnemies,
      max(_layer3TrialEnemyCap, enemyTargetCount),
    );
    while (_spawnTimer <= 0 &&
        activeLayer.layer3TrialSpawnIndex < plan.length) {
      if (_enemies.length >= trialCap) {
        _spawnTimer = 0.16;
        break;
      }
      final spawnIndex = activeLayer.layer3TrialSpawnIndex;
      _spawnLayer3TrialEnemy(plan[spawnIndex], spawnIndex);
      activeLayer.layer3TrialSpawnIndex += 1;
      _spawnTimer += _layer3TrialSpawnCadence;
    }
  }

  void _spawnLayer3TrialEnemy(_Layer3TrialSpawn spawn, int spawnIndex) {
    final laneAngle = _slotAngle(spawnIndex % slotCount);
    final angle =
        laneAngle + spawn.angleOffset + _randomCentered(_spawnClusterAngleStep);
    final radius = _spawnRadiusWithJitter(
      _minimumSpawnRadius + spawn.radiusOffset,
      _spawnClusterRadiusJitter,
    );
    final source = EnemyCardState(
      config: spawn.config,
      unlocked: true,
      copies: 1,
      level: spawn.level,
    );
    _enemies.add(
      _buildEnemyFromCard(
        source,
        angle: angle,
        radius: radius,
        angularJitter: spawn.angularJitter,
      ),
    );
    _spawnSequence += 1;
  }

  void _completeLayer3Trial() {
    activeLayer.layer3TrialActive = false;
    activeLayer.layer3TrialCleared = true;
    activeLayer.layer3TrialSpawnIndex = _layer3TrialPlan().length;
    _spawnTimer = 0.65;
    _showBanner(
      'Nexus trial cleared. Layer 3 is unlocked; open Advancement to create the Nexus Shell.',
      duration: 3.4,
    );
    _needsNotify = true;
  }

  void _failLayer3Trial() {
    if (!activeLayer.layer3TrialActive) {
      return;
    }
    activeLayer.layer3TrialActive = false;
    activeLayer.layer3TrialCleared = false;
    activeLayer.layer3TrialSpawnIndex = 0;
    _spawnTimer = 1.0;
    _showBanner(
      'Nexus trial failed. Rebuild or retune, then begin the proving battle again.',
      duration: 3.2,
      category: LightcoreNotificationCategory.battle,
    );
    _needsNotify = true;
  }

  List<_Layer3TrialSpawn> _layer3TrialPlan() {
    final rushBasic = _trialEnemyConfig(
      PrototypeAffinity.flare,
      EnemyCardRarity.basic,
    );
    final rushUncommon = _trialEnemyConfig(
      PrototypeAffinity.flare,
      EnemyCardRarity.uncommon,
    );
    final rushRare = _trialEnemyConfig(
      PrototypeAffinity.flare,
      EnemyCardRarity.rare,
    );
    final blinkUncommon = _trialEnemyConfig(
      PrototypeAffinity.solar,
      EnemyCardRarity.uncommon,
    );
    final splitBasic = _trialEnemyConfig(
      PrototypeAffinity.violet,
      EnemyCardRarity.basic,
    );
    final splitUncommon = _trialEnemyConfig(
      PrototypeAffinity.violet,
      EnemyCardRarity.uncommon,
    );
    final tankUncommon = _trialEnemyConfig(
      PrototypeAffinity.ember,
      EnemyCardRarity.uncommon,
    );
    final regenUncommon = _trialEnemyConfig(
      PrototypeAffinity.verdant,
      EnemyCardRarity.uncommon,
    );
    final redBoss = _trialBossConfig(PrototypeAffinity.ember);
    final greenBoss = _trialBossConfig(PrototypeAffinity.verdant);

    return <_Layer3TrialSpawn>[
      (
        config: rushBasic,
        level: 3,
        angleOffset: -0.08,
        radiusOffset: 0,
        angularJitter: 0.18,
      ),
      (
        config: rushBasic,
        level: 3,
        angleOffset: 0.07,
        radiusOffset: 6,
        angularJitter: 0.16,
      ),
      (
        config: blinkUncommon,
        level: 2,
        angleOffset: -0.05,
        radiusOffset: 10,
        angularJitter: 0.22,
      ),
      (
        config: rushUncommon,
        level: 2,
        angleOffset: 0.09,
        radiusOffset: 4,
        angularJitter: 0.2,
      ),
      (
        config: splitBasic,
        level: 3,
        angleOffset: -0.03,
        radiusOffset: 12,
        angularJitter: 0.08,
      ),
      (
        config: splitBasic,
        level: 3,
        angleOffset: 0.04,
        radiusOffset: 18,
        angularJitter: 0.1,
      ),
      (
        config: splitUncommon,
        level: 2,
        angleOffset: -0.06,
        radiusOffset: 16,
        angularJitter: 0.1,
      ),
      (
        config: tankUncommon,
        level: 2,
        angleOffset: 0.03,
        radiusOffset: 10,
        angularJitter: 0.02,
      ),
      (
        config: redBoss,
        level: 1,
        angleOffset: 0,
        radiusOffset: 24,
        angularJitter: 0,
      ),
      (
        config: rushRare,
        level: 1,
        angleOffset: -0.1,
        radiusOffset: 0,
        angularJitter: 0.24,
      ),
      (
        config: rushBasic,
        level: 4,
        angleOffset: 0.11,
        radiusOffset: 4,
        angularJitter: 0.22,
      ),
      (
        config: blinkUncommon,
        level: 3,
        angleOffset: -0.04,
        radiusOffset: 8,
        angularJitter: 0.24,
      ),
      (
        config: splitBasic,
        level: 4,
        angleOffset: 0.05,
        radiusOffset: 16,
        angularJitter: 0.12,
      ),
      (
        config: splitUncommon,
        level: 2,
        angleOffset: -0.07,
        radiusOffset: 18,
        angularJitter: 0.12,
      ),
      (
        config: regenUncommon,
        level: 2,
        angleOffset: 0.06,
        radiusOffset: 14,
        angularJitter: 0.04,
      ),
      (
        config: rushRare,
        level: 1,
        angleOffset: -0.09,
        radiusOffset: 2,
        angularJitter: 0.26,
      ),
      (
        config: splitUncommon,
        level: 3,
        angleOffset: 0.08,
        radiusOffset: 20,
        angularJitter: 0.13,
      ),
      (
        config: greenBoss,
        level: 1,
        angleOffset: 0,
        radiusOffset: 28,
        angularJitter: 0.04,
      ),
    ];
  }

  EnemyConfig _trialEnemyConfig(
    PrototypeAffinity affinity,
    EnemyCardRarity rarity,
  ) {
    final candidates = EnemyLibrary.byRarity[rarity] ?? EnemyLibrary.all;
    return candidates.firstWhere(
      (config) => config.affinity == affinity,
      orElse: () => EnemyLibrary.basicWhite,
    );
  }

  EnemyConfig _trialBossConfig(PrototypeAffinity affinity) {
    final candidates =
        BossEnemyLibrary.byRarity[EnemyCardRarity.basic] ??
        BossEnemyLibrary.all;
    return candidates.firstWhere(
      (config) => config.affinity == affinity,
      orElse: () => BossEnemyLibrary.starterWhiteWarden,
    );
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
    final levelHealthScale = _enemyCardThreatScale(source);
    final levelLumenScale = _enemyCardLumenScale(source);
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
        _enemyCardDefenseScale(source) *
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
        _managerValue(1, manager?.speedMultiplier ?? 1, managerEffect) *
        _enemyMovementSpeedMultiplier;
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
    final angularVelocity = _enemySpiralMovementEnabled
        ? max(
                0.12,
                _balancedEnemyStat(
                      config,
                      'baseSpiralDrift',
                      config.baseSpiralDrift,
                    ) +
                    angularJitter,
              ) *
              (splitDepth > 0 ? 1.18 : 1) *
              (config.isBoss ? 0.82 : 1.0)
        : 0.0;

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
