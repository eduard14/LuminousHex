import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/lumicore_trait_catalog.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

List<TowerConfig> _uniformShell(TowerConfig config) =>
    List<TowerConfig>.filled(LightcoreController.slotCount, config);

void _maxOutCurrentShell(
  LightcoreController controller,
  List<TowerConfig> configs,
) {
  controller.lumens = 100000000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, configs[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  expect(controller.isPromotionReady, isTrue);
}

void _promoteRootShell(
  LightcoreController controller,
  List<TowerConfig> configs,
) {
  _maxOutCurrentShell(controller, configs);
  controller.unlockLayer2Tower();
  expect(controller.activeLayer.tier, 2);
}

void _forgeChildShell(
  LightcoreController controller,
  int slotIndex,
  List<TowerConfig> configs,
) {
  expect(
    controller.createChildLayer(slotIndex, PrototypeAffinity.aether),
    isTrue,
  );
  expect(controller.activeLayerHasParentSlot, isTrue);
  _maxOutCurrentShell(controller, configs);
  controller.unlockLayer2Tower();
  expect(controller.activeLayerHasParentSlot, isFalse);
}

void main() {
  test(
    'uniform layer 1 shell forges matching layer 2 projectile and payload',
    () {
      final controller = LightcoreController(traitRandom: Random(3));
      addTearDown(controller.dispose);

      _promoteRootShell(controller, _uniformShell(TowerLibrary.redPrism));

      final core = controller.coreState;
      expect(core.affinity, PrototypeAffinity.ember);
      expect(core.secondaryAffinity, PrototypeAffinity.ember);
      expect(
        forgedProjectilesForAffinity(PrototypeAffinity.ember, targetTier: 2),
        contains(core.projectileType),
      );
      expect(
        forgedPayloadsForAffinity(PrototypeAffinity.ember, targetTier: 2),
        contains(core.payloadType),
      );
    },
  );

  test(
    'mixed child shell only rolls projectile and payload from source colors',
    () {
      final controller = LightcoreController(traitRandom: Random(7));
      addTearDown(controller.dispose);

      _promoteRootShell(controller, _uniformShell(TowerLibrary.yellowPrism));

      _forgeChildShell(controller, 0, <TowerConfig>[
        TowerLibrary.bluePrism,
        TowerLibrary.bluePrism,
        TowerLibrary.bluePrism,
        TowerLibrary.greenPrism,
        TowerLibrary.greenPrism,
        TowerLibrary.greenPrism,
      ]);

      final forged = controller.slots[0];
      expect(forged.isPromotedChildTower, isTrue);
      expect(<PrototypeAffinity>[
        PrototypeAffinity.aether,
        PrototypeAffinity.verdant,
      ], contains(forged.childAffinity));
      expect(<PrototypeAffinity>[
        PrototypeAffinity.aether,
        PrototypeAffinity.verdant,
      ], contains(forged.childSecondaryAffinity));
      expect(
        forgedProjectilesForAffinity(forged.childAffinity!, targetTier: 2),
        contains(forged.childProjectileType),
      );
      expect(
        forgedPayloadsForAffinity(
          forged.childSecondaryAffinity!,
          targetTier: 2,
        ),
        contains(forged.childPayloadType),
      );
      expect(controller.towerProjectileArsenal(forged), hasLength(1));
      expect(controller.towerPayloadArsenal(forged), hasLength(1));
    },
  );

  test('new child shell core uses the selected starting color', () {
    final controller = LightcoreController(traitRandom: Random(5));
    addTearDown(controller.dispose);

    _promoteRootShell(controller, _uniformShell(TowerLibrary.bluePrism));

    expect(controller.coreState.affinity, PrototypeAffinity.aether);
    controller.enterChildLayer(0);
    expect(controller.activeLayer.tier, 2);
    expect(controller.slots[0].childLayerId, isNull);

    expect(controller.createChildLayer(0, PrototypeAffinity.ember), isTrue);

    final core = controller.coreState;
    expect(controller.activeLayer.tier, 1);
    expect(controller.activeLayerHasParentSlot, isTrue);
    expect(core.affinity, PrototypeAffinity.ember);
    expect(core.secondaryAffinity, isNull);
    expect(core.projectileType, ProjectileType.coreBomb);
    expect(core.payloadType, PayloadType.none);
    expect(controller.coreProjectileArsenal, <ProjectileType>[
      ProjectileType.coreBomb,
    ]);
    expect(controller.corePayloadArsenal, <PayloadType>[PayloadType.none]);
  });

  test(
    'layer 3 core upgrades into the layer 3 projectile and payload pools',
    () {
      final controller = LightcoreController(traitRandom: Random(11));
      addTearDown(controller.dispose);

      _promoteRootShell(controller, _uniformShell(TowerLibrary.yellowPrism));

      for (var index = 0; index < LightcoreController.slotCount; index++) {
        _forgeChildShell(
          controller,
          index,
          _uniformShell(TowerLibrary.yellowPrism),
        );
      }

      expect(controller.isPromotionReady, isTrue);
      controller.unlockLayer2Tower();

      final core = controller.coreState;
      expect(controller.activeLayer.tier, 3);
      expect(core.affinity, PrototypeAffinity.solar);
      expect(core.secondaryAffinity, PrototypeAffinity.solar);
      expect(
        forgedProjectilesForAffinity(PrototypeAffinity.solar, targetTier: 3),
        contains(core.projectileType),
      );
      expect(
        forgedPayloadsForAffinity(PrototypeAffinity.solar, targetTier: 3),
        contains(core.payloadType),
      );
    },
  );

  test(
    'echo seed rerolls a promoted child while staying inside its source pools',
    () {
      final controller = LightcoreController(traitRandom: Random(13));
      addTearDown(controller.dispose);

      _promoteRootShell(controller, _uniformShell(TowerLibrary.purplePrism));

      _forgeChildShell(controller, 0, <TowerConfig>[
        TowerLibrary.redPrism,
        TowerLibrary.redPrism,
        TowerLibrary.yellowPrism,
        TowerLibrary.yellowPrism,
        TowerLibrary.yellowPrism,
        TowerLibrary.redPrism,
      ]);

      final before = controller.slots[0];
      expect(controller.echoSeeds, greaterThan(0));

      controller.echoSeeds = 3;
      var changed = false;
      for (var roll = 0; roll < 3 && !changed; roll++) {
        expect(controller.rerollPromotedChildTower(0), isTrue);
        final after = controller.slots[0];
        changed =
            after.childProjectileType != before.childProjectileType ||
            after.childPayloadType != before.childPayloadType ||
            after.childAffinity != before.childAffinity ||
            after.childSecondaryAffinity != before.childSecondaryAffinity;
      }

      final rerolled = controller.slots[0];
      expect(changed, isTrue);
      expect(controller.echoSeeds, lessThan(3));
      expect(<PrototypeAffinity>[
        PrototypeAffinity.ember,
        PrototypeAffinity.solar,
      ], contains(rerolled.childAffinity));
      expect(<PrototypeAffinity>[
        PrototypeAffinity.ember,
        PrototypeAffinity.solar,
      ], contains(rerolled.childSecondaryAffinity));
      expect(
        forgedProjectilesForAffinity(rerolled.childAffinity!, targetTier: 2),
        contains(rerolled.childProjectileType),
      );
      expect(
        forgedPayloadsForAffinity(
          rerolled.childSecondaryAffinity!,
          targetTier: 2,
        ),
        contains(rerolled.childPayloadType),
      );
    },
  );
}
