part of '../lightcore_controller.dart';

extension LightcoreControllerCombatEquipment on LightcoreController {
  int _rollEquipmentEventCacheLevel() {
    final baseLevel = max(1, overallLevel + ((activeLayer.tier - 1) * 2));
    final roll = _packRandom.nextDouble();
    if (roll < 0.18) {
      return baseLevel + 1;
    }
    if (roll < 0.72) {
      return baseLevel;
    }
    return max(1, baseLevel - 1);
  }

  ManagerRarity _rollEquipmentRarity(EnemyState enemy) {
    var baseScore = enemy.config.isBoss
        ? max(2, min(4, enemy.config.rarity.index))
        : min(4, enemy.config.rarity.index);
    if (enemy.cardLevel >= 8) {
      baseScore = min(4, baseScore + 1);
    }
    final roll = _packRandom.nextDouble();
    if (roll < (enemy.config.isBoss ? 0.18 : 0.08)) {
      return ManagerRarity.values[min(4, baseScore + 1)];
    }
    if (roll < 0.48) {
      return ManagerRarity.values[baseScore];
    }
    return ManagerRarity.values[max(0, baseScore - 1)];
  }

  int _rollEquipmentLevel(EnemyState enemy) {
    final targetLevel = max(1, enemy.cardLevel + ((activeLayer.tier - 1) * 2));
    final sameLevelChance = enemy.config.isBoss
        ? 0.38
        : 0.08 + (enemy.config.rarity.index * 0.05);
    final aboveLevelChance = enemy.config.isBoss ? 0.1 : 0.02;
    final roll = _packRandom.nextDouble();
    if (roll < aboveLevelChance) {
      return targetLevel + 1;
    }
    if (roll < aboveLevelChance + sameLevelChance) {
      return targetLevel;
    }
    final reduction = 1 + _packRandom.nextInt(enemy.config.isBoss ? 2 : 3);
    return max(1, targetLevel - reduction);
  }

  double _equipmentRarityScale(ManagerRarity rarity) => switch (rarity) {
    ManagerRarity.common => 1.0,
    ManagerRarity.uncommon => 1.14,
    ManagerRarity.rare => 1.32,
    ManagerRarity.epic => 1.56,
    ManagerRarity.legendary => 1.86,
  };

  void _enforceEquipmentInventoryCap() {
    final overflow = _equipmentInventory.length - maxEquipmentInventorySize;
    if (overflow <= 0) {
      return;
    }
    final removable =
        _equipmentInventory
            .where((item) => !isPlayerItemEquipped(item.instanceId))
            .toList()
          ..sort(_compareEquipmentRemovalPriority);
    final removedItems = removable.take(overflow).toList(growable: false);
    if (removedItems.isEmpty) {
      return;
    }
    final fluxGranted = _removeEquipmentItems(removedItems);
    _showBanner(
      'Inventory capped at $maxEquipmentInventorySize. ${removedItems.length} old equipment piece${removedItems.length == 1 ? '' : 's'} auto-dismantled for ${LightcoreCurrencyLabels.fluxCount(fluxGranted)}.',
    );
  }

  List<PlayerEquipmentItem> _equipmentAutoDismantleCandidates() {
    final candidates = <PlayerEquipmentItem>[];
    for (final slotType in EquipmentInventorySlot.values) {
      final items =
          _equipmentInventory
              .where((item) => item.slotType == slotType)
              .toList()
            ..sort(_compareEquipmentKeepPriority);
      final quota = _equipmentRetentionQuota(slotType);
      if (items.length <= quota) {
        continue;
      }
      candidates.addAll(items.skip(quota));
    }
    candidates.sort(_compareEquipmentRemovalPriority);
    return candidates;
  }

  int _equipmentRetentionQuota(EquipmentInventorySlot slotType) {
    final matchingLoadoutSlots = EquipmentLoadoutSlot.values
        .where((slot) => slot.acceptedType == slotType)
        .length;
    final perLoadoutSlot =
        maxEquipmentInventorySize ~/ EquipmentLoadoutSlot.values.length;
    return max(matchingLoadoutSlots, matchingLoadoutSlots * perLoadoutSlot);
  }

  int _compareEquipmentKeepPriority(
    PlayerEquipmentItem a,
    PlayerEquipmentItem b,
  ) {
    final equippedCompare = _equippedWeight(
      b.instanceId,
    ).compareTo(_equippedWeight(a.instanceId));
    if (equippedCompare != 0) {
      return equippedCompare;
    }
    final rarityCompare = b.rarity.score.compareTo(a.rarity.score);
    if (rarityCompare != 0) {
      return rarityCompare;
    }
    final levelCompare = b.level.compareTo(a.level);
    if (levelCompare != 0) {
      return levelCompare;
    }
    final recencyCompare = b.dropOrder.compareTo(a.dropOrder);
    if (recencyCompare != 0) {
      return recencyCompare;
    }
    return a.instanceId.compareTo(b.instanceId);
  }

  int _compareEquipmentRemovalPriority(
    PlayerEquipmentItem a,
    PlayerEquipmentItem b,
  ) {
    final equippedCompare = _equippedWeight(
      a.instanceId,
    ).compareTo(_equippedWeight(b.instanceId));
    if (equippedCompare != 0) {
      return equippedCompare;
    }
    final rarityCompare = a.rarity.score.compareTo(b.rarity.score);
    if (rarityCompare != 0) {
      return rarityCompare;
    }
    final levelCompare = a.level.compareTo(b.level);
    if (levelCompare != 0) {
      return levelCompare;
    }
    final ageCompare = a.dropOrder.compareTo(b.dropOrder);
    if (ageCompare != 0) {
      return ageCompare;
    }
    return a.instanceId.compareTo(b.instanceId);
  }

  int _equippedWeight(String itemId) => isPlayerItemEquipped(itemId) ? 1 : 0;

  int _removeEquipmentItems(Iterable<PlayerEquipmentItem> items) {
    final itemList = items.toList(growable: false);
    if (itemList.isEmpty) {
      return 0;
    }
    final instanceIds = itemList.map((item) => item.instanceId).toSet();
    final fluxGranted = itemList.fold<int>(
      0,
      (sum, item) => sum + _equipmentDismantleFluxValue(item),
    );
    _newEquipmentItemIds.removeAll(instanceIds);
    _equipmentInventory.removeWhere(
      (item) => instanceIds.contains(item.instanceId),
    );
    flux += fluxGranted;
    return fluxGranted;
  }

  void _trackNewEquipmentItem(PlayerEquipmentItem item) {
    if (!_newEquipmentItemIds.add(item.instanceId)) {
      return;
    }
    _needsNotify = true;
  }

  int _equipmentDismantleFluxValue(PlayerEquipmentItem item) =>
      max(1, item.rarity.score + 1 + ((item.level - 1) ~/ 3));

  EnemyState _applyPayloadEffect(
    EnemyState enemy,
    PayloadType payloadType,
    double damage,
    PrototypeAffinity affinity,
    PrototypeAffinity? secondaryAffinity,
    int? sourceSlotIndex,
  ) {
    final potency = payloadType.potencyMultiplier;
    switch (payloadType.effectProfile) {
      case PayloadEffectProfile.none:
        return enemy;
      case PayloadEffectProfile.burn:
        return enemy.copyWith(
          burnRemaining: max(enemy.burnRemaining, 2.6 * potency),
          burnDamagePerSecond: max(
            enemy.burnDamagePerSecond,
            damage *
                0.14 *
                potency *
                _sourceTowerDotDamageMultiplier(sourceSlotIndex),
          ),
        );
      case PayloadEffectProfile.freeze:
        return enemy.copyWith(
          slowRemaining: max(enemy.slowRemaining, 1.5 * potency),
          slowFactor: min(enemy.slowFactor, 0.56 / potency.clamp(1.0, 1.5)),
        );
      case PayloadEffectProfile.shock:
        for (final secondary in _nearbyEnemies(enemy, within: 28).toList()) {
          _applyDamage(
            secondary.id,
            damage * (0.22 * potency),
            affinity,
            layer2: false,
            secondaryAffinity: secondaryAffinity,
            sourceSlotIndex: sourceSlotIndex,
            payloadType: payloadType,
            applyPayloadEffects: false,
          );
        }
        return enemy.copyWith(
          slowRemaining: max(enemy.slowRemaining, 0.8 * potency),
          slowFactor: min(enemy.slowFactor, 0.86 / potency.clamp(1.0, 1.5)),
          shockRemaining: max(enemy.shockRemaining, 1.0 * potency),
        );
      case PayloadEffectProfile.knockback:
        return enemy.copyWith(radius: enemy.radius + (20 * potency));
      case PayloadEffectProfile.bounty:
        return enemy.copyWith(
          bountyRemaining: max(enemy.bountyRemaining, 1.45 * potency),
          bountyMultiplier: max(enemy.bountyMultiplier, 0.42 * potency),
        );
    }
  }
}
