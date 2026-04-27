import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_social_state.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test('progression EXP unlocks slots without requiring raw kill count', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.unlockedOuterSlotCount, 1);

    controller.grantRewardedResources(
      experienceGranted: LightcoreController.unlockExperienceForOuterSlot(1),
      sourceLabel: 'Test',
    );

    expect(controller.kills, 0);
    expect(controller.progressionExperience, 100);
    expect(controller.unlockedOuterSlotCount, 2);
  });

  test('completed shared relay produces borrowers and alliance bonuses', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.experience = LightcoreController.unlockExperienceForOuterSlot(5);
    controller.lumens = 100000;
    for (var index = 0; index < LightcoreController.slotCount; index++) {
      expect(controller.buildTowerAt(index, TowerLibrary.all[index]), isTrue);
    }

    controller.autoFillSharedRelayTower();

    expect(controller.isSharedRelayComplete, isTrue);
    expect(controller.sharedRelayFilledPieceCount, 7);
    expect(controller.relayEligibleFriendCount, greaterThan(0));
    expect(controller.relayActiveBorrowerCount, greaterThan(0));
    expect(controller.sharedRelayExperienceMultiplier, greaterThan(1.0));
    expect(controller.friendAllianceCombatMultiplier, greaterThan(1.0));
    expect(controller.friendAllianceRewardMultiplier, greaterThan(1.0));
  });

  test('server social overview drives capped mentor multipliers', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.syncSocialOverview(
      const LightcoreSocialOverview(
        self: LightcoreSocialPlayer(
          uid: 'mentor',
          playerId: 'mentor',
          displayName: 'Mentor',
          level: 12,
          progressToNextLevel: 0.2,
          performanceScore: 0.5,
        ),
        directMentees: <LightcoreSocialPlayer>[
          LightcoreSocialPlayer(
            uid: 'mentee',
            playerId: 'mentee',
            displayName: 'Mentee',
            level: 11,
            progressToNextLevel: 0.7,
            performanceScore: 0.9,
            mentorUid: 'mentor',
            withinLevelBand: true,
            bonusActive: true,
          ),
        ],
        bonusProfile: LightcoreSocialBonusProfile(
          experienceMultiplier: 1.32,
          combatMultiplier: 1.11,
          rewardMultiplier: 1.08,
          activeDirectMentees: 1,
        ),
      ),
    );

    expect(controller.relayEligibleFriendCount, 1);
    expect(controller.relayActiveBorrowerCount, 1);
    expect(controller.sharedRelayExperienceMultiplier, 1.32);
    expect(controller.friendAllianceCombatMultiplier, 1.11);
    expect(controller.friendAllianceRewardMultiplier, 1.08);
  });

  test('Home Tower affinity shapes active mentor bonuses', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.mentorshipUnlockLevel,
    );
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
    controller.syncSocialOverview(
      const LightcoreSocialOverview(
        self: LightcoreSocialPlayer(
          uid: 'mentor',
          playerId: 'mentor',
          displayName: 'Mentor',
          level: 30,
          progressToNextLevel: 0.2,
          performanceScore: 0.5,
        ),
        directMentees: <LightcoreSocialPlayer>[
          LightcoreSocialPlayer(
            uid: 'mentee',
            playerId: 'mentee',
            displayName: 'Mentee',
            level: 30,
            progressToNextLevel: 0.7,
            performanceScore: 0.9,
            mentorUid: 'mentor',
            withinLevelBand: true,
            bonusActive: true,
          ),
        ],
        bonusProfile: LightcoreSocialBonusProfile(
          experienceMultiplier: 1.32,
          combatMultiplier: 1.11,
          rewardMultiplier: 1.08,
          activeDirectMentees: 1,
        ),
      ),
    );

    expect(controller.homeTowerLabel, 'Red Home Tower');
    expect(controller.homeTowerMentorCombatMultiplier, greaterThan(1.0));
    expect(controller.sharedRelayExperienceMultiplier, greaterThan(1.32));
    expect(controller.friendAllianceCombatMultiplier, greaterThan(1.11));
    expect(controller.friendAllianceRewardMultiplier, greaterThan(1.08));
  });

  test('social overview counts bulk boss gift actions', () {
    final overview = LightcoreSocialOverview(
      self: _socialPlayer('self'),
      friends: <LightcoreSocialFriend>[
        LightcoreSocialFriend(
          player: _socialPlayer('sent'),
          giftSentToday: true,
          giftAvailable: false,
          giftClaimedToday: false,
        ),
        LightcoreSocialFriend(
          player: _socialPlayer('incoming'),
          giftSentToday: false,
          giftAvailable: true,
          giftClaimedToday: false,
        ),
        LightcoreSocialFriend(
          player: _socialPlayer('ready'),
          giftSentToday: false,
          giftAvailable: false,
          giftClaimedToday: false,
        ),
      ],
    );

    expect(overview.availableBossGiftCount, 1);
    expect(overview.sendableBossGiftCount, 2);
  });

  test('bulk boss gift results update controller state', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final sentOverview = LightcoreSocialOverview(self: _socialPlayer('self'));
    controller.applySocialBossGiftSend(
      LightcoreBossGiftSendResult(
        sentCount: 2,
        skippedCount: 1,
        message: 'Sent 2 Apex Scan gifts.',
        overview: sentOverview,
      ),
    );

    expect(controller.socialOverview, sentOverview);
    expect(controller.bannerMessage, contains('Sent 2 Apex Scan gifts'));

    final claimedOverview = LightcoreSocialOverview(
      self: _socialPlayer('self'),
    );
    controller.applySocialBossGiftClaim(
      LightcoreBossGiftClaimResult(
        bossTicketsGranted: 2,
        message: 'Apex Scan gifts claimed: +2 Apex Scans.',
        overview: claimedOverview,
      ),
    );

    expect(controller.bossTickets, 2);
    expect(controller.socialOverview, claimedOverview);
    expect(controller.bannerMessage, contains('+2 Apex Scans'));
  });
}

LightcoreSocialPlayer _socialPlayer(String uid) {
  return LightcoreSocialPlayer(
    uid: uid,
    playerId: uid,
    displayName: uid,
    level: 10,
    progressToNextLevel: 0.5,
    performanceScore: 0.8,
  );
}
