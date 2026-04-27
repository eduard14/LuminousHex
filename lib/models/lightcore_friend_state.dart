import 'lightcore_types.dart';

enum FriendRelayPieceKind { core, outer }

class FriendContact {
  const FriendContact({
    required this.playerId,
    required this.displayName,
    required this.level,
    required this.progressToNextLevel,
    required this.baseSuccessRating,
    required this.towerSeed,
  });

  final String playerId;
  final String displayName;
  final int level;
  final double progressToNextLevel;
  final double baseSuccessRating;
  final int towerSeed;

  FriendContact copyWith({
    String? playerId,
    String? displayName,
    int? level,
    double? progressToNextLevel,
    double? baseSuccessRating,
    int? towerSeed,
  }) {
    return FriendContact(
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      baseSuccessRating: baseSuccessRating ?? this.baseSuccessRating,
      towerSeed: towerSeed ?? this.towerSeed,
    );
  }
}

class FriendRelayPiece {
  const FriendRelayPiece({
    required this.id,
    required this.kind,
    required this.title,
    required this.ownerLabel,
    required this.sourceLabel,
    required this.affinity,
    required this.level,
    required this.tier,
    required this.powerScore,
    this.projectileType,
    this.payloadType,
  });

  final String id;
  final FriendRelayPieceKind kind;
  final String title;
  final String ownerLabel;
  final String sourceLabel;
  final PrototypeAffinity affinity;
  final int level;
  final int tier;
  final double powerScore;
  final ProjectileType? projectileType;
  final PayloadType? payloadType;

  String get slotLabel => kind == FriendRelayPieceKind.core ? 'Core' : 'Outer';

  String get summary {
    final parts = <String>[
      '${affinity.label} • L$level',
      'T$tier',
      if (projectileType != null) projectileType!.label,
      if (payloadType != null && payloadType != PayloadType.none)
        payloadType!.label,
    ];
    return parts.join(' • ');
  }
}

class FriendRelayTower {
  const FriendRelayTower({
    this.center,
    this.outerPieces = const <FriendRelayPiece?>[],
  });

  final FriendRelayPiece? center;
  final List<FriendRelayPiece?> outerPieces;

  bool get isComplete =>
      center != null &&
      outerPieces.length == 6 &&
      outerPieces.every((piece) => piece != null);

  int get filledPieceCount =>
      (center == null ? 0 : 1) +
      outerPieces.whereType<FriendRelayPiece>().length;

  double get averagePowerScore {
    final pieces = <FriendRelayPiece>[
      ?center,
      ...outerPieces.whereType<FriendRelayPiece>(),
    ];
    if (pieces.isEmpty) {
      return 0;
    }
    final total = pieces.fold<double>(
      0,
      (sum, piece) => sum + piece.powerScore,
    );
    return total / pieces.length;
  }
}

class FriendRelayProfile {
  const FriendRelayProfile({
    required this.playerId,
    required this.displayName,
    required this.level,
    required this.levelGap,
    required this.progressToNextLevel,
    required this.successRating,
    required this.sharedTower,
    required this.withinLevelBand,
    required this.usingPlayerTower,
    required this.personalContributionMultiplier,
  });

  final String playerId;
  final String displayName;
  final int level;
  final int levelGap;
  final double progressToNextLevel;
  final double successRating;
  final FriendRelayTower sharedTower;
  final bool withinLevelBand;
  final bool usingPlayerTower;
  final double personalContributionMultiplier;

  String get progressLabel =>
      '${(progressToNextLevel * 100).toStringAsFixed(0)}% to next level';

  String get successLabel =>
      '${(successRating * 100).toStringAsFixed(0)}% success';
}
