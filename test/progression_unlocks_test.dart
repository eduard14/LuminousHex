import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _maxOutCurrentTier1Shell(LightcoreController controller) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  expect(controller.isPromotionReady, isTrue);
}

void _promoteRootShell(LightcoreController controller) {
  _maxOutCurrentTier1Shell(controller);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 2);
}

void _promoteTier1ChildIntoCurrentCompositeSlot(
  LightcoreController controller,
  int slotIndex,
  PrototypeAffinity affinity,
) {
  final parentLayerId = controller.activeLayer.id;
  expect(controller.activeLayer.tier, greaterThan(1));
  expect(controller.createChildLayer(slotIndex, affinity), isTrue);
  expect(controller.activeLayer.tier, 1);
  expect(controller.activeLayer.parentLayerId, parentLayerId);

  _maxOutCurrentTier1Shell(controller);
  controller.unlockLayer2Tower();

  expect(controller.activeLayer.id, parentLayerId);
  expect(controller.slots[slotIndex].isPromotedChildTower, isTrue);
}

void _fillCurrentCompositeLayerWithPromotedTier1Children(
  LightcoreController controller,
) {
  const affinities = LightcoreController.childCoreAffinityChoices;
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    _promoteTier1ChildIntoCurrentCompositeSlot(
      controller,
      index,
      affinities[index % affinities.length],
    );
  }
}

void main() {
  test('layer 1 outer slots use multi-hour pacing thresholds', () {
    expect(LightcoreController.outerSlotUnlockExperienceThresholds, <int>[
      0,
      100,
      250,
      500,
      850,
      1250,
    ]);
    expect(
      List<int>.generate(
        LightcoreController.slotCount,
        LightcoreController.unlockExperienceForOuterSlot,
      ),
      LightcoreController.outerSlotUnlockExperienceThresholds,
    );

    expect(LightcoreController.unlockedOuterSlotCountForExperience(0), 1);
    expect(LightcoreController.unlockedOuterSlotCountForExperience(99), 1);
    expect(LightcoreController.unlockedOuterSlotCountForExperience(100), 2);
    expect(LightcoreController.unlockedOuterSlotCountForExperience(1249), 5);
    expect(LightcoreController.unlockedOuterSlotCountForExperience(1250), 6);
  });

  test('layer 1 starts projectile-only and manager-free', () {
    final controller = LightcoreController(traitRandom: Random(3));
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);

    expect(controller.layerNavigationUnlocked, isFalse);
    expect(controller.payloadsUnlocked, isFalse);
    expect(controller.managersUnlocked, isFalse);
    expect(controller.managerAssignmentUnlocked, isFalse);
    expect(controller.cards, isEmpty);
    expect(controller.enemyManagers, isEmpty);

    controller.buildTowerAt(0, TowerLibrary.redPrism);
    final tower = controller.slots[0];

    expect(controller.towerProjectileType(tower), ProjectileType.coreBomb);
    expect(controller.towerPayloadLabel(tower), 'No Payload');
    expect(controller.corePayloadLabel, 'No Payload');
    expect(controller.canForgeTowerManager, isFalse);
    expect(controller.canForgeEnemyManager, isFalse);
  });

  test(
    'first promotion unlocks promoted payloads while layer 1 stays pure',
    () {
      final controller = LightcoreController(traitRandom: Random(7));
      addTearDown(controller.dispose);

      _promoteRootShell(controller);

      expect(controller.layerNavigationUnlocked, isTrue);
      expect(controller.payloadsUnlocked, isTrue);
      expect(controller.managersUnlocked, isFalse);
      expect(controller.managerAssignmentUnlocked, isTrue);
      expect(controller.coreState.projectileType.tier, 2);
      expect(controller.coreState.payloadType.tier, 2);

      expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
      controller.lumens = 1000;
      controller.buildTowerAt(0, TowerLibrary.redPrism);

      expect(controller.towerPayloadLabel(controller.slots[0]), 'No Payload');
    },
  );

  test('new shells keep their own enemy deck defaulting to White Basic', () {
    final controller = LightcoreController(traitRandom: Random(9));
    addTearDown(controller.dispose);

    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicWhite.id,
    );
    controller.debugSetEnemyCardLevel(EnemyLibrary.basicRed.id, level: 1);
    controller.toggleEnemyCardSelection(EnemyLibrary.basicRed.id);
    controller.toggleEnemyCardSelection(EnemyLibrary.basicWhite.id);
    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicRed.id,
    );

    final rootLayerId = controller.activeLayer.id;
    _promoteRootShell(controller);
    final prismLayerId = controller.activeLayer.id;

    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicRed.id,
    );

    final rootLayer = controller.layers.firstWhere(
      (layer) => layer.id == rootLayerId,
    );
    expect(controller.isLayerPassiveOnly(rootLayer), isTrue);
    controller.enterLayerById(rootLayerId);
    expect(controller.activeLayer.id, prismLayerId);
    expect(controller.bannerMessage, contains('passive support'));

    controller.enterLayerById(prismLayerId);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicWhite.id,
    );
  });

  test('promoted core inherits source enemies and gets solo packet power', () {
    final controller = LightcoreController(traitRandom: Random(5));
    addTearDown(controller.dispose);

    expect(
      controller.debugSetEnemyCardLevel(EnemyLibrary.basicRed.id, level: 1),
      isTrue,
    );
    controller.toggleEnemyCardSelection(EnemyLibrary.basicRed.id);
    controller.toggleEnemyCardSelection(EnemyLibrary.basicWhite.id);
    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicRed.id,
    );

    _promoteRootShell(controller);

    expect(
      controller.activeEnemyDeck.single.config.id,
      EnemyLibrary.basicRed.id,
    );

    controller.handleBattleCenterTap();
    controller.handleBattleCenterTap();
    controller.tick(0.65);

    expect(controller.queuedAmmoPackets, hasLength(1));
    expect(controller.queuedAmmoPackets.single.power, greaterThan(26));
  });

  test(
    'layer 3 parent slots can be filled by promoted merged layer 2 shells',
    () {
      final controller = LightcoreController(traitRandom: Random(23));
      addTearDown(controller.dispose);

      _promoteRootShell(controller);
      _fillCurrentCompositeLayerWithPromotedTier1Children(controller);
      expect(controller.isPromotionReady, isTrue);

      controller.unlockLayer2Tower();
      final tier3LayerId = controller.activeLayer.id;
      expect(controller.activeLayer.tier, 3);

      expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
      final nestedLayer2Id = controller.activeLayer.id;
      expect(controller.activeLayer.tier, 2);
      expect(controller.activeLayer.parentLayerId, tier3LayerId);
      expect(controller.activeLayerHasParentSlot, isTrue);

      _fillCurrentCompositeLayerWithPromotedTier1Children(controller);
      expect(controller.activeLayer.id, nestedLayer2Id);
      expect(controller.activeLayer.tier, 2);
      expect(controller.isPromotionReady, isTrue);

      controller.unlockLayer2Tower();
      expect(controller.activeLayer.id, tier3LayerId);
      expect(controller.activeLayer.tier, 3);
      expect(controller.slots[0].isPromotedChildTower, isTrue);
      expect(controller.childPromotionReadyTowerCount(controller.slots[0]), 6);
    },
  );

  test('prism shell can assign existing managers before foundry unlock', () {
    final controller = LightcoreController(traitRandom: Random(9));
    addTearDown(controller.dispose);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.managerUnlockLevel,
    );
    controller.flux =
        LightcoreController.towerManagerFluxCost +
        LightcoreController.enemyManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    expect(controller.forgeEnemyManager(), isTrue);
    final towerManagerId = controller.cards.single.instanceId;
    final enemyManagerId = controller.enemyManagers.single.instanceId;

    controller.experience = 0;
    controller.equipCardToCore(towerManagerId);
    controller.assignEnemyManagerToCore(enemyManagerId);
    expect(controller.towerCoreManager, isNull);
    expect(controller.enemyCoreManager, isNull);

    _promoteRootShell(controller);
    controller.flux =
        LightcoreController.towerManagerFluxCost +
        LightcoreController.enemyManagerFluxCost;

    expect(
      controller.overallLevel,
      lessThan(LightcoreController.managerUnlockLevel),
    );
    expect(controller.managersUnlocked, isFalse);
    expect(controller.managerAssignmentUnlocked, isTrue);
    expect(controller.canForgeTowerManager, isFalse);
    expect(controller.canForgeEnemyManager, isFalse);

    controller.equipCardToCore(towerManagerId);
    controller.assignEnemyManagerToCore(enemyManagerId);

    expect(controller.towerCoreManager?.instanceId, towerManagerId);
    expect(controller.enemyCoreManager?.instanceId, enemyManagerId);
    expect(
      controller
          .enemyManagerForCard(EnemyLibrary.starterDefault.id)
          ?.instanceId,
      enemyManagerId,
    );
  });

  test('overall level 10 unlocks the manager foundry', () {
    final controller = LightcoreController(traitRandom: Random(11));
    addTearDown(controller.dispose);

    expect(controller.canForgeTowerManager, isFalse);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.managerUnlockLevel,
    );
    controller.flux =
        LightcoreController.towerManagerFluxCost +
        LightcoreController.enemyManagerFluxCost;

    expect(controller.payloadsUnlocked, isFalse);
    expect(controller.managersUnlocked, isTrue);
    expect(controller.canForgeTowerManager, isTrue);
    expect(controller.canForgeEnemyManager, isTrue);

    expect(controller.forgeTowerManager(), isTrue);
    expect(controller.forgeEnemyManager(), isTrue);
    expect(controller.cards, hasLength(1));
    expect(controller.enemyManagers, hasLength(1));
  });

  test('overall level 15 unlocks daily dungeons', () {
    final controller = LightcoreController(traitRandom: Random(13));
    addTearDown(controller.dispose);

    expect(controller.dailyDungeonsUnlocked, isFalse);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.dailyDungeonUnlockLevel,
    );

    expect(controller.managersUnlocked, isTrue);
    expect(controller.dailyDungeonsUnlocked, isTrue);
    expect(controller.tournamentsUnlocked, isFalse);
  });

  test('overall level 30 unlocks mentorship', () {
    final controller = LightcoreController(traitRandom: Random(15));
    addTearDown(controller.dispose);

    expect(controller.mentorshipUnlocked, isFalse);
    expect(
      controller.mentorshipLevelsRemaining,
      LightcoreController.mentorshipUnlockLevel - controller.overallLevel,
    );

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.mentorshipUnlockLevel,
    );

    expect(controller.mentorshipUnlocked, isTrue);
    expect(controller.mentorshipLevelsRemaining, 0);
  });

  test('daily dungeon tower clears unlock the next stronger reward level', () {
    final controller = LightcoreController(traitRandom: Random(17));
    addTearDown(controller.dispose);
    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.dailyDungeonUnlockLevel,
    );

    final levelOneReward = controller.dailyDungeonRewardForLevel(1);
    final levelTwoReward = controller.dailyDungeonRewardForLevel(2);
    final startingLumens = controller.lumens;
    final startingFlux = controller.flux;
    final startingTickets = controller.enemyTickets;

    expect(levelTwoReward.lumens, greaterThan(levelOneReward.lumens));
    expect(levelTwoReward.flux, greaterThan(levelOneReward.flux));
    expect(controller.dailyDungeonHighestUnlockedTowerLevel, 1);
    expect(controller.isDailyDungeonTowerLevelUnlocked(2), isFalse);

    final clearReward = controller.clearDailyDungeonTowerLevel(
      1,
      showBanner: false,
    );

    expect(clearReward, isNotNull);
    expect(clearReward!.hasRewards, isTrue);
    expect(controller.dailyDungeonHighestClearedTowerLevel, 1);
    expect(controller.dailyDungeonHighestUnlockedTowerLevel, 2);
    expect(controller.isDailyDungeonTowerLevelUnlocked(2), isTrue);
    expect(controller.lumens, startingLumens + levelOneReward.lumens);
    expect(controller.flux, startingFlux + levelOneReward.flux);
    expect(
      controller.enemyTickets,
      startingTickets + levelOneReward.threatScans,
    );

    final replayReward = controller.clearDailyDungeonTowerLevel(
      1,
      showBanner: false,
    );
    expect(replayReward, isNotNull);
    expect(replayReward!.hasRewards, isFalse);
  });

  test('daily dungeon tower profiles are fixed and strengthen by level', () {
    final controller = LightcoreController(traitRandom: Random(18));
    addTearDown(controller.dispose);

    final levelOne = controller.dailyDungeonTowerProfileForLevel(1);
    final levelTwo = controller.dailyDungeonTowerProfileForLevel(2);
    final levelThree = controller.dailyDungeonTowerProfileForLevel(3);

    expect(levelOne.config, TowerLibrary.whitePrism);
    expect(levelTwo.config, TowerLibrary.redPrism);
    expect(levelThree.config, TowerLibrary.orangePrism);
    expect(levelTwo.maxHealth, greaterThan(levelOne.maxHealth));
    expect(levelThree.maxHealth, greaterThan(levelTwo.maxHealth));
    expect(levelTwo.shotDamage, greaterThan(levelOne.shotDamage));
    expect(levelThree.shotDamage, greaterThan(levelTwo.shotDamage));
  });

  test('daily dungeon tower ladder persists in cloud saves', () {
    final controller = LightcoreController(traitRandom: Random(19));
    addTearDown(controller.dispose);
    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.dailyDungeonUnlockLevel,
    );
    controller.clearDailyDungeonTowerLevel(1, showBanner: false);

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.dailyDungeonHighestClearedTowerLevel, 1);
    expect(restored.dailyDungeonHighestUnlockedTowerLevel, 2);
    expect(restored.isDailyDungeonTowerLevelUnlocked(2), isTrue);
  });
}
