part of '../lightcore_controller.dart';

extension LightcoreControllerBattleUnlocks on LightcoreController {
  String _towerActivationBlockedLabel(OuterTowerState tower) {
    if (towerUsesPersistentShieldRing(tower)) {
      return '${towerDisplayName(tower)} is a persistent shield and does not generate packets.';
    }
    final manager = cardForSlot(tower);
    if (manager != null) {
      return '${manager.name} is already automating ready taps on this shell.';
    }
    if (!_slotCountsTowardRing(tower)) {
      return tower.isLayerProject
          ? 'Open this child shell and build it before it can generate packets.'
          : 'Anchor this hex before it can fire.';
    }
    if ((_ammoQueue.length + _pulses.length) >= coreQueueCapacity) {
      return 'Core queue full. Tap the Lightcore or upgrade queue capacity.';
    }
    if (tower.cooldownRemaining > 0) {
      return '${towerDisplayName(tower)} is cycling for ${tower.cooldownRemaining.toStringAsFixed(1)}s.';
    }
    if (tower.charge < 1) {
      return '${towerDisplayName(tower)} is ${(tower.charge * 100).clamp(0, 100).toStringAsFixed(0)}% charged.';
    }
    return '${towerDisplayName(tower)} is not ready.';
  }

  String? _handleOverallLevelIncrease({
    required int previousExperience,
    required int currentExperience,
  }) {
    final previousLevel = overallLevelForExperience(previousExperience);
    final currentLevel = overallLevelForExperience(currentExperience);
    if (currentLevel <= previousLevel) {
      return null;
    }

    final destroyed = _triggerLevelUpRadiance(currentLevel);
    final gainedLevels = currentLevel - previousLevel;
    final enemyNoun = destroyed == 1 ? 'enemy' : 'enemies';
    final levelLabel = currentLevel == previousLevel + 1
        ? 'Account Radiance Lv $currentLevel'
        : 'Account Radiance Lv $currentLevel (+$gainedLevels)';
    final pointLabel = gainedLevels == 1
        ? '1 Radiance point ready'
        : '$gainedLevels Radiance points ready';
    final wipeLabel = destroyed == 0
        ? 'Radiance nova armed.'
        : 'Radiance nova cleared $destroyed $enemyNoun.';
    return 'Level up: $levelLabel. $pointLabel. Choose Might, Focus, Tempo, or Insight from Main Manager > Global Attributes. $wipeLabel';
  }

  int _triggerLevelUpRadiance(int level) {
    final victims = _enemies
        .where((enemy) => !enemy.config.isBoss)
        .toList(growable: false);
    if (victims.isNotEmpty) {
      final victimIds = victims.map((enemy) => enemy.id).toSet();
      _enemies.removeWhere((enemy) => victimIds.contains(enemy.id));
      _blueFocusTargetEnemyIdBySlot.removeWhere(
        (_, lockedEnemyId) => victimIds.contains(lockedEnemyId),
      );
    }
    for (final enemy in victims) {
      _impacts.add(
        ImpactState(
          id: 'level_up_impact_${_impactCounter++}',
          affinity: _core.affinity,
          secondaryAffinity: _core.secondaryAffinity,
          projectileType: ProjectileType.coreBomb,
          payloadType: PayloadType.none,
          angle: enemy.angle,
          radius: enemy.radius,
          progress: 0,
          lethal: true,
          towerHit: false,
          critical: true,
          progressRate: 1.7,
          defeatedEnemyAffinity: enemy.config.affinity,
          defeatedEnemySizeScale: enemy.sizeScale,
        ),
      );
    }
    _levelUpRadianceProgress = 0;
    _levelUpRadianceSequence += 1;
    _lastLevelUpRadianceLevel = level;
    _lastLevelUpRadianceDestroyedEnemies = victims.length;
    _needsNotify = true;
    return victims.length;
  }

  String? _towerUnlockBannerFragment(
    int previousExperience,
    int currentExperience,
  ) {
    final previouslyUnlocked = unlockedOuterSlotCountForExperience(
      previousExperience,
    );
    final currentlyUnlocked = unlockedOuterSlotCountForExperience(
      currentExperience,
    );
    if (currentlyUnlocked <= previouslyUnlocked) {
      return null;
    }

    if (currentlyUnlocked >= slotCount) {
      return 'All $slotCount prism anchors are now stable.';
    }

    final unlockedCount = currentlyUnlocked - previouslyUnlocked;
    final unlockedLabel = unlockedCount == 1
        ? 'Hex $currentlyUnlocked stabilized.'
        : 'Hexes ${previouslyUnlocked + 1}-$currentlyUnlocked stabilized.';
    return '$unlockedLabel Next anchor opens at ${unlockExperienceForOuterSlot(currentlyUnlocked)} EXP.';
  }

  String? _grantBossUnlockIfNeeded() {
    if (_bossUnlockGrantClaimed) {
      return null;
    }
    if (!bossHuntsUnlocked) {
      return null;
    }

    _bossUnlockGrantClaimed = true;
    enemyTickets += bossUnlockTicketGrant;
    return 'Regional boss scans unlocked in the Prism Shell. ${LightcoreCurrencyLabels.rewardThreatScans(bossUnlockTicketGrant)} issued.';
  }

  String? _tournamentUnlockBannerFragment({
    required int previousExperience,
    required int currentExperience,
  }) {
    if (_openEventLevelWallsForTesting) {
      return null;
    }
    final previousLevel = overallLevelForExperience(previousExperience);
    final currentLevel = overallLevelForExperience(currentExperience);
    if (previousLevel >= tournamentUnlockLevel ||
        currentLevel < tournamentUnlockLevel) {
      return null;
    }
    return 'Tournaments unlocked at Account Radiance Lv $tournamentUnlockLevel. Open Settings to set your screen name.';
  }

  String? _mentorshipUnlockBannerFragment({
    required int previousExperience,
    required int currentExperience,
  }) {
    final previousLevel = overallLevelForExperience(previousExperience);
    final currentLevel = overallLevelForExperience(currentExperience);
    if (previousLevel >= mentorshipUnlockLevel ||
        currentLevel < mentorshipUnlockLevel) {
      return null;
    }
    return 'Mentorship unlocked at Account Radiance Lv $mentorshipUnlockLevel. Open Menu to inspect mentors and mentees.';
  }

  String? _managerUnlockBannerFragment({
    required int previousExperience,
    required int currentExperience,
  }) {
    return null;
  }

  String? _dailyDungeonUnlockBannerFragment({
    required int previousExperience,
    required int currentExperience,
  }) {
    if (_openEventLevelWallsForTesting) {
      return null;
    }
    final previousLevel = overallLevelForExperience(previousExperience);
    final currentLevel = overallLevelForExperience(currentExperience);
    if (previousLevel >= dailyDungeonUnlockLevel ||
        currentLevel < dailyDungeonUnlockLevel) {
      return null;
    }
    return 'Daily Dungeons unlocked at Account Radiance Lv $dailyDungeonUnlockLevel. Break Lv 1 of the tower with your anomaly roster to unlock the next level.';
  }
}
