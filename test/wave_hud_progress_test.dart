import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('wave HUD progress resets and increments the wave number', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.activeLayerWaveHudLabel, 'Wave 1');
    expect(controller.activeLayerWaveProgress, 0);

    controller.activeLayer.normalKillsSinceBoss =
        LightcoreController.initialEnemyTarget - 1;
    expect(controller.activeLayerWaveHudLabel, 'Wave 1');
    expect(
      controller.activeLayerWaveProgress,
      closeTo(
        (LightcoreController.initialEnemyTarget - 1) /
            LightcoreController.initialEnemyTarget,
        0.001,
      ),
    );

    controller.activeLayer.normalKillsSinceBoss =
        LightcoreController.initialEnemyTarget;
    expect(controller.activeLayerWaveHudLabel, 'Wave 2');
    expect(controller.activeLayerWaveProgress, 0);
  });

  test('wave HUD progress is current wave progress past Wave 10', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.activeLayer.normalKillsSinceBoss =
        (LightcoreController.initialEnemyTarget * 12) + 3;

    expect(controller.activeLayerWaveHudLabel, 'Wave 13');
    expect(controller.activeLayerWaveProgress, closeTo(0.5, 0.001));
  });

  test('wave transition state turns on after a wave clears', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.startLayer1Run();
    expect(controller.layer1WaveTransitionActive, isFalse);

    controller.activeLayer.normalKillsSinceBoss =
        LightcoreController.initialEnemyTarget;

    expect(controller.activeLayerWaveHudLabel, 'Wave 2');
    expect(controller.activeLayerWaveProgress, 0);
    expect(controller.enemyCount, 0);
    expect(controller.layer1WaveTransitionActive, isTrue);

    expect(controller.releaseLayer1Wave(), isTrue);

    expect(controller.enemyCount, greaterThan(0));
    expect(controller.layer1WaveTransitionActive, isFalse);
  });

  test('release Layer 1 wave fills the active pressure cap', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    expect(controller.swarmActivated, isFalse);
    expect(controller.enemyCount, 0);
    expect(controller.canReleaseLayer1Wave, isTrue);

    expect(controller.releaseLayer1Wave(), isTrue);

    expect(controller.swarmActivated, isTrue);
    expect(controller.enemyCount, controller.enemyTargetCount);
    expect(controller.canReleaseLayer1Wave, isFalse);
  });
}
