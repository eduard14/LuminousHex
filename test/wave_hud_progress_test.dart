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
