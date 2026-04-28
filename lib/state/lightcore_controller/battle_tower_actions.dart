part of '../lightcore_controller.dart';

extension LightcoreControllerBattleTowerActions on LightcoreController {
  bool _guardLockedOuterSlot(int slotIndex) {
    if (isOuterSlotUnlocked(slotIndex)) {
      return false;
    }
    _showBanner(lockedOuterSlotSummary(slotIndex));
    _notifyNow();
    return true;
  }

  bool _prepareTutorialTowerBuild(int slotIndex, TowerConfig config) {
    if (tutorialNeedsTowerPaletteGate &&
        config.id != TowerLibrary.redPrism.id) {
      _showBanner(
        'Start with the Red Prism. The rest of the colors unlock after the counter-color lesson.',
      );
      _notifyNow();
      return false;
    }
    if (_tutorialStep == LightcoreTutorialStep.buildFirstRedTower &&
        slotIndex == 0 &&
        config.id == TowerLibrary.redPrism.id) {
      final buildCost = buildCostForConfig(config);
      if (lumens < buildCost) {
        lumens = buildCost;
      }
    }
    return true;
  }

  Map<ProjectileType, TargetPriority> _updatedProjectileTargetPriorities(
    OuterTowerState tower,
    ProjectileType projectileType,
    TargetPriority priority,
  ) {
    final next = Map<ProjectileType, TargetPriority>.from(
      tower.projectileTargetPriorities,
    );
    next[projectileType] = priority;
    return next;
  }

  int _grantSummoningLevelTicketRewards({
    required int previousLevel,
    required int currentLevel,
  }) {
    if (currentLevel <= previousLevel) {
      return 0;
    }

    var rewardTickets = 0;
    for (var level = previousLevel + 1; level <= currentLevel; level++) {
      rewardTickets += summoningLevelTicketRewardForLevel(level);
    }
    enemyTickets += rewardTickets;
    return rewardTickets;
  }

  int _grantBossSummoningLevelTicketRewards({
    required int previousLevel,
    required int currentLevel,
  }) {
    if (currentLevel <= previousLevel) {
      return 0;
    }

    var rewardTickets = 0;
    for (var level = previousLevel + 1; level <= currentLevel; level++) {
      rewardTickets += bossSummoningLevelTicketRewardForLevel(level);
    }
    bossTickets += rewardTickets;
    return rewardTickets;
  }

  bool _mergeEnemyCardAtIndex(
    int cardIndex, {
    bool showBanner = true,
    bool notify = true,
  }) {
    final card = _enemyCards[cardIndex];
    final nextRarity = card.config.rarity.nextRarity;
    final requirement = enemyMergeRequirement(card);
    if (!canMergeEnemyCard(card) || nextRarity == null) {
      return false;
    }

    final targetPool = EnemyLibrary.byRarity[nextRarity]!;
    final rewardConfig = targetPool[_packRandom.nextInt(targetPool.length)];
    final rewardIndex = _enemyCards.indexWhere(
      (candidate) => candidate.config.id == rewardConfig.id,
    );
    _enemyCards[cardIndex] = card.copyWith(copies: card.copies - requirement);
    final rewardCard = _enemyCards[rewardIndex];
    _enemyCards[rewardIndex] = rewardCard.copyWith(
      unlocked: true,
      copies: rewardCard.copies + 1,
    );
    if (rewardCard.copies == 0 && _activeEnemyCardIds.length < enemyDeckLimit) {
      _activeEnemyCardIds.add(rewardConfig.id);
    }
    if (showBanner) {
      _showBanner('${card.config.name} merged into ${rewardConfig.name}.');
    }
    if (notify) {
      _notifyNow();
    }
    return true;
  }

  void handleBattleCenterTap() {
    if (!_outerRingRevealed) {
      selectCenter();
      return;
    }
    _swarmActivated = true;
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;
    if (_queueCoreBasicAttack(showBanner: true)) {
      _syncTutorialStep(showBanner: false);
      _notifyNow();
      return;
    }
    if (hasSourceLayer) {
      enterSourceLayer();
      return;
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void handleBattleSlotTap(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return;
    }
    final tower = _slots[slotIndex];
    if (isCompositeLayer && tower.isLayerProject) {
      enterChildLayer(slotIndex);
      return;
    }
    if (!tower.isBuilt) {
      selectSlot(slotIndex);
      return;
    }
    if (tower.isFabricating) {
      selectSlot(slotIndex);
      return;
    }
    activateTowerSlot(slotIndex, selectForStats: false);
  }

  bool activateTowerSlot(
    int slotIndex, {
    bool showBanner = true,
    bool selectForStats = true,
  }) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return false;
    }
    final tower = _slots[slotIndex];
    _outerRingRevealed = true;
    _swarmActivated = true;
    if (selectForStats) {
      selectedSlotIndex = slotIndex;
    } else {
      selectedSlotIndex = null;
    }
    _towerRangePreviewSlotIndex = _slotCountsTowardRing(tower)
        ? slotIndex
        : null;
    if (!tower.isBuilt) {
      _syncTutorialStep(showBanner: false);
      _notifyNow();
      return false;
    }
    if (!canManuallyActivateTower(tower)) {
      if (showBanner) {
        _showBanner(_towerActivationBlockedLabel(tower));
      }
      _syncTutorialStep(showBanner: false);
      _notifyNow();
      return false;
    }
    final activatedTower = _towerAfterActivation(tower);
    if (activatedTower == null) {
      if (showBanner) {
        _showBanner(_towerActivationBlockedLabel(tower));
      }
      _syncTutorialStep(showBanner: false);
      _notifyNow();
      return false;
    }
    final completesSecondShellShotTutorial =
        _tutorialStep == LightcoreTutorialStep.tapSecondShellTower &&
        _secondShellShotTutorialSlotIndex() == slotIndex;
    _slots[slotIndex] = activatedTower;
    if (completesSecondShellShotTutorial) {
      _tutorialSecondShellShotTapLearned = true;
    }
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }

  void toggleShellVisibility() {
    if (_outerRingRevealed) {
      _outerRingRevealed = false;
      selectedSlotIndex = null;
      _towerRangePreviewSlotIndex = null;
    } else {
      _outerRingRevealed = true;
    }
    _notifyNow();
  }

  void selectSlot(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return;
    }
    _outerRingRevealed = true;
    _swarmActivated = true;
    selectedSlotIndex = slotIndex;
    _towerRangePreviewSlotIndex = _slotCountsTowardRing(_slots[slotIndex])
        ? slotIndex
        : null;
    _syncTutorialStep(showBanner: false);
    _notifyNow();
  }

  void selectCenter() {
    final firstReveal = !_outerRingRevealed;
    _outerRingRevealed = true;
    _swarmActivated = true;
    selectedSlotIndex = null;
    _towerRangePreviewSlotIndex = null;
    _syncTutorialStep(showBanner: !firstReveal);
    _notifyNow();
  }

  void startManualOverdrive() {
    if (!canUseManualOverdrive || _manualOverdriveHeld) {
      return;
    }
    _manualOverdriveHeld = true;
    _notifyNow();
  }

  void stopManualOverdrive() {
    if (!_manualOverdriveHeld) {
      return;
    }
    _manualOverdriveHeld = false;
    _notifyNow();
  }

  void burstManualOverdrive() {
    if (!canUseManualOverdrive) {
      return;
    }
    final nextCharge = min(
      1.0,
      _manualOverdriveCharge + _manualOverdriveTapBurst,
    );
    if ((nextCharge - _manualOverdriveCharge).abs() < 0.001) {
      return;
    }
    _manualOverdriveCharge = nextCharge;
    _notifyNow();
  }

  void unlockPermanentOverdrive() {
    if (_hasPermanentOverdrive) {
      return;
    }
    _hasPermanentOverdrive = true;
    _tutorialOverdriveLearned = true;
    _resetManualOverdrive();
    _syncTutorialStep(showBanner: false);
    _showBanner('Permanent Overdrive online. Battle speed is locked at X1.50.');
    _notifyNow();
  }

  bool unlockPremiumMembership({bool showBanner = true}) {
    if (_hasPremiumMembership) {
      return false;
    }
    _hasPremiumMembership = true;
    if (showBanner) {
      _showBanner(
        'Premium Membership active. Offline claims are no longer capped at 4 hours.',
      );
    }
    _notifyNow();
    return true;
  }

  bool tutorialBuildTowerForSelected(TowerConfig config) {
    final slotIndex = selectedSlotIndex;
    if (slotIndex == null) {
      return false;
    }
    return tutorialBuildTowerAt(slotIndex, config);
  }

  bool tutorialBuildTowerAt(int slotIndex, TowerConfig config) {
    if (!_prepareTutorialTowerBuild(slotIndex, config)) {
      return false;
    }
    return buildTowerAt(slotIndex, config);
  }

  bool tutorialStartTowerFabricationAt(int slotIndex, TowerConfig config) {
    if (!_prepareTutorialTowerBuild(slotIndex, config)) {
      return false;
    }
    return startTowerFabricationAt(slotIndex, config);
  }

  bool tutorialUpgradeSelectedTower() {
    final slotIndex = selectedSlotIndex;
    if (slotIndex == null) {
      return false;
    }
    return tutorialUpgradeTower(slotIndex);
  }

  bool tutorialUpgradeTower(int slotIndex) {
    if (!_earlyTutorialComplete && slotIndex != 0) {
      _showBanner('Keep tuning the first Red Prism until the lesson finishes.');
      _notifyNow();
      return false;
    }
    return upgradeTower(slotIndex);
  }

  bool buildTowerForSelected(TowerConfig config) {
    final slotIndex = selectedSlotIndex;
    if (slotIndex == null) {
      return false;
    }
    return buildTowerAt(slotIndex, config);
  }

  bool startTowerFabricationAt(int slotIndex, TowerConfig config) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    if (isCompositeLayer) {
      enterChildLayer(slotIndex);
      return false;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return false;
    }
    final cost = buildCostForConfig(config);
    if (_slots[slotIndex].isBuilt || lumens < cost) {
      return false;
    }

    final duration = towerFabricationDurationForConfig(config);
    lumens -= cost;
    _recordLumenSpend(cost);
    _outerRingRevealed = true;
    _swarmActivated = true;
    _slots[slotIndex] =
        _buildRolledTowerState(
          slotIndex: slotIndex,
          config: config,
          investedLumens: cost,
        ).copyWith(
          charge: 0,
          fabricationTotalSeconds: duration,
          fabricationRemainingSeconds: duration,
        );
    selectedSlotIndex = slotIndex;
    _towerRangePreviewSlotIndex = null;
    _showBanner(
      '${config.name} fabrication started on hex ${slotIndex + 1}. ${duration.ceil()}s until the relay comes online.',
    );
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }

  bool buildTowerAt(int slotIndex, TowerConfig config) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }
    if (isCompositeLayer) {
      enterChildLayer(slotIndex);
      return false;
    }
    if (_guardLockedOuterSlot(slotIndex)) {
      return false;
    }
    final cost = buildCostForConfig(config);
    if (_slots[slotIndex].isBuilt || lumens < cost) {
      return false;
    }

    lumens -= cost;
    _recordLumenSpend(cost);
    _totalTowersBuilt += 1;
    _outerRingRevealed = true;
    _swarmActivated = true;
    _slots[slotIndex] = _buildRolledTowerState(
      slotIndex: slotIndex,
      config: config,
      investedLumens: cost,
    );
    final rolledOptions = _slots[slotIndex].towerUpgradeOptions
        .map(
          (upgrade) =>
              '${upgrade.isRadiant ? 'Radiant ' : ''}${upgrade.isOvercharge ? 'Overcharge ' : ''}${upgrade.type.label}',
        )
        .join(', ');
    selectedSlotIndex = slotIndex;
    _towerRangePreviewSlotIndex = slotIndex;

    if (isOuterRingComplete && !_layer2.unlocked) {
      _showBanner(
        'Ring complete. Alignment still needs all $slotCount Source Towers at level $maxTowerLevel.',
      );
    } else {
      _showBanner(
        '${config.name} fabricated on hex ${slotIndex + 1} for $cost Lumens. Trainable stats: $rolledOptions.',
      );
    }
    _updateFlowEfficiency();
    _syncTutorialStep();
    _notifyNow();
    return true;
  }

  bool upgradeSelectedTower() {
    final slotIndex = selectedSlotIndex;
    if (slotIndex == null) {
      return false;
    }
    return upgradeTower(slotIndex);
  }

  bool upgradeTower(int slotIndex, {TowerUpgradeStatType? statType}) {
    if (statType != null) {
      return upgradeTowerStat(slotIndex, statType);
    }
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }

    final tower = _slots[slotIndex];
    if (!tower.isBuilt ||
        tower.isFabricating ||
        tower.isChildLayerNode ||
        tower.level >= maxTowerLevel) {
      return false;
    }

    final cost = upgradeCost(tower);
    if (lumens < cost) {
      return false;
    }

    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    final nextLevel = tower.level + 1;
    _slots[slotIndex] = tower.copyWith(
      level: nextLevel,
      investedLumens: tower.investedLumens + cost,
    );
    _showBanner('${towerDisplayName(tower)} pushed to level $nextLevel.');
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }

  bool upgradeTowerStat(int slotIndex, TowerUpgradeStatType type) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }

    final tower = _slots[slotIndex];
    if (!tower.isBuilt || tower.isFabricating || tower.isChildLayerNode) {
      return false;
    }

    final selectedUpgradeIndex = tower.towerUpgradeOptions.indexWhere(
      (upgrade) => upgrade.type == type,
    );
    if (selectedUpgradeIndex == -1) {
      return false;
    }

    final selectedUpgrade = tower.towerUpgradeOptions[selectedUpgradeIndex];
    if (selectedUpgrade.rank >= maxTowerUpgradeRank) {
      return false;
    }

    final cost = towerStatUpgradeCost(tower, selectedUpgrade);
    if (lumens < cost) {
      return false;
    }

    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    final nextOptions = tower.towerUpgradeOptions.toList(growable: false);
    final nextRank = selectedUpgrade.rank + 1;
    nextOptions[selectedUpgradeIndex] = selectedUpgrade.copyWith(
      rank: nextRank,
    );
    _slots[slotIndex] = tower.copyWith(
      investedLumens: tower.investedLumens + cost,
      towerUpgradeOptions: nextOptions,
    );
    _showBanner(
      '${towerDisplayName(tower)} tuned ${selectedUpgrade.type.label.toLowerCase()} to $nextRank/$maxTowerUpgradeRank.',
    );
    _syncTutorialStep(showBanner: false);
    _notifyNow();
    return true;
  }

  bool upgradeActiveChildTowerStat(ChildTowerUpgradeType type) {
    if (!activeLayerHasParentSlot) {
      return false;
    }

    final upgradeIndex = activeLayer.childTowerUpgrades.indexWhere(
      (upgrade) => upgrade.type == type,
    );
    if (upgradeIndex == -1) {
      return false;
    }

    final currentUpgrade = activeLayer.childTowerUpgrades[upgradeIndex];
    if (currentUpgrade.rank >= childTowerUpgradeMaxRank) {
      return false;
    }

    final cost = childTowerUpgradeCost(currentUpgrade);
    if (lumens < cost) {
      return false;
    }

    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    final nextUpgrades = activeLayer.childTowerUpgrades.toList(growable: false);
    nextUpgrades[upgradeIndex] = currentUpgrade.copyWith(
      rank: currentUpgrade.rank + 1,
    );
    activeLayer.childTowerUpgrades = nextUpgrades;

    final boardCompleted = nextUpgrades.every(
      (upgrade) => upgrade.rank >= childTowerUpgradeMaxRank,
    );
    if (boardCompleted) {
      final nextLevel = _core.level + 1;
      _core = _core.copyWith(level: nextLevel);
      activeLayer.core = _core;
      activeLayer.childTowerUpgrades = _rollChildTowerUpgradeBoard();
      _storeActiveLayer();
      _updateFlowEfficiency();
      final rerollSummary = activeLayer.childTowerUpgrades
          .map((upgrade) => upgrade.type.label)
          .join(', ');
      _showBanner(
        '${activeLayer.label} reached child level $nextLevel. New tuning rolled: $rerollSummary.',
      );
      _notifyNow();
      return true;
    }

    _storeActiveLayer();
    _updateFlowEfficiency();
    _showBanner(
      '${type.label} tuned to ${currentUpgrade.rank + 1}/$childTowerUpgradeMaxRank on ${activeLayer.label}.',
    );
    _notifyNow();
    return true;
  }

  bool upgradeCoreRange() {
    if (!canUpgradeCoreRange) {
      return false;
    }

    final cost = coreRangeUpgradeCost;
    if (lumens < cost) {
      return false;
    }

    final nextLevel = _core.rangeUpgradeLevel + 1;
    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    _core = _core.copyWith(rangeUpgradeLevel: nextLevel);
    _syncTutorialStep(showBanner: false);
    _showBanner(
      'Core range upgraded to ${coreEffectiveRangeForUpgradeLevel(nextLevel).toStringAsFixed(0)}.',
    );
    _notifyNow();
    return true;
  }

  bool upgradeCoreFireSpeed() {
    if (!canUpgradeCoreFireSpeed) {
      return false;
    }

    final cost = coreFireSpeedUpgradeCost;
    if (lumens < cost) {
      return false;
    }

    final nextLevel = _core.fireSpeedUpgradeLevel + 1;
    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    _core = _core.copyWith(fireSpeedUpgradeLevel: nextLevel);
    _showBanner(
      'Core fire speed upgraded to ${coreShotsPerSecondForUpgradeLevel(nextLevel).toStringAsFixed(2)}/s.',
    );
    _notifyNow();
    return true;
  }

  bool upgradeCoreQueueLimit() {
    if (!canUpgradeCoreQueueLimit) {
      return false;
    }

    final cost = coreQueueUpgradeCost;
    if (lumens < cost) {
      return false;
    }

    final nextLevel = _core.queueLimitUpgradeLevel + 1;
    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    _core = _core.copyWith(queueLimitUpgradeLevel: nextLevel);
    _showBanner(
      'Core queue expanded to ${coreQueueCapacityForUpgradeLevel(nextLevel)} packets.',
    );
    _notifyNow();
    return true;
  }

  bool upgradeCoreMultiShot() {
    if (!canUpgradeCoreMultiShot) {
      return false;
    }

    final cost = coreMultiShotUpgradeCost;
    if (lumens < cost) {
      return false;
    }

    final nextLevel = _core.multiShotUpgradeLevel + 1;
    lumens -= cost;
    _recordLumenSpend(cost);
    _recordUpgradePurchase();
    _core = _core.copyWith(multiShotUpgradeLevel: nextLevel);
    _showBanner(
      'Core multi-shot upgraded to ${coreMultiShotCountForUpgradeLevel(nextLevel)}x.',
    );
    _notifyNow();
    return true;
  }

  bool sellTower(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return false;
    }

    final tower = _slots[slotIndex];
    if (!tower.isBuilt || tower.isChildLayerNode) {
      return false;
    }

    final refund = max(
      1,
      ((tower.investedLumens > 0
                  ? tower.investedLumens
                  : buildCostForConfig(tower.config!)) *
              0.7)
          .round(),
    );
    lumens += refund;
    _slots[slotIndex] = OuterTowerState(slotIndex: slotIndex);
    if (selectedSlotIndex == slotIndex) {
      selectedSlotIndex = slotIndex;
    }
    if (_towerRangePreviewSlotIndex == slotIndex) {
      _towerRangePreviewSlotIndex = null;
    }
    _updateFlowEfficiency();
    _showBanner('Hex ${slotIndex + 1} sold for $refund Lumens.');
    _notifyNow();
    return true;
  }

  void setTowerTargetPriority(int slotIndex, TargetPriority priority) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }
    final tower = _slots[slotIndex];
    if (!tower.isBuilt || tower.isFabricating) {
      return;
    }
    final projectileType = _slotProjectileType(tower);
    _slots[slotIndex] = tower.copyWith(
      targetPriority: priority,
      projectileTargetPriorities: _updatedProjectileTargetPriorities(
        tower,
        projectileType,
        priority,
      ),
    );
    _showBanner(
      '${towerDisplayName(tower)} ${projectileType.label.toLowerCase()} now prioritizes ${priority.label.toLowerCase()} targets.',
    );
    _notifyNow();
  }

  void setTowerProjectileTargetPriority(
    int slotIndex,
    ProjectileType projectileType,
    TargetPriority priority,
  ) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }
    final tower = _slots[slotIndex];
    if (!tower.isBuilt || tower.isFabricating) {
      return;
    }
    final isLiveProjectile = _slotProjectileType(tower) == projectileType;
    _slots[slotIndex] = tower.copyWith(
      targetPriority: isLiveProjectile ? priority : tower.targetPriority,
      projectileTargetPriorities: _updatedProjectileTargetPriorities(
        tower,
        projectileType,
        priority,
      ),
    );
    _showBanner(
      '${towerDisplayName(tower)} ${projectileType.label.toLowerCase()} now prioritizes ${priority.label.toLowerCase()} targets.',
    );
    _notifyNow();
  }

  void equipCardToSelected(String cardId) {
    equipCardToCore(cardId);
  }

  void equipCardToCore(String cardId) {
    if (!managerAssignmentUnlocked) {
      _showBanner('Manager assignment unlocks with a Layer 2 Core.');
      _notifyNow();
      return;
    }

    final cardIndex = _cards.indexWhere((card) => card.instanceId == cardId);
    if (cardIndex == -1) {
      return;
    }

    for (var index = 0; index < _cards.length; index++) {
      final card = _cards[index];
      if (index != cardIndex && card.equippedLayerId == activeLayer.id) {
        _cards[index] = card.copyWith(clearEquippedSlot: true);
      }
    }
    for (var layerIndex = 0; layerIndex < _layers.length; layerIndex++) {
      final layer = _layers[layerIndex];
      if (layer.id == activeLayer.id ||
          layer.id == _cards[cardIndex].equippedLayerId) {
        layer.core = layer.core.copyWith(automationCooldownRemaining: 0);
      }
      for (var slotIndex = 0; slotIndex < layer.slots.length; slotIndex++) {
        final slot = layer.slots[slotIndex];
        if (slot.equippedCardInstanceId == cardId ||
            (layer.id == activeLayer.id &&
                slot.equippedCardInstanceId != null)) {
          layer.slots[slotIndex] = slot.copyWith(
            automationCooldownRemaining: 0,
            clearEquippedCard: true,
          );
        }
      }
    }

    _cards[cardIndex] = _cards[cardIndex].copyWith(
      equippedLayerId: activeLayer.id,
      clearEquippedSlotIndex: true,
    );
    _core = _core.copyWith(automationCooldownRemaining: 0);
    if (_tutorialStep == LightcoreTutorialStep.assignTowerManager) {
      _tutorialTowerManagerAssigned = true;
      _syncTutorialStep(showBanner: false);
    }
    _showBanner(
      '${_cards[cardIndex].name} assigned to the Tower Core for all towers.',
    );
    _notifyNow();
  }

  void equipCardToSlot(String cardId, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }
    selectedSlotIndex = slotIndex;
    equipCardToCore(cardId);
  }

  void unequipCoreTowerManager() {
    final manager = _towerCoreManagerForLayer(activeLayer);
    if (manager == null) {
      return;
    }
    for (var index = 0; index < _cards.length; index++) {
      final card = _cards[index];
      if (card.equippedLayerId == activeLayer.id) {
        _cards[index] = card.copyWith(clearEquippedSlot: true);
      }
    }
    for (var slotIndex = 0; slotIndex < _slots.length; slotIndex++) {
      _slots[slotIndex] = _slots[slotIndex].copyWith(
        automationCooldownRemaining: 0,
        clearEquippedCard: true,
      );
    }
    _core = _core.copyWith(automationCooldownRemaining: 0);
    _showBanner('Core Manager removed from the Tower Core.');
    _notifyNow();
  }

  void unequipCardFromSlot(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= _slots.length) {
      return;
    }

    final tower = _slots[slotIndex];
    if (cardForSlot(tower) == null) {
      return;
    }
    unequipCoreTowerManager();
  }

  void unlockLayer2Tower() {
    if (!isPromotionReady) {
      _showBanner(
        builtTowerCount < slotCount
            ? 'Alignment locked. Build all $slotCount Source Towers first.'
            : 'Alignment locked. Raise every Source Tower to level $maxTowerLevel first.',
      );
      _notifyNow();
      return;
    }

    final parentLayerId = activeLayer.parentLayerId;
    final parentSlotIndex = activeLayer.parentSlotIndex;
    if (parentLayerId != null && parentSlotIndex != null) {
      final parent = _layerById(parentLayerId);
      if (activeLayer.promotedIntoParentSlot) {
        _enterLayer(
          parent.id,
          banner:
              'Returned to ${layerDisplayLabel(parent)}. $activeLayerLabel is already aligned into hex ${parentSlotIndex + 1}.',
        );
        return;
      }

      activeLayer.promotedIntoParentSlot = true;
      _storeActiveLayer();
      final forgedSlot = parent.slots[parentSlotIndex];
      echoSeeds += 1;
      _enterLayer(
        parent.id,
        banner:
            '$activeLayerLabel aligned into hex ${parentSlotIndex + 1} as a ${shellBadgeForTier(parent.tier)} tower: ${towerProjectileLabel(forgedSlot)} projectile • ${towerPayloadLabel(forgedSlot)} payload. +1 Echo Seed.',
      );
      return;
    }

    if (activeLayer.promotedParentLayerId != null) {
      _enterLayer(activeLayer.promotedParentLayerId!);
      return;
    }

    if (activeLayer.tier >= maxShellTier) {
      _showBanner(
        'Ascendant Shell stabilized. Future endgame systems will build from this shell.',
      );
      _notifyNow();
      return;
    }

    final nextTier = activeLayer.tier + 1;
    final nextShellName = shellNameForTier(nextTier);
    final sourceShellName = shellNameForTier(nextTier - 1);
    final forgedTraits = _resolvePromotedTraitLoadoutForLayer(
      activeLayer,
      targetTier: nextTier,
    );
    final projectileLoadout = forgedTraits.projectileLoadout;
    final payloadLoadout = forgedTraits.payloadLoadout;
    final forgedAffinity = forgedTraits.projectileAffinity;
    final forgedProjectile = projectileLoadout.first;
    final forgedPayload = payloadLoadout.first;
    final previousProgressionLayer = progressionLayer;
    final promotedCore = _core.copyWith(
      flowEfficiency: _maxFlowEfficiency,
      fireCooldownRemaining: 0,
      level: max(_core.level + 1, nextTier),
      affinity: forgedAffinity,
      secondaryAffinity: forgedTraits.payloadAffinity,
      projectileType: forgedProjectile,
      payloadType: forgedPayload,
      projectileLoadout: projectileLoadout,
      payloadLoadout: payloadLoadout,
      fireSequence: 0,
    );
    final parent = _freshLayerSnapshot(
      label: nextShellName,
      tier: nextTier,
      inheritedCore: promotedCore,
      initialEnemyDeck: List<String>.from(activeLayer.activeEnemyCardIds),
      sourceLayerId: activeLayer.id,
    );
    _layers.add(parent);
    activeLayer.promotedParentLayerId = parent.id;
    _storeActiveLayer();
    _viewLayerId = parent.id;
    _runtimeLayerId = parent.id;
    _loadLayer(parent);
    _showBanner(
      '$nextShellName aligned with ${_traitSignatureLabel(forgedAffinity, forgedTraits.payloadAffinity)} • ${forgedProjectile.label} • ${forgedPayload.label}. Edge slots now grow $sourceShellName anchors; source + six anchors make the 7-shell cluster.${_progressionUnlockBannerFragment(previousProgressionLayer)}',
    );
    _notifyNow();
  }

  // TODO(full-game): Enemy card draws should come from a signed backend result
  // so pity, rates, and inventory grants cannot be spoofed locally.
}
