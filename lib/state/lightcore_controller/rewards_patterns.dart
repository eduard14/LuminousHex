part of '../lightcore_controller.dart';

extension LightcoreControllerRewardPatterns on LightcoreController {
  List<BattlePassTierDefinition> _battlePassTierDefinitions(
    BattlePassProgress pass,
  ) {
    final managerRarity = pass.snapshotManagerRarity;
    final enemyCardRarity = pass.snapshotEnemyCardRarity;
    return switch (pass.type) {
      BattlePassType.dailyKills => const <BattlePassTierDefinition>[
        BattlePassTierDefinition(
          goal: 25,
          freeReward: BattlePassReward.flux(10),
          premiumReward: BattlePassReward.flux(18),
        ),
        BattlePassTierDefinition(
          goal: 80,
          freeReward: BattlePassReward.enemyPulls(2),
          premiumReward: BattlePassReward.flux(18),
        ),
        BattlePassTierDefinition(
          goal: 160,
          freeReward: BattlePassReward.flux(18),
          premiumReward: BattlePassReward.flux(28),
        ),
        BattlePassTierDefinition(
          goal: 280,
          freeReward: BattlePassReward.enemyPulls(3),
          premiumReward: BattlePassReward.flux(30),
        ),
        BattlePassTierDefinition(
          goal: 420,
          freeReward: BattlePassReward.flux(35),
          premiumReward: BattlePassReward.enemyPulls(6),
        ),
      ],
      BattlePassType.towerManagerPulls => <BattlePassTierDefinition>[
        const BattlePassTierDefinition(
          goal: 1,
          freeReward: BattlePassReward.flux(20),
          premiumReward: BattlePassReward.flux(25),
        ),
        const BattlePassTierDefinition(
          goal: 2,
          freeReward: BattlePassReward.flux(30),
          premiumReward: BattlePassReward.flux(40),
        ),
        const BattlePassTierDefinition(
          goal: 4,
          freeReward: BattlePassReward.enemyPulls(3),
          premiumReward: BattlePassReward.flux(40),
        ),
        const BattlePassTierDefinition(
          goal: 7,
          freeReward: BattlePassReward.flux(80),
          premiumReward: BattlePassReward.flux(55),
        ),
        BattlePassTierDefinition(
          goal: 10,
          freeReward: BattlePassReward.flux(80),
          premiumReward: BattlePassReward.towerManager(
            rarity: managerRarity ?? ManagerRarity.rare,
          ),
        ),
      ],
      BattlePassType.enemyManagerPulls => <BattlePassTierDefinition>[
        const BattlePassTierDefinition(
          goal: 1,
          freeReward: BattlePassReward.flux(18),
          premiumReward: BattlePassReward.flux(28),
        ),
        const BattlePassTierDefinition(
          goal: 2,
          freeReward: BattlePassReward.flux(28),
          premiumReward: BattlePassReward.flux(45),
        ),
        const BattlePassTierDefinition(
          goal: 4,
          freeReward: BattlePassReward.enemyPulls(2),
          premiumReward: BattlePassReward.flux(38),
        ),
        const BattlePassTierDefinition(
          goal: 7,
          freeReward: BattlePassReward.flux(95),
          premiumReward: BattlePassReward.flux(60),
        ),
        BattlePassTierDefinition(
          goal: 10,
          freeReward: BattlePassReward.flux(104),
          premiumReward: BattlePassReward.enemyManager(
            rarity: managerRarity ?? ManagerRarity.epic,
          ),
        ),
      ],
      BattlePassType.enemyPulls => <BattlePassTierDefinition>[
        const BattlePassTierDefinition(
          goal: 10,
          freeReward: BattlePassReward.flux(10),
          premiumReward: BattlePassReward.flux(20),
        ),
        const BattlePassTierDefinition(
          goal: 25,
          freeReward: BattlePassReward.flux(15),
          premiumReward: BattlePassReward.enemyPulls(2),
        ),
        const BattlePassTierDefinition(
          goal: 50,
          freeReward: BattlePassReward.flux(90),
          premiumReward: BattlePassReward.flux(30),
        ),
        const BattlePassTierDefinition(
          goal: 80,
          freeReward: BattlePassReward.enemyPulls(4),
          premiumReward: BattlePassReward.flux(45),
        ),
        BattlePassTierDefinition(
          goal: 120,
          freeReward: BattlePassReward.enemyPulls(10),
          premiumReward: BattlePassReward.enemyCard(
            rarity: enemyCardRarity ?? EnemyCardRarity.legendary,
          ),
        ),
      ],
    };
  }

  void _ensureStaticBattlePassesHaveCurrent(
    Map<BattlePassType, List<BattlePassProgress>> passesByType,
  ) {
    for (final type in BattlePassType.values) {
      final passes = passesByType.putIfAbsent(
        type,
        () => <BattlePassProgress>[_createBattlePass(type)],
      );
      if (passes.isEmpty) {
        passes.add(_createBattlePass(type));
      }
      if (type.resetsDaily) {
        continue;
      }
      final active = passes.last;
      final finalGoal = _battlePassTierDefinitions(active).last.goal;
      if (active.progress >= finalGoal) {
        passes.add(_createBattlePass(type, generation: active.generation + 1));
      }
    }
  }

  bool _slotHasAutomationManager(
    TowerLayerSnapshot layer,
    OuterTowerState tower,
  ) {
    if (!_slotCountsTowardRing(tower) || tower.isChildLayerNode) {
      return false;
    }
    return _managerAssignmentUnlockedForLayer(layer) &&
        _towerCoreManagerForLayer(layer) != null;
  }

  Map<PrototypeAffinity, int> _activeTowerAffinityCounts(
    Iterable<OuterTowerState> towers,
  ) {
    final counts = <PrototypeAffinity, int>{};
    for (final tower in towers) {
      if (!_slotCountsTowardRing(tower)) {
        continue;
      }
      final affinity = _slotAffinity(tower);
      counts.update(affinity, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  bool _matchesExclusiveTowerAffinities(
    Map<PrototypeAffinity, int> counts,
    List<PrototypeAffinity> required,
  ) {
    if (counts.length != required.length) {
      return false;
    }
    for (final affinity in required) {
      if (!counts.containsKey(affinity)) {
        return false;
      }
    }
    return counts.keys.every(required.contains);
  }

  List<TowerPatternAchievement> _resolveTowerPatternAchievements(
    Iterable<OuterTowerState> towers,
  ) {
    final counts = _activeTowerAffinityCounts(towers);
    final activeCount = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (activeCount < 2) {
      return const <TowerPatternAchievement>[];
    }

    final activeAffinities = counts.keys.toSet();
    final achievements = <TowerPatternAchievement>[];

    if (activeCount == slotCount &&
        activeAffinities.length == _rainbowTowerAffinities.length &&
        activeAffinities.containsAll(_rainbowTowerAffinities)) {
      achievements.add(
        const TowerPatternAchievement(
          id: 'rainbow_relay',
          name: 'Rainbow Relay',
          summary:
              'One of each prism color is active. Towers gain +12% power, +10% charge, +8% range, and +3% crit chance.',
          bonuses: TowerPatternBonusProfile(
            power: 0.12,
            chargeRate: 0.10,
            range: 0.08,
            critChance: 0.03,
          ),
        ),
      );
    }

    if (activeAffinities.length == 1) {
      achievements.add(
        const TowerPatternAchievement(
          id: 'monochrome_focus',
          name: 'Monochrome Focus',
          summary:
              'Every active tower shares one color. Towers gain +18% power, -10% cooldown, and +12% final damage.',
          bonuses: TowerPatternBonusProfile(
            power: 0.18,
            cooldownReduction: 0.10,
            finalDamage: 0.12,
          ),
        ),
      );
    }

    if (_matchesExclusiveTowerAffinities(counts, const <PrototypeAffinity>[
      PrototypeAffinity.aether,
      PrototypeAffinity.verdant,
    ])) {
      achievements.add(
        const TowerPatternAchievement(
          id: 'storm_chain',
          name: 'Storm Chain',
          summary:
              'Only blue and green towers are online. Towers gain +18% charge, +14% generation, and +4% crit chance.',
          bonuses: TowerPatternBonusProfile(
            chargeRate: 0.18,
            generationSpeed: 0.14,
            critChance: 0.04,
          ),
        ),
      );
    }

    if (_matchesExclusiveTowerAffinities(counts, const <PrototypeAffinity>[
      PrototypeAffinity.ember,
      PrototypeAffinity.flare,
    ])) {
      achievements.add(
        const TowerPatternAchievement(
          id: 'ember_drive',
          name: 'Ember Drive',
          summary:
              'Only red and orange towers are online. Towers gain +16% power, +10% final damage, and +6% defense pen.',
          bonuses: TowerPatternBonusProfile(
            power: 0.16,
            finalDamage: 0.10,
            defensePenetration: 0.06,
          ),
        ),
      );
    }

    return achievements;
  }

  int promotionReadyCountForLayer(TowerLayerSnapshot layer) => layer.slots
      .where(_slotCountsTowardRing)
      .where(_slotReadyForPromotion)
      .length;

  int childPromotionReadyTowerCount(OuterTowerState tower) {
    final childLayerId = tower.childLayerId;
    if (!tower.isChildLayerNode || childLayerId == null) {
      return 0;
    }
    final child = _layerById(childLayerId);
    return promotionReadyCountForLayer(child);
  }

  List<FriendRelayProfile> _buildSocialFriendRelayProfiles(
    LightcoreSocialOverview overview,
  ) {
    return overview.directMentees
        .map((player) {
          final levelGap = (player.level - overallLevel).abs();
          final using = player.withinLevelBand && player.bonusActive;
          return FriendRelayProfile(
            playerId: player.uid,
            displayName: player.displayName,
            level: player.level,
            levelGap: levelGap,
            progressToNextLevel: player.progressToNextLevel,
            successRating: player.performanceScore.clamp(0.0, 1.0),
            sharedTower: _buildMockFriendRelayTower(
              displayName: player.displayName,
              level: player.level,
              seed: _stableSocialSeed(player.uid),
            ),
            withinLevelBand: player.withinLevelBand,
            usingPlayerTower: using,
            personalContributionMultiplier: using
                ? (1 + (0.05 * player.performanceScore.clamp(0.0, 1.0)))
                : 1.0,
          );
        })
        .toList(growable: false);
  }

  FriendRelayTower _buildFriendAllianceTower(
    List<FriendRelayProfile> profiles,
  ) {
    final candidates =
        profiles
            .where((profile) {
              return profile.withinLevelBand;
            })
            .toList(growable: false)
          ..sort((a, b) {
            final left =
                (a.successRating * 0.55) + (a.progressToNextLevel * 0.45);
            final right =
                (b.successRating * 0.55) + (b.progressToNextLevel * 0.45);
            return right.compareTo(left);
          });

    if (candidates.isEmpty) {
      return const FriendRelayTower(
        outerPieces: <FriendRelayPiece?>[null, null, null, null, null, null],
      );
    }

    final center = candidates.first.sharedTower.center;
    final outerPieces = List<FriendRelayPiece?>.filled(slotCount, null);
    for (var index = 0; index < slotCount; index++) {
      final profile = candidates[index % candidates.length];
      final sourcePieces = profile.sharedTower.outerPieces;
      outerPieces[index] = sourcePieces[index % sourcePieces.length];
    }
    return FriendRelayTower(center: center, outerPieces: outerPieces);
  }

  String _mockGuildReplyForMessage(
    String message,
    GuildMemberSnapshot responder,
  ) {
    final normalized = message.toLowerCase();
    if (normalized.contains('boss')) {
      return 'Holding burst for the next Apex wave.';
    }
    if (normalized.contains('ready') || normalized.contains('sync')) {
      return 'I am synced on ${responder.slotLabel.toLowerCase()}.';
    }
    if (normalized.contains('tower') || normalized.contains('swap')) {
      final centerTitle =
          responder.contributedTower.center?.title ?? 'another tower shell';
      return 'I can rotate into $centerTitle after this cycle.';
    }
    return _mockGuildReplies[(_guildChatCounter + responder.slotIndex) %
        _mockGuildReplies.length];
  }
}
