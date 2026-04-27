import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _tickUntil(
  LightcoreController controller,
  bool Function() condition, {
  int steps = 60,
  double dt = 0.05,
}) {
  for (var step = 0; step < steps && !condition(); step++) {
    controller.tick(dt);
  }
}

void main() {
  test('core multi-shot upgrade increases volley count up to its cap', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 100000;

    expect(controller.coreMultiShotCount, 1);
    expect(controller.coreMultiShotLabel, '1x');
    expect(controller.canUpgradeCoreMultiShot, isTrue);

    while (controller.canUpgradeCoreMultiShot) {
      expect(controller.upgradeCoreMultiShot(), isTrue);
    }

    expect(
      controller.coreState.multiShotUpgradeLevel,
      LightcoreController.maxCoreMultiShotUpgradeLevel,
    );
    expect(controller.coreMultiShotCount, 4);
    expect(controller.coreMultiShotLabel, '4x');
    expect(controller.canUpgradeCoreMultiShot, isFalse);
    expect(controller.upgradeCoreMultiShot(), isFalse);
  });

  test('core multi-shot spreads queued packets across distinct targets', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 100000;
    expect(controller.upgradeCoreMultiShot(), isTrue);
    expect(controller.upgradeCoreMultiShot(), isTrue);
    expect(controller.coreMultiShotCount, 3);

    controller.selectCenter();
    for (var index = 0; index < controller.coreMultiShotCount; index++) {
      controller.handleBattleCenterTap();
    }

    expect(controller.pulses, hasLength(3));
    expect(controller.queuedCorePackets, 0);
    _tickUntil(controller, () => controller.queuedCorePackets == 3);

    for (var index = 0; index < controller.coreMultiShotCount; index++) {
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: index * 0.15,
        radius: 220 + (index * 8),
      );
    }
    controller.tick(0.05);

    expect(controller.shots, hasLength(3));
    expect(controller.queuedCorePackets, 0);
    expect(controller.coreState.fireSequence, 3);
    expect(controller.coreState.fireCooldownRemaining, greaterThan(0));
    expect(controller.enemyCount, greaterThan(0));
  });

  test(
    'core multi-shot keeps queued packets when only one target is available',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.lumens = 100000;
      expect(controller.upgradeCoreMultiShot(), isTrue);
      expect(controller.upgradeCoreMultiShot(), isTrue);
      expect(controller.coreMultiShotCount, 3);

      controller.selectCenter();
      for (var index = 0; index < controller.coreMultiShotCount; index++) {
        controller.handleBattleCenterTap();
      }

      expect(controller.pulses, hasLength(3));
      expect(controller.queuedCorePackets, 0);
      _tickUntil(controller, () => controller.queuedCorePackets == 3);

      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 220,
      );
      controller.tick(0.05);

      expect(controller.shots, hasLength(1));
      expect(controller.queuedCorePackets, 2);
      expect(controller.coreState.fireCooldownRemaining, greaterThan(0));
    },
  );
}
