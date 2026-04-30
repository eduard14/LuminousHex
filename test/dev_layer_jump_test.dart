import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test(
    'debug layer seed jumps directly to the requested progression layer',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      final seeded = controller.debugSeedProgressionLayer(3);

      expect(seeded, isTrue);
      expect(controller.progressionLayer, 3);
      expect(controller.activeLayer.tier, 3);
      expect(controller.activeLayer.label, 'Nexus Shell');
      expect(
        controller.layers.map((layer) => layer.tier),
        containsAll(<int>[1, 2, 3]),
      );
      expect(controller.lumens, greaterThanOrEqualTo(30000000));
      expect(controller.shellCores, greaterThanOrEqualTo(150000));
    },
  );

  test('debug layer seed caps at the highest shell tier', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final seeded = controller.debugSeedProgressionLayer(99);

    expect(seeded, isTrue);
    expect(controller.progressionLayer, LightcoreController.maxShellTier);
    expect(controller.activeLayer.tier, LightcoreController.maxShellTier);
    expect(controller.activeLayer.label, 'Ascendant Shell');
  });
}
