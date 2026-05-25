part of '../lightcore_controller.dart';

const double _towerStrengthLayerScaleBase = 10000;
const double _maxTowerStrengthScore = 9000000000000000;

extension LightcoreControllerInventoryRuntime on LightcoreController {
  TowerPatternBonusProfile _inventoryEffectForCard(EnemyCardState card) {
    final config = card.config;
    final bossCard = config.isBoss;
    final healthScale =
        _balancedEnemyStat(config, 'baseHealth', config.baseHealth) /
        (bossCard ? 3200 : 128);
    final defenseScale =
        _balancedEnemyStat(config, 'baseDefense', config.baseDefense) / 140;
    final speedScale =
        _balancedEnemyStat(config, 'baseSpeed', config.baseSpeed) / 21;
    final rewardScale =
        _balancedEnemyStat(config, 'reward', config.reward.toDouble()) /
        (bossCard ? 204 : 20);
    final jamScale =
        _balancedEnemyStat(config, 'jamStrength', config.jamStrength) / 1.02;
    final driftScale =
        _balancedEnemyStat(config, 'baseSpiralDrift', config.baseSpiralDrift) /
        0.78;
    final rarityScale = bossCard
        ? 0.62 + (config.rarity.index * 0.18)
        : 0.42 + (config.rarity.index * 0.22);
    final levelScale = bossCard
        ? 1 + ((card.level - 1) * 0.08)
        : 1 + ((card.level - 1) * 0.045);
    final base = TowerPatternBonusProfile(
      power: 0.006 * (healthScale + defenseScale),
      chargeRate: 0.004 * speedScale,
      cooldownReduction: 0.0026 * speedScale,
      range: 0.003 * driftScale,
      generationSpeed: 0.0028 * (speedScale + (rewardScale * 0.5)),
      critChance: 0.0014 * rewardScale,
      critDamage: 0.0055 * rewardScale,
      finalDamage: 0.0038 * ((jamScale + rewardScale) * 0.5),
      bossDamage: (bossCard ? 0.0054 : 0.0022) * (healthScale + defenseScale),
      normalDamage: 0.0024 * (speedScale + jamScale),
      defensePenetration: 0.002 * defenseScale,
    );
    return base.scale(rarityScale * levelScale);
  }

  double _knowledgeBookDamageMultiplierAgainstEnemy(EnemyState enemy) {
    if (_activeEnemyCardIds.isEmpty) {
      return 1;
    }

    var bestBonus = 0.0;
    for (final card in activeEnemyDeck) {
      if (!card.isOwned) {
        continue;
      }
      final levelScale = 1 + ((card.level - 1).clamp(0, 99) * 0.012);
      final rarityScale = 1 + (card.config.rarity.index * 0.018);
      var bonus = 0.0;
      if (card.config.id == enemy.config.id) {
        bonus = 0.08;
      } else if (card.config.affinity == enemy.config.affinity) {
        bonus = 0.025;
      }
      if (bonus <= 0) {
        continue;
      }
      bestBonus = max(bestBonus, bonus * levelScale * rarityScale);
    }
    return 1 + bestBonus.clamp(0.0, 0.30);
  }

  @visibleForTesting
  double debugKnowledgeBookDamageMultiplierAgainstEnemy(EnemyState enemy) =>
      _knowledgeBookDamageMultiplierAgainstEnemy(enemy);

  String knowledgeTargetLabelForCard(EnemyCardState card) {
    final affinity = card.config.affinity.label;
    final exactBonus = (_knowledgeCardExactMatchBonus(card) * 100)
        .toStringAsFixed(1);
    return '+$exactBonus% vs ${card.config.name}; smaller bonus vs $affinity signatures';
  }

  double _knowledgeCardExactMatchBonus(EnemyCardState card) {
    final levelScale = 1 + ((card.level - 1).clamp(0, 99) * 0.012);
    final rarityScale = 1 + (card.config.rarity.index * 0.018);
    return (0.08 * levelScale * rarityScale).clamp(0.0, 0.30).toDouble();
  }

  double _computeTowerStrength() {
    final liveTowerScore = _slots
        .where(_slotCountsTowardRing)
        .fold<double>(0, (sum, tower) => sum + _towerStrengthForTower(tower));
    final coreScore =
        (coreState.level * 125) +
        (coreState.flowEfficiency * 5.2) +
        (coreEffectiveRange * 0.34) +
        (coreEffectiveShotsPerSecond * 180);
    final equipmentScore = EquipmentLoadoutSlot.values.fold<double>(0, (
      sum,
      slot,
    ) {
      final item = equippedPlayerItemForSlot(slot);
      return item == null ? sum : sum + _equippedItemStrengthScore(item);
    });
    final medalScore = _profileMedalStrengthScore(profileMedalBonuses);
    final enemyScore = _enemyCards.fold<double>(0, (sum, card) {
      if (!card.isOwned) {
        return sum;
      }
      return sum + _collectionScoreForEnemyCard(card, boss: false);
    });
    final bossScore = _bossEnemyCards.fold<double>(0, (sum, card) {
      if (!card.isOwned) {
        return sum;
      }
      return sum + _collectionScoreForEnemyCard(card, boss: true);
    });
    final progressionScore =
        ((1 + totalRadianceStatPointsSpent) * 55) +
        (prestigeLevel * 180) +
        (activeLayer.tier * 140) +
        (builtTowerCount * 42) +
        (promotionReadyTowerCount * 36);
    final baseScore = max(
      1.0,
      liveTowerScore +
          coreScore +
          equipmentScore +
          medalScore +
          enemyScore +
          bossScore +
          progressionScore,
    );
    final layerScale = pow(
      _towerStrengthLayerScaleBase,
      max(0, activeLayer.tier - 1),
    ).toDouble();
    return min(_maxTowerStrengthScore, baseScore * layerScale);
  }

  double _computeGlobalRankingTowerStrength() {
    if (_layers.length <= 1) {
      return _computeTowerStrength();
    }

    final originalActiveLayerId = _activeLayerId;
    final originalSlots = _slots;
    final originalCore = _core;
    final originalLayer2 = _layer2;
    final originalActiveEnemyCardIds = _activeEnemyCardIds;
    final originalActiveBossEnemyCardId = _activeBossEnemyCardId;
    final originalEnemyTargetCount = _enemyTargetCount;
    final originalEnemyTargetUpgradeLevel = _enemyTargetUpgradeLevel;
    final originalOuterRingRevealed = _outerRingRevealed;
    final originalSwarmActivated = _swarmActivated;

    var bestStrength = 0.0;
    try {
      for (final layer in _layers) {
        _activeLayerId = layer.id;
        _slots = layer.slots;
        _core = layer.core;
        _layer2 = layer.layer2;
        _activeEnemyCardIds = layer.activeEnemyCardIds;
        _activeBossEnemyCardId = layer.activeBossEnemyCardId;
        _enemyTargetCount = layer.enemyTargetCount;
        _enemyTargetUpgradeLevel = layer.enemyTargetUpgradeLevel;
        _outerRingRevealed = layer.outerRingRevealed;
        _swarmActivated = layer.swarmActivated;
        bestStrength = max(bestStrength, _computeTowerStrength());
      }
    } finally {
      _activeLayerId = originalActiveLayerId;
      _slots = originalSlots;
      _core = originalCore;
      _layer2 = originalLayer2;
      _activeEnemyCardIds = originalActiveEnemyCardIds;
      _activeBossEnemyCardId = originalActiveBossEnemyCardId;
      _enemyTargetCount = originalEnemyTargetCount;
      _enemyTargetUpgradeLevel = originalEnemyTargetUpgradeLevel;
      _outerRingRevealed = originalOuterRingRevealed;
      _swarmActivated = originalSwarmActivated;
    }

    return min(
      _maxTowerStrengthScore,
      max(bestStrength, _computeTowerStrength()),
    );
  }

  double _towerStrengthForTower(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }

    final power = towerPower(tower);
    final chargeRate = towerChargeRate(tower);
    final liveCooldown = max(0.1, towerLiveCooldown(tower));
    final range = towerEffectiveRange(tower);
    final generation = towerGenerationSpeed(tower);
    final critChance = towerCritChance(tower);
    final critDamage = towerCritMultiplier(tower);
    final finalDamage = towerFinalDamageMultiplier(tower);
    final bossDamage = towerBossDamageMultiplier(tower);
    final normalDamage = towerNormalDamageMultiplier(tower);
    final defensePenetration = towerDefensePenetration(tower);
    final minDamage = towerMinDamageMultiplier(tower);
    final maxDamage = towerMaxDamageMultiplier(tower);
    final dotDamage = towerDotDamageMultiplier(tower);
    final advantage = towerAdvantageMultiplier(tower);
    final liveUptime = 1 - towerDisruptionFraction(tower);
    final averageDamageRange = (minDamage + maxDamage) / 2;
    final expectedCritMultiplier = 1 + (critChance * max(0, critDamage - 1));
    final typeDamageMultiplier = (normalDamage * 0.72) + (bossDamage * 0.28);
    final penetrationMultiplier = 1 + (defensePenetration * 0.9);
    final activationRate = towerUsesPersistentShieldRing(tower)
        ? 1.0
        : max(0.05, towerWantedActivationRate(tower));
    final rangeCoverage = (range / max(1.0, defaultTowerBaseRange))
        .clamp(0.5, 2.4)
        .toDouble();
    final generationUtility = towerUsesPersistentShieldRing(tower)
        ? 1.0
        : (1 + generation).clamp(0.6, 3.0).toDouble();
    final outputScore =
        power *
        activationRate *
        120 *
        finalDamage *
        typeDamageMultiplier *
        averageDamageRange *
        dotDamage *
        expectedCritMultiplier *
        penetrationMultiplier *
        advantage *
        rangeCoverage *
        generationUtility *
        liveUptime;
    final passiveShieldScore = towerUsesPersistentShieldRing(tower)
        ? power * 24
        : 0.0;
    return outputScore +
        passiveShieldScore +
        (power * 2.8) +
        (chargeRate * 90) +
        ((1 / liveCooldown) * 60) +
        (range * 0.16) +
        (generation * 70) +
        (critChance * 260) +
        (critDamage * 38) +
        (finalDamage * 54) +
        (bossDamage * 44) +
        (normalDamage * 36) +
        (defensePenetration * 240) +
        (minDamage * 28) +
        (maxDamage * 34) +
        (dotDamage * 42) +
        (advantage * 32) +
        (tower.level * 24) +
        (liveUptime * 18);
  }

  double _equippedItemStrengthScore(PlayerEquipmentItem item) {
    final combatProfile = _combatBonusProfileFromEquipment(item.bonuses);
    final economyScore =
        (item.bonuses.lumenGain * 150) +
        (item.bonuses.fluxGain * 120) +
        (item.bonuses.ticketGain * 140) +
        (item.bonuses.dropRate * 160);
    return (item.level * 24) +
        (item.rarity.score * 36) +
        (_towerBonusMagnitude(combatProfile) * 120) +
        economyScore;
  }

  double _profileMedalStrengthScore(EquipmentBonusProfile bonuses) {
    if (bonuses.isEmpty) {
      return 0;
    }
    final combatProfile = _combatBonusProfileFromEquipment(bonuses);
    final economyScore =
        (bonuses.lumenGain * 150) +
        (bonuses.fluxGain * 120) +
        (bonuses.ticketGain * 140) +
        (bonuses.dropRate * 160);
    return (_towerBonusMagnitude(combatProfile) * 140) + economyScore;
  }

  double _collectionScoreForEnemyCard(
    EnemyCardState card, {
    required bool boss,
  }) {
    final effect = boss
        ? bossInventoryEffectForCard(card)
        : enemyInventoryEffectForCard(card);
    final copyScore = boss ? 0 : (card.copies * 2.5);
    return (card.level * (boss ? 18 : 8)) +
        ((card.config.rarity.index + 1) * (boss ? 34 : 14)) +
        _towerBonusMagnitude(effect) * (boss ? 170 : 120) +
        copyScore;
  }

  TowerPatternBonusProfile _combatBonusProfileFromEquipment(
    EquipmentBonusProfile bonuses,
  ) {
    return TowerPatternBonusProfile(
      power: bonuses.towerPower,
      chargeRate: bonuses.chargeRate,
      range: bonuses.range,
      critChance: bonuses.critChance,
      critDamage: bonuses.critDamage,
      bossDamage: bonuses.bossDamage,
    );
  }

  double _towerBonusMagnitude(TowerPatternBonusProfile bonus) {
    return (bonus.power * 1.4) +
        (bonus.chargeRate * 1.2) +
        (bonus.cooldownReduction * 1.6) +
        (bonus.range * 1.0) +
        (bonus.generationSpeed * 1.0) +
        (bonus.critChance * 1.8) +
        (bonus.critDamage * 1.2) +
        (bonus.finalDamage * 1.5) +
        (bonus.bossDamage * 1.6) +
        (bonus.normalDamage * 1.3) +
        (bonus.defensePenetration * 1.5);
  }

  List<String> _towerBonusHighlights(
    TowerPatternBonusProfile bonus, {
    required int maxItems,
  }) {
    final entries = <({String text, double weight})>[
      if (bonus.power > 0)
        (
          text: '+${_formatPositivePercent(bonus.power)} Power',
          weight: bonus.power,
        ),
      if (bonus.chargeRate > 0)
        (
          text: '+${_formatPositivePercent(bonus.chargeRate)} Charge',
          weight: bonus.chargeRate,
        ),
      if (bonus.cooldownReduction > 0)
        (
          text: '-${_formatPositivePercent(bonus.cooldownReduction)} CD',
          weight: bonus.cooldownReduction,
        ),
      if (bonus.range > 0)
        (
          text: '+${_formatPositivePercent(bonus.range)} Range',
          weight: bonus.range,
        ),
      if (bonus.generationSpeed > 0)
        (
          text: '+${_formatPositivePercent(bonus.generationSpeed)} Gen',
          weight: bonus.generationSpeed,
        ),
      if (bonus.critChance > 0)
        (
          text: '+${_formatPositivePercent(bonus.critChance)} Crit',
          weight: bonus.critChance,
        ),
      if (bonus.critDamage > 0)
        (
          text: '+${_formatPositivePercent(bonus.critDamage)} Crit Dmg',
          weight: bonus.critDamage,
        ),
      if (bonus.finalDamage > 0)
        (
          text: '+${_formatPositivePercent(bonus.finalDamage)} Final',
          weight: bonus.finalDamage,
        ),
      if (bonus.bossDamage > 0)
        (
          text: '+${_formatPositivePercent(bonus.bossDamage)} Apex',
          weight: bonus.bossDamage,
        ),
      if (bonus.normalDamage > 0)
        (
          text: '+${_formatPositivePercent(bonus.normalDamage)} Normal',
          weight: bonus.normalDamage,
        ),
      if (bonus.defensePenetration > 0)
        (
          text: '+${_formatPositivePercent(bonus.defensePenetration)} Def Pen',
          weight: bonus.defensePenetration,
        ),
    ];
    entries.sort((a, b) => b.weight.compareTo(a.weight));
    return entries.take(maxItems).map((entry) => entry.text).toList();
  }

  String _towerBonusSummary(TowerPatternBonusProfile bonus) {
    final highlights = _towerBonusHighlights(bonus, maxItems: 3);
    if (highlights.isEmpty) {
      return 'No tower bonus';
    }
    return highlights.join(' • ');
  }

  String _compactNumber(int value) {
    if (value >= 1000000000000000) {
      return '${(value / 1000000000000000).toStringAsFixed(value >= 10000000000000000 ? 0 : 1)}Q';
    }
    if (value >= 1000000000000) {
      return '${(value / 1000000000000).toStringAsFixed(value >= 10000000000000 ? 0 : 1)}T';
    }
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(value >= 10000000000 ? 0 : 1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}K';
    }
    return value.toString();
  }

  String _formatPositivePercent(double value) {
    final percent = value * 100;
    return percent >= 10
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
  }

  double _towerManagerAffinityBonus(
    OuterTowerState tower,
    InventoryCard? manager,
  ) {
    if (!tower.isBuilt ||
        manager == null ||
        manager.favoredAffinity != _slotAffinity(tower)) {
      return 1;
    }
    return managerPowerAdjustedMultiplier(
      1 + ((manager.rarity.score + 1) * 0.04),
    );
  }

  double _towerManagerTraitBonus(
    OuterTowerState tower,
    InventoryCard? manager,
  ) {
    if (!tower.isBuilt || manager == null) {
      return 1;
    }

    final projectileMatch =
        manager.projectileFocus != null &&
        manager.projectileFocus == _slotProjectileType(tower);
    final payloadMatch =
        manager.payloadFocus != null &&
        manager.payloadFocus == _slotPayloadType(tower);
    final matchCount = (projectileMatch ? 1 : 0) + (payloadMatch ? 1 : 0);
    return managerPowerAdjustedMultiplier(
      1 + (matchCount * ((manager.rarity.score + 1) * 0.025)),
    );
  }

  String _threatScanBundleId(List<EnemyCardState> deck) {
    if (deck.isEmpty) {
      return 'threat_scan.empty';
    }
    final ids = deck.map((card) => card.config.id).toList()..sort();
    return 'threat_scan.${ids.join('+')}';
  }

  String _threatScanBundleName(
    List<EnemyCardState> deck,
    PrototypeAffinity? primaryAffinity,
  ) {
    if (deck.isEmpty || primaryAffinity == null) {
      return 'Dormant Active Threat Bundle';
    }
    final primaryAffinities = deck.map((card) => card.config.affinity).toSet();
    if (primaryAffinities.length == 1) {
      return '${primaryAffinity.label} Active Threat Bundle';
    }
    return '${primaryAffinity.label}-Led Active Threat Bundle';
  }

  String _threatScanBundleSummary(
    List<EnemyCardState> deck, {
    required PrototypeAffinity? primaryAffinity,
    required List<String> directorNames,
    required int targetCount,
  }) {
    if (deck.isEmpty) {
      return 'No Knowledge Cards are set, so this core is running baseline region pressure at $targetCount active target${targetCount == 1 ? '' : 's'}.';
    }
    final affinityLabel = primaryAffinity?.label ?? 'Mixed';
    final directorLabel = directorNames.isEmpty
        ? 'no Threat Directors'
        : '${directorNames.length} Threat Director${directorNames.length == 1 ? '' : 's'}';
    final cardLabel = deck.map((card) => card.config.name).join(', ');
    return 'Active anomaly deck: $affinityLabel pressure from $cardLabel with $directorLabel at $targetCount region-managed target${targetCount == 1 ? '' : 's'}.';
  }

  PrototypeAffinity? _dominantThreatAffinity(List<EnemyCardState> deck) {
    if (deck.isEmpty) {
      return null;
    }
    final scores = <PrototypeAffinity, double>{};
    for (final card in deck) {
      for (final affinity in card.config.affinities) {
        scores.update(affinity, (score) => score + 1, ifAbsent: () => 1);
      }
    }

    PrototypeAffinity? bestAffinity;
    var bestScore = -1.0;
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestAffinity = entry.key;
        bestScore = entry.value;
      }
    }
    return bestAffinity;
  }

  List<String> _activeThreatDirectorNames(List<EnemyCardState> deck) {
    if (deck.isEmpty || !managerAssignmentUnlocked) {
      return const <String>[];
    }
    final manager = _enemyCoreManagerForLayer(activeLayer);
    return manager == null
        ? const <String>[]
        : List<String>.unmodifiable(<String>['Region: ${manager.name}']);
  }

  String _threatScanRiskLabel({
    required bool hasDeck,
    required double threatReward,
    required double stabilityPressure,
    required double outputEfficiency,
    required int targetCount,
    required int targetMax,
  }) {
    if (!hasDeck) {
      return 'Dormant';
    }
    final targetLoad = targetMax <= 0 ? 0.0 : targetCount / targetMax;
    final pressureScore =
        (threatReward * 0.22) +
        (stabilityPressure * 0.48) +
        (targetLoad * 0.6) +
        ((1 - outputEfficiency).clamp(0.0, 1.0) * 0.9);
    if (outputEfficiency < 0.45 || pressureScore >= 2.0) {
      return 'Critical';
    }
    if (outputEfficiency < 0.65 || pressureScore >= 1.45) {
      return 'High';
    }
    if (pressureScore >= 1.05) {
      return 'Moderate';
    }
    return 'Low';
  }

  String _threatCounterplayLabel(PrototypeAffinity? affinity) {
    return switch (affinity) {
      PrototypeAffinity.neutral =>
        'Counterplay: fundamentals, clean priority, and range coverage.',
      PrototypeAffinity.ember =>
        'Counterplay: burst windows, defense penetration, and overkill control.',
      PrototypeAffinity.flare =>
        'Counterplay: slow, freeze, knockback, and early lane control.',
      PrototypeAffinity.solar =>
        'Counterplay: accuracy, beam uptime, and shock or disrupt marks.',
      PrototypeAffinity.verdant =>
        'Counterplay: anti-regen pressure, burn finishers, and sustained focus.',
      PrototypeAffinity.aether =>
        'Counterplay: disruption recovery, slows, and longer range buffers.',
      PrototypeAffinity.violet =>
        'Counterplay: area damage, chains, and fast split cleanup.',
      PrototypeAffinity.black =>
        'Counterplay: pierce, gravity control, and high minimum damage.',
      null => 'Set Knowledge Cards to reveal this bundle counterplay package.',
    };
  }

  double _enemySpawnPressureMultiplier({List<EnemyCardState>? deck}) {
    final resolvedDeck = deck ?? activeEnemyDeck;
    if (resolvedDeck.isEmpty) {
      return 1;
    }
    final total = resolvedDeck.fold(0.0, (sum, card) {
      final manager = enemyManagerForCard(card.config.id);
      final effect = _enemyManagerEffectMultiplier(card, manager);
      return sum + _managerValue(1, manager?.spawnRateMultiplier ?? 1, effect);
    });
    return max(0.82, total / resolvedDeck.length);
  }

  double _threatRewardMultiplierForCard(EnemyCardState card) {
    final manager = enemyManagerForCard(card.config.id);
    final effect = _enemyManagerEffectMultiplier(card, manager);
    return card.config.threatRewardMultiplier *
        _managerValue(1, manager?.rewardMultiplier ?? 1, effect);
  }

  double _threatStabilityMultiplierForCard(EnemyCardState card) {
    final manager = enemyManagerForCard(card.config.id);
    final effect = _enemyManagerEffectMultiplier(card, manager);
    return card.config.stabilityDamageMultiplier *
        _managerValue(1, manager?.stabilityDamageMultiplier ?? 1, effect);
  }

  double _directorApexStabilityMultiplier() {
    final deck = activeEnemyDeck;
    if (deck.isEmpty) {
      return 1;
    }
    return deck.fold(0.0, (sum, card) {
          final manager = enemyManagerForCard(card.config.id);
          final effect = _enemyManagerEffectMultiplier(card, manager);
          return sum +
              _managerValue(1, manager?.apexStabilityMultiplier ?? 1, effect);
        }) /
        deck.length;
  }

  EnemyCardState _pickEnemyCardForSpawn(List<EnemyCardState> deck) {
    final weightedDeck = <({EnemyCardState card, double weight})>[];
    var totalWeight = 0.0;
    for (final card in deck) {
      final manager = enemyManagerForCard(card.config.id);
      final effect = _enemyManagerEffectMultiplier(card, manager);
      final weight = max(
        0.12,
        _managerValue(1, manager?.spawnRateMultiplier ?? 1, effect),
      );
      weightedDeck.add((card: card, weight: weight));
      totalWeight += weight;
    }

    var roll = _packRandom.nextDouble() * totalWeight;
    for (final entry in weightedDeck) {
      roll -= entry.weight;
      if (roll <= 0) {
        return entry.card;
      }
    }
    return weightedDeck.last.card;
  }

  double _enemyManagerEffectMultiplier(
    EnemyCardState card,
    EnemyManagerState? manager,
  ) {
    if (manager == null) {
      return 0;
    }
    if (manager.targetAffinity == null ||
        manager.targetAffinity == card.config.affinity) {
      return 1;
    }
    return 0.45;
  }

  double managerPowerAdjustedMultiplier(double target, {double base = 1}) =>
      base + ((target - base) * managerPowerEffectMultiplier);

  double managerPowerAdjustedCooldown(double target) {
    if (target >= 1) {
      return managerPowerAdjustedMultiplier(target);
    }
    return max(0.42, 1 - ((1 - target) * managerPowerEffectMultiplier));
  }

  double managerPowerAdjustedRate(double target) =>
      target * managerPowerEffectMultiplier;

  double _managerValue(double base, double target, double effectMultiplier) =>
      base +
      ((target - base) * effectMultiplier * managerPowerEffectMultiplier);

  ProjectileType _rollProjectileTrait(TowerConfig config) =>
      _rollWeighted(config.projectileWeights);

  PayloadType _rollPayloadTrait(TowerConfig config) =>
      _rollWeighted(config.payloadWeights);

  T _rollWeighted<T>(Map<T, int> weights) {
    final total = weights.values.fold(0, (sum, weight) => sum + weight);
    var roll = _traitRandom.nextInt(total);
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) {
        return entry.key;
      }
    }
    return weights.keys.first;
  }

  T _rollWeightedWithRandom<T>(Map<T, int> weights, Random random) {
    final total = weights.values.fold(0, (sum, weight) => sum + weight);
    var roll = random.nextInt(max(1, total));
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) {
        return entry.key;
      }
    }
    return weights.keys.first;
  }

  int _promotionTraitSeedForLayer(
    TowerLayerSnapshot layer, {
    required int targetTier,
  }) {
    var hash = 17;
    hash =
        (hash * 37) +
        max(0, _layers.indexWhere((entry) => entry.id == layer.id));
    hash = (hash * 37) + targetTier;
    hash = (hash * 37) + layer.promotionTraitRoll;
    for (final tower in layer.slots.where(_slotCountsTowardRing)) {
      hash = (hash * 37) + tower.slotIndex;
      hash = (hash * 37) + _effectiveTowerLevel(tower);
      hash = (hash * 37) + _slotAffinity(tower).index;
      hash =
          (hash * 37) +
          (_slotSecondaryAffinity(tower) ?? _slotAffinity(tower)).index;
      hash = (hash * 37) + _slotProjectileType(tower).index;
      hash = (hash * 37) + _slotPayloadType(tower).index;
    }
    return hash & 0x7fffffff;
  }

  Map<PrototypeAffinity, int> _projectileAffinityWeightsForLayer(
    TowerLayerSnapshot layer,
  ) {
    final built = layer.slots.where(_slotCountsTowardRing).toList();
    final counts = <PrototypeAffinity, int>{};
    _addCoreProjectileAffinityWeights(layer, counts);
    for (final tower in built) {
      if (_towerHasRainbowLoadout(tower)) {
        for (final affinity in chromaticTowerAffinities) {
          counts.update(
            affinity,
            (value) => value + _effectiveTowerLevel(tower),
            ifAbsent: () => _effectiveTowerLevel(tower),
          );
        }
        continue;
      }
      final affinity = _slotAffinity(tower);
      counts.update(
        affinity,
        (value) => value + _effectiveTowerLevel(tower),
        ifAbsent: () => _effectiveTowerLevel(tower),
      );
    }
    if (counts.isEmpty) {
      counts[layer.core.affinity] = 1;
    }
    return counts;
  }

  Map<PrototypeAffinity, int> _payloadAffinityWeightsForLayer(
    TowerLayerSnapshot layer,
  ) {
    final built = layer.slots.where(_slotCountsTowardRing).toList();
    final counts = <PrototypeAffinity, int>{};
    _addCorePayloadAffinityWeights(layer, counts);
    for (final tower in built) {
      if (_towerHasRainbowLoadout(tower)) {
        for (final affinity in chromaticTowerAffinities) {
          counts.update(
            affinity,
            (value) => value + _effectiveTowerLevel(tower),
            ifAbsent: () => _effectiveTowerLevel(tower),
          );
        }
        continue;
      }
      final affinity = _slotSecondaryAffinity(tower) ?? _slotAffinity(tower);
      counts.update(
        affinity,
        (value) => value + _effectiveTowerLevel(tower),
        ifAbsent: () => _effectiveTowerLevel(tower),
      );
    }
    if (counts.isEmpty) {
      counts[layer.core.secondaryAffinity ?? layer.core.affinity] = 1;
    }
    return counts;
  }

  void _addCoreProjectileAffinityWeights(
    TowerLayerSnapshot layer,
    Map<PrototypeAffinity, int> counts,
  ) {
    final weight = max(1, layer.core.level);
    final loadout = layer.core.projectileLoadout.isNotEmpty
        ? layer.core.projectileLoadout
        : <ProjectileType>[layer.core.projectileType];
    final affinities = loadout.map((type) => type.affinity).toSet();
    for (final affinity in affinities) {
      counts.update(
        affinity,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
    }
  }

  void _addCorePayloadAffinityWeights(
    TowerLayerSnapshot layer,
    Map<PrototypeAffinity, int> counts,
  ) {
    final weight = max(1, layer.core.level);
    final loadout = layer.core.payloadLoadout.isNotEmpty
        ? layer.core.payloadLoadout
        : <PayloadType>[layer.core.payloadType];
    final affinities = loadout
        .map((type) => type.affinity)
        .whereType<PrototypeAffinity>()
        .toSet();
    if (affinities.isEmpty) {
      affinities.add(layer.core.secondaryAffinity ?? layer.core.affinity);
    }
    for (final affinity in affinities) {
      counts.update(
        affinity,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
    }
  }

  bool _layerCanRollRainbowTower(
    TowerLayerSnapshot layer, {
    required int targetTier,
  }) {
    if (targetTier != payloadUnlockLayer) {
      return false;
    }
    final built = layer.slots.where(_slotCountsTowardRing).toList();
    if (built.length < slotCount) {
      return false;
    }
    final affinities = <PrototypeAffinity>{};
    for (final tower in built) {
      affinities.add(_slotAffinity(tower));
    }
    return chromaticTowerAffinities.every(affinities.contains);
  }

  double _rainbowChanceForPromotionLayer(
    TowerLayerSnapshot layer, {
    required int targetTier,
  }) => _layerCanRollRainbowTower(layer, targetTier: targetTier)
      ? rainbowPromotionChance
      : 0;

  Map<PrototypeAffinity, double> _promotionAffinityRates(
    Map<PrototypeAffinity, int> weights, {
    required double rainbowChance,
  }) {
    final total = weights.values.fold(0, (sum, weight) => sum + weight);
    if (total <= 0) {
      return const <PrototypeAffinity, double>{};
    }
    final rates = <PrototypeAffinity, double>{};
    final orderedAffinities = <PrototypeAffinity>[
      ...chromaticTowerAffinities,
      PrototypeAffinity.neutral,
      PrototypeAffinity.black,
    ];
    final normalChance = max(0.0, 1 - rainbowChance);
    for (final affinity in orderedAffinities) {
      final weight = weights[affinity] ?? 0;
      if (weight <= 0) {
        continue;
      }
      rates[affinity] = normalChance * weight / total;
    }
    for (final entry in weights.entries) {
      if (rates.containsKey(entry.key) || entry.value <= 0) {
        continue;
      }
      rates[entry.key] = normalChance * entry.value / total;
    }
    return Map<PrototypeAffinity, double>.unmodifiable(rates);
  }

  ({
    PrototypeAffinity projectileAffinity,
    PrototypeAffinity? payloadAffinity,
    List<ProjectileType> projectileLoadout,
    List<PayloadType> payloadLoadout,
    bool rainbow,
  })
  _resolvePromotedTraitLoadoutForLayer(
    TowerLayerSnapshot layer, {
    required int targetTier,
  }) {
    final random = Random(
      _promotionTraitSeedForLayer(layer, targetTier: targetTier),
    );
    if (_layerCanRollRainbowTower(layer, targetTier: targetTier) &&
        random.nextDouble() < rainbowPromotionChance) {
      return (
        projectileAffinity: PrototypeAffinity.neutral,
        payloadAffinity: null,
        projectileLoadout: layer2RainbowProjectileLoadout,
        payloadLoadout: layer2RainbowPayloadLoadout,
        rainbow: true,
      );
    }
    final projectileAffinity = _rollWeightedWithRandom(
      _projectileAffinityWeightsForLayer(layer),
      random,
    );
    final projectileOptions = forgedProjectilesForAffinity(
      projectileAffinity,
      targetTier: targetTier,
    );
    final projectile =
        projectileOptions[random.nextInt(projectileOptions.length)];
    if (targetTier < payloadUnlockLayer) {
      return (
        projectileAffinity: projectileAffinity,
        payloadAffinity: null,
        projectileLoadout: <ProjectileType>[projectile],
        payloadLoadout: const <PayloadType>[PayloadType.none],
        rainbow: false,
      );
    }

    final payloadAffinity = _rollWeightedWithRandom(
      _payloadAffinityWeightsForLayer(layer),
      random,
    );
    final payloadOptions = forgedPayloadsForAffinity(
      payloadAffinity,
      targetTier: targetTier,
    );
    final payload = payloadOptions[random.nextInt(payloadOptions.length)];
    return (
      projectileAffinity: projectileAffinity,
      payloadAffinity: payloadAffinity,
      projectileLoadout: <ProjectileType>[projectile],
      payloadLoadout: <PayloadType>[payload],
      rainbow: false,
    );
  }

  double _averageTowerMetricForLayer(
    TowerLayerSnapshot layer,
    double Function(OuterTowerState tower) selector, {
    required double fallback,
  }) {
    final built = layer.slots.where(_slotCountsTowardRing).toList();
    if (built.isEmpty) {
      return fallback;
    }
    var totalWeight = 0.0;
    var weighted = 0.0;
    for (final tower in built) {
      final weight = _effectiveTowerLevel(tower).toDouble();
      totalWeight += weight;
      weighted += selector(tower) * weight;
    }
    if (totalWeight <= 0) {
      return fallback;
    }
    return weighted / totalWeight;
  }

  double _averageRangeForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerBaseRange,
        fallback: coreBaseRange,
      );

  double _averageGenerationForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(layer, towerGenerationSpeed, fallback: 1.0);

  double _averageCritChanceForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerCritChance,
        fallback: _coreBaseCritChance,
      );

  double _averageCritMultiplierForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerCritMultiplier,
        fallback: _coreBaseCritMultiplier,
      );

  double _averageFinalDamageForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerFinalDamageMultiplier,
        fallback: 1.0,
      );

  double _averageBossDamageForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerBossDamageMultiplier,
        fallback: 1.0,
      );

  double _averageNormalDamageForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerNormalDamageMultiplier,
        fallback: 1.0,
      );

  double _averageDefensePenetrationForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerDefensePenetration,
        fallback: 0.0,
      );

  double _averageMinDamageForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerMinDamageMultiplier,
        fallback: 1.0,
      );

  double _averageMaxDamageForLayer(TowerLayerSnapshot layer) =>
      _averageTowerMetricForLayer(
        layer,
        towerMaxDamageMultiplier,
        fallback: 1.0,
      );

  EnemyCardRarity _rollPackRarity() {
    return _rollEnemyCardRarity(summonRates);
  }

  EnemyCardRarity _rollBossPackRarity() {
    return _rollEnemyCardRarity(bossSummonRates);
  }

  EnemyCardRarity _rollEnemyCardRarity(Map<EnemyCardRarity, double> rates) {
    final roll = _packRandom.nextDouble() * 100;
    var running = 0.0;
    for (final rarity in EnemyCardRarity.values) {
      running += rates[rarity] ?? 0;
      if (roll < running) {
        return rarity;
      }
    }
    return EnemyCardRarity.legendary;
  }

  ManagerRarity _rollManagerRarity() {
    final roll = _managerRandom.nextDouble() * 100;
    var running = 0.0;
    final rates = managerForgeRates;
    for (final rarity in ManagerRarity.values) {
      running += rates[rarity] ?? 0;
      if (roll < running) {
        return rarity;
      }
    }
    return ManagerRarity.legendary;
  }

  InventoryCard _generateTowerManager({
    required int forgeCost,
    ManagerRarity? forcedRarity,
  }) {
    final rarity = forcedRarity ?? _rollManagerRarity();
    final template = CardLibrary
        .templates[_managerRandom.nextInt(CardLibrary.templates.length)];
    final focusAffinities = PrototypeAffinity.values
        .where(
          (affinity) =>
              affinity != PrototypeAffinity.neutral &&
              affinity != PrototypeAffinity.black,
        )
        .toList(growable: false);
    final projectileOptions = ProjectileType.values
        .where((type) => type.tier >= 2)
        .toList(growable: false);
    final payloadOptions = PayloadType.values
        .where((type) => type != PayloadType.none)
        .toList(growable: false);
    final scale = 1 + (rarity.score * 0.12);
    final powerMultiplier = 1 + ((template.powerMultiplier - 1) * scale);
    final chargeMultiplier = 1 + ((template.chargeMultiplier - 1) * scale);
    final cooldownMultiplier = max(
      0.68,
      1 - ((1 - template.cooldownMultiplier) * (1 + (rarity.score * 0.14))),
    );
    final advantageMultiplier =
        1 + ((template.advantageMultiplier - 1) * (1 + (rarity.score * 0.16)));
    final automationRate =
        template.automationRate * (1 + (rarity.score * 0.11));
    return InventoryCard(
      instanceId:
          'tower_manager_${_cards.length}_${_managerRandom.nextInt(99999)}',
      config: template,
      rarity: rarity,
      forgeCost: forgeCost,
      powerMultiplier: powerMultiplier,
      chargeMultiplier: chargeMultiplier,
      cooldownMultiplier: cooldownMultiplier,
      advantageMultiplier: advantageMultiplier,
      automationRate: automationRate,
      favoredAffinity:
          focusAffinities[_managerRandom.nextInt(focusAffinities.length)],
      projectileFocus:
          projectileOptions[_managerRandom.nextInt(projectileOptions.length)],
      payloadFocus:
          payloadOptions[_managerRandom.nextInt(payloadOptions.length)],
      primaryTraitLabel:
          'Power ${_formatSignedPercent(powerMultiplier - 1)} • Charge ${_formatSignedPercent(chargeMultiplier - 1)}',
      secondaryTraitLabel:
          'Automation ${automationRate.toStringAsFixed(2)}/s • Cooldown ${_formatSignedPercent(1 - cooldownMultiplier)} • Matchup ${_formatSignedPercent(advantageMultiplier - 1)}',
    );
  }

  EnemyManagerState _generateEnemyManager({
    required int forgeCost,
    ManagerRarity? forcedRarity,
  }) {
    final rarity = forcedRarity ?? _rollManagerRarity();
    final template = EnemyManagerLibrary
        .all[_managerRandom.nextInt(EnemyManagerLibrary.all.length)];
    final targetOptions = PrototypeAffinity.values.toList(growable: false);
    final targetAffinity = _managerRandom.nextInt(4) == 0
        ? null
        : targetOptions[_managerRandom.nextInt(targetOptions.length)];
    final scale = 1 + (rarity.score * 0.14);
    final spawnRateMultiplier =
        1 + ((template.spawnRateMultiplier - 1) * scale);
    final rewardMultiplier = 1 + ((template.rewardMultiplier - 1) * scale);
    final experienceMultiplier =
        1 + ((template.experienceMultiplier - 1) * scale);
    final healthMultiplier = 1 + ((template.healthMultiplier - 1) * scale);
    final speedMultiplier = 1 + ((template.speedMultiplier - 1) * scale);
    final stabilityDamageMultiplier =
        1 + ((template.stabilityDamageMultiplier - 1) * scale);
    final apexStabilityMultiplier =
        1 + ((template.apexStabilityMultiplier - 1) * scale);
    final queueDisruptionMultiplier =
        1 + ((template.queueDisruptionMultiplier - 1) * scale);
    return EnemyManagerState(
      instanceId:
          'enemy_manager_${_enemyManagers.length}_${_managerRandom.nextInt(99999)}',
      config: template,
      rarity: rarity,
      forgeCost: forgeCost,
      spawnRateMultiplier: spawnRateMultiplier,
      rewardMultiplier: rewardMultiplier,
      experienceMultiplier: experienceMultiplier,
      healthMultiplier: healthMultiplier,
      speedMultiplier: speedMultiplier,
      stabilityDamageMultiplier: stabilityDamageMultiplier,
      apexStabilityMultiplier: apexStabilityMultiplier,
      queueDisruptionMultiplier: queueDisruptionMultiplier,
      targetAffinity: targetAffinity,
      primaryTraitLabel:
          'Spawn ${_formatSignedPercent(spawnRateMultiplier - 1)} • Threat ${_formatSignedPercent(rewardMultiplier - 1)} • EXP ${_formatSignedPercent(experienceMultiplier - 1)}',
      secondaryTraitLabel:
          'Health ${_formatSignedPercent(healthMultiplier - 1)} • Stability ${_formatSignedPercent(stabilityDamageMultiplier - 1)} • Apex ${_formatSignedPercent(apexStabilityMultiplier - 1)}',
    );
  }

  // TODO(full-game): Starter grants should come from account bootstrap data so
  // onboarding, compensation grants, and live-ops events can all use one path.
  void _seedStarterEnemyCards() {
    for (final starterId in <String>[
      EnemyLibrary.starterDefault.id,
      EnemyLibrary.basicWhite.id,
    ]) {
      final index = _enemyCards.indexWhere(
        (card) => card.config.id == starterId,
      );
      if (index == -1) {
        continue;
      }
      final current = _enemyCards[index];
      _enemyCards[index] = _enemyCards[index].copyWith(
        unlocked: true,
        copies: current.unlocked ? current.copies : max(1, current.copies),
      );
    }
  }

  void _seedStarterManagers() {
    return;
  }

  void _updateFlowEfficiency() {
    _core = _core.copyWith(
      flowEfficiency: _outputEfficiencyPercentForStability(_core.coreStability),
    );
  }

  void _drainBanner(double dt) {
    if (_bannerTimer <= 0) {
      return;
    }

    _bannerTimer = max(0.0, _bannerTimer - dt);
    if (_bannerTimer == 0 && bannerMessage.isNotEmpty) {
      bannerMessage = '';
      _needsNotify = true;
    }
  }

  void _advanceLevelUpRadiance(double dt) {
    if (_levelUpRadianceProgress >= 1) {
      return;
    }
    _levelUpRadianceProgress = min(1.0, _levelUpRadianceProgress + (dt * 0.86));
    _needsNotify = true;
  }

  void _resetLevelUpRadiance() {
    _levelUpRadianceProgress = 1;
    _lastLevelUpRadianceLevel = overallLevel;
    _lastLevelUpRadianceDestroyedEnemies = 0;
  }

  void _showBanner(
    String message, {
    double duration = 2.8,
    LightcoreNotificationCategory category =
        LightcoreNotificationCategory.action,
  }) {
    if (_suppressRuntimeBanners || _threatRegionChallenge != null) {
      return;
    }
    if (category == LightcoreNotificationCategory.battle &&
        !_battleNotificationBannersEnabled) {
      return;
    }
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || !duration.isFinite) {
      return;
    }
    bannerMessage = normalizedMessage;
    _bannerTimer = max(0.4, duration);
    _needsNotify = true;
  }

  double _advanceManualOverdrive(double dt) {
    final previousCharge = _manualOverdriveCharge;
    if (!_swarmActivated) {
      if (_manualOverdriveHeld || _manualOverdriveCharge > 0) {
        _resetManualOverdrive();
        _needsNotify = true;
      }
      return 1.0;
    }

    if (_hasPermanentOverdrive) {
      if (_manualOverdriveHeld || _manualOverdriveCharge > 0) {
        _resetManualOverdrive();
        _needsNotify = true;
      }
      return _manualOverdriveMaxMultiplier;
    }

    final chargeDelta =
        (_manualOverdriveHeld
            ? _manualOverdriveChargePerSecond
            : -_manualOverdriveDecayPerSecond) *
        dt;
    final nextCharge = (_manualOverdriveCharge + chargeDelta).clamp(0.0, 1.0);
    _manualOverdriveCharge = nextCharge;
    if (_manualOverdriveHeld &&
        !_tutorialOverdriveLearned &&
        nextCharge >= 0.22) {
      _tutorialOverdriveLearned = true;
      _syncTutorialStep(showBanner: false);
      _showBanner(
        'Overdrive synced. Hold it any time a live lane starts feeling long.',
      );
    }
    if ((nextCharge - previousCharge).abs() >= 0.001) {
      _needsNotify = true;
    }

    final averageCharge = (previousCharge + nextCharge) / 2;
    return 1 + ((_manualOverdriveMaxMultiplier - 1) * averageCharge);
  }

  void _resetManualOverdrive() {
    _manualOverdriveHeld = false;
    _manualOverdriveCharge = 0;
  }

  void _maybeNotify({required bool force}) {
    if (force) {
      _needsNotify = true;
    }
    if (_needsNotify && _notifyAccumulator >= _uiNotifyCadence) {
      _notifyAccumulator = 0;
      _needsNotify = false;
      _dispatchUiNotification();
    }
  }

  void _notifyNow() {
    _notifyAccumulator = 0;
    _needsNotify = false;
    _dispatchUiNotification();
  }

  String _formatSignedPercent(double delta) {
    final value = (delta * 100).round();
    return '${value >= 0 ? '+' : ''}$value%';
  }
}
