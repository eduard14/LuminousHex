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
      LightcoreTournamentModeId.enemyBlitz => <TowerConfig>[
        TowerLibrary.redPrism,
        TowerLibrary.orangePrism,
        TowerLibrary.yellowPrism,
        TowerLibrary.redPrism,
        TowerLibrary.orangePrism,
        TowerLibrary.purplePrism,
      ],
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

    final unlockExperience = unlockExperienceForOuterSlot(slotCount - 1);
    kills = max(kills, unlockExperience);
    experience = max(experience, unlockExperience);
    _outerRingRevealed = true;
    _swarmActivated = true;
    _tutorialStep = LightcoreTutorialStep.none;
    _tutorialPromptsEnabled = false;
    bannerMessage = '';
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;

    _core = _core.copyWith(
      coreStability: 100,
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      level: evenEntryTournamentCoreLevel + normalizedTowerTier - 1,
      affinity: coreAffinity,
      secondaryAffinity: null,
      projectileType: coreProjectile,
      payloadType: PayloadType.none,
      projectileLoadout: <ProjectileType>[coreProjectile],
      payloadLoadout: const <PayloadType>[PayloadType.none],
      rangeUpgradeLevel: min(maxCoreUpgradeLevel, 1 + (normalizedSeed ~/ 520)),
      fireSpeedUpgradeLevel: min(
        maxCoreUpgradeLevel,
        1 + (normalizedSeed ~/ 640),
      ),
      queueLimitUpgradeLevel: min(
        maxCoreUpgradeLevel,
        1 + (normalizedSeed ~/ 720),
      ),
      multiShotUpgradeLevel: mode == LightcoreTournamentModeId.arenaFlow
          ? 1
          : 0,
    );
    _layer2 = Layer2TowerState(
      unlocked: mode == LightcoreTournamentModeId.arenaFlow,
      count: mode == LightcoreTournamentModeId.arenaFlow ? 2 : 0,
      fireCooldownRemaining: 0,
      projectileType: coreProjectile,
      payloadType: PayloadType.none,
      affinity: coreAffinity,
      sourceSummary: '${mode.label} event relay',
    );

    for (var slotIndex = 0; slotIndex < slotCount; slotIndex += 1) {
      final config = towerLoadout[slotIndex % towerLoadout.length];
      _slots[slotIndex] =
          _buildRolledTowerState(
            slotIndex: slotIndex,
            config: config,
            investedLumens: config.buildCost,
          ).copyWith(
            level: towerLevel,
            charge: 1,
            cooldownRemaining: 0,
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
      activeLayer.bossReady = mode == LightcoreTournamentModeId.arenaFlow;
      activeLayer.normalKillsSinceBoss =
          mode == LightcoreTournamentModeId.arenaFlow
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
        'tutorialPromptsEnabled': _tutorialPromptsEnabled,
      },
      'player': <String, dynamic>{
        'playerId': _playerId,
        'screenName': _screenName,
        'guideId': _guideProfile.storageId,
        'hasPermanentOverdrive': _hasPermanentOverdrive,
        'hasPremiumMembership': _hasPremiumMembership,
        'bossUnlockGrantClaimed': _bossUnlockGrantClaimed,
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
      'guild': _serializeGuildState(_activeGuild),
      'tutorial': <String, dynamic>{
        'earlyQuestChainCompleted': _tutorialEarlyQuestChainCompleted,
        'firstBossDefeated': _tutorialFirstBossDefeated,
        'firstEquipmentOpened': _tutorialFirstEquipmentOpened,
        'firstManagersOpened': _tutorialFirstManagersOpened,
        'firstEnemyTargetSet': _tutorialFirstEnemyTargetSet,
        'enemyCountAdjusted': _tutorialEnemyCountAdjusted,
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
