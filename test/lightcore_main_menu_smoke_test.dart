import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/models/lightcore_guide.dart';
import 'package:lightcore/screens/lightcore_main_menu_screen.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

void main() {
  final guestSession = LightcoreGuestSession(
    playerId: 'GX-74E2-A91C',
    createdAt: DateTime(2026, 4, 21, 12),
    authLabel: 'Guest session',
  );

  Widget buildMenu({
    required LightcoreBootstrapReport report,
    LightcoreGuideProfile? guideProfile = LightcoreGuideProfile.lumo,
    bool isLoading = false,
    bool skipGuestSignInPrompt = false,
    String? sessionNotice,
    VoidCallback? onEnterGame,
    VoidCallback? onRetryBootstrap,
    Future<bool> Function()? onGoogleSignIn,
    ValueChanged<bool>? onSkipGuestSignInPromptChanged,
  }) {
    return MaterialApp(
      theme: buildLightcoreTheme(),
      home: LightcoreMainMenuScreen(
        guestSession: guestSession,
        bootstrapReport: report,
        guideProfile: guideProfile,
        isLoading: isLoading,
        onEnterGame: onEnterGame ?? () {},
        onSelectGuide: (_) {},
        onRetryBootstrap: onRetryBootstrap ?? () {},
        sessionNotice: sessionNotice,
        skipGuestSignInPrompt: skipGuestSignInPrompt,
        onGoogleSignIn: onGoogleSignIn,
        onSkipGuestSignInPromptChanged: onSkipGuestSignInPromptChanged,
      ),
    );
  }

  LightcoreBootstrapReport buildReport({
    required String clientVersion,
    required String recommendedVersion,
    String? clientBuildNumber,
    String minimumSupportedVersion = '1.0.0',
    String? minimumSupportedBuildNumber,
    String? recommendedBuildNumber,
    LightcoreBackendMode backendMode = LightcoreBackendMode.localFallback,
    bool serverValidated = true,
    bool isAnonymous = true,
  }) {
    return LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: clientVersion,
      clientBuildNumber: clientBuildNumber,
      manifest: LightcoreContentManifest(
        firebaseProjectId: 'lumicore-95c8a',
        seasonKey: 'season-01',
        contentEpoch: 7,
        minimumSupportedVersion: minimumSupportedVersion,
        minimumSupportedBuildNumber: minimumSupportedBuildNumber,
        recommendedVersion: recommendedVersion,
        recommendedBuildNumber: recommendedBuildNumber,
        backendMode: backendMode,
        statusMessage: 'Ready to deploy.',
      ),
      profile: LightcorePlayerProfileSummary(
        playerId: 'GX-74E2-A91C',
        authUid: 'auth-preview-7F31D9A2',
        isAnonymous: isAnonymous,
      ),
      offlineClaim: const LightcoreOfflineClaimResult(
        secondsClaimed: 5400,
        lumensGranted: 320,
        fluxGranted: 190,
        enemyTicketsGranted: 2,
        killsGranted: 74,
        serverValidated: true,
        statusMessage: 'Offline rewards queued.',
      ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: serverValidated,
      appCheckActive: true,
    );
  }

  testWidgets('main menu pumps without throwing', (tester) async {
    final report = buildReport(
      clientVersion: '1.0.18',
      clientBuildNumber: '19',
      minimumSupportedVersion: '1.0.18',
      minimumSupportedBuildNumber: '19',
      recommendedVersion: '1.0.18',
      recommendedBuildNumber: '19',
    );

    await tester.pumpWidget(buildMenu(report: report));

    expect(tester.takeException(), isNull);
    expect(find.text('Lumi Core'), findsOneWidget);
    expect(find.text('BETA'), findsOneWidget);
    expect(find.text('Authentication ID'), findsOneWidget);
    expect(find.text('V1.0.18+19'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('CACHE RESTORED'), findsOneWidget);
    expect(find.text('VERSION BLOCKED'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('main menu blocks an outdated live version', (tester) async {
    final report = buildReport(
      clientVersion: '1.0.0',
      recommendedVersion: '1.1.0',
    );

    await tester.pumpWidget(buildMenu(report: report));

    expect(find.text('VERSION BLOCKED'), findsOneWidget);
    expect(
      find.text('Your version is older than the required server version.'),
      findsOneWidget,
    );
    expect(find.text('Current 1.0.0', findRichText: true), findsOneWidget);
    expect(
      find.text('Required server 1.1.0', findRichText: true),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('main menu blocks launch without server validation', (
    tester,
  ) async {
    var entered = false;
    final report = buildReport(
      clientVersion: '1.0.18',
      clientBuildNumber: '19',
      minimumSupportedVersion: '1.0.18',
      minimumSupportedBuildNumber: '19',
      recommendedVersion: '1.0.18',
      recommendedBuildNumber: '19',
      backendMode: LightcoreBackendMode.firebaseBacked,
      serverValidated: false,
    );

    await tester.pumpWidget(
      buildMenu(report: report, onEnterGame: () => entered = true),
    );

    expect(find.text('INTERNET REQUIRED'), findsWidgets);
    expect(find.text('Internet connection required.'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);

    await tester.tap(find.text('LOCKED'));
    await tester.pump();

    expect(entered, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('main menu blocks launch after session expiration', (
    tester,
  ) async {
    var entered = false;
    var reconnects = 0;
    final report = buildReport(
      clientVersion: '1.0.18',
      clientBuildNumber: '19',
      minimumSupportedVersion: '1.0.18',
      minimumSupportedBuildNumber: '19',
      recommendedVersion: '1.0.18',
      recommendedBuildNumber: '19',
    );

    await tester.pumpWidget(
      buildMenu(
        report: report,
        sessionNotice:
            'Session expired. Reconnect to claim server-calculated offline progress.',
        onEnterGame: () => entered = true,
        onRetryBootstrap: () {
          reconnects += 1;
        },
      ),
    );

    expect(find.text('SESSION EXPIRED'), findsOneWidget);
    expect(find.text('EXPIRED'), findsOneWidget);
    expect(find.text('RECONNECT TO CLAIM PROGRESS'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);

    await tester.tap(find.text('LOCKED'));
    await tester.pump();

    expect(entered, isFalse);

    await tester.tap(find.text('Reconnect'));
    await tester.pump();

    expect(reconnects, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('guest play shows sign-in prompt and can continue as guest', (
    tester,
  ) async {
    var entered = false;
    var googleSignInCalls = 0;
    var skippedPrompt = false;
    final report = buildReport(
      clientVersion: '1.0.18',
      clientBuildNumber: '19',
      recommendedVersion: '1.0.18',
      recommendedBuildNumber: '19',
    );

    await tester.pumpWidget(
      buildMenu(
        report: report,
        onEnterGame: () => entered = true,
        onGoogleSignIn: () async {
          googleSignInCalls += 1;
          return true;
        },
        onSkipGuestSignInPromptChanged: (value) {
          skippedPrompt = value;
        },
      ),
    );

    expect(find.text('Sign In With Google'), findsNothing);

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Save Recovery'), findsOneWidget);
    expect(find.text('Sign In With Google'), findsOneWidget);
    expect(find.text('Continue As Guest'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('guest-sign-in-dont-ask-toggle')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('guest-sign-in-continue-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(entered, isTrue);
    expect(skippedPrompt, isTrue);
    expect(googleSignInCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('guest play can sign in with Google from prompt', (tester) async {
    var entered = false;
    var googleSignInCalls = 0;
    var skippedPrompt = false;
    final report = buildReport(
      clientVersion: '1.0.18',
      clientBuildNumber: '19',
      recommendedVersion: '1.0.18',
      recommendedBuildNumber: '19',
    );

    await tester.pumpWidget(
      buildMenu(
        report: report,
        onEnterGame: () => entered = true,
        onGoogleSignIn: () async {
          googleSignInCalls += 1;
          return true;
        },
        onSkipGuestSignInPromptChanged: (value) {
          skippedPrompt = value;
        },
      ),
    );

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(
      find.byKey(const ValueKey<String>('guest-sign-in-google-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(entered, isTrue);
    expect(googleSignInCalls, 1);
    expect(skippedPrompt, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('signed-in play bypasses guest sign-in prompt', (tester) async {
    var entered = false;
    var googleSignInCalls = 0;
    final report = buildReport(
      clientVersion: '1.0.18',
      clientBuildNumber: '19',
      recommendedVersion: '1.0.18',
      recommendedBuildNumber: '19',
      isAnonymous: false,
    );

    await tester.pumpWidget(
      buildMenu(
        report: report,
        onEnterGame: () => entered = true,
        onGoogleSignIn: () async {
          googleSignInCalls += 1;
          return true;
        },
      ),
    );

    await tester.tap(find.text('PLAY'));
    await tester.pump();

    expect(find.text('Save Recovery'), findsNothing);
    expect(entered, isTrue);
    expect(googleSignInCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('guide chooser stays inline on narrow layouts', (tester) async {
    final report = buildReport(
      clientVersion: '1.0.0',
      recommendedVersion: '1.0.0',
    );

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(buildMenu(report: report, guideProfile: null));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('GUIDE'), findsNothing);
    expect(find.text('Authentication ID'), findsOneWidget);

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Choose Guide'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
