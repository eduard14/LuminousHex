import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
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

void _feedTowerPayload(LightcoreController controller, int slotIndex) {
  final previousFireSequence = controller.slots[slotIndex].fireSequence;
  for (
    var step = 0;
    step < 600 &&
        controller.slots[slotIndex].fireSequence <= previousFireSequence;
    step += 1
  ) {
    controller.tick(0.05);
  }
  expect(
    controller.slots[slotIndex].fireSequence,
    greaterThan(previousFireSequence),
  );
  if (controller.pulses.isNotEmpty) {
    expect(controller.boostPulseToCore(controller.pulses.last.id), isTrue);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('impact shots lead fast spiral targets before impact', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.orangePrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    _feedTowerPayload(controller, 0);

    final fastSpiral = EnemyLibrary.byRarity[EnemyCardRarity.legendary]!
        .firstWhere((enemy) => enemy.affinity == PrototypeAffinity.flare);
    final target = controller.debugSpawnEnemyFromCard(
      fastSpiral.id,
      angle: 0.2,
      radius: 240,
    );

    expect(target, isNotNull);
    final initialHealth = target!.health;

    _tickUntil(
      controller,
      () => controller.shots.any(
        (shot) => shot.projectileType == ProjectileType.heavyShot,
      ),
    );

    final shot = controller.shots.singleWhere(
      (shot) => shot.projectileType == ProjectileType.heavyShot,
    );
    final targetAtFire = controller.enemies.singleWhere(
      (enemy) => enemy.id == target.id,
    );
    expect(shot.aimAngle, greaterThan(targetAtFire.angle));
    expect(shot.travelRadius, lessThan(targetAtFire.radius));

    for (var step = 0; step < 14; step++) {
      controller.tick(0.05);
      final liveTarget = controller.enemies.where(
        (enemy) => enemy.id == target.id,
      );
      if (liveTarget.isEmpty || liveTarget.single.health < initialHealth) {
        break;
      }
    }

    final remainingTarget = controller.enemies.where(
      (enemy) => enemy.id == target.id,
    );
    expect(
      remainingTarget.isEmpty || remainingTarget.single.health < initialHealth,
      isTrue,
    );
  });

  test('orange heavy shots advance at a deliberate travel speed', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.orangePrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    _feedTowerPayload(controller, 0);
    expect(
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 220,
      ),
      isNotNull,
    );

    _tickUntil(
      controller,
      () => controller.shots.any(
        (shot) => shot.projectileType == ProjectileType.heavyShot,
      ),
    );

    final shot = controller.shots.singleWhere(
      (shot) => shot.projectileType == ProjectileType.heavyShot,
    );
    final shotId = shot.id;
    expect(shot.progress, 0);

    controller.tick(0.05);

    final advancedShot = controller.shots.singleWhere(
      (shot) => shot.id == shotId,
    );
    expect(advancedShot.progress, closeTo(0.084375, 0.0001));
  });
}
