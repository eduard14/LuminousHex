part of '../lightcore_controller.dart';

extension LightcoreControllerProgressionLayers on LightcoreController {
  int _boostedExperienceReward(int baseExperience) {
    if (baseExperience <= 0) {
      return 0;
    }
    final multiplier =
        tournamentExperienceMultiplier *
        _radianceExperienceMultiplier *
        _economyBalanceMultiplier('experienceReward');
    return max(1, (baseExperience * multiplier).round());
  }

  String _formatTournamentBoostEnd(DateTime endsAt) {
    final month = switch (endsAt.month) {
      1 => 'Jan',
      2 => 'Feb',
      3 => 'Mar',
      4 => 'Apr',
      5 => 'May',
      6 => 'Jun',
      7 => 'Jul',
      8 => 'Aug',
      9 => 'Sep',
      10 => 'Oct',
      11 => 'Nov',
      12 => 'Dec',
      _ => '',
    };
    final hour = endsAt.hour == 0 ? 12 : ((endsAt.hour - 1) % 12) + 1;
    final meridiem = endsAt.hour >= 12 ? 'PM' : 'AM';
    final minute = endsAt.minute.toString().padLeft(2, '0');
    return '$month ${endsAt.day}, $hour:$minute $meridiem';
  }

  bool _layerHasDescendants(String layerId) => _layers.any(
    (layer) => layer.parentLayerId == layerId || layer.sourceLayerId == layerId,
  );

  double _layerPriceMultiplier(TowerLayerSnapshot layer) {
    final parentId = layer.parentLayerId;
    if (parentId == null) {
      return 1;
    }
    final targetTier = _layerById(parentId).tier;
    return pow(2.4, max(0, targetTier - 1)).toDouble();
  }

  int _effectiveTowerLevel(OuterTowerState tower) => tower.hasTowerProgression
      ? tower.level
      : max(1, tower.childCoreLevel ?? 1);

  double get _overallStatRollBias =>
      ((overallLevel - 1) / 18).clamp(0.0, 0.72).toDouble();

  double _rollBiasedUnit(double qualityBias) {
    final exponent = max(0.34, 1 - qualityBias);
    return pow(_traitRandom.nextDouble(), exponent).toDouble();
  }

  double _rollAroundOne(double variance, {double qualityBias = 0}) =>
      (1 - variance) + (_rollBiasedUnit(qualityBias) * variance * 2);

  double _rollSymmetric(double variance, {double qualityBias = 0}) {
    final biasedCenter = _traitRandom.nextDouble() + (qualityBias * 0.45);
    final normalized = biasedCenter.clamp(0.0, 1.0);
    return -variance + (normalized * variance * 2);
  }

  double _rollPositiveStat(
    double maxBonus, {
    double base = 1,
    double qualityBias = 0,
  }) => base + (_rollBiasedUnit(qualityBias) * maxBonus);

  double _rollPositiveBonus(double maxBonus, {double qualityBias = 0}) =>
      _rollBiasedUnit(qualityBias) * maxBonus;

  bool _projectileUsesInstantBlastOnly(ProjectileType projectileType) {
    final behavior = projectileType.behaviorProfile;
    return projectileType.affinity == PrototypeAffinity.ember &&
        (behavior == ProjectileBehaviorProfile.explosion ||
            behavior == ProjectileBehaviorProfile.nova);
  }

  bool _projectileHasLingeringField(ProjectileType projectileType) {
    if (_projectileUsesInstantBlastOnly(projectileType)) {
      return false;
    }
    return projectileType.behaviorProfile ==
            ProjectileBehaviorProfile.explosion ||
        projectileType.behaviorProfile == ProjectileBehaviorProfile.nova;
  }

  bool _towerLoadoutSupportsDotDamage(
    ProjectileType projectileType,
    PayloadType payloadType,
  ) =>
      projectileType == ProjectileType.shieldHalo ||
      _projectileHasLingeringField(projectileType) ||
      payloadType.effectProfile == PayloadEffectProfile.burn;

  bool _towerConfigSupportsDotDamage(TowerConfig config) =>
      _towerLoadoutSupportsDotDamage(
        config.defaultProjectileType,
        config.defaultPayloadType,
      );

  List<TowerUpgradeStatType> _eligibleTowerUpgradeTypesForLoadout(
    ProjectileType projectileType,
    PayloadType payloadType,
  ) {
    if (projectileType == ProjectileType.shieldHalo) {
      return <TowerUpgradeStatType>[
        TowerUpgradeStatType.power,
        TowerUpgradeStatType.range,
        TowerUpgradeStatType.finalDamage,
        TowerUpgradeStatType.bossDamage,
        TowerUpgradeStatType.normalDamage,
        TowerUpgradeStatType.defensePenetration,
        TowerUpgradeStatType.minDamage,
        TowerUpgradeStatType.maxDamage,
        TowerUpgradeStatType.dotDamage,
      ];
    }
    return <TowerUpgradeStatType>[
      TowerUpgradeStatType.power,
      TowerUpgradeStatType.chargeRate,
      TowerUpgradeStatType.cooldown,
      TowerUpgradeStatType.range,
      TowerUpgradeStatType.generationSpeed,
      TowerUpgradeStatType.critChance,
      TowerUpgradeStatType.critDamage,
      TowerUpgradeStatType.finalDamage,
      TowerUpgradeStatType.bossDamage,
      TowerUpgradeStatType.normalDamage,
      TowerUpgradeStatType.defensePenetration,
      TowerUpgradeStatType.minDamage,
      TowerUpgradeStatType.maxDamage,
      if (_towerLoadoutSupportsDotDamage(projectileType, payloadType))
        TowerUpgradeStatType.dotDamage,
    ];
  }

  List<TowerUpgradeStatType> _eligibleTowerUpgradeTypesForConfig(
    TowerConfig config,
  ) => _eligibleTowerUpgradeTypesForLoadout(
    config.defaultProjectileType,
    config.defaultPayloadType,
  );

  List<TowerUpgradeStatType> _eligibleTowerUpgradeTypesForTower(
    OuterTowerState tower,
  ) {
    final config = tower.config;
    if (config == null) {
      if (!tower.isPromotedChildTower) {
        return const <TowerUpgradeStatType>[];
      }
      return _eligibleTowerUpgradeTypesForLoadout(
        _slotProjectileType(tower),
        _slotPayloadType(tower),
      );
    }
    return _eligibleTowerUpgradeTypesForConfig(config);
  }

  List<TowerUpgradeOptionState> _rollTowerUpgradeBoardForLoadout(
    ProjectileType projectileType,
    PayloadType payloadType,
  ) {
    final pool = _eligibleTowerUpgradeTypesForLoadout(
      projectileType,
      payloadType,
    ).toList(growable: true)..shuffle(_traitRandom);
    final guaranteedType = projectileType == ProjectileType.shieldHalo
        ? TowerUpgradeStatType.power
        : TowerUpgradeStatType.chargeRate;
    final chosen = <TowerUpgradeStatType>[guaranteedType];
    pool.remove(guaranteedType);
    final maxOptions = min(maxTowerUpgradeOptions, pool.length);
    final minOptions = min(minTowerUpgradeOptions, maxOptions);
    final optionCount = minOptions >= maxOptions
        ? maxOptions
        : minOptions + _traitRandom.nextInt((maxOptions - minOptions) + 1);
    final selected = <TowerUpgradeStatType>[
      ...chosen,
      ...pool.take(max(0, optionCount - chosen.length)),
    ];
    final remaining = pool
        .where((type) => !selected.contains(type))
        .toList(growable: true);
    final hasOvercharge =
        remaining.isNotEmpty && _traitRandom.nextDouble() < 0.08;
    final overchargeType = hasOvercharge
        ? remaining[_traitRandom.nextInt(remaining.length)]
        : null;
    if (overchargeType != null) {
      selected.add(overchargeType);
    }
    final radiantIndex = selected.isNotEmpty && _traitRandom.nextDouble() < 0.07
        ? _traitRandom.nextInt(selected.length)
        : -1;
    return <TowerUpgradeOptionState>[
      for (var index = 0; index < selected.length; index += 1)
        TowerUpgradeOptionState(
          type: selected[index],
          isOvercharge: selected[index] == overchargeType,
          isRadiant: index == radiantIndex,
        ),
    ];
  }

  List<TowerUpgradeOptionState> _rollTowerUpgradeBoard(TowerConfig config) =>
      _rollTowerUpgradeBoardForLoadout(
        config.defaultProjectileType,
        config.defaultPayloadType,
      );

  List<TowerUpgradeStatType> _eligibleCoreUpgradeTypesForLoadout(
    ProjectileType projectileType,
    PayloadType payloadType,
  ) => <TowerUpgradeStatType>[
    TowerUpgradeStatType.power,
    TowerUpgradeStatType.cooldown,
    TowerUpgradeStatType.range,
    TowerUpgradeStatType.critChance,
    TowerUpgradeStatType.critDamage,
    TowerUpgradeStatType.finalDamage,
    TowerUpgradeStatType.bossDamage,
    TowerUpgradeStatType.normalDamage,
    TowerUpgradeStatType.defensePenetration,
    TowerUpgradeStatType.minDamage,
    TowerUpgradeStatType.maxDamage,
  ];

  List<TowerUpgradeOptionState> _rollCoreUpgradeBoardForLoadout(
    ProjectileType projectileType,
    PayloadType payloadType,
  ) {
    final pool = _eligibleCoreUpgradeTypesForLoadout(
      projectileType,
      payloadType,
    ).toList(growable: true)..shuffle(_traitRandom);
    const guaranteedType = TowerUpgradeStatType.power;
    final selected = <TowerUpgradeStatType>[guaranteedType];
    pool.remove(guaranteedType);
    final maxOptions = min(maxTowerUpgradeOptions, pool.length + 1);
    final minOptions = min(minTowerUpgradeOptions, maxOptions);
    final optionCount = minOptions >= maxOptions
        ? maxOptions
        : minOptions + _traitRandom.nextInt((maxOptions - minOptions) + 1);
    selected.addAll(pool.take(max(0, optionCount - selected.length)));

    final remaining = pool
        .where((type) => !selected.contains(type))
        .toList(growable: true);
    final hasOvercharge =
        remaining.isNotEmpty && _traitRandom.nextDouble() < 0.08;
    final overchargeType = hasOvercharge
        ? remaining[_traitRandom.nextInt(remaining.length)]
        : null;
    if (overchargeType != null) {
      selected.add(overchargeType);
    }
    final radiantIndex = selected.isNotEmpty && _traitRandom.nextDouble() < 0.07
        ? _traitRandom.nextInt(selected.length)
        : -1;
    return <TowerUpgradeOptionState>[
      for (var index = 0; index < selected.length; index += 1)
        TowerUpgradeOptionState(
          type: selected[index],
          isOvercharge: selected[index] == overchargeType,
          isRadiant: index == radiantIndex,
        ),
    ];
  }

  double _towerUpgradeBonusValue(int rank) =>
      rank.clamp(0, maxTowerUpgradeRank) / maxTowerUpgradeRank;

  double _upgradeBonusForOptions(
    Iterable<TowerUpgradeOptionState> options,
    TowerUpgradeStatType type,
  ) {
    final match = options.where((upgrade) => upgrade.type == type);
    if (match.isEmpty) {
      return 0;
    }
    final upgrade = match.first;
    final radiantMultiplier = upgrade.isRadiant ? 1.30 : 1.0;
    return _towerUpgradeBonusValue(upgrade.rank) * radiantMultiplier;
  }

  double _towerUpgradeBonusFor(
    OuterTowerState tower,
    TowerUpgradeStatType type,
  ) => _upgradeBonusForOptions(tower.towerUpgradeOptions, type);

  double _coreUpgradeBonusForState(CoreState core, TowerUpgradeStatType type) =>
      _upgradeBonusForOptions(core.coreUpgradeOptions, type);

  double _coreUpgradeBonusFor(TowerUpgradeStatType type) =>
      _coreUpgradeBonusForState(_core, type);

  List<ChildTowerUpgradeState> _rollChildTowerUpgradeBoard() {
    final pool = ChildTowerUpgradeType.values.toList(growable: false)
      ..shuffle(_traitRandom);
    return pool
        .take(childTowerUpgradeOptionsPerLevel)
        .map((type) => ChildTowerUpgradeState(type: type))
        .toList(growable: false);
  }

  double _childTowerUpgradeBonusValue(int rank) =>
      rank.clamp(0, childTowerUpgradeMaxRank) / childTowerUpgradeMaxRank;

  double _childTowerUpgradeBonusForLayer(
    TowerLayerSnapshot layer,
    ChildTowerUpgradeType type,
  ) {
    final match = layer.childTowerUpgrades.where(
      (upgrade) => upgrade.type == type,
    );
    if (match.isEmpty) {
      return 0;
    }
    return _childTowerUpgradeBonusValue(match.first.rank);
  }

  double _childTowerPowerMultiplier(double bonusValue) =>
      1 + (bonusValue * 0.25);

  double _childTowerChargeMultiplier(double bonusValue) =>
      1 + (bonusValue * 0.18);

  double _childTowerCooldownMultiplier(double bonusValue) =>
      max(0.72, 1 - (bonusValue * 0.14));

  double _childTowerRangeBonus(double bonusValue) => bonusValue * 36;

  double _childTowerGenerationBonus(double bonusValue) => bonusValue * 0.12;

  double _childTowerCritChanceBonus(double bonusValue) => bonusValue * 0.04;

  double _childTowerCritDamageBonus(double bonusValue) => bonusValue * 0.25;

  double _childTowerFinalDamageBonus(double bonusValue) => bonusValue * 0.22;

  double _childTowerBossDamageBonus(double bonusValue) => bonusValue * 0.34;

  double _childTowerNormalDamageBonus(double bonusValue) => bonusValue * 0.2;

  double _childTowerDefensePenetrationBonus(double bonusValue) =>
      bonusValue * 0.14;

  double _childTowerMinDamageBonus(double bonusValue) => bonusValue * 0.12;

  double _childTowerMaxDamageBonus(double bonusValue) => bonusValue * 0.2;

  double _towerPowerUpgradeMultiplier(double bonusValue) =>
      _childTowerPowerMultiplier(bonusValue);

  double _towerChargeUpgradeMultiplier(double bonusValue) =>
      1 + (bonusValue * 0.56);

  double _towerCooldownUpgradeMultiplier(double bonusValue) =>
      _childTowerCooldownMultiplier(bonusValue);

  double _towerRangeUpgradeBonus(double bonusValue) =>
      _childTowerRangeBonus(bonusValue);

  double _towerGenerationUpgradeBonus(double bonusValue) =>
      _childTowerGenerationBonus(bonusValue);

  double _towerCritChanceUpgradeBonus(double bonusValue) =>
      _childTowerCritChanceBonus(bonusValue);

  double _towerCritDamageUpgradeBonus(double bonusValue) =>
      _childTowerCritDamageBonus(bonusValue);

  double _towerFinalDamageUpgradeBonus(double bonusValue) =>
      _childTowerFinalDamageBonus(bonusValue);

  double _towerBossDamageUpgradeBonus(double bonusValue) =>
      _childTowerBossDamageBonus(bonusValue);

  double _towerNormalDamageUpgradeBonus(double bonusValue) =>
      _childTowerNormalDamageBonus(bonusValue);

  double _towerDefensePenetrationUpgradeBonus(double bonusValue) =>
      _childTowerDefensePenetrationBonus(bonusValue);

  double _towerMinDamageUpgradeBonus(double bonusValue) =>
      _childTowerMinDamageBonus(bonusValue);

  double _towerMaxDamageUpgradeBonus(double bonusValue) =>
      _childTowerMaxDamageBonus(bonusValue);

  double _towerDotDamageUpgradeBonus(double bonusValue) => bonusValue * 0.24;

  int _towerLevelRanks(OuterTowerState tower) =>
      max(0, min(maxTowerLevel, tower.level) - 1);

  double _towerLevelOutputMultiplier(OuterTowerState tower) =>
      1 + (_towerLevelRanks(tower) * 0.035);

  double _towerLevelCooldownMultiplier(OuterTowerState tower) =>
      max(0.86, 1 - (_towerLevelRanks(tower) * 0.025));

  double _towerLevelRangeBonus(OuterTowerState tower) =>
      _towerLevelRanks(tower) * 6.0;

  double _towerLevelCritChanceBonus(OuterTowerState tower) =>
      _towerLevelRanks(tower) * 0.004;

  double _towerLevelCritDamageMultiplier(OuterTowerState tower) =>
      1 + (_towerLevelRanks(tower) * 0.015);

  double _towerLevelDamageBonus(OuterTowerState tower) =>
      _towerLevelRanks(tower) * 0.012;

  double _towerLevelDefensePenetrationBonus(OuterTowerState tower) =>
      _towerLevelRanks(tower) * 0.003;

  OuterTowerState _buildRolledTowerState({
    required int slotIndex,
    required TowerConfig config,
    required int investedLumens,
  }) {
    final qualityBias = _overallStatRollBias;
    final hasDotStat = _towerConfigSupportsDotDamage(config);
    final minDamageFactor = _rollPositiveStat(
      0.1 + (config.statVariance * 0.42),
      qualityBias: qualityBias,
    );
    return OuterTowerState(
      slotIndex: slotIndex,
      config: config,
      projectileType: config.defaultProjectileType,
      payloadType: config.defaultPayloadType,
      investedLumens: investedLumens,
      powerFactor: _rollAroundOne(
        config.statVariance,
        qualityBias: qualityBias,
      ),
      chargeFactor: _rollAroundOne(
        config.statVariance,
        qualityBias: qualityBias,
      ),
      cooldownFactor: _rollAroundOne(
        config.statVariance * 0.82,
        qualityBias: qualityBias,
      ),
      rangeFactor: _rollAroundOne(
        config.statVariance,
        qualityBias: qualityBias,
      ),
      generationFactor: _rollAroundOne(
        config.statVariance,
        qualityBias: qualityBias,
      ),
      critChanceBonus: _rollSymmetric(
        config.critChanceVariance,
        qualityBias: qualityBias,
      ),
      critDamageFactor: _rollAroundOne(
        config.critDamageVariance,
        qualityBias: qualityBias,
      ),
      finalDamageFactor: _rollPositiveStat(
        0.12 + (config.statVariance * 0.46),
        qualityBias: qualityBias,
      ),
      bossDamageFactor: _rollPositiveStat(
        0.2 + (config.statVariance * 0.72),
        qualityBias: qualityBias,
      ),
      normalDamageFactor: _rollPositiveStat(
        0.14 + (config.statVariance * 0.56),
        qualityBias: qualityBias,
      ),
      defensePenetration: _rollPositiveBonus(
        0.08 + (config.statVariance * 0.34),
        qualityBias: qualityBias,
      ),
      minDamageFactor: minDamageFactor,
      maxDamageFactor: max(
        minDamageFactor,
        _rollPositiveStat(
          0.18 + (config.statVariance * 0.78),
          qualityBias: qualityBias,
        ),
      ),
      dotDamageFactor: hasDotStat
          ? _rollPositiveStat(
              0.14 + (config.statVariance * 0.52),
              qualityBias: qualityBias,
            )
          : 1,
      towerUpgradeOptions: _rollTowerUpgradeBoard(config),
    );
  }

  bool isOuterSlotUnlocked(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    return _slots[slotIndex].isBuilt || slotIndex < unlockedOuterSlotCount;
  }

  int experienceRemainingForOuterSlot(int slotIndex) => max(
    0,
    _outerSlotUnlockExperienceForProgression(slotIndex) - progressionExperience,
  );

  int killsRemainingForOuterSlot(int slotIndex) =>
      experienceRemainingForOuterSlot(slotIndex);

  int? get nextLockedOuterSlotIndex =>
      unlockedOuterSlotCount >= slotCount ? null : unlockedOuterSlotCount;

  int? get nextOuterSlotKillRequirement {
    final slotIndex = nextLockedOuterSlotIndex;
    return slotIndex == null
        ? null
        : _outerSlotUnlockExperienceForProgression(slotIndex);
  }

  int get nextOuterSlotKillsRemaining {
    final requirement = nextOuterSlotKillRequirement;
    if (requirement == null) {
      return 0;
    }
    return max(0, requirement - progressionExperience);
  }

  double slotUnlockProgressForIndex(int slotIndex) {
    if (slotIndex < 0 ||
        slotIndex >= slotCount ||
        isOuterSlotUnlocked(slotIndex)) {
      return 1;
    }
    final previousRequirement = slotIndex == 0
        ? 0
        : _outerSlotUnlockExperienceForProgression(slotIndex - 1);
    final requirement = _outerSlotUnlockExperienceForProgression(slotIndex);
    final span = max(1, requirement - previousRequirement);
    return ((progressionExperience - previousRequirement) / span).clamp(
      0.0,
      1.0,
    );
  }

  String lockedOuterSlotSummary(int slotIndex) {
    final requirement = _outerSlotUnlockExperienceForProgression(slotIndex);
    final remaining = max(0, requirement - progressionExperience);
    return remaining <= 0
        ? 'Hex ${slotIndex + 1} is stable. Anchor a prism relay when ready.'
        : 'Hex ${slotIndex + 1} stabilizes at $requirement total EXP. $remaining more EXP needed.';
  }

  String get outerSlotUnlockStatusLabel {
    final slotIndex = nextLockedOuterSlotIndex;
    if (slotIndex == null) {
      return 'All $slotCount prism anchors are stable.';
    }
    return 'Prism anchors $unlockedOuterSlotCount/$slotCount stable • Hex ${slotIndex + 1} opens at ${_outerSlotUnlockExperienceForProgression(slotIndex)} EXP.';
  }

  String get promotionStatusLabel {
    final base =
        '$builtTowerCount/$slotCount built • '
        '$promotionReadyTowerCount/$slotCount ready for alignment';
    if (_requiresLayer3TrialGate && isPromotionReady) {
      return '$base • $layer3TrialStatusLabel';
    }
    return base;
  }

  String childShellProgressLabel(OuterTowerState tower) {
    final childLayerId = tower.childLayerId;
    if (childLayerId == null) {
      return '${tower.childBuiltCount}/$slotCount built';
    }
    final child = _layerById(childLayerId);
    final built = child.slots.where(_slotCountsTowardRing).length;
    final ready = promotionReadyCountForLayer(child);
    return '$built/$slotCount built • $ready/$slotCount ready';
  }

  String childTowerGrowthLabel(OuterTowerState tower) {
    if (tower.isPromotedChildTower) {
      return towerCompletionLabel(tower);
    }
    final childLayerId = tower.childLayerId;
    if (childLayerId == null) {
      return 'Level ${tower.childCoreLevel ?? 1}';
    }
    final child = _layerById(childLayerId);
    final cap = child.childTowerUpgrades.length * childTowerUpgradeMaxRank;
    final spent = child.childTowerUpgrades.fold(
      0,
      (sum, upgrade) => sum + upgrade.rank,
    );
    if (cap <= 0) {
      return 'Level ${child.core.level}';
    }
    return 'Level ${child.core.level} • $spent/$cap tuned';
  }

  int towerUpgradePointsSpent(OuterTowerState tower) =>
      tower.towerUpgradeOptions.fold(0, (sum, upgrade) => sum + upgrade.rank);

  int towerUpgradePointsCap(OuterTowerState tower) =>
      tower.towerUpgradeOptions.length * maxTowerUpgradeRank;

  int towerUpgradePointsRemaining(OuterTowerState tower) =>
      max(0, towerUpgradePointsCap(tower) - towerUpgradePointsSpent(tower));

  UnmodifiableListView<TowerUpgradeOptionState> get coreUpgradeOptions =>
      UnmodifiableListView(_core.coreUpgradeOptions);

  int get coreUpgradePointsSpent =>
      _core.coreUpgradeOptions.fold(0, (sum, upgrade) => sum + upgrade.rank);

  int get coreUpgradePointsCap =>
      _core.coreUpgradeOptions.length * maxTowerUpgradeRank;

  int get coreUpgradePointsRemaining =>
      max(0, coreUpgradePointsCap - coreUpgradePointsSpent);

  bool get coreStatUpgradesComplete =>
      coreUpgradePointsCap > 0 &&
      coreUpgradePointsSpent >= coreUpgradePointsCap;

  String get coreTrainingLabel {
    final cap = coreUpgradePointsCap;
    final statsLabel = cap <= 0
        ? 'No stat board'
        : 'Stat ranks $coreUpgradePointsSpent/$cap';
    return 'Level ${_core.level}/$maxCoreLevel • $statsLabel';
  }

  bool towerStatUpgradesComplete(OuterTowerState tower) {
    final cap = towerUpgradePointsCap(tower);
    return cap > 0 && towerUpgradePointsSpent(tower) >= cap;
  }

  bool isTowerComplete(OuterTowerState tower) =>
      tower.hasTowerProgression &&
      tower.level >= maxTowerLevel &&
      towerStatUpgradesComplete(tower);

  String towerCompletionLabel(OuterTowerState tower) {
    final spent = towerUpgradePointsSpent(tower);
    final cap = towerUpgradePointsCap(tower);
    final statsLabel = cap <= 0 ? 'No stat board' : 'Stats $spent/$cap';
    if (isTowerComplete(tower)) {
      return 'Complete • $statsLabel';
    }
    if (tower.level >= maxTowerLevel) {
      return 'Level max • $statsLabel';
    }
    return 'Level ${tower.level}/$maxTowerLevel • $statsLabel';
  }

  UnmodifiableListView<TowerUpgradeOptionState> towerUpgradeOptionsFor(
    OuterTowerState tower,
  ) => UnmodifiableListView(tower.towerUpgradeOptions);

  bool towerHasUpgradeOption(
    OuterTowerState tower,
    TowerUpgradeStatType type,
  ) => tower.towerUpgradeOptions.any((upgrade) => upgrade.type == type);

  List<TowerUpgradeStatType> towerLockedUpgradeTypesFor(OuterTowerState tower) {
    final pool = _eligibleTowerUpgradeTypesForTower(tower);
    return List<TowerUpgradeStatType>.unmodifiable(
      pool.where((type) => !towerHasUpgradeOption(tower, type)),
    );
  }

  String towerUpgradeEffectLabel(TowerUpgradeOptionState upgrade) {
    final bonusValue =
        _towerUpgradeBonusValue(upgrade.rank) *
        (upgrade.isRadiant ? 1.30 : 1.0);
    final label = switch (upgrade.type) {
      TowerUpgradeStatType.power => '+${(bonusValue * 25).round()}% damage',
      TowerUpgradeStatType.chargeRate =>
        '+${(bonusValue * 18).round()}% charge',
      TowerUpgradeStatType.cooldown =>
        '-${(bonusValue * 14).round()}% cooldown',
      TowerUpgradeStatType.range =>
        '+${_towerRangeUpgradeBonus(bonusValue).round()} range',
      TowerUpgradeStatType.generationSpeed =>
        '+${_towerGenerationUpgradeBonus(bonusValue).toStringAsFixed(2)} gen',
      TowerUpgradeStatType.critChance =>
        '+${(_towerCritChanceUpgradeBonus(bonusValue) * 100).toStringAsFixed(1)}% crit',
      TowerUpgradeStatType.critDamage =>
        '+${_towerCritDamageUpgradeBonus(bonusValue).toStringAsFixed(2)} crit x',
      TowerUpgradeStatType.finalDamage =>
        '+${(_towerFinalDamageUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% final',
      TowerUpgradeStatType.bossDamage =>
        '+${(_towerBossDamageUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% apex',
      TowerUpgradeStatType.normalDamage =>
        '+${(_towerNormalDamageUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% normal',
      TowerUpgradeStatType.defensePenetration =>
        '+${(_towerDefensePenetrationUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% ignore def',
      TowerUpgradeStatType.minDamage =>
        '+${(_towerMinDamageUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% min',
      TowerUpgradeStatType.maxDamage =>
        '+${(_towerMaxDamageUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% max',
      TowerUpgradeStatType.dotDamage =>
        '+${(_towerDotDamageUpgradeBonus(bonusValue) * 100).toStringAsFixed(0)}% DoT',
    };
    final tags = <String>[
      if (upgrade.isRadiant) 'Radiant',
      if (upgrade.isOvercharge) 'Overcharge',
    ];
    return tags.isEmpty ? label : '$label • ${tags.join(' • ')}';
  }

  String coreUpgradeEffectLabel(TowerUpgradeOptionState upgrade) =>
      towerUpgradeEffectLabel(upgrade);

  String coreSubstatValueLabel(TowerUpgradeStatType type) => switch (type) {
    TowerUpgradeStatType.power => coreBasicShotPower.toStringAsFixed(1),
    TowerUpgradeStatType.cooldown => coreCooldownLabel,
    TowerUpgradeStatType.range => coreRangeLabel,
    TowerUpgradeStatType.critChance =>
      '${(coreCritChance * 100).toStringAsFixed(0)}%',
    TowerUpgradeStatType.critDamage =>
      'x${coreCritMultiplier.toStringAsFixed(2)}',
    TowerUpgradeStatType.finalDamage => coreFinalDamageLabel,
    TowerUpgradeStatType.bossDamage => coreBossDamageLabel,
    TowerUpgradeStatType.normalDamage => coreNormalDamageLabel,
    TowerUpgradeStatType.defensePenetration => coreDefensePenetrationLabel,
    TowerUpgradeStatType.minDamage => coreMinDamageLabel,
    TowerUpgradeStatType.maxDamage => coreMaxDamageLabel,
    TowerUpgradeStatType.chargeRate => 'N/A',
    TowerUpgradeStatType.generationSpeed => 'N/A',
    TowerUpgradeStatType.dotDamage => 'N/A',
  };

  String towerSubstatValueLabel(
    OuterTowerState tower,
    TowerUpgradeStatType type,
  ) => switch (type) {
    TowerUpgradeStatType.power => towerPower(tower).toStringAsFixed(1),
    TowerUpgradeStatType.chargeRate => towerChargeRate(
      tower,
    ).toStringAsFixed(2),
    TowerUpgradeStatType.cooldown =>
      '${towerCooldown(tower).toStringAsFixed(2)}s',
    TowerUpgradeStatType.range => towerRangeLabel(tower),
    TowerUpgradeStatType.generationSpeed => towerGenerationLabel(tower),
    TowerUpgradeStatType.critChance =>
      '${(towerCritChance(tower) * 100).toStringAsFixed(0)}%',
    TowerUpgradeStatType.critDamage =>
      'x${towerCritMultiplier(tower).toStringAsFixed(2)}',
    TowerUpgradeStatType.finalDamage => towerFinalDamageLabel(tower),
    TowerUpgradeStatType.bossDamage => towerBossDamageLabel(tower),
    TowerUpgradeStatType.normalDamage => towerNormalDamageLabel(tower),
    TowerUpgradeStatType.defensePenetration => towerDefensePenetrationLabel(
      tower,
    ),
    TowerUpgradeStatType.minDamage => towerMinDamageLabel(tower),
    TowerUpgradeStatType.maxDamage => towerMaxDamageLabel(tower),
    TowerUpgradeStatType.dotDamage => towerDotDamageLabel(tower),
  };

  String towerUpgradeBoardSummary(OuterTowerState tower) {
    if (!tower.hasTowerProgression || !tower.isBuilt) {
      return 'No tower substats';
    }
    final rolled = tower.towerUpgradeOptions;
    final locked = towerLockedUpgradeTypesFor(tower).length;
    final rolledLabel = rolled
        .map(
          (upgrade) =>
              '${upgrade.isRadiant ? 'Radiant ' : ''}${upgrade.isOvercharge ? 'Overcharge ' : ''}${upgrade.type.label} ${upgrade.rank}/$maxTowerUpgradeRank',
        )
        .join(' • ');
    return locked > 0 ? '$rolledLabel • $locked locked' : rolledLabel;
  }

  bool _layerQualifiesForCompletedShell(TowerLayerSnapshot layer) =>
      layer.tier == 1 &&
      layer.slots.where(_slotCountsTowardRing).length == slotCount &&
      promotionReadyCountForLayer(layer) == slotCount;

  String _liveCompletedShellId(String layerId) => 'live:$layerId';

  OuterTowerState _completedShellTowerCopy(
    OuterTowerState tower,
    int slotIndex,
  ) {
    return tower
        .copyForSlot(slotIndex)
        .copyWith(
          charge: 0,
          cooldownRemaining: 0,
          automationCooldownRemaining: 0,
          disruption: 0,
          fireSequence: 0,
          fabricationTotalSeconds: 0,
          fabricationRemainingSeconds: 0,
          clearEquippedCard: true,
        );
  }

  TowerLayerSnapshot _completedShellLayerCopy(
    TowerLayerSnapshot source, {
    required String id,
    required String label,
    required int tier,
    String? parentLayerId,
    int? parentSlotIndex,
    String? sourceLayerId,
    String? promotedParentLayerId,
    bool promotedIntoParentSlot = false,
  }) {
    return TowerLayerSnapshot(
      id: id,
      tier: tier,
      label: label,
      slots: List<OuterTowerState>.generate(slotCount, (index) {
        if (index >= source.slots.length) {
          return OuterTowerState(slotIndex: index);
        }
        return _completedShellTowerCopy(source.slots[index], index);
      }),
      core: source.core.copyWith(
        coreStability: _maxCoreStability,
        flowEfficiency: _maxFlowEfficiency,
        fireCooldownRemaining: 0,
        packetCooldownRemaining: 0,
        automationCooldownRemaining: 0,
        fireSequence: 0,
      ),
      layer2: source.layer2.copyWith(fireCooldownRemaining: 0),
      enemies: <EnemyState>[],
      pulses: <EnergyPulseState>[],
      shots: <CoreShotState>[],
      impacts: <ImpactState>[],
      ammoQueue: <AmmoPacket>[],
      activeEnemyCardIds: List<String>.from(source.activeEnemyCardIds),
      enemyTargetCount: source.enemyTargetCount,
      enemyTargetUpgradeLevel: source.enemyTargetUpgradeLevel,
      outerRingRevealed: source.outerRingRevealed,
      swarmActivated: source.swarmActivated,
      elapsed: 0,
      spawnTimer: 1.0,
      spawnSequence: 0,
      enemyCounter: 0,
      pulseCounter: 0,
      shotCounter: 0,
      impactCounter: 0,
      normalKillsSinceBoss: 0,
      bossReady: false,
      childTowerUpgrades: source.childTowerUpgrades
          .map((upgrade) => upgrade.copyWith())
          .toList(growable: false),
      threatAssignmentPresets: List<ThreatAssignmentPresetState>.from(
        source.threatAssignmentPresets,
      ),
      activeBossEnemyCardId: source.activeBossEnemyCardId,
      selectedThreatAssignmentPresetId: source.selectedThreatAssignmentPresetId,
      parentLayerId: parentLayerId,
      parentSlotIndex: parentSlotIndex,
      sourceLayerId: sourceLayerId,
      promotedParentLayerId: promotedParentLayerId,
      promotedIntoParentSlot: promotedIntoParentSlot,
      promotionTraitRoll: source.promotionTraitRoll,
    );
  }

  List<CompletedTowerShellState> _liveCompletedTowerShells() {
    final entries = <CompletedTowerShellState>[];
    for (final layer in _layers) {
      if (!_layerQualifiesForCompletedShell(layer)) {
        continue;
      }
      entries.add(
        CompletedTowerShellState(
          id: _liveCompletedShellId(layer.id),
          sourceLayerId: layer.id,
          sourceLayerLabel: layer.label,
          sourceLayerTier: layer.tier,
          sourceSlotIndex: layer.parentSlotIndex,
          savedAtMillis: 0,
          layer: layer,
          archived: false,
        ),
      );
    }
    return entries;
  }

  UnmodifiableListView<CompletedTowerShellState> get liveCompletedTowerShells =>
      UnmodifiableListView(_liveCompletedTowerShells());

  UnmodifiableListView<CompletedTowerShellState>
  get completedTowerShellLibrary =>
      UnmodifiableListView(<CompletedTowerShellState>[
        ..._liveCompletedTowerShells(),
        ..._completedTowerShells,
      ]);

  CompletedTowerShellState? completedTowerShellById(String id) {
    for (final shell in completedTowerShellLibrary) {
      if (shell.id == id) {
        return shell;
      }
    }
    return null;
  }

  bool saveCompletedShell(String shellId) {
    if (!completedShellLibraryUnlocked) {
      _showBanner('Completed shell storage unlocks at Layer 2.');
      _notifyNow();
      return false;
    }
    final shell = completedTowerShellById(shellId);
    if (shell == null || shell.archived) {
      return false;
    }
    if (!_layerQualifiesForCompletedShell(shell.layer)) {
      _showBanner('Only complete Layer 1 sets can be saved.');
      _notifyNow();
      return false;
    }
    final now = DateTime.now();
    final archiveId =
        'shell_${_completedTowerShells.length}_${now.microsecondsSinceEpoch}';
    final saved = CompletedTowerShellState(
      id: archiveId,
      sourceLayerId: shell.sourceLayerId,
      sourceLayerLabel: shell.sourceLayerLabel,
      sourceLayerTier: shell.sourceLayerTier,
      sourceSlotIndex: shell.sourceSlotIndex,
      savedAtMillis: now.millisecondsSinceEpoch,
      layer: _completedShellLayerCopy(
        shell.layer,
        id: 'archive_layer_$archiveId',
        label: shell.layer.label,
        tier: shell.layer.tier,
      ),
    );
    _completedTowerShells.add(saved);
    _showBanner('${shell.sourceLabel} saved to completed Layer 1 sets.');
    _notifyNow();
    return true;
  }

  bool replaceCompletedShell({
    required String archiveId,
    required String targetId,
  }) {
    if (!completedShellLibraryUnlocked) {
      _showBanner('Completed shell replacement unlocks at Layer 2.');
      _notifyNow();
      return false;
    }
    final archive = completedTowerShellById(archiveId);
    final target = completedTowerShellById(targetId);
    if (archive == null ||
        target == null ||
        !archive.archived ||
        target.archived ||
        target.sourceSlotIndex == null) {
      return false;
    }
    final layer = _layerForId(target.sourceLayerId);
    if (layer == null || !_layerQualifiesForCompletedShell(archive.layer)) {
      return false;
    }

    final replacement = _completedShellLayerCopy(
      archive.layer,
      id: layer.id,
      label: layer.label,
      tier: layer.tier,
      parentLayerId: layer.parentLayerId,
      parentSlotIndex: layer.parentSlotIndex,
      sourceLayerId: layer.sourceLayerId,
      promotedParentLayerId: layer.promotedParentLayerId,
      promotedIntoParentSlot: layer.promotedIntoParentSlot,
    );
    final layerIndex = _layers.indexWhere((item) => item.id == layer.id);
    if (layerIndex == -1) {
      return false;
    }
    _layers[layerIndex] = replacement;
    if (replacement.id == _activeLayerId) {
      _loadLayer(replacement);
    }
    _syncParentSlotFromLayer(replacement);
    final parentId = replacement.parentLayerId;
    if (parentId != null && parentId == _activeLayerId) {
      _slots = _layerById(parentId).slots;
    }
    _updateFlowEfficiency();
    _showBanner('${archive.sourceLabel} replaced ${target.sourceLabel}.');
    _notifyNow();
    return true;
  }

  String get flowSummary =>
      'Output Efficiency is the visible multiplier from hidden Core Stability. Effective Gain = Base Gain x Threat Reward x Output Efficiency.';

  String get queueSummary =>
      'The charged-shot markers inherit projectile colors and show which relay shots are ready to fire. Capacity is $coreQueueCapacity, so full buffers make edge towers hold charge.';

  int boostedExperienceRewardFor(int baseExperience) =>
      _boostedExperienceReward(baseExperience);

  int get builtRelayCount => _slots.where((slot) => slot.config != null).length;

  int buildCostForConfig(TowerConfig config) {
    final shellCurve = activeLayer.tier == 1
        ? layer1TowerBuildCostMultipliers[builtRelayCount
              .clamp(0, layer1TowerBuildCostMultipliers.length - 1)
              .toInt()]
        : pow(1.85, builtRelayCount).toDouble();
    final price =
        _balancedTowerStat(config, 'buildCost', config.buildCost.toDouble()) *
        activeLayerPriceMultiplier *
        shellCurve;
    return max(1, price.round());
  }

  double towerFabricationDurationForConfig(TowerConfig config) {
    if (activeLayer.tier != 1) {
      return towerConstructionDurationSeconds;
    }
    final rampIndex = builtRelayCount.clamp(0, slotCount - 1).toInt();
    return layer1TowerConstructionDurationsSeconds[rampIndex
        .clamp(0, layer1TowerConstructionDurationsSeconds.length - 1)
        .toInt()];
  }

  String towerFabricationDurationLabelForConfig(TowerConfig config) =>
      _towerFabricationSecondsLabel(towerFabricationDurationForConfig(config));

  String towerFabricationRemainingLabel(OuterTowerState tower) =>
      _towerFabricationSecondsLabel(tower.fabricationRemainingSeconds);

  String _towerFabricationSecondsLabel(double seconds) {
    final totalSeconds = seconds.ceil();
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  String towerFabricationProgressLabel(OuterTowerState tower) {
    if (!tower.isFabricating) {
      return 'Fabrication complete';
    }
    return 'Fabricating ${towerDisplayName(tower)} • ${towerFabricationRemainingLabel(tower)} remaining';
  }

  int get currentTraitRefreshCost =>
      max(1, (traitRefreshLumenCost * activeLayerPriceMultiplier).round());

  String childTowerUpgradeEffectLabel(ChildTowerUpgradeState upgrade) {
    final bonusValue = _childTowerUpgradeBonusValue(upgrade.rank);
    return switch (upgrade.type) {
      ChildTowerUpgradeType.power => '+${(bonusValue * 25).round()}% damage',
      ChildTowerUpgradeType.chargeRate =>
        '+${(bonusValue * 18).round()}% charge',
      ChildTowerUpgradeType.cooldown =>
        '-${(bonusValue * 14).round()}% cooldown',
      ChildTowerUpgradeType.range =>
        '+${_childTowerRangeBonus(bonusValue).round()} range',
      ChildTowerUpgradeType.generationSpeed =>
        '+${_childTowerGenerationBonus(bonusValue).toStringAsFixed(2)} gen',
      ChildTowerUpgradeType.critChance =>
        '+${(_childTowerCritChanceBonus(bonusValue) * 100).toStringAsFixed(1)}% crit',
      ChildTowerUpgradeType.critDamage =>
        '+${_childTowerCritDamageBonus(bonusValue).toStringAsFixed(2)} crit x',
      ChildTowerUpgradeType.finalDamage =>
        '+${(_childTowerFinalDamageBonus(bonusValue) * 100).toStringAsFixed(0)}% final',
      ChildTowerUpgradeType.bossDamage =>
        '+${(_childTowerBossDamageBonus(bonusValue) * 100).toStringAsFixed(0)}% apex',
      ChildTowerUpgradeType.normalDamage =>
        '+${(_childTowerNormalDamageBonus(bonusValue) * 100).toStringAsFixed(0)}% normal',
      ChildTowerUpgradeType.defensePenetration =>
        '+${(_childTowerDefensePenetrationBonus(bonusValue) * 100).toStringAsFixed(0)}% ignore def',
      ChildTowerUpgradeType.minDamage =>
        '+${(_childTowerMinDamageBonus(bonusValue) * 100).toStringAsFixed(0)}% min',
      ChildTowerUpgradeType.maxDamage =>
        '+${(_childTowerMaxDamageBonus(bonusValue) * 100).toStringAsFixed(0)}% max',
    };
  }

  int childTowerUpgradeCost(ChildTowerUpgradeState upgrade) {
    if (!activeLayerHasParentSlot || upgrade.rank >= childTowerUpgradeMaxRank) {
      return 0;
    }
    final levelCurve = 1 + ((activeLayer.core.level - 1) * 0.22);
    final rankCurve = 1 + (upgrade.rank * 0.08);
    final shellCurve = 2.2 + ((activeLayer.tier - 1) * 0.2);
    final price =
        activeLayerPriceMultiplier * levelCurve * rankCurve * shellCurve;
    return max(1, price.round());
  }

  String childTowerUpgradeCostLabel(ChildTowerUpgradeState upgrade) =>
      LightcoreCurrencyLabels.shellCoreCount(childTowerUpgradeCost(upgrade));

  InventoryCard? cardForSlot(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower) || !managerAssignmentUnlocked) {
      return null;
    }
    return _towerCoreManagerForLayer(activeLayer);
  }

  InventoryCard? inventoryCardById(String id) {
    final match = _cards.where((card) => card.instanceId == id);
    return match.isEmpty ? null : match.first;
  }

  EnemyCardState? enemyCardById(String id) {
    final match = _enemyCards.where((card) => card.config.id == id);
    return match.isEmpty ? null : match.first;
  }

  EnemyCardState? bossEnemyCardById(String id) {
    final match = _bossEnemyCards.where((card) => card.config.id == id);
    return match.isEmpty ? null : match.first;
  }

  TowerPatternBonusProfile enemyInventoryEffectForCard(EnemyCardState card) {
    if (!card.isOwned) {
      return TowerPatternBonusProfile.zero;
    }
    return _inventoryEffectForCard(card);
  }

  TowerPatternBonusProfile bossInventoryEffectForCard(EnemyCardState card) {
    if (!card.isOwned) {
      return TowerPatternBonusProfile.zero;
    }
    return _inventoryEffectForCard(card);
  }

  List<String> inventoryEffectHighlightsForCard(
    EnemyCardState card, {
    int maxItems = 3,
  }) => _towerBonusHighlights(
    card.config.isBoss
        ? bossInventoryEffectForCard(card)
        : enemyInventoryEffectForCard(card),
    maxItems: maxItems,
  );

  String inventoryEffectSummaryLabelForCard(EnemyCardState card) =>
      _towerBonusSummary(
        card.config.isBoss
            ? bossInventoryEffectForCard(card)
            : enemyInventoryEffectForCard(card),
      );

  int bossBaseLevelCap(EnemyCardState card) => switch (card.config.rarity) {
    EnemyCardRarity.basic => 3,
    EnemyCardRarity.uncommon => 5,
    EnemyCardRarity.rare => 8,
    EnemyCardRarity.epic => 12,
    EnemyCardRarity.legendary => 16,
  };

  int bossLevelCap(EnemyCardState card) {
    if (!card.isOwned) {
      return 0;
    }
    final duplicateBonus = max(0, card.copies - 1) * 2;
    return min(maxBossCardLevel, bossBaseLevelCap(card) + duplicateBonus);
  }

  int bossCopiesToNextCapIncrease(EnemyCardState card) {
    if (!card.isOwned || bossLevelCap(card) >= maxBossCardLevel) {
      return 0;
    }
    return 1;
  }

  int bossUpgradeRequirement(EnemyCardState card) =>
      1 + card.config.rarity.index + ((card.level - 1) ~/ 3);

  bool canUpgradeBossEnemyCard(EnemyCardState card) =>
      _threatRegionChallenge == null &&
      card.isOwned &&
      card.level < bossLevelCap(card) &&
      threatShards >= bossUpgradeRequirement(card);

  bool upgradeBossEnemyCard(String cardId) {
    if (_threatRegionChallenge != null) {
      return false;
    }
    final cardIndex = _bossEnemyCards.indexWhere(
      (card) => card.config.id == cardId,
    );
    if (cardIndex == -1) {
      return false;
    }

    final card = _bossEnemyCards[cardIndex];
    final cost = bossUpgradeRequirement(card);
    if (!card.isOwned ||
        card.level >= bossLevelCap(card) ||
        threatShards < cost) {
      return false;
    }

    threatShards -= cost;
    _bossEnemyCards[cardIndex] = card.copyWith(level: card.level + 1);
    _recordUpgradePurchase();
    _showBanner(
      '${card.config.name} Knowledge Bonus raised to Lv ${card.level + 1}.',
    );
    _notifyNow();
    return true;
  }

  int upgradeAllReadyBossEnemyCards() {
    var upgradedCount = 0;

    while (true) {
      final readyCards = _bossEnemyCards
          .where(canUpgradeBossEnemyCard)
          .toList(growable: false);
      if (readyCards.isEmpty) {
        break;
      }

      readyCards.sort((left, right) {
        final costCompare = bossUpgradeRequirement(
          left,
        ).compareTo(bossUpgradeRequirement(right));
        if (costCompare != 0) {
          return costCompare;
        }
        final levelCompare = left.level.compareTo(right.level);
        if (levelCompare != 0) {
          return levelCompare;
        }
        final rarityCompare = left.config.rarity.index.compareTo(
          right.config.rarity.index,
        );
        if (rarityCompare != 0) {
          return rarityCompare;
        }
        return left.config.id.compareTo(right.config.id);
      });

      final nextCardId = readyCards.first.config.id;
      final nextIndex = _bossEnemyCards.indexWhere(
        (card) => card.config.id == nextCardId,
      );
      if (nextIndex == -1) {
        break;
      }

      final card = _bossEnemyCards[nextIndex];
      final cost = bossUpgradeRequirement(card);
      if (!card.isOwned ||
          card.level >= bossLevelCap(card) ||
          threatShards < cost) {
        break;
      }

      threatShards -= cost;
      _bossEnemyCards[nextIndex] = card.copyWith(level: card.level + 1);
      _recordUpgradePurchase();
      upgradedCount++;
    }

    if (upgradedCount == 0) {
      return 0;
    }

    _showBanner(
      upgradedCount == 1
          ? 'Bulk leveled 1 Apex.'
          : 'Bulk leveled $upgradedCount Apex levels.',
    );
    _notifyNow();
    return upgradedCount;
  }

  EnemyManagerState? enemyManagerById(String id) {
    final match = _enemyManagers.where((manager) => manager.instanceId == id);
    return match.isEmpty ? null : match.first;
  }

  PlayerEquipmentItem? playerEquipmentById(String id) {
    final match = _equipmentInventory.where((item) => item.instanceId == id);
    return match.isEmpty ? null : match.first;
  }

  PlayerEquipmentItem? equippedPlayerItemForSlot(EquipmentLoadoutSlot slot) {
    final instanceId = _equippedPlayerItems[slot];
    return instanceId == null ? null : playerEquipmentById(instanceId);
  }

  EquipmentLoadoutSlot? equippedSlotForItem(String itemId) {
    for (final slot in EquipmentLoadoutSlot.values) {
      if (_equippedPlayerItems[slot] == itemId) {
        return slot;
      }
    }
    return null;
  }

  bool isPlayerItemEquipped(String itemId) =>
      equippedSlotForItem(itemId) != null;

  List<PlayerEquipmentItem> equipmentOptionsForSlot(EquipmentLoadoutSlot slot) {
    final items =
        _equipmentInventory
            .where((item) => item.slotType == slot.acceptedType)
            .toList()
          ..sort((a, b) {
            final rarityCompare = b.rarity.score.compareTo(a.rarity.score);
            if (rarityCompare != 0) {
              return rarityCompare;
            }
            final levelCompare = b.level.compareTo(a.level);
            if (levelCompare != 0) {
              return levelCompare;
            }
            return b.dropOrder.compareTo(a.dropOrder);
          });
    return items;
  }

  bool equipPlayerItem(String itemId, EquipmentLoadoutSlot slot) {
    final item = playerEquipmentById(itemId);
    if (item == null || item.slotType != slot.acceptedType) {
      return false;
    }
    _newEquipmentItemIds.remove(itemId);
    final previousSlot = equippedSlotForItem(itemId);
    if (previousSlot != null) {
      _equippedPlayerItems[previousSlot] = null;
    }
    _equippedPlayerItems[slot] = itemId;
    _showBanner('${item.name} equipped to ${slot.label}.');
    _notifyNow();
    return true;
  }

  bool unequipPlayerSlot(EquipmentLoadoutSlot slot) {
    final item = equippedPlayerItemForSlot(slot);
    if (item == null) {
      return false;
    }
    _equippedPlayerItems[slot] = null;
    _showBanner('${item.name} removed from ${slot.label}.');
    _notifyNow();
    return true;
  }

  bool isProfileMedalUnlocked(String medalId) =>
      profileMedalStatusById(medalId)?.unlocked ?? false;

  bool equipProfileMedal(String medalId) {
    final config = MedalLibrary.byId[medalId];
    if (config == null) {
      return false;
    }
    _syncProfileMedalAchievements(showBanner: false);
    if (!isProfileMedalUnlocked(medalId)) {
      _showBanner('${config.name} is still locked.');
      _notifyNow();
      return false;
    }
    if (_equippedProfileMedalId == medalId) {
      return true;
    }

    _equippedProfileMedalId = medalId;
    _showBanner(
      '${config.name} equipped to your profile. ${config.bonusLabel}.',
    );
    _notifyNow();
    return true;
  }

  bool unequipProfileMedal() {
    final equipped = equippedProfileMedal;
    if (equipped == null) {
      return false;
    }
    _equippedProfileMedalId = null;
    _showBanner('${equipped.name} removed from your profile.');
    _notifyNow();
    return true;
  }

  int autoDismantleOldEquipment() {
    final candidates = _equipmentAutoDismantleCandidates();
    if (candidates.isEmpty) {
      _showBanner('No old unused equipment needs dismantling.');
      _notifyNow();
      return 0;
    }
    final fluxGranted = _removeEquipmentItems(candidates);
    _showBanner(
      '${candidates.length} old equipment piece${candidates.length == 1 ? '' : 's'} auto-dismantled for ${LightcoreCurrencyLabels.fluxCount(fluxGranted)}.',
    );
    _notifyNow();
    return candidates.length;
  }

  @visibleForTesting
  double equipmentDropChanceForEnemy(EnemyState _) {
    return 0;
  }

  EnemyManagerState? enemyManagerForCard(String enemyCardId) {
    if (!managerAssignmentUnlocked) {
      return null;
    }
    return _enemyCoreManagerForLayer(activeLayer);
  }

  bool isEnemyCardActive(String id) => _activeEnemyCardIds.contains(id);

  bool isBossEnemyCardActive(String id) => _activeBossEnemyCardId == id;

  bool debugSeedProgressionLayer(int targetLayer) {
    if (!kDebugMode) {
      return false;
    }

    final targetTier = targetLayer.clamp(1, maxShellTier).toInt();
    debugDisableTutorial();
    debugCompleteBossAndEquipmentTutorial();
    _debugGrantLayerJumpResources(targetTier);

    while (activeLayer.tier < targetTier) {
      _debugPrepareActiveLayerForPromotion();
      if (_requiresLayer3TrialGate) {
        debugCompleteLayer3Trial();
      }

      final previousLayerId = activeLayer.id;
      final previousTier = activeLayer.tier;
      unlockLayer2Tower();
      if (activeLayer.id == previousLayerId ||
          activeLayer.tier <= previousTier) {
        return false;
      }
    }

    _debugGrantLayerJumpResources(targetTier);
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _ammoQueue.clear();
    _outerRingRevealed = true;
    _swarmActivated = true;
    _core = _core.copyWith(flowEfficiency: _maxFlowEfficiency);
    activeLayer.layer3TrialActive = false;
    activeLayer.layer3TrialSpawnIndex = 0;
    _storeActiveLayer();
    _showBanner(
      'Dev layer jump: ${layerDisplayLabel(activeLayer)} ready for testing.',
      duration: 4.0,
    );
    _notifyNow();
    return true;
  }

  void _debugGrantLayerJumpResources(int targetTier) {
    final levelTarget = max(
      managerUnlockLevel,
      max(dailyDungeonUnlockLevel, bossUnlockLevel + (targetTier * 5)),
    );
    kills = max(kills, killsForOverallLevel(levelTarget));
    experience = max(experience, experienceForOverallLevel(levelTarget));
    lumens = max(lumens, 10000000 * targetTier);
    flux = max(flux, 50000 * targetTier);
    prismShards = max(prismShards, 5000 * targetTier);
    managerShards = max(managerShards, 5000 * targetTier);
    shellCores = max(shellCores, 50000 * targetTier);
    enemyTickets = max(enemyTickets, 100 * targetTier);
    bossTickets = max(bossTickets, 40 * targetTier);
    threatShards = max(threatShards, 40 * targetTier);
  }

  void _debugPrepareActiveLayerForPromotion() {
    final finalSlotExperience = unlockExperienceForOuterSlot(slotCount - 1);
    kills = max(kills, finalSlotExperience);
    experience = max(experience, finalSlotExperience);
    lumens = max(lumens, 10000000 * activeLayer.tier);
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _ammoQueue.clear();
    _outerRingRevealed = true;
    _swarmActivated = true;
    activeLayer.layer3TrialActive = false;
    activeLayer.layer3TrialSpawnIndex = 0;
    _core = _core.copyWith(
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      packetCooldownRemaining: 0,
    );

    for (var index = 0; index < slotCount; index += 1) {
      final current = _slots[index];
      if (current.isPromotedChildTower) {
        _slots[index] = current.copyWith(
          level: maxTowerLevel,
          charge: 0,
          cooldownRemaining: 0,
          automationCooldownRemaining: 0,
          disruption: 0,
          towerUpgradeOptions: current.towerUpgradeOptions
              .map((upgrade) => upgrade.copyWith(rank: maxTowerUpgradeRank))
              .toList(growable: false),
        );
        continue;
      }

      final config =
          current.config ?? TowerLibrary.all[index % TowerLibrary.all.length];
      final rolled = current.config == null
          ? _buildRolledTowerState(
              slotIndex: index,
              config: config,
              investedLumens: config.buildCost,
            )
          : current;
      _slots[index] = rolled.copyWith(
        level: maxTowerLevel,
        charge: 0,
        cooldownRemaining: 0,
        automationCooldownRemaining: 0,
        disruption: 0,
        fabricationTotalSeconds: 0,
        fabricationRemainingSeconds: 0,
        towerUpgradeOptions: rolled.towerUpgradeOptions
            .map((upgrade) => upgrade.copyWith(rank: maxTowerUpgradeRank))
            .toList(growable: false),
      );
    }

    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;
    _updateFlowEfficiency();
    _storeActiveLayer();
  }

  @visibleForTesting
  void debugAddBossTickets(int count) {
    if (!kDebugMode || count <= 0) {
      return;
    }
    bossTickets += count;
    _notifyNow();
  }

  @visibleForTesting
  void debugAddBossCores(int count) {
    if (!kDebugMode || count <= 0) {
      return;
    }
    threatShards += count;
    _notifyNow();
  }

  @visibleForTesting
  void debugSetSpawnSequence(int value) {
    if (!kDebugMode) {
      return;
    }
    _spawnSequence = max(0, value);
    _activeSpawnClusterIndex = null;
    activeLayer.spawnSequence = _spawnSequence;
    _notifyNow();
  }

  @visibleForTesting
  void debugCompleteBossAndEquipmentTutorial() {
    if (!kDebugMode) {
      return;
    }

    final cardIndex = _bossEnemyCards.indexWhere(
      (card) => card.config.id == BossEnemyLibrary.starterWhiteWarden.id,
    );
    if (cardIndex != -1) {
      final current = _bossEnemyCards[cardIndex];
      _bossEnemyCards[cardIndex] = current.copyWith(
        unlocked: true,
        copies: max(1, current.copies),
      );
    }

    bossPullCount = max(1, bossPullCount);
    _activeBossEnemyCardId = BossEnemyLibrary.starterWhiteWarden.id;
    activeLayer.activeBossEnemyCardId = _activeBossEnemyCardId;
    activeLayer.bossReady = false;
    _tutorialFirstBossDefeated = true;
    _tutorialFirstEquipmentOpened = true;
    _tutorialIntroBossPending = false;
    _tutorialTrackedBossEnemyId = null;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  @visibleForTesting
  void debugDisableTutorial() {
    if (!kDebugMode) {
      return;
    }

    _tutorialStep = LightcoreTutorialStep.none;
    _tutorialEarlyQuestChainCompleted = true;
    _tutorialFirstBossDefeated = true;
    _tutorialFirstEquipmentOpened = true;
    _tutorialFirstManagersOpened = true;
    _tutorialFirstEnemyTargetSet = true;
    _tutorialEnemyCountAdjusted = true;
    _tutorialStabilityPanelOpened = false;
    _tutorialTowerMatrixOpened = true;
    _tutorialStoreOpened = true;
    _tutorialBattlePassRewardClaimed = true;
    _tutorialTowerManagerAssigned = true;
    _tutorialEnemyManagerAssigned = true;
    _tutorialFriendsOpened = true;
    _tutorialMenteesOpened = true;
    _tutorialMentorsOpened = true;
    _tutorialManualAimFireLearned = true;
    _tutorialSecondShellShotTapLearned = true;
    _tutorialOverdriveLearned = true;
    _tutorialIntroBossPending = false;
    _tutorialSafeScanDefeats = 5;
    _tutorialAutoQueuedPulses = 0;
    _tutorialTrackedBossEnemyId = null;
    if (_activeBossEnemyCardId == BossEnemyLibrary.starterWhiteWarden.id &&
        activeLayer.bossReady &&
        totalBossesDefeated == 0) {
      activeLayer.bossReady = false;
      activeLayer.normalKillsSinceBoss = 0;
    }
    _tutorialPulseTarget = null;
    _tutorialPulseSignal = 0;
    _rewardedTutorialSteps
      ..clear()
      ..addAll(LightcoreTutorialStep.values);
    bannerMessage = '';
    _bannerTimer = 0;
    _notifyNow();
  }

  @visibleForTesting
  bool debugSetEnemyCardLevel(
    String cardId, {
    required int level,
    int? copies,
    bool boss = false,
  }) {
    final cards = boss ? _bossEnemyCards : _enemyCards;
    final index = cards.indexWhere((card) => card.config.id == cardId);
    if (index == -1) {
      return false;
    }

    final current = cards[index];
    final normalizedLevel = boss
        ? level.clamp(1, maxBossCardLevel)
        : level.clamp(1, enemyLevelCap(current));
    final next = current.copyWith(
      unlocked: true,
      copies: copies ?? current.copies,
      level: normalizedLevel,
    );
    cards[index] = next;
    _notifyNow();
    return true;
  }

  @visibleForTesting
  EnemyState? debugSpawnEnemyFromCard(
    String cardId, {
    required double angle,
    required double radius,
    int? level,
    bool boss = false,
    double? healthFraction,
    double shockRemaining = 0,
  }) {
    final cards = boss ? _bossEnemyCards : _enemyCards;
    final sourceIndex = cards.indexWhere((card) => card.config.id == cardId);
    if (sourceIndex == -1) {
      return null;
    }

    final source = cards[sourceIndex];
    var enemy = _buildEnemyFromCard(
      source.copyWith(level: level ?? source.level),
      angle: angle,
      radius: radius,
    );
    if (healthFraction != null || shockRemaining > 0) {
      final healthRatio = (healthFraction ?? 1).clamp(0.0, 1.0).toDouble();
      enemy = enemy.copyWith(
        health: enemy.maxHealth * healthRatio,
        shockRemaining: shockRemaining,
      );
    }
    _enemies.add(enemy);
    return enemy;
  }

  @visibleForTesting
  bool debugDefeatEnemy(String enemyId) {
    if (!kDebugMode) {
      return false;
    }
    final enemyIndex = _enemies.indexWhere((enemy) => enemy.id == enemyId);
    if (enemyIndex == -1) {
      return false;
    }

    final enemy = _enemies.removeAt(enemyIndex);
    _killEnemy(
      enemy,
      enemy.config.affinity,
      projectileType: ProjectileType.starBolt,
    );
    _notifyNow();
    return true;
  }

  @visibleForTesting
  bool debugCompleteLayer3Trial() {
    if (!kDebugMode || !_requiresLayer3TrialGate) {
      return false;
    }
    _enemies.clear();
    _pulses.clear();
    _shots.clear();
    _impacts.clear();
    _ammoQueue.clear();
    activeLayer.layer3TrialActive = true;
    activeLayer.layer3TrialSpawnIndex = _layer3TrialPlan().length;
    _completeLayer3Trial();
    _notifyNow();
    return true;
  }

  @visibleForTesting
  void debugSetCoreEnergy(double value) {
    if (!kDebugMode) {
      return;
    }
    _core = _core.copyWith(
      coreEnergy: value.clamp(0.0, coreEnergyCapacity).toDouble(),
    );
    activeLayer.core = _core;
    _notifyNow();
  }

  @visibleForTesting
  void debugSetCoreStability(double value) {
    if (!kDebugMode) {
      return;
    }
    _setCoreStability(value);
    activeLayer.core = _core;
    _notifyNow();
  }

  @visibleForTesting
  List<EnemyConfig> debugLayer3TrialPlanConfigs() {
    if (!kDebugMode) {
      return const <EnemyConfig>[];
    }
    return _layer3TrialPlan()
        .map((spawn) => spawn.config)
        .toList(growable: false);
  }

  @visibleForTesting
  void debugSetAmmoQueue(List<AmmoPacket> packets) {
    if (!kDebugMode) {
      return;
    }
    _ammoQueue
      ..clear()
      ..addAll(packets);
    activeLayer.ammoQueue = _ammoQueue;
    _notifyNow();
  }

  @visibleForTesting
  bool debugSetTowerCharge(
    int slotIndex, {
    required double charge,
    double cooldownRemaining = 0,
  }) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    final tower = _slots[slotIndex];
    if (!_slotCountsTowardRing(tower)) {
      return false;
    }
    _slots[slotIndex] = tower.copyWith(
      charge: charge.clamp(0.0, 1.35),
      cooldownRemaining: cooldownRemaining,
    );
    _syncTutorialStep(showBanner: false);
    return true;
  }

  @visibleForTesting
  void debugCompleteSafeThreatScanTutorial() {
    if (!kDebugMode) {
      return;
    }
    final cardIndex = _enemyCards.indexWhere(
      (card) => card.config.id == EnemyLibrary.basicWhite.id,
    );
    if (cardIndex != -1) {
      final current = _enemyCards[cardIndex];
      _enemyCards[cardIndex] = current.copyWith(
        unlocked: true,
        copies: max(1, current.copies),
      );
      if (!_activeEnemyCardIds.contains(EnemyLibrary.basicWhite.id) &&
          _activeEnemyCardIds.length < enemyDeckLimit) {
        _activeEnemyCardIds.add(EnemyLibrary.basicWhite.id);
      }
    }
    enemyPullCount = max(1, enemyPullCount);
    _tutorialSafeScanDefeats = 5;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  @visibleForTesting
  void debugCompleteCoreLearningTutorial() {
    if (!kDebugMode) {
      return;
    }
    _tutorialEarlyQuestChainCompleted = true;
    _tutorialSafeScanDefeats = 5;
    _tutorialStabilityPanelOpened = false;
    _tutorialManualAimFireLearned = true;
    _tutorialAutoQueuedPulses = 0;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }
}
