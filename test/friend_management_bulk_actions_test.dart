import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/models/lightcore_social_invite_link.dart';
import 'package:lightcore/models/lightcore_social_state.dart';
import 'package:lightcore/screens/friend_management_screen.dart';
import 'package:lightcore/services/lightcore_firebase_backend.dart';
import 'package:lightcore/services/lightcore_firebase_runtime_config.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

void main() {
  testWidgets('friend daily apex scans expose send all and claim all', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1200));

    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final backend = _FakeFriendBackend(_overviewWithGiftState());

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: FriendManagementScreen(
            controller: controller,
            backend: backend,
            isActive: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Send All (2)'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Send All (2)'), findsOneWidget);
    expect(find.text('Claim All (1)'), findsOneWidget);

    await tester.tap(find.text('Send All (2)'));
    await tester.pump();
    await tester.pump();

    expect(backend.sendAllCalls, 1);
    expect(controller.bannerMessage, contains('Sent 2 Apex Scan gifts'));
    expect(find.text('Send All'), findsOneWidget);

    await tester.tap(find.text('Claim All (1)'));
    await tester.pump();
    await tester.pump();

    expect(backend.claimAllCalls, 1);
    expect(controller.bossTickets, 1);
    expect(controller.bannerMessage, contains('+1 Apex Scan'));
    expect(find.text('Claim All'), findsOneWidget);
  });

  testWidgets('friend invite links surface QR sharing and request action', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final backend = _FakeFriendBackend(_overviewWithGiftState());

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: FriendManagementScreen(
            controller: controller,
            backend: backend,
            isActive: true,
            initialInviteLink: const LightcoreSocialInviteLink(
              kind: LightcoreSocialInviteLinkKind.friend,
              target: 'ally-77',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Your Friend QR'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
    expect(find.text('Copy Code'), findsAtLeastNWidgets(1));
    expect(find.text('Friend Link Ready'), findsOneWidget);

    await tester.tap(find.text('Send Friend Request'));
    await tester.pump();
    await tester.pump();

    expect(backend.sentFriendTargets, <String>['ally-77']);
  });

  testWidgets('mentor manual entry accepts pasted invite links', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1200));

    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final backend = _FakeFriendBackend(_overviewWithGiftState());

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: FriendManagementScreen(
            controller: controller,
            backend: backend,
            isActive: true,
            section: FriendManagementSection.mentors,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'https://lumicore-95c8a.firebaseapp.com/?socialInvite=mentor&target=mentor-88',
    );
    await tester.scrollUntilVisible(
      find.text('Add Mentor'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add Mentor'));
    await tester.pump();
    await tester.pump();

    expect(backend.acceptedMentorTargets, <String>['mentor-88']);
  });

  testWidgets('mentor map pinches out to the mentor focus', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1200));

    final controller = LightcoreController();
    addTearDown(controller.dispose);
    final backend = _FakeFriendBackend(_overviewWithMentorTree());

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: FriendManagementScreen(
            controller: controller,
            backend: backend,
            isActive: true,
            section: FriendManagementSection.mentors,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Mentorship Hex Map'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final map = find.byKey(const ValueKey<String>('mentor-hex-map-viewport'));
    expect(map, findsOneWidget);

    final center = tester.getCenter(map);
    final first = await tester.createGesture(pointer: 11);
    final second = await tester.createGesture(pointer: 12);
    await first.down(center + const Offset(-150, 0));
    await second.down(center + const Offset(150, 0));
    await tester.pump();
    await first.moveTo(center + const Offset(-24, 0));
    await second.moveTo(center + const Offset(24, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Mentor Tower Hex'), findsOneWidget);
  });
}

class _FakeFriendBackend extends FirebaseLightcoreBackend {
  _FakeFriendBackend(this.overview)
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  LightcoreSocialOverview overview;
  int sendAllCalls = 0;
  int claimAllCalls = 0;
  final List<String> sentFriendTargets = <String>[];
  final List<String> acceptedMentorTargets = <String>[];

  @override
  Future<LightcoreSocialOverview> fetchSocialOverview() async => overview;

  @override
  Future<LightcoreSocialOverview> sendFriendRequest({
    required String target,
  }) async {
    sentFriendTargets.add(target);
    return overview;
  }

  @override
  Future<LightcoreSocialOverview> acceptMentorLink({
    required String mentor,
  }) async {
    acceptedMentorTargets.add(mentor);
    return overview;
  }

  @override
  Future<LightcoreBossGiftSendResult> sendAllBossPullGifts() async {
    sendAllCalls += 1;
    overview = _overviewWithGiftState(allSent: true);
    return LightcoreBossGiftSendResult(
      sentCount: 2,
      skippedCount: 1,
      message: 'Sent 2 Apex Scan gifts.',
      overview: overview,
    );
  }

  @override
  Future<LightcoreBossGiftClaimResult> claimAllBossPullGifts() async {
    claimAllCalls += 1;
    overview = _overviewWithGiftState(allSent: true, allClaimed: true);
    return LightcoreBossGiftClaimResult(
      bossTicketsGranted: 1,
      message: 'Apex Scan gifts claimed: +1 Apex Scan.',
      overview: overview,
    );
  }
}

LightcoreSocialOverview _overviewWithGiftState({
  bool allSent = false,
  bool allClaimed = false,
}) {
  return LightcoreSocialOverview(
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
        giftSentToday: allSent,
        giftAvailable: !allClaimed,
        giftClaimedToday: allClaimed,
      ),
      LightcoreSocialFriend(
        player: _socialPlayer('ready'),
        giftSentToday: allSent,
        giftAvailable: false,
        giftClaimedToday: false,
      ),
    ],
  );
}

LightcoreSocialOverview _overviewWithMentorTree() {
  return LightcoreSocialOverview(
    self: _socialPlayer('self', mentorUid: 'mentor'),
    mentor: _socialPlayer('mentor'),
    directMentees: <LightcoreSocialPlayer>[
      _socialPlayer('alpha', mentorUid: 'self', bonusActive: true),
      _socialPlayer('beta', mentorUid: 'self'),
    ],
    grandMentees: <LightcoreSocialPlayer>[
      _socialPlayer('gamma', mentorUid: 'alpha'),
    ],
  );
}

LightcoreSocialPlayer _socialPlayer(
  String uid, {
  String? mentorUid,
  bool withinLevelBand = true,
  bool bonusActive = false,
}) {
  return LightcoreSocialPlayer(
    uid: uid,
    playerId: uid,
    displayName: uid,
    level: 10,
    progressToNextLevel: 0.5,
    performanceScore: 0.8,
    mentorUid: mentorUid,
    withinLevelBand: withinLevelBand,
    bonusActive: bonusActive,
  );
}
