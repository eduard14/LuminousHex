import 'lightcore_currency_labels.dart';
import 'lightcore_types.dart';

enum LightcoreTournamentModeId { enemyBlitz, hexGauntlet, arenaFlow }

extension LightcoreTournamentModeIdX on LightcoreTournamentModeId {
  String get wireKey => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'enemyBlitz',
    LightcoreTournamentModeId.hexGauntlet => 'hexGauntlet',
    LightcoreTournamentModeId.arenaFlow => 'arenaFlow',
  };

  String get label => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'Anomaly Blitz',
    LightcoreTournamentModeId.hexGauntlet => 'Hex',
    LightcoreTournamentModeId.arenaFlow => 'Arena Flow',
  };

  String get subtitle => switch (this) {
    LightcoreTournamentModeId.enemyBlitz =>
      'An open testing survival board: draft anomalies, keep upgrading through a weekend-length session, and improve your best wave before reset.',
    LightcoreTournamentModeId.hexGauntlet =>
      'A normalized event shell is dropped into a hex-path defense map and pushed through a weekly global wave climb.',
    LightcoreTournamentModeId.arenaFlow =>
      'Each player sends their highest-layer Home Tower into a 20-second arena duel where enemy waves attack the opposing tower directly.',
  };

  String get queueLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'Testing leaderboard',
    LightcoreTournamentModeId.hexGauntlet => 'Global leaderboard',
    LightcoreTournamentModeId.arenaFlow => 'Weekly ladder',
  };

  String get mechanicLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'Draft and reinvest',
    LightcoreTournamentModeId.hexGauntlet => 'Lane reinforcement',
    LightcoreTournamentModeId.arenaFlow => 'Overclock timing',
  };

  String get compressedLoopLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz =>
      'Anomaly Blitz stays open for testing, but each survival session uses a weekend-length clock instead of a quick match timer.',
    LightcoreTournamentModeId.hexGauntlet =>
      'The event shell and lane defense rules stay intact, but the wave ramp is accelerated into a weekly solo climb on the global board.',
    LightcoreTournamentModeId.arenaFlow =>
      'The highest-layer Home Tower becomes the arena tower, and the duel condenses damage dealt minus damage taken into one short run.',
  };

  String get scoringLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'Highest wave and survival score',
    LightcoreTournamentModeId.hexGauntlet => 'Deepest path clear',
    LightcoreTournamentModeId.arenaFlow =>
      'Highest net damage after 20 seconds',
  };

  String get eventCadenceLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'Open testing',
    LightcoreTournamentModeId.hexGauntlet => 'Weekly',
    LightcoreTournamentModeId.arenaFlow => 'Weekly',
  };

  String get prepLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz =>
      'Pick three enemies from your tournament pool.',
    LightcoreTournamentModeId.hexGauntlet =>
      'Import the event-normalized shell into the weekly hex board.',
    LightcoreTournamentModeId.arenaFlow =>
      'Bring your active Home Tower and current enemy stack into the arena.',
  };

  String get focusLabel => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => 'Anomaly drafting',
    LightcoreTournamentModeId.hexGauntlet => 'Event shell layout',
    LightcoreTournamentModeId.arenaFlow => 'Highest-layer Home Tower',
  };

  bool get usesTowerSeed => this == LightcoreTournamentModeId.arenaFlow;

  bool get usesGlobalRating => this == LightcoreTournamentModeId.arenaFlow;

  bool get supportsEnemyDraft =>
      this == LightcoreTournamentModeId.enemyBlitz ||
      this == LightcoreTournamentModeId.arenaFlow;

  bool get supportsBossDraft => this == LightcoreTournamentModeId.arenaFlow;

  List<String> get rules => switch (this) {
    LightcoreTournamentModeId.enemyBlitz => const <String>[
      'Testing access stays open while the format is being tuned.',
      'Each survival session runs on a weekend-length clock.',
      'Drafted enemy pressure increases future payouts and score.',
      'Runs score from wave depth, survival, and reinvestment timing.',
    ],
    LightcoreTournamentModeId.hexGauntlet => const <String>[
      'Build fixed-stat towers on open hexes; the cut path is reserved for waves.',
      'Send every wave manually. No offline progress is awarded.',
      'Defeated enemies pay event currency for more towers or stronger enemy tiers.',
      'Merge two matching towers into one payload tower, then merge two payload towers for an impact projectile.',
      'Higher enemy tiers are riskier and worth more score.',
    ],
    LightcoreTournamentModeId.arenaFlow => const <String>[
      'Your Home Tower is always your highest-layer tower.',
      'Both Home Towers are visible, and each side faces the other player\'s enemy wave.',
      'Server-seeded rivals keep the arena populated even before other players post runs.',
      'Runs score from damage dealt minus damage taken after the short arena duel.',
      'Weekly rewards are awarded from the closed server leaderboard after reset.',
    ],
  };
}

LightcoreTournamentModeId tournamentModeFromWireKey(String value) {
  return LightcoreTournamentModeId.values.firstWhere(
    (mode) => mode.wireKey == value,
    orElse: () => LightcoreTournamentModeId.enemyBlitz,
  );
}

class LightcoreTournamentPlayerSnapshot {
  const LightcoreTournamentPlayerSnapshot({
    required this.overallLevel,
    required this.prestigeLevel,
    required this.activeLayerTier,
    required this.builtTowerCount,
    required this.coreLevel,
    required this.towerPowerIndex,
    this.towerAffinity = PrototypeAffinity.neutral,
    this.enemyAffinity = PrototypeAffinity.neutral,
    this.enemyCardIds = const <String>[],
    this.enemyCardLevels = const <String, int>{},
    this.bossEnemyCardId,
    this.bossEnemyLevel = 1,
  });

  final int overallLevel;
  final int prestigeLevel;
  final int activeLayerTier;
  final int builtTowerCount;
  final int coreLevel;
  final int towerPowerIndex;
  final PrototypeAffinity towerAffinity;
  final PrototypeAffinity enemyAffinity;
  final List<String> enemyCardIds;
  final Map<String, int> enemyCardLevels;
  final String? bossEnemyCardId;
  final int bossEnemyLevel;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'overallLevel': overallLevel,
      'prestigeLevel': prestigeLevel,
      'activeLayerTier': activeLayerTier,
      'builtTowerCount': builtTowerCount,
      'coreLevel': coreLevel,
      'towerPowerIndex': towerPowerIndex,
      'towerAffinity': towerAffinity.name,
      'enemyAffinity': enemyAffinity.name,
      'enemyCardIds': List<String>.from(enemyCardIds),
      'enemyCardLevels': Map<String, int>.from(enemyCardLevels),
      if (bossEnemyCardId != null) 'bossEnemyCardId': bossEnemyCardId,
      'bossEnemyLevel': bossEnemyLevel,
    };
  }

  factory LightcoreTournamentPlayerSnapshot.fromMap(Map<String, dynamic> data) {
    final enemyCardLevels = _coerceIntMap(data['enemyCardLevels']);
    return LightcoreTournamentPlayerSnapshot(
      overallLevel: (data['overallLevel'] as num?)?.toInt() ?? 1,
      prestigeLevel: (data['prestigeLevel'] as num?)?.toInt() ?? 0,
      activeLayerTier: (data['activeLayerTier'] as num?)?.toInt() ?? 1,
      builtTowerCount: (data['builtTowerCount'] as num?)?.toInt() ?? 0,
      coreLevel: (data['coreLevel'] as num?)?.toInt() ?? 1,
      towerPowerIndex: (data['towerPowerIndex'] as num?)?.toInt() ?? 0,
      towerAffinity:
          _affinityFromName(data['towerAffinity'] as String?) ??
          PrototypeAffinity.neutral,
      enemyAffinity:
          _affinityFromName(data['enemyAffinity'] as String?) ??
          PrototypeAffinity.neutral,
      enemyCardIds: _coerceStringList(data['enemyCardIds']),
      enemyCardLevels: enemyCardLevels,
      bossEnemyCardId: data['bossEnemyCardId'] as String?,
      bossEnemyLevel: (data['bossEnemyLevel'] as num?)?.toInt() ?? 1,
    );
  }
}

class LightcoreTournamentRewardPackage {
  const LightcoreTournamentRewardPackage({
    required this.flux,
    required this.tickets,
    required this.experienceMultiplier,
    required this.experienceBuffHours,
    this.bonusTowerManagers = 0,
    this.bonusTowerManagerRarity,
    this.bonusEquipmentCaches = 0,
    this.bonusEquipmentRarity,
  });

  final int flux;
  final int tickets;
  final double experienceMultiplier;
  final int experienceBuffHours;
  final int bonusTowerManagers;
  final ManagerRarity? bonusTowerManagerRarity;
  final int bonusEquipmentCaches;
  final ManagerRarity? bonusEquipmentRarity;

  bool get hasImmediateRewards =>
      flux > 0 ||
      tickets > 0 ||
      bonusTowerManagers > 0 ||
      bonusEquipmentCaches > 0;

  String get summaryLabel {
    final parts = <String>[
      'x${experienceMultiplier.toStringAsFixed(2)} EXP',
      LightcoreCurrencyLabels.rewardFlux(flux),
      LightcoreCurrencyLabels.rewardThreatScans(tickets),
      if (bonusTowerManagers > 0)
        '$bonusTowerManagers ${bonusTowerManagerRarity?.label ?? 'Bonus'} manager cache${bonusTowerManagers == 1 ? '' : 's'}',
      if (bonusEquipmentCaches > 0)
        '$bonusEquipmentCaches ${bonusEquipmentRarity?.label ?? 'Weekly'} equipment cache${bonusEquipmentCaches == 1 ? '' : 's'}',
    ];
    return parts.join('  •  ');
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'flux': flux,
      'tickets': tickets,
      'experienceMultiplier': experienceMultiplier,
      'experienceBuffHours': experienceBuffHours,
      'bonusTowerManagers': bonusTowerManagers,
      'bonusTowerManagerRarity': bonusTowerManagerRarity?.name,
      'bonusEquipmentCaches': bonusEquipmentCaches,
      'bonusEquipmentRarity': bonusEquipmentRarity?.name,
    };
  }

  factory LightcoreTournamentRewardPackage.fromMap(Map<String, dynamic> data) {
    return LightcoreTournamentRewardPackage(
      flux: (data['flux'] as num?)?.toInt() ?? 0,
      tickets: (data['tickets'] as num?)?.toInt() ?? 0,
      experienceMultiplier:
          (data['experienceMultiplier'] as num?)?.toDouble() ?? 1.0,
      experienceBuffHours: (data['experienceBuffHours'] as num?)?.toInt() ?? 0,
      bonusTowerManagers: (data['bonusTowerManagers'] as num?)?.toInt() ?? 0,
      bonusTowerManagerRarity: _managerRarityFromName(
        data['bonusTowerManagerRarity'] as String?,
      ),
      bonusEquipmentCaches:
          (data['bonusEquipmentCaches'] as num?)?.toInt() ?? 0,
      bonusEquipmentRarity: _managerRarityFromName(
        data['bonusEquipmentRarity'] as String?,
      ),
    );
  }
}

class LightcoreTournamentLeaderboardEntry {
  const LightcoreTournamentLeaderboardEntry({
    required this.displayName,
    required this.score,
    required this.globalRating,
    this.isPlayer = false,
    this.snapshot,
  });

  final String displayName;
  final int score;
  final int globalRating;
  final bool isPlayer;
  final LightcoreTournamentPlayerSnapshot? snapshot;

  factory LightcoreTournamentLeaderboardEntry.fromMap(
    Map<String, dynamic> data,
  ) {
    final snapshotData = _coerceMap(data['snapshot']);
    return LightcoreTournamentLeaderboardEntry(
      displayName: (data['displayName'] as String?) ?? 'Pilot',
      score: (data['score'] as num?)?.toInt() ?? 0,
      globalRating: (data['globalRating'] as num?)?.toInt() ?? 1000,
      isPlayer: (data['isPlayer'] as bool?) ?? false,
      snapshot: snapshotData.isEmpty
          ? null
          : LightcoreTournamentPlayerSnapshot.fromMap(snapshotData),
    );
  }
}

class LightcoreTournamentModeState {
  const LightcoreTournamentModeState({
    required this.mode,
    required this.statusMessage,
    required this.mechanicSummary,
    required this.rewardPreview,
    required this.startsAt,
    required this.endsAt,
    this.groupId,
    this.matchBucketLabel,
    this.groupSize = 0,
    this.capacity = 15,
    this.playerBestScore = 0,
    this.playerRank,
    this.joined = false,
    this.isOpen = true,
    this.rewardReady = false,
    this.rewardClaimed = false,
    this.seedPowerIndex = 1000,
    this.leaderboard = const <LightcoreTournamentLeaderboardEntry>[],
  });

  final LightcoreTournamentModeId mode;
  final String statusMessage;
  final String mechanicSummary;
  final LightcoreTournamentRewardPackage rewardPreview;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? groupId;
  final String? matchBucketLabel;
  final int groupSize;
  final int capacity;
  final int playerBestScore;
  final int? playerRank;
  final bool joined;
  final bool isOpen;
  final bool rewardReady;
  final bool rewardClaimed;
  final int seedPowerIndex;
  final List<LightcoreTournamentLeaderboardEntry> leaderboard;

  bool get canStartRun => joined && isOpen;

  factory LightcoreTournamentModeState.fromMap(Map<String, dynamic> data) {
    return LightcoreTournamentModeState(
      mode: tournamentModeFromWireKey((data['mode'] as String?) ?? ''),
      statusMessage:
          (data['statusMessage'] as String?) ?? 'Queue is available.',
      mechanicSummary:
          (data['mechanicSummary'] as String?) ?? 'Weekly modifier active.',
      rewardPreview: LightcoreTournamentRewardPackage.fromMap(
        _coerceMap(data['rewardPreview']),
      ),
      startsAt:
          DateTime.tryParse((data['startsAt'] as String?) ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse((data['endsAt'] as String?) ?? '') ??
          DateTime.now(),
      groupId: data['groupId'] as String?,
      matchBucketLabel: data['matchBucketLabel'] as String?,
      groupSize: (data['groupSize'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 15,
      playerBestScore: (data['playerBestScore'] as num?)?.toInt() ?? 0,
      playerRank: (data['playerRank'] as num?)?.toInt(),
      joined: (data['joined'] as bool?) ?? false,
      isOpen: (data['isOpen'] as bool?) ?? true,
      rewardReady: (data['rewardReady'] as bool?) ?? false,
      rewardClaimed: (data['rewardClaimed'] as bool?) ?? false,
      seedPowerIndex: (data['seedPowerIndex'] as num?)?.toInt() ?? 1000,
      leaderboard: (_coerceList(data['leaderboard']))
          .map(LightcoreTournamentLeaderboardEntry.fromMap)
          .toList(growable: false),
    );
  }
}

class LightcoreTournamentOverview {
  const LightcoreTournamentOverview({
    required this.seasonKey,
    required this.seasonLabel,
    required this.startsAt,
    required this.endsAt,
    required this.globalTournamentRating,
    required this.activeExperienceMultiplier,
    required this.online,
    required this.statusMessage,
    required this.modes,
    this.activeExperienceBoostEndsAt,
  });

  final String seasonKey;
  final String seasonLabel;
  final DateTime startsAt;
  final DateTime endsAt;
  final int globalTournamentRating;
  final double activeExperienceMultiplier;
  final DateTime? activeExperienceBoostEndsAt;
  final bool online;
  final String statusMessage;
  final List<LightcoreTournamentModeState> modes;

  bool get hasActiveExperienceBoost =>
      activeExperienceMultiplier > 1.0 &&
      activeExperienceBoostEndsAt != null &&
      activeExperienceBoostEndsAt!.isAfter(DateTime.now());

  LightcoreTournamentModeState modeFor(LightcoreTournamentModeId mode) {
    return modes.firstWhere(
      (state) => state.mode == mode,
      orElse: () => LightcoreTournamentModeState(
        mode: mode,
        statusMessage: 'No weekly state returned.',
        mechanicSummary: mode.subtitle,
        rewardPreview: const LightcoreTournamentRewardPackage(
          flux: 0,
          tickets: 0,
          experienceMultiplier: 1.0,
          experienceBuffHours: 0,
        ),
        startsAt: DateTime.now(),
        endsAt: endsAt,
      ),
    );
  }

  factory LightcoreTournamentOverview.fromMap(Map<String, dynamic> data) {
    return LightcoreTournamentOverview(
      seasonKey: (data['seasonKey'] as String?) ?? 'season-unknown',
      seasonLabel: (data['seasonLabel'] as String?) ?? 'Weekly Tournament',
      startsAt:
          DateTime.tryParse((data['startsAt'] as String?) ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse((data['endsAt'] as String?) ?? '') ??
          DateTime.now(),
      globalTournamentRating:
          (data['globalTournamentRating'] as num?)?.toInt() ?? 1000,
      activeExperienceMultiplier:
          (data['activeExperienceMultiplier'] as num?)?.toDouble() ?? 1.0,
      activeExperienceBoostEndsAt: DateTime.tryParse(
        (data['activeExperienceBoostEndsAt'] as String?) ?? '',
      ),
      online: (data['online'] as bool?) ?? true,
      statusMessage:
          (data['statusMessage'] as String?) ??
          'Weekly tournament feed is online.',
      modes: (_coerceList(
        data['modes'],
      )).map(LightcoreTournamentModeState.fromMap).toList(growable: false),
    );
  }
}

class LightcoreTournamentClaimResult {
  const LightcoreTournamentClaimResult({
    required this.reward,
    required this.overview,
  });

  final LightcoreTournamentRewardPackage reward;
  final LightcoreTournamentOverview overview;

  factory LightcoreTournamentClaimResult.fromMap(Map<String, dynamic> data) {
    return LightcoreTournamentClaimResult(
      reward: LightcoreTournamentRewardPackage.fromMap(
        _coerceMap(data['reward']),
      ),
      overview: LightcoreTournamentOverview.fromMap(
        _coerceMap(data['overview']),
      ),
    );
  }
}

ManagerRarity? _managerRarityFromName(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final rarity in ManagerRarity.values) {
    if (rarity.name == value) {
      return rarity;
    }
  }
  return null;
}

PrototypeAffinity? _affinityFromName(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final affinity in PrototypeAffinity.values) {
    if (affinity.name == value) {
      return affinity;
    }
  }
  return null;
}

Map<String, dynamic> _coerceMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _coerceList(dynamic value) {
  if (value is List) {
    return value.map(_coerceMap).toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<String> _coerceStringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Object>()
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

Map<String, int> _coerceIntMap(dynamic value) {
  if (value is! Map) {
    return const <String, int>{};
  }
  return value.map((key, dynamic item) {
    final parsed = item is num ? item.toInt() : int.tryParse('$item') ?? 1;
    return MapEntry(key.toString(), parsed);
  });
}
