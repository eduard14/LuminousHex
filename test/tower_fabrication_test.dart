import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _promoteRootShell(LightcoreController controller) {
  controller.lumens = 100000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    expect(controller.buildTowerAt(index, TowerLibrary.all[index]), isTrue);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      expect(controller.upgradeTower(index), isTrue);
    }
  }
  expect(controller.isPromotionReady, isTrue);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 2);
}

void main() {
  test('tower fabrication reserves a slot until the timer completes', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.lumens = 1000;

    final initialDuration = controller.towerFabricationDurationForConfig(
      TowerLibrary.redPrism,
    );
    expect(
      initialDuration,
      LightcoreController.towerConstructionDurationSeconds,
    );

    expect(
      controller.startTowerFabricationAt(0, TowerLibrary.redPrism),
      isTrue,
    );

    final fabricatingTower = controller.slots[0];
    expect(fabricatingTower.isFabricating, isTrue);
    expect(fabricatingTower.fabricationTotalSeconds, initialDuration);
    expect(fabricatingTower.fabricationRemainingSeconds, initialDuration);
    expect(controller.builtTowerCount, 0);
    expect(controller.upgradeTower(0), isFalse);

    controller.tick(fabricatingTower.fabricationRemainingSeconds - 0.1);

    expect(controller.slots[0].isFabricating, isTrue);
    expect(controller.builtTowerCount, 0);

    controller.tick(0.2);
    controller.lumens = 1000;

    expect(controller.slots[0].isFabricating, isFalse);
    expect(controller.builtTowerCount, 1);
    expect(controller.upgradeTower(0), isTrue);
  });

  test('background child-shell fabrication advances while viewing parent', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    final parentLayerId = controller.activeLayer.id;
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    final childLayerId = controller.activeLayer.id;
    controller.lumens = 1000;

    expect(
      controller.startTowerFabricationAt(0, TowerLibrary.redPrism),
      isTrue,
    );
    final duration = controller.slots[0].fabricationRemainingSeconds;

    controller.enterLayerById(parentLayerId);
    controller.tick(duration + 0.1);
    controller.enterLayerById(childLayerId);

    expect(controller.slots[0].isFabricating, isFalse);
    expect(controller.builtTowerCount, 1);
  });

  test('root layer 1 fabrication uses the layer 1 ramp timer', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(
      LightcoreController.slotCount - 1,
    );
    controller.lumens = 1000000000;

    final durations = <double>[];
    for (var index = 0; index < LightcoreController.slotCount; index++) {
      final duration = controller.towerFabricationDurationForConfig(
        TowerLibrary.redPrism,
      );
      durations.add(duration);
      expect(
        controller.startTowerFabricationAt(index, TowerLibrary.redPrism),
        isTrue,
      );
      expect(controller.slots[index].fabricationTotalSeconds, duration);
    }

    expect(
      durations.first,
      LightcoreController.towerConstructionDurationSeconds,
    );
    for (var index = 1; index < durations.length; index++) {
      expect(durations[index], greaterThan(durations[index - 1]));
    }
    expect(
      durations.last,
      LightcoreController.layer1ChildTowerMaxConstructionDurationSeconds,
    );
  });

  test('layer 1 child-shell fabrication ramps up to twenty minutes', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
    controller.lumens = 1000000000;

    final durations = <double>[];
    for (var index = 0; index < LightcoreController.slotCount; index++) {
      final duration = controller.towerFabricationDurationForConfig(
        TowerLibrary.redPrism,
      );
      durations.add(duration);
      expect(
        controller.startTowerFabricationAt(index, TowerLibrary.redPrism),
        isTrue,
      );
      expect(controller.slots[index].fabricationTotalSeconds, duration);
    }

    expect(
      durations.first,
      LightcoreController.towerConstructionDurationSeconds,
    );
    for (var index = 1; index < durations.length; index++) {
      expect(durations[index], greaterThan(durations[index - 1]));
    }
    expect(
      durations.last,
      LightcoreController.layer1ChildTowerMaxConstructionDurationSeconds,
    );
  });

  test('layer 2 caps active layer 1 core projects by membership', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _promoteRootShell(controller);
    final parentLayerId = controller.activeLayer.id;

    expect(controller.showsLayerOneCoreCreation, isTrue);
    expect(controller.layerOneCoreProjectLimit, 1);
    expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);

    controller.enterLayerById(parentLayerId);
    expect(controller.layerOneCoreProjectsInProgress, 1);
    expect(controller.canCreateLayerOneCore, isFalse);
    expect(controller.createChildLayer(1, PrototypeAffinity.ember), isFalse);

    expect(controller.unlockPremiumMembership(showBanner: false), isTrue);
    expect(controller.layerOneCoreProjectLimit, 2);
    expect(controller.createChildLayer(1, PrototypeAffinity.ember), isTrue);
  });
}
