import 'lightcore_currency_labels.dart';
import 'lightcore_types.dart';

enum BattlePassType {
  dailyKills,
  towerManagerPulls,
  enemyManagerPulls,
  enemyPulls,
}

enum BattlePassTrack { free, premium }

enum BattlePassRewardKind {
  lumens,
  flux,
  enemyPulls,
  towerManager,
  enemyManager,
  enemyCard,
}

extension BattlePassTypeX on BattlePassType {
  String get label => switch (this) {
    BattlePassType.dailyKills => 'Daily Kill Pass',
    BattlePassType.towerManagerPulls => 'Core Manager Pass',
    BattlePassType.enemyManagerPulls => 'Threat Director Pass',
    BattlePassType.enemyPulls => 'Threat Scan Pass',
  };

  String get shortLabel => switch (this) {
    BattlePassType.dailyKills => 'Daily',
    BattlePassType.towerManagerPulls => 'Core Managers',
    BattlePassType.enemyManagerPulls => 'Threat Directors',
    BattlePassType.enemyPulls => 'Threat Scans',
  };

  String get progressUnitLabel => switch (this) {
    BattlePassType.dailyKills => 'Kills',
    BattlePassType.towerManagerPulls => 'Core Manager Pulls',
    BattlePassType.enemyManagerPulls => 'Threat Director Pulls',
    BattlePassType.enemyPulls => 'Scans',
  };

  String get cadenceLabel => switch (this) {
    BattlePassType.dailyKills => 'Resets daily',
    BattlePassType.towerManagerPulls => 'Rolling pass',
    BattlePassType.enemyManagerPulls => 'Rolling pass',
    BattlePassType.enemyPulls => 'Rolling pass',
  };

  bool get resetsDaily => this == BattlePassType.dailyKills;
}

extension BattlePassTrackX on BattlePassTrack {
  String get label => switch (this) {
    BattlePassTrack.free => 'Free',
    BattlePassTrack.premium => 'Premium',
  };
}

class BattlePassReward {
  const BattlePassReward._({
    required this.kind,
    required this.quantity,
    this.managerRarity,
    this.enemyCardRarity,
  });

  const BattlePassReward.lumens(int amount)
    : this._(kind: BattlePassRewardKind.lumens, quantity: amount);

  const BattlePassReward.flux(int amount)
    : this._(kind: BattlePassRewardKind.flux, quantity: amount);

  const BattlePassReward.enemyPulls(int amount)
    : this._(kind: BattlePassRewardKind.enemyPulls, quantity: amount);

  const BattlePassReward.towerManager({
    int quantity = 1,
    required ManagerRarity rarity,
  }) : this._(
         kind: BattlePassRewardKind.towerManager,
         quantity: quantity,
         managerRarity: rarity,
       );

  const BattlePassReward.enemyManager({
    int quantity = 1,
    required ManagerRarity rarity,
  }) : this._(
         kind: BattlePassRewardKind.enemyManager,
         quantity: quantity,
         managerRarity: rarity,
       );

  const BattlePassReward.enemyCard({
    int quantity = 1,
    required EnemyCardRarity rarity,
  }) : this._(
         kind: BattlePassRewardKind.enemyCard,
         quantity: quantity,
         enemyCardRarity: rarity,
       );

  final BattlePassRewardKind kind;
  final int quantity;
  final ManagerRarity? managerRarity;
  final EnemyCardRarity? enemyCardRarity;

  String get label {
    final quantityPrefix = quantity > 1 ? '$quantity x ' : '';
    return switch (kind) {
      BattlePassRewardKind.lumens => LightcoreCurrencyLabels.rewardLumens(
        quantity,
      ),
      BattlePassRewardKind.flux => LightcoreCurrencyLabels.rewardFlux(quantity),
      BattlePassRewardKind.enemyPulls =>
        LightcoreCurrencyLabels.rewardThreatScans(quantity),
      BattlePassRewardKind.towerManager =>
        '$quantityPrefix${managerRarity!.label} Core Manager',
      BattlePassRewardKind.enemyManager =>
        '$quantityPrefix${managerRarity!.label} Threat Director',
      BattlePassRewardKind.enemyCard =>
        '$quantityPrefix${enemyCardRarity!.label} Anomaly Card',
    };
  }
}

class BattlePassTierDefinition {
  const BattlePassTierDefinition({
    required this.goal,
    required this.freeReward,
    required this.premiumReward,
  });

  final int goal;
  final BattlePassReward freeReward;
  final BattlePassReward premiumReward;
}

class BattlePassProgress {
  BattlePassProgress({
    required this.type,
    required this.seasonKey,
    this.generation = 1,
    this.progress = 0,
    this.premiumUnlocked = false,
    Set<String>? claimedRewardKeys,
    this.snapshotManagerRarity,
    this.snapshotEnemyCardRarity,
  }) : claimedRewardKeys = claimedRewardKeys ?? <String>{};

  final BattlePassType type;
  final String seasonKey;
  final int generation;
  int progress;
  bool premiumUnlocked;
  final Set<String> claimedRewardKeys;
  final ManagerRarity? snapshotManagerRarity;
  final EnemyCardRarity? snapshotEnemyCardRarity;
}
