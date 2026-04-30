import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/card_configs.dart';
import 'package:lightcore/data/enemy_manager_configs.dart';

void main() {
  test('core manager templates all have portrait seeds and bios', () {
    final ids = <String>{};

    for (final config in CardLibrary.templates) {
      expect(ids.add(config.id), isTrue, reason: 'Duplicate ${config.id}');
      expect(config.flavorBio, contains(config.name), reason: config.id);
      expect(config.flavorBio.length, greaterThan(80), reason: config.id);
      expect(config.flavorBio, isNot(contains('TODO')), reason: config.id);
      expect(File(config.portraitAssetPath).existsSync(), isTrue);
    }
  });

  test('threat director templates all have portrait seeds and bios', () {
    final ids = <String>{};

    for (final config in EnemyManagerLibrary.all) {
      expect(ids.add(config.id), isTrue, reason: 'Duplicate ${config.id}');
      expect(config.flavorBio, contains(config.name), reason: config.id);
      expect(config.flavorBio.length, greaterThan(80), reason: config.id);
      expect(config.flavorBio, isNot(contains('TODO')), reason: config.id);
      expect(File(config.portraitAssetPath).existsSync(), isTrue);
    }
  });
}
