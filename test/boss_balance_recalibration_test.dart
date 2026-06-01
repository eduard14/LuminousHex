import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void _unlockBossHunts(LightcoreController controller) {
  controller.applyOfflineClaim(
    LightcoreOfflineClaimResult(
      secondsClaimed: 1,
      lumensGranted: 0,
      fluxGranted: 0,
      enemyTicketsGranted: 0,
      killsGranted: LightcoreController.killsForOverallLevel(
        LightcoreController.bossUnlockLevel,
      ),
      serverValidated: true,
    ),
    showBanner: false,
  );
}

void _buildMaxedRedPrisms(LightcoreController controller, int count) {
  controller.lumens = 100000;
  for (var slotIndex = 0; slotIndex < count; slotIndex++) {
    controller.kills = max(
      controller.kills,
      LightcoreController.unlockKillsForOuterSlot(slotIndex),
    );
    expect(controller.buildTowerAt(slotIndex, TowerLibrary.redPrism), isTrue);
    while (controller.slots[slotIndex].level <
        LightcoreController.maxTowerLevel) {
      expect(controller.upgradeTower(slotIndex), isTrue);
    }
  }
}

void _activateReadyTowers(LightcoreController controller, int count) {
  for (var slotIndex = 0; slotIndex < count; slotIndex++) {
    if (!controller.canActivateTower(controller.slots[slotIndex])) {
      continue;
    }
    controller.activateTowerSlot(
      slotIndex,
      showBanner: false,
      selectForStats: false,
    );
  }
}

void main() {
  test('first live boss is survivable with three maxed tier 1 towers', () {
    final controller = LightcoreController(
      packRandom: Random(3),
      traitRandom: Random(5),
    );
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    _unlockBossHunts(controller);
    _buildMaxedRedPrisms(controller, 3);
    expect(
      controller.debugSetEnemyCardLevel(
        BossEnemyLibrary.starterWhiteWarden.id,
        level: 1,
        copies: 1,
        boss: true,
      ),
      isTrue,
    );
    controller.setActiveBossEnemyCard(BossEnemyLibrary.starterWhiteWarden.id);
    final boss = controller.debugSpawnEnemyFromCard(
      BossEnemyLibrary.starterWhiteWarden.id,
      angle: 0,
      radius: 220,
      boss: true,
      healthFraction: 0.05,
    );
    expect(boss, isNotNull);

    for (var step = 0; step < 4000 && controller.bossAlive; step++) {
      _activateReadyTowers(controller, 3);
      controller.tick(0.1);
    }

    expect(controller.bossAlive, isFalse);
  });
}
