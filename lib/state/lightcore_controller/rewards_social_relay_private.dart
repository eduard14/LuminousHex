part of '../lightcore_controller.dart';

extension LightcoreControllerSocialRelayPrivate on LightcoreController {
  List<FriendRelayPiece> _ownedSharedRelayCorePieces() {
    final pieces =
        _layers
            .map((layer) {
              final powerScore =
                  (18 + (layer.core.level * 10) + ((layer.tier - 1) * 16)) *
                  (1 +
                      (layer.core.rangeUpgradeLevel * 0.08) +
                      (layer.core.fireSpeedUpgradeLevel * 0.1) +
                      (layer.core.queueLimitUpgradeLevel * 0.06) +
                      ((coreMultiShotCountForUpgradeLevel(
                                layer.core.multiShotUpgradeLevel,
                              ) -
                              1) *
                          0.3));
              return FriendRelayPiece(
                id: 'relay_core:${layer.id}',
                kind: FriendRelayPieceKind.core,
                title: '${layer.label} Core',
                ownerLabel: 'You',
                sourceLabel: layer.label,
                affinity: layer.core.affinity,
                level: layer.core.level,
                tier: layer.tier,
                powerScore: powerScore,
                projectileType: layer.core.projectileType,
                payloadType: layer.core.payloadType,
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.powerScore.compareTo(a.powerScore));
    return pieces;
  }

  List<FriendRelayPiece> _ownedSharedRelayTowerPieces() {
    final pieces = <FriendRelayPiece>[];
    for (final layer in _layers) {
      for (final tower in layer.slots) {
        if (!_slotCountsTowardRing(tower)) {
          continue;
        }
        final effectiveLevel = tower.config != null
            ? tower.level
            : max(1, tower.childCoreLevel ?? 1);
        final effectiveTier = tower.childLayerTier ?? layer.tier;
        final powerScore = _sharedRelayTowerScoreForSnapshot(
          tower,
          parentTier: layer.tier,
        );
        pieces.add(
          FriendRelayPiece(
            id: 'relay_tower:${layer.id}:${tower.slotIndex}',
            kind: FriendRelayPieceKind.outer,
            title:
                tower.config?.name ?? tower.childLayerName ?? 'Promoted Relay',
            ownerLabel: 'You',
            sourceLabel: '${layer.label} • Hex ${tower.slotIndex + 1}',
            affinity:
                tower.config?.affinity ??
                tower.childAffinity ??
                layer.core.affinity,
            level: effectiveLevel,
            tier: effectiveTier,
            powerScore: powerScore,
            projectileType:
                tower.projectileType ??
                tower.config?.defaultProjectileType ??
                tower.childProjectileType,
            payloadType:
                tower.payloadType ??
                tower.config?.defaultPayloadType ??
                tower.childPayloadType,
          ),
        );
      }
    }
    pieces.sort((a, b) => b.powerScore.compareTo(a.powerScore));
    return pieces;
  }

  double _sharedRelayTowerScoreForSnapshot(
    OuterTowerState tower, {
    required int parentTier,
  }) {
    final effectiveLevel = tower.config != null
        ? tower.level
        : max(1, tower.childCoreLevel ?? 1);
    final effectiveTier = tower.childLayerTier ?? parentTier;
    final basePower =
        tower.config?.basePower ??
        (9 + (effectiveLevel * 2.4) + ((effectiveTier - 1) * 4.5));
    final damageFactor = tower.isChildLayerNode
        ? _childTowerPowerMultiplier(tower.childPowerUpgradeBonus) *
              (tower.childFinalDamageMultiplier ?? 1.08) *
              (tower.childNormalDamageMultiplier ?? 1.06)
        : tower.powerFactor *
              tower.finalDamageFactor *
              tower.normalDamageFactor;
    return basePower *
        damageFactor.clamp(0.45, 4.2) *
        (1 + ((effectiveLevel - 1) * 0.16)) *
        (1 + ((effectiveTier - 1) * 0.2));
  }

  FriendRelayPiece? _sharedRelayCorePieceById(String id) {
    for (final piece in _ownedSharedRelayCorePieces()) {
      if (piece.id == id) {
        return piece;
      }
    }
    return null;
  }

  FriendRelayPiece? _sharedRelayTowerPieceById(String id) {
    for (final piece in _ownedSharedRelayTowerPieces()) {
      if (piece.id == id) {
        return piece;
      }
    }
    return null;
  }

  List<FriendRelayProfile> _buildMockFriendRelayProfiles() {
    const levelOffsets = <int>[-3, -1, 0, 1, 2, 4, -2, 3];
    const progressSeeds = <double>[
      0.18,
      0.44,
      0.62,
      0.28,
      0.73,
      0.54,
      0.37,
      0.81,
    ];
    const successSeeds = <double>[
      0.58,
      0.63,
      0.69,
      0.74,
      0.77,
      0.71,
      0.65,
      0.82,
    ];

    final playerLevel = overallLevel;
    final baseProfiles = List<FriendRelayProfile>.generate(
      _mockFriendNames.length,
      (index) {
        final level = max(1, playerLevel + levelOffsets[index]);
        final levelGap = (level - playerLevel).abs();
        final progress = progressSeeds[index];
        final success = (successSeeds[index] - (levelGap * 0.012)).clamp(
          0.42,
          0.96,
        );
        return FriendRelayProfile(
          playerId: 'mock_friend_$index',
          displayName: _mockFriendNames[index],
          level: level,
          levelGap: levelGap,
          progressToNextLevel: progress,
          successRating: success,
          sharedTower: _buildMockFriendRelayTower(
            displayName: _mockFriendNames[index],
            level: level,
            seed: index,
          ),
          withinLevelBand: levelGap <= friendRelayLevelBand,
          usingPlayerTower: false,
          personalContributionMultiplier: 1.0,
        );
      },
      growable: false,
    );

    final eligible =
        baseProfiles
            .where((profile) {
              return profile.withinLevelBand;
            })
            .toList(growable: false)
          ..sort((a, b) {
            final left =
                (a.successRating * 0.7) + (a.progressToNextLevel * 0.3);
            final right =
                (b.successRating * 0.7) + (b.progressToNextLevel * 0.3);
            return right.compareTo(left);
          });

    final appeal = sharedRelayTower.averagePowerScore <= 0
        ? 0.0
        : ((sharedRelayTower.averagePowerScore - 12) / 34).clamp(0.0, 1.0);
    final borrowerCount = !isSharedRelayComplete || eligible.isEmpty
        ? 0
        : max(1, (1 + (appeal * (eligible.length - 1))).round());
    final activeBorrowers = eligible
        .take(min(borrowerCount, eligible.length))
        .map((profile) => profile.playerId)
        .toSet();

    return baseProfiles
        .map((profile) {
          final using = activeBorrowers.contains(profile.playerId);
          return FriendRelayProfile(
            playerId: profile.playerId,
            displayName: profile.displayName,
            level: profile.level,
            levelGap: profile.levelGap,
            progressToNextLevel: profile.progressToNextLevel,
            successRating: profile.successRating,
            sharedTower: profile.sharedTower,
            withinLevelBand: profile.withinLevelBand,
            usingPlayerTower: using,
            personalContributionMultiplier: using
                ? _relayContributionMultiplier(profile)
                : 1.0,
          );
        })
        .toList(growable: false);
  }

  bool canClaimBattlePassRewardForPass(
    BattlePassProgress pass,
    int tierIndex,
    BattlePassTrack track,
  ) {
    final tiers = _battlePassTierDefinitions(pass);
    if (tierIndex < 0 || tierIndex >= tiers.length) {
      return false;
    }
    if (track == BattlePassTrack.premium && !pass.premiumUnlocked) {
      return false;
    }
    if (pass.progress < tiers[tierIndex].goal) {
      return false;
    }
    return !pass.claimedRewardKeys.contains(
      _battlePassClaimKey(tierIndex, track),
    );
  }

  int _stableSocialSeed(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash % max(1, _mockFriendNames.length);
  }

  FriendRelayTower _buildMockFriendRelayTower({
    required String displayName,
    required int level,
    required int seed,
  }) {
    final configs = TowerLibrary.all;
    final centerConfig = configs[(seed + level) % configs.length];
    final centerTier = 1 + (((level + seed) ~/ 4).clamp(0, 5));
    final center = FriendRelayPiece(
      id: 'mock_center:$seed',
      kind: FriendRelayPieceKind.core,
      title: '${centerConfig.name} Core',
      ownerLabel: displayName,
      sourceLabel: 'Shared core',
      affinity: centerConfig.affinity,
      level: max(1, level),
      tier: centerTier,
      powerScore:
          (22 + (level * 6.4) + ((centerTier - 1) * 12)) * (1 + (seed * 0.03)),
      projectileType: centerConfig.defaultProjectileType,
      payloadType: level >= payloadUnlockLayer
          ? centerConfig.defaultPayloadType
          : PayloadType.none,
    );

    final outerPieces = List<FriendRelayPiece?>.generate(slotCount, (index) {
      final config = configs[(seed + index) % configs.length];
      final tier = 1 + (((level + index) ~/ 5).clamp(0, 5));
      final pieceLevel = max(1, level - ((index + seed) % 3));
      return FriendRelayPiece(
        id: 'mock_outer:$seed:$index',
        kind: FriendRelayPieceKind.outer,
        title: config.name,
        ownerLabel: displayName,
        sourceLabel: 'Hex ${index + 1}',
        affinity: config.affinity,
        level: pieceLevel,
        tier: tier,
        powerScore:
            config.basePower *
            (1 + ((pieceLevel - 1) * 0.22)) *
            (1 + ((tier - 1) * 0.18)),
        projectileType: config.defaultProjectileType,
        payloadType: pieceLevel >= payloadUnlockLayer
            ? config.defaultPayloadType
            : PayloadType.none,
      );
    }, growable: false);

    return FriendRelayTower(center: center, outerPieces: outerPieces);
  }

  bool claimBattlePassReward(
    BattlePassType type,
    int tierIndex,
    BattlePassTrack track,
  ) {
    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    return claimBattlePassRewardForPass(
      _activeBattlePassFor(type),
      tierIndex,
      track,
    );
  }

  double _relayContributionMultiplier(FriendRelayProfile profile) {
    final engagement =
        (0.55 +
                (profile.progressToNextLevel * 0.2) +
                (profile.successRating * 0.25))
            .clamp(0.55, 1.0);
    return 1 + (0.05 * engagement);
  }

  double _guildRecruitPriority(FriendRelayProfile profile) =>
      (profile.successRating * 0.52) +
      (profile.progressToNextLevel * 0.22) +
      ((profile.sharedTower.averagePowerScore / 40).clamp(0.0, 1.0) * 0.26);

  GuildMemberSnapshot _buildPlayerGuildMember({
    required int slotIndex,
    required GuildMemberRole role,
  }) {
    return GuildMemberSnapshot(
      playerId: 'player_local',
      displayName: 'You',
      role: role,
      level: overallLevel,
      slotIndex: slotIndex,
      contributedTower: guildContributionTower,
      readiness: _localGuildReadiness(),
      isLocalPlayer: true,
      isOnline: true,
    );
  }

  GuildMemberSnapshot _buildGuildMemberFromProfile(
    FriendRelayProfile profile, {
    required int slotIndex,
    GuildMemberRole role = GuildMemberRole.member,
  }) {
    return GuildMemberSnapshot(
      playerId: profile.playerId,
      displayName: profile.displayName,
      role: role,
      level: profile.level,
      slotIndex: slotIndex,
      contributedTower: profile.sharedTower,
      readiness:
          ((profile.successRating * 0.62) +
                  (profile.progressToNextLevel * 0.38))
              .clamp(0.42, 0.98),
      isOnline: profile.successRating >= 0.66,
    );
  }

  double _localGuildReadiness() {
    final fillRatio = guildContributionTower.filledPieceCount / guildMemberCap;
    return (0.44 + (fillRatio * 0.34) + (overallLevelProgress * 0.22)).clamp(
      0.42,
      1.0,
    );
  }

  void _syncGuildPlayerContribution() {
    final currentGuild = _activeGuild;
    if (currentGuild == null) {
      return;
    }
    final playerIndex = currentGuild.members.indexWhere(
      (member) => member.isLocalPlayer,
    );
    if (playerIndex == -1) {
      return;
    }

    final existing = currentGuild.members[playerIndex];
    currentGuild.members[playerIndex] = _buildPlayerGuildMember(
      slotIndex: existing.slotIndex,
      role: existing.role,
    );
  }

  int? _nextOpenGuildSlot(GuildState guild) {
    for (var index = 0; index < guild.memberCap; index++) {
      if (guild.memberAtSlot(index) == null) {
        return index;
      }
    }
    return null;
  }

  String _normalizeGuildName(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^A-Za-z0-9 &-]'), '')
      .trim();

  void _appendGuildSystemMessage(String message) {
    _appendGuildChatMessage(
      authorLabel: 'System',
      message: message,
      isSystem: true,
    );
  }

  void _appendGuildChatMessage({
    required String authorLabel,
    required String message,
    bool isLocalPlayer = false,
    bool isSystem = false,
  }) {
    final currentGuild = _activeGuild;
    if (currentGuild == null) {
      return;
    }
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return;
    }

    _guildChatCounter += 1;
    currentGuild.chatMessages.add(
      GuildChatMessage(
        id: 'guild_chat_$_guildChatCounter',
        authorLabel: authorLabel,
        message: normalizedMessage,
        sentAtSeconds: elapsed,
        isLocalPlayer: isLocalPlayer,
        isSystem: isSystem,
      ),
    );
    if (currentGuild.chatMessages.length > 36) {
      currentGuild.chatMessages.removeRange(
        0,
        currentGuild.chatMessages.length - 36,
      );
    }
  }

  String _mockRecruitJoinLine(FriendRelayProfile recruit, int slotIndex) {
    final center = recruit.sharedTower.center;
    final towerLabel = center?.title ?? 'tower loadout';
    return 'Anchoring ${_guildSlotLabel(slotIndex)} with $towerLabel. Call if we need a swap.';
  }

  bool claimBattlePassRewardForPass(
    BattlePassProgress pass,
    int tierIndex,
    BattlePassTrack track,
  ) {
    if (!canClaimBattlePassRewardForPass(pass, tierIndex, track)) {
      return false;
    }

    final tier = _battlePassTierDefinitions(pass)[tierIndex];
    final reward = track == BattlePassTrack.free
        ? tier.freeReward
        : tier.premiumReward;
    _grantBattlePassReward(reward);
    pass.claimedRewardKeys.add(_battlePassClaimKey(tierIndex, track));
    _showBanner(
      '${pass.type.shortLabel} ${track.label.toLowerCase()} tier ${tierIndex + 1}: ${reward.label}.',
    );
    if (_tutorialStep == LightcoreTutorialStep.claimBattlePassReward) {
      _tutorialBattlePassRewardClaimed = true;
      _syncTutorialStep(showBanner: false);
    }
    _notifyNow();
    return true;
  }

  String _guildSlotLabel(int slotIndex) =>
      slotIndex == 0 ? 'the anchor' : 'Hex $slotIndex';

  List<GuildSuggestion> _buildMockGuildSuggestions() {
    if (!guildsEnabled) {
      return const <GuildSuggestion>[];
    }

    final recruits =
        friendRelayProfiles
            .where((profile) => profile.withinLevelBand)
            .toList(growable: false)
          ..sort((a, b) {
            final left = _guildRecruitPriority(a);
            final right = _guildRecruitPriority(b);
            return right.compareTo(left);
          });
    if (recruits.isEmpty) {
      return const <GuildSuggestion>[];
    }

    return _mockGuildSuggestionSeeds
        .map((seed) {
          final selectedIds = <String>{};
          final selected = <FriendRelayProfile>[];
          for (final offset in seed.recruitOffsets) {
            final profile = recruits[offset % recruits.length];
            if (selectedIds.add(profile.playerId)) {
              selected.add(profile);
            }
          }
          final leader = selected.isEmpty ? recruits.first : selected.first;
          final averagePower = selected.isEmpty
              ? 0.0
              : selected.fold<double>(
                      0,
                      (sum, profile) =>
                          sum + profile.sharedTower.averagePowerScore,
                    ) /
                    selected.length;
          return GuildSuggestion(
            id: seed.id,
            name: seed.name,
            motto: seed.motto,
            leaderLabel: leader.displayName,
            memberCount: selected.length,
            averageContributionPower: averagePower,
            activityLabel: seed.activityLabel,
            seedMemberIds: selected
                .map((profile) => profile.playerId)
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }

  void _initializeSharedRelayLoadout() {
    final corePieces = _ownedSharedRelayCorePieces();
    final towerPieces = _ownedSharedRelayTowerPieces();
    if (_sharedRelayCenterPieceId == null && corePieces.isNotEmpty) {
      _sharedRelayCenterPieceId = corePieces.first.id;
    }
    if (_sharedRelayOuterPieceIds.every((id) => id == null) &&
        towerPieces.isNotEmpty) {
      for (var index = 0; index < min(slotCount, towerPieces.length); index++) {
        _sharedRelayOuterPieceIds[index] = towerPieces[index].id;
      }
    }
  }
}
