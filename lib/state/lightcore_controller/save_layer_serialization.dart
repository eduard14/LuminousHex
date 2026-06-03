part of '../lightcore_controller.dart';

extension LightcoreControllerSaveLayerSerialization on LightcoreController {
  Map<String, dynamic> _serializeLayerSnapshot(TowerLayerSnapshot layer) {
    return <String, dynamic>{
      'id': layer.id,
      'tier': layer.tier,
      'label': layer.label,
      'slots': layer.slots
          .map(_serializeOuterTowerState)
          .toList(growable: false),
      'core': _serializeCoreState(layer.core),
      'activeEnemyCardIds': List<String>.from(layer.activeEnemyCardIds),
      'activeBossEnemyCardId': layer.activeBossEnemyCardId,
      'enemyTargetCount': layer.enemyTargetCount,
      'enemyTargetUpgradeLevel': layer.enemyTargetUpgradeLevel,
      'enemyTargetUpgradeStep': enemyTargetUpgradeStep,
      'outerRingRevealed': layer.outerRingRevealed,
      'swarmActivated': layer.swarmActivated,
      'selectedSlotIndex': layer.selectedSlotIndex,
      'selectedEnemyCardId': layer.selectedEnemyCardId,
      'elapsed': layer.elapsed,
      'spawnTimer': layer.spawnTimer,
      'spawnSequence': layer.spawnSequence,
      'enemyCounter': layer.enemyCounter,
      'pulseCounter': layer.pulseCounter,
      'shotCounter': layer.shotCounter,
      'impactCounter': layer.impactCounter,
      'normalKillsSinceBoss': layer.normalKillsSinceBoss,
      'bossReady': layer.bossReady,
      'threatAssignmentPresets': layer.threatAssignmentPresets
          .map(_serializeThreatAssignmentPreset)
          .toList(growable: false),
      'selectedThreatAssignmentPresetId':
          layer.selectedThreatAssignmentPresetId,
      'childTowerUpgrades': layer.childTowerUpgrades
          .map(
            (upgrade) => <String, dynamic>{
              'type': upgrade.type.name,
              'rank': upgrade.rank,
            },
          )
          .toList(growable: false),
      'parentLayerId': layer.parentLayerId,
      'parentSlotIndex': layer.parentSlotIndex,
      'sourceLayerId': layer.sourceLayerId,
      'promotedParentLayerId': layer.promotedParentLayerId,
      'promotedIntoParentSlot': layer.promotedIntoParentSlot,
      'promotionTraitRoll': layer.promotionTraitRoll,
      'bestWaveReached': layer.bestWaveReached,
      'layer3TrialCleared': layer.layer3TrialCleared,
    };
  }

  TowerLayerSnapshot? _deserializeLayerSnapshot(Map<String, dynamic> data) {
    final layerId = _stringOrNull(data['id']);
    if (layerId == null) {
      return null;
    }
    final tier = _intValue(data['tier'], fallback: 1);
    final activeEnemyCardIds = _coerceList(
      data['activeEnemyCardIds'],
    ).map(_stringOrNull).whereType<String>().toList(growable: false);
    final resolvedActiveEnemyCardIds =
        activeEnemyCardIds.isEmpty ||
            (activeEnemyCardIds.length == 1 &&
                activeEnemyCardIds.single == EnemyLibrary.starterDefault.id)
        ? <String>[EnemyLibrary.basicWhite.id]
        : activeEnemyCardIds;
    final enemyTargetUpgradeLevel = _migratedEnemyTargetUpgradeLevel(
      savedUpgradeLevel: _intValue(
        data['enemyTargetUpgradeLevel'],
        fallback: 0,
      ),
      savedUpgradeStep: _intValue(
        data['enemyTargetUpgradeStep'],
        fallback: _legacyEnemyTargetUpgradeStep,
      ),
    );
    return TowerLayerSnapshot(
      id: layerId,
      tier: max(1, tier),
      label: _stringOrNull(data['label']) ?? 'Recovered Shell',
      slots: _deserializeOuterTowerSlots(_coerceList(data['slots'])),
      core: _deserializeCoreState(_coerceMap(data['core'])),
      enemies: <EnemyState>[],
      pulses: <EnergyPulseState>[],
      shots: <CoreShotState>[],
      impacts: <ImpactState>[],
      ammoQueue: <AmmoPacket>[],
      activeEnemyCardIds: resolvedActiveEnemyCardIds,
      enemyTargetCount: _intValue(
        data['enemyTargetCount'],
        fallback: initialEnemyTarget,
      ),
      enemyTargetUpgradeLevel: enemyTargetUpgradeLevel,
      outerRingRevealed: _boolValue(data['outerRingRevealed']),
      swarmActivated: _boolValue(data['swarmActivated']),
      selectedSlotIndex: _intOrNull(data['selectedSlotIndex']),
      selectedEnemyCardId:
          _stringOrNull(data['selectedEnemyCardId']) ??
          resolvedActiveEnemyCardIds.first,
      elapsed: _doubleValue(data['elapsed']),
      spawnTimer: _doubleValue(data['spawnTimer'], fallback: 1.0),
      spawnSequence: _intValue(data['spawnSequence']),
      enemyCounter: _intValue(data['enemyCounter']),
      pulseCounter: _intValue(data['pulseCounter']),
      shotCounter: _intValue(data['shotCounter']),
      impactCounter: _intValue(data['impactCounter']),
      normalKillsSinceBoss: _intValue(data['normalKillsSinceBoss']),
      bossReady: _boolValue(data['bossReady']),
      threatAssignmentPresets: _coerceList(data['threatAssignmentPresets'])
          .map((item) => _deserializeThreatAssignmentPreset(_coerceMap(item)))
          .whereType<ThreatAssignmentPresetState>()
          .toList(growable: false),
      selectedThreatAssignmentPresetId: _stringOrNull(
        data['selectedThreatAssignmentPresetId'],
      ),
      childTowerUpgrades: _coerceList(data['childTowerUpgrades'])
          .map((item) => _deserializeChildTowerUpgrade(_coerceMap(item)))
          .whereType<ChildTowerUpgradeState>()
          .toList(growable: false),
      activeBossEnemyCardId: _stringOrNull(data['activeBossEnemyCardId']),
      parentLayerId: _stringOrNull(data['parentLayerId']),
      parentSlotIndex: _intOrNull(data['parentSlotIndex']),
      sourceLayerId: _stringOrNull(data['sourceLayerId']),
      promotedParentLayerId: _stringOrNull(data['promotedParentLayerId']),
      promotedIntoParentSlot: _boolValue(data['promotedIntoParentSlot']),
      promotionTraitRoll: _intValue(data['promotionTraitRoll']),
      bestWaveReached: max(1, _intValue(data['bestWaveReached'], fallback: 1)),
      layer3TrialCleared: _boolValue(data['layer3TrialCleared']),
    );
  }

  Map<String, dynamic> _serializeThreatAssignmentPreset(
    ThreatAssignmentPresetState preset,
  ) {
    return <String, dynamic>{
      'id': preset.id,
      'name': preset.name,
      'enemyCardIds': List<String>.from(preset.enemyCardIds),
      'bossCardId': preset.bossCardId,
    };
  }

  ThreatAssignmentPresetState? _deserializeThreatAssignmentPreset(
    Map<String, dynamic> data,
  ) {
    final id = _stringOrNull(data['id']);
    final name = _stringOrNull(data['name']);
    if (id == null || name == null) {
      return null;
    }
    final seen = <String>{};
    final enemyCardIds = _coerceList(data['enemyCardIds'])
        .map(_stringOrNull)
        .whereType<String>()
        .where(seen.add)
        .take(enemyDeckLimit)
        .toList(growable: false);
    if (enemyCardIds.isEmpty) {
      return null;
    }
    return ThreatAssignmentPresetState(
      id: id,
      name: name,
      enemyCardIds: enemyCardIds,
      bossCardId: _stringOrNull(data['bossCardId']),
    );
  }

  List<OuterTowerState> _deserializeOuterTowerSlots(List<dynamic> savedSlots) {
    return List<OuterTowerState>.generate(slotCount, (index) {
      if (index >= savedSlots.length) {
        return OuterTowerState(slotIndex: index);
      }
      return _deserializeOuterTowerState(
            _coerceMap(savedSlots[index]),
            slotIndex: index,
          ) ??
          OuterTowerState(slotIndex: index);
    }, growable: false);
  }

  Map<String, dynamic> _serializeOuterTowerState(OuterTowerState tower) {
    return <String, dynamic>{
      'slotIndex': tower.slotIndex,
      'configId': tower.config?.id,
      'level': tower.level,
      'charge': tower.charge,
      'cooldownRemaining': tower.cooldownRemaining,
      'automationCooldownRemaining': tower.automationCooldownRemaining,
      'disruption': tower.disruption,
      'equippedCardInstanceId': tower.equippedCardInstanceId,
      'projectileType': tower.projectileType?.name,
      'payloadType': tower.payloadType?.name,
      'fireSequence': tower.fireSequence,
      'investedLumens': tower.investedLumens,
      'fabricationTotalSeconds': tower.fabricationTotalSeconds,
      'fabricationRemainingSeconds': tower.fabricationRemainingSeconds,
      'fabricationStartedAtServerMillis':
          tower.fabricationStartedAtServerMillis,
      'fabricationCompletesAtServerMillis':
          tower.fabricationCompletesAtServerMillis,
      'powerFactor': tower.powerFactor,
      'chargeFactor': tower.chargeFactor,
      'cooldownFactor': tower.cooldownFactor,
      'rangeFactor': tower.rangeFactor,
      'generationFactor': tower.generationFactor,
      'critChanceBonus': tower.critChanceBonus,
      'critDamageFactor': tower.critDamageFactor,
      'finalDamageFactor': tower.finalDamageFactor,
      'bossDamageFactor': tower.bossDamageFactor,
      'normalDamageFactor': tower.normalDamageFactor,
      'defensePenetration': tower.defensePenetration,
      'minDamageFactor': tower.minDamageFactor,
      'maxDamageFactor': tower.maxDamageFactor,
      'dotDamageFactor': tower.dotDamageFactor,
      'towerUpgradeOptions': tower.towerUpgradeOptions
          .map(_serializeTowerUpgradeState)
          .toList(growable: false),
      'childLayerId': tower.childLayerId,
      'childLayerTier': tower.childLayerTier,
      'childLayerName': tower.childLayerName,
      'childAffinity': tower.childAffinity?.name,
      'childSecondaryAffinity': tower.childSecondaryAffinity?.name,
      'childProjectileLoadout': tower.childProjectileLoadout
          .map((type) => type.name)
          .toList(growable: false),
      'childPayloadLoadout': tower.childPayloadLoadout
          .map((type) => type.name)
          .toList(growable: false),
      'childProjectileType': tower.childProjectileType?.name,
      'childPayloadType': tower.childPayloadType?.name,
      'childCoreLevel': tower.childCoreLevel,
      'childRange': tower.childRange,
      'childGenerationSpeed': tower.childGenerationSpeed,
      'childCritChance': tower.childCritChance,
      'childCritMultiplier': tower.childCritMultiplier,
      'childFinalDamageMultiplier': tower.childFinalDamageMultiplier,
      'childBossDamageMultiplier': tower.childBossDamageMultiplier,
      'childNormalDamageMultiplier': tower.childNormalDamageMultiplier,
      'childDefensePenetration': tower.childDefensePenetration,
      'childMinDamageMultiplier': tower.childMinDamageMultiplier,
      'childMaxDamageMultiplier': tower.childMaxDamageMultiplier,
      'childPowerUpgradeBonus': tower.childPowerUpgradeBonus,
      'childChargeUpgradeBonus': tower.childChargeUpgradeBonus,
      'childCooldownUpgradeBonus': tower.childCooldownUpgradeBonus,
      'childRangeUpgradeBonus': tower.childRangeUpgradeBonus,
      'childGenerationUpgradeBonus': tower.childGenerationUpgradeBonus,
      'childCritChanceUpgradeBonus': tower.childCritChanceUpgradeBonus,
      'childCritDamageUpgradeBonus': tower.childCritDamageUpgradeBonus,
      'childFinalDamageUpgradeBonus': tower.childFinalDamageUpgradeBonus,
      'childBossDamageUpgradeBonus': tower.childBossDamageUpgradeBonus,
      'childNormalDamageUpgradeBonus': tower.childNormalDamageUpgradeBonus,
      'childDefensePenetrationUpgradeBonus':
          tower.childDefensePenetrationUpgradeBonus,
      'childMinDamageUpgradeBonus': tower.childMinDamageUpgradeBonus,
      'childMaxDamageUpgradeBonus': tower.childMaxDamageUpgradeBonus,
      'childBuiltCount': tower.childBuiltCount,
      'childPromoted': tower.childPromoted,
    };
  }

  OuterTowerState? _deserializeOuterTowerState(
    Map<String, dynamic> data, {
    required int slotIndex,
  }) {
    final config = _towerConfigById(_stringOrNull(data['configId']));
    final projectileType = _deserializeOuterTowerProjectileType(
      config,
      _stringOrNull(data['projectileType']),
    );
    return OuterTowerState(
      slotIndex: _intValue(data['slotIndex'], fallback: slotIndex),
      config: config,
      level: _intValue(data['level'], fallback: 1),
      charge: _doubleValue(data['charge']),
      cooldownRemaining: _doubleValue(data['cooldownRemaining']),
      automationCooldownRemaining: _doubleValue(
        data['automationCooldownRemaining'],
      ),
      disruption: _doubleValue(data['disruption']),
      equippedCardInstanceId: _stringOrNull(data['equippedCardInstanceId']),
      projectileType: projectileType,
      payloadType: _enumByName(
        PayloadType.values,
        _stringOrNull(data['payloadType']),
      ),
      fireSequence: _intValue(data['fireSequence']),
      investedLumens: _intValue(data['investedLumens']),
      fabricationTotalSeconds: _doubleValue(data['fabricationTotalSeconds']),
      fabricationRemainingSeconds: _doubleValue(
        data['fabricationRemainingSeconds'],
      ),
      fabricationStartedAtServerMillis: _intOrNull(
        data['fabricationStartedAtServerMillis'],
      ),
      fabricationCompletesAtServerMillis: _intOrNull(
        data['fabricationCompletesAtServerMillis'],
      ),
      powerFactor: _doubleValue(data['powerFactor'], fallback: 1),
      chargeFactor: _doubleValue(data['chargeFactor'], fallback: 1),
      cooldownFactor: _doubleValue(data['cooldownFactor'], fallback: 1),
      rangeFactor: _doubleValue(data['rangeFactor'], fallback: 1),
      generationFactor: _doubleValue(data['generationFactor'], fallback: 1),
      critChanceBonus: _doubleValue(data['critChanceBonus']),
      critDamageFactor: _doubleValue(data['critDamageFactor'], fallback: 1),
      finalDamageFactor: _doubleValue(data['finalDamageFactor'], fallback: 1),
      bossDamageFactor: _doubleValue(data['bossDamageFactor'], fallback: 1),
      normalDamageFactor: _doubleValue(data['normalDamageFactor'], fallback: 1),
      defensePenetration: _doubleValue(data['defensePenetration']),
      minDamageFactor: _doubleValue(data['minDamageFactor'], fallback: 1),
      maxDamageFactor: _doubleValue(data['maxDamageFactor'], fallback: 1),
      dotDamageFactor: _doubleValue(data['dotDamageFactor'], fallback: 1),
      towerUpgradeOptions: _coerceList(data['towerUpgradeOptions'])
          .map((item) => _deserializeTowerUpgrade(_coerceMap(item)))
          .whereType<TowerUpgradeOptionState>()
          .toList(growable: false),
      childLayerId: _stringOrNull(data['childLayerId']),
      childLayerTier: _intOrNull(data['childLayerTier']),
      childLayerName: _stringOrNull(data['childLayerName']),
      childAffinity: _enumByName(
        PrototypeAffinity.values,
        _stringOrNull(data['childAffinity']),
      ),
      childSecondaryAffinity: _enumByName(
        PrototypeAffinity.values,
        _stringOrNull(data['childSecondaryAffinity']),
      ),
      childProjectileLoadout: _coerceList(data['childProjectileLoadout'])
          .map(_stringOrNull)
          .whereType<String>()
          .map(_restoreOptionalActiveProjectileType)
          .whereType<ProjectileType>()
          .toList(growable: false),
      childPayloadLoadout: _coerceList(data['childPayloadLoadout'])
          .map(_stringOrNull)
          .whereType<String>()
          .map((value) => _enumByName(PayloadType.values, value))
          .whereType<PayloadType>()
          .toList(growable: false),
      childProjectileType: _restoreOptionalActiveProjectileType(
        _stringOrNull(data['childProjectileType']),
      ),
      childPayloadType: _enumByName(
        PayloadType.values,
        _stringOrNull(data['childPayloadType']),
      ),
      childCoreLevel: _intOrNull(data['childCoreLevel']),
      childRange: _doubleOrNull(data['childRange']),
      childGenerationSpeed: _doubleOrNull(data['childGenerationSpeed']),
      childCritChance: _doubleOrNull(data['childCritChance']),
      childCritMultiplier: _doubleOrNull(data['childCritMultiplier']),
      childFinalDamageMultiplier: _doubleOrNull(
        data['childFinalDamageMultiplier'],
      ),
      childBossDamageMultiplier: _doubleOrNull(
        data['childBossDamageMultiplier'],
      ),
      childNormalDamageMultiplier: _doubleOrNull(
        data['childNormalDamageMultiplier'],
      ),
      childDefensePenetration: _doubleOrNull(data['childDefensePenetration']),
      childMinDamageMultiplier: _doubleOrNull(data['childMinDamageMultiplier']),
      childMaxDamageMultiplier: _doubleOrNull(data['childMaxDamageMultiplier']),
      childPowerUpgradeBonus: _doubleValue(data['childPowerUpgradeBonus']),
      childChargeUpgradeBonus: _doubleValue(data['childChargeUpgradeBonus']),
      childCooldownUpgradeBonus: _doubleValue(
        data['childCooldownUpgradeBonus'],
      ),
      childRangeUpgradeBonus: _doubleValue(data['childRangeUpgradeBonus']),
      childGenerationUpgradeBonus: _doubleValue(
        data['childGenerationUpgradeBonus'],
      ),
      childCritChanceUpgradeBonus: _doubleValue(
        data['childCritChanceUpgradeBonus'],
      ),
      childCritDamageUpgradeBonus: _doubleValue(
        data['childCritDamageUpgradeBonus'],
      ),
      childFinalDamageUpgradeBonus: _doubleValue(
        data['childFinalDamageUpgradeBonus'],
      ),
      childBossDamageUpgradeBonus: _doubleValue(
        data['childBossDamageUpgradeBonus'],
      ),
      childNormalDamageUpgradeBonus: _doubleValue(
        data['childNormalDamageUpgradeBonus'],
      ),
      childDefensePenetrationUpgradeBonus: _doubleValue(
        data['childDefensePenetrationUpgradeBonus'],
      ),
      childMinDamageUpgradeBonus: _doubleValue(
        data['childMinDamageUpgradeBonus'],
      ),
      childMaxDamageUpgradeBonus: _doubleValue(
        data['childMaxDamageUpgradeBonus'],
      ),
      childBuiltCount: _intValue(data['childBuiltCount']),
      childPromoted: _boolValue(data['childPromoted']),
    );
  }

  Map<String, dynamic> _serializeCompletedTowerShellState(
    CompletedTowerShellState shell,
  ) {
    return <String, dynamic>{
      'id': shell.id,
      'sourceLayerId': shell.sourceLayerId,
      'sourceLayerLabel': shell.sourceLayerLabel,
      'sourceLayerTier': shell.sourceLayerTier,
      'sourceSlotIndex': shell.sourceSlotIndex,
      'savedAtMillis': shell.savedAtMillis,
      'layer': _serializeLayerSnapshot(shell.layer),
    };
  }

  CompletedTowerShellState? _deserializeCompletedTowerShellState(
    Map<String, dynamic> data,
  ) {
    final id = _stringOrNull(data['id']);
    final sourceLayerId = _stringOrNull(data['sourceLayerId']);
    final layer = _deserializeLayerSnapshot(_coerceMap(data['layer']));
    if (id == null || sourceLayerId == null || layer == null) {
      return null;
    }
    return CompletedTowerShellState(
      id: id,
      sourceLayerId: sourceLayerId,
      sourceLayerLabel:
          _stringOrNull(data['sourceLayerLabel']) ?? shellNameForTier(1),
      sourceLayerTier: _intValue(data['sourceLayerTier'], fallback: 1),
      sourceSlotIndex: _intOrNull(data['sourceSlotIndex']),
      savedAtMillis: _intValue(data['savedAtMillis']),
      layer: layer,
    );
  }

  Map<String, dynamic> _serializeLayer2ComponentState(
    Layer2ComponentState component,
  ) {
    return <String, dynamic>{
      'id': component.id,
      'sourceLayerId': component.sourceLayerId,
      'sourceLayerLabel': component.sourceLayerLabel,
      'createdAtMillis': component.createdAtMillis,
      'reachedWave': component.reachedWave,
      'statTier': component.statTier,
      'projectileAffinity': component.projectileAffinity.name,
      'payloadAffinity': component.payloadAffinity?.name,
      'projectileType': component.projectileType.name,
      'payloadType': component.payloadType.name,
      'basePowerMultiplier': component.basePowerMultiplier,
      'baseRangeMultiplier': component.baseRangeMultiplier,
      'baseChargeMultiplier': component.baseChargeMultiplier,
      'baseFinalDamageMultiplier': component.baseFinalDamageMultiplier,
      'baseBossDamageMultiplier': component.baseBossDamageMultiplier,
      'baseNormalDamageMultiplier': component.baseNormalDamageMultiplier,
      'baseDefensePenetration': component.baseDefensePenetration,
      'subtraits': component.subtraits
          .map(
            (subtrait) => <String, dynamic>{
              'type': subtrait.type.name,
              'value': subtrait.value,
            },
          )
          .toList(growable: false),
      'scrollLevel': component.scrollLevel,
      'equippedRegionId': component.equippedRegionId,
      'favorite': component.favorite,
    };
  }

  Layer2ComponentState? _deserializeLayer2ComponentState(
    Map<String, dynamic> data,
  ) {
    final id = _stringOrNull(data['id']);
    final sourceLayerId = _stringOrNull(data['sourceLayerId']);
    final projectileAffinity = _enumByName(
      PrototypeAffinity.values,
      _stringOrNull(data['projectileAffinity']),
    );
    final projectileType = _enumByName(
      ProjectileType.values,
      _stringOrNull(data['projectileType']),
    );
    final payloadType =
        _enumByName(PayloadType.values, _stringOrNull(data['payloadType'])) ??
        PayloadType.none;
    if (id == null ||
        sourceLayerId == null ||
        projectileAffinity == null ||
        projectileType == null) {
      return null;
    }
    return Layer2ComponentState(
      id: id,
      sourceLayerId: sourceLayerId,
      sourceLayerLabel:
          _stringOrNull(data['sourceLayerLabel']) ?? 'Archived Shell',
      createdAtMillis: _intValue(data['createdAtMillis']),
      reachedWave: max(1, _intValue(data['reachedWave'], fallback: 1)),
      statTier: max(1, _intValue(data['statTier'], fallback: 1)),
      projectileAffinity: projectileAffinity,
      payloadAffinity: _enumByName(
        PrototypeAffinity.values,
        _stringOrNull(data['payloadAffinity']),
      ),
      projectileType: projectileType,
      payloadType: payloadType,
      basePowerMultiplier: _doubleValue(
        data['basePowerMultiplier'],
        fallback: 1,
      ),
      baseRangeMultiplier: _doubleValue(
        data['baseRangeMultiplier'],
        fallback: 1,
      ),
      baseChargeMultiplier: _doubleValue(
        data['baseChargeMultiplier'],
        fallback: 1,
      ),
      baseFinalDamageMultiplier: _doubleValue(
        data['baseFinalDamageMultiplier'],
        fallback: 1,
      ),
      baseBossDamageMultiplier: _doubleValue(
        data['baseBossDamageMultiplier'],
        fallback: 1,
      ),
      baseNormalDamageMultiplier: _doubleValue(
        data['baseNormalDamageMultiplier'],
        fallback: 1,
      ),
      baseDefensePenetration: _doubleValue(data['baseDefensePenetration']),
      subtraits: _coerceList(data['subtraits'])
          .map((item) => _deserializeLayer2ComponentSubtrait(_coerceMap(item)))
          .whereType<Layer2ComponentSubtraitState>()
          .toList(growable: false),
      scrollLevel: max(0, _intValue(data['scrollLevel'])),
      equippedRegionId: _stringOrNull(data['equippedRegionId']),
      favorite: _boolValue(data['favorite']),
    );
  }

  Layer2ComponentSubtraitState? _deserializeLayer2ComponentSubtrait(
    Map<String, dynamic> data,
  ) {
    final type = _enumByName(
      TowerUpgradeStatType.values,
      _stringOrNull(data['type']),
    );
    if (type == null) {
      return null;
    }
    return Layer2ComponentSubtraitState(
      type: type,
      value: _doubleValue(data['value']),
    );
  }

  ProjectileType? _deserializeOuterTowerProjectileType(
    TowerConfig? config,
    String? projectileTypeName,
  ) {
    final projectileType = _enumByName(
      ProjectileType.values,
      projectileTypeName,
    );
    if (projectileType == ProjectileType.orbitNode) {
      return ProjectileType.shieldHalo;
    }
    return projectileType;
  }

  ProjectileType _restoreActiveProjectileType(
    String? projectileTypeName, {
    required ProjectileType fallback,
  }) {
    final projectileType = _enumByName(
      ProjectileType.values,
      projectileTypeName,
    );
    if (projectileType == ProjectileType.orbitNode) {
      return ProjectileType.shieldHalo;
    }
    return projectileType ?? fallback;
  }

  ProjectileType? _restoreOptionalActiveProjectileType(
    String? projectileTypeName,
  ) {
    final projectileType = _enumByName(
      ProjectileType.values,
      projectileTypeName,
    );
    if (projectileType == ProjectileType.orbitNode) {
      return ProjectileType.shieldHalo;
    }
    return projectileType;
  }

  TowerUpgradeOptionState? _deserializeTowerUpgrade(Map<String, dynamic> data) {
    final type = _enumByName(
      TowerUpgradeStatType.values,
      _stringOrNull(data['type']),
    );
    if (type == null) {
      return null;
    }
    return TowerUpgradeOptionState(
      type: type,
      rank: _intValue(data['rank']),
      isOvercharge: _boolValue(data['isOvercharge']),
      isRadiant: _boolValue(data['isRadiant']),
    );
  }

  ChildTowerUpgradeState? _deserializeChildTowerUpgrade(
    Map<String, dynamic> data,
  ) {
    final type = _enumByName(
      ChildTowerUpgradeType.values,
      _stringOrNull(data['type']),
    );
    if (type == null) {
      return null;
    }
    return ChildTowerUpgradeState(type: type, rank: _intValue(data['rank']));
  }

  Map<String, dynamic> _serializeCoreState(CoreState core) {
    return <String, dynamic>{
      'coreStability': core.coreStability,
      'coreEnergy': core.coreEnergy,
      'flowEfficiency': core.flowEfficiency,
      'fireCooldownRemaining': core.fireCooldownRemaining,
      'packetCooldownRemaining': core.packetCooldownRemaining,
      'automationCooldownRemaining': core.automationCooldownRemaining,
      'level': core.level,
      'projectileType': core.projectileType.name,
      'payloadType': core.payloadType.name,
      'affinity': core.affinity.name,
      'secondaryAffinity': core.secondaryAffinity?.name,
      'projectileLoadout': core.projectileLoadout
          .map((type) => type.name)
          .toList(growable: false),
      'payloadLoadout': core.payloadLoadout
          .map((type) => type.name)
          .toList(growable: false),
      'fireSequence': core.fireSequence,
      'rangeUpgradeLevel': core.rangeUpgradeLevel,
      'fireSpeedUpgradeLevel': core.fireSpeedUpgradeLevel,
      'multiShotUpgradeLevel': core.multiShotUpgradeLevel,
      'queueLimitUpgradeLevel': core.queueLimitUpgradeLevel,
      'energyCapacityUpgradeLevel': core.energyCapacityUpgradeLevel,
      'energyRecoveryUpgradeLevel': core.energyRecoveryUpgradeLevel,
      'coreUpgradeOptions': core.coreUpgradeOptions
          .map(_serializeTowerUpgradeState)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _serializeTowerUpgradeState(
    TowerUpgradeOptionState option,
  ) {
    return <String, dynamic>{
      'type': option.type.name,
      'rank': option.rank,
      'isOvercharge': option.isOvercharge,
      'isRadiant': option.isRadiant,
    };
  }

  CoreState _deserializeCoreState(Map<String, dynamic> data) {
    final legacyFlowEfficiency = _doubleValue(
      data['flowEfficiency'],
      fallback: _maxFlowEfficiency,
    );
    final coreStability = _doubleValue(
      data['coreStability'],
      fallback: _stabilityForLegacyOutputEfficiency(legacyFlowEfficiency),
    ).clamp(0.0, _maxCoreStability);
    final energyCapacityUpgradeLevel = _intValue(
      data['energyCapacityUpgradeLevel'],
    ).clamp(0, _maxCoreEnergyUpgradeLevel);
    final coreEnergyCapacity = _coreEnergyCapacityForUpgradeLevel(
      energyCapacityUpgradeLevel,
    );
    final coreEnergy = _doubleValue(
      data['coreEnergy'],
      fallback: coreEnergyCapacity,
    ).clamp(0.0, coreEnergyCapacity);
    final projectileType = _restoreActiveProjectileType(
      _stringOrNull(data['projectileType']),
      fallback: ProjectileType.starBolt,
    );
    final payloadType =
        _enumByName(PayloadType.values, _stringOrNull(data['payloadType'])) ??
        PayloadType.none;
    final coreUpgradeOptions = _coerceList(data['coreUpgradeOptions'])
        .map((item) => _deserializeTowerUpgrade(_coerceMap(item)))
        .whereType<TowerUpgradeOptionState>()
        .toList(growable: false);
    return CoreState(
      coreStability: coreStability,
      coreEnergy: coreEnergy,
      flowEfficiency: _outputEfficiencyPercentForStability(coreStability),
      fireCooldownRemaining: _doubleValue(data['fireCooldownRemaining']),
      packetCooldownRemaining: _doubleValue(data['packetCooldownRemaining']),
      automationCooldownRemaining: _doubleValue(
        data['automationCooldownRemaining'],
      ),
      level: _intValue(data['level'], fallback: 1),
      projectileType: projectileType,
      payloadType: payloadType,
      affinity:
          _enumByName(
            PrototypeAffinity.values,
            _stringOrNull(data['affinity']),
          ) ??
          PrototypeAffinity.neutral,
      secondaryAffinity: _enumByName(
        PrototypeAffinity.values,
        _stringOrNull(data['secondaryAffinity']),
      ),
      projectileLoadout: _coerceList(data['projectileLoadout'])
          .map(_stringOrNull)
          .whereType<String>()
          .map(_restoreOptionalActiveProjectileType)
          .whereType<ProjectileType>()
          .toList(growable: false),
      payloadLoadout: _coerceList(data['payloadLoadout'])
          .map(_stringOrNull)
          .whereType<String>()
          .map((value) => _enumByName(PayloadType.values, value))
          .whereType<PayloadType>()
          .toList(growable: false),
      fireSequence: _intValue(data['fireSequence']),
      rangeUpgradeLevel: _intValue(data['rangeUpgradeLevel']),
      fireSpeedUpgradeLevel: _intValue(data['fireSpeedUpgradeLevel']),
      multiShotUpgradeLevel: _intValue(data['multiShotUpgradeLevel']),
      queueLimitUpgradeLevel: _intValue(data['queueLimitUpgradeLevel']),
      energyCapacityUpgradeLevel: energyCapacityUpgradeLevel,
      energyRecoveryUpgradeLevel: _intValue(
        data['energyRecoveryUpgradeLevel'],
      ).clamp(0, _maxCoreEnergyUpgradeLevel),
      coreUpgradeOptions: coreUpgradeOptions.isNotEmpty
          ? coreUpgradeOptions
          : _rollCoreUpgradeBoardForLoadout(projectileType, payloadType),
    );
  }
}
