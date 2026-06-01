import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/app/lightcore_build_info.dart';
import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_guide.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/screens/lightcore_main_menu_screen.dart';
import 'package:lightcore/screens/lightcore_shell.dart';
import 'package:lightcore/services/lightcore_firebase_backend.dart';
import 'package:lightcore/services/lightcore_firebase_runtime_config.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

export 'package:lightcore/state/lightcore_controller.dart';

const lightcoreGoldenDesktopSize = Size(1200, 1000);
const lightcoreGoldenCompactSize = Size(430, 932);

final lightcoreGoldenGuestSession = LightcoreGuestSession(
  playerId: 'GX-74E2-A91C',
  createdAt: DateTime(2026, 4, 21, 12),
  authLabel: 'Guest session',
);

LightcoreBootstrapReport buildReadyBootstrapReport({
  String clientVersion = LightcoreBuildInfo.versionName,
  String clientBuildNumber = LightcoreBuildInfo.buildNumber,
  String recommendedVersion = LightcoreBuildInfo.versionName,
}) {
  return LightcoreBootstrapReport(
    guestSession: lightcoreGoldenGuestSession,
    clientVersion: clientVersion,
    clientBuildNumber: clientBuildNumber,
    manifest: LightcoreContentManifest(
      firebaseProjectId: 'lumicore-95c8a',
      seasonKey: 'season-01',
      contentEpoch: 7,
      minimumSupportedVersion: LightcoreBuildInfo.versionName,
      minimumSupportedBuildNumber: LightcoreBuildInfo.buildNumber,
      recommendedVersion: recommendedVersion,
      recommendedBuildNumber: LightcoreBuildInfo.buildNumber,
      backendMode: LightcoreBackendMode.localFallback,
      statusMessage: 'Ready to deploy.',
    ),
    profile: const LightcorePlayerProfileSummary(
      playerId: 'GX-74E2-A91C',
      authUid: 'auth-preview-7F31D9A2',
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
    serverValidated: true,
    appCheckActive: true,
  );
}

Widget buildReadyMainMenu({
  LightcoreGuideProfile? guideProfile = LightcoreGuideProfile.lumo,
  VoidCallback? onEnterGame,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTestLightcoreTheme(),
    home: LightcoreMainMenuScreen(
      guestSession: lightcoreGoldenGuestSession,
      bootstrapReport: buildReadyBootstrapReport(),
      guideProfile: guideProfile,
      isLoading: false,
      onEnterGame: onEnterGame ?? () {},
      onSelectGuide: (_) {},
      onRetryBootstrap: () {},
    ),
  );
}

Widget buildTestShell(LightcoreController controller) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTestLightcoreTheme(),
    home: LightcoreShell(
      controller: controller,
      backend: FirebaseLightcoreBackend(
        runtimeConfig: lightcoreFirebaseRuntimeConfig,
      ),
    ),
  );
}

Widget buildTestBattle(LightcoreController controller) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTestLightcoreTheme(),
    home: Scaffold(body: BattleScreen(controller: controller, isActive: true)),
  );
}

ThemeData buildTestLightcoreTheme() {
  final theme = buildLightcoreTheme();
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );
}

LightcoreController createDeterministicController() {
  final controller = LightcoreController(
    packRandom: Random(1101),
    traitRandom: Random(2202),
    managerRandom: Random(3303),
    spawnRandom: Random(4404),
    guideProfile: LightcoreGuideProfile.lumo,
    playerId: 'GX-74E2-A91C',
    screenName: 'Astra',
  );
  controller.debugDisableTutorial();
  return controller;
}

void preparePromotionReadyRing(LightcoreController controller) {
  controller.kills = max(
    LightcoreController.unlockKillsForOuterSlot(
      LightcoreController.slotCount - 1,
    ),
    LightcoreController.killsForOverallLevel(
      LightcoreController.managerUnlockLevel,
    ),
  );
  controller.lumens = 240000;
  controller.flux = 12000;
  controller.debugAddEnemyTickets(12);

  for (var index = 0; index < LightcoreController.slotCount; index++) {
    final config = TowerLibrary.all[index % TowerLibrary.all.length];
    controller.buildTowerAt(index, config);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }

  controller.dismissBanner();
}

void forgeLayer2(LightcoreController controller) {
  preparePromotionReadyRing(controller);
  controller.unlockLayer2Tower();
  controller.dismissBanner();
}

void stageBattleActivity(
  LightcoreController controller, {
  int frames = 90,
  double dt = 1 / 30,
}) {
  controller.selectCenter();
  controller.setEnemyTargetCount(min(8, controller.enemyTargetMax));
  for (var frame = 0; frame < frames; frame++) {
    controller.tick(dt);
  }
  controller.dismissBanner();
}

Future<void> pumpFixedFrame(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 300),
}) async {
  await tester.pump();
  final gameFinder = find.byType(GameWidget<LightcoreBattleGame>);
  if (gameFinder.evaluate().isNotEmpty) {
    final gameWidget = tester.widget<GameWidget<LightcoreBattleGame>>(
      gameFinder.first,
    );
    final game = gameWidget.game;
    if (game != null) {
      for (var frame = 0; frame < 30 && !game.isLoaded; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await tester.pump();
  }
  await tester.pump(duration);
}
