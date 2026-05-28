import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

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

  test('core queue orbit waits until inbound pulse lands', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final game = buildGame(controller);

    for (var step = 0; step < 40 && controller.pulses.isEmpty; step += 1) {
      controller.tick(0.05);
    }

    expect(controller.pulses, hasLength(1));
    expect(controller.queuedAmmoPackets, isEmpty);
    expect(controller.coreQueueOccupancy, 0);
    expect(game.debugCoreQueueOrbitProjectileTypes, isEmpty);

    for (
      var step = 0;
      step < 260 && controller.queuedAmmoPackets.isEmpty;
      step += 1
    ) {
      controller.tick(0.05);
    }

    expect(controller.queuedAmmoPackets, hasLength(1));
    expect(game.debugCoreQueueOrbitProjectileTypes, isEmpty);
  });

  test('payload taps quick-load without opening tower placement', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    var backgroundTaps = 0;
    final game = LightcoreBattleGame(
      controller: controller,
      onCenterTap: () => fail('near-missed payload should not tap core'),
      onSlotTap: (_) => fail('near-missed payload should not tap slots'),
      onBackgroundTap: () => backgroundTaps += 1,
    );
    game.onGameResize(Vector2(900, 1100));
    controller.toggleShellVisibility();

    for (var step = 0; step < 40 && controller.pulses.isEmpty; step += 1) {
      controller.tick(0.05);
    }

    final pulse = controller.pulses.single;
    final position = game.debugPulsePosition(pulse.id);
    expect(position, isNotNull);

    game.handleCanvasTap(Offset(position!.x, position.y));

    expect(backgroundTaps, 0);
    expect(controller.pulses.single.progress, 0);
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
    final game = buildGame(controller);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.purplePrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    controller.tick(0.1);
    expect(controller.pulses, isNotEmpty);
    expect(controller.boostPulseToCore(controller.pulses.last.id), isTrue);
    expect(
      controller.debugSpawnEnemyFromCard(
        EnemyLibrary.basicWhite.id,
        angle: 0,
        radius: 220,
      ),
      isNotNull,
    );

    game.update(0);
    for (var step = 0; step < 40 && controller.shots.isEmpty; step++) {
      controller.tick(0.05);
    }
    expect(controller.shots, isNotEmpty);

    game.update(0);

    expect(game.debugActiveShotFireBurstCount, greaterThan(0));
    expect(
      game.debugActiveShotFireBurstTypes,
      contains(ProjectileType.pulseRing),
    );

    for (var step = 0; step < 8; step++) {
      game.update(0.05);
    }

    expect(game.debugActiveShotFireBurstCount, 0);
  });

  test('surviving enemy hits trigger a short face reaction', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final game = buildGame(controller);

    controller.lumens = 1000;
    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    expect(controller.buildTowerAt(0, TowerLibrary.purplePrism), isTrue);
    expect(controller.debugSetTowerCharge(0, charge: 1.2), isTrue);
    final enemy = controller.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 220,
      level: 50,
    );
    expect(enemy, isNotNull);
    final enemyId = enemy!.id;
    controller.tick(0.1);
    expect(controller.pulses, isNotEmpty);
    expect(controller.boostPulseToCore(controller.pulses.last.id), isTrue);

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
