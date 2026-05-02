part of '../lightcore_controller.dart';

extension LightcoreControllerRewardsSocial on LightcoreController {
  double get _homeTowerMentorBaseBonus {
    if (!mentorshipUnlocked || homeTowerAffinity == null) {
      return 0;
    }
    final profile = socialBonusProfile;
    final direct = min(
      profile.activeDirectMentees,
      LightcoreSocialLimits.activeMenteeBonusLimit,
    );
    final grand = min(
      profile.activeGrandMentees,
      LightcoreSocialLimits.activeMenteeBonusLimit * 2,
    );
    if (direct <= 0 && grand <= 0) {
      return 0;
    }
    final buildFactor = (builtTowerCount / slotCount)
        .clamp(0.25, 1.0)
        .toDouble();
    return ((direct * 0.018) + (grand * 0.005)) * buildFactor;
  }

  double _homeTowerExperienceWeight(PrototypeAffinity affinity) =>
      switch (affinity) {
        PrototypeAffinity.neutral => 0.9,
        PrototypeAffinity.aether => 1.2,
        PrototypeAffinity.flare => 0.7,
        PrototypeAffinity.ember => 0.8,
        PrototypeAffinity.solar => 0.95,
        PrototypeAffinity.verdant => 1.05,
        PrototypeAffinity.violet => 1.15,
        PrototypeAffinity.black => 0.9,
      };

  double _homeTowerCombatWeight(PrototypeAffinity affinity) =>
      switch (affinity) {
        PrototypeAffinity.neutral => 0.9,
        PrototypeAffinity.aether => 0.95,
        PrototypeAffinity.flare => 1.12,
        PrototypeAffinity.ember => 1.2,
        PrototypeAffinity.solar => 0.82,
        PrototypeAffinity.verdant => 0.78,
        PrototypeAffinity.violet => 0.9,
        PrototypeAffinity.black => 1.0,
      };

  double _homeTowerRewardWeight(PrototypeAffinity affinity) =>
      switch (affinity) {
        PrototypeAffinity.neutral => 0.9,
        PrototypeAffinity.aether => 0.75,
        PrototypeAffinity.flare => 0.95,
        PrototypeAffinity.ember => 0.78,
        PrototypeAffinity.solar => 1.2,
        PrototypeAffinity.verdant => 1.12,
        PrototypeAffinity.violet => 1.05,
        PrototypeAffinity.black => 1.0,
      };

  void _applyTimeWarpProgress(LightcoreTimeWarpOfferDefinition offer) {
    final previousExperience = progressionExperience;
    final durationSeconds = max(0, offer.durationSeconds);
    final lumensGranted = max(
      0,
      (passiveLumenPerSecond * durationSeconds).floor(),
    );
    final killsGranted = max(
      0,
      ((offlineKillsPerHour * durationSeconds) / 3600).floor(),
    );
    final experienceGranted = _boostedExperienceReward(killsGranted);

    lumens += lumensGranted;
    kills += killsGranted;
    experience += experienceGranted;
    _totalTimeWarpSecondsClaimed += durationSeconds;
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );

    final unlockBanner = _towerUnlockBannerFragment(
      previousExperience,
      progressionExperience,
    );
    final bossUnlockBanner = _grantBossUnlockIfNeeded();
    final managerUnlockBanner = _managerUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final dailyDungeonUnlockBanner = _dailyDungeonUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final tournamentUnlockBanner = _tournamentUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final mentorshipUnlockBanner = _mentorshipUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final remaining = timeWarpPurchasesRemaining(offer.id);
    final rewardParts = <String>[
      if (lumensGranted > 0)
        LightcoreCurrencyLabels.rewardLumens(lumensGranted),
      if (killsGranted > 0) '+$killsGranted Kills',
      if (experienceGranted > 0) '+$experienceGranted EXP',
    ];
    _showBanner(
      [
        rewardParts.isEmpty
            ? '${offer.title} applied ${offer.durationLabel}. No idle production is online yet.'
            : '${offer.title}: ${offer.durationLabel} skipped for ${rewardParts.join(', ')}.',
        'Weekly remaining: $remaining/${offer.weeklyLimit}.',
        ...<String?>[
          levelUpBanner,
          unlockBanner,
          bossUnlockBanner,
          managerUnlockBanner,
          dailyDungeonUnlockBanner,
          tournamentUnlockBanner,
          mentorshipUnlockBanner,
        ].whereType<String>(),
      ].join(' '),
    );
    _syncTutorialStep(showBanner: false);
  }

  String _dayKey(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }

  String _currentDayKey() => _serverDayKey ?? _dayKey(DateTime.now());

  String _currentWeekKey() => _serverWeekKey ?? _weekKey(DateTime.now());

  String? _normalizeDateKey(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)
        ? normalized
        : null;
  }

  String _weekKey(DateTime time) {
    final startOfDay = DateTime(time.year, time.month, time.day);
    final weekStart = startOfDay.subtract(
      Duration(days: startOfDay.weekday - DateTime.monday),
    );
    return _dayKey(weekStart);
  }

  TowerLayerSnapshot _layerById(String id) {
    return _layers.firstWhere((layer) => layer.id == id);
  }

  TowerLayerSnapshot? _layerByIdOrNull(String id) {
    for (final layer in _layers) {
      if (layer.id == id) {
        return layer;
      }
    }
    return null;
  }

  bool _slotCountsTowardRing(OuterTowerState tower) =>
      (tower.config != null && !tower.isFabricating) ||
      tower.isPromotedChildTower;

  InventoryCard? _directTowerCoreManagerForLayer(TowerLayerSnapshot layer) {
    InventoryCard? legacyLayerManager;
    for (final card in _cards) {
      if (card.equippedLayerId != layer.id) {
        continue;
      }
      if (card.equippedSlotIndex == null) {
        return card;
      }
      legacyLayerManager ??= card;
    }
    return legacyLayerManager;
  }

  String? _towerCoreManagerOwnerLayerIdForLayer(TowerLayerSnapshot layer) =>
      _towerCoreManagerOwnerLayerIdForLayerId(layer.id, <String>{});

  String? _towerCoreManagerOwnerLayerIdForLayerId(
    String layerId,
    Set<String> visitedLayerIds,
  ) {
    if (!visitedLayerIds.add(layerId)) {
      return null;
    }
    final layer = _layerByIdOrNull(layerId);
    if (layer == null) {
      return null;
    }
    if (_directTowerCoreManagerForLayer(layer) != null) {
      return layer.id;
    }
    final inheritedLayerId = layer.promotedParentLayerId ?? layer.parentLayerId;
    if (inheritedLayerId == null) {
      return null;
    }
    return _towerCoreManagerOwnerLayerIdForLayerId(
      inheritedLayerId,
      visitedLayerIds,
    );
  }

  InventoryCard? _towerCoreManagerForLayer(TowerLayerSnapshot layer) {
    final ownerLayerId = _towerCoreManagerOwnerLayerIdForLayer(layer);
    if (ownerLayerId == null) {
      return null;
    }
    final ownerLayer = _layerByIdOrNull(ownerLayerId);
    return ownerLayer == null
        ? null
        : _directTowerCoreManagerForLayer(ownerLayer);
  }

  EnemyManagerState? _enemyCoreManagerForLayer(TowerLayerSnapshot layer) {
    EnemyManagerState? legacyLayerManager;
    for (final manager in _enemyManagers) {
      if (manager.assignedLayerId != layer.id) {
        continue;
      }
      if (manager.assignedEnemyCardId == null) {
        return manager;
      }
      legacyLayerManager ??= manager;
    }
    return legacyLayerManager;
  }

  LightcoreDailyDungeonTowerProfile dailyDungeonTowerProfileForLevel(
    int towerLevel,
  ) {
    final level = towerLevel
        .clamp(dailyDungeonStartingTowerLevel, dailyDungeonMaxTowerLevel)
        .toInt();
    const towerCycle = <TowerConfig>[
      TowerLibrary.whitePrism,
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.greenPrism,
      TowerLibrary.cyanPrism,
      TowerLibrary.purplePrism,
    ];
    final config = towerCycle[(level - 1) % towerCycle.length];
    final tier = 1 + ((level - 1) ~/ towerCycle.length);
    final displayLevel = 1 + ((level - 1) % maxTowerLevel);
    final maxHealth =
        760 +
        (level * 240) +
        (pow(level, 1.45).toDouble() * 95) +
        (max(0, level - 1) * 120) +
        (config.basePower * 10) +
        ((tier - 1) * 210);
    final shotDamage =
        (10 + (config.basePower * 1.15) + (level * 6.0) + ((tier - 1) * 7.5)) *
        (1 + ((displayLevel - 1) * 0.035));
    final chargeRate =
        (0.42 + (config.baseChargeRate * 0.28) + ((tier - 1) * 0.035))
            .clamp(0.52, 1.18)
            .toDouble();
    final cooldownSeconds = (config.baseCooldown + 0.32 - ((tier - 1) * 0.025))
        .clamp(0.72, 1.92)
        .toDouble();
    return LightcoreDailyDungeonTowerProfile(
      towerLevel: level,
      config: config,
      displayLevel: displayLevel,
      maxHealth: maxHealth,
      shotDamage: shotDamage,
      chargeRate: chargeRate,
      cooldownSeconds: cooldownSeconds,
    );
  }

  LightcoreDailyDungeonTowerProfile dailyDungeonBattleTowerProfileForLevel(
    int towerLevel,
  ) {
    final baseProfile = dailyDungeonTowerProfileForLevel(towerLevel);
    final sourceTower = _highestLayerDungeonTower();
    if (sourceTower == null) {
      return baseProfile;
    }
    final projectileType = towerProjectileType(sourceTower);
    final payloadType = towerPayloadType(sourceTower);
    final config =
        sourceTower.config ??
        _sourceTowerConfigForAffinity(projectileType.affinity);
    final displayLevel = sourceTower.config != null
        ? sourceTower.level
        : sourceTower.childCoreLevel ?? baseProfile.displayLevel;
    final layerLabel = sourceTower.childLayerName?.trim();
    final title = layerLabel != null && layerLabel.isNotEmpty
        ? layerLabel
        : towerDisplayName(sourceTower);
    return LightcoreDailyDungeonTowerProfile(
      towerLevel: baseProfile.towerLevel,
      config: config,
      displayLevel: baseProfile.displayLevel,
      maxHealth: baseProfile.maxHealth,
      shotDamage: baseProfile.shotDamage,
      chargeRate: baseProfile.chargeRate,
      cooldownSeconds: baseProfile.cooldownSeconds,
      battleTitle: title,
      battleAffinity:
          sourceTower.childAffinity ??
          sourceTower.config?.affinity ??
          projectileType.affinity,
      battleProjectileType: projectileType,
      battlePayloadType: payloadType,
      battleDisplayLevel: displayLevel.clamp(1, maxTowerLevel).toInt(),
    );
  }

  OuterTowerState? _highestLayerDungeonTower() {
    final candidates = <({TowerLayerSnapshot layer, OuterTowerState tower})>[];
    for (final layer in _layers) {
      for (final tower in layer.slots) {
        if (_slotCountsTowardRing(tower)) {
          candidates.add((layer: layer, tower: tower));
        }
      }
    }
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((left, right) {
      final tierCompare = right.layer.tier.compareTo(left.layer.tier);
      if (tierCompare != 0) {
        return tierCompare;
      }
      final levelCompare = _dungeonTowerRank(
        right.tower,
      ).compareTo(_dungeonTowerRank(left.tower));
      if (levelCompare != 0) {
        return levelCompare;
      }
      return left.tower.slotIndex.compareTo(right.tower.slotIndex);
    });
    return candidates.first.tower;
  }

  double _dungeonTowerRank(OuterTowerState tower) {
    final level = tower.config != null
        ? tower.level
        : tower.childCoreLevel ?? 1;
    final power = tower.config?.basePower ?? tower.childPowerUpgradeBonus + 10;
    final childBuilt = tower.childBuiltCount * 0.35;
    return level + power + childBuilt;
  }

  TowerConfig _sourceTowerConfigForAffinity(PrototypeAffinity affinity) {
    return TowerLibrary.all.firstWhere(
      (config) => config.affinity == affinity,
      orElse: () => TowerLibrary.whitePrism,
    );
  }

  bool _managerAssignmentUnlockedForLayer(TowerLayerSnapshot layer) =>
      _towerCoreManagerForLayer(layer) != null ||
      _managerCoreLevelUnlockedForLayer(layer) ||
      overallLevel >= managerUnlockLevel ||
      (layer.parentLayerId == null &&
          layer.tier == 1 &&
          _starterManagerTutorialUnlocked);

  bool _managerCoreLevelUnlockedForLayer(TowerLayerSnapshot layer) =>
      layer.core.level >= managerCoreLevelRequirement ||
      _layer1TowerLevelUnlockedForManagers(layer);

  bool _layer1TowerLevelUnlockedForManagers(TowerLayerSnapshot layer) {
    if (layer.parentLayerId != null || layer.tier != 1) {
      return false;
    }
    return layer.slots.any(
      (tower) =>
          _slotCountsTowardRing(tower) &&
          tower.level >= managerCoreLevelRequirement,
    );
  }

  int _managedTowerCountForLayer(TowerLayerSnapshot layer) => layer.slots
      .where((tower) => _slotHasAutomationManager(layer, tower))
      .length;

  bool isBattlePassRewardClaimed(
    BattlePassType type,
    int tierIndex,
    BattlePassTrack track,
  ) {
    final pass = battlePassFor(type);
    return isBattlePassRewardClaimedForPass(pass, tierIndex, track);
  }

  PrototypeAffinity? _dominantTowerAffinityForLayer(TowerLayerSnapshot layer) {
    final counts = _activeTowerAffinityCounts(layer.slots);
    if (counts.isEmpty) {
      return null;
    }

    PrototypeAffinity? dominant;
    var dominantCount = 0;
    for (final entry in counts.entries) {
      if (dominant == null || entry.value > dominantCount) {
        dominant = entry.key;
        dominantCount = entry.value;
      }
    }
    return dominant;
  }

  bool isBattlePassRewardClaimedForPass(
    BattlePassProgress pass,
    int tierIndex,
    BattlePassTrack track,
  ) {
    return pass.claimedRewardKeys.contains(
      _battlePassClaimKey(tierIndex, track),
    );
  }

  bool canClaimBattlePassReward(
    BattlePassType type,
    int tierIndex,
    BattlePassTrack track,
  ) {
    final pass = battlePassFor(type);
    return canClaimBattlePassRewardForPass(pass, tierIndex, track);
  }

  bool _slotReadyForPromotion(OuterTowerState tower) =>
      tower.hasTowerProgression && tower.level >= maxTowerLevel;

  UnmodifiableListView<FriendRelayPiece> get availableSharedRelayCorePieces =>
      UnmodifiableListView(_ownedSharedRelayCorePieces());

  UnmodifiableListView<FriendRelayPiece> get availableSharedRelayTowerPieces =>
      UnmodifiableListView(_ownedSharedRelayTowerPieces());

  List<EnemyCardState> get activeEnemyDeck => _activeEnemyCardIds
      .map(enemyCardById)
      .whereType<EnemyCardState>()
      .where((card) => card.isOwned)
      .toList();

  UnmodifiableListView<ThreatAssignmentPresetState>
  get activeThreatAssignmentPresets {
    _normalizeThreatAssignmentPresetSelection(activeLayer);
    return UnmodifiableListView(activeLayer.threatAssignmentPresets);
  }

  String? get selectedThreatAssignmentPresetId {
    _normalizeThreatAssignmentPresetSelection(activeLayer);
    return activeLayer.selectedThreatAssignmentPresetId;
  }

  ThreatAssignmentPresetState? get selectedThreatAssignmentPreset {
    _normalizeThreatAssignmentPresetSelection(activeLayer);
    final presetId = activeLayer.selectedThreatAssignmentPresetId;
    if (presetId == null) {
      return null;
    }
    for (final preset in activeLayer.threatAssignmentPresets) {
      if (preset.id == presetId) {
        return preset;
      }
    }
    return null;
  }
}
