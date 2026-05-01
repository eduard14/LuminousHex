import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/card_configs.dart';
import 'package:lightcore/data/enemy_manager_configs.dart';

void main() {
  test('core manager templates all have portrait seeds and bios', () {
    final ids = <String>{};

    for (final config in CardLibrary.templates) {
      expect(ids.add(config.id), isTrue, reason: 'Duplicate ${config.id}');
      expect(
        config.id,
        matches(RegExp(r'^mgr_\d{3}_[a-z0-9_]+$')),
        reason: config.id,
      );
      expect(config.flavorBio.length, greaterThan(60), reason: config.id);
      expect(config.flavorBio, isNot(contains('TODO')), reason: config.id);
      expect(File(config.portraitAssetPath).existsSync(), isTrue);
    }
    expect(CardLibrary.templates, hasLength(40));
    expect(CardLibrary.templates.first.id, 'mgr_001_whitney_stardust');
    expect(CardLibrary.templates.last.id, 'mgr_040_the_singularity_stylist');
    expect(CardLibrary.byId('quick_relay')?.id, 'mgr_003_yella_nova');
  });

  test('threat director templates all have portrait seeds and bios', () {
    final ids = <String>{};

    for (final config in EnemyManagerLibrary.all) {
      expect(ids.add(config.id), isTrue, reason: 'Duplicate ${config.id}');
      expect(
        config.id,
        matches(RegExp(r'^emg_\d{3}_[a-z0-9_]+$')),
        reason: config.id,
      );
      expect(config.flavorBio.length, greaterThan(60), reason: config.id);
      expect(config.flavorBio, isNot(contains('TODO')), reason: config.id);
      expect(File(config.portraitAssetPath).existsSync(), isTrue);
    }
    expect(EnemyManagerLibrary.all, hasLength(40));
    expect(EnemyManagerLibrary.all.first.id, 'emg_001_plain_jane_quasar');
    expect(EnemyManagerLibrary.all.last.id, 'emg_040_the_dark_spectrum');
    expect(
      EnemyManagerLibrary.byId('swarm_broker')?.id,
      'emg_003_splinter_stella',
    );
  });
}
