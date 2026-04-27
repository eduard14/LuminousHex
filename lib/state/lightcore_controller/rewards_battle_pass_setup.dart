part of '../lightcore_controller.dart';

extension LightcoreControllerBattlePassSetup on LightcoreController {
  Map<BattlePassType, List<BattlePassProgress>> _createBattlePassMap() {
    return <BattlePassType, List<BattlePassProgress>>{
      for (final type in BattlePassType.values)
        type: <BattlePassProgress>[_createBattlePass(type)],
    };
  }

  BattlePassProgress _createBattlePass(
    BattlePassType type, {
    int generation = 1,
    String? seasonKey,
  }) {
    return BattlePassProgress(
      type: type,
      seasonKey:
          seasonKey ?? _newBattlePassSeasonKey(type, generation: generation),
      generation: generation,
      snapshotManagerRarity: _battlePassManagerRewardRarity(type),
      snapshotEnemyCardRarity: _battlePassEnemyCardRewardRarity(type),
    );
  }

  String _newBattlePassSeasonKey(
    BattlePassType type, {
    required int generation,
  }) {
    if (type.resetsDaily) {
      return _currentDayKey();
    }
    return '${type.name}-$generation-${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  BattlePassProgress _activeBattlePassFor(BattlePassType type) {
    final passes = _battlePasses[type];
    if (passes == null || passes.isEmpty) {
      final pass = _createBattlePass(type);
      _battlePasses[type] = <BattlePassProgress>[pass];
      return pass;
    }
    return passes.last;
  }

  ManagerRarity? _battlePassManagerRewardRarity(BattlePassType type) {
    return switch (type) {
      BattlePassType.towerManagerPulls => ManagerRarity.rare,
      BattlePassType.enemyManagerPulls => ManagerRarity.epic,
      _ => null,
    };
  }

  EnemyCardRarity? _battlePassEnemyCardRewardRarity(BattlePassType type) {
    return switch (type) {
      BattlePassType.enemyPulls => EnemyCardRarity.legendary,
      _ => null,
    };
  }

  bool _refreshBattlePassesForToday({bool showBanner = false}) {
    final dailyPasses = _battlePasses[BattlePassType.dailyKills];
    if (dailyPasses == null || dailyPasses.isEmpty) {
      return false;
    }

    final dailyPass = dailyPasses.last;
    final today = _currentDayKey();
    if (dailyPass.seasonKey == today) {
      return false;
    }

    _battlePasses[BattlePassType.dailyKills] = <BattlePassProgress>[
      _createBattlePass(BattlePassType.dailyKills, seasonKey: today),
    ];
    if (showBanner) {
      _showBanner('Daily kill pass reset for $today.');
    }
    return true;
  }

  bool _refreshTimeWarpPurchaseWeek() {
    final currentWeek = _currentWeekKey();
    if (_timeWarpPurchaseWeekKey == currentWeek) {
      return false;
    }
    _timeWarpPurchaseWeekKey = currentWeek;
    _timeWarpWeeklyPurchases.clear();
    return true;
  }

  bool _refreshStoreOfferPurchaseWeek() {
    final currentWeek = _currentWeekKey();
    if (_storeOfferPurchaseWeekKey == currentWeek) {
      return false;
    }
    _storeOfferPurchaseWeekKey = currentWeek;
    _storeOfferWeeklyPurchases.clear();
    return true;
  }

  void _advanceBattlePass(BattlePassType type, int amount) {
    if (amount <= 0) {
      return;
    }

    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    if (type.resetsDaily) {
      final pass = _activeBattlePassFor(type);
      final finalGoal = _battlePassTierDefinitions(pass).last.goal;
      pass.progress = min(finalGoal, pass.progress + amount);
      return;
    }

    var remaining = amount;
    while (remaining > 0) {
      final pass = _activeBattlePassFor(type);
      final finalGoal = _battlePassTierDefinitions(pass).last.goal;
      final room = finalGoal - pass.progress;
      if (room <= 0) {
        _battlePasses[type]!.add(
          _createBattlePass(type, generation: pass.generation + 1),
        );
        continue;
      }
      final applied = min(room, remaining);
      pass.progress += applied;
      remaining -= applied;
      if (pass.progress >= finalGoal) {
        _battlePasses[type]!.add(
          _createBattlePass(type, generation: pass.generation + 1),
        );
      }
    }
  }

  void _grantBattlePassReward(BattlePassReward reward) {
    switch (reward.kind) {
      case BattlePassRewardKind.lumens:
        lumens += reward.quantity;
      case BattlePassRewardKind.flux:
        flux += reward.quantity;
      case BattlePassRewardKind.enemyPulls:
        enemyTickets += reward.quantity;
      case BattlePassRewardKind.towerManager:
        for (var index = 0; index < reward.quantity; index++) {
          _cards.add(
            _generateTowerManager(
              forgeCost: towerManagerFluxCost,
              forcedRarity:
                  reward.managerRarity ?? _highestAvailableManagerRarity(),
            ),
          );
        }
      case BattlePassRewardKind.enemyManager:
        for (var index = 0; index < reward.quantity; index++) {
          _enemyManagers.add(
            _generateEnemyManager(
              forgeCost: enemyManagerFluxCost,
              forcedRarity:
                  reward.managerRarity ?? _highestAvailableManagerRarity(),
            ),
          );
        }
      case BattlePassRewardKind.enemyCard:
        _grantEnemyCardByRarity(
          reward.enemyCardRarity ?? _highestAvailableEnemyCardRarity(),
          copies: reward.quantity,
        );
    }
  }

  void _grantEnemyCardByRarity(EnemyCardRarity rarity, {required int copies}) {
    if (copies <= 0) {
      return;
    }

    final pool = EnemyLibrary.byRarity[rarity];
    if (pool == null || pool.isEmpty) {
      return;
    }

    for (var copy = 0; copy < copies; copy++) {
      final config = pool[_packRandom.nextInt(pool.length)];
      final cardIndex = _enemyCards.indexWhere(
        (card) => card.config.id == config.id,
      );
      final current = _enemyCards[cardIndex];
      final wasNew = !current.unlocked;
      _enemyCards[cardIndex] = current.copyWith(
        unlocked: true,
        copies: current.copies + 1,
      );
      if (wasNew && _activeEnemyCardIds.length < enemyDeckLimit) {
        _activeEnemyCardIds.add(config.id);
      }
    }
  }

  ManagerRarity _highestAvailableManagerRarity() {
    final rates = managerForgeRates;
    for (final rarity in ManagerRarity.values.reversed) {
      if ((rates[rarity] ?? 0) > 0) {
        return rarity;
      }
    }
    return ManagerRarity.common;
  }

  EnemyCardRarity _highestAvailableEnemyCardRarity() {
    final rates = summonRates;
    for (final rarity in EnemyCardRarity.values.reversed) {
      if ((rates[rarity] ?? 0) > 0) {
        return rarity;
      }
    }
    return EnemyCardRarity.basic;
  }

  String _battlePassClaimKey(int tierIndex, BattlePassTrack track) =>
      '${track.name}:$tierIndex';
}
