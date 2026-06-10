import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('new Layer 1 run resets Sparks and run upgrades only', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    expect(controller.layerRunState.wave, 1);
    expect(controller.layerRunState.active, isTrue);
    expect(controller.sparks, LightcoreController.layer1BaseStartingSparks);

    expect(controller.buyRunUpgrade(LayerRunUpgradeType.damage), isTrue);
    expect(controller.layerRunState.rankFor(LayerRunUpgradeType.damage), 1);
    expect(controller.coreState.level, 2);

    controller.resetLayer1Run();
    expect(controller.layerRunState.active, isFalse);
    expect(controller.layerRunState.rankFor(LayerRunUpgradeType.damage), 0);
    expect(controller.sparks, LightcoreController.layer1BaseStartingSparks);
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

  test('core break ends run and awards persistent Star Bolts', () {
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

  test('persistent Star Bolt upgrades are blocked during active runs', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(10);
    expect(controller.starBolts, LightcoreController.layer1CompletionStarBolts);

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

  test(
    'Wave 10 creates one shell and auto-installs into first Layer 2 slot',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.startLayer1Run();
      expect(controller.buildNextLayer1Feeder(), isTrue);
      controller.debugSetLayer1WaveForTest(10);
      controller.debugSetLayer1WaveForTest(10);

      expect(controller.layerRunState.shellReady, isTrue);
      expect(controller.layer2BaseBoard.filledSlotCount, 1);
      expect(controller.layer2BaseBoard.storage, isEmpty);
      expect(
        controller.starBolts,
        LightcoreController.layer1CompletionStarBolts,
      );

      final shell = controller.layer2BaseBoard.slots.first!;
      expect(shell.feederAffinities, hasLength(LightcoreController.slotCount));
      expect(
        shell.colorDistribution[PrototypeAffinity.neutral],
        closeTo(6 / 7, 0.0001),
      );
      expect(
        shell.colorDistribution[PrototypeAffinity.verdant],
        closeTo(1 / 7, 0.0001),
      );
    },
  );

  test('completed shells go to storage when Layer 2 board is full', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    for (var index = 0; index < 8; index += 1) {
      controller.startLayer1Run();
      controller.debugSetLayer1WaveForTest(10);
    }

    expect(controller.layer2BaseBoard.filledSlotCount, 7);
    expect(controller.layer2BaseBoard.storage, hasLength(1));
    expect(controller.layerRunState.active, isFalse);

    controller.startLayer1Run();
    expect(controller.layerRunState.active, isTrue);
    expect(controller.layer2BaseBoard.filledSlotCount, 7);
  });

  test('Star Bolts and Layer 2 board survive controller restore', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    controller.debugSetLayer1WaveForTest(10);

    final payload = controller.buildCloudSavePayload();
    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    expect(restored.starBolts, LightcoreController.layer1CompletionStarBolts);
    expect(restored.layerPersistentProgress.bestWave, 10);
    expect(restored.layer2BaseBoard.filledSlotCount, 1);
  });
}
