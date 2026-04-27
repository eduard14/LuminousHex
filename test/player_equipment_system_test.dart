import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

EnemyState _enemyFromConfig(EnemyConfig config, {int cardLevel = 1}) {
  return EnemyState(
    id: 'test_${config.id}_$cardLevel',
    sourceCardId: config.id,
    cardLevel: cardLevel,
    config: config,
    spawnRadius: 900,
    angle: 0,
    radius: 900,
    health: config.baseHealth,
    maxHealth: config.baseHealth,
    defense: config.baseDefense,
    speed: config.baseSpeed,
    reward: config.reward,
    experienceReward: config.baseExperience,
    jamStrength: config.jamStrength,
    angularVelocity: config.baseSpiralDrift,
    splitDepth: 0,
    sizeScale: 1,
  );
}

void main() {
  test('equipment drops are reserved for weekly event caches', () {
    final controller = LightcoreController(
      packRandom: Random(1),
      traitRandom: Random(2),
      managerRandom: Random(3),
    );
    addTearDown(controller.dispose);

    final basicEnemy = _enemyFromConfig(EnemyLibrary.basicWhite, cardLevel: 1);
    final epicEnemy = _enemyFromConfig(
      EnemyLibrary.byRarity[EnemyCardRarity.epic]!.first,
      cardLevel: 8,
    );
    final bossEnemy = _enemyFromConfig(
      BossEnemyLibrary.all.first,
      cardLevel: 10,
    );

    expect(controller.equipmentDropChanceForEnemy(basicEnemy), 0);
    expect(controller.equipmentDropChanceForEnemy(epicEnemy), 0);
    expect(controller.equipmentDropChanceForEnemy(bossEnemy), 0);
  });

  test('matching outfit pieces unlock set bonuses and raise tower power', () {
    final controller = LightcoreController(
      packRandom: Random(4),
      traitRandom: Random(5),
      managerRandom: Random(6),
    );
    addTearDown(controller.dispose);

    final emberEnemy = _enemyFromConfig(
      EnemyLibrary.all.firstWhere(
        (config) =>
            config.affinity == PrototypeAffinity.ember &&
            config.rarity == EnemyCardRarity.rare,
      ),
      cardLevel: 10,
    );

    final hat = controller.debugGrantEquipmentDropForEnemy(
      emberEnemy,
      slotType: EquipmentInventorySlot.hat,
      rarity: ManagerRarity.rare,
      level: 10,
    );
    final top = controller.debugGrantEquipmentDropForEnemy(
      emberEnemy,
      slotType: EquipmentInventorySlot.top,
      rarity: ManagerRarity.rare,
      level: 10,
    );

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.buildTowerAt(0, TowerLibrary.redPrism);

    final powerBefore = controller.towerPower(controller.slots[0]);
    final towerStrengthBefore = controller.towerStrength;

    expect(controller.newEquipmentNotificationCount, 2);
    expect(
      controller.equipPlayerItem(hat.instanceId, EquipmentLoadoutSlot.hat),
      isTrue,
    );
    expect(
      controller.equipPlayerItem(top.instanceId, EquipmentLoadoutSlot.top),
      isTrue,
    );

    final activeSet = controller.activeEquipmentSets.single;
    final totalBonuses = controller.equipmentBonuses;
    final powerAfter = controller.towerPower(controller.slots[0]);

    expect(activeSet.config.name, 'Ashspike');
    expect(activeSet.equippedCount, 2);
    expect(
      activeSet.unlockedBonuses.map((bonus) => bonus.pieceCount),
      contains(2),
    );
    expect(
      totalBonuses.towerPower,
      greaterThan(hat.bonuses.towerPower + top.bonuses.towerPower),
    );
    expect(powerAfter, greaterThan(powerBefore));
    expect(controller.towerStrength, greaterThan(towerStrengthBefore));
    expect(controller.newEquipmentNotificationCount, 0);
  });

  test(
    'auto dismantle trims older unused equipment and preserves equipped gear',
    () {
      final controller = LightcoreController(
        packRandom: Random(7),
        traitRandom: Random(8),
        managerRandom: Random(9),
      );
      addTearDown(controller.dispose);

      final enemy = _enemyFromConfig(EnemyLibrary.basicWhite, cardLevel: 6);
      final equippedHat = controller.debugGrantEquipmentDropForEnemy(
        enemy,
        slotType: EquipmentInventorySlot.hat,
        rarity: ManagerRarity.legendary,
        level: 9,
      );

      expect(
        controller.equipPlayerItem(
          equippedHat.instanceId,
          EquipmentLoadoutSlot.hat,
        ),
        isTrue,
      );

      for (var i = 0; i < 40; i++) {
        controller.debugGrantEquipmentDropForEnemy(
          enemy,
          slotType: EquipmentInventorySlot.hat,
          rarity: ManagerRarity.common,
          level: 1,
        );
      }

      final fluxBefore = controller.flux;
      final removed = controller.autoDismantleOldEquipment();

      expect(removed, 8);
      expect(controller.playerEquipmentById(equippedHat.instanceId), isNotNull);
      expect(controller.isPlayerItemEquipped(equippedHat.instanceId), isTrue);
      expect(
        controller.equipmentInventory
            .where((item) => item.slotType == EquipmentInventorySlot.hat)
            .length,
        33,
      );
      expect(controller.flux, greaterThan(fluxBefore));
    },
  );

  test(
    'equipment inventory caps at 200 pieces and removes the oldest overflow',
    () {
      final controller = LightcoreController(
        packRandom: Random(10),
        traitRandom: Random(11),
        managerRandom: Random(12),
      );
      addTearDown(controller.dispose);

      final enemy = _enemyFromConfig(EnemyLibrary.basicWhite, cardLevel: 3);
      final grantedItems = <PlayerEquipmentItem>[];
      for (var i = 0; i < 205; i++) {
        grantedItems.add(
          controller.debugGrantEquipmentDropForEnemy(
            enemy,
            slotType: EquipmentInventorySlot.hat,
            rarity: ManagerRarity.common,
            level: 1,
          ),
        );
      }

      expect(
        controller.equipmentInventory.length,
        LightcoreController.maxEquipmentInventorySize,
      );
      expect(
        controller.playerEquipmentById(grantedItems[0].instanceId),
        isNull,
      );
      expect(
        controller.playerEquipmentById(grantedItems[4].instanceId),
        isNull,
      );
      expect(
        controller.playerEquipmentById(grantedItems[5].instanceId),
        isNotNull,
      );
      expect(
        controller.playerEquipmentById(grantedItems.last.instanceId),
        isNotNull,
      );
      expect(
        controller.newEquipmentNotificationCount,
        LightcoreController.maxEquipmentInventorySize,
      );

      controller.markNewEquipmentNotificationsSeen();

      expect(controller.newEquipmentNotificationCount, 0);
    },
  );
}
