import 'dart:math';

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
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  expect(controller.isPromotionReady, isTrue);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 2);
}

LightcoreController _buildPassiveHarness() {
  final controller = LightcoreController(traitRandom: Random(9));
  _promoteRootShell(controller);
  expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
  controller.selectCenter();
  controller.lumens = 0;
  return controller;
}

void main() {
  test('manual overdrive ramps battle time and decays after release', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();

    expect(controller.canUseManualOverdrive, isTrue);
    expect(controller.manualOverdriveMultiplier, 1);

    controller.startManualOverdrive();
    controller.tick(1.0);

    expect(controller.manualOverdriveCharge, closeTo(0.7, 0.001));
    expect(controller.manualOverdriveMultiplier, closeTo(1.35, 0.001));
    expect(controller.elapsed, closeTo(0.88125, 0.001));

    controller.stopManualOverdrive();
    controller.tick(1.0);

    expect(controller.manualOverdriveCharge, closeTo(0.25, 0.001));
    expect(controller.elapsed, closeTo(1.809375, 0.001));

    controller.burstManualOverdrive();

    expect(controller.manualOverdriveCharge, closeTo(0.43, 0.001));
  });

  test('manual overdrive leaves passive shell income on real time', () {
    final baseline = _buildPassiveHarness();
    final boosted = _buildPassiveHarness();
    addTearDown(baseline.dispose);
    addTearDown(boosted.dispose);

    boosted.startManualOverdrive();

    baseline.tick(0.5);
    boosted.tick(0.5);

    expect(boosted.lumens, baseline.lumens);
    expect(boosted.elapsed, greaterThan(baseline.elapsed));
  });

  test('permanent overdrive locks battle speed at x1.5', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    controller.unlockPermanentOverdrive();

    expect(controller.hasPermanentOverdrive, isTrue);
    expect(controller.canUseManualOverdrive, isFalse);
    expect(controller.manualOverdriveMultiplier, closeTo(1.5, 0.001));

    controller.startManualOverdrive();
    expect(controller.isManualOverdriveHeld, isFalse);

    controller.tick(1.0);

    expect(controller.manualOverdriveCharge, 0);
    expect(controller.elapsed, closeTo(1.125, 0.001));
  });

  test('normal battle time advances slower than real time', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    controller.tick(1.0);

    expect(controller.manualOverdriveMultiplier, 1);
    expect(controller.elapsed, closeTo(0.75, 0.001));
  });
}
