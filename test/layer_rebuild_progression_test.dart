import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('reset Layer 1 run restarts Wave 1 and clears run upgrades only', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    expect(controller.layerRunState.wave, 1);
    expect(controller.layerRunState.active, isTrue);
    expect(controller.sparks, LightcoreController.layer1BaseStartingSparks);
    expect(controller.coreState.coreStability, 100);

    expect(controller.buyRunUpgrade(LayerRunUpgradeType.damage), isTrue);
    controller.debugApplyLumenHarvestDamage(25);
    expect(controller.layerRunState.rankFor(LayerRunUpgradeType.damage), 1);
    expect(controller.coreState.level, 2);
    expect(controller.coreState.coreStability, lessThan(100));

    controller.resetLayer1Run();
    expect(controller.layerRunState.active, isTrue);
    expect(controller.layerRunState.wave, 1);
    expect(controller.layerRunState.rankFor(LayerRunUpgradeType.damage), 0);
    expect(controller.sparks, LightcoreController.layer1BaseStartingSparks);
    expect(controller.coreState.coreStability, 100);
    expect(controller.starBolts, 0);
  });

  test('run upgrades spend Sparks and map to existing core combat stats', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();

    expect(controller.buyRunUpgrade(LayerRunUpgradeType.damage), isTrue);
    expect(controller.buyRunUpgrade(LayerRunUpgradeType.fireRate), isTrue);
    expect(controller.buyRunUpgrade(LayerRunUpgradeType.multishot), isTrue);

    expect(controller.coreState.level, 2);
    expect(controller.coreState.fireSpeedUpgradeLevel, 1);
    expect(controller.coreState.multiShotUpgradeLevel, 1);
    expect(
      controller.sparks,
      lessThan(LightcoreController.layer1BaseStartingSparks),
    );
  });

  test('Layer 1 enemy defeats drop Sparks immediately', () {
    final controller = LightcoreController(spawnRandom: Random(23));
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.startLayer1Run();
    final beforeSparks = controller.sparks;
    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 360,
    );

    expect(enemy, isNotNull);
    expect(controller.debugDefeatEnemy(enemy!.id), isTrue);
    expect(
      controller.sparks,
      beforeSparks + LightcoreController.layer1SparksPerEnemy,
    );
  });

  test('feeder construction uses the player selected color', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();

    expect(
      controller.buildLayer1FeederAt(0, config: TowerLibrary.redPrism),
      isTrue,
    );
    expect(controller.slots[0].config?.id, TowerLibrary.redPrism.id);
    expect(controller.slots[0].config?.affinity, PrototypeAffinity.ember);
    expect(controller.sparks, 51);
  });

  test('core break ends run and awards persistent Nova Shards', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(6);

    expect(controller.endLayer1RunFromCoreBreak(), isTrue);
    expect(controller.layerRunState.active, isFalse);
    expect(controller.layer1PersistentUpgradeWindowVisible, isTrue);
    expect(
      controller.starBolts,
      5 * LightcoreController.layer1StarBoltsPerCompletedWave,
    );

    expect(
      controller.buyPersistentUpgrade(LayerPersistentUpgradeType.feederSlots),
      isTrue,
    );
  });

  test('active Layer 1 tower health does not recover during a run', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugApplyLumenHarvestDamage(35);
    final damagedStability = controller.coreState.coreStability;

    controller.debugAdvanceLumenHarvestRecovery(120);

    expect(controller.layerRunState.active, isTrue);
    expect(controller.coreState.coreStability, damagedStability);
  });

  test('unupgraded Layer 1 run collapses before Wave 3', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.startLayer1Run();
    _advanceLayer1Run(
      controller,
      until: () => !controller.layerRunState.active,
      maxSeconds: 160,
    );

    expect(controller.layerRunState.active, isFalse);
    expect(controller.layerRunState.wave, lessThanOrEqualTo(2));
  });

  test('early Sparks upgrades push a Layer 1 run past the first wall', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    controller.startLayer1Run();
    expect(controller.buyRunUpgrade(LayerRunUpgradeType.damage), isTrue);
    expect(controller.buyRunUpgrade(LayerRunUpgradeType.fireRate), isTrue);
    expect(controller.buyRunUpgrade(LayerRunUpgradeType.multishot), isTrue);

    _advanceLayer1Run(
      controller,
      until: () =>
          !controller.layerRunState.active ||
          controller.layerRunState.completedWave >= 2,
      maxSeconds: 160,
    );

    expect(controller.layerRunState.completedWave, greaterThanOrEqualTo(2));
  });

  test('persistent Nova Shard upgrades are blocked during active runs', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(6);
    expect(controller.endLayer1RunFromCoreBreak(), isTrue);
    expect(controller.starBolts, greaterThan(0));

    controller.startLayer1Run();

    expect(controller.layerRunState.active, isTrue);
    expect(
      controller.canBuyPersistentUpgrade(
        LayerPersistentUpgradeType.feederSlots,
      ),
      isFalse,
    );
    expect(
      controller.buyPersistentUpgrade(LayerPersistentUpgradeType.feederSlots),
      isFalse,
    );
  });

  test('Wave 10 plus six feeders can be manually completed into Layer 2', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(10);
    expect(controller.layer1Wave10Ready, isTrue);
    expect(controller.layer1CanCompleteShell, isFalse);
    expect(controller.claimCompletedLayer1Shell(), isFalse);

    controller.debugSetLayer1SparksForTest(1000);
    for (var index = 0; index < LightcoreController.slotCount; index += 1) {
      expect(
        controller.buildLayer1FeederAt(index, config: TowerLibrary.greenPrism),
        isTrue,
      );
    }

    expect(controller.layer1ShellCoverageLabel, '7/7 hexes');
    expect(controller.layer1CanCompleteShell, isTrue);
    expect(controller.claimCompletedLayer1Shell(), isTrue);
    controller.debugSetLayer1WaveForTest(10);

    expect(controller.layerRunState.shellReady, isTrue);
    expect(controller.layer2BaseBoard.filledSlotCount, 1);
    expect(controller.layer2BaseBoard.storage, isEmpty);
    expect(controller.starBolts, LightcoreController.layer1CompletionStarBolts);

    final shell = controller.layer2BaseBoard.slots.first!;
    expect(shell.feederAffinities, hasLength(LightcoreController.slotCount));
    expect(
      shell.colorDistribution[PrototypeAffinity.neutral],
      closeTo(1 / 7, 0.0001),
    );
    expect(
      shell.colorDistribution[PrototypeAffinity.verdant],
      closeTo(6 / 7, 0.0001),
    );
  });

  test('completed shells go to storage when Layer 2 board is full', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    for (var index = 0; index < 8; index += 1) {
      _completeFullLayer1Shell(controller);
    }

    expect(controller.layer2BaseBoard.filledSlotCount, 7);
    expect(controller.layer2BaseBoard.storage, hasLength(1));
    expect(controller.layerRunState.active, isFalse);

    controller.startLayer1Run();
    expect(controller.layerRunState.active, isTrue);
    expect(controller.layer2BaseBoard.filledSlotCount, 7);
  });

  test('Nova Shards and Layer 2 board survive controller restore', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(10);
    controller.debugSetLayer1SparksForTest(1000);
    for (var index = 0; index < LightcoreController.slotCount; index += 1) {
      expect(
        controller.buildLayer1FeederAt(index, config: TowerLibrary.greenPrism),
        isTrue,
      );
    }
    expect(controller.claimCompletedLayer1Shell(), isTrue);

    final payload = controller.buildCloudSavePayload();
    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    expect(restored.starBolts, LightcoreController.layer1CompletionStarBolts);
    expect(restored.layerPersistentProgress.bestWave, 10);
    expect(restored.layer2BaseBoard.filledSlotCount, 1);
  });
}

void _completeFullLayer1Shell(LightcoreController controller) {
  controller.startLayer1Run();
  controller.debugSetLayer1WaveForTest(10);
  controller.debugSetLayer1SparksForTest(1000);
  for (var index = 0; index < LightcoreController.slotCount; index += 1) {
    if (!controller.slots[index].isBuilt) {
      expect(
        controller.buildLayer1FeederAt(index, config: TowerLibrary.greenPrism),
        isTrue,
      );
    }
  }
  expect(controller.layer1CanCompleteShell, isTrue);
  expect(controller.claimCompletedLayer1Shell(), isTrue);
}

void _advanceLayer1Run(
  LightcoreController controller, {
  required bool Function() until,
  double maxSeconds = 120,
  double dt = 0.2,
}) {
  final steps = (maxSeconds / dt).ceil();
  for (var index = 0; index < steps; index += 1) {
    if (until()) {
      return;
    }
    controller.tick(dt);
  }
  fail(
    'Layer 1 run did not reach expected state after ${maxSeconds.toStringAsFixed(1)}s. '
    'wave=${controller.layerRunState.wave}, completed=${controller.layerRunState.completedWave}, '
    'active=${controller.layerRunState.active}, core=${controller.coreState.coreStability.round()}',
  );
}
