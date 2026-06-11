part of '../lightcore_controller.dart';

extension LightcoreControllerStatusBattlePass on LightcoreController {
  // L1L2_REBUILD_SAFE: Experience rewards no longer inherit removed output pressure.
  double get effectiveExperienceEfficiencyMultiplier => 1.0;

  String get coreStabilityLabel => '${_core.coreStability.round()}/100';

  bool get hasPermanentOverdrive => _hasPermanentOverdrive;

  bool get hasPremiumMembership => _hasPremiumMembership;

  bool get hasActivePermanentOverdrive =>
      _hasPermanentOverdrive && _swarmActivated;

  bool get canUseManualOverdrive => _swarmActivated && !_hasPermanentOverdrive;

  bool get showManualOverdriveHud {
    if (!_tutorialPromptsEnabled ||
        _earlyTutorialComplete ||
        _tutorialOverdriveLearned ||
        _hasPermanentOverdrive) {
      return true;
    }
    return _tutorialStep == LightcoreTutorialStep.holdOverdrive;
  }

  bool get isManualOverdriveHeld =>
      _manualOverdriveHeld && canUseManualOverdrive;

  double get manualOverdriveCharge => _manualOverdriveCharge;

  double get manualOverdriveMultiplier => hasActivePermanentOverdrive
      ? _manualOverdriveMaxMultiplier
      : 1 + ((_manualOverdriveMaxMultiplier - 1) * _manualOverdriveCharge);

  String get manualOverdriveMultiplierLabel =>
      'X${manualOverdriveMultiplier.toStringAsFixed(2)}';

  String get manualOverdriveStatusLabel {
    if (hasActivePermanentOverdrive) {
      return 'Permanent overdrive is active at X1.50.';
    }
    if (_hasPermanentOverdrive) {
      return 'Permanent overdrive will engage once the shell goes live.';
    }
    if (!canUseManualOverdrive) {
      return 'Reveal the shell once to unlock Overdrive.';
    }
    if (isManualOverdriveHeld) {
      return manualOverdriveCharge >= 0.99
          ? 'Overdrive capped. Release to let the charge bleed back down.'
          : 'Holding builds the live battle toward x1.5 speed.';
    }
    if (manualOverdriveCharge > 0.02) {
      return 'Stored momentum is still accelerating the live battle.';
    }
    return 'Click for a burst or hold to build up to x1.5 speed.';
  }

  int get tournamentPowerIndex => evenEntryTournamentPowerIndex;

  double get tournamentExperienceMultiplier {
    final endsAt = _tournamentExperienceBoostEndsAt;
    if (_tournamentExperienceMultiplier <= 1.0 || endsAt == null) {
      return 1.0;
    }
    if (!endsAt.isAfter(DateTime.now())) {
      return 1.0;
    }
    return _tournamentExperienceMultiplier;
  }

  DateTime? get tournamentExperienceBoostEndsAt {
    final endsAt = _tournamentExperienceBoostEndsAt;
    if (endsAt == null || !endsAt.isAfter(DateTime.now())) {
      return null;
    }
    return endsAt;
  }

  bool get hasActiveTournamentExperienceBoost =>
      tournamentExperienceMultiplier > 1.0;

  String get tournamentExperienceBoostLabel =>
      'x${tournamentExperienceMultiplier.toStringAsFixed(2)} EXP';

  void dismissBanner() {
    if (bannerMessage.isEmpty) {
      return;
    }

    bannerMessage = '';
    _bannerTimer = 0;
    _notifyNow();
  }

  double get globalLumenGuard => _slots
      .where(_slotCountsTowardRing)
      .fold(
        0.0,
        (sum, slot) =>
            sum +
            (slot.config == null
                ? ((slot.childLayerTier ?? 1) * 0.006)
                : _balancedTowerStat(
                    slot.config!,
                    'lumenPressureGuard',
                    slot.config!.lumenPressureGuard,
                  )),
      );

  List<BattlePassType> get battlePassTypes => BattlePassType.values;

  List<BattlePassProgress> battlePassesFor(BattlePassType type) {
    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    return List<BattlePassProgress>.unmodifiable(
      _battlePasses[type] ?? const <BattlePassProgress>[],
    );
  }

  BattlePassProgress battlePassFor(BattlePassType type) {
    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    return _activeBattlePassFor(type);
  }

  List<BattlePassTierDefinition> battlePassTiers(BattlePassType type) {
    final pass = battlePassFor(type);
    return _battlePassTierDefinitions(pass);
  }

  List<BattlePassTierDefinition> battlePassTiersForPass(
    BattlePassProgress pass,
  ) {
    return _battlePassTierDefinitions(pass);
  }

  int claimableBattlePassRewards(BattlePassType type) {
    return battlePassesFor(
      type,
    ).fold(0, (sum, pass) => sum + claimableBattlePassRewardsForPass(pass));
  }

  int claimableBattlePassRewardsForPass(BattlePassProgress pass) {
    final tiers = _battlePassTierDefinitions(pass);
    var total = 0;
    for (var tierIndex = 0; tierIndex < tiers.length; tierIndex++) {
      for (final track in BattlePassTrack.values) {
        if (canClaimBattlePassRewardForPass(pass, tierIndex, track)) {
          total += 1;
        }
      }
    }
    return total;
  }

  int claimUnlockedBattlePassRewards(BattlePassType type) {
    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    var total = 0;
    for (final pass in _battlePasses[type] ?? const <BattlePassProgress>[]) {
      total += claimUnlockedBattlePassRewardsForPass(pass);
    }
    return total;
  }

  int claimUnlockedBattlePassRewardsForPass(BattlePassProgress pass) {
    final tiers = _battlePassTierDefinitions(pass);
    final claimedRewards = <BattlePassReward>[];

    for (var tierIndex = 0; tierIndex < tiers.length; tierIndex++) {
      final tier = tiers[tierIndex];
      for (final track in BattlePassTrack.values) {
        if (track == BattlePassTrack.premium && !pass.premiumUnlocked) {
          continue;
        }
        if (pass.progress < tier.goal) {
          continue;
        }

        final claimKey = _battlePassClaimKey(tierIndex, track);
        if (pass.claimedRewardKeys.contains(claimKey)) {
          continue;
        }

        final reward = track == BattlePassTrack.free
            ? tier.freeReward
            : tier.premiumReward;
        _grantBattlePassReward(reward);
        pass.claimedRewardKeys.add(claimKey);
        claimedRewards.add(reward);
      }
    }

    if (claimedRewards.isEmpty) {
      return 0;
    }

    final previewCount = min(3, claimedRewards.length);
    final preview = claimedRewards
        .take(previewCount)
        .map((reward) => reward.label)
        .join(', ');
    final remainder = claimedRewards.length - previewCount;
    final summary = remainder > 0 ? '$preview, +$remainder more' : preview;

    _showBanner(
      '${pass.type.shortLabel}: claimed ${claimedRewards.length} reward${claimedRewards.length == 1 ? '' : 's'} ($summary).',
    );
    if (_tutorialStep == LightcoreTutorialStep.claimBattlePassReward) {
      _tutorialBattlePassRewardClaimed = true;
      _syncTutorialStep(showBanner: false);
    }
    _notifyNow();
    return claimedRewards.length;
  }

  int get totalClaimableBattlePassRewards {
    _refreshBattlePassesForToday();
    _ensureStaticBattlePassesHaveCurrent(_battlePasses);
    return BattlePassType.values.fold(
      0,
      (sum, type) => sum + claimableBattlePassRewards(type),
    );
  }

  double get averageDisruption {
    final built = _slots.where(_slotCountsTowardRing).toList();
    if (built.isEmpty) {
      return 0;
    }
    final total = built.fold(0.0, (sum, slot) => sum + slot.disruption);
    return total / built.length;
  }

  bool get canScrapActiveLayer =>
      activeLayer.parentLayerId != null &&
      !_layerHasDescendants(activeLayer.id);

  bool isSlotActiveTower(OuterTowerState tower) => _slotCountsTowardRing(tower);

  bool isSlotLayerProject(OuterTowerState tower) => tower.isLayerProject;

  bool isSlotPromotionReady(OuterTowerState tower) =>
      tower.isLayerProject && childPromotionReadyTowerCount(tower) == slotCount;
}
