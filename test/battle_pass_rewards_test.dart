import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/models/lightcore_progression.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

int _sumRewardQuantity(
  Iterable<BattlePassReward> rewards,
  BattlePassRewardKind kind,
) {
  return rewards
      .where((reward) => reward.kind == kind)
      .fold(0, (total, reward) => total + reward.quantity);
}

void main() {
  test('battle pass tiers keep currency rewards except final premium pulls', () {
    final controller = LightcoreController(
      packRandom: Random(1),
      traitRandom: Random(2),
      managerRandom: Random(3),
    );
    addTearDown(controller.dispose);

    for (final type in controller.battlePassTypes) {
      final tiers = controller.battlePassTiers(type);
      for (final tier in tiers) {
        expect(
          tier.freeReward.kind,
          anyOf(BattlePassRewardKind.flux, BattlePassRewardKind.enemyPulls),
          reason: '$type free track should stay on currency rewards.',
        );
      }

      for (var index = 0; index < tiers.length; index++) {
        final tier = tiers[index];
        final finalTier = index == tiers.length - 1;
        if (finalTier && type == BattlePassType.towerManagerPulls) {
          expect(tier.premiumReward.kind, BattlePassRewardKind.towerManager);
          expect(tier.premiumReward.managerRarity, ManagerRarity.rare);
          continue;
        }
        if (finalTier && type == BattlePassType.enemyManagerPulls) {
          expect(tier.premiumReward.kind, BattlePassRewardKind.enemyManager);
          expect(tier.premiumReward.managerRarity, ManagerRarity.epic);
          continue;
        }
        if (finalTier && type == BattlePassType.enemyPulls) {
          expect(tier.premiumReward.kind, BattlePassRewardKind.enemyCard);
          expect(tier.premiumReward.enemyCardRarity, EnemyCardRarity.legendary);
          continue;
        }
        expect(
          tier.premiumReward.kind,
          anyOf(BattlePassRewardKind.flux, BattlePassRewardKind.enemyPulls),
          reason:
              '$type premium track should stay on currency rewards except the final pull.',
        );
      }
    }

    expect(BattlePassReward.enemyPulls(3).label, '+3 Threat Scans');
    expect(
      const BattlePassReward.towerManager(rarity: ManagerRarity.rare).label,
      'Rare Core Manager',
    );
  });

  test('reading a training section grants 5 tickets once', () {
    final controller = LightcoreController(
      packRandom: Random(4),
      traitRandom: Random(5),
      managerRandom: Random(6),
    );
    addTearDown(controller.dispose);

    final startingTickets = controller.enemyTickets;

    expect(controller.markHelpSectionRead('header-icons'), isTrue);
    expect(
      controller.enemyTickets,
      startingTickets + LightcoreController.helpSectionTicketReward,
    );

    expect(controller.markHelpSectionRead('header-icons'), isFalse);
    expect(
      controller.enemyTickets,
      startingTickets + LightcoreController.helpSectionTicketReward,
    );
  });

  test('claim all batches every unlocked reward on the selected pass', () {
    final controller = LightcoreController(
      packRandom: Random(7),
      traitRandom: Random(8),
      managerRandom: Random(9),
    );
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    const type = BattlePassType.dailyKills;
    const premiumUnlockCost = 120;
    final secondTierGoal = controller.battlePassTiers(type)[1].goal;
    final pass = controller.battlePassFor(type);
    pass.progress = secondTierGoal;
    controller.flux = 200;
    controller.prismShards = premiumUnlockCost;

    final unlockedTiers = controller.battlePassTiers(type).take(2).toList();
    final freeRewards = unlockedTiers.map((tier) => tier.freeReward);
    final premiumRewards = unlockedTiers.map((tier) => tier.premiumReward);

    final startingFlux = controller.flux;
    final startingPrismShards = controller.prismShards;
    final startingTickets = controller.enemyTickets;

    expect(controller.claimableBattlePassRewards(type), 2);
    expect(controller.claimUnlockedBattlePassRewards(type), 2);
    expect(controller.claimableBattlePassRewards(type), 0);
    expect(
      controller.flux,
      startingFlux + _sumRewardQuantity(freeRewards, BattlePassRewardKind.flux),
    );
    expect(
      controller.enemyTickets,
      startingTickets +
          _sumRewardQuantity(freeRewards, BattlePassRewardKind.enemyPulls),
    );

    expect(
      controller.unlockPremiumBattlePass(
        type,
        prismShardCost: premiumUnlockCost,
      ),
      isTrue,
    );
    expect(controller.prismShards, startingPrismShards - premiumUnlockCost);
    expect(controller.claimableBattlePassRewards(type), 2);
    expect(controller.claimUnlockedBattlePassRewards(type), 2);
    expect(controller.claimUnlockedBattlePassRewards(type), 0);
    expect(
      controller.flux,
      startingFlux +
          _sumRewardQuantity(freeRewards, BattlePassRewardKind.flux) +
          _sumRewardQuantity(premiumRewards, BattlePassRewardKind.flux),
    );
    expect(
      controller.enemyTickets,
      startingTickets +
          _sumRewardQuantity(freeRewards, BattlePassRewardKind.enemyPulls) +
          _sumRewardQuantity(premiumRewards, BattlePassRewardKind.enemyPulls),
    );
  });

  test(
    'rolling passes create a new active pass and keep old premium purchasable',
    () {
      final controller = LightcoreController(
        packRandom: Random(10),
        traitRandom: Random(11),
        managerRandom: Random(12),
      );
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();

      const type = BattlePassType.enemyPulls;
      const premiumUnlockCost = 90;
      final firstPass = controller.battlePassFor(type);
      final finalGoal = controller.battlePassTiersForPass(firstPass).last.goal;
      firstPass.progress = finalGoal - 1;
      controller.debugAddEnemyTickets(2);

      expect(controller.openEnemyTickets(2), hasLength(2));

      final passes = controller.battlePassesFor(type);
      expect(passes, hasLength(2));
      expect(passes.first.seasonKey, firstPass.seasonKey);
      expect(passes.first.progress, finalGoal);
      expect(passes.first.premiumUnlocked, isFalse);
      expect(passes.last.progress, 1);

      controller.prismShards = premiumUnlockCost;
      expect(
        controller.unlockPremiumBattlePassForPass(
          firstPass,
          prismShardCost: premiumUnlockCost,
        ),
        isTrue,
      );
      expect(firstPass.premiumUnlocked, isTrue);
      expect(controller.battlePassFor(type).seasonKey, passes.last.seasonKey);

      final payload = controller.buildCloudSavePayload();
      final savedPasses = payload['battlePasses'] as List<dynamic>;
      expect(
        savedPasses.where(
          (item) => item is Map<String, dynamic> && item['type'] == type.name,
        ),
        hasLength(2),
      );

      final restored = LightcoreController.fromCloudSavePayload(payload);
      addTearDown(restored.dispose);
      final restoredPasses = restored.battlePassesFor(type);
      expect(restoredPasses, hasLength(2));
      expect(restoredPasses.first.premiumUnlocked, isTrue);
      expect(restoredPasses.last.progress, 1);
    },
  );
}
