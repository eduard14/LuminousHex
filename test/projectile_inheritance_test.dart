import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/lumicore_trait_catalog.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_config.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

List<TowerConfig> _uniformShell(TowerConfig config) =>
    List<TowerConfig>.filled(LightcoreController.slotCount, config);

const _chromaticShell = <TowerConfig>[
  TowerLibrary.redPrism,
  TowerLibrary.orangePrism,
  TowerLibrary.yellowPrism,
  TowerLibrary.greenPrism,
  TowerLibrary.bluePrism,
  TowerLibrary.purplePrism,
];

Iterable<List<TowerConfig>> _towerPermutations(
  List<TowerConfig> configs,
) sync* {
  if (configs.length <= 1) {
    yield configs;
    return;
  }
  for (var index = 0; index < configs.length; index += 1) {
    final head = configs[index];
    final tail = <TowerConfig>[
      ...configs.take(index),
      ...configs.skip(index + 1),
    ];
    for (final permutation in _towerPermutations(tail)) {
      yield <TowerConfig>[head, ...permutation];
    }
  }
}

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

void _clearLayer3Trial(LightcoreController controller) {
  expect(controller.layer3TrialActive, isTrue);
  expect(controller.debugCompleteLayer3Trial(), isTrue);
  expect(controller.layer3TrialCleared, isTrue);
}

void main() {
  test('chromatic layer 1 shell exposes rainbow merge rates', () {
    final controller = LightcoreController(traitRandom: Random(17));
    addTearDown(controller.dispose);

    _maxOutCurrentShell(controller, _chromaticShell);

    expect(controller.promotionRainbowEligible, isTrue);
    expect(
      controller.promotionRainbowResultChance,
      closeTo(LightcoreController.rainbowPromotionChance, 0.0001),
    );
    expect(
      controller.promotionProjectileAffinityRates.values,
      everyElement(closeTo(0.15, 0.0001)),
    );
    expect(
      controller.promotionPayloadAffinityRates.values,
      everyElement(closeTo(0.15, 0.0001)),
    );
  });

  test('rainbow promotion cycles every prism projectile and payload', () {
    LightcoreController? rainbowController;

    for (final configs in _towerPermutations(_chromaticShell)) {
      final controller = LightcoreController(traitRandom: Random(23));
      _promoteRootShell(controller, configs);
      if (controller.coreAffinitySignatureLabel == 'Rainbow tower') {
        rainbowController = controller;
        break;
      }
      controller.dispose();
    }

    expect(rainbowController, isNotNull);
    final controller = rainbowController!;
    addTearDown(controller.dispose);

    expect(controller.coreProjectileArsenal, layer2RainbowProjectileLoadout);
    expect(controller.corePayloadArsenal, layer2RainbowPayloadLoadout);

    controller.selectCenter();
    controller.handleBattleCenterTap();
    var pulse = controller.pulses.last;
    expect(pulse.projectileType, layer2RainbowProjectileLoadout.first);
    expect(pulse.payloadType, layer2RainbowPayloadLoadout.first);
    expect(pulse.affinity, pulse.projectileType.affinity);
    expect(pulse.secondaryAffinity, pulse.payloadType.affinity);

    controller.handleBattleCenterTap();
    pulse = controller.pulses.last;
    expect(pulse.projectileType, layer2RainbowProjectileLoadout[1]);
    expect(pulse.payloadType, layer2RainbowPayloadLoadout[1]);
    expect(pulse.affinity, pulse.projectileType.affinity);
    expect(pulse.secondaryAffinity, pulse.payloadType.affinity);
  });

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
      _clearLayer3Trial(controller);
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

      controller.echoSeeds = 10;
      while (controller.promotedChildTowerRerollsRemaining(
            controller.slots[0],
          ) >
          0) {
        expect(controller.rerollPromotedChildTower(0), isTrue);
      }
      final seedsBeforeBlockedRoll = controller.echoSeeds;
      expect(
        controller.promotedChildTowerRerollsRemaining(controller.slots[0]),
        0,
      );
      expect(controller.rerollPromotedChildTower(0), isFalse);
      expect(controller.echoSeeds, seedsBeforeBlockedRoll);
    },
  );
}
