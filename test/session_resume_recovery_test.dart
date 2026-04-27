import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('cloud restore re-arms a legacy dormant battle runtime', () {
    final source = LightcoreController();
    addTearDown(source.dispose);
    source.debugDisableTutorial();
    expect(source.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    final payload = source.buildCloudSavePayload();
    final layerData = payload['layers'] as Map<String, dynamic>;
    final layers = layerData['items'] as List<dynamic>;
    final firstLayer = layers.first as Map<String, dynamic>;
    firstLayer
      ..remove('outerRingRevealed')
      ..remove('swarmActivated')
      ..['spawnTimer'] = 45.0;

    final restored = LightcoreController.fromCloudSavePayload(payload);
    addTearDown(restored.dispose);

    expect(restored.outerRingRevealed, isTrue);
    expect(restored.swarmActivated, isTrue);
    expect(restored.enemyCount, 0);

    for (var frame = 0; frame < 20; frame += 1) {
      restored.tick(1 / 30);
    }

    expect(restored.enemyCount, greaterThan(0));
  });

  test('cloud restore keeps an untouched save dormant', () {
    final restored = LightcoreController.fromCloudSavePayload(
      const <String, dynamic>{
        'player': <String, dynamic>{'playerId': 'LUMI-FRESH'},
      },
    );
    addTearDown(restored.dispose);

    expect(restored.outerRingRevealed, isFalse);
    expect(restored.swarmActivated, isFalse);

    for (var frame = 0; frame < 90; frame += 1) {
      restored.tick(1 / 30);
    }

    expect(restored.enemyCount, 0);
  });
}
