import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/models/enemy_art_assets.dart';

void main() {
  test('every apex anomaly resolves to a 1024 square boss asset', () async {
    final invalidBossPaths = <String>[];
    final missingBossPaths = <String>[];
    final misSizedBossPaths = <String>[];

    for (final config in BossEnemyLibrary.all) {
      final path = enemyImageAssetForConfig(config);
      if (path == null || !path.startsWith('assets/sprites/bosses/')) {
        invalidBossPaths.add('${config.id}: $path');
        continue;
      }
      final file = File(path);
      if (!file.existsSync()) {
        missingBossPaths.add('${config.id}: $path');
        continue;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (image.width != 1024 || image.height != 1024) {
        misSizedBossPaths.add(
          '${config.id}: $path was ${image.width}x${image.height}',
        );
      }
      image.dispose();
    }

    expect(
      invalidBossPaths,
      isEmpty,
      reason: 'Apex art should not fall back to normal anomaly sprites.',
    );
    expect(
      missingBossPaths,
      isEmpty,
      reason: 'Every Apex config needs a concrete image asset.',
    );
    expect(
      misSizedBossPaths,
      isEmpty,
      reason: 'Apex assets should stay consistently sized.',
    );
  });
}
