import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

double _healthForEnemy(LightcoreController controller, String enemyId) {
  return controller.enemies.firstWhere((enemy) => enemy.id == enemyId).health;
}

double _radiusForEnemy(LightcoreController controller, String enemyId) {
  return controller.enemies.firstWhere((enemy) => enemy.id == enemyId).radius;
}

bool _enemyMissingOrDamaged(
  LightcoreController controller,
  String enemyId,
  double initialHealth,
) {
  final enemy = controller.enemies.where((enemy) => enemy.id == enemyId);
  if (enemy.isEmpty) {
    return true;
  }
  return enemy.first.health < initialHealth;
}

double _damageTaken(
  LightcoreController controller,
  String enemyId,
  double initialHealth,
) {
  final enemy = controller.enemies.where((enemy) => enemy.id == enemyId);
  if (enemy.isEmpty) {
    return initialHealth;
  }
  return initialHealth - enemy.first.health;
}

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pulse ring expands from the tower center and hits enemies off-angle',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.lumens = 1000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
      expect(controller.buildTowerAt(0, TowerLibrary.purplePrism), isTrue);
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
      expect(controller.activateTowerSlot(0, showBanner: false), isTrue);

      final frontEnemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0.15,
        radius: 220,
      );
      final flankEnemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 1.8,
        radius: 220,
      );

      expect(frontEnemy, isNotNull);
      expect(flankEnemy, isNotNull);

      final initialFrontHealth = _healthForEnemy(controller, frontEnemy!.id);
      final initialFlankHealth = _healthForEnemy(controller, flankEnemy!.id);

      _tickUntil(controller, () => controller.shots.isNotEmpty);
      expect(controller.shots, isNotEmpty);

      _tickUntil(
        controller,
        () =>
            _enemyMissingOrDamaged(
              controller,
              frontEnemy.id,
              initialFrontHealth,
            ) &&
            _enemyMissingOrDamaged(
              controller,
              flankEnemy.id,
              initialFlankHealth,
            ),
      );

      expect(
        _enemyMissingOrDamaged(controller, frontEnemy.id, initialFrontHealth),
        isTrue,
      );
      expect(
        _enemyMissingOrDamaged(controller, flankEnemy.id, initialFlankHealth),
        isTrue,
      );
    },
  );

  test('green shield halo is passive, stackable, and skips generation', () {
    final single = LightcoreController(traitRandom: Random(3));
    addTearDown(single.dispose);

    single.lumens = 1000;
    single.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(single.buildTowerAt(0, TowerLibrary.greenPrism), isTrue);
    expect(single.towerLiveChargeRate(single.slots[0]), 0);
    expect(single.towerGenerationLabel(single.slots[0]), 'Persistent');
    expect(single.debugSetTowerCharge(0, charge: 1.2), isTrue);
    expect(single.activateTowerSlot(0, showBanner: false), isFalse);
    expect(single.pulses, isEmpty);

    final singleRadius = single.towerShieldRingRadius(single.slots[0]);
    expect(singleRadius, closeTo(single.relayImpactRadius + 20, 0.001));
    expect(
      singleRadius,
      closeTo(single.towerEffectiveRange(single.slots[0]), 0.001),
    );
    final singleEnemy = single.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.1,
      radius: singleRadius,
    );
    final farEnemy = single.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.5,
      radius: singleRadius + 80,
    );
    expect(singleEnemy, isNotNull);
    expect(farEnemy, isNotNull);
    final initialSingleHealth = _healthForEnemy(single, singleEnemy!.id);
    final initialFarHealth = _healthForEnemy(single, farEnemy!.id);

    single.tick(1.0);

    final singleDamage = _damageTaken(
      single,
      singleEnemy.id,
      initialSingleHealth,
    );
    expect(singleDamage, greaterThan(0));
    expect(_damageTaken(single, farEnemy.id, initialFarHealth), 0);
    expect(single.pulses, isEmpty);
    expect(single.queuedAmmoPackets, isEmpty);
    expect(single.shots, isEmpty);

    final stacked = LightcoreController(traitRandom: Random(3));
    addTearDown(stacked.dispose);

    stacked.lumens = 1000;
    stacked.kills = LightcoreController.unlockKillsForOuterSlot(1);
    expect(stacked.buildTowerAt(0, TowerLibrary.greenPrism), isTrue);
    expect(stacked.buildTowerAt(1, TowerLibrary.greenPrism), isTrue);

    final stackedRadius =
        (stacked.towerShieldRingRadius(stacked.slots[0]) +
            stacked.towerShieldRingRadius(stacked.slots[1])) /
        2;
    final stackedEnemy = stacked.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 1.35,
      radius: stackedRadius,
    );
    expect(stackedEnemy, isNotNull);
    final initialStackedHealth = _healthForEnemy(stacked, stackedEnemy!.id);

    stacked.tick(1.0);

    final stackedDamage = _damageTaken(
      stacked,
      stackedEnemy.id,
      initialStackedHealth,
    );
    expect(stackedDamage, greaterThan(singleDamage * 1.35));
    expect(stacked.pulses, isEmpty);
    expect(stacked.queuedAmmoPackets, isEmpty);
    expect(stacked.shots, isEmpty);
  });

  test('blue tower focus laser damages its locked target', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.bluePrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    expect(controller.activateTowerSlot(0, showBanner: false), isTrue);

    final frontEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.0,
      radius: 180,
    );
    final flankEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.35,
      radius: 200,
    );

    expect(frontEnemy, isNotNull);
    expect(flankEnemy, isNotNull);

    final initialFrontHealth = _healthForEnemy(controller, frontEnemy!.id);
    final initialFlankHealth = _healthForEnemy(controller, flankEnemy!.id);

    _tickUntil(controller, () => controller.shots.isNotEmpty, steps: 80);
    expect(controller.shots, isNotEmpty);

    controller.tick(0.01);

    expect(
      _enemyMissingOrDamaged(controller, frontEnemy.id, initialFrontHealth),
      isTrue,
    );
    expect(_healthForEnemy(controller, flankEnemy.id), initialFlankHealth);
  });

  test('chain arc briefly freezes the struck target while the zap lingers', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.yellowPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    expect(controller.activateTowerSlot(0, showBanner: false), isTrue);

    final target = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.18,
      radius: 188,
      level: 16,
    );

    expect(target, isNotNull);

    var radiusBeforeZap = _radiusForEnemy(controller, target!.id);
    var zappedRadius = radiusBeforeZap;
    var shockRemaining = 0.0;
    var slowRemaining = 0.0;
    for (var step = 0; step < 80 && shockRemaining <= 0; step++) {
      radiusBeforeZap = _radiusForEnemy(controller, target.id);
      controller.tick(0.05);
      final zappedTarget = controller.enemies.firstWhere(
        (enemy) => enemy.id == target.id,
      );
      shockRemaining = zappedTarget.shockRemaining;
      slowRemaining = zappedTarget.slowRemaining;
      zappedRadius = zappedTarget.radius;
    }

    expect(shockRemaining, greaterThan(0));
    expect(slowRemaining, greaterThan(0));
    expect(zappedRadius, closeTo(radiusBeforeZap, 0.08));
  });

  test('chain arc jumps to the enemy nearest the struck target', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.yellowPrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    expect(controller.activateTowerSlot(0, showBanner: false), isTrue);

    final primaryTarget = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.2,
      radius: 180,
      level: 10,
    );
    final centerCloserButFartherFromPrimary = controller
        .debugSpawnEnemyFromCard(
          EnemyLibrary.basicWhite.id,
          angle: 2.6,
          radius: 188,
          level: 10,
        );
    final fartherFromCenterButCloserToPrimary = controller
        .debugSpawnEnemyFromCard(
          EnemyLibrary.basicWhite.id,
          angle: 0.6,
          radius: 240,
          level: 10,
        );

    expect(primaryTarget, isNotNull);
    expect(centerCloserButFartherFromPrimary, isNotNull);
    expect(fartherFromCenterButCloserToPrimary, isNotNull);

    final initialPrimaryHealth = _healthForEnemy(controller, primaryTarget!.id);
    final initialCenterCloserHealth = _healthForEnemy(
      controller,
      centerCloserButFartherFromPrimary!.id,
    );
    final initialNearbyHealth = _healthForEnemy(
      controller,
      fartherFromCenterButCloserToPrimary!.id,
    );

    _tickUntil(
      controller,
      () => controller.shots.any(
        (shot) =>
            shot.projectileType ==
            TowerLibrary.yellowPrism.defaultProjectileType,
      ),
    );
    expect(
      controller.shots.any(
        (shot) =>
            shot.projectileType ==
            TowerLibrary.yellowPrism.defaultProjectileType,
      ),
      isTrue,
    );

    _tickUntil(
      controller,
      () =>
          _healthForEnemy(controller, primaryTarget.id) <
              initialPrimaryHealth &&
          _healthForEnemy(controller, fartherFromCenterButCloserToPrimary.id) <
              initialNearbyHealth,
    );

    expect(
      _healthForEnemy(controller, primaryTarget.id),
      lessThan(initialPrimaryHealth),
    );
    expect(
      _healthForEnemy(controller, fartherFromCenterButCloserToPrimary.id),
      lessThan(initialNearbyHealth),
    );
    expect(
      _healthForEnemy(controller, centerCloserButFartherFromPrimary.id),
      closeTo(initialCenterCloserHealth, 0.0001),
    );
    final linkedChainImpacts = controller.impacts.where(
      (impact) =>
          impact.projectileType ==
              TowerLibrary.yellowPrism.defaultProjectileType &&
          impact.hasChainSource,
    );
    expect(linkedChainImpacts, isNotEmpty);
    final linkedImpact = linkedChainImpacts.first;
    expect(linkedImpact.chainSourceAngle, isNotNull);
    expect(linkedImpact.chainSourceRadius, isNotNull);
    expect(
      (linkedImpact.chainSourceRadius! - linkedImpact.radius).abs(),
      greaterThan(1),
    );

    final linkedImpactId = linkedImpact.id;
    controller.tick(0.38);
    expect(
      controller.impacts.any((impact) => impact.id == linkedImpactId),
      isTrue,
    );

    controller.tick(0.32);
    expect(
      controller.impacts.any((impact) => impact.id == linkedImpactId),
      isFalse,
    );
  });

  test(
    'lethal chain arc still jumps to the nearest struck-target neighbor',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.lumens = 1000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
      expect(controller.buildTowerAt(0, TowerLibrary.yellowPrism), isTrue);

      final primaryTarget = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0.2,
        radius: 180,
        level: 1,
      );
      final centerCloserButFartherFromPrimary = controller
          .debugSpawnEnemyFromCard(
            EnemyLibrary.basicWhite.id,
            angle: 2.6,
            radius: 188,
            level: 10,
          );
      final fartherFromCenterButCloserToPrimary = controller
          .debugSpawnEnemyFromCard(
            EnemyLibrary.basicWhite.id,
            angle: 0.6,
            radius: 240,
            level: 10,
          );

      expect(primaryTarget, isNotNull);
      expect(centerCloserButFartherFromPrimary, isNotNull);
      expect(fartherFromCenterButCloserToPrimary, isNotNull);

      final initialCenterCloserHealth = _healthForEnemy(
        controller,
        centerCloserButFartherFromPrimary!.id,
      );
      final initialNearbyHealth = _healthForEnemy(
        controller,
        fartherFromCenterButCloserToPrimary!.id,
      );

      controller.debugSetAmmoQueue(const [
        AmmoPacket(
          id: 'test_lethal_chain_arc',
          sourceSlotIndex: 0,
          affinity: PrototypeAffinity.solar,
          power: 40,
          advantageMultiplier: 1,
          projectileType: ProjectileType.chainArc,
          payloadType: PayloadType.none,
          targetPriority: TargetPriority.close,
          range: 320,
          critChance: 0,
          critMultiplier: 1,
          finalDamageMultiplier: 1,
          bossDamageMultiplier: 1,
          normalDamageMultiplier: 1,
          defensePenetration: 0,
          minDamageMultiplier: 1,
          maxDamageMultiplier: 1,
        ),
      ]);

      _tickUntil(
        controller,
        () =>
            controller.enemies.every(
              (enemy) => enemy.id != primaryTarget!.id,
            ) &&
            _enemyMissingOrDamaged(
              controller,
              fartherFromCenterButCloserToPrimary.id,
              initialNearbyHealth,
            ),
        steps: 80,
      );

      expect(
        controller.enemies.every((enemy) => enemy.id != primaryTarget!.id),
        isTrue,
      );
      expect(
        _enemyMissingOrDamaged(
          controller,
          fartherFromCenterButCloserToPrimary.id,
          initialNearbyHealth,
        ),
        isTrue,
      );
      expect(
        _healthForEnemy(controller, centerCloserButFartherFromPrimary.id),
        closeTo(initialCenterCloserHealth, 0.0001),
      );

      final linkedChainImpacts = controller.impacts.where(
        (impact) =>
            impact.projectileType == ProjectileType.chainArc &&
            impact.hasChainSource,
      );
      expect(linkedChainImpacts, isNotEmpty);
      expect(linkedChainImpacts.first.chainSourceAngle, isNotNull);
      expect(linkedChainImpacts.first.chainSourceRadius, isNotNull);
    },
  );
}
