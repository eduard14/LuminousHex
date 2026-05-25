import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/app/lightcore_bootstrap.dart';
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

  test('server clock anchors tower fabrication completion', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final startedAt = DateTime.utc(2026, 5, 24, 12);
    controller.syncServerClock(startedAt);
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.lumens = 1000;

    expect(
      controller.startTowerFabricationAt(0, TowerLibrary.redPrism),
      isTrue,
    );

    final fabricatingTower = controller.slots[0];
    expect(fabricatingTower.isFabricating, isTrue);
    expect(
      fabricatingTower.fabricationStartedAtServerMillis,
      startedAt.millisecondsSinceEpoch,
    );
    expect(
      fabricatingTower.fabricationCompletesAtServerMillis,
      startedAt
          .add(
            Duration(
              seconds: LightcoreController.towerConstructionDurationSeconds
                  .round(),
            ),
          )
          .millisecondsSinceEpoch,
    );

    controller.tick(fabricatingTower.fabricationRemainingSeconds + 60);

    expect(controller.slots[0].isFabricating, isTrue);
    expect(controller.builtTowerCount, 0);

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.slots[0].isFabricating, isTrue);
    expect(
      restored.slots[0].fabricationCompletesAtServerMillis,
      fabricatingTower.fabricationCompletesAtServerMillis,
    );

    controller.syncServerClock(
      startedAt.add(
        Duration(
          seconds: LightcoreController.towerConstructionDurationSeconds.round(),
        ),
      ),
    );

    expect(controller.slots[0].isFabricating, isFalse);
    expect(controller.builtTowerCount, 1);

    restored.syncServerClock(
      startedAt.add(
        Duration(
          seconds: LightcoreController.towerConstructionDurationSeconds.round(),
        ),
      ),
    );

    expect(restored.slots[0].isFabricating, isFalse);
    expect(restored.builtTowerCount, 1);
  });

  test('server offline claim advances fabrication without rewards', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.lumens = 1000;

    expect(
      controller.startTowerFabricationAt(0, TowerLibrary.redPrism),
      isTrue,
    );

    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 3,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 0,
        serverValidated: true,
      ),
      showBanner: false,
    );

    expect(controller.slots[0].isFabricating, isTrue);
    expect(controller.slots[0].fabricationRemainingSeconds, 2);
    expect(controller.builtTowerCount, 0);

    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 2,
        lumensGranted: 0,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: 0,
        serverValidated: true,
      ),
      showBanner: false,
    );

    expect(controller.slots[0].isFabricating, isFalse);
    expect(controller.builtTowerCount, 1);
    expect(controller.totalOfflineSecondsClaimed, 5);
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
    expect(durations, <double>[5, 45, 120, 240, 420, 600]);
    expect(
      durations.last,
      LightcoreController.layer1ChildTowerMaxConstructionDurationSeconds,
    );
  });

  test('layer 1 child-shell fabrication ramps up to ten minutes', () {
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
    expect(durations, <double>[5, 45, 120, 240, 420, 600]);
    expect(
      durations.last,
      LightcoreController.layer1ChildTowerMaxConstructionDurationSeconds,
    );
  });

  test('layer 1 tower build costs ramp toward a meaningful sixth tower', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(
      LightcoreController.slotCount - 1,
    );
    controller.lumens = 1000000000;

    final costs = <int>[];
    for (var index = 0; index < LightcoreController.slotCount; index++) {
      final config = TowerLibrary.all[index];
      costs.add(controller.buildCostForConfig(config));
      expect(controller.buildTowerAt(index, config), isTrue);
    }

    expect(costs, <int>[10, 25, 55, 110, 220, 400]);
    expect(costs.last, greaterThanOrEqualTo(costs.first * 40));
  });

  test('layer 2 caps active layer 1 set projects at one', () {
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
    expect(controller.layerOneCoreProjectLimit, 1);
    expect(controller.createChildLayer(1, PrototypeAffinity.ember), isFalse);
  });
}
