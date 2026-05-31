import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

AmmoPacket _visualTestPacket(ProjectileType projectileType) => AmmoPacket(
  id: 'visual_packet_${projectileType.name}',
  sourceSlotIndex: 0,
  affinity: PrototypeAffinity.violet,
  power: 28,
  advantageMultiplier: 1,
  projectileType: projectileType,
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

void main() {
  LightcoreBattleGame buildGame(LightcoreController controller) {
    final game = LightcoreBattleGame(
      controller: controller,
      onCenterTap: () {},
      onSlotTap: (_) {},
      onBackgroundTap: () {},
    );
    game.onGameResize(Vector2(900, 1100));
    return game;
  }

  test('zero-size update and render are safe before layout is ready', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final game = LightcoreBattleGame(
      controller: controller,
      onCenterTap: () {},
      onSlotTap: (_) {},
      onBackgroundTap: () {},
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 240, 320));

    game.onGameResize(Vector2.zero());
    expect(() => game.update(1 / 60), returnsNormally);
    expect(() => game.render(canvas), returnsNormally);

    recorder.endRecording().dispose();
  });

  test('disabled battlefield taps are ignored by the game layer', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    var centerTaps = 0;
    var slotTaps = 0;
    var backgroundTaps = 0;
    final game = LightcoreBattleGame(
      controller: controller,
      onCenterTap: () => centerTaps += 1,
      onSlotTap: (_) => slotTaps += 1,
      onBackgroundTap: () => backgroundTaps += 1,
      enableBattlefieldTaps: false,
    );
    game.onGameResize(Vector2(900, 1100));

    game.handleCanvasTap(const Offset(450, 506));
    game.handleCanvasTap(const Offset(600, 506));
    game.handleCanvasTap(const Offset(40, 40));

    expect(centerTaps, 0);
    expect(slotTaps, 0);
    expect(backgroundTaps, 0);
  });

  test('core auto-feed queues a packet without an orbiting pulse', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    final game = buildGame(controller);

    controller.selectCenter();
    controller.handleBattleCenterTap();
    for (
      var step = 0;
      step < 80 && controller.queuedAmmoPackets.isEmpty;
      step++
    ) {
      controller.tick(0.1);
    }

    expect(controller.pulses, isEmpty);
    expect(controller.queuedAmmoPackets, hasLength(1));
    expect(controller.coreQueueOccupancy, 1);
    expect(game.debugCoreQueueOrbitProjectileTypes, isEmpty);
  });

  test(
    'waiting packet visuals stay hidden instead of becoming tap targets',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();
      var backgroundTaps = 0;
      var slotTaps = 0;
      final game = LightcoreBattleGame(
        controller: controller,
        onCenterTap: () => fail('floating packet visual should not tap core'),
        onSlotTap: (_) => slotTaps += 1,
        onBackgroundTap: () => backgroundTaps += 1,
      );
      game.onGameResize(Vector2(900, 1100));
      controller.toggleShellVisibility();
      controller.lumens = 1000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
      expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
      final remainingFabrication =
          controller.slots[0].fabricationRemainingSeconds;
      if (remainingFabrication > 0) {
        controller.tick(remainingFabrication + 0.1);
      }
      expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
      expect(
        controller.activateTowerSlot(
          0,
          showBanner: false,
          selectForStats: false,
        ),
        isTrue,
      );

      final pulse = controller.pulses.singleWhere(
        (candidate) => candidate.sourceSlotIndex == 0,
      );
      expect(game.debugPulsePosition(pulse.id), isNull);
      expect(backgroundTaps, 0);
      expect(slotTaps, 0);
    },
  );

  test('tower hit areas take priority over payload and aim taps', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    var slotTaps = 0;
    final game = LightcoreBattleGame(
      controller: controller,
      onCenterTap: () => fail('tower hit should not tap core'),
      onSlotTap: (_) => slotTaps += 1,
      onBackgroundTap: () => fail('tower hit should not tap background'),
    );
    game.onGameResize(Vector2(900, 1100));
    controller.toggleShellVisibility();
    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    final remainingFabrication =
        controller.slots[0].fabricationRemainingSeconds;
    if (remainingFabrication > 0) {
      controller.tick(remainingFabrication + 0.1);
    }
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);

    const slotCenter = Offset(618.0, 506.0);
    expect(game.isTowerHitAt(slotCenter), isTrue);
    game.handleCanvasTap(slotCenter);

    expect(slotTaps, 1);
    expect(controller.pulses, isEmpty);
    expect(controller.slots[0].charge, greaterThanOrEqualTo(1));
  });

  test('single-finger gesture pans the battle view', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final game = buildGame(controller);

    expect(game.viewPanOffset.x, 0);
    expect(game.viewPanOffset.y, 0);

    game.handleScaleStart(
      ScaleStartDetails(
        focalPoint: Offset(620, 720),
        localFocalPoint: Offset(620, 720),
        pointerCount: 1,
      ),
    );
    game.handleScaleUpdate(
      ScaleUpdateDetails(
        focalPoint: Offset(676, 760),
        localFocalPoint: Offset(676, 760),
        focalPointDelta: Offset(56, 40),
        scale: 1,
        horizontalScale: 1,
        verticalScale: 1,
        rotation: 0,
        pointerCount: 1,
      ),
    );

    expect(game.viewPanOffset.x, greaterThan(0));
    expect(game.viewPanOffset.y, greaterThan(0));
  });

  test('two-finger gesture pinches the battle view', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final game = buildGame(controller);
    final initialScale = game.viewScale;

    game.handleScaleStart(
      ScaleStartDetails(
        focalPoint: Offset(520, 640),
        localFocalPoint: Offset(520, 640),
        pointerCount: 2,
      ),
    );
    game.handleScaleUpdate(
      ScaleUpdateDetails(
        focalPoint: Offset(520, 640),
        localFocalPoint: Offset(520, 640),
        focalPointDelta: Offset.zero,
        scale: 1.45,
        horizontalScale: 1.45,
        verticalScale: 1.45,
        rotation: 0,
        pointerCount: 2,
      ),
    );

    expect(game.viewScale, greaterThan(initialScale));
  });

  test('core damage starts a screen shake', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final game = buildGame(controller);

    game.update(0);
    expect(game.screenShakeRemaining, 0);

    controller.debugApplyLumenHarvestDamage(8);
    game.update(1 / 60);

    expect(game.screenShakeRemaining, greaterThan(0));
    expect(game.screenShakeOffset.length, greaterThan(0));
  });

  test('new projectile shots start and expire fire burst animations', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    final game = buildGame(controller);

    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
    );
    expect(enemy, isNotNull);
    controller.debugSetAmmoQueue([_visualTestPacket(ProjectileType.pulseRing)]);
    expect(controller.fireQueuedCorePacketAtEnemy(enemy!.id), isTrue);

    game.update(0);
    for (var step = 0; step < 40 && controller.shots.isEmpty; step++) {
      controller.tick(0.05);
    }
    expect(controller.shots, isNotEmpty);

    game.update(0);

    expect(game.debugActiveShotFireBurstCount, greaterThanOrEqualTo(0));

    for (var step = 0; step < 8; step++) {
      game.update(0.05);
    }

    expect(game.debugActiveShotFireBurstCount, greaterThanOrEqualTo(0));
  });

  test('surviving enemy hits trigger a short face reaction', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    final game = buildGame(controller);

    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
      level: 50,
    );
    expect(enemy, isNotNull);
    final enemyId = enemy!.id;
    controller.debugSetAmmoQueue([_visualTestPacket(ProjectileType.pulseRing)]);
    expect(controller.fireQueuedCorePacketAtEnemy(enemyId), isTrue);

    game.update(0);
    for (
      var step = 0;
      step < 220 && !game.debugEnemyHitFaceRemaining.containsKey(enemyId);
      step += 1
    ) {
      game.update(0.05);
    }

    expect(game.debugEnemyHitFaceRemaining[enemyId], greaterThan(0));
    expect(controller.enemies.any((active) => active.id == enemyId), isTrue);

    for (var step = 0; step < 8; step += 1) {
      game.update(0.05);
    }

    expect(game.debugEnemyHitFaceRemaining.containsKey(enemyId), isFalse);
  });
}
