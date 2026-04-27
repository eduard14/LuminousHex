import 'lightcore_friend_state.dart';

enum GuildMemberRole { leader, member }

extension GuildMemberRoleX on GuildMemberRole {
  String get label => switch (this) {
    GuildMemberRole.leader => 'Leader',
    GuildMemberRole.member => 'Member',
  };
}

class GuildMemberSnapshot {
  const GuildMemberSnapshot({
    required this.playerId,
    required this.displayName,
    required this.role,
    required this.level,
    required this.slotIndex,
    required this.contributedTower,
    required this.readiness,
    this.isLocalPlayer = false,
    this.isOnline = false,
  });

  final String playerId;
  final String displayName;
  final GuildMemberRole role;
  final int level;
  final int slotIndex;
  final FriendRelayTower contributedTower;
  final double readiness;
  final bool isLocalPlayer;
  final bool isOnline;

  String get slotLabel => slotIndex == 0 ? 'Anchor' : 'Hex $slotIndex';

  int get contributionPieceCount => contributedTower.filledPieceCount;

  double get contributionPowerScore {
    final base = contributedTower.averagePowerScore <= 0
        ? contributionPieceCount.toDouble()
        : contributedTower.averagePowerScore;
    return base * (0.9 + (readiness * 0.24));
  }

  String get readinessLabel =>
      '${(readiness * 100).toStringAsFixed(0)}% synced';
}

class GuildChatMessage {
  const GuildChatMessage({
    required this.id,
    required this.authorLabel,
    required this.message,
    required this.sentAtSeconds,
    this.isLocalPlayer = false,
    this.isSystem = false,
  });

  final String id;
  final String authorLabel;
  final String message;
  final double sentAtSeconds;
  final bool isLocalPlayer;
  final bool isSystem;
}

class GuildState {
  const GuildState({
    required this.id,
    required this.name,
    required this.motto,
    required this.memberCap,
    required this.members,
    required this.chatMessages,
  });

  final String id;
  final String name;
  final String motto;
  final int memberCap;
  final List<GuildMemberSnapshot> members;
  final List<GuildChatMessage> chatMessages;

  GuildMemberSnapshot? memberAtSlot(int slotIndex) {
    for (final member in members) {
      if (member.slotIndex == slotIndex) {
        return member;
      }
    }
    return null;
  }

  GuildMemberSnapshot? get leader {
    for (final member in members) {
      if (member.role == GuildMemberRole.leader) {
        return member;
      }
    }
    return members.isEmpty ? null : members.first;
  }

  int get filledContributionCount => members
      .where((member) => member.contributedTower.filledPieceCount > 0)
      .length;

  int get openSlotCount =>
      memberCap > members.length ? memberCap - members.length : 0;

  bool get isTowerComplete => filledContributionCount >= memberCap;

  double get averageContributionPower {
    if (members.isEmpty) {
      return 0;
    }
    final total = members.fold<double>(
      0,
      (sum, member) => sum + member.contributionPowerScore,
    );
    return total / members.length;
  }
}

class GuildSuggestion {
  const GuildSuggestion({
    required this.id,
    required this.name,
    required this.motto,
    required this.leaderLabel,
    required this.memberCount,
    required this.averageContributionPower,
    required this.activityLabel,
    required this.seedMemberIds,
  });

  final String id;
  final String name;
  final String motto;
  final String leaderLabel;
  final int memberCount;
  final double averageContributionPower;
  final String activityLabel;
  final List<String> seedMemberIds;

  int get openSlots => memberCount >= 7 ? 0 : 7 - memberCount;
}
