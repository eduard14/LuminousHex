part of '../lightcore_controller.dart';

extension LightcoreControllerSaveInventorySerialization on LightcoreController {
  Map<String, dynamic> _serializeInventoryCard(InventoryCard card) {
    return <String, dynamic>{
      'instanceId': card.instanceId,
      'configId': card.config.id,
      'rarity': card.rarity.name,
      'forgeCost': card.forgeCost,
      'powerMultiplier': card.powerMultiplier,
      'chargeMultiplier': card.chargeMultiplier,
      'cooldownMultiplier': card.cooldownMultiplier,
      'advantageMultiplier': card.advantageMultiplier,
      'automationRate': card.automationRate,
      'primaryTraitLabel': card.primaryTraitLabel,
      'secondaryTraitLabel': card.secondaryTraitLabel,
      'favoredAffinity': card.favoredAffinity?.name,
      'projectileFocus': card.projectileFocus?.name,
      'payloadFocus': card.payloadFocus?.name,
      'equippedLayerId': card.equippedLayerId,
      'equippedSlotIndex': card.equippedSlotIndex,
    };
  }

  InventoryCard? _deserializeInventoryCard(Map<String, dynamic> data) {
    final config = _cardConfigById(_stringOrNull(data['configId']));
    final rarity = _enumByName(
      ManagerRarity.values,
      _stringOrNull(data['rarity']),
    );
    if (config == null || rarity == null) {
      return null;
    }
    return InventoryCard(
      instanceId: _stringOrNull(data['instanceId']) ?? '${config.id}_card',
      config: config,
      rarity: rarity,
      forgeCost: _intValue(data['forgeCost']),
      powerMultiplier: _doubleValue(data['powerMultiplier'], fallback: 1),
      chargeMultiplier: _doubleValue(data['chargeMultiplier'], fallback: 1),
      cooldownMultiplier: _doubleValue(data['cooldownMultiplier'], fallback: 1),
      advantageMultiplier: _doubleValue(
        data['advantageMultiplier'],
        fallback: 1,
      ),
      automationRate: _doubleValue(
        data['automationRate'],
        fallback: config.automationRate,
      ),
      primaryTraitLabel: _stringValue(data['primaryTraitLabel']),
      secondaryTraitLabel: _stringValue(data['secondaryTraitLabel']),
      favoredAffinity: _enumByName(
        PrototypeAffinity.values,
        _stringOrNull(data['favoredAffinity']),
      ),
      projectileFocus: _enumByName(
        ProjectileType.values,
        _stringOrNull(data['projectileFocus']),
      ),
      payloadFocus: _enumByName(
        PayloadType.values,
        _stringOrNull(data['payloadFocus']),
      ),
      equippedLayerId: _stringOrNull(data['equippedLayerId']),
      equippedSlotIndex: _intOrNull(data['equippedSlotIndex']),
    );
  }

  Map<String, dynamic> _serializeEnemyManager(EnemyManagerState manager) {
    return <String, dynamic>{
      'instanceId': manager.instanceId,
      'configId': manager.config.id,
      'rarity': manager.rarity.name,
      'forgeCost': manager.forgeCost,
      'spawnRateMultiplier': manager.spawnRateMultiplier,
      'rewardMultiplier': manager.rewardMultiplier,
      'experienceMultiplier': manager.experienceMultiplier,
      'healthMultiplier': manager.healthMultiplier,
      'speedMultiplier': manager.speedMultiplier,
      'stabilityDamageMultiplier': manager.stabilityDamageMultiplier,
      'apexStabilityMultiplier': manager.apexStabilityMultiplier,
      'queueDisruptionMultiplier': manager.queueDisruptionMultiplier,
      'primaryTraitLabel': manager.primaryTraitLabel,
      'secondaryTraitLabel': manager.secondaryTraitLabel,
      'targetAffinity': manager.targetAffinity?.name,
      'assignedLayerId': manager.assignedLayerId,
      'assignedEnemyCardId': manager.assignedEnemyCardId,
    };
  }

  EnemyManagerState? _deserializeEnemyManager(Map<String, dynamic> data) {
    final config = _enemyManagerConfigById(_stringOrNull(data['configId']));
    final rarity = _enumByName(
      ManagerRarity.values,
      _stringOrNull(data['rarity']),
    );
    if (config == null || rarity == null) {
      return null;
    }
    return EnemyManagerState(
      instanceId:
          _stringOrNull(data['instanceId']) ?? '${config.id}_enemy_manager',
      config: config,
      rarity: rarity,
      forgeCost: _intValue(data['forgeCost']),
      spawnRateMultiplier: _doubleValue(
        data['spawnRateMultiplier'],
        fallback: 1,
      ),
      rewardMultiplier: _doubleValue(data['rewardMultiplier'], fallback: 1),
      experienceMultiplier: _doubleValue(
        data['experienceMultiplier'],
        fallback: 1,
      ),
      healthMultiplier: _doubleValue(data['healthMultiplier'], fallback: 1),
      speedMultiplier: _doubleValue(data['speedMultiplier'], fallback: 1),
      stabilityDamageMultiplier: _doubleValue(
        data['stabilityDamageMultiplier'],
        fallback: config.stabilityDamageMultiplier,
      ),
      apexStabilityMultiplier: _doubleValue(
        data['apexStabilityMultiplier'],
        fallback: config.apexStabilityMultiplier,
      ),
      queueDisruptionMultiplier: _doubleValue(
        data['queueDisruptionMultiplier'],
        fallback: config.queueDisruptionMultiplier,
      ),
      primaryTraitLabel: _stringValue(data['primaryTraitLabel']),
      secondaryTraitLabel: _stringValue(data['secondaryTraitLabel']),
      targetAffinity: _enumByName(
        PrototypeAffinity.values,
        _stringOrNull(data['targetAffinity']),
      ),
      assignedLayerId: _stringOrNull(data['assignedLayerId']),
      assignedEnemyCardId: _stringOrNull(data['assignedEnemyCardId']),
    );
  }

  Map<String, dynamic> _serializeEnemyCardState(EnemyCardState card) {
    return <String, dynamic>{
      'configId': card.config.id,
      'unlocked': card.unlocked,
      'copies': card.copies,
      'level': card.level,
    };
  }

  List<EnemyCardState> _restoreEnemyCardInventory({
    required List<dynamic> savedCards,
    required List<EnemyCardState> defaults,
  }) {
    final byId = <String, EnemyCardState>{
      for (final card in defaults) card.config.id: card,
    };

    for (final item in savedCards) {
      final data = _coerceMap(item);
      final configId = _stringOrNull(data['configId']);
      final existing = configId == null ? null : byId[configId];
      if (existing == null || configId == null) {
        continue;
      }
      byId[configId] = existing.copyWith(
        unlocked: _boolValue(data['unlocked']),
        copies: _intValue(data['copies'], fallback: existing.copies),
        level: _intValue(data['level'], fallback: existing.level),
      );
    }

    final orderedIds = defaults
        .map((card) => card.config.id)
        .toList(growable: false);
    return orderedIds
        .map((configId) => byId[configId]!)
        .toList(growable: false);
  }

  Map<String, dynamic> _serializePlayerEquipmentItem(PlayerEquipmentItem item) {
    return <String, dynamic>{
      'instanceId': item.instanceId,
      'setId': item.setId,
      'setName': item.setName,
      'slotType': item.slotType.name,
      'name': item.name,
      'rarity': item.rarity.name,
      'level': item.level,
      'affinity': item.affinity.name,
      'sourceEnemyId': item.sourceEnemyId,
      'sourceEnemyName': item.sourceEnemyName,
      'dropOrder': item.dropOrder,
      'bonuses': <String, dynamic>{
        'towerPower': item.bonuses.towerPower,
        'chargeRate': item.bonuses.chargeRate,
        'critChance': item.bonuses.critChance,
        'critDamage': item.bonuses.critDamage,
        'range': item.bonuses.range,
        'bossDamage': item.bonuses.bossDamage,
        'lumenGain': item.bonuses.lumenGain,
        'fluxGain': item.bonuses.fluxGain,
        'ticketGain': item.bonuses.ticketGain,
        'dropRate': item.bonuses.dropRate,
      },
    };
  }

  PlayerEquipmentItem? _deserializePlayerEquipmentItem(
    Map<String, dynamic> data,
  ) {
    final slotType = _enumByName(
      EquipmentInventorySlot.values,
      _stringOrNull(data['slotType']),
    );
    final rarity = _enumByName(
      ManagerRarity.values,
      _stringOrNull(data['rarity']),
    );
    final affinity = _enumByName(
      PrototypeAffinity.values,
      _stringOrNull(data['affinity']),
    );
    if (slotType == null || rarity == null || affinity == null) {
      return null;
    }
    final bonusData = _coerceMap(data['bonuses']);
    return PlayerEquipmentItem(
      instanceId: _stringOrNull(data['instanceId']) ?? 'equipment',
      setId: _stringValue(data['setId']),
      setName: _stringValue(data['setName']),
      slotType: slotType,
      name: _stringValue(data['name']),
      rarity: rarity,
      level: _intValue(data['level'], fallback: 1),
      affinity: affinity,
      sourceEnemyId: _stringValue(data['sourceEnemyId']),
      sourceEnemyName: _stringValue(data['sourceEnemyName']),
      bonuses: EquipmentBonusProfile(
        towerPower: _doubleValue(bonusData['towerPower']),
        chargeRate: _doubleValue(bonusData['chargeRate']),
        critChance: _doubleValue(bonusData['critChance']),
        critDamage: _doubleValue(bonusData['critDamage']),
        range: _doubleValue(bonusData['range']),
        bossDamage: _doubleValue(bonusData['bossDamage']),
        lumenGain: _doubleValue(bonusData['lumenGain']),
        fluxGain: _doubleValue(bonusData['fluxGain']),
        ticketGain: _doubleValue(bonusData['ticketGain']),
        dropRate: _doubleValue(bonusData['dropRate']),
      ),
      dropOrder: _intValue(data['dropOrder']),
    );
  }

  Map<BattlePassType, List<BattlePassProgress>> _restoreBattlePassMap(
    List<dynamic> savedBattlePasses,
  ) {
    final restored = _createBattlePassMap();
    final grouped = <BattlePassType, List<BattlePassProgress>>{};
    for (final item in savedBattlePasses) {
      final data = _coerceMap(item);
      final type = _enumByName(
        BattlePassType.values,
        _stringOrNull(data['type']),
      );
      if (type == null) {
        continue;
      }
      final passes = grouped.putIfAbsent(type, () => <BattlePassProgress>[]);
      final fallbackPass = restored[type]!.last;
      final generation = max(
        1,
        _intValue(data['generation'], fallback: passes.length + 1),
      );
      passes.add(
        BattlePassProgress(
          type: type,
          seasonKey:
              _stringOrNull(data['seasonKey']) ??
              _newBattlePassSeasonKey(type, generation: generation),
          generation: generation,
          progress: _intValue(data['progress']),
          premiumUnlocked: _boolValue(data['premiumUnlocked']),
          claimedRewardKeys: _coerceList(
            data['claimedRewardKeys'],
          ).map(_stringOrNull).whereType<String>().toSet(),
          snapshotManagerRarity:
              _enumByName(
                ManagerRarity.values,
                _stringOrNull(data['snapshotManagerRarity']),
              ) ??
              fallbackPass.snapshotManagerRarity,
          snapshotEnemyCardRarity:
              _enumByName(
                EnemyCardRarity.values,
                _stringOrNull(data['snapshotEnemyCardRarity']),
              ) ??
              fallbackPass.snapshotEnemyCardRarity,
        ),
      );
    }
    for (final entry in grouped.entries) {
      restored[entry.key] = entry.value;
    }
    _ensureStaticBattlePassesHaveCurrent(restored);
    return restored;
  }
}
