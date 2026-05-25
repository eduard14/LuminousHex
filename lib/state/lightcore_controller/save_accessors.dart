part of '../lightcore_controller.dart';

extension LightcoreControllerSaveAccessors on LightcoreController {
  void syncServerClock(
    DateTime? serverTime, {
    bool showCompletionBanners = false,
  }) {
    if (serverTime == null) {
      return;
    }

    _serverClockAnchorMillis = serverTime.toUtc().millisecondsSinceEpoch;
    _serverClockElapsed
      ..reset()
      ..start();

    if (_reconcileServerAnchoredTowerFabrication(
      showCompletionBanners: showCompletionBanners,
    )) {
      _syncTutorialStep(showBanner: false);
      _notifyNow();
    }
  }

  void syncServerDateKeys({String? dayKey, String? weekKey}) {
    var changed = false;
    final normalizedDayKey = _normalizeDateKey(dayKey);
    if (normalizedDayKey != null && normalizedDayKey != _serverDayKey) {
      _serverDayKey = normalizedDayKey;
      changed = true;
    }
    final normalizedWeekKey = _normalizeDateKey(weekKey);
    if (normalizedWeekKey != null && normalizedWeekKey != _serverWeekKey) {
      _serverWeekKey = normalizedWeekKey;
      changed = true;
    }
    if (!changed) {
      return;
    }

    final resetBattlePass = _refreshBattlePassesForToday();
    final resetTimeWarp = _refreshTimeWarpPurchaseWeek();
    final resetStoreOffers = _refreshStoreOfferPurchaseWeek();
    final resetDailyQuickClears = _refreshDailyDungeonQuickClearsForToday();
    if (resetBattlePass ||
        resetTimeWarp ||
        resetStoreOffers ||
        resetDailyQuickClears) {
      _notifyNow();
    }
  }

  Map<EnemyCardRarity, List<EnemyCardState>> get enemyCardsByRarity => {
    for (final rarity in EnemyCardRarity.values)
      rarity: _enemyCards
          .where((card) => card.config.rarity == rarity)
          .toList(growable: false),
  };

  List<EnemyCardRarity> get availableEnemyPullRarities => EnemyCardRarity.values
      .where((rarity) => (summonRates[rarity] ?? 0) > 0)
      .toList(growable: false);

  List<EnemyCardRarity> get availableBossPullRarities => EnemyCardRarity.values
      .where((rarity) => (bossSummonRates[rarity] ?? 0) > 0)
      .toList(growable: false);

  EnemyCardRarity get highestAvailableEnemyPullRarity =>
      availableEnemyPullRarities.last;

  EnemyCardRarity get highestAvailableBossPullRarity =>
      availableBossPullRarities.last;

  EnemyCardRarity? get secondHighestAvailableEnemyPullRarity {
    final available = availableEnemyPullRarities;
    return available.length < 2 ? null : available[available.length - 2];
  }

  EnemyCardRarity? get secondHighestAvailableBossPullRarity {
    final available = availableBossPullRarities;
    return available.length < 2 ? null : available[available.length - 2];
  }

  bool get isSummoningLevelMaxed => summoningLevel >= maxSummoningLevel;

  bool get isBossSummoningLevelMaxed =>
      bossSummoningLevel >= maxBossSummoningLevel;

  int get currentSummoningLevelPullFloor =>
      summoningLevelPullTargetForLevel(summoningLevel);

  int get currentBossSummoningLevelPullFloor =>
      (bossSummoningLevel - 1) * bossPullsPerSummoningLevel;

  int get nextSummoningLevel =>
      isSummoningLevelMaxed ? maxSummoningLevel : summoningLevel + 1;

  int get nextBossSummoningLevel => isBossSummoningLevelMaxed
      ? maxBossSummoningLevel
      : bossSummoningLevel + 1;

  int get nextSummoningLevelPullTarget => isSummoningLevelMaxed
      ? currentSummoningLevelPullFloor
      : summoningLevelPullTargetForLevel(nextSummoningLevel);

  int get nextBossSummoningLevelPullTarget =>
      currentBossSummoningLevelPullFloor + bossPullsPerSummoningLevel;

  int get currentSummoningLevelPullGap => isSummoningLevelMaxed
      ? summoningLevelPullGapForLevel(maxSummoningLevel)
      : nextSummoningLevelPullTarget - currentSummoningLevelPullFloor;

  int get summoningLevelPullsIntoCurrent => isSummoningLevelMaxed
      ? currentSummoningLevelPullGap
      : enemyPullCount - currentSummoningLevelPullFloor;

  int get bossSummoningLevelPullsIntoCurrent => isBossSummoningLevelMaxed
      ? bossPullsPerSummoningLevel
      : bossPullCount - currentBossSummoningLevelPullFloor;

  double get summoningLevelProgress => isSummoningLevelMaxed
      ? 1.0
      : (summoningLevelPullsIntoCurrent / currentSummoningLevelPullGap).clamp(
          0.0,
          1.0,
        );

  double get bossSummoningLevelProgress => isBossSummoningLevelMaxed
      ? 1.0
      : (bossSummoningLevelPullsIntoCurrent / bossPullsPerSummoningLevel).clamp(
          0.0,
          1.0,
        );

  int get pullsToNextSummoningLevel => isSummoningLevelMaxed
      ? 0
      : max(0, nextSummoningLevelPullTarget - enemyPullCount);

  int get pullsToNextBossSummoningLevel => isBossSummoningLevelMaxed
      ? 0
      : max(0, nextBossSummoningLevelPullTarget - bossPullCount);

  int get nextSummoningLevelTicketReward => isSummoningLevelMaxed
      ? 0
      : summoningLevelTicketRewardForLevel(nextSummoningLevel);

  int get nextBossSummoningLevelTicketReward => isBossSummoningLevelMaxed
      ? 0
      : bossSummoningLevelTicketRewardForLevel(nextBossSummoningLevel);

  Map<EnemyCardRarity, double> get summonRates {
    final progress = ((summoningLevel - 1) / (maxSummoningLevel - 1)).clamp(
      0.0,
      1.0,
    );
    final uncommon = 9.99 + (8.01 * progress);
    final rare = 0.01 + (2.99 * progress);
    final epicProgress = ((summoningLevel - 5) / (maxSummoningLevel - 5)).clamp(
      0.0,
      1.0,
    );
    final epic = 0.75 * epicProgress;
    final legendaryProgress = ((summoningLevel - 10) / (maxSummoningLevel - 10))
        .clamp(0.0, 1.0);
    final legendary = 0.1 * legendaryProgress;
    final basic = max(0.0, 100 - uncommon - rare - epic - legendary);
    return <EnemyCardRarity, double>{
      EnemyCardRarity.basic: basic,
      EnemyCardRarity.uncommon: uncommon,
      EnemyCardRarity.rare: rare,
      EnemyCardRarity.epic: epic,
      EnemyCardRarity.legendary: legendary,
    };
  }

  Map<EnemyCardRarity, double> get bossSummonRates {
    final progress = ((bossSummoningLevel - 1) / (maxBossSummoningLevel - 1))
        .clamp(0.0, 1.0);
    final uncommon = 14.0 + (18.0 * progress);
    final rare = 1.2 + (8.8 * progress);
    final epicProgress =
        ((bossSummoningLevel - 3) / (maxBossSummoningLevel - 3)).clamp(
          0.0,
          1.0,
        );
    final epic = 2.2 * epicProgress;
    final legendaryProgress =
        ((bossSummoningLevel - 7) / (maxBossSummoningLevel - 7)).clamp(
          0.0,
          1.0,
        );
    final legendary = 0.8 * legendaryProgress;
    final basic = max(0.0, 100 - uncommon - rare - epic - legendary);
    return <EnemyCardRarity, double>{
      EnemyCardRarity.basic: basic,
      EnemyCardRarity.uncommon: uncommon,
      EnemyCardRarity.rare: rare,
      EnemyCardRarity.epic: epic,
      EnemyCardRarity.legendary: legendary,
    };
  }

  Map<ManagerRarity, double> get managerForgeRates {
    final prestigeProgress = (prestigeLevel / 12).clamp(0.0, 1.0);
    final legendary = 0.2 + (1.8 * prestigeProgress);
    final epic = 1.2 + (3.8 * prestigeProgress);
    final rare = 8.0 + (9.0 * prestigeProgress);
    final uncommon = 22.0 + (4.0 * prestigeProgress);
    final common = max(0.0, 100 - uncommon - rare - epic - legendary);
    return <ManagerRarity, double>{
      ManagerRarity.common: common,
      ManagerRarity.uncommon: uncommon,
      ManagerRarity.rare: rare,
      ManagerRarity.epic: epic,
      ManagerRarity.legendary: legendary,
    };
  }

  double get currentLumenMultiplier {
    final crowdedBy = max(0, enemyCount - 1);
    final penaltyPerEnemy = max(0.03, 0.09 - globalLumenGuard);
    return max(0.35, 1 - (crowdedBy * penaltyPerEnemy)) *
        lumenTierMultiplier *
        _gearLumenMultiplier *
        _economyBalanceMultiplier('lumenReward');
  }

  double get lumenTierMultiplier => pow(2, activeLayer.tier - 1).toDouble();
}
