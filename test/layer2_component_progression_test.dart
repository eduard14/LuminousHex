import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_types.dart';

import 'helpers/lightcore_test_fixtures.dart';

void _preparePureRing(
  LightcoreController controller,
  TowerConfig config, {
  int bestWave = 1,
}) {
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  controller.lumens = 1000000;
  for (var index = 0; index < LightcoreController.slotCount; index += 1) {
    expect(controller.buildTowerAt(index, config), isTrue);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      expect(controller.upgradeTower(index), isTrue);
    }
  }
  controller.activeLayer.bestWaveReached = bestWave;
}

void main() {
  test('pure Layer 1 composition creates matching Layer 2 component odds', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);

    _preparePureRing(controller, TowerLibrary.redPrism, bestWave: 15);

    expect(controller.promotionProjectileAffinityRates.keys, [
      PrototypeAffinity.ember,
    ]);
    expect(controller.promotionProjectileAffinityRates.values.single, 1);
    expect(controller.promotionPayloadAffinityRates.keys, [
      PrototypeAffinity.ember,
    ]);
    expect(controller.promotionPayloadAffinityRates.values.single, 1);

    controller.unlockLayer2Tower();

    final component = controller.latestLayer2Component;
    expect(component, isNotNull);
    expect(component!.projectileAffinity, PrototypeAffinity.ember);
    expect(component.payloadAffinity, PrototypeAffinity.ember);
    expect(component.reachedWave, 15);
    expect(component.statTier, 15);
    expect(component.subtraits, hasLength(2));
  });

  test('deeper Layer 1 push improves component tier and subtrait count', () {
    final shallow = createDeterministicController();
    final deep = createDeterministicController();
    addTearDown(shallow.dispose);
    addTearDown(deep.dispose);

    _preparePureRing(shallow, TowerLibrary.cyanPrism, bestWave: 5);
    _preparePureRing(deep, TowerLibrary.cyanPrism, bestWave: 30);

    shallow.unlockLayer2Tower();
    deep.unlockLayer2Tower();

    final shallowComponent = shallow.latestLayer2Component!;
    final deepComponent = deep.latestLayer2Component!;

    expect(shallowComponent.statTier, 5);
    expect(shallowComponent.subtraits, hasLength(1));
    expect(deepComponent.statTier, 30);
    expect(deepComponent.subtraits, hasLength(3));
    expect(
      deepComponent.baseFinalDamageMultiplier,
      greaterThan(shallowComponent.baseFinalDamageMultiplier),
    );
  });

  test('component forecast labels track wave tier breakpoints', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);

    expect(
      controller.activeLayerComponentForecastReadyLabel,
      'Build towers to shape a component',
    );
    expect(controller.activeLayerComponentStatTier, 1);
    expect(controller.activeLayerComponentLevel, 0);
    expect(controller.activeLayerExpectedSubtraitCount, 1);
    expect(
      controller.activeLayerNextComponentTierLabel,
      'Reach Wave 10 for Layer 2 Lv 1',
    );

    _preparePureRing(controller, TowerLibrary.orangePrism, bestWave: 10);

    expect(
      controller.activeLayerComponentForecastReadyLabel,
      'Ready to Create Layer 2 Component',
    );
    expect(controller.activeLayerBestWaveLabel, 'Best Wave 10');
    expect(controller.activeLayerComponentStatTier, 10);
    expect(controller.activeLayerComponentLevel, 1);
    expect(controller.activeLayerExpectedSubtraitCount, 2);
    expect(
      controller.activeLayerNextComponentTierLabel,
      'Reach Wave 25 for 3 subtraits',
    );

    controller.activeLayer.bestWaveReached = 25;

    expect(controller.activeLayerComponentStatTier, 25);
    expect(controller.activeLayerComponentLevel, 2);
    expect(controller.activeLayerExpectedSubtraitCount, 3);
    expect(
      controller.activeLayerNextComponentTierLabel,
      'Max subtrait count reached',
    );
  });

  test('Layer 2 components round trip through cloud saves', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    _preparePureRing(controller, TowerLibrary.purplePrism, bestWave: 25);

    controller.unlockLayer2Tower();
    final original = controller.latestLayer2Component!;

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(restored.layer2Components, hasLength(1));
    final roundTripped = restored.layer2Components.single;
    expect(roundTripped.id, original.id);
    expect(roundTripped.projectileType, original.projectileType);
    expect(roundTripped.payloadType, original.payloadType);
    expect(roundTripped.reachedWave, original.reachedWave);
    expect(roundTripped.subtraits.map((trait) => trait.type), [
      for (final trait in original.subtraits) trait.type,
    ]);
  });

  test(
    'component scroll upgrades and favorites round trip through cloud saves',
    () {
      final controller = createDeterministicController();
      addTearDown(controller.dispose);
      _preparePureRing(controller, TowerLibrary.purplePrism, bestWave: 25);

      controller.unlockLayer2Tower();
      final component = controller.latestLayer2Component!;
      controller.componentScrolls = controller.componentScrollUpgradeCost(
        component,
      );

      expect(controller.upgradeLayer2Component(component.id), isTrue);
      expect(controller.toggleLayer2ComponentFavorite(component.id), isTrue);

      final upgraded = controller.layer2ComponentById(component.id)!;
      expect(upgraded.scrollLevel, 1);
      expect(upgraded.favorite, isTrue);
      expect(controller.scrapLayer2Component(component.id), isFalse);

      final restored = LightcoreController.fromCloudSavePayload(
        controller.buildCloudSavePayload(),
      );
      addTearDown(restored.dispose);

      final roundTripped = restored.layer2Components.single;
      expect(roundTripped.scrollLevel, 1);
      expect(roundTripped.favorite, isTrue);
      expect(restored.componentScrolls, 0);
    },
  );

  test('component assignment scales the validated regional farm rate', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    _preparePureRing(controller, TowerLibrary.redPrism, bestWave: 25);
    controller.unlockLayer2Tower();
    final component = controller.latestLayer2Component!;

    final starter = controller.threatRegionConfigs.first;
    controller.debugRevealThreatRegion(starter.id, stabilizedLevel: 1);
    expect(controller.startThreatRegionFarmValidation(starter.id), isTrue);
    final baseline = controller.threatRegionOfflineKillsPerHour;

    expect(
      controller.equipLayer2ComponentToRegion(
        componentId: component.id,
        regionId: starter.id,
      ),
      isTrue,
    );

    expect(controller.threatRegionOfflineKillsPerHour, greaterThan(baseline));
    expect(
      controller.equippedLayer2ComponentForRegion(starter.id)?.id,
      component.id,
    );
  });

  test('component region assignments restore after threat map state', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    _preparePureRing(controller, TowerLibrary.redPrism, bestWave: 25);
    controller.unlockLayer2Tower();
    final component = controller.latestLayer2Component!;

    final secondRegion = controller.threatRegionConfigs[1];
    controller.debugRevealThreatRegion(secondRegion.id, stabilizedLevel: 1);
    expect(
      controller.equipLayer2ComponentToRegion(
        componentId: component.id,
        regionId: secondRegion.id,
      ),
      isTrue,
    );

    final restored = LightcoreController.fromCloudSavePayload(
      controller.buildCloudSavePayload(),
    );
    addTearDown(restored.dispose);

    expect(
      restored.layer2ComponentById(component.id)?.equippedRegionId,
      secondRegion.id,
    );
  });

  test(
    'dismantling unprotected components returns scrolls and removes the roll',
    () {
      final controller = createDeterministicController();
      addTearDown(controller.dispose);
      _preparePureRing(controller, TowerLibrary.orangePrism, bestWave: 10);
      controller.unlockLayer2Tower();
      final component = controller.latestLayer2Component!;
      final scrapValue = controller.componentScrapScrollValue(component);

      expect(controller.scrapLayer2Component(component.id), isTrue);

      expect(controller.layer2Components, isEmpty);
      expect(controller.componentScrolls, scrapValue);
    },
  );

  test('region farm wave locks from the best completed challenge wave', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);

    final starter = controller.threatRegionConfigs.first;
    controller.debugRevealThreatRegion(starter.id, stabilizedLevel: 1);

    expect(controller.canStartThreatRegionFarmValidation(starter.id), isTrue);
    expect(controller.startThreatRegionFarmValidation(starter.id), isTrue);

    final state = controller.threatRegionStateById(starter.id)!;
    expect(state.lockedFarmWave, 5);
    expect(controller.validatedFarmRegionId, starter.id);
    expect(controller.threatRegionOfflineKillsPerHour, greaterThan(0));
  });

  test('equipment drops are boss-only from Layer 2 and higher', () {
    final layer1 = createDeterministicController();
    final layer2 = createDeterministicController();
    addTearDown(layer1.dispose);
    addTearDown(layer2.dispose);

    layer1.debugCompleteBossAndEquipmentTutorial();
    layer2.debugCompleteBossAndEquipmentTutorial();
    forgeLayer2(layer2);

    final layer1Boss = layer1.debugSpawnEnemyFromCard(
      BossEnemyLibrary.starterWhiteWarden.id,
      boss: true,
      angle: 0,
      radius: 120,
      healthFraction: 1,
    );
    final layer2Boss = layer2.debugSpawnEnemyFromCard(
      BossEnemyLibrary.starterWhiteWarden.id,
      boss: true,
      angle: 0,
      radius: 120,
      healthFraction: 1,
    );
    final layer2Normal = layer2.debugSpawnEnemyFromCard(
      EnemyLibrary.basicWhite.id,
      angle: 0,
      radius: 120,
      healthFraction: 1,
    );

    expect(layer1.equipmentDropChanceForEnemy(layer1Boss!), 0);
    expect(layer2.equipmentDropChanceForEnemy(layer2Normal!), 0);
    expect(layer2.equipmentDropChanceForEnemy(layer2Boss!), greaterThan(0));
  });

  test('Layer 2 bosses grant component scrolls', () {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    controller.debugCompleteBossAndEquipmentTutorial();
    forgeLayer2(controller);

    final boss = controller.debugSpawnEnemyFromCard(
      BossEnemyLibrary.starterWhiteWarden.id,
      boss: true,
      angle: 0,
      radius: 120,
      healthFraction: 1,
    );

    expect(boss, isNotNull);
    expect(controller.componentScrolls, 0);
    expect(controller.debugDefeatEnemy(boss!.id), isTrue);
    expect(controller.componentScrolls, greaterThan(0));
  });
}
