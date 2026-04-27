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

    expect(
      controller.startTowerFabricationAt(0, TowerLibrary.redPrism),
      isTrue,
    );

    final fabricatingTower = controller.slots[0];
    expect(fabricatingTower.isFabricating, isTrue);
    expect(
      fabricatingTower.fabricationTotalSeconds,
      LightcoreController.towerConstructionDurationSeconds,
    );
    expect(
      fabricatingTower.fabricationRemainingSeconds,
      LightcoreController.towerConstructionDurationSeconds,
    );
    expect(
      controller.towerFabricationDurationForConfig(TowerLibrary.redPrism),
      LightcoreController.towerConstructionDurationSeconds,
    );
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
}
