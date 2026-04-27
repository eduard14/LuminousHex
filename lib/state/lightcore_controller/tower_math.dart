part of '../lightcore_controller.dart';

extension LightcoreControllerTowerMath on LightcoreController {
  T _loadoutEntryAt<T>(List<T> loadout, int sequence, T fallback) {
    if (loadout.isEmpty) {
      return fallback;
    }
    return loadout[sequence % loadout.length];
  }

  PrototypeAffinity _slotAffinity(OuterTowerState tower) {
    if (tower.config != null) {
      return tower.config!.affinity;
    }
    return tower.childAffinity ?? _core.affinity;
  }

  PrototypeAffinity? _slotSecondaryAffinity(OuterTowerState tower) {
    if (tower.config != null) {
      return null;
    }
    return tower.childSecondaryAffinity;
  }

  List<ProjectileType> _slotProjectileLoadout(OuterTowerState tower) {
    if (tower.config != null) {
      return <ProjectileType>[
        tower.projectileType ?? tower.config!.defaultProjectileType,
      ];
    }
    if (tower.childProjectileLoadout.isNotEmpty) {
      return tower.childProjectileLoadout;
    }
    return <ProjectileType>[
      tower.childProjectileType ?? ProjectileType.threadBeam,
    ];
  }

  ProjectileType _slotProjectileType(OuterTowerState tower) {
    return _loadoutEntryAt(
      _slotProjectileLoadout(tower),
      tower.fireSequence,
      tower.config?.defaultProjectileType ??
          tower.childProjectileType ??
          ProjectileType.threadBeam,
    );
  }

  bool towerUsesPersistentShieldRing(OuterTowerState tower) =>
      _slotCountsTowardRing(tower) &&
      !tower.isChildLayerNode &&
      _slotAffinity(tower) == PrototypeAffinity.verdant &&
      _slotProjectileType(tower) == ProjectileType.shieldHalo;

  List<PayloadType> _slotPayloadLoadout(OuterTowerState tower) {
    if (!payloadsUnlocked) {
      return const <PayloadType>[PayloadType.none];
    }
    if (tower.config != null) {
      return <PayloadType>[
        tower.payloadType ?? tower.config!.defaultPayloadType,
      ];
    }
    if (tower.childPayloadLoadout.isNotEmpty) {
      return tower.childPayloadLoadout;
    }
    return <PayloadType>[tower.childPayloadType ?? PayloadType.none];
  }

  PayloadType _slotPayloadType(OuterTowerState tower) {
    return _loadoutEntryAt(
      _slotPayloadLoadout(tower),
      tower.fireSequence,
      tower.config?.defaultPayloadType ??
          tower.childPayloadType ??
          PayloadType.none,
    );
  }

  List<ProjectileType> get _coreProjectileLoadout =>
      _core.projectileLoadout.isNotEmpty
      ? _core.projectileLoadout
      : <ProjectileType>[_core.projectileType];

  ProjectileType _coreProjectileTypeForSequence(int sequence) =>
      _loadoutEntryAt(_coreProjectileLoadout, sequence, _core.projectileType);

  ProjectileType get _coreProjectileType => _loadoutEntryAt(
    _coreProjectileLoadout,
    _core.fireSequence,
    _core.projectileType,
  );

  List<PayloadType> get _corePayloadLoadout => !payloadsUnlocked
      ? const <PayloadType>[PayloadType.none]
      : _core.payloadLoadout.isNotEmpty
      ? _core.payloadLoadout
      : <PayloadType>[_core.payloadType];

  PayloadType _corePayloadTypeForSequence(int sequence) =>
      _loadoutEntryAt(_corePayloadLoadout, sequence, _core.payloadType);

  PayloadType get _corePayloadType => _loadoutEntryAt(
    _corePayloadLoadout,
    _core.fireSequence,
    _core.payloadType,
  );

  double _slotCoreCooldownMultiplier(OuterTowerState tower) {
    if (tower.config != null) {
      return _balancedTowerStat(
        tower.config!,
        'coreCooldownMultiplier',
        tower.config!.coreCooldownMultiplier,
      );
    }
    return max(0.8, 0.96 - (((tower.childLayerTier ?? 1) - 1) * 0.03));
  }

  double _slotAffinityBonusMultiplier(OuterTowerState tower) {
    if (tower.config != null) {
      return _balancedTowerStat(
        tower.config!,
        'affinityBonusMultiplier',
        tower.config!.affinityBonusMultiplier,
      );
    }
    return 1 + (((tower.childLayerTier ?? 1) - 1) * 0.08);
  }

  double _slotJamHitMultiplier(OuterTowerState tower) {
    if (tower.config != null) {
      return _balancedTowerStat(
        tower.config!,
        'jamHitMultiplier',
        tower.config!.jamHitMultiplier,
      );
    }
    return max(0.72, 0.92 - (((tower.childLayerTier ?? 1) - 1) * 0.04));
  }

  double _slotJamDecayMultiplier(OuterTowerState tower) {
    if (tower.config != null) {
      return _balancedTowerStat(
        tower.config!,
        'jamDecayMultiplier',
        tower.config!.jamDecayMultiplier,
      );
    }
    return 1 + (((tower.childLayerTier ?? 1) - 1) * 0.12);
  }

  int _rollFluxDropForEnemy(EnemyState enemy) {
    if (_packRandom.nextDouble() >= _fluxDropChanceForEnemy(enemy)) {
      return 0;
    }
    final rarityBonus = enemy.config.rarity.index;
    final baseAmount = enemy.config.isBoss
        ? 3 + activeLayer.tier + rarityBonus
        : 1 + (rarityBonus ~/ 2);
    final amount =
        baseAmount *
        friendAllianceRewardMultiplier *
        _gearFluxMultiplier *
        _economyBalanceMultiplier('fluxReward');
    return max(1, amount.round());
  }

  double _fluxDropChanceForEnemy(EnemyState enemy) {
    final baseChance = enemy.config.isBoss
        ? _bossFluxDropChance
        : _normalFluxDropChance +
              (enemy.config.rarity.index * _fluxDropChancePerRarity);
    final cappedChance = enemy.config.isBoss ? 0.8 : 0.16;
    return (baseChance * _economyBalanceMultiplier('fluxReward'))
        .clamp(0.0, cappedChance)
        .toDouble();
  }

  int _rollThreatScanDropForEnemy(EnemyState enemy) {
    if (_packRandom.nextDouble() >= _threatScanDropChanceForEnemy(enemy)) {
      return 0;
    }
    final baseAmount = enemy.config.isBoss
        ? max(1, activeLayer.tier + (enemy.config.rarity.index ~/ 2))
        : 1;
    final amount =
        baseAmount *
        _gearTicketMultiplier *
        _economyBalanceMultiplier('threatScanReward');
    return max(1, amount.round());
  }

  double _threatScanDropChanceForEnemy(EnemyState enemy) {
    final baseChance = enemy.config.isBoss
        ? _bossThreatScanDropChance
        : _normalThreatScanDropChance +
              (enemy.config.rarity.index * _threatScanDropChancePerRarity);
    final cappedChance = enemy.config.isBoss ? 0.65 : 0.1;
    return (baseChance * _gearTicketMultiplier)
        .clamp(0.0, cappedChance)
        .toDouble();
  }

  int _killCreditForEnemy(EnemyState enemy) =>
      _killCreditForConfig(enemy.config);

  int _killCreditForConfig(EnemyConfig _) => 1;

  bool _enemyIsImmuneToAffinity(EnemyState enemy, PrototypeAffinity affinity) {
    return enemy.config.immunityAffinities.contains(affinity);
  }

  int upgradeCost(OuterTowerState tower) {
    if (!tower.isBuilt || tower.isFabricating) {
      return 0;
    }
    if (tower.isChildLayerNode) {
      return 0;
    }
    if (tower.level >= maxTowerLevel) {
      return 0;
    }
    final shellCurve = pow(1.35, max(0, builtRelayCount - 1)).toDouble();
    final levelCurve = pow(1.75, tower.level - 1).toDouble();
    final baseBuildCost = _balancedTowerStat(
      tower.config!,
      'buildCost',
      tower.config!.buildCost.toDouble(),
    );
    final baseCost = (baseBuildCost * 2.2) + (tower.level * 10) + 8;
    final price =
        baseCost * activeLayerPriceMultiplier * shellCurve * levelCurve;
    return max(1, price.round());
  }

  int towerStatUpgradeCost(
    OuterTowerState tower,
    TowerUpgradeOptionState upgrade,
  ) {
    if (!tower.isBuilt ||
        tower.isFabricating ||
        tower.isChildLayerNode ||
        upgrade.rank >= maxTowerUpgradeRank) {
      return 0;
    }
    final shellCurve = pow(1.26, max(0, builtRelayCount - 1)).toDouble();
    final levelRank = max(0, min(maxTowerLevel, tower.level) - 1);
    final levelCurve = 1 + (levelRank * 0.16);
    final rankCurve = pow(1.42, upgrade.rank).toDouble();
    final rarityCurve =
        (upgrade.isRadiant ? 1.16 : 1.0) * (upgrade.isOvercharge ? 1.24 : 1.0);
    final baseBuildCost = _balancedTowerStat(
      tower.config!,
      'buildCost',
      tower.config!.buildCost.toDouble(),
    );
    final baseCost = (baseBuildCost * 1.1) + ((upgrade.rank + 1) * 9) + 6;
    final price =
        baseCost *
        activeLayerPriceMultiplier *
        shellCurve *
        levelCurve *
        rankCurve *
        rarityCurve;
    return max(1, price.round());
  }

  double towerPower(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      final childTier = tower.childLayerTier ?? 1;
      final base = 9 + (childLevel * 2.4) + ((childTier - 1) * 4.5);
      return base *
          _towerDamageOutputMultiplier *
          _childTowerPowerMultiplier(tower.childPowerUpgradeBonus) *
          (tower.powerFactor.clamp(0.84, 1.22)) *
          friendAllianceCombatMultiplier *
          _gearPowerMultiplier *
          (1 + combatBonus.power);
    }
    final powerUpgradeMultiplier = _towerPowerUpgradeMultiplier(
      _towerUpgradeBonusFor(tower, TowerUpgradeStatType.power),
    );
    final manager = cardForSlot(tower);
    final cardMultiplier = manager?.powerMultiplier ?? 1;
    final affinityBonus = _towerManagerAffinityBonus(tower, manager);
    return _balancedTowerStat(
          tower.config!,
          'basePower',
          tower.config!.basePower,
        ) *
        _towerDamageOutputMultiplier *
        tower.powerFactor *
        _towerLevelOutputMultiplier(tower) *
        powerUpgradeMultiplier *
        cardMultiplier *
        affinityBonus *
        friendAllianceCombatMultiplier *
        _gearPowerMultiplier *
        (1 + combatBonus.power);
  }

  double towerChargeRate(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    if (towerUsesPersistentShieldRing(tower)) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      final childTier = tower.childLayerTier ?? 1;
      return (0.38 + (childLevel * 0.04) + ((childTier - 1) * 0.06)) *
          tower.chargeFactor *
          _childTowerChargeMultiplier(tower.childChargeUpgradeBonus) *
          _gearChargeMultiplier *
          (1 + combatBonus.chargeRate);
    }
    final chargeUpgradeMultiplier = _towerChargeUpgradeMultiplier(
      _towerUpgradeBonusFor(tower, TowerUpgradeStatType.chargeRate),
    );
    final manager = cardForSlot(tower);
    final cardMultiplier = manager?.chargeMultiplier ?? 1;
    final traitBonus = _towerManagerTraitBonus(tower, manager);
    return _balancedTowerStat(
          tower.config!,
          'baseChargeRate',
          tower.config!.baseChargeRate,
        ) *
        tower.chargeFactor *
        _towerLevelOutputMultiplier(tower) *
        chargeUpgradeMultiplier *
        cardMultiplier *
        traitBonus *
        _gearChargeMultiplier *
        (1 + combatBonus.chargeRate);
  }

  double towerLiveChargeRate(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    return towerChargeRate(tower) * (1 - towerDisruptionFraction(tower));
  }

  double towerCooldown(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    final patternCooldownMultiplier = max(
      0.55,
      1 - combatBonus.cooldownReduction,
    );
    if (tower.isChildLayerNode) {
      final childTier = tower.childLayerTier ?? 1;
      final childLevel = tower.childCoreLevel ?? 1;
      final levelMultiplier = max(0.72, 1 - ((childLevel - 1) * 0.035));
      return max(
        0.48,
        max(0.6, 1.38 - ((childTier - 1) * 0.08)) *
            tower.cooldownFactor *
            levelMultiplier *
            _childTowerCooldownMultiplier(tower.childCooldownUpgradeBonus) *
            patternCooldownMultiplier,
      );
    }
    final cooldownUpgradeMultiplier = _towerCooldownUpgradeMultiplier(
      _towerUpgradeBonusFor(tower, TowerUpgradeStatType.cooldown),
    );
    final cardMultiplier = cardForSlot(tower)?.cooldownMultiplier ?? 1;
    return max(
      0.35,
      _balancedTowerStat(
            tower.config!,
            'baseCooldown',
            tower.config!.baseCooldown,
          ) *
          tower.cooldownFactor *
          _towerLevelCooldownMultiplier(tower) *
          cooldownUpgradeMultiplier *
          cardMultiplier *
          patternCooldownMultiplier *
          _layer1OpeningCadenceMultiplier,
    );
  }

  double towerLiveCooldown(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    return towerLiveCooldownForProjectile(tower, _slotProjectileType(tower));
  }

  double? towerAutomationRate(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower) ||
        tower.isChildLayerNode ||
        towerUsesPersistentShieldRing(tower)) {
      return null;
    }
    return cardForSlot(tower)?.automationRate;
  }

  double? towerAutomationInterval(OuterTowerState tower) {
    final rate = towerAutomationRate(tower);
    if (rate == null || rate <= 0) {
      return null;
    }
    return 1 / rate;
  }

  double towerWantedActivationRate(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    final chargeRate = towerLiveChargeRate(tower);
    if (chargeRate <= 0) {
      return 0;
    }
    final cycleSeconds = (1 / chargeRate) + towerLiveCooldown(tower);
    if (cycleSeconds <= 0) {
      return 0;
    }
    return 1 / cycleSeconds;
  }

  double? towerAutomationEfficiency(OuterTowerState tower) {
    final automationRate = towerAutomationRate(tower);
    if (automationRate == null) {
      return null;
    }
    final wantedRate = towerWantedActivationRate(tower);
    if (wantedRate <= 0) {
      return 1;
    }
    return (automationRate / wantedRate).clamp(0.0, 1.0).toDouble();
  }

  String towerAutomationLabel(OuterTowerState tower) {
    final automationRate = towerAutomationRate(tower);
    if (automationRate == null) {
      return 'Manual tap';
    }
    final efficiency = towerAutomationEfficiency(tower) ?? 1;
    return '${automationRate.toStringAsFixed(2)}/s • ${(efficiency * 100).round()}% efficient';
  }

  bool canActivateTower(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return false;
    }
    if (towerUsesPersistentShieldRing(tower)) {
      return false;
    }
    if (tower.charge < 1 || tower.cooldownRemaining > 0) {
      return false;
    }
    return (_ammoQueue.length + _pulses.length) < coreQueueCapacity;
  }

  bool canManuallyActivateTower(OuterTowerState tower) {
    if (cardForSlot(tower) != null) {
      return false;
    }
    return canActivateTower(tower);
  }

  double towerLiveCooldownForProjectile(
    OuterTowerState tower,
    ProjectileType projectileType,
  ) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    return towerCooldown(tower) *
        _projectileCooldownMultiplier(projectileType) *
        (1 + (tower.disruption.clamp(0, 1) * 0.45));
  }

  double towerAdvantageMultiplier(OuterTowerState tower) {
    if (tower.isChildLayerNode) {
      return 1 + (((tower.childLayerTier ?? 1) - 1) * 0.08);
    }
    final manager = cardForSlot(tower);
    final base = manager?.advantageMultiplier ?? 1;
    return base * _towerManagerTraitBonus(tower, manager);
  }

  double towerDisruptionFraction(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    return min(0.82, tower.disruption.clamp(0, 1.2) * 0.68);
  }

  double towerBaseRange(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    if (tower.isChildLayerNode) {
      final tier = tower.childLayerTier ?? 1;
      final childLevel = tower.childCoreLevel ?? 1;
      return (((tower.childRange ?? (292 + ((tier - 1) * 44))) *
                  _promotedChildTowerRangeMultiplier) +
              ((childLevel - 1) * 8) +
              _childTowerRangeBonus(tower.childRangeUpgradeBonus)) *
          tower.rangeFactor;
    }
    return (coreBaseRange +
            _towerLevelRangeBonus(tower) +
            _towerRangeUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.range),
            )) *
        tower.rangeFactor;
  }

  double towerEffectiveRange(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    return towerEffectiveRangeForProjectile(tower, _slotProjectileType(tower));
  }

  double towerShieldRingRadius(OuterTowerState tower) {
    if (!towerUsesPersistentShieldRing(tower)) {
      return towerEffectiveRange(tower);
    }
    final maxRange = towerEffectiveRangeForProjectile(
      tower,
      ProjectileType.shieldHalo,
    );
    return min(maxRange, max(112.0, maxRange * 0.7));
  }

  double towerEffectiveRangeForProjectile(
    OuterTowerState tower,
    ProjectileType projectileType,
  ) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    return towerBaseRange(tower) *
        _projectileRangeMultiplier(projectileType) *
        _gearRangeMultiplier *
        (1 + combatBonus.range);
  }

  double towerMaxPotentialRange(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 0;
    }
    final loadout = _slotProjectileLoadout(tower);
    final maxMultiplier = loadout.isEmpty
        ? _projectileRangeMultiplier(_slotProjectileType(tower))
        : loadout
              .map(_projectileRangeMultiplier)
              .reduce((current, next) => max(current, next));
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    return towerBaseRange(tower) *
        maxMultiplier *
        _gearRangeMultiplier *
        (1 + combatBonus.range);
  }

  double towerGenerationSpeed(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    if (towerUsesPersistentShieldRing(tower)) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final tier = tower.childLayerTier ?? 1;
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childGenerationSpeed ?? (0.72 + ((tier - 1) * 0.05))) +
              ((childLevel - 1) * 0.02) +
              _childTowerGenerationBonus(tower.childGenerationUpgradeBonus)) *
          tower.generationFactor *
          (1 + combatBonus.generationSpeed);
    }
    return (_balancedTowerStat(
              tower.config!,
              'baseGenerationSpeed',
              tower.config!.baseGenerationSpeed,
            ) +
            _towerGenerationUpgradeBonus(
              _towerUpgradeBonusFor(
                tower,
                TowerUpgradeStatType.generationSpeed,
              ),
            )) *
        _towerLevelOutputMultiplier(tower) *
        tower.generationFactor *
        (1 + combatBonus.generationSpeed);
  }

  double towerCritChance(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childCritChance ??
                  (0.08 + (((tower.childLayerTier ?? 1) - 1) * 0.02))) +
              ((childLevel - 1) * 0.006) +
              _childTowerCritChanceBonus(tower.childCritChanceUpgradeBonus) +
              _gearCritChanceBonus +
              combatBonus.critChance)
          .clamp(0.02, 0.55);
    }
    return (_balancedTowerStat(
              tower.config!,
              'baseCritChance',
              tower.config!.baseCritChance,
            ) +
            tower.critChanceBonus +
            _towerCritChanceUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.critChance),
            ) +
            _towerLevelCritChanceBonus(tower) +
            _gearCritChanceBonus +
            combatBonus.critChance)
        .clamp(0.02, 0.5);
  }

  double towerCritMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 1;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return (tower.childCritMultiplier ??
              (1.62 + (((tower.childLayerTier ?? 1) - 1) * 0.08)) +
                  ((childLevel - 1) * 0.04) +
                  _childTowerCritDamageBonus(
                    tower.childCritDamageUpgradeBonus,
                  )) *
          tower.critDamageFactor *
          _gearCritDamageMultiplier *
          (1 + combatBonus.critDamage);
    }
    return (_balancedTowerStat(
              tower.config!,
              'baseCritMultiplier',
              tower.config!.baseCritMultiplier,
            ) +
            _towerCritDamageUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.critDamage),
            )) *
        tower.critDamageFactor *
        _towerLevelCritDamageMultiplier(tower) *
        _gearCritDamageMultiplier *
        (1 + combatBonus.critDamage);
  }

  double towerFinalDamageMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 1;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childFinalDamageMultiplier ??
                  (1.06 + (((tower.childLayerTier ?? 1) - 1) * 0.03))) +
              ((childLevel - 1) * 0.01) +
              _childTowerFinalDamageBonus(tower.childFinalDamageUpgradeBonus) +
              combatBonus.finalDamage)
          .clamp(1.0, 2.8);
    }
    return (tower.finalDamageFactor +
            _towerFinalDamageUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.finalDamage),
            ) +
            _towerLevelDamageBonus(tower) +
            combatBonus.finalDamage)
        .clamp(1.0, 2.5);
  }

  double towerBossDamageMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 1;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childBossDamageMultiplier ??
                      (1.1 + (((tower.childLayerTier ?? 1) - 1) * 0.04))) +
                  ((childLevel - 1) * 0.014) +
                  _childTowerBossDamageBonus(
                    tower.childBossDamageUpgradeBonus,
                  ) +
                  combatBonus.bossDamage)
              .clamp(1.0, 3.2) *
          _gearBossDamageMultiplier;
    }
    return ((tower.bossDamageFactor +
                _towerBossDamageUpgradeBonus(
                  _towerUpgradeBonusFor(tower, TowerUpgradeStatType.bossDamage),
                ) +
                _towerLevelDamageBonus(tower) +
                combatBonus.bossDamage) *
            _gearBossDamageMultiplier)
        .clamp(1.0, 3.6);
  }

  double towerNormalDamageMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 1;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childNormalDamageMultiplier ??
                  (1.04 + (((tower.childLayerTier ?? 1) - 1) * 0.025))) +
              ((childLevel - 1) * 0.01) +
              _childTowerNormalDamageBonus(
                tower.childNormalDamageUpgradeBonus,
              ) +
              combatBonus.normalDamage)
          .clamp(1.0, 2.8);
    }
    return (tower.normalDamageFactor +
            _towerNormalDamageUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.normalDamage),
            ) +
            _towerLevelDamageBonus(tower) +
            combatBonus.normalDamage)
        .clamp(1.0, 2.6);
  }

  double towerDefensePenetration(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 0;
    }
    final combatBonus = towerPatternBonusesFor(tower) + towerInventoryBonuses;
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childDefensePenetration ??
                  (0.04 + (((tower.childLayerTier ?? 1) - 1) * 0.012))) +
              ((childLevel - 1) * 0.004) +
              _childTowerDefensePenetrationBonus(
                tower.childDefensePenetrationUpgradeBonus,
              ) +
              combatBonus.defensePenetration)
          .clamp(0.0, 0.85);
    }
    return (tower.defensePenetration +
            _towerDefensePenetrationUpgradeBonus(
              _towerUpgradeBonusFor(
                tower,
                TowerUpgradeStatType.defensePenetration,
              ),
            ) +
            _towerLevelDefensePenetrationBonus(tower) +
            combatBonus.defensePenetration)
        .clamp(0.0, 0.75);
  }

  double towerMinDamageMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 1;
    }
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      return ((tower.childMinDamageMultiplier ??
                  (1.02 + (((tower.childLayerTier ?? 1) - 1) * 0.015))) +
              ((childLevel - 1) * 0.004) +
              _childTowerMinDamageBonus(tower.childMinDamageUpgradeBonus))
          .clamp(1.0, 2.4);
    }
    return (tower.minDamageFactor +
            _towerMinDamageUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.minDamage),
            ) +
            _towerLevelDamageBonus(tower))
        .clamp(1.0, 2.2);
  }

  double towerMaxDamageMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt) {
      return 1;
    }
    if (tower.isChildLayerNode) {
      final childLevel = tower.childCoreLevel ?? 1;
      final value =
          ((tower.childMaxDamageMultiplier ??
                      (1.1 + (((tower.childLayerTier ?? 1) - 1) * 0.02))) +
                  ((childLevel - 1) * 0.006) +
                  _childTowerMaxDamageBonus(tower.childMaxDamageUpgradeBonus))
              .clamp(1.0, 2.8);
      return max(value, towerMinDamageMultiplier(tower));
    }
    return max(
      (tower.maxDamageFactor +
              _towerMaxDamageUpgradeBonus(
                _towerUpgradeBonusFor(tower, TowerUpgradeStatType.maxDamage),
              ) +
              _towerLevelDamageBonus(tower))
          .clamp(1.0, 2.5),
      towerMinDamageMultiplier(tower),
    );
  }

  double towerDotDamageMultiplier(OuterTowerState tower) {
    if (!tower.isBuilt || tower.isChildLayerNode) {
      return 1;
    }
    return (tower.dotDamageFactor +
            _towerDotDamageUpgradeBonus(
              _towerUpgradeBonusFor(tower, TowerUpgradeStatType.dotDamage),
            ) +
            _towerLevelDamageBonus(tower))
        .clamp(1.0, 2.8);
  }

  int scaledReward(
    EnemyState enemy, {
    int? currentEnemyCount,
    int? sourceSlotIndex,
  }) {
    // TODO(full-game): Currency grants should be validated against an
    // authoritative encounter snapshot to block client-side reward spoofing.
    final sourceTower = sourceSlotIndex == null
        ? null
        : _slots[sourceSlotIndex];
    final yellowBonus =
        sourceTower != null &&
            _slotCountsTowardRing(sourceTower) &&
            _slotAffinity(sourceTower) == PrototypeAffinity.solar
        ? 1
        : 0;
    return max(
      1,
      (enemy.reward *
                  outputEfficiencyMultiplier *
                  lumenTierMultiplier *
                  friendAllianceRewardMultiplier *
                  _gearLumenMultiplier *
                  _economyBalanceMultiplier('lumenReward'))
              .round() +
          yellowBonus,
    );
  }

  double affinityMultiplier(
    PrototypeAffinity attacker,
    PrototypeAffinity defender,
  ) {
    if (attacker == PrototypeAffinity.neutral ||
        defender == PrototypeAffinity.neutral ||
        attacker == PrototypeAffinity.black ||
        defender == PrototypeAffinity.black) {
      return 1;
    }
    if (attacker == defender) {
      return 0.68;
    }

    const wheel = <PrototypeAffinity>[
      PrototypeAffinity.ember,
      PrototypeAffinity.flare,
      PrototypeAffinity.solar,
      PrototypeAffinity.verdant,
      PrototypeAffinity.aether,
      PrototypeAffinity.violet,
    ];

    final attackerIndex = wheel.indexOf(attacker);
    final defenderIndex = wheel.indexOf(defender);
    final strongIndex = (attackerIndex + 1) % wheel.length;
    final weakIndex = (attackerIndex - 1 + wheel.length) % wheel.length;

    if (defenderIndex == strongIndex) {
      return 1.32;
    }
    if (defenderIndex == weakIndex) {
      return 0.74;
    }
    return 1.0;
  }

  double _affinityMultiplierAgainstEnemy(
    PrototypeAffinity attacker,
    EnemyState enemy,
  ) {
    if (_enemyIsImmuneToAffinity(enemy, attacker)) {
      return 0;
    }

    var multiplier = affinityMultiplier(attacker, enemy.config.affinity);
    final secondaryAffinity = enemy.config.secondaryAffinity;
    if (secondaryAffinity != null) {
      multiplier = max(
        multiplier,
        affinityMultiplier(attacker, secondaryAffinity),
      );
    }
    return multiplier;
  }
}
