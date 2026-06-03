import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('cloud-restored promotion-ready shell can create the next layer', () {
    final source = LightcoreController();
    addTearDown(source.dispose);
    _preparePromotionReadyRootShell(source);

    final restored = LightcoreController.fromCloudSavePayload(
      source.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.isPromotionReady, isTrue);

    restored.unlockLayer2Tower();

    expect(restored.activeLayer.tier, 2);
    expect(restored.layers.length, source.layers.length + 1);
  });

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

  test(
    'cloud restore migrates legacy orbit node projectiles to shield halo',
    () {
      final source = LightcoreController();
      addTearDown(source.dispose);
      source.debugDisableTutorial();
      source.lumens = 1000;
      expect(source.buildTowerAt(0, TowerLibrary.greenPrism), isTrue);

      final payload = source.buildCloudSavePayload();
      final layers = payload['layers'] as Map<String, dynamic>;
      final firstLayer =
          (layers['items'] as List<dynamic>).first as Map<String, dynamic>;
      final core = firstLayer['core'] as Map<String, dynamic>;
      final slots = firstLayer['slots'] as List<dynamic>;
      final greenSlot = slots.first as Map<String, dynamic>;
      core
        ..['projectileType'] = ProjectileType.orbitNode.name
        ..['projectileLoadout'] = <String>[ProjectileType.orbitNode.name];
      greenSlot
        ..['projectileType'] = ProjectileType.orbitNode.name
        ..['childProjectileType'] = ProjectileType.orbitNode.name
        ..['childProjectileLoadout'] = <String>[ProjectileType.orbitNode.name];

      final restored = LightcoreController.fromCloudSavePayload(payload);
      addTearDown(restored.dispose);

      expect(restored.coreState.projectileType, ProjectileType.shieldHalo);
      expect(restored.coreState.projectileLoadout, [ProjectileType.shieldHalo]);
      expect(restored.slots.first.projectileType, ProjectileType.shieldHalo);
      expect(
        restored.slots.first.childProjectileType,
        ProjectileType.shieldHalo,
      );
      expect(restored.slots.first.childProjectileLoadout, [
        ProjectileType.shieldHalo,
      ]);
    },
  );

  test('threat assignment presets save anomaly deck and apex per core', () {
    final source = LightcoreController();
    addTearDown(source.dispose);
    source.debugDisableTutorial();

    final aetherBasic = EnemyLibrary.all.firstWhere(
      (config) =>
          config.rarity == EnemyCardRarity.basic &&
          config.affinity == PrototypeAffinity.aether,
    );
    expect(
      source.debugSetEnemyCardLevel(EnemyLibrary.basicRed.id, level: 1),
      isTrue,
    );
    expect(source.debugSetEnemyCardLevel(aetherBasic.id, level: 1), isTrue);
    expect(
      source.debugSetEnemyCardLevel(
        BossEnemyLibrary.starterWhiteWarden.id,
        level: 1,
        boss: true,
      ),
      isTrue,
    );

    source.toggleEnemyCardSelection(EnemyLibrary.basicRed.id);
    source.toggleEnemyCardSelection(aetherBasic.id);
    source.setActiveBossEnemyCard(BossEnemyLibrary.starterWhiteWarden.id);
    final presetId = source.createThreatAssignmentPreset(name: 'Root Push');

    expect(presetId, isNotNull);
    expect(source.activeThreatAssignmentPresets.single.name, 'Root Push');
    final presetStats = source.threatAssignmentGroupStatsForPreset(
      source.activeThreatAssignmentPresets.single,
    );
    expect(presetStats.anomalyCount, greaterThan(0));
    expect(presetStats.lumensPerMinute, greaterThan(0));
    expect(presetStats.experiencePerMinute, greaterThan(0));
    expect(presetStats.clearsPerMinute, greaterThan(0));

    source.toggleEnemyCardSelection(EnemyLibrary.basicRed.id);
    expect(
      source.activeEnemyCardIds,
      isNot(contains(EnemyLibrary.basicRed.id)),
    );
    expect(source.applyThreatAssignmentPreset(presetId!), isTrue);
    expect(source.activeEnemyCardIds, contains(EnemyLibrary.basicRed.id));
    expect(
      source.activeBossEnemyCard?.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );
    expect(source.renameThreatAssignmentPreset(presetId, 'Root Farm'), isTrue);

    final restored = LightcoreController.fromCloudSavePayload(
      source.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.activeThreatAssignmentPresets.single.name, 'Root Farm');
    expect(restored.applyThreatAssignmentPreset(presetId), isTrue);
    expect(restored.activeEnemyCardIds, contains(EnemyLibrary.basicRed.id));
    expect(
      restored.activeBossEnemyCard?.config.id,
      BossEnemyLibrary.starterWhiteWarden.id,
    );
  });
}

void _preparePromotionReadyRootShell(LightcoreController controller) {
  controller.debugDisableTutorial();
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  controller.lumens = 1000000;
  controller.activeLayer.bestWaveReached = 10;

  for (var index = 0; index < LightcoreController.slotCount; index += 1) {
    final config = TowerLibrary.all[index % TowerLibrary.all.length];
    expect(controller.buildTowerAt(index, config), isTrue);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      expect(controller.upgradeTower(index), isTrue);
    }
  }
}
