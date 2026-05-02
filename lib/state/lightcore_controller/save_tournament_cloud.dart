part of '../lightcore_controller.dart';

extension LightcoreControllerSaveTournamentCloud on LightcoreController {
  void configureTournamentBattle({
    required LightcoreTournamentModeId mode,
    required int seedPowerIndex,
    Iterable<EnemyCardState> enemyDraft = const <EnemyCardState>[],
    EnemyCardState? bossDraft,
    int towerTier = 1,
    int enemyPressure = initialEnemyTarget,
  }) {
    final normalizedSeed = max(evenEntryTournamentPowerIndex, seedPowerIndex);
    final normalizedTowerTier = max(1, towerTier);
    final towerLevel = min(
      maxTowerLevel,
      max(1, 1 + (normalizedSeed ~/ 360) + normalizedTowerTier - 1),
    );
    final coreAffinity = switch (mode) {
      LightcoreTournamentModeId.enemyBlitz => PrototypeAffinity.ember,
      LightcoreTournamentModeId.hexGauntlet => PrototypeAffinity.solar,
      LightcoreTournamentModeId.arenaFlow => PrototypeAffinity.violet,
    };
    final coreProjectile = switch (mode) {
      LightcoreTournamentModeId.enemyBlitz => ProjectileType.coreBomb,
      LightcoreTournamentModeId.hexGauntlet => ProjectileType.chainArc,
      LightcoreTournamentModeId.arenaFlow => ProjectileType.pulseRing,
    };
    final towerLoadout = switch (mode) {
      LightcoreTournamentModeId.enemyBlitz => _enemyBlitzTowerLoadout(
        normalizedSeed,
      ),
      LightcoreTournamentModeId.hexGauntlet => <TowerConfig>[
        TowerLibrary.yellowPrism,
        TowerLibrary.greenPrism,
        TowerLibrary.cyanPrism,
        TowerLibrary.yellowPrism,
        TowerLibrary.greenPrism,
        TowerLibrary.whitePrism,
      ],
      LightcoreTournamentModeId.arenaFlow => <TowerConfig>[
        TowerLibrary.purplePrism,
        TowerLibrary.cyanPrism,
        TowerLibrary.greenPrism,
        TowerLibrary.purplePrism,
        TowerLibrary.yellowPrism,
        TowerLibrary.whitePrism,
      ],
    };

    _configureEventBattle(
      eventLabel: mode.label,
      seedPowerIndex: normalizedSeed,
      coreAffinity: coreAffinity,
      coreProjectile: coreProjectile,
      corePayload: PayloadType.none,
      coreLevel: evenEntryTournamentCoreLevel + normalizedTowerTier - 1,
      coreMultiShotUpgradeLevel: mode == LightcoreTournamentModeId.arenaFlow
          ? 1
          : 0,
      towerLoadout: towerLoadout,
      towerLevel: towerLevel,
      builtSlotCount: mode == LightcoreTournamentModeId.enemyBlitz
          ? 0
          : slotCount,
      enemyDraft: enemyDraft,
      bossDraft: bossDraft,
      enemyPressure: enemyPressure,
      layer2Unlocked: mode == LightcoreTournamentModeId.arenaFlow,
      layer2Count: mode == LightcoreTournamentModeId.arenaFlow ? 2 : 0,
      spawnBossImmediately: mode == LightcoreTournamentModeId.arenaFlow,
      installCoreManager: mode != LightcoreTournamentModeId.enemyBlitz,
    );
  }

  void configureArenaFlowBattleFromHomeTower({
    required LightcoreController source,
    required int seedPowerIndex,
    Iterable<EnemyCardState> enemyDraft = const <EnemyCardState>[],
    EnemyCardState? bossDraft,
    int enemyPressure = initialEnemyTarget,
  }) {
    configureTournamentBattle(
      mode: LightcoreTournamentModeId.arenaFlow,
      seedPowerIndex: seedPowerIndex,
      enemyDraft: enemyDraft,
      bossDraft: bossDraft,
      towerTier: source.homeTowerTier,
      enemyPressure: enemyPressure,
    );

    final homeLayer = source.homeTowerLayer;
    _removeEventCoreManagers();
    _core = homeLayer.core.copyWith(
      coreStability: 100,
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      packetCooldownRemaining: 0,
      automationCooldownRemaining: 0,
    );
    _layer2 = homeLayer.layer2.copyWith(fireCooldownRemaining: 0);
    for (var slotIndex = 0; slotIndex < slotCount; slotIndex += 1) {
      if (slotIndex >= homeLayer.slots.length ||
          !source._slotCountsTowardRing(homeLayer.slots[slotIndex])) {
        _slots[slotIndex] = OuterTowerState(slotIndex: slotIndex);
        continue;
      }
      final sourceSlot = homeLayer.slots[slotIndex];
      _slots[slotIndex] = sourceSlot
          .copyForSlot(slotIndex)
          .copyWith(
            charge: max(0.35, min(1.0, sourceSlot.charge)),
            cooldownRemaining: 0,
            automationCooldownRemaining: 0,
            disruption: 0,
            fabricationTotalSeconds: 0,
            fabricationRemainingSeconds: 0,
          );
    }

    final builtSlots = _slots.where(_slotCountsTowardRing).length;
    final unlockExperience = builtSlots <= 0
        ? 0
        : unlockExperienceForOuterSlot(builtSlots - 1);
    kills = unlockExperience;
    experience = unlockExperience;
    _towerRangePreviewSlotIndex = _slots.indexWhere(_slotCountsTowardRing);
    if (_towerRangePreviewSlotIndex == -1) {
      _towerRangePreviewSlotIndex = null;
    }
    _storeActiveLayer();
    _notifyNow();
  }

  void applyEnemyBlitzTowerUpgrade({
    required int seedPowerIndex,
    required int towerTier,
  }) {
    final normalizedSeed = max(evenEntryTournamentPowerIndex, seedPowerIndex);
    final normalizedTier = max(1, towerTier);
    final builtSlots = _enemyBlitzBuiltTowerCountForTier(normalizedTier);
    final towerLevel = _enemyBlitzTowerLevelForTier(normalizedTier);
    final loadout = _enemyBlitzTowerLoadout(normalizedSeed);
    if (builtSlots > 0) {
      final unlockExperience = unlockExperienceForOuterSlot(builtSlots - 1);
      kills = max(kills, unlockExperience);
      experience = max(experience, unlockExperience);
    }
    _core = _core.copyWith(
      level: (1 + ((normalizedTier - 1) ~/ 2))
          .clamp(1, maxCoreUpgradeLevel)
          .toInt(),
      rangeUpgradeLevel: (1 + (normalizedTier ~/ 2))
          .clamp(0, maxCoreUpgradeLevel)
          .toInt(),
      fireSpeedUpgradeLevel: (1 + (normalizedTier ~/ 3))
          .clamp(0, maxCoreUpgradeLevel)
          .toInt(),
      queueLimitUpgradeLevel: (1 + (normalizedTier ~/ 4))
          .clamp(0, maxCoreUpgradeLevel)
          .toInt(),
    );
    for (var slotIndex = 0; slotIndex < slotCount; slotIndex += 1) {
      if (slotIndex >= builtSlots) {
        if (!_slotCountsTowardRing(_slots[slotIndex])) {
          _slots[slotIndex] = OuterTowerState(slotIndex: slotIndex);
        }
        continue;
      }
      final config = loadout[slotIndex % loadout.length];
      final existing = _slots[slotIndex];
      if (_slotCountsTowardRing(existing) && existing.config?.id == config.id) {
        _slots[slotIndex] = existing.copyWith(
          level: max(existing.level, towerLevel),
          fabricationTotalSeconds: 0,
          fabricationRemainingSeconds: 0,
        );
      } else {
        _slots[slotIndex] =
            _buildRolledTowerState(
              slotIndex: slotIndex,
              config: config,
              investedLumens: config.buildCost,
            ).copyWith(
              level: towerLevel,
              charge: 0.45,
              cooldownRemaining: 0,
              automationCooldownRemaining: 0,
              fabricationTotalSeconds: 0,
              fabricationRemainingSeconds: 0,
            );
      }
    }
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = builtSlots > 0 ? builtSlots - 1 : null;
    _storeActiveLayer();
    _notifyNow();
  }

  void applyTournamentEnemyRuntime({
    required Iterable<EnemyCardState> enemyDraft,
    required int enemyPressure,
    int enemyLevelBonus = 0,
  }) {
    final draft = enemyDraft.toList(growable: false);
    final activeDraft = draft.isEmpty
        ? <EnemyCardState>[
            EnemyCardState(
              config: EnemyLibrary.basicWhite,
              unlocked: true,
              copies: 1,
              level: 1,
            ),
          ]
        : draft.take(enemyDeckLimit).toList(growable: false);
    _activeEnemyCardIds = <String>[];
    for (final card in activeDraft) {
      final levelCap = card.config.rarity.levelCap;
      final boosted = card.copyWith(
        unlocked: true,
        copies: max(1, card.copies),
        level: (card.level + enemyLevelBonus).clamp(1, levelCap).toInt(),
      );
      _forceTournamentEnemyCard(boosted);
      _activeEnemyCardIds.add(boosted.config.id);
    }
    selectedEnemyCardId = _activeEnemyCardIds.first;
    _enemyTargetUpgradeLevel = max(
      _enemyTargetUpgradeLevel,
      max(
        0,
        min(maxEnemyTargetUpgradeLevel, enemyPressure - baseEnemyTargetMax),
      ),
    );
    _enemyTargetCount = _normalizeEnemyTargetCount(enemyPressure);
    _storeActiveLayer();
    _notifyNow();
  }

  void configureThreatDirectorDungeonBattle({
    required int towerLevel,
    Iterable<EnemyCardState> enemyDraft = const <EnemyCardState>[],
    EnemyCardState? bossDraft,
  }) {
    final profile = dailyDungeonTowerProfileForLevel(towerLevel);
    final builtSlots = (profile.towerLevel - 1).clamp(0, slotCount).toInt();
    final pressure =
        (initialEnemyTarget +
                min(18, profile.towerLevel ~/ 2) +
                min(8, enemyDraft.length * 2) +
                (bossDraft == null ? 0 : 4))
            .toInt();
    _configureEventBattle(
      eventLabel: 'Threat Director',
      seedPowerIndex:
          evenEntryTournamentPowerIndex + (profile.towerLevel * 290),
      coreAffinity: profile.affinity,
      coreProjectile: profile.projectileType,
      corePayload: profile.payloadType,
      coreLevel: 1 + ((profile.towerLevel - 1) ~/ 8),
      towerLoadout: _dailyDungeonTowerLoadout(profile.towerLevel),
      towerLevel: profile.effectiveDisplayLevel,
      builtSlotCount: builtSlots,
      enemyDraft: enemyDraft,
      bossDraft: bossDraft,
      enemyPressure: pressure,
      spawnBossImmediately: false,
      spawnPolicy: LightcoreBattleSpawnPolicy.manual,
    );
  }

  void configurePrismRiftDungeonBattle({
    required int towerLevel,
    Iterable<EnemyCardState> enemyDraft = const <EnemyCardState>[],
  }) {
    final profile = dailyDungeonTowerProfileForLevel(towerLevel);
    final builtSlots = min(slotCount, 2 + ((profile.towerLevel - 1) ~/ 2));
    _configureEventBattle(
      eventLabel: 'Prism Rift',
      seedPowerIndex:
          evenEntryTournamentPowerIndex + (profile.towerLevel * 340),
      coreAffinity: PrototypeAffinity.violet,
      coreProjectile: ProjectileType.prismBeam,
      corePayload: PayloadType.fracture,
      coreLevel: 1 + ((profile.towerLevel - 1) ~/ 6),
      coreMultiShotUpgradeLevel: profile.towerLevel >= 10 ? 1 : 0,
      towerLoadout: _dailyDungeonTowerLoadout(
        profile.towerLevel,
        prismRift: true,
      ),
      towerLevel: profile.effectiveDisplayLevel,
      builtSlotCount: builtSlots,
      enemyDraft: enemyDraft,
      enemyPressure:
          initialEnemyTarget + min(20, 3 + (profile.towerLevel ~/ 2)),
      layer2Unlocked: profile.towerLevel >= 7,
      layer2Count: profile.towerLevel >= 14 ? 2 : 1,
      installCoreManager: false,
    );
  }

  void configurePrismRiftDungeonBattleFromHomeTower({
    required LightcoreController source,
    required int towerLevel,
    Iterable<EnemyCardState> enemyDraft = const <EnemyCardState>[],
  }) {
    configurePrismRiftDungeonBattle(
      towerLevel: towerLevel,
      enemyDraft: enemyDraft,
    );

    final homeLayer = source.homeTowerLayer;
    final eventLayer = activeLayer;
    eventLayer.tier = homeLayer.tier;
    eventLayer.label = homeLayer.label;
    eventLayer.promotionTraitRoll = homeLayer.promotionTraitRoll;

    _core = homeLayer.core.copyWith(
      coreStability: 100,
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      packetCooldownRemaining: 0,
      automationCooldownRemaining: 0,
    );
    _layer2 = homeLayer.layer2.copyWith(fireCooldownRemaining: 0);
    for (var slotIndex = 0; slotIndex < slotCount; slotIndex += 1) {
      if (slotIndex >= homeLayer.slots.length ||
          !source._slotCountsTowardRing(homeLayer.slots[slotIndex])) {
        _slots[slotIndex] = OuterTowerState(slotIndex: slotIndex);
        continue;
      }
      final sourceSlot = homeLayer.slots[slotIndex];
      _slots[slotIndex] = sourceSlot
          .copyForSlot(slotIndex)
          .copyWith(
            charge: max(0.45, min(1.0, sourceSlot.charge)),
            cooldownRemaining: 0,
            automationCooldownRemaining: 0,
            disruption: 0,
            fabricationTotalSeconds: 0,
            fabricationRemainingSeconds: 0,
          );
    }

    final builtSlots = _slots.where(_slotCountsTowardRing).length;
    final unlockExperience = builtSlots <= 0
        ? 0
        : unlockExperienceForOuterSlot(builtSlots - 1);
    kills = unlockExperience;
    experience = unlockExperience;
    _towerRangePreviewSlotIndex = _slots.indexWhere(_slotCountsTowardRing);
    if (_towerRangePreviewSlotIndex == -1) {
      _towerRangePreviewSlotIndex = null;
    }
    _storeActiveLayer();
    _notifyNow();
  }

  void _configureEventBattle({
    required String eventLabel,
    required int seedPowerIndex,
    required PrototypeAffinity coreAffinity,
    required ProjectileType coreProjectile,
    required PayloadType corePayload,
    required int coreLevel,
    required List<TowerConfig> towerLoadout,
    required int towerLevel,
    required int builtSlotCount,
    Iterable<EnemyCardState> enemyDraft = const <EnemyCardState>[],
    EnemyCardState? bossDraft,
    int enemyPressure = initialEnemyTarget,
    bool layer2Unlocked = false,
    int layer2Count = 0,
    int coreMultiShotUpgradeLevel = 0,
    bool spawnBossImmediately = false,
    bool installCoreManager = true,
    LightcoreBattleSpawnPolicy spawnPolicy =
        LightcoreBattleSpawnPolicy.automatic,
  }) {
    final normalizedSeed = max(evenEntryTournamentPowerIndex, seedPowerIndex);
    final normalizedBuiltSlots = builtSlotCount.clamp(0, slotCount).toInt();
    final normalizedTowerLevel = towerLevel.clamp(1, maxTowerLevel).toInt();
    final unlockExperience = normalizedBuiltSlots <= 0
        ? 0
        : unlockExperienceForOuterSlot(normalizedBuiltSlots - 1);
    kills = unlockExperience;
    experience = unlockExperience;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _battleSpawnPolicy = spawnPolicy;
    _tutorialStep = LightcoreTutorialStep.none;
    _tutorialPromptsEnabled = false;
    bannerMessage = '';
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;
    _removeEventCoreManagers();
    if (installCoreManager) {
      _installEventCoreManager(
        eventLabel: eventLabel,
        affinity: coreAffinity,
        projectileType: coreProjectile,
        payloadType: corePayload,
      );
    }

    _core = _core.copyWith(
      coreStability: 100,
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      packetCooldownRemaining: 0,
      automationCooldownRemaining: 0,
      level: coreLevel.clamp(1, maxCoreUpgradeLevel).toInt(),
      affinity: coreAffinity,
      secondaryAffinity: corePayload.affinity,
      projectileType: coreProjectile,
      payloadType: corePayload,
      projectileLoadout: <ProjectileType>[coreProjectile],
      payloadLoadout: <PayloadType>[corePayload],
      rangeUpgradeLevel: min(maxCoreUpgradeLevel, 1 + (normalizedSeed ~/ 520)),
      fireSpeedUpgradeLevel: min(
        maxCoreUpgradeLevel,
        1 + (normalizedSeed ~/ 640),
      ),
      queueLimitUpgradeLevel: min(
        maxCoreUpgradeLevel,
        1 + (normalizedSeed ~/ 720),
      ),
      multiShotUpgradeLevel: coreMultiShotUpgradeLevel
          .clamp(0, maxCoreMultiShotUpgradeLevel)
          .toInt(),
    );
    _layer2 = Layer2TowerState(
      unlocked: layer2Unlocked,
      count: layer2Unlocked ? max(1, layer2Count) : 0,
      fireCooldownRemaining: 0,
      projectileType: coreProjectile,
      payloadType: corePayload,
      affinity: coreAffinity,
      sourceSummary: '$eventLabel event relay',
    );

    for (var slotIndex = 0; slotIndex < slotCount; slotIndex += 1) {
      if (slotIndex >= normalizedBuiltSlots || towerLoadout.isEmpty) {
        _slots[slotIndex] = OuterTowerState(slotIndex: slotIndex);
        continue;
      }
      final config = towerLoadout[slotIndex % towerLoadout.length];
      _slots[slotIndex] =
          _buildRolledTowerState(
            slotIndex: slotIndex,
            config: config,
            investedLumens: config.buildCost,
          ).copyWith(
            level: normalizedTowerLevel,
            charge: 1,
            cooldownRemaining: 0,
            automationCooldownRemaining: 0,
            fabricationTotalSeconds: 0,
            fabricationRemainingSeconds: 0,
          );
    }

    final draft = enemyDraft.toList(growable: false);
    final activeDraft = draft.isEmpty
        ? <EnemyCardState>[
            EnemyCardState(
              config: EnemyLibrary.basicWhite,
              unlocked: true,
              copies: 1,
              level: 1,
            ),
          ]
        : draft.take(enemyDeckLimit).toList(growable: false);
    _activeEnemyCardIds = <String>[];
    for (final card in activeDraft) {
      _forceTournamentEnemyCard(card);
      _activeEnemyCardIds.add(card.config.id);
    }
    selectedEnemyCardId = _activeEnemyCardIds.first;

    if (bossDraft == null) {
      _activeBossEnemyCardId = null;
      activeLayer.activeBossEnemyCardId = null;
      activeLayer.bossReady = false;
      activeLayer.normalKillsSinceBoss = 0;
    } else {
      _forceTournamentBossCard(bossDraft);
      _activeBossEnemyCardId = bossDraft.config.id;
      activeLayer.activeBossEnemyCardId = bossDraft.config.id;
      activeLayer.bossReady = spawnBossImmediately;
      activeLayer.normalKillsSinceBoss = spawnBossImmediately
          ? bossSpawnKillRequirement
          : 0;
    }

    _enemyTargetUpgradeLevel = max(
      _enemyTargetUpgradeLevel,
      max(
        0,
        min(maxEnemyTargetUpgradeLevel, enemyPressure - baseEnemyTargetMax),
      ),
    );
    _enemyTargetCount = _normalizeEnemyTargetCount(enemyPressure);
    _enemies = <EnemyState>[];
    _pulses = <EnergyPulseState>[];
    _shots = <CoreShotState>[];
    _impacts = <ImpactState>[];
    _ammoQueue = <AmmoPacket>[];
    _spawnTimer = 0.05;
    elapsed = 0;
    _activeSpawnClusterIndex = null;
    _blueFocusTargetEnemyIdBySlot.clear();
    _resetManualOverdrive();
    _updateFlowEfficiency();
    _storeActiveLayer();
    _notifyNow();
  }

  void _installEventCoreManager({
    required String eventLabel,
    required PrototypeAffinity affinity,
    required ProjectileType projectileType,
    required PayloadType payloadType,
  }) {
    _removeEventCoreManagers();
    final template = CardLibrary.templates.first;
    _cards.add(
      InventoryCard(
        instanceId:
            'event_core_manager_${eventLabel.toLowerCase().replaceAll(' ', '_')}',
        config: template,
        rarity: ManagerRarity.legendary,
        forgeCost: 0,
        powerMultiplier: 1.18,
        chargeMultiplier: 1.22,
        cooldownMultiplier: 0.84,
        advantageMultiplier: 1.10,
        automationRate: 2.8,
        primaryTraitLabel: '$eventLabel automation',
        secondaryTraitLabel: 'Predetermined tower pilot',
        favoredAffinity: affinity,
        projectileFocus: projectileType,
        payloadFocus: payloadType == PayloadType.none ? null : payloadType,
        equippedLayerId: activeLayer.id,
      ),
    );
  }

  void _removeEventCoreManagers() {
    _cards = _cards
        .where((card) => !card.instanceId.startsWith('event_core_manager_'))
        .toList(growable: true);
  }

  int _enemyBlitzBuiltTowerCountForTier(int towerTier) =>
      max(0, min(2, towerTier - 1));

  int _enemyBlitzTowerLevelForTier(int towerTier) =>
      (1 + max(0, towerTier - 3)).clamp(1, maxTowerLevel).toInt();

  List<TowerConfig> _enemyBlitzTowerLoadout(int seedPowerIndex) {
    const pool = <TowerConfig>[
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.greenPrism,
      TowerLibrary.cyanPrism,
      TowerLibrary.purplePrism,
      TowerLibrary.whitePrism,
    ];
    final offset = ((seedPowerIndex ~/ 97) % pool.length).toInt();
    return <TowerConfig>[pool[offset], pool[(offset + 3) % pool.length]];
  }

  List<TowerConfig> _dailyDungeonTowerLoadout(
    int towerLevel, {
    bool prismRift = false,
  }) {
    const threatDirectorLoadout = <TowerConfig>[
      TowerLibrary.whitePrism,
      TowerLibrary.redPrism,
      TowerLibrary.orangePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.greenPrism,
      TowerLibrary.cyanPrism,
      TowerLibrary.purplePrism,
    ];
    const prismRiftLoadout = <TowerConfig>[
      TowerLibrary.purplePrism,
      TowerLibrary.cyanPrism,
      TowerLibrary.whitePrism,
      TowerLibrary.yellowPrism,
      TowerLibrary.greenPrism,
      TowerLibrary.redPrism,
    ];
    final source = prismRift ? prismRiftLoadout : threatDirectorLoadout;
    final offset = max(0, towerLevel - 1) % source.length;
    return <TowerConfig>[
      for (var index = 0; index < slotCount; index += 1)
        source[(offset + index) % source.length],
    ];
  }

  Map<String, dynamic> buildCloudSavePayload() {
    _storeActiveLayer();
    _refreshTimeWarpPurchaseWeek();
    _refreshStoreOfferPurchaseWeek();
    _syncProfileMedalAchievements(showBanner: false);

    return <String, dynamic>{
      'schemaVersion': lightcoreCloudSaveSchemaVersion,
      'savedAtMillis': DateTime.now().millisecondsSinceEpoch,
      'settings': <String, dynamic>{
        'notificationBannersEnabled': _notificationBannersEnabled,
        'battleNotificationBannersEnabled': _battleNotificationBannersEnabled,
        'tutorialPromptsEnabled': _tutorialPromptsEnabled,
      },
      'player': <String, dynamic>{
        'playerId': _playerId,
        'screenName': _screenName,
        'guideId': _guideProfile.storageId,
        'hasPermanentOverdrive': _hasPermanentOverdrive,
        'hasPremiumMembership': _hasPremiumMembership,
        'bossUnlockGrantClaimed': _bossUnlockGrantClaimed,
        'avatarCosmetics': <String, dynamic>{
          'unlockedIds': _unlockedAvatarCosmeticIds.toList(growable: false),
          'equippedHairId': _equippedHairCosmeticId,
          'equippedFaceId': _equippedFaceCosmeticId,
        },
        'publicAvatar': publicAvatarProfile.toMap(),
        'equippedProfileMedalId': _equippedProfileMedalId,
        'unlockedProfileMedalIds': _unlockedProfileMedalIds.toList(
          growable: false,
        ),
        'radianceStats': _serializeRadianceStats(),
        'sharedRelayCenterPieceId': _sharedRelayCenterPieceId,
        'sharedRelayOuterPieceIds': List<String?>.from(
          _sharedRelayOuterPieceIds,
        ),
      },
      'resources': <String, dynamic>{
        'lumens': lumens,
        'flux': flux,
        'prismShards': prismShards,
        'managerShards': managerShards,
        'managerPowerLevel': managerPowerLevel,
        'shellCores': shellCores,
        'enemyTickets': enemyTickets,
        'bossTickets': bossTickets,
        'bossCores': bossCores,
        'enemyPullCount': enemyPullCount,
        'bossPullCount': bossPullCount,
        'towerManagerPullCount': towerManagerPullCount,
        'enemyManagerPullCount': enemyManagerPullCount,
        'kills': kills,
        'experience': experience,
        'echoSeeds': echoSeeds,
        'totalHelpSectionsRead': totalHelpSectionsRead,
        'lumenHarvestSlowdown': _lumenHarvestSlowdown,
        'enemyTicketBuffer': _enemyTicketBuffer,
        'equipmentDropCounter': _equipmentDropCounter,
      },
      'metrics': <String, dynamic>{
        'totalBattleSeconds': _totalBattleSeconds,
        'totalOfflineSecondsClaimed': _totalOfflineSecondsClaimed,
        'totalUpgradesBought': _totalUpgradesBought,
        'totalTowersBuilt': _totalTowersBuilt,
        'totalManagersForged': _totalManagersForged,
        'totalBossesDefeated': _totalBossesDefeated,
        'totalLumensSpent': _totalLumensSpent,
        'totalFluxSpent': _totalFluxSpent,
        'totalPrismShardsSpent': _totalPrismShardsSpent,
        'totalTimeWarpSecondsClaimed': _totalTimeWarpSecondsClaimed,
        'balanceEpoch': _balanceTuning.balanceEpoch,
      },
      'store': <String, dynamic>{
        'timeWarpWeekKey': _timeWarpPurchaseWeekKey,
        'timeWarpWeeklyPurchases': Map<String, int>.from(
          _timeWarpWeeklyPurchases,
        ),
        'storeOfferWeekKey': _storeOfferPurchaseWeekKey,
        'storeOfferWeeklyPurchases': Map<String, int>.from(
          _storeOfferWeeklyPurchases,
        ),
      },
      'dailyDungeons': <String, dynamic>{
        'highestUnlockedTowerLevel': _dailyDungeonHighestUnlockedTowerLevel,
        'highestClearedTowerLevel': _dailyDungeonHighestClearedTowerLevel,
        'quickClearDayKey': _dailyDungeonQuickClearDayKey,
        'quickClearsUsed': _dailyDungeonQuickClearsUsed,
      },
      'socialSnapshot': _buildSocialPerformanceSnapshot(),
      'readHelpSections': _readHelpSections.toList(growable: false),
      'battlePasses': _battlePasses.values
          .expand((passes) => passes)
          .map(
            (pass) => <String, dynamic>{
              'type': pass.type.name,
              'seasonKey': pass.seasonKey,
              'generation': pass.generation,
              'progress': pass.progress,
              'premiumUnlocked': pass.premiumUnlocked,
              'claimedRewardKeys': pass.claimedRewardKeys.toList(
                growable: false,
              ),
              'snapshotManagerRarity': pass.snapshotManagerRarity?.name,
              'snapshotEnemyCardRarity': pass.snapshotEnemyCardRarity?.name,
            },
          )
          .toList(growable: false),
      'inventory': <String, dynamic>{
        'cards': _cards.map(_serializeInventoryCard).toList(growable: false),
        'enemyManagers': _enemyManagers
            .map(_serializeEnemyManager)
            .toList(growable: false),
        'enemyCards': _enemyCards
            .map(_serializeEnemyCardState)
            .toList(growable: false),
        'bossEnemyCards': _bossEnemyCards
            .map(_serializeEnemyCardState)
            .toList(growable: false),
        'equipmentInventory': _equipmentInventory
            .map(_serializePlayerEquipmentItem)
            .toList(growable: false),
        'equippedPlayerItems': <String, dynamic>{
          for (final entry in _equippedPlayerItems.entries)
            entry.key.name: entry.value,
        },
      },
      'layers': <String, dynamic>{
        'activeLayerId': _activeLayerId,
        'viewLayerId': _viewLayerId,
        'runtimeLayerId': _runtimeLayerId,
        'items': _layers.map(_serializeLayerSnapshot).toList(growable: false),
      },
      'completedTowerShells': _completedTowerShells
          .map(_serializeCompletedTowerShellState)
          .toList(growable: false),
      'guild': _serializeGuildState(_activeGuild),
      'tutorial': <String, dynamic>{
        'earlyQuestChainCompleted': _tutorialEarlyQuestChainCompleted,
        'firstBossDefeated': _tutorialFirstBossDefeated,
        'firstEquipmentOpened': _tutorialFirstEquipmentOpened,
        'firstManagersOpened': _tutorialFirstManagersOpened,
        'firstEnemyTargetSet': _tutorialFirstEnemyTargetSet,
        'enemyCountAdjusted': _tutorialEnemyCountAdjusted,
        'firstTowerStatsOpened': _tutorialFirstTowerStatsOpened,
        'stabilityPanelOpened': _tutorialStabilityPanelOpened,
        'towerMatrixOpened': _tutorialTowerMatrixOpened,
        'storeOpened': _tutorialStoreOpened,
        'battlePassRewardClaimed': _tutorialBattlePassRewardClaimed,
        'towerManagerAssigned': _tutorialTowerManagerAssigned,
        'enemyManagerAssigned': _tutorialEnemyManagerAssigned,
        'friendsOpened': _tutorialFriendsOpened,
        'menteesOpened': _tutorialMenteesOpened,
        'mentorsOpened': _tutorialMentorsOpened,
        'coreShotTapLearned': _tutorialCoreShotTapLearned,
        'secondShellShotTapLearned': _tutorialSecondShellShotTapLearned,
        'overdriveLearned': _tutorialOverdriveLearned,
        'introBossPending': _tutorialIntroBossPending,
        'safeScanDefeats': _tutorialSafeScanDefeats,
        'autoQueuedPulses': _tutorialAutoQueuedPulses,
        'trackedBossEnemyId': _tutorialTrackedBossEnemyId,
        'reviewedTournamentModes': _reviewedTournamentTutorialModes
            .map((mode) => mode.name)
            .toList(growable: false),
        'rewardedSteps': _rewardedTutorialSteps
            .map((step) => step.name)
            .toList(growable: false),
      },
    };
  }
}
