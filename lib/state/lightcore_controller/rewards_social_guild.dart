part of '../lightcore_controller.dart';

extension LightcoreControllerSocialGuild on LightcoreController {
  String? get sharedRelayCenterPieceId => _sharedRelayCenterPieceId;

  String? sharedRelayOuterPieceId(int index) {
    if (index < 0 || index >= _sharedRelayOuterPieceIds.length) {
      return null;
    }
    return _sharedRelayOuterPieceIds[index];
  }

  FriendRelayTower get sharedRelayTower => FriendRelayTower(
    center: _sharedRelayCenterPieceId == null
        ? null
        : _sharedRelayCorePieceById(_sharedRelayCenterPieceId!),
    outerPieces: List<FriendRelayPiece?>.generate(slotCount, (index) {
      final id = _sharedRelayOuterPieceIds[index];
      return id == null ? null : _sharedRelayTowerPieceById(id);
    }, growable: false),
  );

  bool get isSharedRelayComplete => sharedRelayTower.isComplete;

  int get sharedRelayFilledPieceCount => sharedRelayTower.filledPieceCount;

  bool get guildsEnabled => _guildsEnabled;

  int get guildCreationUnlockLevel => _guildCreationUnlockLevel;

  LightcoreBalanceTuning get balanceTuning => _balanceTuning;

  void syncBalanceTuning(
    LightcoreBalanceTuning tuning, {
    bool showBanner = false,
  }) {
    final previousEpoch = _balanceTuning.balanceEpoch;
    final previousActive = _balanceTuning.active;
    _balanceTuning = tuning;
    if (showBanner &&
        tuning.hasOverrides &&
        (previousEpoch != tuning.balanceEpoch ||
            previousActive != tuning.active)) {
      _showBanner('Balance epoch ${tuning.balanceEpoch} synced.');
    }
    _updateFlowEfficiency();
    _notifyNow();
  }

  bool get guildsUnlocked =>
      guildsEnabled && overallLevel >= guildCreationUnlockLevel;

  int get guildLevelsRemaining =>
      max(0, guildCreationUnlockLevel - overallLevel);

  double get guildUnlockProgress {
    if (!guildsEnabled) {
      return 0;
    }
    if (guildsUnlocked) {
      return 1.0;
    }
    return (overallLevel / guildCreationUnlockLevel).clamp(0.0, 1.0);
  }

  GuildState? get activeGuild {
    if (!guildsEnabled) {
      return null;
    }
    _syncGuildPlayerContribution();
    return _activeGuild;
  }

  bool get hasGuild => activeGuild != null;

  FriendRelayTower get guildContributionTower => sharedRelayTower;

  List<FriendRelayProfile> get friendRelayProfiles {
    final overview = _socialOverview;
    if (overview != null) {
      return _buildSocialFriendRelayProfiles(overview);
    }
    return _buildMockFriendRelayProfiles();
  }

  List<FriendRelayProfile> get guildRecruitCandidates {
    final currentGuild = activeGuild;
    final reservedIds = currentGuild == null
        ? const <String>{}
        : currentGuild.members.map((member) => member.playerId).toSet();
    return friendRelayProfiles
        .where((profile) => profile.withinLevelBand)
        .where((profile) => !reservedIds.contains(profile.playerId))
        .toList(growable: false)
      ..sort((a, b) {
        final left = _guildRecruitPriority(a);
        final right = _guildRecruitPriority(b);
        return right.compareTo(left);
      });
  }

  List<GuildSuggestion> get guildSuggestions => _buildMockGuildSuggestions();

  int get guildMemberCount => activeGuild?.members.length ?? 0;

  int get guildOpenSlotCount =>
      max(0, guildMemberCap - (activeGuild?.members.length ?? 0));

  double get guildContributionCompleteness {
    final currentGuild = activeGuild;
    if (currentGuild == null || currentGuild.memberCap <= 0) {
      return 0;
    }
    return (currentGuild.filledContributionCount / currentGuild.memberCap)
        .clamp(0.0, 1.0);
  }

  double get guildAverageReadiness {
    final currentGuild = activeGuild;
    if (currentGuild == null || currentGuild.members.isEmpty) {
      return 0;
    }
    final total = currentGuild.members.fold<double>(
      0,
      (sum, member) => sum + member.readiness,
    );
    return total / currentGuild.members.length;
  }

  double get guildAverageContributionPower =>
      activeGuild?.averageContributionPower ?? 0;

  double get guildExperienceMultiplier {
    final currentGuild = activeGuild;
    if (currentGuild == null || currentGuild.members.isEmpty) {
      return 1.0;
    }
    final readiness = guildAverageReadiness.clamp(0.0, 1.0);
    return (1 + (guildContributionCompleteness * readiness * 0.48)).clamp(
      1.0,
      1.75,
    );
  }

  double get guildCombatMultiplier {
    final currentGuild = activeGuild;
    if (currentGuild == null || currentGuild.members.isEmpty) {
      return 1.0;
    }
    final powerFactor = (guildAverageContributionPower / 40).clamp(0.18, 1.0);
    return 1 + (guildContributionCompleteness * powerFactor * 0.22);
  }

  double get guildRewardMultiplier {
    final currentGuild = activeGuild;
    if (currentGuild == null || currentGuild.members.isEmpty) {
      return 1.0;
    }
    final readiness = guildAverageReadiness.clamp(0.0, 1.0);
    final openPressure = currentGuild.openSlotCount <= 0
        ? 1.0
        : (currentGuild.members.length / currentGuild.memberCap).clamp(
            0.0,
            1.0,
          );
    return 1 +
        (guildContributionCompleteness *
            ((readiness * 0.1) + (openPressure * 0.1)));
  }

  int get relayEligibleFriendCount =>
      friendRelayProfiles.where((profile) => profile.withinLevelBand).length;

  int get relayActiveBorrowerCount => friendRelayProfiles
      .where((profile) => profile.withinLevelBand && profile.usingPlayerTower)
      .length;

  PrototypeAffinity? get homeTowerAffinity =>
      _dominantTowerAffinityForLayer(homeTowerLayer);

  String get homeTowerLabel {
    final affinity = homeTowerAffinity;
    if (affinity == null) {
      return 'Home Tower forming';
    }
    return '${affinity.label} Home Tower';
  }

  double get homeTowerMentorExperienceMultiplier {
    final affinity = homeTowerAffinity;
    if (affinity == null) {
      return 1.0;
    }
    return (1 +
            (_homeTowerMentorBaseBonus * _homeTowerExperienceWeight(affinity)))
        .clamp(1.0, 1.35)
        .toDouble();
  }

  double get homeTowerMentorCombatMultiplier {
    final affinity = homeTowerAffinity;
    if (affinity == null) {
      return 1.0;
    }
    return (1 + (_homeTowerMentorBaseBonus * _homeTowerCombatWeight(affinity)))
        .clamp(1.0, 1.25)
        .toDouble();
  }

  double get homeTowerMentorRewardMultiplier {
    final affinity = homeTowerAffinity;
    if (affinity == null) {
      return 1.0;
    }
    return (1 + (_homeTowerMentorBaseBonus * _homeTowerRewardWeight(affinity)))
        .clamp(1.0, 1.2)
        .toDouble();
  }

  String get homeTowerMentorBonusLabel =>
      'EXP x${homeTowerMentorExperienceMultiplier.toStringAsFixed(2)}  •  Combat x${homeTowerMentorCombatMultiplier.toStringAsFixed(2)}  •  Rewards x${homeTowerMentorRewardMultiplier.toStringAsFixed(2)}';

  double get sharedRelayExperienceMultiplier {
    final socialMultiplier = _socialOverview?.bonusProfile.experienceMultiplier;
    double base;
    if (socialMultiplier != null) {
      base = hasGuild
          ? max(guildExperienceMultiplier, socialMultiplier)
          : socialMultiplier;
    } else if (hasGuild) {
      base = guildExperienceMultiplier;
    } else {
      var multiplier = 1.0;
      for (final profile in friendRelayProfiles) {
        if (!profile.withinLevelBand || !profile.usingPlayerTower) {
          continue;
        }
        multiplier *= profile.personalContributionMultiplier;
        if (multiplier >= 2) {
          base = 2.0;
          return (base * homeTowerMentorExperienceMultiplier)
              .clamp(1.0, 2.0)
              .toDouble();
        }
      }
      base = multiplier;
    }
    return (base * homeTowerMentorExperienceMultiplier)
        .clamp(1.0, 2.0)
        .toDouble();
  }

  FriendRelayTower get friendAllianceTower =>
      _buildFriendAllianceTower(friendRelayProfiles);

  double get friendAllianceCombatMultiplier {
    final socialMultiplier = _socialOverview?.bonusProfile.combatMultiplier;
    double base;
    if (socialMultiplier != null) {
      base = hasGuild
          ? max(guildCombatMultiplier, socialMultiplier)
          : socialMultiplier;
    } else if (hasGuild) {
      base = guildCombatMultiplier;
    } else {
      final tower = friendAllianceTower;
      if (tower.filledPieceCount == 0) {
        return homeTowerMentorCombatMultiplier;
      }
      final members = friendRelayProfiles
          .where((profile) {
            return profile.withinLevelBand;
          })
          .toList(growable: false);
      if (members.isEmpty) {
        return homeTowerMentorCombatMultiplier;
      }
      final completeness = tower.filledPieceCount / (slotCount + 1);
      final resonance =
          members.fold<double>(
            0,
            (sum, profile) =>
                sum +
                ((profile.successRating * 0.58) +
                    (profile.progressToNextLevel * 0.42)),
          ) /
          members.length;
      base = 1 + (completeness * resonance * 0.18);
    }
    return (base * homeTowerMentorCombatMultiplier).clamp(1.0, 2.0).toDouble();
  }

  double get friendAllianceRewardMultiplier {
    final socialMultiplier = _socialOverview?.bonusProfile.rewardMultiplier;
    double base;
    if (socialMultiplier != null) {
      base = hasGuild
          ? max(guildRewardMultiplier, socialMultiplier)
          : socialMultiplier;
    } else if (hasGuild) {
      base = guildRewardMultiplier;
    } else {
      final tower = friendAllianceTower;
      if (tower.filledPieceCount == 0) {
        return homeTowerMentorRewardMultiplier;
      }
      final completeness = tower.filledPieceCount / (slotCount + 1);
      final borrowers = relayActiveBorrowerCount;
      final borrowPressure = relayEligibleFriendCount == 0
          ? 0
          : borrowers / relayEligibleFriendCount;
      base = 1 + (completeness * (0.06 + (borrowPressure * 0.08)));
    }
    return (base * homeTowerMentorRewardMultiplier).clamp(1.0, 2.0).toDouble();
  }

  bool setSharedRelayCenterPiece(String? pieceId) {
    if (pieceId != null && _sharedRelayCorePieceById(pieceId) == null) {
      return false;
    }
    if (_sharedRelayCenterPieceId == pieceId) {
      return false;
    }
    _sharedRelayCenterPieceId = pieceId;
    _syncGuildPlayerContribution();
    _notifyNow();
    return true;
  }

  bool setSharedRelayOuterPiece(int index, String? pieceId) {
    if (index < 0 || index >= _sharedRelayOuterPieceIds.length) {
      return false;
    }
    if (pieceId != null && _sharedRelayTowerPieceById(pieceId) == null) {
      return false;
    }
    if (pieceId != null) {
      final existingIndex = _sharedRelayOuterPieceIds.indexOf(pieceId);
      if (existingIndex != -1 && existingIndex != index) {
        _sharedRelayOuterPieceIds[existingIndex] = null;
      }
    }
    if (_sharedRelayOuterPieceIds[index] == pieceId) {
      return false;
    }
    _sharedRelayOuterPieceIds[index] = pieceId;
    _syncGuildPlayerContribution();
    _notifyNow();
    return true;
  }

  void clearSharedRelayTower() {
    _sharedRelayCenterPieceId = null;
    _sharedRelayOuterPieceIds = List<String?>.filled(slotCount, null);
    _syncGuildPlayerContribution();
    _notifyNow();
  }

  void autoFillSharedRelayTower() {
    final corePieces = _ownedSharedRelayCorePieces();
    final towerPieces = _ownedSharedRelayTowerPieces();
    _sharedRelayCenterPieceId = corePieces.isEmpty ? null : corePieces.first.id;
    _sharedRelayOuterPieceIds = List<String?>.filled(slotCount, null);
    for (var index = 0; index < min(slotCount, towerPieces.length); index++) {
      _sharedRelayOuterPieceIds[index] = towerPieces[index].id;
    }
    _syncGuildPlayerContribution();
    _notifyNow();
  }

  bool createGuild(String name) {
    if (!guildsEnabled) {
      _showBanner('Guild services are offline in the current manifest.');
      _notifyNow();
      return false;
    }
    if (!guildsUnlocked) {
      _showBanner(
        'Guilds unlock at Account Radiance Lv $guildCreationUnlockLevel.',
      );
      _notifyNow();
      return false;
    }
    if (_activeGuild != null) {
      _showBanner('Leave your current guild before founding a new one.');
      _notifyNow();
      return false;
    }

    final normalizedName = _normalizeGuildName(name);
    if (normalizedName.length < 3) {
      _showBanner('Guild names need at least 3 visible characters.');
      _notifyNow();
      return false;
    }

    _activeGuild = GuildState(
      id: 'guild_${normalizedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
      name: normalizedName,
      motto: 'One tower per member. Fill the ring before the push.',
      memberCap: guildMemberCap,
      members: <GuildMemberSnapshot>[
        _buildPlayerGuildMember(slotIndex: 0, role: GuildMemberRole.leader),
      ],
      chatMessages: <GuildChatMessage>[],
    );
    _guildChatCounter = 0;
    _appendGuildSystemMessage(
      '$normalizedName formed. Each member contributes one full tower to the guild spire.',
    );
    _appendGuildSystemMessage(
      'Guild chat is live. Coordinate empty slots before the next Apex cycle.',
    );
    _showBanner(
      '$normalizedName founded. Recruit members to raise the shared spire.',
    );
    _notifyNow();
    return true;
  }

  bool joinGuildSuggestion(GuildSuggestion suggestion) {
    if (!guildsEnabled) {
      _showBanner('Guild services are offline in the current manifest.');
      _notifyNow();
      return false;
    }
    if (!guildsUnlocked) {
      _showBanner(
        'Guilds unlock at Account Radiance Lv $guildCreationUnlockLevel.',
      );
      _notifyNow();
      return false;
    }
    if (_activeGuild != null) {
      _showBanner('Leave your current guild before joining another one.');
      _notifyNow();
      return false;
    }

    final profilesById = {
      for (final profile in friendRelayProfiles) profile.playerId: profile,
    };
    final seededProfiles = suggestion.seedMemberIds
        .map((id) => profilesById[id])
        .whereType<FriendRelayProfile>()
        .toList(growable: false);
    if (seededProfiles.isEmpty) {
      _showBanner('That guild roster is no longer available.');
      _notifyNow();
      return false;
    }

    final members = <GuildMemberSnapshot>[];
    var nextSlotIndex = 0;
    for (var index = 0; index < seededProfiles.length; index++) {
      members.add(
        _buildGuildMemberFromProfile(
          seededProfiles[index],
          slotIndex: nextSlotIndex,
          role: index == 0 ? GuildMemberRole.leader : GuildMemberRole.member,
        ),
      );
      nextSlotIndex += 1;
    }
    members.add(
      _buildPlayerGuildMember(
        slotIndex: nextSlotIndex,
        role: GuildMemberRole.member,
      ),
    );

    _activeGuild = GuildState(
      id: suggestion.id,
      name: suggestion.name,
      motto: suggestion.motto,
      memberCap: guildMemberCap,
      members: members,
      chatMessages: <GuildChatMessage>[],
    );
    _guildChatCounter = 0;
    _appendGuildSystemMessage(
      'You joined ${suggestion.name}. One tower is now anchored on ${_guildSlotLabel(nextSlotIndex)}.',
    );
    _appendGuildChatMessage(
      authorLabel: suggestion.leaderLabel,
      message:
          'Welcome in. Call out any empty slots before the next shell push.',
    );
    _showBanner('Joined ${suggestion.name}. Guild chat is open.');
    _notifyNow();
    return true;
  }

  bool recruitNextGuildMember() {
    final currentGuild = activeGuild;
    if (currentGuild == null) {
      _showBanner('Create or join a guild first.');
      _notifyNow();
      return false;
    }
    if (currentGuild.members.length >= guildMemberCap) {
      _showBanner('Guild spire is already fully staffed.');
      _notifyNow();
      return false;
    }

    final recruits = guildRecruitCandidates;
    if (recruits.isEmpty) {
      _showBanner('No eligible recruits are in range right now.');
      _notifyNow();
      return false;
    }

    final recruit = recruits.first;
    final slotIndex = _nextOpenGuildSlot(currentGuild);
    if (slotIndex == null) {
      _showBanner('Guild spire is already fully staffed.');
      _notifyNow();
      return false;
    }

    currentGuild.members.add(
      _buildGuildMemberFromProfile(recruit, slotIndex: slotIndex),
    );
    _appendGuildSystemMessage(
      '${recruit.displayName} anchored ${_guildSlotLabel(slotIndex)}.',
    );
    _appendGuildChatMessage(
      authorLabel: recruit.displayName,
      message: _mockRecruitJoinLine(recruit, slotIndex),
    );
    _showBanner('${recruit.displayName} joined ${currentGuild.name}.');
    _notifyNow();
    return true;
  }

  bool leaveGuild() {
    final currentGuild = activeGuild;
    if (currentGuild == null) {
      _showBanner('You are not in a guild.');
      _notifyNow();
      return false;
    }

    final name = currentGuild.name;
    _activeGuild = null;
    _guildChatCounter = 0;
    _showBanner(
      'Left $name. Your contribution tower is back in solo rotation.',
    );
    _notifyNow();
    return true;
  }

  bool sendGuildChatMessage(String message) {
    final currentGuild = activeGuild;
    if (currentGuild == null) {
      _showBanner('Join a guild before using guild chat.');
      _notifyNow();
      return false;
    }

    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return false;
    }

    _appendGuildChatMessage(
      authorLabel: 'You',
      message: normalizedMessage,
      isLocalPlayer: true,
    );

    final responders = currentGuild.members
        .where((member) => !member.isLocalPlayer)
        .toList(growable: false);
    if (responders.isNotEmpty) {
      final responder = responders[_guildChatCounter % responders.length];
      _appendGuildChatMessage(
        authorLabel: responder.displayName,
        message: _mockGuildReplyForMessage(normalizedMessage, responder),
      );
    }
    _notifyNow();
    return true;
  }
}
