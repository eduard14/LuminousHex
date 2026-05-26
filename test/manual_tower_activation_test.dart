import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _completeLayer1Coverage(
  LightcoreController controller,
  TowerConfig config,
) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    if (controller.slots[index].config == null &&
        !controller.slots[index].isPromotedChildTower) {
      expect(controller.buildTowerAt(index, config), isTrue);
    }
    final remaining = controller.slots[index].fabricationRemainingSeconds;
    if (remaining > 0) {
      controller.tick(remaining + 0.1);
    }
  }
  expect(controller.managerAssignmentUnlocked, isTrue);
}

void _maxOutCurrentShell(LightcoreController controller, TowerConfig config) {
  _completeLayer1Coverage(controller, config);
  controller.lumens = 100000000;
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      expect(controller.upgradeTower(index), isTrue);
    }
  }
  expect(controller.isPromotionReady, isTrue);
}

double _healthForEnemy(LightcoreController controller, String enemyId) {
  return controller.enemies.firstWhere((enemy) => enemy.id == enemyId).health;
}

void main() {
  test(
    'battle slot taps select built towers while payloads feed separately',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();

      controller.lumens = 1000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
      expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
      controller.selectCenter();
      expect(controller.selectedSlotIndex, isNull);
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

      controller.handleBattleSlotTap(0);

      expect(controller.selectedSlotIndex, 0);
      expect(controller.towerRangePreviewSlotIndex, 0);
      expect(controller.pulses, isEmpty);
      expect(controller.slots[0].charge, greaterThanOrEqualTo(1));
    },
  );

  test('unmanaged towers auto-feed payload pieces at starter rate', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.tick(0.1);

    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].charge, 0);
  });

  test('core managers improve payload feed after shell coverage', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    final starterRate = controller.towerPayloadFeedRate(controller.slots[0]);

    _completeLayer1Coverage(controller, TowerLibrary.redPrism);
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    controller.equipCardToSlot(controller.cards.single.instanceId, 0);

    final managedRate = controller.towerPayloadFeedRate(controller.slots[0]);
    expect(managedRate, greaterThan(starterRate));
  });

  test('payload boost accelerates a floating piece toward the queue', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.tick(0.1);

    expect(controller.pulses, isNotEmpty);
    final pulse = controller.pulses.singleWhere(
      (candidate) => candidate.sourceSlotIndex == 0,
    );
    expect(controller.boostPulseToCore(pulse.id), isTrue);
    expect(
      controller.pulses
          .singleWhere((candidate) => candidate.id == pulse.id)
          .progress,
      greaterThan(pulse.progress),
    );
  });

  test('critical boosted payload packets guarantee critical shots', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.tick(0.1);
    final pulse = controller.pulses.singleWhere(
      (candidate) => candidate.sourceSlotIndex == 0,
    );
    expect(
      controller.releaseDraggedPulse(pulse.id, crossedSourceTower: true),
      isTrue,
    );
    for (
      var step = 0;
      step < 80 && controller.queuedAmmoPackets.isEmpty;
      step += 1
    ) {
      controller.tick(0.05);
    }

    expect(
      controller.queuedAmmoPackets.any((packet) => packet.criticalBoosted),
      isTrue,
    );
    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 180,
      level: 1,
    );
    expect(enemy, isNotNull);
    for (var step = 0; step < 80 && controller.shots.isEmpty; step += 1) {
      controller.tick(0.05);
    }
    expect(controller.shots.any((shot) => shot.criticalBoosted), isTrue);
    for (
      var step = 0;
      step < 80 && !controller.impacts.any((impact) => impact.critical);
      step += 1
    ) {
      controller.tick(0.05);
    }
    expect(controller.impacts.any((impact) => impact.critical), isTrue);
  });

  test('default auto manager generates center payload pieces', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.tick(0.1);

    final corePulses = controller.pulses.where(
      (pulse) => pulse.sourceSlotIndex == null,
    );
    expect(corePulses, isNotEmpty);
    expect(controller.coreState.automationCooldownRemaining, greaterThan(0));
  });

  test('auto payload pieces orbit before drifting to the core', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.tick(0.1);

    final pulse = controller.pulses.firstWhere(
      (candidate) => candidate.sourceSlotIndex == null,
    );
    expect(pulse.progress, lessThanOrEqualTo(-3));

    for (var step = 0; step < 25; step += 1) {
      controller.tick(0.1);
    }
    expect(
      controller.pulses
          .firstWhere((candidate) => candidate.id == pulse.id)
          .progress,
      lessThan(0),
    );

    for (
      var step = 0;
      step < 90 && controller.queuedAmmoPackets.isEmpty;
      step += 1
    ) {
      controller.tick(0.1);
    }
    expect(controller.queuedAmmoPackets, isNotEmpty);
  });

  test('default auto manager caps floating center payload pieces', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    for (var step = 0; step < 60; step += 1) {
      controller.tick(0.1);
    }

    final corePulses = controller.pulses.where(
      (pulse) => pulse.sourceSlotIndex == null,
    );
    expect(corePulses, isNotEmpty);
    expect(
      corePulses.length,
      lessThanOrEqualTo(LightcoreController.maxFloatingPayloadsPerSource),
    );
  });

  test('core managers improve center payload feed', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final starterRate = controller.corePayloadFeedRate();
    _completeLayer1Coverage(controller, TowerLibrary.redPrism);
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    controller.equipCardToCore(controller.cards.single.instanceId);

    expect(controller.corePayloadFeedRate(), greaterThan(starterRate));
  });

  test('core manager assignment carries into promoted layer 2 shell', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _completeLayer1Coverage(controller, TowerLibrary.redPrism);
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    final managerId = controller.cards.single.instanceId;
    controller.equipCardToCore(managerId);

    _maxOutCurrentShell(controller, TowerLibrary.redPrism);
    controller.unlockLayer2Tower();

    expect(controller.activeLayer.tier, 2);
    expect(controller.towerCoreManager?.instanceId, managerId);
  });

  test(
    'layer 2 core manager waits for child shell coverage before inheriting',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      _completeLayer1Coverage(controller, TowerLibrary.redPrism);
      controller.flux = LightcoreController.towerManagerFluxCost;
      expect(controller.forgeTowerManager(), isTrue);
      final managerId = controller.cards.single.instanceId;
      controller.equipCardToCore(managerId);

      _maxOutCurrentShell(controller, TowerLibrary.redPrism);
      controller.unlockLayer2Tower();
      expect(controller.activeLayer.tier, 2);
      expect(controller.towerCoreManager?.instanceId, managerId);

      expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
      expect(controller.activeLayer.tier, 1);
      expect(controller.managerAssignmentUnlocked, isFalse);
      expect(controller.towerCoreManager, isNull);

      _completeLayer1Coverage(controller, TowerLibrary.bluePrism);
      expect(controller.towerCoreManager?.instanceId, managerId);
      expect(
        controller.cardForSlot(controller.slots[0])?.instanceId,
        managerId,
      );
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

      controller.tick(0.1);

      expect(controller.pulses, isNotEmpty);
      expect(controller.slots[0].charge, 0);
    },
  );

  test('layer 2 core manager automates promoted child towers', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _completeLayer1Coverage(controller, TowerLibrary.redPrism);
    controller.flux = LightcoreController.towerManagerFluxCost;
    expect(controller.forgeTowerManager(), isTrue);
    final managerId = controller.cards.single.instanceId;
    controller.equipCardToCore(managerId);

    _maxOutCurrentShell(controller, TowerLibrary.redPrism);
    controller.unlockLayer2Tower();
    expect(controller.activeLayer.tier, 2);

    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    _maxOutCurrentShell(controller, TowerLibrary.bluePrism);
    controller.unlockLayer2Tower();

    expect(controller.activeLayer.tier, 2);
    expect(controller.slots[0].isPromotedChildTower, isTrue);
    expect(controller.cardForSlot(controller.slots[0])?.instanceId, managerId);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    controller.tick(0.1);

    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].charge, 0);
  });

  test('core managers apply across towers and enemies on the active shell', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _completeLayer1Coverage(controller, TowerLibrary.redPrism);

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

  test('red tower bomb damages nearby enemies through payload feed', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    final primaryEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 180,
      level: 1,
    );
    final splashEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.12,
      radius: 180,
      level: 16,
    );
    final outsideEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 3.05,
      radius: 320,
      level: 16,
    );
    expect(primaryEnemy, isNotNull);
    expect(splashEnemy, isNotNull);
    expect(outsideEnemy, isNotNull);

    final initialSplashHealth = _healthForEnemy(controller, splashEnemy!.id);
    final initialOutsideHealth = _healthForEnemy(controller, outsideEnemy!.id);

    controller.tick(0.1);
    expect(controller.pulses, isNotEmpty);
    final towerPulse = controller.pulses.singleWhere(
      (pulse) => pulse.sourceSlotIndex == 0,
    );
    controller.boostPulseToCore(towerPulse.id);
    for (
      var step = 0;
      step < 80 &&
          controller.enemies.any((enemy) => enemy.id == primaryEnemy!.id);
      step += 1
    ) {
      controller.tick(0.05);
    }

    expect(
      controller.enemies.any((enemy) => enemy.id == primaryEnemy!.id),
      isFalse,
    );
    expect(
      _healthForEnemy(controller, splashEnemy.id),
      lessThan(initialSplashHealth),
    );
    expect(_healthForEnemy(controller, outsideEnemy.id), initialOutsideHealth);
  });

  test(
    'localhost auto tapper unfolds the shell and leaves core feed automatic',
    () {
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
    },
  );

  test('enemy leaks visibly lower core stability and output efficiency', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    expect(controller.battleNotificationBannersEnabled, isFalse);
    expect(controller.bannerMessage, isEmpty);
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
    expect(controller.bannerMessage, isEmpty);
  });

  test('battle alert banners are opt-in for passive combat pressure', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.setBattleNotificationBannersEnabled(true);

    expect(
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: controller.relayImpactRadius + 1,
      ),
      isNotNull,
    );

    controller.tick(0.1);

    expect(controller.bannerMessage, contains('Core Stability'));
  });

  test('promoted child slot taps select while payloads feed separately', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

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
    expect(controller.selectedSlotIndex, 0);
    expect(controller.pulses, isEmpty);
    expect(controller.slots[0].charge, greaterThanOrEqualTo(1));

    controller.tick(0.1);
    expect(controller.pulses, isNotEmpty);
    expect(controller.slots[0].charge, 0);
  });
}
