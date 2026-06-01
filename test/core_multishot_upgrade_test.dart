import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
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

void _queueCenterPackets(LightcoreController controller, int count) {
  controller.selectCenter();
  controller.debugSetAmmoQueue([
    for (var index = 0; index < count; index++)
      AmmoPacket(
        id: 'core_multishot_packet_$index',
        sourceSlotIndex: null,
        affinity: PrototypeAffinity.aether,
        power: 12,
        advantageMultiplier: 1,
        projectileType: ProjectileType.lanceBeam,
        payloadType: PayloadType.none,
        targetPriority: TargetPriority.close,
        range: 320,
        critChance: 0.05,
        critMultiplier: 1.5,
        finalDamageMultiplier: 1,
        bossDamageMultiplier: 1,
        normalDamageMultiplier: 1,
        defensePenetration: 0,
        minDamageMultiplier: 1,
        maxDamageMultiplier: 1,
      ),
  ]);
  _tickUntil(controller, () => controller.queuedCorePackets == count);
}

void main() {
  test('core multi-shot upgrade increases volley count up to its cap', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

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

    _queueCenterPackets(controller, controller.coreMultiShotCount);

    expect(controller.pulses, isEmpty);
    expect(controller.queuedCorePackets, 3);

    String? firstEnemyId;
    for (var index = 0; index < controller.coreMultiShotCount; index++) {
      final enemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: index * 0.15,
        radius: 220 + (index * 8),
      );
      firstEnemyId ??= enemy?.id;
    }
    expect(firstEnemyId, isNotNull);
    expect(controller.selectBattleEnemyForManualAim(firstEnemyId!), isTrue);
    controller.tick(0.05);

    expect(controller.shots, hasLength(3));
    expect(controller.queuedCorePackets, 1);
    expect(controller.coreState.fireSequence, 1);
    expect(controller.coreState.fireCooldownRemaining, greaterThan(0));
    expect(controller.enemyCount, greaterThan(0));
  });

  test(
    'core multi-shot keeps queued packets when only one target is available',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();

      controller.lumens = 100000;
      expect(controller.upgradeCoreMultiShot(), isTrue);
      expect(controller.upgradeCoreMultiShot(), isTrue);
      expect(controller.coreMultiShotCount, 3);

      _queueCenterPackets(controller, controller.coreMultiShotCount);

      expect(controller.pulses, isEmpty);
      expect(controller.queuedCorePackets, 3);

      final enemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 220,
      );
      expect(enemy, isNotNull);
      expect(controller.selectBattleEnemyForManualAim(enemy!.id), isTrue);
      controller.tick(0.05);

      expect(controller.shots, hasLength(1));
      expect(controller.queuedCorePackets, 3);
      expect(controller.coreState.fireCooldownRemaining, greaterThan(0));
    },
  );
}
