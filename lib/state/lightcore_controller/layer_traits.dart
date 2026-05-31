part of '../lightcore_controller.dart';

extension LightcoreControllerLayerTraits on LightcoreController {
  String _traitSignatureLabel(
    PrototypeAffinity projectileAffinity,
    PrototypeAffinity? payloadAffinity,
  ) => payloadAffinity == null
      ? '${projectileAffinity.label} projectile'
      : '${projectileAffinity.label} projectile / ${payloadAffinity.label} payload';

  String _arsenalSummary<T>(Iterable<T> loadout) {
    final labels = <String>[];
    for (final item in loadout) {
      final label = switch (item) {
        ProjectileType value => '${value.label} (${value.rarity.label})',
        PayloadType value => value.label,
        PrototypeAffinity value => value.label,
        _ => item.toString(),
      };
      if (!labels.contains(label)) {
        labels.add(label);
      }
    }
    if (labels.isEmpty) {
      return 'None';
    }
    return labels.join(' • ');
  }

  int _coreUpgradeCost({required int baseCost, required int upgradeLevel}) {
    final levelCurve = 1 + ((_core.level - 1) * 0.16);
    final shellCurve = 1 + (builtTowerCount * 0.08);
    final upgradeCurve = pow(1.72, upgradeLevel).toDouble();
    final price =
        baseCost *
        activeLayerPriceMultiplier *
        levelCurve *
        shellCurve *
        upgradeCurve;
    return max(1, price.round());
  }

  int _normalizeCoreUpgradeLevel(int level) =>
      min(maxCoreUpgradeLevel, max(0, level));

  int _normalizeCoreMultiShotUpgradeLevel(int level) =>
      min(maxCoreMultiShotUpgradeLevel, max(0, level));

  int _normalizeEnemyTargetUpgradeLevel(int level) =>
      min(maxEnemyTargetUpgradeLevel, max(0, level));

  int _migratedEnemyTargetUpgradeLevel({
    required int savedUpgradeLevel,
    required int savedUpgradeStep,
  }) {
    if (savedUpgradeStep == enemyTargetUpgradeStep) {
      return _normalizeEnemyTargetUpgradeLevel(savedUpgradeLevel);
    }

    final savedTargetMax = min(
      maxActiveEnemies,
      baseEnemyTargetMax +
          (max(0, savedUpgradeLevel) * max(1, savedUpgradeStep)),
    );
    final migratedLevel =
        ((savedTargetMax - baseEnemyTargetMax) / enemyTargetUpgradeStep).ceil();
    return _normalizeEnemyTargetUpgradeLevel(migratedLevel);
  }

  int _enemyTargetMaxForLevel(int upgradeLevel) => min(
    maxActiveEnemies,
    baseEnemyTargetMax +
        (_normalizeEnemyTargetUpgradeLevel(upgradeLevel) *
            enemyTargetUpgradeStep),
  );

  int _normalizeEnemyTargetCount(int value, {int? upgradeLevel}) => min(
    _enemyTargetMaxForLevel(upgradeLevel ?? _enemyTargetUpgradeLevel),
    max(minEnemyTarget, value),
  );

  int _enemyTargetUpgradeCost({required int upgradeLevel}) {
    final shellCurve = 1 + (builtTowerCount * 0.07);
    final upgradeCurve = pow(1.5, upgradeLevel).toDouble();
    final price = 14 * activeLayerPriceMultiplier * shellCurve * upgradeCurve;
    return max(1, price.round());
  }

  double _coreBasicShotPowerForLayer(TowerLayerSnapshot layer) {
    final tierBonus = max(0, layer.tier - payloadUnlockLayer);
    final promotedMultiplier = layer.tier < payloadUnlockLayer
        ? 1.0
        : _promotedCoreShotPowerMultiplier +
              (tierBonus * _promotedCoreShotPowerTierStep);
    return (6.5 + ((layer.core.level - 1) * 1.7)) *
        promotedMultiplier *
        _towerPowerUpgradeMultiplier(
          _coreUpgradeBonusForState(layer.core, TowerUpgradeStatType.power),
        );
  }

  double _coreBasicShotPower() => _coreBasicShotPowerForLayer(activeLayer);

  OuterTowerState? get _firstTutorialTower {
    if (_slots.isEmpty) {
      return null;
    }
    final tower = _slots[0];
    return tower.isBuilt && !tower.isFabricating ? tower : null;
  }

  bool _isOpeningStarterTower(TowerConfig? config) =>
      config != null &&
      (config.id == TowerLibrary.redPrism.id ||
          config.id == TowerLibrary.cyanPrism.id);

  int _outerSlotUnlockExperienceForProgression(int slotIndex) {
    return unlockExperienceForOuterSlot(slotIndex);
  }

  bool get _currentLayerEarlyTutorialComplete {
    final tower = _firstTutorialTower;
    if (builtTowerCount > 1) {
      return true;
    }
    if (tower == null) {
      return false;
    }
    if (!_isOpeningStarterTower(tower.config)) {
      return false;
    }
    return _tutorialManualAimFireLearned &&
        tower.level >= 3 &&
        _tutorialFirstTowerStatsOpened &&
        _tutorialStabilityPanelOpened &&
        (totalRadianceStatPointsSpent > 0 ||
            _core.rangeUpgradeLevel > 0 ||
            !hasUnspentRadianceStatPoints);
  }

  bool get _earlyTutorialComplete =>
      _tutorialEarlyQuestChainCompleted || _currentLayerEarlyTutorialComplete;

  bool get _firstThreatChallengeStarted {
    final starterId = ThreatRegionLibrary.all.first.id;
    final starterState = threatRegionStateById(starterId);
    return _threatRegionChallenge?.regionId == starterId ||
        (starterState?.stabilizedLevel ?? 0) > 0;
  }

  bool get _openingThreatEscalationReady {
    final firstTower = _firstTutorialTower;
    if (firstTower == null ||
        !_isOpeningStarterTower(firstTower.config) ||
        firstTower.level < 2 ||
        _firstThreatChallengeStarted ||
        !canStartFirstThreatChallenge) {
      return false;
    }
    if (_core.coreStability < 96 || outputEfficiencyMultiplier < 0.96) {
      return false;
    }
    final stats = activeThreatAssignmentGroupStats;
    if (!stats.hasAnomalies ||
        stats.spawnsPerMinute <= 0 ||
        stats.clearsPerMinute <= 0) {
      return false;
    }
    return !stats.isDpsLimited ||
        stats.clearsPerMinute >= stats.spawnsPerMinute * 0.5;
  }

  bool get _hasCreatedFirstChildShell =>
      _layers.any((layer) => layer.parentLayerId != null);

  bool get _shouldOfferOverdriveTutorial =>
      _hasCreatedFirstChildShell &&
      !_tutorialOverdriveLearned &&
      !_hasPermanentOverdrive &&
      canUseManualOverdrive;

  bool get _ownsBasicRedEnemy => _enemyCards.any(
    (card) => card.config.id == EnemyLibrary.basicRed.id && card.isOwned,
  );

  bool get _hasAssignedTowerManagerOnActiveLayer =>
      _towerCoreManagerForLayer(activeLayer) != null;

  bool get _hasAssignedEnemyManagerOnActiveLayer => _enemyManagers.any(
    (manager) => manager.assignedLayerId == activeLayer.id,
  );

  int? _secondShellShotTutorialSlotIndex() {
    if (!_hasCreatedFirstChildShell ||
        _tutorialSecondShellShotTapLearned ||
        (!activeLayerHasParentSlot && !isCompositeLayer)) {
      return null;
    }
    for (var index = 0; index < _slots.length; index++) {
      if (_pulses.any((pulse) => pulse.sourceSlotIndex == index) ||
          canActivateTower(_slots[index])) {
        return index;
      }
    }
    return null;
  }

  LightcoreTutorialStep? _deriveSecondShellShotTutorialStep() =>
      _secondShellShotTutorialSlotIndex() == null
      ? null
      : LightcoreTutorialStep.tapSecondShellTower;

  bool _isTutorialStepComplete(LightcoreTutorialStep step) {
    final firstTower = _slots.isEmpty ? null : _slots[0];
    return switch (step) {
      LightcoreTutorialStep.none => false,
      LightcoreTutorialStep.unfoldShell => _outerRingRevealed,
      LightcoreTutorialStep.waitForFirstHex => isOuterSlotUnlocked(0),
      LightcoreTutorialStep.selectFirstHex => selectedSlotIndex == 0,
      LightcoreTutorialStep.buildFirstRedTower =>
        _isOpeningStarterTower(firstTower?.config) &&
            firstTower?.isFabricating == false,
      LightcoreTutorialStep.inspectFirstTowerStats =>
        _tutorialFirstTowerStatsOpened,
      LightcoreTutorialStep.tapBattleCore => _tutorialCoreShotTapLearned,
      LightcoreTutorialStep.tapFirstTower => _tutorialManualAimFireLearned,
      LightcoreTutorialStep.tapSecondShellTower =>
        _tutorialSecondShellShotTapLearned || _ammoQueue.isNotEmpty,
      LightcoreTutorialStep.upgradeFirstTowerToLevel3 =>
        firstTower != null && firstTower.level >= 2,
      LightcoreTutorialStep.raiseThreat => _firstThreatChallengeStarted,
      LightcoreTutorialStep.pullFirstWhiteEnemy => enemyPullCount >= 1,
      LightcoreTutorialStep.readEffectiveGain => _tutorialStabilityPanelOpened,
      LightcoreTutorialStep.autoQueueCheck => _tutorialAutoQueuedPulses >= 5,
      LightcoreTutorialStep.upgradeFirstTowerToLevel4 =>
        firstTower != null && firstTower.level >= 3,
      LightcoreTutorialStep.pullFirstRedEnemy => enemyPullCount >= 2,
      LightcoreTutorialStep.setFirstEnemyTarget =>
        _tutorialFirstEnemyTargetSet || _ownsBasicRedEnemy,
      LightcoreTutorialStep.adjustEnemyCount => _tutorialEnemyCountAdjusted,
      LightcoreTutorialStep.openTowerMatrix => _tutorialTowerMatrixOpened,
      LightcoreTutorialStep.upgradeCoreRange =>
        totalRadianceStatPointsSpent > 0 || _core.rangeUpgradeLevel > 0,
      LightcoreTutorialStep.openStore => _tutorialStoreOpened,
      LightcoreTutorialStep.claimBattlePassReward =>
        _tutorialBattlePassRewardClaimed,
      LightcoreTutorialStep.openBossPulls => fullThreatMapUnlocked,
      LightcoreTutorialStep.armFirstBoss => hasCompleteEnemySuite,
      LightcoreTutorialStep.defeatFirstBoss =>
        _tutorialFirstBossDefeated || totalBossesDefeated > 0,
      LightcoreTutorialStep.openEquipment => _tutorialFirstEquipmentOpened,
      LightcoreTutorialStep.openManagers => _tutorialFirstManagersOpened,
      LightcoreTutorialStep.forgeTowerManager => _cards.isNotEmpty,
      LightcoreTutorialStep.assignTowerManager =>
        managerAssignmentUnlocked &&
            (_tutorialTowerManagerAssigned ||
                _hasAssignedTowerManagerOnActiveLayer),
      LightcoreTutorialStep.forgeEnemyManager => _enemyManagers.isNotEmpty,
      LightcoreTutorialStep.assignEnemyManager =>
        _tutorialEnemyManagerAssigned || _hasAssignedEnemyManagerOnActiveLayer,
      LightcoreTutorialStep.holdOverdrive => _tutorialOverdriveLearned,
      LightcoreTutorialStep.setScreenName => hasCustomScreenName,
      LightcoreTutorialStep.openFriends => _tutorialFriendsOpened,
      LightcoreTutorialStep.openMentees => _tutorialMenteesOpened,
      LightcoreTutorialStep.openMentors => _tutorialMentorsOpened,
      LightcoreTutorialStep.inspectEnemyBlitz =>
        _reviewedTournamentTutorialModes.contains(
          LightcoreTournamentModeId.enemyBlitz,
        ),
      LightcoreTutorialStep.inspectHexGauntlet =>
        _reviewedTournamentTutorialModes.contains(
          LightcoreTournamentModeId.hexGauntlet,
        ),
      LightcoreTutorialStep.inspectArenaFlow =>
        _reviewedTournamentTutorialModes.contains(
          LightcoreTournamentModeId.arenaFlow,
        ),
    };
  }

  bool _tutorialStepAlreadyComplete(LightcoreTutorialStep step) =>
      _rewardedTutorialSteps.contains(step) || _isTutorialStepComplete(step);

  LightcoreTutorialStep? _deriveCoreLearningTutorialStep() {
    if (_earlyTutorialComplete) {
      return null;
    }
    if (!_outerRingRevealed && builtTowerCount == 0) {
      return LightcoreTutorialStep.unfoldShell;
    }
    final firstTower = _slots[0];
    if (!firstTower.isBuilt) {
      if (selectedSlotIndex != 0) {
        return LightcoreTutorialStep.selectFirstHex;
      }
      return LightcoreTutorialStep.buildFirstRedTower;
    }
    if (firstTower.isFabricating) {
      return LightcoreTutorialStep.none;
    }
    if (!_isOpeningStarterTower(firstTower.config)) {
      return null;
    }
    if (!_tutorialManualAimFireLearned) {
      return LightcoreTutorialStep.tapFirstTower;
    }
    if (!_tutorialFirstTowerStatsOpened) {
      return LightcoreTutorialStep.inspectFirstTowerStats;
    }
    final firstTowerUpgradeCost = upgradeCost(firstTower);
    if (firstTower.level < 2 &&
        firstTowerUpgradeCost > 0 &&
        lumens >= firstTowerUpgradeCost) {
      return LightcoreTutorialStep.upgradeFirstTowerToLevel3;
    }
    if (_openingThreatEscalationReady) {
      return LightcoreTutorialStep.raiseThreat;
    }
    if (!_tutorialStabilityPanelOpened) {
      return LightcoreTutorialStep.readEffectiveGain;
    }
    final nextFirstTowerUpgradeCost = upgradeCost(firstTower);
    if (firstTower.level < 3 &&
        firstTower.level >= 2 &&
        nextFirstTowerUpgradeCost > 0 &&
        lumens >= nextFirstTowerUpgradeCost) {
      return LightcoreTutorialStep.upgradeFirstTowerToLevel4;
    }
    if (totalRadianceStatPointsSpent == 0) {
      return hasUnspentRadianceStatPoints
          ? LightcoreTutorialStep.upgradeCoreRange
          : LightcoreTutorialStep.none;
    }
    return null;
  }

  LightcoreTutorialStep? _deriveTournamentTutorialStep() {
    if (!tournamentsUnlocked) {
      return null;
    }
    if (!hasCustomScreenName) {
      return LightcoreTutorialStep.setScreenName;
    }
    if (!_reviewedTournamentTutorialModes.contains(
      LightcoreTournamentModeId.enemyBlitz,
    )) {
      return LightcoreTutorialStep.inspectEnemyBlitz;
    }
    if (!_reviewedTournamentTutorialModes.contains(
      LightcoreTournamentModeId.hexGauntlet,
    )) {
      return LightcoreTutorialStep.inspectHexGauntlet;
    }
    if (!_reviewedTournamentTutorialModes.contains(
      LightcoreTournamentModeId.arenaFlow,
    )) {
      return LightcoreTutorialStep.inspectArenaFlow;
    }
    return null;
  }

  LightcoreTutorialStep? _deriveSidecarTutorialStep() {
    if (!_tutorialTowerMatrixOpened &&
        _earlyTutorialComplete &&
        completedShellLibraryUnlocked) {
      return LightcoreTutorialStep.openTowerMatrix;
    }
    if (totalRadianceStatPointsSpent == 0 && hasUnspentRadianceStatPoints) {
      return LightcoreTutorialStep.upgradeCoreRange;
    }
    if (!_tutorialStoreOpened && _earlyTutorialComplete) {
      return LightcoreTutorialStep.openStore;
    }
    if (!_tutorialBattlePassRewardClaimed &&
        totalClaimableBattlePassRewards > 0) {
      return LightcoreTutorialStep.claimBattlePassReward;
    }
    return null;
  }

  LightcoreTutorialStep? _deriveManagerTutorialStep() {
    if (!managersUnlocked || !managerAssignmentUnlocked) {
      return null;
    }
    if (!_tutorialFirstManagersOpened) {
      return LightcoreTutorialStep.openManagers;
    }
    if (_cards.isEmpty && canForgeTowerManager) {
      return LightcoreTutorialStep.forgeTowerManager;
    }
    if (!_tutorialTowerManagerAssigned &&
        _cards.isNotEmpty &&
        builtTowerCount > 0 &&
        !_hasAssignedTowerManagerOnActiveLayer) {
      return LightcoreTutorialStep.assignTowerManager;
    }
    if (_enemyManagers.isEmpty && canForgeEnemyManager) {
      return LightcoreTutorialStep.forgeEnemyManager;
    }
    if (!_tutorialEnemyManagerAssigned &&
        _enemyManagers.isNotEmpty &&
        activeEnemyDeck.isNotEmpty &&
        !_hasAssignedEnemyManagerOnActiveLayer) {
      return LightcoreTutorialStep.assignEnemyManager;
    }
    return null;
  }

  LightcoreTutorialStep? _deriveSocialTutorialStep() {
    if (!hasCustomScreenName) {
      return null;
    }
    if (!_tutorialFriendsOpened) {
      return LightcoreTutorialStep.openFriends;
    }
    if (!mentorshipUnlocked) {
      return null;
    }
    if (!_tutorialMenteesOpened || !_tutorialMentorsOpened) {
      return LightcoreTutorialStep.openMentees;
    }
    return null;
  }

  LightcoreTutorialStep _deriveTutorialStep() {
    final candidate = _deriveTutorialStepCandidate();
    return _tutorialStepAlreadyComplete(candidate)
        ? LightcoreTutorialStep.none
        : candidate;
  }

  LightcoreTutorialStep _deriveTutorialStepCandidate() {
    final coreLearningStep = _deriveCoreLearningTutorialStep();
    if (coreLearningStep != null) {
      return coreLearningStep;
    }
    final introBossDefeated =
        _tutorialFirstBossDefeated || totalBossesDefeated > 0;
    if (_earlyTutorialComplete &&
        !introBossDefeated &&
        activeBossEnemyCard != null &&
        (_tutorialTrackedBossEnemyId != null || bossAlive)) {
      return LightcoreTutorialStep.defeatFirstBoss;
    }
    if (LightcoreController.equipmentReleaseEnabled &&
        !_tutorialFirstEquipmentOpened &&
        introBossDefeated) {
      return LightcoreTutorialStep.openEquipment;
    }
    final managerStep = _deriveManagerTutorialStep();
    if (managerStep != null) {
      return managerStep;
    }
    if (_shouldOfferOverdriveTutorial) {
      final shotStep = _deriveSecondShellShotTutorialStep();
      if (shotStep != null) {
        return shotStep;
      }
      return _tutorialSecondShellShotTapLearned
          ? LightcoreTutorialStep.holdOverdrive
          : LightcoreTutorialStep.none;
    }
    final sidecarStep = _deriveSidecarTutorialStep();
    if (sidecarStep != null) {
      return sidecarStep;
    }
    if (bossHuntsUnlocked) {
      if (!fullThreatMapUnlocked) {
        return LightcoreTutorialStep.openBossPulls;
      }
      if (!hasCompleteEnemySuite) {
        return LightcoreTutorialStep.armFirstBoss;
      }
      if (!introBossDefeated) {
        if (_tutorialTrackedBossEnemyId != null || bossAlive) {
          return LightcoreTutorialStep.defeatFirstBoss;
        }
        return LightcoreTutorialStep.none;
      }
      if (LightcoreController.equipmentReleaseEnabled &&
          !_tutorialFirstEquipmentOpened) {
        return LightcoreTutorialStep.openEquipment;
      }
    }
    final tournamentStep = _deriveTournamentTutorialStep();
    if (tournamentStep == LightcoreTutorialStep.setScreenName) {
      return LightcoreTutorialStep.setScreenName;
    }
    final socialStep = _deriveSocialTutorialStep();
    if (socialStep != null) {
      return socialStep;
    }
    if (tournamentStep != null) {
      return tournamentStep;
    }
    if (bossHuntsUnlocked) {
      return LightcoreTutorialStep.none;
    }
    return LightcoreTutorialStep.none;
  }

  void _syncTutorialStep({bool showBanner = true}) {
    if (!_tutorialEarlyQuestChainCompleted &&
        _currentLayerEarlyTutorialComplete) {
      _tutorialEarlyQuestChainCompleted = true;
    }
    final previousStep = _tutorialStep;
    var nextStep = _deriveTutorialStep();
    if (nextStep == _tutorialStep) {
      return;
    }
    final completedPrevious =
        previousStep != LightcoreTutorialStep.none &&
        _isTutorialStepComplete(previousStep);
    final completionMessage = completedPrevious
        ? _grantTutorialCompletionReward(previousStep)
        : null;
    if (completedPrevious) {
      nextStep = _deriveTutorialStep();
    }
    _tutorialStep = nextStep;
    _ensureTutorialFocusEnemy();
    final prompt = tutorialPrompt;
    if (completionMessage != null) {
      _showBanner(completionMessage, duration: 3.4);
    } else if (showBanner &&
        _tutorialPromptsEnabled &&
        prompt != null &&
        prompt.isNotEmpty) {
      _showBanner(prompt, duration: 4.2);
    }
  }

  String? _grantTutorialCompletionReward(LightcoreTutorialStep step) {
    if (step == LightcoreTutorialStep.none ||
        !_rewardedTutorialSteps.add(step)) {
      return null;
    }

    final lumensGranted = switch (step) {
      LightcoreTutorialStep.unfoldShell => 0,
      LightcoreTutorialStep.waitForFirstHex => 12,
      LightcoreTutorialStep.selectFirstHex => 0,
      LightcoreTutorialStep.buildFirstRedTower => 0,
      LightcoreTutorialStep.tapBattleCore => 36,
      LightcoreTutorialStep.tapFirstTower => 48,
      LightcoreTutorialStep.tapSecondShellTower => 42,
      LightcoreTutorialStep.upgradeFirstTowerToLevel3 => 48,
      LightcoreTutorialStep.raiseThreat => 0,
      LightcoreTutorialStep.readEffectiveGain => 40,
      LightcoreTutorialStep.autoQueueCheck => 120,
      LightcoreTutorialStep.upgradeFirstTowerToLevel4 => 64,
      LightcoreTutorialStep.setFirstEnemyTarget => 45,
      LightcoreTutorialStep.adjustEnemyCount => 55,
      LightcoreTutorialStep.openTowerMatrix => 50,
      LightcoreTutorialStep.upgradeCoreRange => 70,
      LightcoreTutorialStep.openStore => 30,
      LightcoreTutorialStep.openBossPulls => 80,
      LightcoreTutorialStep.armFirstBoss => 90,
      LightcoreTutorialStep.defeatFirstBoss => 120,
      LightcoreTutorialStep.openFriends => 35,
      LightcoreTutorialStep.openMentees => 35,
      LightcoreTutorialStep.openMentors => 35,
      _ => 0,
    };
    final fluxGranted = switch (step) {
      LightcoreTutorialStep.openStore => 8,
      LightcoreTutorialStep.claimBattlePassReward => 5,
      LightcoreTutorialStep.openEquipment => 8,
      LightcoreTutorialStep.openManagers => 12,
      LightcoreTutorialStep.forgeTowerManager => 18,
      LightcoreTutorialStep.assignTowerManager => 12,
      LightcoreTutorialStep.forgeEnemyManager => 20,
      LightcoreTutorialStep.assignEnemyManager => 14,
      LightcoreTutorialStep.holdOverdrive => 10,
      LightcoreTutorialStep.setScreenName => 10,
      LightcoreTutorialStep.inspectEnemyBlitz => 8,
      LightcoreTutorialStep.inspectHexGauntlet => 8,
      LightcoreTutorialStep.inspectArenaFlow => 12,
      _ => 0,
    };
    final scansGranted = switch (step) {
      LightcoreTutorialStep.unfoldShell => 1,
      LightcoreTutorialStep.tapFirstTower => 1,
      LightcoreTutorialStep.pullFirstWhiteEnemy => 0,
      LightcoreTutorialStep.pullFirstRedEnemy => 1,
      LightcoreTutorialStep.openTowerMatrix => 1,
      LightcoreTutorialStep.raiseThreat => 1,
      LightcoreTutorialStep.openStore => 1,
      LightcoreTutorialStep.autoQueueCheck => 1,
      LightcoreTutorialStep.assignEnemyManager => 2,
      LightcoreTutorialStep.openFriends => 1,
      LightcoreTutorialStep.openMentees => 1,
      LightcoreTutorialStep.openMentors => 1,
      _ => 0,
    };

    lumens += lumensGranted;
    flux += fluxGranted;
    enemyTickets += scansGranted;

    final parts = <String>[
      if (lumensGranted > 0)
        LightcoreCurrencyLabels.rewardLumens(lumensGranted),
      if (fluxGranted > 0) LightcoreCurrencyLabels.rewardFlux(fluxGranted),
      if (scansGranted > 0)
        LightcoreCurrencyLabels.rewardThreatScans(scansGranted),
    ];
    final outcome = _tutorialCompletionOutcome(step);
    if (parts.isEmpty) {
      return outcome;
    }
    if (outcome == null) {
      return 'Guide quest complete: ${parts.join(', ')}.';
    }
    return '$outcome Reward: ${parts.join(', ')}.';
  }

  String? _tutorialCompletionOutcome(
    LightcoreTutorialStep step,
  ) => switch (step) {
    LightcoreTutorialStep.unfoldShell =>
      'Core online. The shell can now open lanes and start earning.',
    LightcoreTutorialStep.buildFirstRedTower =>
      'First tower online. It will charge and feed auto-generated packets into the core queue.',
    LightcoreTutorialStep.inspectFirstTowerStats =>
      'Stats mapped. Use power, charge, cooldown, automation, and load to decide what to tune next.',
    LightcoreTutorialStep.tapBattleCore =>
      'Auto-charge verified. The queue fills without repeated core taps.',
    LightcoreTutorialStep.tapFirstTower =>
      'Focus fire learned. Managers later take over firing when you want automation.',
    LightcoreTutorialStep.upgradeFirstTowerToLevel3 =>
      'Anchor tower tuned. Higher tower levels make every queued packet hit harder.',
    LightcoreTutorialStep.raiseThreat =>
      'Threat raised. The starter region is now testing that upgraded tower.',
    LightcoreTutorialStep.pullFirstWhiteEnemy =>
      'Safe signature added. Threat Scans shape the encounter, not your tower roster.',
    LightcoreTutorialStep.readEffectiveGain =>
      'Flow mapped. Better threats only matter when Output Efficiency stays healthy.',
    LightcoreTutorialStep.assignTowerManager =>
      'Manager assigned. Payload feed now runs with better automation.',
    LightcoreTutorialStep.autoQueueCheck =>
      'Automation verified. The queue keeps moving while you focus on targets.',
    LightcoreTutorialStep.upgradeFirstTowerToLevel4 =>
      'Opening lane reinforced. Strong anchors handle denser pressure better.',
    LightcoreTutorialStep.pullFirstRedEnemy =>
      'Red signature added. Same-color resistance is why mixed colors matter.',
    LightcoreTutorialStep.setFirstEnemyTarget =>
      'Red pressure reviewed. Same-color resistance is active in the deck.',
    LightcoreTutorialStep.adjustEnemyCount =>
      'Region pressure reviewed. Higher pressure can pay more, but watch Output Efficiency.',
    LightcoreTutorialStep.openBossPulls =>
      'Starter region stabilized. The next route region opens after every region is fully stabilized.',
    LightcoreTutorialStep.upgradeCoreRange =>
      'Global stat assigned. Account upgrades make every shell easier to grow.',
    _ => null,
  };

  List<EnemyCardState> _createEnemyCardInventory() {
    return <EnemyCardState>[
      EnemyCardState(config: EnemyLibrary.starterDefault),
      ...EnemyLibrary.all.map((config) => EnemyCardState(config: config)),
    ];
  }

  List<EnemyCardState> _createBossEnemyCardInventory() {
    return BossEnemyLibrary.all
        .map(
          (config) => EnemyCardState(
            config: config,
            unlocked: config.id == BossEnemyLibrary.starterWhiteWarden.id,
            copies: config.id == BossEnemyLibrary.starterWhiteWarden.id ? 1 : 0,
          ),
        )
        .toList(growable: false);
  }

  void _ensureStarterBossCardAvailable() {
    final starterId = BossEnemyLibrary.starterWhiteWarden.id;
    final cardIndex = _bossEnemyCards.indexWhere(
      (card) => card.config.id == starterId,
    );
    if (cardIndex == -1) {
      return;
    }
    final current = _bossEnemyCards[cardIndex];
    if (current.isOwned && current.copies > 0) {
      return;
    }
    _bossEnemyCards[cardIndex] = current.copyWith(
      unlocked: true,
      copies: max(1, current.copies),
    );
  }

  void _armStarterBossForOpening() {
    if (_layers.isEmpty) {
      return;
    }
    final starterId = BossEnemyLibrary.starterWhiteWarden.id;
    _ensureStarterBossCardAvailable();
    if (!bossHuntsUnlocked || _activeBossEnemyCardId == null) {
      _activeBossEnemyCardId = starterId;
      activeLayer.activeBossEnemyCardId = starterId;
    }

    final introBossDefeated =
        _tutorialFirstBossDefeated || totalBossesDefeated > 0;
    if (introBossDefeated) {
      return;
    }
    final liveStarterBosses = _enemies.where(
      (enemy) => enemy.config.id == starterId,
    );
    if (_tutorialTrackedBossEnemyId == null && liveStarterBosses.isNotEmpty) {
      _tutorialTrackedBossEnemyId = liveStarterBosses.first.id;
    }
    if (!bossAlive &&
        !activeLayer.bossReady &&
        activeLayer.normalKillsSinceBoss >= bossSpawnKillRequirement) {
      activeLayer.bossReady = true;
    }
    _tutorialIntroBossPending = true;
    if (activeLayer.bossReady) {
      _spawnTimer = min(_spawnTimer, 0.05);
    }
  }

  EnemyConfig? _scriptedEnemyPullForTutorial() {
    final firstTower = _firstTutorialTower;
    if (firstTower?.config?.id != TowerLibrary.redPrism.id ||
        builtTowerCount > 1) {
      return null;
    }
    if (enemyPullCount == 0) {
      return EnemyLibrary.basicWhite;
    }
    if (enemyPullCount == 1) {
      return EnemyLibrary.basicRed;
    }
    return null;
  }

  EnemyConfig? _scriptedBossPull() {
    if (!bossHuntsUnlocked || bossPullCount > 0) {
      return null;
    }
    return BossEnemyLibrary.byRarity[EnemyCardRarity.basic]!.firstWhere(
      (config) => config.id != BossEnemyLibrary.starterWhiteWarden.id,
      orElse: () => BossEnemyLibrary.starterWhiteWarden,
    );
  }

  double get _layer1OpeningCadenceMultiplier {
    if (activeLayer.tier != 1) {
      return 1.0;
    }
    return switch (_tutorialStep) {
      LightcoreTutorialStep.none => _tutorialFirstBossDefeated ? 1.0 : 1.08,
      LightcoreTutorialStep.unfoldShell ||
      LightcoreTutorialStep.waitForFirstHex ||
      LightcoreTutorialStep.selectFirstHex ||
      LightcoreTutorialStep.buildFirstRedTower ||
      LightcoreTutorialStep.inspectFirstTowerStats ||
      LightcoreTutorialStep.tapBattleCore ||
      LightcoreTutorialStep.tapFirstTower ||
      LightcoreTutorialStep.tapSecondShellTower ||
      LightcoreTutorialStep.upgradeFirstTowerToLevel3 ||
      LightcoreTutorialStep.raiseThreat ||
      LightcoreTutorialStep.pullFirstWhiteEnemy ||
      LightcoreTutorialStep.readEffectiveGain ||
      LightcoreTutorialStep.autoQueueCheck ||
      LightcoreTutorialStep.upgradeFirstTowerToLevel4 ||
      LightcoreTutorialStep.pullFirstRedEnemy ||
      LightcoreTutorialStep.setFirstEnemyTarget ||
      LightcoreTutorialStep.adjustEnemyCount ||
      LightcoreTutorialStep.openTowerMatrix ||
      LightcoreTutorialStep.upgradeCoreRange ||
      LightcoreTutorialStep.openStore => 1.26,
      _ => 1.08,
    };
  }

  String _progressionUnlockBannerFragment(int previousProgressionLayer) {
    final unlocks = <String>[];
    if (previousProgressionLayer < payloadUnlockLayer && payloadsUnlocked) {
      unlocks.add('Promoted payload traits are now live.');
    }
    return unlocks.isEmpty ? '' : ' ${unlocks.join(' ')}';
  }

  TowerLayerSnapshot _freshLayerSnapshot({
    required String label,
    required int tier,
    CoreState? inheritedCore,
    Layer2TowerState? inheritedLayer2,
    List<String>? initialEnemyDeck,
    String? parentLayerId,
    int? parentSlotIndex,
    String? sourceLayerId,
  }) {
    final core =
        inheritedCore ??
        CoreState(
          flowEfficiency: _maxFlowEfficiency,
          fireCooldownRemaining: 0,
          level: 1,
          projectileType: ProjectileType.starBolt,
          payloadType: PayloadType.none,
          affinity: PrototypeAffinity.neutral,
          coreUpgradeOptions: _rollCoreUpgradeBoardForLoadout(
            ProjectileType.starBolt,
            PayloadType.none,
          ),
        );
    return TowerLayerSnapshot(
      id: 'layer_${_layers.length}_${DateTime.now().microsecondsSinceEpoch}',
      tier: tier,
      label: label,
      slots: List<OuterTowerState>.generate(
        slotCount,
        (index) => OuterTowerState(slotIndex: index),
      ),
      core: core,
      layer2:
          inheritedLayer2 ??
          const Layer2TowerState(
            unlocked: false,
            count: 0,
            fireCooldownRemaining: 0,
          ),
      enemies: <EnemyState>[],
      pulses: <EnergyPulseState>[],
      shots: <CoreShotState>[],
      impacts: <ImpactState>[],
      ammoQueue: <AmmoPacket>[],
      activeEnemyCardIds: List<String>.from(
        (initialEnemyDeck == null || initialEnemyDeck.isEmpty)
            ? <String>[EnemyLibrary.basicWhite.id]
            : initialEnemyDeck,
      ),
      enemyTargetCount: initialEnemyTarget,
      enemyTargetUpgradeLevel: 0,
      outerRingRevealed: false,
      swarmActivated: false,
      elapsed: 0,
      spawnTimer: 1.0,
      spawnSequence: 0,
      enemyCounter: 0,
      pulseCounter: 0,
      shotCounter: 0,
      impactCounter: 0,
      normalKillsSinceBoss: 0,
      bossReady: false,
      childTowerUpgrades: parentLayerId == null
          ? <ChildTowerUpgradeState>[]
          : _rollChildTowerUpgradeBoard(),
      activeBossEnemyCardId: _activeBossEnemyCardId,
      parentLayerId: parentLayerId,
      parentSlotIndex: parentSlotIndex,
      sourceLayerId: sourceLayerId,
      selectedEnemyCardId:
          (initialEnemyDeck == null || initialEnemyDeck.isEmpty)
          ? EnemyLibrary.basicWhite.id
          : initialEnemyDeck.first,
    );
  }

  CoreState _childCoreForSelectedAffinity(
    PrototypeAffinity affinity, {
    required int childTier,
  }) {
    final projectileLoadout = forgedProjectilesForAffinity(
      affinity,
      targetTier: childTier,
    );
    final payloadLoadout = forgedPayloadsForAffinity(
      affinity,
      targetTier: childTier,
    );
    return CoreState(
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      level: max(1, childTier),
      projectileType: projectileLoadout.first,
      payloadType: payloadLoadout.first,
      affinity: affinity,
      secondaryAffinity: childTier < payloadUnlockLayer ? null : affinity,
      projectileLoadout: projectileLoadout,
      payloadLoadout: payloadLoadout,
      coreUpgradeOptions: _rollCoreUpgradeBoardForLoadout(
        projectileLoadout.first,
        payloadLoadout.first,
      ),
    );
  }

  void _loadLayer(TowerLayerSnapshot layer) {
    _activeLayerId = layer.id;
    _slots = List<OuterTowerState>.from(layer.slots);
    layer.slots = _slots;
    _core = layer.core;
    if (_core.coreUpgradeOptions.isEmpty) {
      _core = _core.copyWith(
        coreUpgradeOptions: _rollCoreUpgradeBoardForLoadout(
          _core.projectileLoadout.isEmpty
              ? _core.projectileType
              : _core.projectileLoadout.first,
          _core.payloadLoadout.isEmpty
              ? _core.payloadType
              : _core.payloadLoadout.first,
        ),
      );
      layer.core = _core;
    }
    _layer2 = layer.layer2;
    _enemies = List<EnemyState>.from(layer.enemies);
    layer.enemies = _enemies;
    _pulses = List<EnergyPulseState>.from(layer.pulses);
    layer.pulses = _pulses;
    _shots = List<CoreShotState>.from(layer.shots);
    layer.shots = _shots;
    _impacts = List<ImpactState>.from(layer.impacts);
    layer.impacts = _impacts;
    _ammoQueue = List<AmmoPacket>.from(layer.ammoQueue);
    layer.ammoQueue = _ammoQueue;
    if (layer.activeEnemyCardIds.isEmpty ||
        (layer.activeEnemyCardIds.length == 1 &&
            layer.activeEnemyCardIds.single ==
                EnemyLibrary.starterDefault.id)) {
      layer.activeEnemyCardIds = <String>[EnemyLibrary.basicWhite.id];
    }
    _activeEnemyCardIds = List<String>.from(layer.activeEnemyCardIds);
    layer.activeEnemyCardIds = _activeEnemyCardIds;
    _activeBossEnemyCardId = layer.activeBossEnemyCardId;
    _normalizeThreatAssignmentPresetSelection(layer);
    _enemyTargetUpgradeLevel = _normalizeEnemyTargetUpgradeLevel(
      layer.enemyTargetUpgradeLevel,
    );
    _enemyTargetCount = _normalizeEnemyTargetCount(
      layer.enemyTargetCount,
      upgradeLevel: _enemyTargetUpgradeLevel,
    );
    _outerRingRevealed = layer.outerRingRevealed;
    _swarmActivated = layer.swarmActivated;
    selectedSlotIndex = layer.selectedSlotIndex;
    _towerRangePreviewSlotIndex = null;
    selectedEnemyCardId =
        layer.selectedEnemyCardId ?? _activeEnemyCardIds.first;
    elapsed = layer.elapsed;
    _spawnTimer = layer.spawnTimer;
    _spawnSequence = layer.spawnSequence;
    _activeSpawnClusterIndex = null;
    _enemyCounter = layer.enemyCounter;
    _pulseCounter = layer.pulseCounter;
    _shotCounter = layer.shotCounter;
    _impactCounter = layer.impactCounter;
    _blueFocusTargetEnemyIdBySlot.clear();
    if (!_swarmActivated && layer.id == _viewLayerId) {
      _resetManualOverdrive();
    }
    _updateFlowEfficiency();
  }

  void _normalizeCoreManagerAssignments() {
    for (final layer in _layers) {
      int? towerManagerIndex;
      for (var index = 0; index < _cards.length; index++) {
        final card = _cards[index];
        if (card.equippedLayerId != layer.id) {
          continue;
        }
        if (towerManagerIndex == null ||
            (card.equippedSlotIndex == null &&
                _cards[towerManagerIndex].equippedSlotIndex != null)) {
          towerManagerIndex = index;
        }
      }
      if (towerManagerIndex != null) {
        for (var index = 0; index < _cards.length; index++) {
          final card = _cards[index];
          if (card.equippedLayerId != layer.id) {
            continue;
          }
          _cards[index] = index == towerManagerIndex
              ? card.copyWith(
                  equippedLayerId: layer.id,
                  clearEquippedSlotIndex: true,
                )
              : card.copyWith(clearEquippedSlot: true);
        }
      }

      int? enemyManagerIndex;
      for (var index = 0; index < _enemyManagers.length; index++) {
        final manager = _enemyManagers[index];
        if (manager.assignedLayerId != layer.id) {
          continue;
        }
        if (enemyManagerIndex == null ||
            (manager.assignedEnemyCardId == null &&
                _enemyManagers[enemyManagerIndex].assignedEnemyCardId !=
                    null)) {
          enemyManagerIndex = index;
        }
      }
      if (enemyManagerIndex != null) {
        for (var index = 0; index < _enemyManagers.length; index++) {
          final manager = _enemyManagers[index];
          if (manager.assignedLayerId != layer.id) {
            continue;
          }
          _enemyManagers[index] = index == enemyManagerIndex
              ? manager.copyWith(
                  assignedLayerId: layer.id,
                  clearAssignedEnemyCard: true,
                )
              : manager.copyWith(clearAssignment: true);
        }
      }

      for (var slotIndex = 0; slotIndex < layer.slots.length; slotIndex++) {
        final slot = layer.slots[slotIndex];
        if (slot.equippedCardInstanceId != null) {
          layer.slots[slotIndex] = slot.copyWith(
            automationCooldownRemaining: 0,
            clearEquippedCard: true,
          );
        }
      }
    }
  }

  void _storeActiveLayer() {
    final layer = activeLayer;
    layer.slots = _slots;
    layer.core = _core;
    layer.layer2 = _layer2;
    layer.enemies = _enemies;
    layer.pulses = _pulses;
    layer.shots = _shots;
    layer.impacts = _impacts;
    layer.ammoQueue = _ammoQueue;
    layer.activeEnemyCardIds = _activeEnemyCardIds;
    layer.activeBossEnemyCardId = _activeBossEnemyCardId;
    layer.enemyTargetCount = _enemyTargetCount;
    layer.enemyTargetUpgradeLevel = _enemyTargetUpgradeLevel;
    layer.outerRingRevealed = _outerRingRevealed;
    layer.swarmActivated = _swarmActivated;
    layer.selectedSlotIndex = selectedSlotIndex;
    layer.selectedEnemyCardId = selectedEnemyCardId;
    layer.elapsed = elapsed;
    layer.spawnTimer = _spawnTimer;
    layer.spawnSequence = _spawnSequence;
    layer.enemyCounter = _enemyCounter;
    layer.pulseCounter = _pulseCounter;
    layer.shotCounter = _shotCounter;
    layer.impactCounter = _impactCounter;
    layer.normalKillsSinceBoss = activeLayer.normalKillsSinceBoss;
    layer.bossReady = activeLayer.bossReady;
    _syncParentSlotFromLayer(layer);
  }

  void _syncParentSlotFromLayer(TowerLayerSnapshot layer) {
    final parentId = layer.parentLayerId;
    final parentSlotIndex = layer.parentSlotIndex;
    if (parentId == null || parentSlotIndex == null) {
      return;
    }
    final parent = _layerById(parentId);
    final slot = parent.slots[parentSlotIndex];
    final forgedTraits = _resolvePromotedTraitLoadoutForLayer(
      layer,
      targetTier: parent.tier,
    );
    final projectileLoadout = forgedTraits.projectileLoadout;
    final payloadLoadout = forgedTraits.payloadLoadout;
    final forgedAffinity = forgedTraits.projectileAffinity;
    final forgedProjectile = projectileLoadout.first;
    final forgedPayload = payloadLoadout.first;
    final averagedRange = _averageRangeForLayer(layer);
    final averagedGeneration = _averageGenerationForLayer(layer);
    final averagedCritChance = _averageCritChanceForLayer(layer);
    final averagedCritMultiplier = _averageCritMultiplierForLayer(layer);
    final averagedFinalDamage = _averageFinalDamageForLayer(layer);
    final averagedBossDamage = _averageBossDamageForLayer(layer);
    final averagedNormalDamage = _averageNormalDamageForLayer(layer);
    final averagedDefensePenetration = _averageDefensePenetrationForLayer(
      layer,
    );
    final averagedMinDamage = _averageMinDamageForLayer(layer);
    final averagedMaxDamage = _averageMaxDamageForLayer(layer);
    final powerBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.power,
    );
    final chargeBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.chargeRate,
    );
    final cooldownBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.cooldown,
    );
    final rangeBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.range,
    );
    final generationBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.generationSpeed,
    );
    final critChanceBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.critChance,
    );
    final critDamageBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.critDamage,
    );
    final finalDamageBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.finalDamage,
    );
    final bossDamageBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.bossDamage,
    );
    final normalDamageBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.normalDamage,
    );
    final defensePenetrationBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.defensePenetration,
    );
    final minDamageBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.minDamage,
    );
    final maxDamageBonus = _childTowerUpgradeBonusForLayer(
      layer,
      ChildTowerUpgradeType.maxDamage,
    );
    final towerUpgradeOptions = layer.promotedIntoParentSlot
        ? (slot.towerUpgradeOptions.isNotEmpty
              ? slot.towerUpgradeOptions
              : _rollTowerUpgradeBoardForLoadout(
                  forgedProjectile,
                  forgedPayload,
                ))
        : const <TowerUpgradeOptionState>[];
    parent.slots[parentSlotIndex] = slot.copyWith(
      level: layer.promotedIntoParentSlot ? max(1, slot.level) : slot.level,
      towerUpgradeOptions: towerUpgradeOptions,
      childLayerId: layer.id,
      childLayerTier: parent.tier,
      childLayerName: layerDisplayLabel(layer),
      childAffinity: forgedAffinity,
      childSecondaryAffinity: forgedTraits.payloadAffinity,
      childProjectileLoadout: projectileLoadout,
      childPayloadLoadout: payloadLoadout,
      childProjectileType: forgedProjectile,
      childPayloadType: forgedPayload,
      childCoreLevel: layer.core.level,
      childRange: averagedRange,
      childGenerationSpeed: averagedGeneration,
      childCritChance: averagedCritChance,
      childCritMultiplier: averagedCritMultiplier,
      childFinalDamageMultiplier: averagedFinalDamage,
      childBossDamageMultiplier: averagedBossDamage,
      childNormalDamageMultiplier: averagedNormalDamage,
      childDefensePenetration: averagedDefensePenetration,
      childMinDamageMultiplier: averagedMinDamage,
      childMaxDamageMultiplier: averagedMaxDamage,
      childPowerUpgradeBonus: powerBonus,
      childChargeUpgradeBonus: chargeBonus,
      childCooldownUpgradeBonus: cooldownBonus,
      childRangeUpgradeBonus: rangeBonus,
      childGenerationUpgradeBonus: generationBonus,
      childCritChanceUpgradeBonus: critChanceBonus,
      childCritDamageUpgradeBonus: critDamageBonus,
      childFinalDamageUpgradeBonus: finalDamageBonus,
      childBossDamageUpgradeBonus: bossDamageBonus,
      childNormalDamageUpgradeBonus: normalDamageBonus,
      childDefensePenetrationUpgradeBonus: defensePenetrationBonus,
      childMinDamageUpgradeBonus: minDamageBonus,
      childMaxDamageUpgradeBonus: maxDamageBonus,
      childBuiltCount: layer.slots.where(_slotCountsTowardRing).length,
      childPromoted: layer.promotedIntoParentSlot,
      clearEquippedCard: true,
    );
  }

  void _enterLayer(String layerId, {String? banner}) {
    _storeActiveLayer();
    final nextLayer = _layerById(layerId);
    _viewLayerId = layerId;
    _runtimeLayerId = _liveLayerForLayer(nextLayer).id;
    _loadLayer(nextLayer);
    if (banner != null) {
      _showBanner(banner);
    }
    _notifyNow();
  }

  ProjectileType towerProjectileType(OuterTowerState tower) =>
      _slotProjectileType(tower);

  String towerProjectileLabel(OuterTowerState tower) =>
      towerProjectileType(tower).label;

  ProjectileType towerDefaultProjectileType(OuterTowerState tower) {
    if (tower.config != null) {
      return tower.projectileType ?? tower.config!.defaultProjectileType;
    }
    final loadout = tower.childProjectileLoadout;
    return tower.childProjectileType ??
        (loadout.isNotEmpty ? loadout.first : null) ??
        ProjectileType.threadBeam;
  }

  String towerDefaultProjectileLabel(OuterTowerState tower) =>
      towerDefaultProjectileType(tower).label;

  List<ProjectileType> towerProjectileArsenal(OuterTowerState tower) =>
      List<ProjectileType>.unmodifiable(_slotProjectileLoadout(tower));

  String towerProjectileArsenalLabel(OuterTowerState tower) =>
      _towerHasRainbowLoadout(tower)
      ? 'All Prism projectiles'
      : _arsenalSummary(_slotProjectileLoadout(tower));

  String towerPayloadLabel(OuterTowerState tower) =>
      _slotPayloadType(tower).label;

  PayloadType towerPayloadType(OuterTowerState tower) =>
      _slotPayloadType(tower);

  List<PayloadType> towerPayloadArsenal(OuterTowerState tower) =>
      List<PayloadType>.unmodifiable(_slotPayloadLoadout(tower));

  String towerPayloadArsenalLabel(OuterTowerState tower) =>
      _towerHasRainbowLoadout(tower)
      ? 'All Prism payloads'
      : _arsenalSummary(_slotPayloadLoadout(tower));

  String towerAffinitySignatureLabel(OuterTowerState tower) =>
      _towerHasRainbowLoadout(tower)
      ? 'Rainbow tower'
      : _traitSignatureLabel(
          _slotAffinity(tower),
          _slotSecondaryAffinity(tower),
        );

  String get corePayloadLabel => _corePayloadType.label;

  String get coreProjectileLabel => _coreProjectileType.label;

  List<ProjectileType> get coreProjectileArsenal =>
      List<ProjectileType>.unmodifiable(_coreProjectileLoadout);

  String get coreProjectileArsenalLabel => _coreHasRainbowLoadout
      ? 'All Prism projectiles'
      : _arsenalSummary(_coreProjectileLoadout);

  List<PayloadType> get corePayloadArsenal =>
      List<PayloadType>.unmodifiable(_corePayloadLoadout);

  String get corePayloadArsenalLabel => _coreHasRainbowLoadout
      ? 'All Prism payloads'
      : _arsenalSummary(_corePayloadLoadout);

  String get coreAffinitySignatureLabel => _coreHasRainbowLoadout
      ? 'Rainbow tower'
      : _traitSignatureLabel(_core.affinity, _core.secondaryAffinity);

  String get payloadUnlockLabel => payloadsUnlocked
      ? 'Promoted payloads online'
      : 'Payloads unlock in the Prism Shell';

  String get managerUnlockLabel => managersUnlocked
      ? 'Managers online'
      : 'Managers unlock when a Layer 1 shell has all $slotCount outer towers online';

  String get managerAssignmentUnlockLabel => managerAssignmentUnlocked
      ? 'Manager assignment online'
      : 'Manager assignment unlocks when this Layer 1 shell has all $slotCount outer towers online';

  int promotedChildTowerRerollsUsed(OuterTowerState tower) {
    return 0;
  }

  int promotedChildTowerRerollsRemaining(OuterTowerState tower) => 0;

  String promotedChildTowerRerollLabel(OuterTowerState tower) {
    return 'Disabled';
  }

  bool canRerollPromotedChildTower(OuterTowerState tower) => false;

  TargetPriority towerTargetPriority(OuterTowerState tower) =>
      towerTargetPriorityForProjectile(tower, towerProjectileType(tower));

  TargetPriority towerTargetPriorityForProjectile(
    OuterTowerState tower,
    ProjectileType projectileType,
  ) => tower.projectileTargetPriorities[projectileType] ?? tower.targetPriority;

  String towerTargetLabel(OuterTowerState tower) =>
      towerTargetPriority(tower).label;

  String towerTargetLabelForProjectile(
    OuterTowerState tower,
    ProjectileType projectileType,
  ) => towerTargetPriorityForProjectile(tower, projectileType).label;

  String towerPatternAchievementLabel(OuterTowerState tower) {
    if (!_slotCountsTowardRing(tower)) {
      return 'None';
    }
    final achievements = activeTowerAchievements;
    if (achievements.isEmpty) {
      return 'None';
    }
    return achievements.map((achievement) => achievement.name).join(' + ');
  }

  String towerRangeLabel(OuterTowerState tower) =>
      (towerUsesPersistentShieldRing(tower)
              ? towerShieldRingRadius(tower)
              : towerEffectiveRange(tower))
          .toStringAsFixed(0);

  String towerDefaultProjectileRangeLabel(OuterTowerState tower) =>
      (towerUsesPersistentShieldRing(tower)
              ? towerShieldRingRadius(tower)
              : towerEffectiveRangeForProjectile(
                  tower,
                  towerDefaultProjectileType(tower),
                ))
          .toStringAsFixed(0);

  String towerGenerationLabel(OuterTowerState tower) =>
      towerUsesPersistentShieldRing(tower)
      ? 'Persistent'
      : towerGenerationSpeed(tower).toStringAsFixed(2);

  String towerCritLabel(OuterTowerState tower) =>
      '${(towerCritChance(tower) * 100).toStringAsFixed(0)}% x${towerCritMultiplier(tower).toStringAsFixed(2)}';

  String towerDamageRangeLabel(OuterTowerState tower) =>
      '${(towerMinDamageMultiplier(tower) * 100).toStringAsFixed(0)}-${(towerMaxDamageMultiplier(tower) * 100).toStringAsFixed(0)}%';

  String towerMinDamageLabel(OuterTowerState tower) =>
      '${(towerMinDamageMultiplier(tower) * 100).toStringAsFixed(0)}%';

  String towerMaxDamageLabel(OuterTowerState tower) =>
      '${(towerMaxDamageMultiplier(tower) * 100).toStringAsFixed(0)}%';

  String towerFinalDamageLabel(OuterTowerState tower) =>
      '+${((towerFinalDamageMultiplier(tower) - 1) * 100).toStringAsFixed(0)}%';

  String towerBossDamageLabel(OuterTowerState tower) =>
      '+${((towerBossDamageMultiplier(tower) - 1) * 100).toStringAsFixed(0)}%';

  String towerNormalDamageLabel(OuterTowerState tower) =>
      '+${((towerNormalDamageMultiplier(tower) - 1) * 100).toStringAsFixed(0)}%';

  String towerDefensePenetrationLabel(OuterTowerState tower) =>
      '${(towerDefensePenetration(tower) * 100).toStringAsFixed(0)}%';

  String towerDotDamageLabel(OuterTowerState tower) =>
      '+${((towerDotDamageMultiplier(tower) - 1) * 100).toStringAsFixed(0)}%';

  String get overallLevelProgressLabel =>
      'Account Radiance Lv $accountRadianceLevel • $experienceIntoCurrentOverallLevel/$experienceNeededForCurrentOverallLevel EXP';

  String get sharedRelayExperienceMultiplierLabel =>
      'x${sharedRelayExperienceMultiplier.toStringAsFixed(2)} EXP';

  String get guildExperienceMultiplierLabel =>
      'x${guildExperienceMultiplier.toStringAsFixed(2)} EXP';

  String get guildCombatMultiplierLabel =>
      'x${guildCombatMultiplier.toStringAsFixed(2)} combat';

  String get guildRewardMultiplierLabel =>
      'x${guildRewardMultiplier.toStringAsFixed(2)} rewards';

  String get friendAllianceCombatMultiplierLabel =>
      'x${friendAllianceCombatMultiplier.toStringAsFixed(2)} combat';

  String get friendAllianceRewardMultiplierLabel =>
      'x${friendAllianceRewardMultiplier.toStringAsFixed(2)} rewards';

  String get bossSpawnStatusLabel {
    final boss = activeBossEnemyCard;
    if (!bossHuntsUnlocked && boss == null) {
      return 'Regional boss changes unlock in the Prism Shell.';
    }
    if (ownedBossEnemyCardCount == 0) {
      return activeLayer.bossReady
          ? 'Apex lane primed. Pull an Apex Anomaly card to arm the next spawn.'
          : 'No Apex Anomaly armed yet. Pull your first Apex Anomaly card.';
    }
    if (bossAlive) {
      return '${boss?.config.name ?? 'Apex Anomaly'} is active in the field.';
    }
    if (activeLayer.bossReady) {
      return '${boss?.config.name ?? 'Apex Anomaly'} is queued for the next spawn.';
    }
    return '$bossKillsRemaining anomaly clears until ${boss?.config.name ?? 'the next Apex Anomaly'}.';
  }

  String? get tutorialHeadline =>
      tutorialQuestDefinition?.title ??
      switch (_tutorialStep) {
        LightcoreTutorialStep.none => null,
        LightcoreTutorialStep.unfoldShell => 'Unfold The Shell',
        LightcoreTutorialStep.waitForFirstHex => 'Hex 1 Ready',
        LightcoreTutorialStep.selectFirstHex => 'Select Hex 1',
        LightcoreTutorialStep.buildFirstRedTower => 'Choose First Tower',
        LightcoreTutorialStep.inspectFirstTowerStats => 'Read Tower Stats',
        LightcoreTutorialStep.tapBattleCore => 'Auto-Feed Ready',
        LightcoreTutorialStep.tapFirstTower => 'Focus Fire',
        LightcoreTutorialStep.tapSecondShellTower => 'Fire Child Tower',
        LightcoreTutorialStep.upgradeFirstTowerToLevel3 =>
          'Tune The Main Tower',
        LightcoreTutorialStep.raiseThreat => 'Raise Threat',
        LightcoreTutorialStep.pullFirstWhiteEnemy => 'Open Knowledge Cards',
        LightcoreTutorialStep.readEffectiveGain => 'Read Effective Gain',
        LightcoreTutorialStep.autoQueueCheck => 'Auto Queue Check',
        LightcoreTutorialStep.upgradeFirstTowerToLevel4 =>
          'Reinforce The Anchor',
        LightcoreTutorialStep.pullFirstRedEnemy => 'Teach Color Counters',
        LightcoreTutorialStep.setFirstEnemyTarget => 'Review Red Pressure',
        LightcoreTutorialStep.adjustEnemyCount => 'Read Spiral Path',
        LightcoreTutorialStep.openTowerMatrix => 'Inspect Tower Lists',
        LightcoreTutorialStep.upgradeCoreRange => 'Upgrade A Global Stat',
        LightcoreTutorialStep.openStore => 'Inspect The Store',
        LightcoreTutorialStep.claimBattlePassReward => 'Claim A Pass Reward',
        LightcoreTutorialStep.openBossPulls => 'Stabilize A Region',
        LightcoreTutorialStep.armFirstBoss => 'Set A Knowledge Book',
        LightcoreTutorialStep.defeatFirstBoss => 'Clear The Region Boss',
        LightcoreTutorialStep.openEquipment => 'Check Profile',
        LightcoreTutorialStep.openManagers => 'Inspect The Foundry',
        LightcoreTutorialStep.forgeTowerManager => 'Forge A Core Manager',
        LightcoreTutorialStep.assignTowerManager => 'Assign A Core Manager',
        LightcoreTutorialStep.forgeEnemyManager => 'Forge A Threat Director',
        LightcoreTutorialStep.assignEnemyManager => 'Assign A Threat Director',
        LightcoreTutorialStep.holdOverdrive => 'Hold Overdrive',
        LightcoreTutorialStep.setScreenName => 'Claim Your Screen Name',
        LightcoreTutorialStep.openFriends => 'Inspect Friends',
        LightcoreTutorialStep.openMentees => 'Inspect Mentorship',
        LightcoreTutorialStep.openMentors => 'Inspect Mentorship',
        LightcoreTutorialStep.inspectEnemyBlitz => 'Inspect Anomaly Blitz',
        LightcoreTutorialStep.inspectHexGauntlet => 'Inspect Hex Gauntlet',
        LightcoreTutorialStep.inspectArenaFlow => 'Inspect Arena Flow',
      };

  String? get tutorialPrompt =>
      tutorialQuestDefinition?.coachCopy ??
      switch (_tutorialStep) {
        LightcoreTutorialStep.none => null,
        LightcoreTutorialStep.unfoldShell =>
          'Click the center core to wake the shell.',
        LightcoreTutorialStep.waitForFirstHex => 'Click Hex 1.',
        LightcoreTutorialStep.selectFirstHex => 'Click Hex 1.',
        LightcoreTutorialStep.buildFirstRedTower =>
          'Click Hex 1 and choose Comet Mortar or Rayline Spire.',
        LightcoreTutorialStep.inspectFirstTowerStats =>
          'Open the first tower stats pop-out.',
        LightcoreTutorialStep.tapBattleCore =>
          'Tap a visible anomaly. Auto-feed will supply the next packet.',
        LightcoreTutorialStep.tapFirstTower =>
          'Tap a visible anomaly to focus fire. Tower taps open tower controls.',
        LightcoreTutorialStep.tapSecondShellTower =>
          'Tap the charged child-shell tower to feed the Lightcore.',
        LightcoreTutorialStep.upgradeFirstTowerToLevel3 =>
          'Click the first tower in Hex 1 and upgrade it once.',
        LightcoreTutorialStep.raiseThreat =>
          'Click Challenge Lv 1 on the battlefield to raise anomaly pressure.',
        LightcoreTutorialStep.pullFirstWhiteEnemy =>
          'Click Map and run 1 threat scan.',
        LightcoreTutorialStep.readEffectiveGain =>
          'Tap Output Efficiency to inspect Effective Gain.',
        LightcoreTutorialStep.autoQueueCheck =>
          'Watch your manager spend 5 queued pulses automatically.',
        LightcoreTutorialStep.upgradeFirstTowerToLevel4 =>
          'Click the first tower in Hex 1 and upgrade it to level 3.',
        LightcoreTutorialStep.pullFirstRedEnemy =>
          'Click Map and start the next stabilization challenge.',
        LightcoreTutorialStep.setFirstEnemyTarget =>
          'Click Anomalies and review Basic Red in the active deck.',
        LightcoreTutorialStep.adjustEnemyCount =>
          'Click Map and inspect the linear route and stabilization controls.',
        LightcoreTutorialStep.openTowerMatrix =>
          'Click Towers to inspect completed Layer 1 sets and Layer 2 shell tools.',
        LightcoreTutorialStep.upgradeCoreRange =>
          'Open Profile and add one Global Attribute point.',
        LightcoreTutorialStep.openStore =>
          'Click Store and inspect the resource offers.',
        LightcoreTutorialStep.claimBattlePassReward =>
          'Click Passes and claim a reward.',
        LightcoreTutorialStep.openBossPulls =>
          'Click Map and stabilize the starter region.',
        LightcoreTutorialStep.armFirstBoss =>
          'Click Anomalies, open Apex, and review the enemy suite pieces from regional bosses.',
        LightcoreTutorialStep.defeatFirstBoss =>
          'Go back to battle and defeat White Warden.',
        LightcoreTutorialStep.openEquipment =>
          'Click the profile HUD and review account attributes.',
        LightcoreTutorialStep.openManagers => 'Click Managers.',
        LightcoreTutorialStep.forgeTowerManager =>
          'Click Managers and forge 1 Core Manager.',
        LightcoreTutorialStep.assignTowerManager =>
          'Click a Core Manager tile, then assign it to the shell.',
        LightcoreTutorialStep.forgeEnemyManager =>
          'Click Managers and forge 1 Threat Director.',
        LightcoreTutorialStep.assignEnemyManager =>
          'Click a Threat Director tile, then assign it to the selected region.',
        LightcoreTutorialStep.holdOverdrive =>
          'Hold the Overdrive button until the battle speeds up.',
        LightcoreTutorialStep.setScreenName =>
          'Open Menu, select Settings, then Change Name, and set your screen name.',
        LightcoreTutorialStep.openFriends =>
          'Open Menu, select Friends, and inspect requests plus Threat Scan gifts.',
        LightcoreTutorialStep.openMentees =>
          'Open Menu, select Mentorship, and inspect your mentor plus mentee network.',
        LightcoreTutorialStep.openMentors =>
          'Open Menu, select Mentorship, and inspect your mentor plus mentee network.',
        LightcoreTutorialStep.inspectEnemyBlitz =>
          'Open Menu, select Tournaments, and inspect Anomaly Blitz.',
        LightcoreTutorialStep.inspectHexGauntlet =>
          'Open Menu, select Tournaments, and inspect Hex Gauntlet.',
        LightcoreTutorialStep.inspectArenaFlow =>
          'Open Menu, select Tournaments, and inspect Arena Flow.',
      };

  String? get tutorialMechanicHint =>
      tutorialQuestDefinition?.teachGoal ??
      switch (_tutorialStep) {
        LightcoreTutorialStep.none => null,
        LightcoreTutorialStep.unfoldShell =>
          'The shell stays folded until the core wakes up, so lanes and combat systems remain locked while it sleeps.',
        LightcoreTutorialStep.waitForFirstHex =>
          'Hex 1 opens with the shell now, so the first lesson moves straight into selecting a lane and building.',
        LightcoreTutorialStep.selectFirstHex =>
          'Command opens the shell one lane at a time so flow stays stable while the relay network comes online.',
        LightcoreTutorialStep.buildFirstRedTower =>
          'Tower projectile families matter. Comet Mortar opens with area pressure, while Rayline Spire opens with steady single-target pressure.',
        LightcoreTutorialStep.inspectFirstTowerStats =>
          'Tower stats show power, charge, cooldown, automation, and lane load before the tower starts feeding the core queue.',
        LightcoreTutorialStep.tapBattleCore =>
          'The Lightcore auto-charges packets after the shell wakes, so the player can focus on choosing targets.',
        LightcoreTutorialStep.tapFirstTower =>
          'Enemy focus teaches target choice before managers unlock auto-fire. Tower clicks remain tower controls.',
        LightcoreTutorialStep.tapSecondShellTower =>
          'Second-shell lanes use the same tower-tap rule: tower bodies open tower controls while packet flow stays automatic.',
        LightcoreTutorialStep.upgradeFirstTowerToLevel3 =>
          'The first upgrade proves the loop quickly: aim, earn, tune, then raise pressure.',
        LightcoreTutorialStep.raiseThreat =>
          'The upgraded tower is overmatching the starter field. Raise the starter-region challenge so stronger pressure turns back into better rewards.',
        LightcoreTutorialStep.pullFirstWhiteEnemy =>
          'Threat scans add real anomalies to the live deck. White anomalies establish the neutral baseline before color counters appear.',
        LightcoreTutorialStep.readEffectiveGain =>
          'Output Efficiency turns threat pressure into a visible gain multiplier, so the best scan is the one your core can keep stable.',
        LightcoreTutorialStep.autoQueueCheck =>
          'Automation proves an assigned manager can route queued packets without taking enemy focus control away from the player.',
        LightcoreTutorialStep.upgradeFirstTowerToLevel4 =>
          'A level 3 anchor keeps the lane efficient before Lumens get split across multiple towers.',
        LightcoreTutorialStep.pullFirstRedEnemy =>
          'Same-color attacks are resisted. Red anomalies punish overcommitting to one color and unlock the full counter system.',
        LightcoreTutorialStep.setFirstEnemyTarget =>
          'Basic Red is already live in the anomaly deck. The next step is reading how region pressure changes the shell.',
        LightcoreTutorialStep.adjustEnemyCount =>
          'Anomaly count controls live pressure. More active anomalies can pay faster, but crowded lanes slow Output Efficiency if your towers cannot keep up.',
        LightcoreTutorialStep.openTowerMatrix =>
          'The tower archive stores completed Layer 1 sets and unlocks once the Prism Shell is online.',
        LightcoreTutorialStep.upgradeCoreRange =>
          'Global Attributes are permanent account upgrades earned from Account Radiance levels.',
        LightcoreTutorialStep.openStore =>
          'The store groups conversions, premium unlocks, and resource offers in one place. Opening it does not spend anything.',
        LightcoreTutorialStep.claimBattlePassReward =>
          'Passes convert normal play into side rewards. Claim during quiet moments so active combat tutorials do not pile up.',
        LightcoreTutorialStep.openBossPulls =>
          'Regional bosses unlock in the Prism Shell. Final stabilization clears award Apex Cores, boss traits, and Knowledge Cards for books.',
        LightcoreTutorialStep.armFirstBoss =>
          'Knowledge Books are portable loadouts: one Apex Core, two boss traits, and three Knowledge Cards.',
        LightcoreTutorialStep.defeatFirstBoss =>
          'Apex Anomalies are milestone fights. This first one is weakened so you can learn the scan loop before full-strength encounters.',
        LightcoreTutorialStep.openEquipment =>
          'The profile panel is where account attributes and guide identity live.',
        LightcoreTutorialStep.openManagers =>
          'Managers are flux-forged modifiers. Core Managers assign to the shell, while Threat Directors attach to Threat Map regions.',
        LightcoreTutorialStep.forgeTowerManager =>
          'Core Manager pulls cost Flux and advance the Core Manager Pass. Each roll can improve payload feed across the active shell.',
        LightcoreTutorialStep.assignTowerManager =>
          'Assigned Core Managers spend prism charge for you, turning payload feed into a steadier automated rhythm.',
        LightcoreTutorialStep.forgeEnemyManager =>
          'Threat Director pulls cost Flux and advance the Threat Director Pass. Their bonuses tune live spawns, enemy strength, and rewards.',
        LightcoreTutorialStep.assignEnemyManager =>
          'Threat Directors attach to a revealed region immediately. Restabilizing that region validates the Director for offline output.',
        LightcoreTutorialStep.holdOverdrive =>
          'Manual Overdrive only accelerates live battle time. Passive shell income still tracks real time, so use it when you are actively pushing lanes.',
        LightcoreTutorialStep.setScreenName =>
          'Tournament rooms use your screen name on leaderboards and reward feeds, so the account needs a public pilot label before bracket play starts.',
        LightcoreTutorialStep.openFriends =>
          'Friends are the direct social lane for requests and daily Threat Scan gifts. It is safe to inspect even with no pending invites.',
        LightcoreTutorialStep.openMentees =>
          'Mentorship keeps your single mentor and all mentees in one relay board.',
        LightcoreTutorialStep.openMentors =>
          'Mentorship keeps your single mentor and all mentees in one relay board.',
        LightcoreTutorialStep.inspectEnemyBlitz =>
          'Anomaly Blitz stays open for testing, but the survival session is weekend-length. Draft anomalies, keep upgrading, and improve your best wave before reset.',
        LightcoreTutorialStep.inspectHexGauntlet =>
          'Hex Gauntlet is the shell stress test. It mirrors your live tower build and asks how deep that exact layout can climb.',
        LightcoreTutorialStep.inspectArenaFlow =>
          'Arena Flow is the shortest format. Your highest-layer Home Tower trades enemy waves with a rival tower, and damage dealt minus damage taken decides the score.',
      };

  String? get tutorialStoryBeat => tutorialQuestDefinition == null
      ? switch (_tutorialStep) {
          LightcoreTutorialStep.none => null,
          LightcoreTutorialStep.unfoldShell =>
            'This relay shell has been drifting in standby. Waking it exposes the battle lattice and alerts nearby anomalies.',
          LightcoreTutorialStep.waitForFirstHex =>
            'Hex 1 is already lit, giving the shell a clean first anchor lane.',
          LightcoreTutorialStep.selectFirstHex =>
            'Hex 1 is the safest breach point, so command uses it as the anchor lane for the opening defense grid.',
          LightcoreTutorialStep.buildFirstRedTower =>
            'Lumo wants the first prism online before the shell fans wider, so the relay net has a stable firing spine.',
          LightcoreTutorialStep.inspectFirstTowerStats =>
            'The first prism report opens so the crew can label what each tower number means before combat speeds up.',
          LightcoreTutorialStep.tapBattleCore =>
            'A hostile signature crosses the core lens while auto-feed readies the next packet.',
          LightcoreTutorialStep.tapFirstTower =>
            'The packet is loaded. Aim at a visible anomaly; tap towers only when you want tower controls.',
          LightcoreTutorialStep.tapSecondShellTower =>
            'The next shell is awake. Tap the charged tower body before Lumo hands you speed controls.',
          LightcoreTutorialStep.upgradeFirstTowerToLevel3 =>
            'Command is tuning the flagship lane before exposing more of the shell to hostile traffic.',
          LightcoreTutorialStep.raiseThreat =>
            'Command marks the field as too quiet and opens Challenge Lv 1 directly from battle.',
          LightcoreTutorialStep.pullFirstWhiteEnemy =>
            'The starter driftling was only training noise. This is your first proper hostile signature.',
          LightcoreTutorialStep.readEffectiveGain =>
            'The crew pins the real-gain formula beside the output dial before opening harder scans.',
          LightcoreTutorialStep.autoQueueCheck =>
            'The assigned Core Manager takes the relay chair and starts spending queued packets without a manual command.',
          LightcoreTutorialStep.upgradeFirstTowerToLevel4 =>
            'The shell is absorbing denser traffic now, so the first lane needs one more tune pass before expansion.',
          LightcoreTutorialStep.pullFirstRedEnemy =>
            'Anomaly scouts start adapting as soon as they detect the Prism spectrum you deployed on the shell rim.',
          LightcoreTutorialStep.setFirstEnemyTarget =>
            'The crew marks the red signature as live so the next pressure lesson has real resistance in the deck.',
          LightcoreTutorialStep.adjustEnemyCount =>
            'Lumo opens the pressure valve a notch, enough to prove the shell can choose how dense the anomaly field becomes.',
          LightcoreTutorialStep.openTowerMatrix =>
            'The first combat loop is stable, so command hands you the full tower ledger instead of only the battle shortcuts.',
          LightcoreTutorialStep.upgradeCoreRange =>
            'The crew routes the new Radiance point into a permanent account attribute before the next set of anomalies closes in.',
          LightcoreTutorialStep.openStore =>
            'Supply control is online. The crew wants you to know where conversions and permanent offers live before you need them.',
          LightcoreTutorialStep.claimBattlePassReward =>
            'A side ledger flashes with completed field orders. It is a quiet moment to pull the reward before the next push.',
          LightcoreTutorialStep.openBossPulls =>
            'High-output shells attract Wardens. Your rising signal has started to pull true apex-class anomalies into orbit.',
          LightcoreTutorialStep.armFirstBoss =>
            'White Warden has your shell marked and is closing to intercept range.',
          LightcoreTutorialStep.defeatFirstBoss =>
            'Breaking the first Warden proves the shell can survive real pursuit instead of just ambient drift.',
          LightcoreTutorialStep.openEquipment =>
            'White Warden cleared the next account-growth panel.',
          LightcoreTutorialStep.openManagers =>
            'With enough field experience logged, the foundry crews can finally start drafting Core Managers and Threat Directors.',
          LightcoreTutorialStep.forgeTowerManager =>
            'The tower foundry spins up first, looking for a specialist who can take over prism fire commands.',
          LightcoreTutorialStep.assignTowerManager =>
            'A manager steps into the relay chair and starts turning charged prisms into repeatable output.',
          LightcoreTutorialStep.forgeEnemyManager =>
            'The anomaly foundry answers next, offering a Threat Director who can tune hostile traffic and payouts instead of only fighting them.',
          LightcoreTutorialStep.assignEnemyManager =>
            'The selected region gets a director, changing current spawn pressure, enemy strength, and payout bonuses.',
          LightcoreTutorialStep.holdOverdrive =>
            '"Sometimes in space, things are really far apart," Lumo says. "Hold Overdrive when a child lane feels long and pull the battle clock toward you."',
          LightcoreTutorialStep.setScreenName =>
            'Tournament control will not post an anonymous relay into public brackets. Your crew needs a callsign on the record first.',
          LightcoreTutorialStep.openFriends =>
            'Relay control opens the public contact lane so requests and Threat Scan gifts are not hidden in a corner menu.',
          LightcoreTutorialStep.openMentees =>
            'The mentorship board shows your one upward connection and every branch growing under your signal.',
          LightcoreTutorialStep.openMentors =>
            'The mentorship board shows your one upward connection and every branch growing under your signal.',
          LightcoreTutorialStep.inspectEnemyBlitz =>
            'Anomaly Blitz is the crew’s first sanctioned trial run: a fast bracket where resource calls matter as much as raw shell power.',
          LightcoreTutorialStep.inspectHexGauntlet =>
            'Hex Gauntlet is where command measures how well a real shell layout survives sustained weekly pressure.',
          LightcoreTutorialStep.inspectArenaFlow =>
            'Arena Flow is the public duel format for highest-layer Home Towers. Once you understand it, every tournament type in the Nexus has been introduced.',
        }
      : null;

  List<TowerConfig> get tutorialTowerChoices {
    if (tutorialNeedsTowerPaletteGate) {
      return const <TowerConfig>[TowerLibrary.redPrism, TowerLibrary.cyanPrism];
    }
    if (tutorialShowsStarterProjectileChoices) {
      if (_slots.firstOrNull?.config?.id == TowerLibrary.cyanPrism.id) {
        return const <TowerConfig>[
          TowerLibrary.redPrism,
          TowerLibrary.greenPrism,
        ];
      }
      return const <TowerConfig>[
        TowerLibrary.cyanPrism,
        TowerLibrary.greenPrism,
      ];
    }
    return towerConfigs.toList(growable: false);
  }

  bool tutorialHighlightsBuildButton(TowerConfig config) =>
      _tutorialStep == LightcoreTutorialStep.buildFirstRedTower &&
      _isOpeningStarterTower(config);

  bool tutorialHighlightsUpgradeButton(int slotIndex) =>
      slotIndex == 0 &&
      (_tutorialStep == LightcoreTutorialStep.upgradeFirstTowerToLevel3 ||
          _tutorialStep == LightcoreTutorialStep.upgradeFirstTowerToLevel4);

  bool get tutorialHighlightsCoreRangeUpgrade =>
      _tutorialStep == LightcoreTutorialStep.upgradeCoreRange;

  bool tutorialHighlightsEnemyTarget(String cardId) =>
      _tutorialStep == LightcoreTutorialStep.setFirstEnemyTarget &&
      cardId == EnemyLibrary.basicRed.id;

  bool get tutorialHighlightsEnemyCountControl =>
      _tutorialStep == LightcoreTutorialStep.adjustEnemyCount;

  bool get tutorialHighlightsTowerManagerForge =>
      _tutorialStep == LightcoreTutorialStep.forgeTowerManager;

  bool get tutorialHighlightsTowerManagerAssign =>
      _tutorialStep == LightcoreTutorialStep.assignTowerManager;

  bool tutorialHighlightsTowerManager(String managerId) =>
      tutorialHighlightsTowerManagerAssign &&
      _cards.any((card) => card.instanceId == managerId);

  bool get tutorialHighlightsEnemyManagerForge =>
      _tutorialStep == LightcoreTutorialStep.forgeEnemyManager;

  bool get tutorialHighlightsEnemyManagerAssign =>
      _tutorialStep == LightcoreTutorialStep.assignEnemyManager;

  bool tutorialHighlightsEnemyManager(String managerId) =>
      tutorialHighlightsEnemyManagerAssign &&
      _enemyManagers.any((manager) => manager.instanceId == managerId);

  bool tutorialHighlightsBossesTab(bool bossesSelected) =>
      _tutorialStep == LightcoreTutorialStep.armFirstBoss && !bossesSelected;

  bool tutorialHighlightsBossTile(String cardId) =>
      _tutorialStep == LightcoreTutorialStep.armFirstBoss &&
      cardId == BossEnemyLibrary.starterWhiteWarden.id;

  bool tutorialHighlightsBossArmButton(String cardId) =>
      _tutorialStep == LightcoreTutorialStep.armFirstBoss &&
      cardId == BossEnemyLibrary.starterWhiteWarden.id;

  bool get _activeLayerAllowsCoreTraining =>
      _activeLayerAllowsProgressionUpgrades && !activeLayerHasParentSlot;

  bool get canTrainCoreStats => _activeLayerAllowsCoreTraining;

  bool get canUpgradeCoreLevel =>
      _activeLayerAllowsCoreTraining && _core.level < maxCoreLevel;

  bool get canUpgradeCoreRange =>
      _activeLayerAllowsProgressionUpgrades &&
      _core.rangeUpgradeLevel < maxCoreUpgradeLevel;

  bool get canUpgradeCoreFireSpeed =>
      _activeLayerAllowsProgressionUpgrades &&
      _core.fireSpeedUpgradeLevel < maxCoreUpgradeLevel;

  bool get canUpgradeCoreQueueLimit =>
      _activeLayerAllowsProgressionUpgrades &&
      _core.queueLimitUpgradeLevel < maxCoreUpgradeLevel;

  bool get canUpgradeCoreMultiShot =>
      _activeLayerAllowsProgressionUpgrades &&
      _core.multiShotUpgradeLevel < maxCoreMultiShotUpgradeLevel;

  bool get coreEnergyUnlocked => activeLayer.tier >= _coreEnergyUnlockLayer;

  bool get canUpgradeCoreEnergyCapacity =>
      coreEnergyUnlocked &&
      _activeLayerAllowsProgressionUpgrades &&
      _core.energyCapacityUpgradeLevel < _maxCoreEnergyUpgradeLevel;

  bool get canUpgradeCoreEnergyRecovery =>
      coreEnergyUnlocked &&
      _activeLayerAllowsProgressionUpgrades &&
      _core.energyRecoveryUpgradeLevel < _maxCoreEnergyUpgradeLevel;

  int get coreRangeUpgradeCost => canUpgradeCoreRange
      ? _coreUpgradeCost(baseCost: 18, upgradeLevel: _core.rangeUpgradeLevel)
      : 0;

  int get coreFireSpeedUpgradeCost => canUpgradeCoreFireSpeed
      ? _coreUpgradeCost(
          baseCost: 22,
          upgradeLevel: _core.fireSpeedUpgradeLevel,
        )
      : 0;

  int get coreQueueUpgradeCost => canUpgradeCoreQueueLimit
      ? _coreUpgradeCost(
          baseCost: 20,
          upgradeLevel: _core.queueLimitUpgradeLevel,
        )
      : 0;

  int get coreMultiShotUpgradeCost => canUpgradeCoreMultiShot
      ? _coreUpgradeCost(
          baseCost: 32,
          upgradeLevel: _core.multiShotUpgradeLevel,
        )
      : 0;

  int get coreLevelUpgradeCost => canUpgradeCoreLevel
      ? _coreUpgradeCost(baseCost: 26, upgradeLevel: max(0, _core.level - 1))
      : 0;

  int get coreEnergyCapacityUpgradeCost => canUpgradeCoreEnergyCapacity
      ? _coreUpgradeCost(
          baseCost: 28,
          upgradeLevel: _core.energyCapacityUpgradeLevel,
        )
      : 0;

  int get coreEnergyRecoveryUpgradeCost => canUpgradeCoreEnergyRecovery
      ? _coreUpgradeCost(
          baseCost: 24,
          upgradeLevel: _core.energyRecoveryUpgradeLevel,
        )
      : 0;

  double _coreEnergyCapacityForUpgradeLevel(int upgradeLevel) {
    final normalized = upgradeLevel.clamp(0, _maxCoreEnergyUpgradeLevel);
    return _baseCoreEnergyCapacity +
        (normalized * _coreEnergyCapacityUpgradeStep);
  }

  double _coreEnergyRecoveryForUpgradeLevel(int upgradeLevel) {
    final normalized = upgradeLevel.clamp(0, _maxCoreEnergyUpgradeLevel);
    return _baseCoreEnergyRecoveryPerSecond +
        (normalized * _coreEnergyRecoveryUpgradeStep);
  }

  double get coreEnergyCapacity =>
      _coreEnergyCapacityForUpgradeLevel(_core.energyCapacityUpgradeLevel);

  double get coreEnergyRecoveryPerSecond =>
      _coreEnergyRecoveryForUpgradeLevel(_core.energyRecoveryUpgradeLevel);

  double get coreEnergyRatio => coreEnergyUnlocked
      ? (_core.coreEnergy / max(0.001, coreEnergyCapacity))
            .clamp(0.0, 1.0)
            .toDouble()
      : 1.0;

  String get coreEnergyLabel =>
      '${_core.coreEnergy.clamp(0, coreEnergyCapacity).round()}/${coreEnergyCapacity.round()}';

  String get coreEnergyRecoveryLabel =>
      '+${coreEnergyRecoveryPerSecond.toStringAsFixed(1)}/s';

  double get _coreEnergyOutputMultiplier =>
      coreEnergyUnlocked ? 0.92 + (0.08 * coreEnergyRatio) : 1.0;

  double get _coreEnergyStabilityRecoveryMultiplier =>
      coreEnergyUnlocked ? 0.90 + (0.20 * coreEnergyRatio) : 1.0;

  int coreStatUpgradeCost(TowerUpgradeOptionState upgrade) {
    if (!canTrainCoreStats || upgrade.rank >= maxTowerUpgradeRank) {
      return 0;
    }
    final shellCurve = 1 + (builtTowerCount * 0.07);
    final levelCurve = 1 + (max(0, _core.level - 1) * 0.15);
    final rankCurve = pow(1.42, upgrade.rank).toDouble();
    final rarityCurve =
        (upgrade.isRadiant ? 1.16 : 1.0) * (upgrade.isOvercharge ? 1.24 : 1.0);
    final baseCost = 18 + ((upgrade.rank + 1) * 8);
    final price =
        baseCost *
        activeLayerPriceMultiplier *
        shellCurve *
        levelCurve *
        rankCurve *
        rarityCurve;
    return max(1, price.round());
  }

  double get coreBaseRange =>
      coreBaseRangeForUpgradeLevel(_core.rangeUpgradeLevel);

  double get coreEffectiveRange => coreEffectiveRangeForUpgradeLevel(
    _core.rangeUpgradeLevel,
    projectileType: _coreProjectileType,
  );

  double get coreShotCooldown => coreShotCooldownForUpgradeLevel(
    _core.fireSpeedUpgradeLevel,
    projectileType: _coreProjectileType,
  );

  double get coreShotsPerSecond => coreShotsPerSecondForUpgradeLevel(
    _core.fireSpeedUpgradeLevel,
    projectileType: _coreProjectileType,
  );

  int get coreQueueCapacity =>
      coreQueueCapacityForUpgradeLevel(_core.queueLimitUpgradeLevel);

  int get coreMultiShotCount =>
      coreMultiShotCountForUpgradeLevel(_core.multiShotUpgradeLevel);

  double get coreEffectiveShotsPerSecond =>
      coreShotsPerSecond * coreMultiShotCount;

  double get coreBasicShotPower => _coreBasicShotPower();

  double get coreCritChance =>
      (_coreBaseCritChance +
              _gearCritChanceBonus +
              _towerCritChanceUpgradeBonus(
                _coreUpgradeBonusFor(TowerUpgradeStatType.critChance),
              ))
          .clamp(0.02, 0.65)
          .toDouble();

  double get coreCritMultiplier =>
      (_coreBaseCritMultiplier +
          _towerCritDamageUpgradeBonus(
            _coreUpgradeBonusFor(TowerUpgradeStatType.critDamage),
          )) *
      _gearCritDamageMultiplier;

  double get coreFinalDamageMultiplier =>
      1 +
      _towerFinalDamageUpgradeBonus(
        _coreUpgradeBonusFor(TowerUpgradeStatType.finalDamage),
      );

  double get coreBossDamageMultiplier =>
      _gearBossDamageMultiplier *
      (1 +
          _towerBossDamageUpgradeBonus(
            _coreUpgradeBonusFor(TowerUpgradeStatType.bossDamage),
          ));

  double get coreNormalDamageMultiplier =>
      1 +
      _towerNormalDamageUpgradeBonus(
        _coreUpgradeBonusFor(TowerUpgradeStatType.normalDamage),
      );

  double get coreDefensePenetration => _towerDefensePenetrationUpgradeBonus(
    _coreUpgradeBonusFor(TowerUpgradeStatType.defensePenetration),
  ).clamp(0.0, 0.65).toDouble();

  double get coreMinDamageMultiplier =>
      1 +
      _towerMinDamageUpgradeBonus(
        _coreUpgradeBonusFor(TowerUpgradeStatType.minDamage),
      );

  double get coreMaxDamageMultiplier => max(
    coreMinDamageMultiplier,
    1 +
        _towerMaxDamageUpgradeBonus(
          _coreUpgradeBonusFor(TowerUpgradeStatType.maxDamage),
        ),
  );

  String get coreRangeLabel => coreEffectiveRange.toStringAsFixed(0);

  String get coreFireSpeedLabel => '${coreShotsPerSecond.toStringAsFixed(2)}/s';

  String get coreCooldownLabel => '${coreShotCooldown.toStringAsFixed(2)}s';

  String get coreQueueCapacityLabel => '$coreQueueCapacity';

  String get coreQueueLoadLabel => '$coreQueueOccupancy/$coreQueueCapacity';

  String get coreMultiShotLabel => '${coreMultiShotCount}x';

  String get corePowerLabel => coreBasicShotPower.toStringAsFixed(1);

  String get coreCritLabel =>
      '${(coreCritChance * 100).toStringAsFixed(0)}% / x${coreCritMultiplier.toStringAsFixed(2)}';

  String get coreFinalDamageLabel =>
      'x${coreFinalDamageMultiplier.toStringAsFixed(2)}';

  String get coreBossDamageLabel =>
      'x${coreBossDamageMultiplier.toStringAsFixed(2)}';

  String get coreNormalDamageLabel =>
      'x${coreNormalDamageMultiplier.toStringAsFixed(2)}';

  String get coreDefensePenetrationLabel =>
      '${(coreDefensePenetration * 100).toStringAsFixed(0)}%';

  String get coreMinDamageLabel =>
      'x${coreMinDamageMultiplier.toStringAsFixed(2)}';

  String get coreMaxDamageLabel =>
      'x${coreMaxDamageMultiplier.toStringAsFixed(2)}';

  String get nextCoreRangeLabel => coreEffectiveRangeForUpgradeLevel(
    _core.rangeUpgradeLevel + 1,
    projectileType: _coreProjectileType,
  ).toStringAsFixed(0);

  String get nextCoreFireSpeedLabel =>
      '${coreShotsPerSecondForUpgradeLevel(_core.fireSpeedUpgradeLevel + 1, projectileType: _coreProjectileType).toStringAsFixed(2)}/s';

  String get nextCoreCooldownLabel =>
      '${coreShotCooldownForUpgradeLevel(_core.fireSpeedUpgradeLevel + 1, projectileType: _coreProjectileType).toStringAsFixed(2)}s';

  String get nextCoreQueueCapacityLabel =>
      '${coreQueueCapacityForUpgradeLevel(_core.queueLimitUpgradeLevel + 1)}';

  String get nextCoreMultiShotLabel =>
      '${coreMultiShotCountForUpgradeLevel(_core.multiShotUpgradeLevel + 1)}x';

  String towerDisplayName(OuterTowerState tower) {
    if (tower.config != null) {
      return tower.config!.name;
    }
    if (tower.childLayerId != null) {
      return tower.childLayerName ??
          shellNameForTier(tower.childLayerTier ?? 1);
    }
    return 'Empty Hex ${tower.slotIndex + 1}';
  }

  double coreBaseRangeForUpgradeLevel(int upgradeLevel) {
    final normalized = _normalizeCoreUpgradeLevel(upgradeLevel);
    return _coreBaseRange * (1 + (normalized * 0.11));
  }

  double coreEffectiveRangeForUpgradeLevel(
    int upgradeLevel, {
    ProjectileType? projectileType,
  }) {
    return (coreBaseRangeForUpgradeLevel(upgradeLevel) +
            _towerRangeUpgradeBonus(
              _coreUpgradeBonusFor(TowerUpgradeStatType.range),
            )) *
        _projectileRangeMultiplier(projectileType ?? _core.projectileType) *
        _gearRangeMultiplier;
  }

  double coreShotCooldownForUpgradeLevel(
    int upgradeLevel, {
    ProjectileType? projectileType,
  }) {
    final normalized = _normalizeCoreUpgradeLevel(upgradeLevel);
    final cooldownMultiplier = pow(0.9, normalized).toDouble();
    return max(
      0.08,
      _coreBaseCooldown *
          cooldownMultiplier *
          _radianceCoreCooldownMultiplier *
          _projectileCooldownMultiplier(
            projectileType ?? _core.projectileType,
          ) *
          _towerCooldownUpgradeMultiplier(
            _coreUpgradeBonusFor(TowerUpgradeStatType.cooldown),
          ) *
          _layer1OpeningCadenceMultiplier,
    );
  }

  double coreShotsPerSecondForUpgradeLevel(
    int upgradeLevel, {
    ProjectileType? projectileType,
  }) {
    return 1 /
        coreShotCooldownForUpgradeLevel(
          upgradeLevel,
          projectileType: projectileType,
        );
  }

  int coreQueueCapacityForUpgradeLevel(int upgradeLevel) =>
      baseCoreQueueCapacity +
      (_normalizeCoreUpgradeLevel(upgradeLevel) * coreQueueCapacityUpgradeStep);

  int coreMultiShotCountForUpgradeLevel(int upgradeLevel) =>
      1 + _normalizeCoreMultiShotUpgradeLevel(upgradeLevel);

  String traitBiasSummary(TowerConfig config) {
    final projectile = config.defaultProjectileType;
    return '${projectile.label}: ${projectile.summary}';
  }

  bool showcaseCurrentTutorialTarget() {
    final target = tutorialShowcaseTarget;
    if (target == null) {
      return false;
    }
    _tutorialPulseTarget = target;
    _tutorialPulseSignal += 1;
    _notifyNow();
    return true;
  }

  void enterSourceLayer() {
    final sourceId = activeLayer.sourceLayerId;
    if (sourceId == null) {
      return;
    }
    final source = _layerById(sourceId);
    _enterLayer(
      source.id,
      banner: isLayerPassiveOnly(source)
          ? '${layerDisplayLabel(source)} archive opened. Its merged pieces are static, but each hex can still be inspected.'
          : null,
    );
  }

  void enterLayerById(String layerId) {
    final layer = _layerForId(layerId);
    if (layer == null) {
      return;
    }
    if (layer.id == _activeLayerId) {
      return;
    }
    _enterLayer(
      layer.id,
      banner: isLayerPassiveOnly(layer)
          ? '${layerDisplayLabel(layer)} archive opened. Static support remains linked to ${layerDisplayLabel(_liveLayerForLayer(layer))}.'
          : null,
    );
  }

  void enterChildLayer(int slotIndex) {
    if (!isCompositeLayer || slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return;
    }
    final slot = _slots[slotIndex];
    final existingChildId = slot.childLayerId;
    if (existingChildId != null) {
      final child = _layerById(existingChildId);
      _enterLayer(
        child.id,
        banner: isLayerPassiveOnly(child)
            ? '${layerDisplayLabel(child)} archive opened. Its root pieces are static and inspectable.'
            : null,
      );
      return;
    }

    final blockedLabel = childLayerCreationBlockedLabelForSlot(slotIndex);
    if (blockedLabel != null) {
      _showBanner(blockedLabel);
      _notifyNow();
      return;
    }

    _showBanner('Choose a starting core color for hex ${slotIndex + 1}.');
    _notifyNow();
  }

  bool createChildLayer(int slotIndex, PrototypeAffinity coreAffinity) {
    if (!isCompositeLayer || slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return false;
    }
    final slot = _slots[slotIndex];
    final existingChildId = slot.childLayerId;
    if (existingChildId != null) {
      final child = _layerById(existingChildId);
      _enterLayer(
        child.id,
        banner: isLayerPassiveOnly(child)
            ? '${layerDisplayLabel(child)} archive opened. Its root pieces are static and inspectable.'
            : null,
      );
      return true;
    }
    final blockedLabel = childLayerCreationBlockedLabelForSlot(slotIndex);
    if (blockedLabel != null) {
      _showBanner(blockedLabel);
      _notifyNow();
      return false;
    }
    if (!childCoreAffinityChoices.contains(coreAffinity)) {
      return false;
    }

    final childTier = childLayerTierToCreate;
    final child = _freshLayerSnapshot(
      label: shellNameForTier(childTier),
      tier: childTier,
      inheritedCore: _childCoreForSelectedAffinity(
        coreAffinity,
        childTier: childTier,
      ),
      parentLayerId: activeLayer.id,
      parentSlotIndex: slotIndex,
    );
    _layers.add(child);
    _syncParentSlotFromLayer(child);
    _storeActiveLayer();
    _viewLayerId = child.id;
    _runtimeLayerId = child.id;
    _loadLayer(child);
    _showBanner(
      'Created ${layerDisplayLabel(child)} with a ${coreAffinity.label} core. Shared resources stay global.',
    );
    _notifyNow();
    return true;
  }
}
