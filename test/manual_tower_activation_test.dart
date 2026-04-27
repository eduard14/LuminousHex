import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _maxOutCurrentShell(LightcoreController controller, TowerConfig config) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    expect(controller.buildTowerAt(index, config), isTrue);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      expect(controller.upgradeTower(index), isTrue);
    }
  }
  expect(controller.isPromotionReady, isTrue);
}

void main() {
  test('battle slot taps activate built towers without opening stats', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    controller.selectCenter();
    expect(controller.selectedSlotIndex, isNull);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.handleBattleSlotTap(0);

    expect(controller.selectedSlotIndex, isNull);
    expect(controller.towerRangePreviewSlotIndex, 0);
    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].charge, 0);
  });

  test('unmanaged towers hold charge while managers automate ready taps', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    controller.tick(5);

    expect(controller.slots[0].charge, greaterThanOrEqualTo(1));
    expect(controller.pulses, isEmpty);
    expect(controller.queuedCorePackets, 0);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.managerUnlockLevel,
    );
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    controller.equipCardToSlot(controller.cards.single.instanceId, 0);

    controller.tick(0.1);

    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].charge, 0);
  });

  test('manual tower taps are disabled once a manager automates the shell', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.managerUnlockLevel,
    );
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    controller.equipCardToSlot(controller.cards.single.instanceId, 0);

    expect(controller.canActivateTower(controller.slots[0]), isTrue);
    expect(controller.canManuallyActivateTower(controller.slots[0]), isFalse);

    controller.handleBattleSlotTap(0);

    expect(controller.pulses, isEmpty);
    expect(controller.slots[0].charge, greaterThanOrEqualTo(1));

    controller.tick(0.1);

    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].charge, 0);
  });

  test('core managers apply across towers and enemies on the active shell', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(1);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.buildTowerAt(1, TowerLibrary.greenPrism), isTrue);
    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.managerUnlockLevel,
    );

    controller.flux =
        LightcoreController.towerManagerFluxCost +
        LightcoreController.enemyManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    final towerManager = controller.cards.single;
    controller.equipCardToCore(towerManager.instanceId);

    expect(
      controller.cardForSlot(controller.slots[0])?.instanceId,
      towerManager.instanceId,
    );
    expect(
      controller.cardForSlot(controller.slots[1])?.instanceId,
      towerManager.instanceId,
    );

    expect(controller.forgeEnemyManager(), isTrue);
    final enemyManager = controller.enemyManagers.single;
    controller.assignEnemyManagerToCore(enemyManager.instanceId);

    expect(
      controller
          .enemyManagerForCard(EnemyLibrary.starterDefault.id)
          ?.instanceId,
      enemyManager.instanceId,
    );
    expect(
      controller.enemyManagerForCard(EnemyLibrary.basicWhite.id)?.instanceId,
      enemyManager.instanceId,
    );
  });

  test('localhost auto tapper activates ready unmanaged towers', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.setLocalhostAutoTapperEnabled(true);
    controller.tick(0.1);

    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].fireSequence, 1);
    expect(controller.slots[0].charge, 0);
  });

  test('localhost auto tapper unfolds the shell and queues core taps', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
    );

    expect(controller.outerRingRevealed, isFalse);

    controller.setLocalhostAutoTapperEnabled(true);
    controller.tick(0.1);

    expect(controller.outerRingRevealed, isTrue);
    expect(
      controller.queuedCorePackets +
          controller.pulses.length +
          controller.shots.length,
      greaterThan(0),
    );
  });

  test('enemy leaks visibly lower core stability and output efficiency', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    expect(controller.coreState.coreStability, 100);
    expect(controller.outputEfficiencyLabel, '100%');
    expect(
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: controller.relayImpactRadius + 1,
      ),
      isNotNull,
    );

    controller.tick(0.1);

    expect(controller.enemies, isEmpty);
    expect(controller.coreState.coreStability, lessThan(99));
    expect(controller.outputEfficiencyLabel, isNot('100%'));
  });

  test(
    'promoted child tower taps generate packets instead of entering shell',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      _maxOutCurrentShell(controller, TowerLibrary.redPrism);
      controller.unlockLayer2Tower();
      expect(controller.activeLayer.tier, 2);

      expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
      _maxOutCurrentShell(controller, TowerLibrary.bluePrism);
      controller.unlockLayer2Tower();

      final parentLayerId = controller.activeLayer.id;
      expect(controller.slots[0].isPromotedChildTower, isTrue);
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

      controller.handleBattleSlotTap(0);

      expect(controller.activeLayer.id, parentLayerId);
      expect(controller.selectedSlotIndex, isNull);
      expect(controller.pulses, isNotEmpty);
      expect(controller.slots[0].charge, 0);
    },
  );
}
