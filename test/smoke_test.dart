import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('graphics quality storage values stay stable', () {
    expect(
      LightcoreGraphicsQuality.maybeFromStorageValue('high'),
      LightcoreGraphicsQuality.high,
    );
    expect(
      LightcoreGraphicsQuality.maybeFromStorageValue('low_power'),
      LightcoreGraphicsQuality.lowPower,
    );
    expect(LightcoreGraphicsQuality.maybeFromStorageValue('unknown'), isNull);
  });
}
