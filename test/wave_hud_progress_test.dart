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
}
