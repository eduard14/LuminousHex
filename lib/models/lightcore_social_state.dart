import 'dart:math';

import 'lightcore_avatar.dart';

class LightcoreSocialLimits {
  const LightcoreSocialLimits._();

  static const int mentorLevelBand = 6;
  static const int activeMenteeBonusLimit = 6;
  static const int maxFriends = 30;
  static const int bossPullGiftAmount = 1;
}

class LightcoreSocialPlayer {
  const LightcoreSocialPlayer({
    required this.uid,
    required this.playerId,
    required this.displayName,
    required this.level,
    required this.progressToNextLevel,
    required this.performanceScore,
    this.mentorUid,
    this.withinLevelBand = false,
    this.bonusActive = false,
    this.towerStrength = 0,
    this.towerStrengthRank,
    this.towerStrengthRankedPlayers = 0,
    this.sharedRelayFilledPieceCount = 0,
    this.sharedRelayAveragePower = 0,
    this.avatar = LightcoreAvatarProfile.empty,
    this.lastActiveAt,
  });

  final String uid;
  final String playerId;
  final String displayName;
  final int level;
  final double progressToNextLevel;
  final double performanceScore;
  final String? mentorUid;
  final bool withinLevelBand;
  final bool bonusActive;
  final int towerStrength;
  final int? towerStrengthRank;
  final int towerStrengthRankedPlayers;
  final int sharedRelayFilledPieceCount;
  final double sharedRelayAveragePower;
  final LightcoreAvatarProfile avatar;
  final DateTime? lastActiveAt;

  String get levelLabel => 'AR $level';

  String get performanceLabel =>
      '${(performanceScore.clamp(0.0, 1.0) * 100).round()}% sync';

  String get sharedRelayLabel => sharedRelayFilledPieceCount > 0
      ? '$sharedRelayFilledPieceCount/7 tower'
      : 'Tower pending';

  LightcoreSocialPlayer copyWith({
    String? uid,
    String? playerId,
    String? displayName,
    int? level,
    double? progressToNextLevel,
    double? performanceScore,
    String? mentorUid,
    bool? withinLevelBand,
    bool? bonusActive,
    int? towerStrength,
    int? towerStrengthRank,
    int? towerStrengthRankedPlayers,
    int? sharedRelayFilledPieceCount,
    double? sharedRelayAveragePower,
    LightcoreAvatarProfile? avatar,
    DateTime? lastActiveAt,
  }) {
    return LightcoreSocialPlayer(
      uid: uid ?? this.uid,
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      performanceScore: performanceScore ?? this.performanceScore,
      mentorUid: mentorUid ?? this.mentorUid,
      withinLevelBand: withinLevelBand ?? this.withinLevelBand,
      bonusActive: bonusActive ?? this.bonusActive,
      towerStrength: towerStrength ?? this.towerStrength,
      towerStrengthRank: towerStrengthRank ?? this.towerStrengthRank,
      towerStrengthRankedPlayers:
          towerStrengthRankedPlayers ?? this.towerStrengthRankedPlayers,
      sharedRelayFilledPieceCount:
          sharedRelayFilledPieceCount ?? this.sharedRelayFilledPieceCount,
      sharedRelayAveragePower:
          sharedRelayAveragePower ?? this.sharedRelayAveragePower,
      avatar: avatar ?? this.avatar,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  factory LightcoreSocialPlayer.fromMap(Map<String, dynamic> data) {
    final fallbackId = _stringValue(data['uid'], fallback: 'unknown-player');
    return LightcoreSocialPlayer(
      uid: fallbackId,
      playerId: _stringValue(data['playerId'], fallback: fallbackId),
      displayName: _stringValue(
        data['displayName'],
        fallback: _stringValue(data['screenName'], fallback: fallbackId),
      ),
      level: _intValue(data['level'], fallback: 1).clamp(1, 1000000),
      progressToNextLevel: _doubleValue(
        data['progressToNextLevel'],
      ).clamp(0.0, 1.0),
      performanceScore: _doubleValue(data['performanceScore']).clamp(0.0, 1.0),
      mentorUid: _nullableString(data['mentorUid']),
      withinLevelBand: data['withinLevelBand'] == true,
      bonusActive: data['bonusActive'] == true,
      towerStrength: _intValue(data['towerStrength']),
      towerStrengthRank: _nullableInt(data['towerStrengthRank']),
      towerStrengthRankedPlayers: _intValue(data['towerStrengthRankedPlayers']),
      sharedRelayFilledPieceCount: _intValue(
        data['sharedRelayFilledPieceCount'],
      ).clamp(0, 7),
      sharedRelayAveragePower: _doubleValue(data['sharedRelayAveragePower']),
      avatar: LightcoreAvatarProfile.fromMap(_mapValue(data['avatar'])),
      lastActiveAt: _dateFromValue(data['lastActiveAt']),
    );
  }
}

enum LightcoreSocialInviteKind { mentor, friend }

enum LightcoreSocialInviteDirection { incoming, outgoing }

class LightcoreSocialInvite {
  const LightcoreSocialInvite({
    required this.id,
    required this.kind,
    required this.direction,
    required this.fromPlayer,
    required this.toPlayer,
    this.createdAt,
  });

  final String id;
  final LightcoreSocialInviteKind kind;
  final LightcoreSocialInviteDirection direction;
  final LightcoreSocialPlayer fromPlayer;
  final LightcoreSocialPlayer toPlayer;
  final DateTime? createdAt;

  LightcoreSocialPlayer get otherPlayer =>
      direction == LightcoreSocialInviteDirection.incoming
      ? fromPlayer
      : toPlayer;

  factory LightcoreSocialInvite.fromMap(Map<String, dynamic> data) {
    return LightcoreSocialInvite(
      id: _stringValue(data['id'], fallback: 'invite'),
      kind: switch (_stringValue(data['kind'], fallback: 'friend')) {
        'mentor' => LightcoreSocialInviteKind.mentor,
        _ => LightcoreSocialInviteKind.friend,
      },
      direction: switch (_stringValue(
        data['direction'],
        fallback: 'incoming',
      )) {
        'outgoing' => LightcoreSocialInviteDirection.outgoing,
        _ => LightcoreSocialInviteDirection.incoming,
      },
      fromPlayer: LightcoreSocialPlayer.fromMap(_mapValue(data['fromPlayer'])),
      toPlayer: LightcoreSocialPlayer.fromMap(_mapValue(data['toPlayer'])),
      createdAt: _dateFromValue(data['createdAt']),
    );
  }
}

class LightcoreSocialFriend {
  const LightcoreSocialFriend({
    required this.player,
    required this.giftSentToday,
    required this.giftAvailable,
    required this.giftClaimedToday,
    this.incomingGiftId,
  });

  final LightcoreSocialPlayer player;
  final bool giftSentToday;
  final bool giftAvailable;
  final bool giftClaimedToday;
  final String? incomingGiftId;

  String get giftStatusLabel {
    if (giftAvailable) {
      return 'Threat Scan waiting';
    }
    if (giftSentToday && giftClaimedToday) {
      return 'Exchanged today';
    }
    if (giftSentToday) {
      return 'Sent today';
    }
    if (giftClaimedToday) {
      return 'Claimed today';
    }
    return 'Ready today';
  }

  factory LightcoreSocialFriend.fromMap(Map<String, dynamic> data) {
    return LightcoreSocialFriend(
      player: LightcoreSocialPlayer.fromMap(_mapValue(data['player'])),
      giftSentToday: data['giftSentToday'] == true,
      giftAvailable: data['giftAvailable'] == true,
      giftClaimedToday: data['giftClaimedToday'] == true,
      incomingGiftId: _nullableString(data['incomingGiftId']),
    );
  }
}

class LightcoreSocialBonusProfile {
  const LightcoreSocialBonusProfile({
    this.experienceMultiplier = 1.0,
    this.combatMultiplier = 1.0,
    this.rewardMultiplier = 1.0,
    this.activeDirectMentees = 0,
    this.activeGrandMentees = 0,
    this.capped = false,
  });

  final double experienceMultiplier;
  final double combatMultiplier;
  final double rewardMultiplier;
  final int activeDirectMentees;
  final int activeGrandMentees;
  final bool capped;

  static const zero = LightcoreSocialBonusProfile();

  String get experienceLabel =>
      'x${experienceMultiplier.toStringAsFixed(2)} EXP';

  String get combatLabel => 'x${combatMultiplier.toStringAsFixed(2)} combat';

  String get rewardLabel => 'x${rewardMultiplier.toStringAsFixed(2)} rewards';

  factory LightcoreSocialBonusProfile.fromMap(Map<String, dynamic> data) {
    return LightcoreSocialBonusProfile(
      experienceMultiplier: max(
        1.0,
        _doubleValue(data['experienceMultiplier']),
      ),
      combatMultiplier: max(1.0, _doubleValue(data['combatMultiplier'])),
      rewardMultiplier: max(1.0, _doubleValue(data['rewardMultiplier'])),
      activeDirectMentees: _intValue(data['activeDirectMentees']),
      activeGrandMentees: _intValue(data['activeGrandMentees']),
      capped: data['capped'] == true,
    );
  }
}

class LightcoreSocialOverview {
  const LightcoreSocialOverview({
    required this.self,
    this.mentor,
    this.directMentees = const <LightcoreSocialPlayer>[],
    this.grandMentees = const <LightcoreSocialPlayer>[],
    this.friends = const <LightcoreSocialFriend>[],
    this.invites = const <LightcoreSocialInvite>[],
    this.globalTowerStrengthLeaderboard = const <LightcoreSocialPlayer>[],
    this.bonusProfile = LightcoreSocialBonusProfile.zero,
    this.dailyResetKey = '',
    this.nextDailyResetAt,
    this.levelBand = LightcoreSocialLimits.mentorLevelBand,
    this.activeMenteeBonusLimit = LightcoreSocialLimits.activeMenteeBonusLimit,
    this.maxFriends = LightcoreSocialLimits.maxFriends,
  });

  final LightcoreSocialPlayer self;
  final LightcoreSocialPlayer? mentor;
  final List<LightcoreSocialPlayer> directMentees;
  final List<LightcoreSocialPlayer> grandMentees;
  final List<LightcoreSocialFriend> friends;
  final List<LightcoreSocialInvite> invites;
  final List<LightcoreSocialPlayer> globalTowerStrengthLeaderboard;
  final LightcoreSocialBonusProfile bonusProfile;
  final String dailyResetKey;
  final DateTime? nextDailyResetAt;
  final int levelBand;
  final int activeMenteeBonusLimit;
  final int maxFriends;

  int get pendingInviteCount => invites
      .where(
        (invite) => invite.direction == LightcoreSocialInviteDirection.incoming,
      )
      .length;

  int get availableBossGiftCount =>
      friends.where((friend) => friend.giftAvailable).length;

  int get sendableBossGiftCount =>
      friends.where((friend) => !friend.giftSentToday).length;

  List<LightcoreSocialPlayer> childrenOf(String uid) {
    final direct = directMentees
        .where((player) => player.mentorUid == uid)
        .toList(growable: false);
    if (direct.isNotEmpty) {
      return direct;
    }
    return grandMentees
        .where((player) => player.mentorUid == uid)
        .toList(growable: false);
  }

  List<LightcoreSocialPlayer> grandchildrenOf(String uid) {
    final directChildIds = childrenOf(uid).map((player) => player.uid).toSet();
    if (directChildIds.isEmpty) {
      return const <LightcoreSocialPlayer>[];
    }
    return grandMentees
        .where((player) => directChildIds.contains(player.mentorUid))
        .toList(growable: false);
  }

  factory LightcoreSocialOverview.fromMap(Map<String, dynamic> data) {
    return LightcoreSocialOverview(
      self: LightcoreSocialPlayer.fromMap(_mapValue(data['self'])),
      mentor: _optionalPlayer(data['mentor']),
      directMentees: _playerList(data['directMentees']),
      grandMentees: _playerList(data['grandMentees']),
      friends: _listValue(data['friends'])
          .map((item) => LightcoreSocialFriend.fromMap(_mapValue(item)))
          .toList(growable: false),
      invites: _listValue(data['invites'])
          .map((item) => LightcoreSocialInvite.fromMap(_mapValue(item)))
          .toList(growable: false),
      globalTowerStrengthLeaderboard: _playerList(
        data['globalTowerStrengthLeaderboard'],
      ),
      bonusProfile: LightcoreSocialBonusProfile.fromMap(
        _mapValue(data['bonusProfile']),
      ),
      dailyResetKey: _stringValue(data['dailyResetKey']),
      nextDailyResetAt: _dateFromValue(data['nextDailyResetAt']),
      levelBand: _intValue(
        data['levelBand'],
        fallback: LightcoreSocialLimits.mentorLevelBand,
      ),
      activeMenteeBonusLimit: _intValue(
        data['activeMenteeBonusLimit'],
        fallback: LightcoreSocialLimits.activeMenteeBonusLimit,
      ),
      maxFriends: _intValue(
        data['maxFriends'],
        fallback: LightcoreSocialLimits.maxFriends,
      ),
    );
  }
}

class LightcoreBossGiftClaimResult {
  const LightcoreBossGiftClaimResult({
    required this.bossTicketsGranted,
    required this.message,
    required this.overview,
  });

  final int bossTicketsGranted;
  final String message;
  final LightcoreSocialOverview overview;

  factory LightcoreBossGiftClaimResult.fromMap(Map<String, dynamic> data) {
    return LightcoreBossGiftClaimResult(
      bossTicketsGranted: _intValue(data['bossTicketsGranted']),
      message: _stringValue(data['message']),
      overview: LightcoreSocialOverview.fromMap(_mapValue(data['overview'])),
    );
  }
}

class LightcoreBossGiftSendResult {
  const LightcoreBossGiftSendResult({
    required this.sentCount,
    required this.skippedCount,
    required this.message,
    required this.overview,
  });

  final int sentCount;
  final int skippedCount;
  final String message;
  final LightcoreSocialOverview overview;

  factory LightcoreBossGiftSendResult.fromMap(Map<String, dynamic> data) {
    return LightcoreBossGiftSendResult(
      sentCount: _intValue(data['sentCount']),
      skippedCount: _intValue(data['skippedCount']),
      message: _stringValue(data['message']),
      overview: LightcoreSocialOverview.fromMap(_mapValue(data['overview'])),
    );
  }
}

LightcoreSocialPlayer? _optionalPlayer(dynamic value) {
  final data = _mapValue(value);
  if (data.isEmpty) {
    return null;
  }
  return LightcoreSocialPlayer.fromMap(data);
}

List<LightcoreSocialPlayer> _playerList(dynamic value) => _listValue(value)
    .map((item) => LightcoreSocialPlayer.fromMap(_mapValue(item)))
    .toList(growable: false);

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, dynamic item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<dynamic> _listValue(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return fallback;
  }
  return text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  return _intValue(value);
}

double _doubleValue(dynamic value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _dateFromValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  final parsed = DateTime.tryParse(value.toString());
  if (parsed != null) {
    return parsed;
  }
  try {
    final dynamic dynamicValue = value;
    final dynamic date = dynamicValue.toDate();
    if (date is DateTime) {
      return date;
    }
  } catch (_) {
    return null;
  }
  return null;
}
