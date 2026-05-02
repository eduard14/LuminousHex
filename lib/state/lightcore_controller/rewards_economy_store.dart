part of '../lightcore_controller.dart';

extension LightcoreControllerEconomyStore on LightcoreController {
  bool hasReadHelpSection(String id) => _readHelpSections.contains(id);

  bool markHelpSectionRead(String id) {
    if (_readHelpSections.contains(id)) {
      return false;
    }
    _readHelpSections.add(id);
    totalHelpSectionsRead += 1;
    enemyTickets += helpSectionTicketReward;
    _showBanner(
      'Field briefing complete: ${LightcoreCurrencyLabels.rewardThreatScans(helpSectionTicketReward)}.',
    );
    _notifyNow();
    return true;
  }

  void grantRewardedResources({
    int lumensGranted = 0,
    int fluxGranted = 0,
    int enemyTicketsGranted = 0,
    int bossTicketsGranted = 0,
    int killsGranted = 0,
    int experienceGranted = 0,
    required String sourceLabel,
  }) {
    final grantedLumens = max(0, lumensGranted);
    final grantedFlux = max(0, fluxGranted);
    final grantedTickets = max(0, enemyTicketsGranted);
    final grantedBossTickets = max(0, bossTicketsGranted);
    final grantedKills = max(0, killsGranted);
    final grantedExperience = _boostedExperienceReward(
      max(0, experienceGranted > 0 ? experienceGranted : grantedKills),
    );
    if (grantedLumens == 0 &&
        grantedFlux == 0 &&
        grantedTickets == 0 &&
        grantedBossTickets == 0 &&
        grantedKills == 0 &&
        grantedExperience == 0) {
      return;
    }

    final previousExperience = progressionExperience;
    lumens += grantedLumens;
    flux += grantedFlux;
    enemyTickets += grantedTickets;
    bossTickets += grantedBossTickets;
    kills += grantedKills;
    experience += grantedExperience;
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );

    final rewardParts = <String>[];
    if (grantedLumens > 0) {
      rewardParts.add(LightcoreCurrencyLabels.rewardLumens(grantedLumens));
    }
    if (grantedFlux > 0) {
      rewardParts.add(LightcoreCurrencyLabels.rewardFlux(grantedFlux));
    }
    if (grantedTickets > 0) {
      rewardParts.add(
        LightcoreCurrencyLabels.rewardThreatScans(grantedTickets),
      );
    }
    if (grantedBossTickets > 0) {
      rewardParts.add(
        LightcoreCurrencyLabels.rewardBossScans(grantedBossTickets),
      );
    }
    if (grantedExperience > 0) {
      rewardParts.add('+$grantedExperience EXP');
    }
    if (grantedKills > 0 && grantedKills != grantedExperience) {
      rewardParts.add('+$grantedKills Kills');
    }

    final unlockBanner = _towerUnlockBannerFragment(
      previousExperience,
      progressionExperience,
    );
    final tournamentUnlockBanner = _tournamentUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final managerUnlockBanner = _managerUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final dailyDungeonUnlockBanner = _dailyDungeonUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final mentorshipUnlockBanner = _mentorshipUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    _showBanner(
      [
        '$sourceLabel: ${rewardParts.join(', ')}.',
        ...<String?>[
          levelUpBanner,
          unlockBanner,
          managerUnlockBanner,
          dailyDungeonUnlockBanner,
          tournamentUnlockBanner,
          mentorshipUnlockBanner,
        ].whereType<String>(),
      ].join(' '),
    );
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void advanceEventOfflineProgress(double durationSeconds) {
    if (durationSeconds <= 0) {
      return;
    }

    final previousExperience = progressionExperience;
    final claimedSeconds = durationSeconds.floor();
    if (claimedSeconds > 0) {
      _totalOfflineSecondsClaimed += claimedSeconds;
    }
    _eventOfflineLumenBuffer += passiveLumenPerSecond * durationSeconds;
    _eventOfflineKillBuffer += (offlineKillsPerHour * durationSeconds) / 3600;
    final grantedLumens = _eventOfflineLumenBuffer.floor();
    final grantedKills = _eventOfflineKillBuffer.floor();
    if (grantedLumens <= 0 && grantedKills <= 0) {
      if (claimedSeconds > 0) {
        _notifyNow();
      }
      return;
    }

    _eventOfflineLumenBuffer -= grantedLumens;
    _eventOfflineKillBuffer -= grantedKills;
    lumens += grantedLumens;
    kills += grantedKills;
    experience += _boostedExperienceReward(grantedKills);
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );

    final unlockBanner = _towerUnlockBannerFragment(
      previousExperience,
      progressionExperience,
    );
    final tournamentUnlockBanner = _tournamentUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final mentorshipUnlockBanner = _mentorshipUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    if (levelUpBanner != null ||
        unlockBanner != null ||
        tournamentUnlockBanner != null ||
        mentorshipUnlockBanner != null) {
      _showBanner(
        <String?>[
          levelUpBanner,
          unlockBanner,
          tournamentUnlockBanner,
          mentorshipUnlockBanner,
        ].whereType<String>().join(' '),
      );
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  bool isDailyDungeonTowerLevelUnlocked(int towerLevel) {
    return dailyDungeonsUnlocked &&
        towerLevel >= dailyDungeonStartingTowerLevel &&
        towerLevel <= _dailyDungeonHighestUnlockedTowerLevel;
  }

  bool _refreshDailyDungeonQuickClearsForToday() {
    final today = _currentDayKey();
    if (_dailyDungeonQuickClearDayKey == today) {
      return false;
    }
    _dailyDungeonQuickClearDayKey = today;
    _dailyDungeonQuickClearsUsed = 0;
    return true;
  }

  bool isDailyDungeonTowerLevelCleared(int towerLevel) {
    return towerLevel >= dailyDungeonStartingTowerLevel &&
        towerLevel <= _dailyDungeonHighestClearedTowerLevel;
  }

  double dailyDungeonTowerMaxHealthForLevel(int towerLevel) {
    return dailyDungeonTowerProfileForLevel(towerLevel).maxHealth;
  }

  LightcoreDailyDungeonReward dailyDungeonRewardForLevel(int towerLevel) {
    final level = towerLevel
        .clamp(dailyDungeonStartingTowerLevel, dailyDungeonMaxTowerLevel)
        .toInt();
    return LightcoreDailyDungeonReward(
      towerLevel: level,
      lumens: 120 + (level * 40) + (level * level * 4),
      flux: 6 + (level * 2) + (level ~/ 4),
      managerShards: 3 + level + (level ~/ 5),
      shellCores: 1 + (level ~/ 3),
      threatScans: 1 + (level ~/ 5),
      experience: 18 + (level * 7),
    );
  }

  LightcoreDailyDungeonReward dailyDungeonQuickClearRewardForLevel(
    int towerLevel,
  ) {
    final base = dailyDungeonRewardForLevel(towerLevel);
    return LightcoreDailyDungeonReward(
      towerLevel: base.towerLevel,
      lumens: (base.lumens * 0.55).round(),
      flux: max(1, (base.flux * 0.55).round()),
      managerShards: max(1, (base.managerShards * 0.55).round()),
      shellCores: base.shellCores,
      threatScans: max(0, base.threatScans - 1),
      experience: (base.experience * 0.55).round(),
    );
  }

  bool canQuickClearDailyDungeonTowerLevel(int towerLevel) {
    _refreshDailyDungeonQuickClearsForToday();
    return dailyDungeonsUnlocked &&
        isDailyDungeonTowerLevelCleared(towerLevel) &&
        dailyDungeonQuickClearsRemaining > 0;
  }

  String dailyDungeonQuickClearButtonLabel(
    int towerLevel, {
    bool includeExperience = true,
  }) {
    final reward = includeExperience
        ? dailyDungeonQuickClearRewardForLevel(towerLevel)
        : dailyDungeonQuickClearRewardForLevel(towerLevel).withoutExperience();
    if (!isDailyDungeonTowerLevelCleared(towerLevel)) {
      return 'Clear once to quick clear';
    }
    if (dailyDungeonQuickClearsRemaining <= 0) {
      return 'Daily clears used';
    }
    return 'Quick Clear • ${reward.label}';
  }

  LightcoreDailyDungeonReward? quickClearDailyDungeonTowerLevel(
    int towerLevel, {
    bool showBanner = true,
    bool grantExperience = true,
  }) {
    _refreshDailyDungeonQuickClearsForToday();
    if (!canQuickClearDailyDungeonTowerLevel(towerLevel)) {
      if (showBanner) {
        _showBanner(
          isDailyDungeonTowerLevelCleared(towerLevel)
              ? 'Daily clears are used for today.'
              : 'Clear Daily Tower Lv $towerLevel once before quick clearing it.',
        );
        _notifyNow();
      }
      return null;
    }

    final previousExperience = progressionExperience;
    final reward = grantExperience
        ? dailyDungeonQuickClearRewardForLevel(towerLevel)
        : dailyDungeonQuickClearRewardForLevel(towerLevel).withoutExperience();
    lumens += reward.lumens;
    flux += reward.flux;
    managerShards += reward.managerShards;
    shellCores += reward.shellCores;
    enemyTickets += reward.threatScans;
    experience += _boostedExperienceReward(reward.experience);
    _dailyDungeonQuickClearsUsed += 1;
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    if (showBanner) {
      _showBanner(
        [
          'Daily Tower Lv $towerLevel quick cleared: ${reward.label}.',
          '$dailyDungeonQuickClearsRemaining daily clears remain today.',
          ...<String?>[levelUpBanner].whereType<String>(),
        ].join(' '),
      );
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return reward;
  }

  LightcoreDailyDungeonReward? clearDailyDungeonTowerLevel(
    int towerLevel, {
    bool showBanner = true,
    bool grantExperience = true,
  }) {
    if (!isDailyDungeonTowerLevelUnlocked(towerLevel)) {
      if (showBanner) {
        _showBanner('Daily Tower Lv $towerLevel is still locked.');
        _notifyNow();
      }
      return null;
    }

    if (isDailyDungeonTowerLevelCleared(towerLevel)) {
      _refreshDailyDungeonQuickClearsForToday();
      final baseReplayReward = dailyDungeonQuickClearsRemaining > 0
          ? dailyDungeonQuickClearRewardForLevel(towerLevel)
          : LightcoreDailyDungeonReward(
              towerLevel: towerLevel,
              lumens: 0,
              flux: 0,
              shellCores: 0,
              managerShards: 0,
              threatScans: 0,
              experience: 0,
            );
      final replayReward = grantExperience
          ? baseReplayReward
          : baseReplayReward.withoutExperience();
      String? levelUpBanner;
      if (replayReward.hasRewards) {
        final previousExperience = progressionExperience;
        lumens += replayReward.lumens;
        flux += replayReward.flux;
        managerShards += replayReward.managerShards;
        shellCores += replayReward.shellCores;
        enemyTickets += replayReward.threatScans;
        experience += _boostedExperienceReward(replayReward.experience);
        _dailyDungeonQuickClearsUsed += 1;
        levelUpBanner = _handleOverallLevelIncrease(
          previousExperience: previousExperience,
          currentExperience: progressionExperience,
        );
      }
      if (showBanner) {
        _showBanner(
          [
            replayReward.hasRewards
                ? 'Daily Tower Lv $towerLevel daily cleared: ${replayReward.label}.'
                : 'Daily Tower Lv $towerLevel already cleared. Push Lv $_dailyDungeonHighestUnlockedTowerLevel for the next first-pass reward.',
            if (replayReward.hasRewards)
              '$dailyDungeonQuickClearsRemaining daily clears remain today.',
            ...<String?>[levelUpBanner].whereType<String>(),
          ].join(' '),
        );
      }
      _syncTutorialStep(showBanner: false);
      _notifyNow();
      return replayReward;
    }

    final previousExperience = progressionExperience;
    final reward = grantExperience
        ? dailyDungeonRewardForLevel(towerLevel)
        : dailyDungeonRewardForLevel(towerLevel).withoutExperience();
    lumens += reward.lumens;
    flux += reward.flux;
    managerShards += reward.managerShards;
    shellCores += reward.shellCores;
    enemyTickets += reward.threatScans;
    experience += _boostedExperienceReward(reward.experience);
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    _dailyDungeonHighestClearedTowerLevel = max(
      _dailyDungeonHighestClearedTowerLevel,
      towerLevel,
    );
    _dailyDungeonHighestUnlockedTowerLevel = max(
      _dailyDungeonHighestUnlockedTowerLevel,
      min(dailyDungeonMaxTowerLevel, towerLevel + 1),
    );

    final unlockBanner = _towerUnlockBannerFragment(
      previousExperience,
      progressionExperience,
    );
    final managerUnlockBanner = _managerUnlockBannerFragment(
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
    if (showBanner) {
      _showBanner(
        [
          'Daily Tower Lv $towerLevel cleared: ${reward.label}.',
          if (towerLevel < dailyDungeonMaxTowerLevel)
            'Lv ${towerLevel + 1} unlocked.',
          ...<String?>[
            levelUpBanner,
            unlockBanner,
            managerUnlockBanner,
            tournamentUnlockBanner,
            mentorshipUnlockBanner,
          ].whereType<String>(),
        ].join(' '),
      );
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return reward;
  }

  bool buyLumensWithFlux({required int fluxCost, required int lumenAmount}) {
    if (fluxCost <= 0 || lumenAmount <= 0 || flux < fluxCost) {
      return false;
    }

    flux -= fluxCost;
    _recordFluxSpend(fluxCost);
    lumens += lumenAmount;
    _showBanner(
      'Converted ${LightcoreCurrencyLabels.fluxCount(fluxCost)} into ${LightcoreCurrencyLabels.lumenCount(lumenAmount)}.',
    );
    _notifyNow();
    return true;
  }

  bool buyEnemyPullsWithFlux({required int fluxCost, required int pullAmount}) {
    if (fluxCost <= 0 || pullAmount <= 0 || flux < fluxCost) {
      return false;
    }

    flux -= fluxCost;
    _recordFluxSpend(fluxCost);
    enemyTickets += pullAmount;
    _showBanner(
      'Bought ${LightcoreCurrencyLabels.threatScanCount(pullAmount)} for ${LightcoreCurrencyLabels.fluxCount(fluxCost)}.',
    );
    _notifyNow();
    return true;
  }

  bool grantPrismShards({
    required int amount,
    required String sourceLabel,
    bool showBanner = true,
  }) {
    final grantedAmount = max(0, amount);
    if (grantedAmount == 0) {
      return false;
    }

    prismShards += grantedAmount;
    if (showBanner) {
      _showBanner(
        '$sourceLabel: ${LightcoreCurrencyLabels.rewardPrismShards(grantedAmount)}.',
      );
    }
    _notifyNow();
    return true;
  }

  bool spendPrismShards({
    required int amount,
    required String reasonLabel,
    bool showBanner = true,
  }) {
    if (amount <= 0 || prismShards < amount) {
      return false;
    }

    prismShards -= amount;
    _recordPrismShardSpend(amount);
    if (showBanner) {
      _showBanner(
        'Spent ${LightcoreCurrencyLabels.prismShardCount(amount)} on $reasonLabel.',
      );
    }
    _notifyNow();
    return true;
  }

  bool purchaseAvatarCosmetic(String cosmeticId) {
    final config = AvatarCosmeticCatalog.byId[cosmeticId];
    if (config == null) {
      return false;
    }
    if (_unlockedAvatarCosmeticIds.contains(cosmeticId)) {
      return equipAvatarCosmetic(cosmeticId);
    }
    if (prismShards < config.pricePrismShards) {
      _showBanner(
        '${config.name} needs ${LightcoreCurrencyLabels.prismShardCount(config.pricePrismShards)}.',
      );
      _notifyNow();
      return false;
    }
    if (!spendPrismShards(
      amount: config.pricePrismShards,
      reasonLabel: config.name,
      showBanner: false,
    )) {
      return false;
    }
    _unlockedAvatarCosmeticIds.add(cosmeticId);
    _equipAvatarCosmeticConfig(config);
    _showBanner(
      '${config.name} added to your profile for ${LightcoreCurrencyLabels.prismShardCount(config.pricePrismShards)}.',
    );
    _notifyNow();
    return true;
  }

  bool equipAvatarCosmetic(String cosmeticId) {
    final config = AvatarCosmeticCatalog.byId[cosmeticId];
    if (config == null) {
      return false;
    }
    if (!_unlockedAvatarCosmeticIds.contains(cosmeticId)) {
      _showBanner('${config.name} is still locked.');
      _notifyNow();
      return false;
    }
    if (isAvatarCosmeticEquipped(cosmeticId)) {
      return true;
    }
    _equipAvatarCosmeticConfig(config);
    _showBanner('${config.name} equipped to your profile.');
    _notifyNow();
    return true;
  }

  bool unequipAvatarCosmeticType(AvatarCosmeticType type) {
    final current = equippedAvatarCosmeticForType(type);
    if (current == null) {
      return false;
    }
    switch (type) {
      case AvatarCosmeticType.hair:
        _equippedHairCosmeticId = null;
      case AvatarCosmeticType.face:
        _equippedFaceCosmeticId = null;
    }
    _showBanner('${current.name} removed from your profile.');
    _notifyNow();
    return true;
  }

  void _equipAvatarCosmeticConfig(AvatarCosmeticConfig config) {
    switch (config.type) {
      case AvatarCosmeticType.hair:
        _equippedHairCosmeticId = config.id;
      case AvatarCosmeticType.face:
        _equippedFaceCosmeticId = config.id;
    }
  }

  int storeOfferPurchasesRemaining(String offerId, {required int weeklyLimit}) {
    _refreshStoreOfferPurchaseWeek();
    if (weeklyLimit <= 0) {
      return 0;
    }
    return max(0, weeklyLimit - (_storeOfferWeeklyPurchases[offerId] ?? 0));
  }

  bool canSpendPrismShardsForStoreOffer(
    String offerId, {
    required int amount,
    required int weeklyLimit,
  }) {
    return amount > 0 &&
        prismShards >= amount &&
        storeOfferPurchasesRemaining(offerId, weeklyLimit: weeklyLimit) > 0;
  }

  bool spendPrismShardsForStoreOffer({
    required String offerId,
    required int amount,
    required int weeklyLimit,
    required String reasonLabel,
    bool showBanner = true,
  }) {
    _refreshStoreOfferPurchaseWeek();
    if (weeklyLimit <= 0 || amount <= 0) {
      return false;
    }
    if (storeOfferPurchasesRemaining(offerId, weeklyLimit: weeklyLimit) <= 0) {
      _showBanner('$reasonLabel is sold out until next week.');
      _notifyNow();
      return false;
    }
    if (prismShards < amount) {
      return false;
    }

    prismShards -= amount;
    _recordPrismShardSpend(amount);
    _storeOfferWeeklyPurchases[offerId] =
        (_storeOfferWeeklyPurchases[offerId] ?? 0) + 1;
    if (showBanner) {
      _showBanner(
        'Spent ${LightcoreCurrencyLabels.prismShardCount(amount)} on $reasonLabel.',
      );
    }
    _notifyNow();
    return true;
  }

  LightcoreTimeWarpOfferDefinition? timeWarpOfferById(String offerId) {
    for (final offer in timeWarpOffers) {
      if (offer.id == offerId) {
        return offer;
      }
    }
    return null;
  }

  int timeWarpPurchasesRemaining(String offerId) {
    _refreshTimeWarpPurchaseWeek();
    final offer = timeWarpOfferById(offerId);
    if (offer == null) {
      return 0;
    }
    return max(
      0,
      offer.weeklyLimit - (_timeWarpWeeklyPurchases[offer.id] ?? 0),
    );
  }

  bool canPurchaseTimeWarp(String offerId) {
    final offer = timeWarpOfferById(offerId);
    if (offer == null || timeWarpPurchasesRemaining(offer.id) <= 0) {
      return false;
    }
    return switch (offer.currency) {
      LightcoreTimeWarpCurrency.flux => flux >= offer.cost,
      LightcoreTimeWarpCurrency.prismShards => prismShards >= offer.cost,
    };
  }

  bool purchaseTimeWarp(String offerId) {
    _refreshTimeWarpPurchaseWeek();
    final offer = timeWarpOfferById(offerId);
    if (offer == null) {
      return false;
    }
    if (timeWarpPurchasesRemaining(offer.id) <= 0) {
      _showBanner('${offer.title} is sold out until next week.');
      _notifyNow();
      return false;
    }

    switch (offer.currency) {
      case LightcoreTimeWarpCurrency.flux:
        if (flux < offer.cost) {
          return false;
        }
        flux -= offer.cost;
        _recordFluxSpend(offer.cost);
      case LightcoreTimeWarpCurrency.prismShards:
        if (prismShards < offer.cost) {
          return false;
        }
        prismShards -= offer.cost;
        _recordPrismShardSpend(offer.cost);
    }

    _timeWarpWeeklyPurchases[offer.id] =
        (_timeWarpWeeklyPurchases[offer.id] ?? 0) + 1;
    _applyTimeWarpProgress(offer);
    _notifyNow();
    return true;
  }

  bool unlockPremiumBattlePass(
    BattlePassType type, {
    required int prismShardCost,
  }) {
    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    return unlockPremiumBattlePassForPass(
      _activeBattlePassFor(type),
      prismShardCost: prismShardCost,
    );
  }

  bool unlockPremiumBattlePassForPass(
    BattlePassProgress pass, {
    required int prismShardCost,
  }) {
    if (pass.premiumUnlocked ||
        prismShardCost <= 0 ||
        prismShards < prismShardCost) {
      return false;
    }

    prismShards -= prismShardCost;
    _recordPrismShardSpend(prismShardCost);
    pass.premiumUnlocked = true;
    _showBanner(
      'Spent ${LightcoreCurrencyLabels.prismShardCount(prismShardCost)} to unlock the ${pass.type.shortLabel} premium track.',
    );
    _notifyNow();
    return true;
  }

  void applyOfflineClaim(
    LightcoreOfflineClaimResult claim, {
    bool showBanner = true,
  }) {
    if (!claim.serverValidated) {
      return;
    }

    final claimedSeconds = max(0, claim.secondsClaimed);
    final fabricationAdvanced = _advanceOfflineTowerFabrication(
      claimedSeconds.toDouble(),
      showCompletionBanners: showBanner,
    );
    if (!claim.hasRewards && !fabricationAdvanced) {
      if (claimedSeconds > 0) {
        _totalOfflineSecondsClaimed += claimedSeconds;
        _notifyNow();
      }
      return;
    }

    final previousExperience = progressionExperience;
    _totalOfflineSecondsClaimed += claimedSeconds;
    if (!claim.hasRewards) {
      _syncTutorialStep(showBanner: false);
      _notifyNow();
      return;
    }

    lumens += claim.lumensGranted;
    flux += claim.fluxGranted;
    enemyTickets += claim.enemyTicketsGranted;
    kills += claim.killsGranted;
    final grantedExperience = _boostedExperienceReward(claim.killsGranted);
    experience += grantedExperience;
    final levelUpBanner = _handleOverallLevelIncrease(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final bossUnlockBanner = _grantBossUnlockIfNeeded();
    final tournamentUnlockBanner = _tournamentUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final managerUnlockBanner = _managerUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final dailyDungeonUnlockBanner = _dailyDungeonUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );
    final mentorshipUnlockBanner = _mentorshipUnlockBannerFragment(
      previousExperience: previousExperience,
      currentExperience: progressionExperience,
    );

    if (showBanner) {
      final claimedHours = max(0, claim.secondsClaimed) / 3600;
      final summary =
          'Offline claim: +${claim.lumensGranted}L, +${claim.fluxGranted}F, +${claim.enemyTicketsGranted} scans, +$grantedExperience EXP (${claimedHours.toStringAsFixed(1)}h).';
      final unlockBanner = _towerUnlockBannerFragment(
        previousExperience,
        progressionExperience,
      );
      final banners = <String>[
        summary,
        ...<String?>[
          levelUpBanner,
          unlockBanner,
          bossUnlockBanner,
          managerUnlockBanner,
          dailyDungeonUnlockBanner,
          tournamentUnlockBanner,
          mentorshipUnlockBanner,
        ].whereType<String>(),
      ];
      _showBanner(banners.join(' '));
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  String normalizeScreenName(String value) =>
      _normalizeOptionalScreenName(value);

  String? validateScreenName(String value) {
    if (!canEditScreenName) {
      return 'Screen names unlock at Account Radiance Lv $tournamentUnlockLevel.';
    }
    if (_screenNameVisibleLength(value) < minScreenNameLength) {
      return 'Screen names need at least $minScreenNameLength visible characters.';
    }
    if (_screenNameLength(value) > maxScreenNameLength) {
      return 'Screen names cannot exceed $maxScreenNameLength characters.';
    }
    return null;
  }

  bool setScreenName(String value, {bool showBanner = true}) {
    final validationError = validateScreenName(value);
    if (validationError != null) {
      if (showBanner) {
        _showBanner(validationError);
        _notifyNow();
      }
      return false;
    }

    final normalized = normalizeScreenName(value);
    final changed = _screenName != normalized;
    _screenName = normalized;
    _syncTutorialStep(showBanner: false);
    if (showBanner) {
      _showBanner(
        changed
            ? 'Screen name set to $normalized. Tournament brackets will use this callsign.'
            : 'Screen name confirmed as $normalized.',
      );
    }
    _notifyNow();
    return true;
  }

  void syncPlayerProfile(
    LightcorePlayerProfileSummary profile, {
    bool showBanner = false,
  }) {
    _playerId = profile.playerId;
    final normalizedScreenName = _normalizeOptionalScreenName(
      profile.screenName,
    );
    if (normalizedScreenName.isNotEmpty) {
      _screenName = normalizedScreenName;
    }
    _hasPremiumMembership =
        _hasPremiumMembership || profile.hasPremiumMembership;
    _syncTutorialStep(showBanner: false);
    setTournamentExperienceBoost(
      multiplier: profile.activeTournamentExpMultiplier,
      endsAt: profile.activeTournamentBoostEndsAt,
      showBanner: showBanner,
    );
  }

  void syncSocialOverview(
    LightcoreSocialOverview overview, {
    bool showBanner = false,
  }) {
    _socialOverview = overview;
    if (showBanner) {
      _showBanner(
        'Mentor hex synced: ${overview.bonusProfile.experienceLabel}, ${overview.bonusProfile.combatLabel}, ${overview.bonusProfile.rewardLabel}.',
        duration: 3.4,
      );
    }
    _notifyNow();
  }

  void applySocialBossGiftClaim(LightcoreBossGiftClaimResult claim) {
    final granted = max(0, claim.bossTicketsGranted);
    if (granted > 0) {
      bossTickets += granted;
    }
    _socialOverview = claim.overview;
    _showBanner(
      claim.message.isNotEmpty
          ? claim.message
          : 'Apex Scan gift claimed: +$granted $bossTicketCurrencyName.',
      duration: 3.2,
    );
    _notifyNow();
  }

  void applySocialBossGiftSend(LightcoreBossGiftSendResult send) {
    _socialOverview = send.overview;
    _showBanner(
      send.message.isNotEmpty
          ? send.message
          : 'Apex Scan gifts sent: ${send.sentCount}.',
      duration: 3.0,
    );
    _notifyNow();
  }

  void syncTournamentProfile(
    LightcorePlayerProfileSummary profile, {
    bool showBanner = false,
  }) {
    syncPlayerProfile(profile, showBanner: showBanner);
  }

  void setTournamentExperienceBoost({
    required double multiplier,
    required DateTime? endsAt,
    bool showBanner = false,
  }) {
    final normalizedMultiplier = multiplier <= 1.0 ? 1.0 : multiplier;
    final active =
        endsAt != null &&
        endsAt.isAfter(DateTime.now()) &&
        normalizedMultiplier > 1.0;
    _tournamentExperienceMultiplier = active ? normalizedMultiplier : 1.0;
    _tournamentExperienceBoostEndsAt = active ? endsAt : null;
    if (showBanner && active) {
      _showBanner(
        'Tournament reward active: $tournamentExperienceBoostLabel until ${_formatTournamentBoostEnd(endsAt)}.',
      );
    }
    _notifyNow();
  }

  void applyTournamentRewardPackage(
    LightcoreTournamentRewardPackage reward, {
    bool showBanner = true,
  }) {
    flux += max(0, reward.flux);
    enemyTickets += max(0, reward.tickets);
    if (reward.bonusTowerManagers > 0) {
      for (var index = 0; index < reward.bonusTowerManagers; index++) {
        _cards.add(
          _generateTowerManager(
            forgeCost: towerManagerFluxCost,
            forcedRarity:
                reward.bonusTowerManagerRarity ??
                _highestAvailableManagerRarity(),
          ),
        );
      }
    }
    if (reward.bonusEquipmentCaches > 0) {
      for (var index = 0; index < reward.bonusEquipmentCaches; index++) {
        _grantEquipmentEventCache(rarity: reward.bonusEquipmentRarity);
      }
    }
    setTournamentExperienceBoost(
      multiplier: reward.experienceMultiplier,
      endsAt: DateTime.now().add(
        Duration(hours: max(0, reward.experienceBuffHours)),
      ),
      showBanner: false,
    );
    if (showBanner) {
      final rewardParts = <String>[
        if (reward.flux > 0) LightcoreCurrencyLabels.rewardFlux(reward.flux),
        if (reward.tickets > 0)
          LightcoreCurrencyLabels.rewardThreatScans(reward.tickets),
        if (reward.bonusTowerManagers > 0)
          '+${reward.bonusTowerManagers} ${reward.bonusTowerManagerRarity?.label ?? 'Bonus'} manager cache${reward.bonusTowerManagers == 1 ? '' : 's'}',
        if (reward.bonusEquipmentCaches > 0)
          '+${reward.bonusEquipmentCaches} ${reward.bonusEquipmentRarity?.label ?? 'Weekly'} equipment cache${reward.bonusEquipmentCaches == 1 ? '' : 's'}',
        if (reward.experienceMultiplier > 1.0)
          '${reward.experienceMultiplier.toStringAsFixed(2)}x EXP for ${reward.experienceBuffHours}h',
      ];
      _showBanner('Tournament reward claimed: ${rewardParts.join('  •  ')}.');
      _notifyNow();
    }
  }
}
