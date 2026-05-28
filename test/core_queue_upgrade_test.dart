import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _buildMaxedBluePrism(LightcoreController controller) {
  controller.lumens = 100000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(0);

  expect(controller.buildTowerAt(0, TowerLibrary.bluePrism), isTrue);
  while (controller.slots[0].level < LightcoreController.maxTowerLevel) {
    expect(controller.upgradeTower(0), isTrue);
  }
}

AmmoPacket _dummyAmmoPacket(int id) {
  return AmmoPacket(
    id: 'test_packet_$id',
    sourceSlotIndex: 0,
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
  );
}

AmmoPacket _coreBombPacket() {
  return const AmmoPacket(
    id: 'test_core_bomb',
    sourceSlotIndex: null,
    affinity: PrototypeAffinity.ember,
    power: 12,
    advantageMultiplier: 1,
    projectileType: ProjectileType.coreBomb,
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
  );
}

AmmoPacket _redTowerBombPacket() {
  return const AmmoPacket(
    id: 'test_red_tower_bomb',
    sourceSlotIndex: 0,
    affinity: PrototypeAffinity.ember,
    power: 18,
    advantageMultiplier: 1,
    projectileType: ProjectileType.coreBomb,
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
  );
}

void _fillQueue(LightcoreController controller, int count) {
  controller.debugSetAmmoQueue(
    List<AmmoPacket>.generate(count, _dummyAmmoPacket),
  );
}

double _healthForEnemy(LightcoreController controller, String enemyId) {
  return controller.enemies.firstWhere((enemy) => enemy.id == enemyId).health;
}

void _tickUntil(
  LightcoreController controller,
  bool Function() condition, {
  int steps = 40,
  double dt = 0.05,
}) {
  for (var step = 0; step < steps && !condition(); step++) {
    controller.tick(dt);
  }
}

void _tickThroughCoreBombSweep(LightcoreController controller) {
  for (var step = 0; step < 20 && controller.shots.isNotEmpty; step++) {
    controller.tick(0.05);
  }
  for (
    var step = 0;
    step < 8 &&
        controller.impacts.any(
          (impact) => impact.projectileType == ProjectileType.coreBomb,
        );
    step++
  ) {
    controller.tick(0.05);
  }
}

void main() {
  test('starter core manually queues and fires basic shots', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    expect(controller.coreState.affinity, PrototypeAffinity.neutral);
    expect(controller.coreState.projectileType, ProjectileType.starBolt);
    expect(controller.corePayloadLabel, 'No Payload');

    controller.selectCenter();
    controller.handleBattleCenterTap();

    expect(controller.queuedCorePackets, 1);
    final packet = controller.queuedAmmoPackets.single;
    expect(packet.sourceSlotIndex, isNull);
    expect(packet.affinity, PrototypeAffinity.neutral);
    expect(packet.projectileType, ProjectileType.starBolt);

    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
    );
    expect(enemy, isNotNull);
    expect(controller.fireQueuedCorePacketAtEnemy(enemy!.id), isTrue);

    expect(controller.queuedCorePackets, 0);
    final shot = controller.shots.single;
    expect(shot.sourceSlotIndex, isNull);
    expect(shot.affinity, PrototypeAffinity.neutral);
    expect(shot.projectileType, ProjectileType.starBolt);
  });

  test('layer 1 manual core tap counts as queue occupancy immediately', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    expect(controller.activeLayer.tier, 1);
    expect(controller.coreQueueLoadLabel, '0/${controller.coreQueueCapacity}');

    controller.selectCenter();
    controller.handleBattleCenterTap();

    expect(controller.queuedCorePackets, 1);
    expect(controller.pulses, isEmpty);
    expect(controller.coreQueueOccupancy, 1);
    expect(controller.coreQueueLoadLabel, '1/${controller.coreQueueCapacity}');
  });

  test('layer 1 core waits for manual generation before queueing', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    for (var step = 0; step < 60; step += 1) {
      controller.tick(0.1);
    }

    expect(
      controller.pulses.where((pulse) => pulse.sourceSlotIndex == null).length,
      0,
    );
    expect(controller.queuedCorePackets, 0);
  });

  test('core queue upgrade raises queue capacity and spends lumens', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    final initialLumens = controller.lumens;
    final upgradeCost = controller.coreQueueUpgradeCost;

    expect(
      controller.coreQueueCapacity,
      LightcoreController.baseCoreQueueCapacity,
    );
    expect(controller.canUpgradeCoreQueueLimit, isTrue);
    expect(upgradeCost, greaterThan(0));

    expect(controller.upgradeCoreQueueLimit(), isTrue);

    expect(
      controller.coreQueueCapacity,
      LightcoreController.baseCoreQueueCapacity +
          LightcoreController.coreQueueCapacityUpgradeStep,
    );
    expect(controller.lumens, initialLumens - upgradeCost);
  });

  test(
    'full queue holds payloads in flight until the queue limit is upgraded',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();

      _buildMaxedBluePrism(controller);
      controller.rebootEncounter(showBanner: false);

      final baseCapacity = controller.coreQueueCapacity;
      _fillQueue(controller, baseCapacity);
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
      expect(
        controller.activateTowerSlot(
          0,
          showBanner: false,
          selectForStats: false,
        ),
        isTrue,
      );

      _tickUntil(controller, () => controller.pulses.isNotEmpty, steps: 600);

      expect(controller.queuedCorePackets, greaterThan(0));

      controller.lumens = 1000;
      expect(controller.upgradeCoreQueueLimit(), isTrue);
      controller.rebootEncounter(showBanner: false);

      _fillQueue(controller, baseCapacity);
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
      expect(
        controller.activateTowerSlot(
          0,
          showBanner: false,
          selectForStats: false,
        ),
        isTrue,
      );

      _tickUntil(
        controller,
        () => controller.queuedCorePackets > 0,
        steps: 600,
      );

      expect(controller.queuedCorePackets, greaterThan(0));
      expect(
        controller.queuedCorePackets,
        lessThanOrEqualTo(controller.coreQueueCapacity),
      );
    },
  );

  test(
    'manual core feed generates a basic packet before the core fires it',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();

      final enemy = controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 220,
      );
      expect(enemy, isNotNull);

      expect(controller.queuedCorePackets, 0);
      expect(controller.shots, isEmpty);

      controller.selectCenter();
      controller.handleBattleCenterTap();
      expect(controller.fireQueuedCorePacketAtEnemy(enemy!.id), isTrue);

      expect(controller.queuedCorePackets, 0);
      expect(controller.shots, hasLength(1));
      expect(controller.shots.single.sourceSlotIndex, isNull);
    },
  );

  test('tapping an enemy manually fires a queued core packet', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
    );
    expect(enemy, isNotNull);
    controller.debugSetAmmoQueue([_dummyAmmoPacket(1)]);

    expect(controller.fireQueuedCorePacketAtEnemy(enemy!.id), isTrue);

    expect(controller.queuedCorePackets, 0);
    expect(controller.shots, hasLength(1));
    expect(controller.shots.single.enemyId, enemy.id);
  });

  test('queued core basic impacts one enemy instead of piercing a pack', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    final firstEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
      level: 16,
    );
    final secondEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.01,
      radius: 220,
      level: 16,
    );
    expect(firstEnemy, isNotNull);
    expect(secondEnemy, isNotNull);

    final initialFirstHealth = _healthForEnemy(controller, firstEnemy!.id);
    final initialSecondHealth = _healthForEnemy(controller, secondEnemy!.id);

    controller.selectCenter();
    controller.handleBattleCenterTap();
    expect(controller.fireQueuedCorePacketAtEnemy(firstEnemy.id), isTrue);
    for (var step = 0; step < 20 && controller.shots.isNotEmpty; step++) {
      controller.tick(0.05);
    }

    final damagedCount = <bool>[
      _healthForEnemy(controller, firstEnemy.id) < initialFirstHealth,
      _healthForEnemy(controller, secondEnemy.id) < initialSecondHealth,
    ].where((damaged) => damaged).length;

    expect(damagedCount, 1);
  });

  test('queued core bomb damages enemies inside its blast radius', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final firstEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
      level: 16,
    );
    final secondEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.12,
      radius: 220,
      level: 16,
    );
    final edgeEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.295,
      radius: 220,
      level: 16,
    );
    final visualEdgeEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.72,
      radius: 220,
      level: 16,
    );
    final outsideEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 1.35,
      radius: 220,
      level: 16,
    );
    expect(firstEnemy, isNotNull);
    expect(secondEnemy, isNotNull);
    expect(edgeEnemy, isNotNull);
    expect(visualEdgeEnemy, isNotNull);
    expect(outsideEnemy, isNotNull);

    final initialFirstHealth = _healthForEnemy(controller, firstEnemy!.id);
    final initialSecondHealth = _healthForEnemy(controller, secondEnemy!.id);
    final initialEdgeHealth = _healthForEnemy(controller, edgeEnemy!.id);
    final initialVisualEdgeHealth = _healthForEnemy(
      controller,
      visualEdgeEnemy!.id,
    );
    final initialOutsideHealth = _healthForEnemy(controller, outsideEnemy!.id);

    controller.debugSetAmmoQueue([_coreBombPacket()]);
    expect(controller.fireQueuedCorePacketAtEnemy(firstEnemy.id), isTrue);
    _tickThroughCoreBombSweep(controller);

    expect(
      _healthForEnemy(controller, firstEnemy.id),
      lessThan(initialFirstHealth),
    );
    expect(
      _healthForEnemy(controller, secondEnemy.id),
      lessThan(initialSecondHealth),
    );
    expect(
      _healthForEnemy(controller, edgeEnemy.id),
      lessThan(initialEdgeHealth),
    );
    expect(
      _healthForEnemy(controller, visualEdgeEnemy.id),
      lessThan(initialVisualEdgeHealth),
    );
    expect(_healthForEnemy(controller, outsideEnemy.id), initialOutsideHealth);
  });

  test('red tower bomb splashes nearby enemies when primary target dies', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    final primaryEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 200,
      level: 1,
    );
    final splashEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.12,
      radius: 220,
      level: 16,
    );
    final outsideEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 1.35,
      radius: 220,
      level: 16,
    );
    expect(primaryEnemy, isNotNull);
    expect(splashEnemy, isNotNull);
    expect(outsideEnemy, isNotNull);

    final initialSplashHealth = _healthForEnemy(controller, splashEnemy!.id);
    final initialOutsideHealth = _healthForEnemy(controller, outsideEnemy!.id);

    controller.debugSetAmmoQueue([_redTowerBombPacket()]);
    expect(controller.fireQueuedCorePacketAtEnemy(primaryEnemy!.id), isTrue);
    _tickThroughCoreBombSweep(controller);

    expect(
      controller.enemies.any((enemy) => enemy.id == primaryEnemy.id),
      isFalse,
    );
    expect(
      _healthForEnemy(controller, splashEnemy.id),
      lessThan(initialSplashHealth),
    );
    expect(_healthForEnemy(controller, outsideEnemy.id), initialOutsideHealth);
    expect(
      controller.impacts.any(
        (impact) => impact.projectileType == ProjectileType.coreBomb,
      ),
      isTrue,
    );
  });

  test('red tower bomb splash deals full damage to nearby enemies', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    final primaryEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
      level: 16,
    );
    final splashEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0.12,
      radius: 220,
      level: 16,
    );
    final outsideEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 1.35,
      radius: 220,
      level: 16,
    );
    expect(primaryEnemy, isNotNull);
    expect(splashEnemy, isNotNull);
    expect(outsideEnemy, isNotNull);

    final initialPrimaryHealth = _healthForEnemy(controller, primaryEnemy!.id);
    final initialSplashHealth = _healthForEnemy(controller, splashEnemy!.id);
    final initialOutsideHealth = _healthForEnemy(controller, outsideEnemy!.id);

    controller.debugSetAmmoQueue([_redTowerBombPacket()]);
    expect(controller.fireQueuedCorePacketAtEnemy(primaryEnemy.id), isTrue);
    _tickThroughCoreBombSweep(controller);

    final primaryDamage =
        initialPrimaryHealth - _healthForEnemy(controller, primaryEnemy.id);
    final splashDamage =
        initialSplashHealth - _healthForEnemy(controller, splashEnemy.id);

    expect(primaryDamage, greaterThan(0));
    expect(splashDamage, closeTo(primaryDamage, 0.0001));
    expect(_healthForEnemy(controller, outsideEnemy.id), initialOutsideHealth);
  });

  test('queued core bomb does not damage enemies after its sweep passes', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final target = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
      level: 16,
    );
    expect(target, isNotNull);

    controller.debugSetAmmoQueue([_coreBombPacket()]);
    expect(controller.fireQueuedCorePacketAtEnemy(target!.id), isTrue);
    for (var step = 0; step < 20 && controller.shots.isNotEmpty; step++) {
      controller.tick(0.05);
    }

    final bombImpact = controller.impacts.firstWhere(
      (impact) => impact.projectileType == ProjectileType.coreBomb,
    );
    expect(bombImpact.hasLingeringField, isFalse);
    expect(bombImpact.hasImpactSweep, isTrue);
    final impactAngle = bombImpact.angle;
    final impactRadius = bombImpact.radius;

    for (
      var step = 0;
      step < 8 &&
          controller.impacts.any(
            (impact) => impact.projectileType == ProjectileType.coreBomb,
          );
      step++
    ) {
      controller.tick(0.05);
    }

    final lateEnemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: impactAngle,
      radius: impactRadius,
      level: 16,
    );
    expect(lateEnemy, isNotNull);

    final initialLateHealth = _healthForEnemy(controller, lateEnemy!.id);
    controller.tick(0.2);

    expect(_healthForEnemy(controller, lateEnemy.id), initialLateHealth);
  });
}
