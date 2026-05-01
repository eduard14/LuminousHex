import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lightcore/app/lightcore_bootstrap.dart';
import 'package:lightcore/app/lightcore_app.dart';
import 'package:lightcore/battle/lightcore_battle_game.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_cloud_save.dart';
import 'package:lightcore/models/lightcore_guide.dart';
import 'package:lightcore/models/lightcore_social_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/screens/daily_dungeons_screen.dart';
import 'package:lightcore/screens/lightcore_shell.dart';
import 'package:lightcore/services/lightcore_firebase_backend.dart';
import 'package:lightcore/services/lightcore_firebase_runtime_config.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_icons.dart';
import 'package:lightcore/theme/lightcore_theme.dart';
import 'package:lightcore/widgets/meta_progression_sheet.dart';

Future<void> _pumpShell(
  WidgetTester tester,
  LightcoreController controller, {
  bool disableTutorial = true,
  String? clientDisplayVersion,
  AsyncCallback? onGoogleSignIn,
  AsyncCallback? onSignOut,
}) async {
  if (disableTutorial) {
    controller.debugDisableTutorial();
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightcoreTheme(),
      home: LightcoreShell(
        controller: controller,
        backend: FirebaseLightcoreBackend(
          runtimeConfig: lightcoreFirebaseRuntimeConfig,
        ),
        clientDisplayVersion: clientDisplayVersion,
        onGoogleSignIn: onGoogleSignIn,
        onSignOut: onSignOut,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpBattleScreen(
  WidgetTester tester,
  LightcoreController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightcoreTheme(),
      home: Scaffold(
        body: BattleScreen(controller: controller, isActive: true),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 240));
}

double _scrollOffsetForKey(WidgetTester tester, Key key) {
  final scrollable = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Scrollable),
  );
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

Future<void> _scrollSettingsUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey<String>('settings-scroll-view')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
}

Future<void> _openHeaderMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open Menu'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 240));
}

Future<void> _openSettingsFromHeaderMenu(WidgetTester tester) async {
  await _openHeaderMenu(tester);
  await tester.tap(find.text('Settings'));
  await _pumpTransition(tester);
}

Future<void> _openHeaderMenuDestination(
  WidgetTester tester,
  String label,
) async {
  await _openHeaderMenu(tester);
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void _promoteRootShell(LightcoreController controller) {
  controller.lumens = 100000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  controller.unlockLayer2Tower();
}

Future<void> _waitForMainMenu(WidgetTester tester) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.text('Lumi Core').evaluate().isNotEmpty) {
      break;
    }
  }
}

void main() {
  testWidgets('renders the Lightcore main menu', (tester) async {
    await tester.pumpWidget(const LightcoreApp());
    await tester.pump();
    await _waitForMainMenu(tester);

    expect(find.text('Lumi Core'), findsOneWidget);
    expect(find.text('Authentication ID'), findsOneWidget);
  });

  testWidgets('renders compact main menu layout without overflow', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));

    await tester.pumpWidget(const LightcoreApp());
    await tester.pump();
    await _waitForMainMenu(tester);

    expect(find.text('Lumi Core'), findsOneWidget);
    expect(find.text('Authentication ID'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('defers notification rebuilds triggered during build', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    var pushedNotification = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (!pushedNotification) {
              pushedNotification = true;
              controller.pushNotification('Build-safe notification');
            }
            return Text(
              controller.bannerMessage.isEmpty
                  ? 'No notification'
                  : controller.bannerMessage,
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Build-safe notification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session expiry during shell link stays on main menu', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    PackageInfo.setMockInitialValues(
      appName: 'LumiHex',
      packageName: 'com.lightcore.test',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
    });
    final backend = _ExpiringSessionBackend();

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);
    for (var attempt = 0; attempt < 30; attempt += 1) {
      if (find.text('PLAY', skipOffstage: false).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('PLAY', skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('PLAY', skipOffstage: false));
    await tester.pump();

    expect(find.text('Opening Shell'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Lumi Core'), findsOneWidget);
    expect(find.byType(LightcoreShell), findsNothing);
    expect(backend.syncCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bootstrap errors render retryable main menu', (tester) async {
    final backend = _ThrowingBootstrapBackend();

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);

    expect(find.text('Lumi Core'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('PLAY'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session expiry after resume returns from shell to main menu', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    PackageInfo.setMockInitialValues(
      appName: 'LumiHex',
      packageName: 'com.lightcore.test',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
    });
    final backend = _ExpiringSessionBackend(expireOnSync: false);

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);
    for (var attempt = 0; attempt < 30; attempt += 1) {
      if (find.text('PLAY', skipOffstage: false).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('PLAY', skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LightcoreShell), findsOneWidget);

    backend.expireOnClaim = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Lumi Core'), findsOneWidget);
    expect(find.byType(LightcoreShell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('main menu Google sign-in failure does not throw', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    PackageInfo.setMockInitialValues(
      appName: 'LumiHex',
      packageName: 'com.lightcore.test',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
    });
    final backend = _GoogleSignInFailureBackend();

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);
    for (var attempt = 0; attempt < 30; attempt += 1) {
      if (find.text('PLAY', skipOffstage: false).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('PLAY', skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Save Recovery'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('guest-sign-in-google-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('Google sign-in failed'), findsOneWidget);
    expect(find.byType(LightcoreShell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'foreground resume during Google sign-in does not start a stale bootstrap',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(430, 780));
      PackageInfo.setMockInitialValues(
        appName: 'LumiHex',
        packageName: 'com.lightcore.test',
        version: '1.0.6',
        buildNumber: '7',
        buildSignature: '',
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
      });
      final backend = _PendingGoogleSignInBackend();

      await tester.pumpWidget(LightcoreApp(backend: backend));
      await tester.pump();
      await _waitForMainMenu(tester);
      for (var attempt = 0; attempt < 30; attempt += 1) {
        if (find.text('PLAY', skipOffstage: false).evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.text('PLAY', skipOffstage: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Save Recovery'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('guest-sign-in-google-button')),
      );
      await tester.pump();
      expect(backend.signInCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));

      expect(backend.bootstrapCalls, 1);

      backend.completeGoogleSignIn();
      for (var attempt = 0; attempt < 30; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(LightcoreShell).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(backend.bootstrapCalls, 3);
      expect(find.byType(LightcoreShell), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('foreground resume remounts the battle renderer surface', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    PackageInfo.setMockInitialValues(
      appName: 'LumiHex',
      packageName: 'com.lightcore.test',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
    });
    final backend = _ExpiringSessionBackend(expireOnSync: false);

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);
    for (var attempt = 0; attempt < 30; attempt += 1) {
      if (find.text('PLAY', skipOffstage: false).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('PLAY', skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final gameFinder = find.byType(GameWidget<LightcoreBattleGame>);
    expect(gameFinder, findsOneWidget);
    final initialElement = tester.element(gameFinder);
    final initialGame = tester
        .widget<GameWidget<LightcoreBattleGame>>(gameFinder)
        .game;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LightcoreShell), findsOneWidget);
    expect(gameFinder, findsOneWidget);
    expect(tester.element(gameFinder), isNot(same(initialElement)));
    expect(
      tester.widget<GameWidget<LightcoreBattleGame>>(gameFinder).game,
      isNot(same(initialGame)),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('battle canvas clears abandoned tap on lifecycle resume', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 780));
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();

    await _pumpBattleScreen(tester, controller);
    await tester.pump(const Duration(milliseconds: 100));

    final gameFinder = find.byType(GameWidget<LightcoreBattleGame>);
    expect(gameFinder, findsOneWidget);
    final center = tester.getCenter(gameFinder);

    final interruptedTap = await tester.createGesture(pointer: 1);
    await interruptedTap.down(center);
    await tester.pump();
    expect(controller.outerRingRevealed, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    final resumedTap = await tester.createGesture(pointer: 2);
    await resumedTap.down(center);
    await resumedTap.up();
    await interruptedTap.cancel();
    await tester.pump();

    expect(controller.outerRingRevealed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enter game refreshes bootstrap before restoring shell', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'LumiHex',
      packageName: 'com.lightcore.test',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
    });
    final backend = _RefreshingLaunchBackend();

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);
    for (var attempt = 0; attempt < 30; attempt += 1) {
      if (find.text('PLAY', skipOffstage: false).evaluate().isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.text('PLAY', skipOffstage: false));
    await tester.pump();
    expect(find.text('Opening Shell'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(backend.bootstrapCalls, 2);
    final shell = tester.widget<LightcoreShell>(find.byType(LightcoreShell));
    expect(shell.controller.lumens, 802);
    expect(shell.controller.swarmActivated, isTrue);
    expect(find.text('Offline Gains'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('main menu keeps play hidden when cloud restore fails', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'LumiHex',
      packageName: 'com.lightcore.test',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lightcore.guide_id': LightcoreGuideProfile.lumo.storageId,
    });
    final backend = _CloudRestoreFailureLaunchBackend();

    await tester.pumpWidget(LightcoreApp(backend: backend));
    await tester.pump();
    await _waitForMainMenu(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(backend.bootstrapCalls, 1);
    expect(backend.saveCalls, 0);
    expect(find.text('PLAY', skipOffstage: false), findsNothing);
    expect(find.byType(LightcoreShell), findsNothing);
    expect(find.text('Lumi Core'), findsOneWidget);
    expect(
      find.textContaining('Cloud save restore did not finish'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows offline gains dialog on initial shell entry', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    final claim = LightcoreOfflineClaimResult(
      secondsClaimed: 5400,
      lumensGranted: 120,
      fluxGranted: 18,
      enemyTicketsGranted: 3,
      killsGranted: 0,
      serverValidated: true,
      statusMessage: 'Claim validated before battle resumed.',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: LightcoreShell(
          controller: controller,
          backend: FirebaseLightcoreBackend(
            runtimeConfig: lightcoreFirebaseRuntimeConfig,
          ),
          initialOfflineClaim: claim,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Offline Gains'), findsOneWidget);
    expect(find.text('+120'), findsOneWidget);
    expect(find.text('Enter Shell'), findsOneWidget);
  });

  testWidgets('tower navigation stays locked until Prism Shell is forged', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    expect(
      find.text('Tower Archive Locked', skipOffstage: false),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Towers').first);
    await tester.pump();

    expect(
      controller.bannerMessage,
      contains('Towers unlock when Layer 2 is online'),
    );
    expect(
      find.text('Tower Archive Locked', skipOffstage: false),
      findsNothing,
    );
    expect(find.byTooltip('Return to Base Game'), findsNothing);

    _promoteRootShell(controller);
    await tester.pump();

    await tester.tap(find.byTooltip('Towers').first);
    await _pumpTransition(tester);

    expect(find.text('Completed Layer 1 Sets'), findsOneWidget);
    expect(find.byTooltip('Return to Base Game'), findsOneWidget);

    await tester.tap(find.byTooltip('Return to Base Game'));
    await _pumpTransition(tester);

    expect(
      find.text('Tower Archive Locked', skipOffstage: false),
      findsNothing,
    );
    expect(find.byTooltip('Battle'), findsOneWidget);
  });

  testWidgets('tournament overlay opens before level 20 for testing', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    await _openHeaderMenuDestination(tester, 'Tournaments');

    expect(
      controller.bannerMessage,
      contains('Set a screen name in Settings before entering tournaments.'),
    );

    controller.setScreenName('Nova Relay', showBanner: false);

    await _openHeaderMenuDestination(tester, 'Tournaments');

    expect(find.byTooltip('Return to Base Game'), findsOneWidget);
  });

  testWidgets('daily dungeon overlay opens before level 15 for testing', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    await _openHeaderMenuDestination(tester, 'Daily Dungeons');

    expect(find.text('Daily Dungeons'), findsOneWidget);
    expect(find.text('Threat Director'), findsWidgets);
    expect(find.text('Prism Rift'), findsWidgets);
    expect(find.text('Open'), findsNWidgets(2));
    expect(find.text('Sealed'), findsOneWidget);
  });

  testWidgets('mentorship overlay unlocks at level 30', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    await _openHeaderMenuDestination(tester, 'Mentorship');

    expect(
      controller.bannerMessage,
      contains('Mentorship unlocks at Account Radiance Lv 30'),
    );
    expect(find.text('Add Mentor Manually', skipOffstage: false), findsNothing);

    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.mentorshipUnlockLevel,
    );

    await _openHeaderMenuDestination(tester, 'Mentorship');

    expect(find.byTooltip('Return to Base Game'), findsOneWidget);
    expect(find.text('Add Mentor Manually'), findsOneWidget);
  });

  testWidgets('threat director dungeon opens dedicated run screen', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.dailyDungeonUnlockLevel,
    );
    controller.debugSetEnemyCardLevel(EnemyLibrary.basicWhite.id, level: 1);
    controller.debugSetEnemyCardLevel(EnemyLibrary.basicRed.id, level: 1);
    final orangeBasic = EnemyLibrary.all.firstWhere(
      (config) =>
          config.rarity == EnemyCardRarity.basic &&
          config.affinity == PrototypeAffinity.flare,
    );
    controller.debugSetEnemyCardLevel(orangeBasic.id, level: 1);

    await _pumpShell(tester, controller);
    await _openHeaderMenuDestination(tester, 'Daily Dungeons');

    await tester.scrollUntilVisible(
      find.text('Enter Lv 1'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    await tester.tap(find.text('Enter Lv 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 620));

    expect(find.text('Threat Director Lv 1'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().startsWith('GameWidget<'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Back to dungeons'), findsOneWidget);
    expect(find.text('WHT'), findsWidgets);
    expect(find.text('RED'), findsWidgets);
    expect(find.text('Ready'), findsWidgets);
    expect(find.byTooltip('Open Menu'), findsNothing);
  });

  testWidgets('prism rift dungeon opens battle run screen', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.dailyDungeonUnlockLevel,
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: DailyDungeonsScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find
          .ancestor(of: find.text('Prism Rift'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Enter Rift Lv 1'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Enter Rift Lv 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 620));

    expect(find.text('Prism Rift Lv 1'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().startsWith('GameWidget<'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Back to dungeons'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.textContaining('clears'), findsOneWidget);
    expect(find.textContaining('% core'), findsOneWidget);
    expect(find.byTooltip('Open Menu'), findsNothing);
  });

  testWidgets('shell navigation stays hidden until Prism Shell is forged', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    expect(find.byTooltip('Open shells'), findsNothing);

    _promoteRootShell(controller);
    await tester.pump();

    expect(find.byTooltip('Open shells'), findsOneWidget);

    await tester.tap(find.byTooltip('Towers').first);
    await _pumpTransition(tester);

    expect(find.byTooltip('Shells'), findsOneWidget);

    await tester.tap(find.byTooltip('Shells'));
    await _pumpTransition(tester);

    expect(find.text('Shell Map'), findsOneWidget);
    expect(find.text('Current Shell Focus'), findsOneWidget);
    expect(find.text('Active Route'), findsOneWidget);
    expect(find.text('Root Shell'), findsOneWidget);
  });

  testWidgets(
    'creating Prism Shell closes advancement and opens battle core stats',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(900, 1100));

      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.debugDisableTutorial();
      controller.lumens = 100000;
      controller.kills = LightcoreController.unlockKillsForOuterSlot(
        LightcoreController.slotCount - 1,
      );
      for (var index = 0; index < LightcoreController.slotCount; index++) {
        controller.buildTowerAt(index, TowerLibrary.all[index]);
        while (controller.slots[index].level <
            LightcoreController.maxTowerLevel) {
          controller.upgradeTower(index);
        }
      }
      controller.dismissBanner();

      await _pumpShell(tester, controller);

      await tester.tap(find.byTooltip('Advance'));
      await _pumpTransition(tester);

      final createPrismButton = find.text('Create Prism Shell');
      final prestigeScroll = find.byKey(
        const PageStorageKey<String>('prestige-scroll'),
      );
      final prestigeScrollable = find.descendant(
        of: prestigeScroll,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        createPrismButton,
        320,
        scrollable: prestigeScrollable,
      );
      await tester.pump();

      await tester.tap(createPrismButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 460));
      await tester.pump(const Duration(milliseconds: 320));

      expect(controller.activeLayer.label, 'Prism Shell');

      expect(find.text('Advancement Path'), findsNothing);
      expect(find.byTooltip('Open Store'), findsNothing);
      expect(find.text('Core Upgrades'), findsNothing);

      await tester.pump(const Duration(seconds: 4));

      expect(find.byTooltip('Open Store'), findsOneWidget);
      expect(find.text('Core Upgrades'), findsOneWidget);
      expect(find.text('Prism Shell'), findsWidgets);
    },
  );

  test('shell visibility changes do not show notifications', () {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.debugDisableTutorial();
    controller.dismissBanner();

    controller.selectCenter();
    expect(controller.bannerMessage, isEmpty);

    controller.toggleShellVisibility();
    expect(controller.bannerMessage, isEmpty);
  });

  testWidgets(
    'locked navigation features show their unlock conditions instead of opening',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      await _pumpShell(tester, controller);

      await tester.tap(find.byTooltip('Towers').first);
      await tester.pump();

      expect(
        controller.bannerMessage,
        contains('Towers unlock when Layer 2 is online'),
      );
      expect(
        find.text('Completed Layer 1 Sets', skipOffstage: false),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Managers').first);
      await tester.pump();

      expect(
        controller.bannerMessage,
        contains(
          'Manager assignment unlocks when the active core reaches Lv ${LightcoreController.managerCoreLevelRequirement}',
        ),
      );
      expect(find.text('Main Manager', skipOffstage: false), findsNothing);

      await _openHeaderMenuDestination(tester, 'Daily Dungeons');

      expect(find.text('Daily Dungeons'), findsOneWidget);

      await tester.tap(find.byTooltip('Return to Base Game'));
      await _pumpTransition(tester);

      await tester.tap(find.byTooltip('Advance').first);
      await tester.pump();

      expect(
        controller.bannerMessage,
        contains('Advancement unlocks after all 6 edge towers are built'),
      );
      expect(find.text('Advancement Path', skipOffstage: false), findsNothing);
    },
  );

  testWidgets('header pulls action opens the summon sheet', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    final pullsButton = find.byTooltip(
      'Open Scans (${controller.enemyTickets} scans ready)',
    );

    expect(pullsButton, findsOneWidget);

    await tester.tap(pullsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Threat Scans'), findsOneWidget);
  });

  testWidgets(
    'header hamburger menu exposes settings social and event entries',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      await _pumpShell(tester, controller);

      expect(find.byTooltip('Mentorship'), findsNothing);
      expect(find.byTooltip('Dungeons'), findsNothing);
      expect(find.byTooltip('Tournament'), findsNothing);

      await _openHeaderMenu(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Space Room'), findsOneWidget);
      expect(find.text('Mentorship'), findsOneWidget);
      expect(find.text('Daily Dungeons'), findsOneWidget);
      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);

      await tester.tap(find.text('Friends'));
      await _pumpTransition(tester);

      expect(find.byTooltip('Return to Base Game'), findsOneWidget);
    },
  );

  testWidgets('global leaderboard opens from hamburger menu', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LightcoreController(screenName: 'Pilot Hex');
    addTearDown(controller.dispose);
    controller.syncSocialOverview(
      const LightcoreSocialOverview(
        self: LightcoreSocialPlayer(
          uid: 'self',
          playerId: 'LUMI-SELF',
          displayName: 'Pilot Hex',
          level: 18,
          progressToNextLevel: 0.4,
          performanceScore: 0.72,
          towerStrength: 1200,
          towerStrengthRank: 2,
          towerStrengthRankedPlayers: 31,
        ),
        globalTowerStrengthLeaderboard: <LightcoreSocialPlayer>[
          LightcoreSocialPlayer(
            uid: 'nova',
            playerId: 'LUMI-NOVA',
            displayName: 'Nova Prime',
            level: 44,
            progressToNextLevel: 0.82,
            performanceScore: 0.94,
            towerStrength: 2500,
            towerStrengthRank: 1,
            towerStrengthRankedPlayers: 31,
          ),
          LightcoreSocialPlayer(
            uid: 'self',
            playerId: 'LUMI-SELF',
            displayName: 'Pilot Hex',
            level: 18,
            progressToNextLevel: 0.4,
            performanceScore: 0.72,
            towerStrength: 1200,
            towerStrengthRank: 2,
            towerStrengthRankedPlayers: 31,
          ),
        ],
      ),
    );

    await _pumpShell(tester, controller);
    await _openHeaderMenu(tester);
    await tester.tap(find.text('Leaderboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(find.text('Global Leaderboard'), findsOneWidget);
    expect(find.text('Nova Prime'), findsOneWidget);
    expect(find.text('Pilot Hex'), findsWidgets);
    expect(find.text('#2 of 31'), findsOneWidget);
    expect(find.text('TS 2.5k'), findsOneWidget);
  });

  testWidgets('space room opens from hamburger and sends channel chat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = LightcoreController(screenName: 'Pilot Hex');
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);
    await _openHeaderMenuDestination(tester, 'Space Room');

    expect(find.text('Space Room'), findsOneWidget);
    expect(find.text('Aurora Drift 5/8'), findsOneWidget);
    expect(find.text('Room Chat'), findsOneWidget);
    expect(find.text('Players and Managers'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('space-room-chat-field')),
      'Signal check',
    );
    await tester.tap(find.byTooltip('Send chat'));
    await tester.pump();

    expect(find.text('Signal check'), findsOneWidget);
  });

  testWidgets('battle keeps the resource rail while settings opens stats', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.grantRewardedResources(
      killsGranted: 12,
      sourceLabel: 'Test rewards',
    );
    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 3600,
        lumensGranted: 20,
        fluxGranted: 5,
        enemyTicketsGranted: 1,
        killsGranted: 0,
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.buildTowerAt(0, TowerLibrary.all.first);

    await _pumpShell(tester, controller);

    expect(find.byTooltip('Open Stats'), findsNothing);
    expect(find.byTooltip('Open Help'), findsNothing);
    expect(find.byTooltip('Open Menu'), findsOneWidget);
    expect(find.byTooltip('Open Settings'), findsNothing);
    expect(
      find.byTooltip(controller.globalTowerStrengthRankingTooltip),
      findsOneWidget,
    );
    expect(
      find.byTooltip('TS: ${controller.towerStrengthLabel}'),
      findsOneWidget,
    );
    expect(find.byTooltip('Lumen: ${controller.lumens}'), findsOneWidget);
    expect(find.byTooltip('Flux: ${controller.flux}'), findsOneWidget);
    expect(find.byTooltip('Scans: ${controller.enemyTickets}'), findsNothing);
    expect(
      find.byTooltip(
        'Output Efficiency: ${controller.outputEfficiencyLabel} • Core Stability ${controller.coreStabilityLabel}',
      ),
      findsOneWidget,
    );

    await _openSettingsFromHeaderMenu(tester);
    await _scrollSettingsUntilVisible(tester, find.text('Stats'));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.byTooltip('Open Help'), findsOneWidget);
    await tester.tap(find.text('Stats'));
    await _pumpTransition(tester);

    expect(find.text('Run Ledger'), findsOneWidget);
    expect(find.text('Anomalies Resolved'), findsOneWidget);
    expect(find.text('Offline Time Claimed'), findsOneWidget);
    expect(find.text('Upgrades Bought'), findsOneWidget);
  });

  testWidgets('settings help action opens the field guide', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    await _openSettingsFromHeaderMenu(tester);
    await _scrollSettingsUntilVisible(tester, find.byTooltip('Open Help'));
    await tester.tap(find.byTooltip('Open Help'));
    await _pumpTransition(tester);

    expect(
      find.text('${controller.guideProfile.displayName} Field Guide'),
      findsOneWidget,
    );
  });

  testWidgets('screen-name dialog clears stale visible-character errors', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.kills = LightcoreController.killsForOverallLevel(
      LightcoreController.tournamentUnlockLevel,
    );

    await _pumpShell(tester, controller);
    await tester.tap(find.byTooltip('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('Settings'), findsWidgets);

    final changeNameText = find.text('Change Name');
    await _scrollSettingsUntilVisible(tester, changeNameText);
    await tester.tap(changeNameText.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    await tester.tap(
      find.byKey(const ValueKey<String>('save-screen-name-button')),
    );
    await tester.pump();

    expect(
      find.text('Screen names need at least 3 visible characters.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('player-screen-name-field')),
      'Nova Relay',
    );
    await tester.pump();

    expect(
      find.text('Screen names need at least 3 visible characters.'),
      findsNothing,
    );
  });

  testWidgets('screen-name dialog focuses the input when opened', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.kills = LightcoreController.killsForOverallLevel(
      LightcoreController.tournamentUnlockLevel,
    );

    await _pumpShell(tester, controller);
    await _openSettingsFromHeaderMenu(tester);

    final changeNameText = find.text('Change Name');
    await _scrollSettingsUntilVisible(tester, changeNameText);
    await tester.tap(changeNameText.last);
    await _pumpTransition(tester);

    final screenNameField = find.byKey(
      const ValueKey<String>('player-screen-name-field'),
    );
    tester.testTextInput.enterText('Nova Relay');
    await tester.pump();

    final textField = tester.widget<TextField>(screenNameField);
    expect(textField.controller?.text, 'Nova Relay');

    await tester.tap(
      find.byKey(const ValueKey<String>('save-screen-name-button')),
    );
    await tester.pump();

    expect(controller.screenName, 'Nova Relay');
  });

  testWidgets(
    'screen-name dialog keeps typed text through controller refreshes',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.kills = LightcoreController.killsForOverallLevel(
        LightcoreController.tournamentUnlockLevel,
      );

      await _pumpShell(tester, controller);
      await _openSettingsFromHeaderMenu(tester);

      final changeNameText = find.text('Change Name');
      await _scrollSettingsUntilVisible(tester, changeNameText);
      await tester.tap(changeNameText.last);
      await _pumpTransition(tester);

      final screenNameField = find.byKey(
        const ValueKey<String>('player-screen-name-field'),
      );
      await tester.enterText(screenNameField, 'Nova Relay');
      await tester.pump();

      FocusManager.instance.primaryFocus?.unfocus();
      controller.pushNotification('Refresh while editing screen name.');
      await tester.pump();

      final textField = tester.widget<TextField>(screenNameField);
      expect(textField.controller?.text, 'Nova Relay');

      await tester.tap(
        find.byKey(const ValueKey<String>('save-screen-name-button')),
      );
      await tester.pump();

      expect(controller.screenName, 'Nova Relay');
      expect(
        find.text('Screen names need at least 3 visible characters.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'screen-name dialog keeps save action visible on compact height',
    (tester) async {
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 456));

      final controller = LightcoreController();
      addTearDown(controller.dispose);
      controller.kills = LightcoreController.killsForOverallLevel(
        LightcoreController.tournamentUnlockLevel,
      );

      await _pumpShell(tester, controller);
      await _openSettingsFromHeaderMenu(tester);

      final changeNameText = find.text('Change Name');
      await _scrollSettingsUntilVisible(tester, changeNameText);
      await tester.tap(changeNameText.last);
      await _pumpTransition(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('save-screen-name-button')),
      );
      await tester.pump();

      final screenNameField = find.byKey(
        const ValueKey<String>('player-screen-name-field'),
      );
      final saveButton = find.byKey(
        const ValueKey<String>('save-screen-name-button'),
      );

      expect(screenNameField, findsOneWidget);
      expect(saveButton, findsOneWidget);
      expect(tester.getRect(screenNameField).top, greaterThanOrEqualTo(0));
      expect(tester.getRect(saveButton).bottom, lessThanOrEqualTo(456));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings exposes notification toggles and Google linking', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    var googleSignInCalls = 0;

    await _pumpShell(
      tester,
      controller,
      onGoogleSignIn: () async {
        googleSignInCalls += 1;
      },
    );

    await _openSettingsFromHeaderMenu(tester);
    await _scrollSettingsUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('settings-google-sign-in-button')),
    );

    expect(
      find.byKey(const ValueKey<String>('settings-google-sign-in-button')),
      findsOneWidget,
    );
    expect(controller.notificationBannersEnabled, isTrue);
    expect(controller.battleNotificationBannersEnabled, isFalse);
    expect(controller.tutorialPromptsEnabled, isTrue);

    await tester.tap(
      find.byKey(const ValueKey<String>('settings-google-sign-in-button')),
    );
    await tester.pump();
    expect(googleSignInCalls, 1);

    await _scrollSettingsUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('notification-banners-switch')),
    );
    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('notification-banners-switch')),
    );
    await tester.pump();
    await _scrollSettingsUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('battle-alert-banners-switch')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('battle-alert-banners-switch')),
    );
    await tester.pump();
    await _scrollSettingsUntilVisible(
      tester,
      find.byKey(const ValueKey<String>('tutorial-prompts-switch')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('tutorial-prompts-switch')),
    );
    await tester.pump();

    expect(controller.notificationBannersEnabled, isFalse);
    expect(controller.battleNotificationBannersEnabled, isTrue);
    expect(controller.tutorialPromptsEnabled, isFalse);

    await _scrollSettingsUntilVisible(tester, find.text('Battle Visuals'));
    expect(controller.graphicsQuality, LightcoreGraphicsQuality.high);

    await tester.tap(find.text('Low Power'));
    await tester.pump();

    expect(controller.graphicsQuality, LightcoreGraphicsQuality.lowPower);
    expect(
      find.text(LightcoreGraphicsQuality.lowPower.summary),
      findsOneWidget,
    );
  });

  testWidgets('settings shows the app version at the bottom', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller, clientDisplayVersion: '9.8.7+6');

    await _openSettingsFromHeaderMenu(tester);

    final versionNumber = find.byKey(
      const ValueKey<String>('settings-version-number'),
    );
    expect(versionNumber, findsOneWidget);
    expect(find.text('V9.8.7+6'), findsOneWidget);

    final settingsDialog = tester.getRect(find.text('Settings').first);
    final versionRect = tester.getRect(versionNumber);
    expect(versionRect.top, greaterThan(settingsDialog.bottom));
  });

  testWidgets('current quest stays on battle page without a shell popup', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 932));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller, disableTutorial: false);

    expect(
      find.byKey(const ValueKey<String>('shell-current-quest-nav-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('shell-quest-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('shell-quest-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Tap the center Lightcore to wake the first shell and reveal where towers will go.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
  });

  testWidgets('quest card stays off overlay screens without blocking chrome', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller, disableTutorial: false);
    await tester.tap(find.byTooltip('Anomalies').first);
    await _pumpTransition(tester);

    expect(
      find.byKey(const ValueKey<String>('shell-current-quest-overlay-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('shell-quest-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-card')),
      findsNothing,
    );
    expect(find.byTooltip('Return to Base Game'), findsOneWidget);

    await tester.tap(find.byTooltip('Return to Base Game'));
    await _pumpTransition(tester);

    expect(
      find.byKey(const ValueKey<String>('battle-quest-card')),
      findsOneWidget,
    );
  });

  testWidgets('tracked quest shows details by default and can collapse', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('battle-quest-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-card-collapsed')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-quest-collapse-button')),
    );
    await _pumpTransition(tester);

    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-card-collapsed')),
      findsOneWidget,
    );
  });

  testWidgets('queue quest opens details with beginner copy', (tester) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.selectCenter();
    controller.applyOfflineClaim(
      LightcoreOfflineClaimResult(
        secondsClaimed: 1,
        lumensGranted: 1000,
        fluxGranted: 0,
        enemyTicketsGranted: 0,
        killsGranted: LightcoreController.unlockKillsForOuterSlot(0),
        serverValidated: true,
      ),
      showBanner: false,
    );
    controller.selectSlot(0);
    expect(controller.tutorialBuildTowerAt(0, TowerLibrary.redPrism), isTrue);
    controller.markTutorialFirstTowerStatsOpened();
    expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
    expect(controller.tutorialStep, LightcoreTutorialStep.tapFirstTower);

    await _pumpBattleScreen(tester, controller);

    expect(find.text('Queue a Pulse'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Tap the charged Red Prism to add pulses. More queued shots means faster kills, more Lumens, and earlier upgrades.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tracked quest details reopen when the next step starts', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpBattleScreen(tester, controller);

    controller.handleBattleCenterTap();
    await tester.pump();

    expect(controller.tutorialStep, LightcoreTutorialStep.buildFirstRedTower);
    expect(
      find.byKey(const ValueKey<String>('battle-quest-card-collapsed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-detail-card')),
      findsOneWidget,
    );
  });

  testWidgets('battle screen removes zoom buttons from the HUD', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpBattleScreen(tester, controller);

    expect(find.byTooltip('Zoom in'), findsNothing);
    expect(find.byTooltip('Zoom out'), findsNothing);
  });

  testWidgets(
    'notification banner renders as a top layer and dismisses on tap',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      await _pumpShell(tester, controller);

      controller.dismissBanner();
      await tester.pump();

      final resourceRail = find.byKey(
        const ValueKey<String>('battle-resource-rail'),
      );
      final storeButton = find.byTooltip('Open Store');

      final resourceRailBefore = tester.getTopLeft(resourceRail);
      final storeButtonBefore = tester.getTopLeft(storeButton);

      controller.pushNotification('Relay ping.');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey<String>('shell-notification-banner')),
        findsOneWidget,
      );
      expect(find.text('Relay ping.'), findsOneWidget);
      expect(tester.getTopLeft(resourceRail), resourceRailBefore);
      expect(tester.getTopLeft(storeButton), storeButtonBefore);

      await tester.tap(
        find.byKey(const ValueKey<String>('shell-notification-banner')),
      );
      await tester.pump();

      expect(controller.bannerMessage, isEmpty);
      expect(find.text('Relay ping.'), findsNothing);
    },
  );

  testWidgets('battle resource gains fly toward header quantities', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    controller.applyOfflineClaim(
      const LightcoreOfflineClaimResult(
        secondsClaimed: 60,
        lumensGranted: 12,
        fluxGranted: 3,
        enemyTicketsGranted: 2,
        killsGranted: 0,
        serverValidated: true,
      ),
      showBanner: false,
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('battle-resource-flyouts')),
      findsOneWidget,
    );
    expect(find.text('+12 Lumens'), findsNothing);
    expect(find.text('+3 Flux'), findsOneWidget);
    expect(find.text('+2 Scans'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));

    expect(
      find.byKey(const ValueKey<String>('battle-resource-flyouts')),
      findsNothing,
    );
  });

  testWidgets('header scan badge appears only at 10 or more tickets', (
    tester,
  ) async {
    final controller = LightcoreController();
    controller.enemyTickets = 9;
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    expect(find.text('10+'), findsNothing);

    controller.debugAddEnemyTickets(1);
    await tester.pump();

    expect(find.text('10+'), findsOneWidget);
  });

  testWidgets('battle panel stays collapsed until a target is selected', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1100));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await _pumpShell(tester, controller);

    expect(find.textContaining('Root Shell'), findsNothing);
    expect(find.text('Overdrive'), findsNothing);
    expect(find.text('Tower Upgrades'), findsNothing);
    expect(find.text('Tower Stats'), findsNothing);
  });

  testWidgets('selected battle tower shows inline stats', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1100));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.selectSlot(0);
    controller.buildTowerForSelected(TowerLibrary.redPrism);
    final upgradeButton = find.textContaining('Upgrade Level');

    await _pumpShell(tester, controller);

    expect(find.text('Tower Upgrades'), findsOneWidget);
    expect(find.text('Tower Stats'), findsOneWidget);
    expect(find.textContaining('Power '), findsOneWidget);
    expect(upgradeButton, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Stats'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Tower Upgrades')).dy,
      lessThan(tester.getTopLeft(find.text('Tower Stats')).dy),
    );
    expect(
      tester.getTopLeft(upgradeButton).dy,
      lessThan(tester.getTopLeft(find.text('Tower Stats')).dy),
    );
  });

  testWidgets('store sheet exposes premium membership and overdrive offers', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.prismShards = 500;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(body: LightcoreStoreSheet(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.text('Premium Membership'), findsOneWidget);
    expect(
      find.text('Monthly subscription for the longer offline cap.'),
      findsOneWidget,
    );
    expect(find.text('\$4.99'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);
    expect(find.text('Prism Pack'), findsOneWidget);
    expect(find.text('250 Prism Shards'), findsOneWidget);
    expect(find.text('Permanent Overdrive'), findsOneWidget);
    expect(find.text('240'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);

    final storeScrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Activate'),
      320,
      scrollable: storeScrollable,
    );

    await tester.tap(find.text('Activate'));
    await tester.pump();

    expect(controller.hasPremiumMembership, isTrue);
    expect(find.text('Owned'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Unlock'),
      320,
      scrollable: storeScrollable,
    );

    await tester.tap(find.text('Unlock'));
    await tester.pump();

    expect(controller.hasPermanentOverdrive, isTrue);
    expect(controller.prismShards, 260);
    expect(find.text('Owned'), findsNWidgets(2));
  });

  testWidgets('battle panel shows active tower pattern bonuses', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1100));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(1);
    controller.buildTowerAt(0, TowerLibrary.bluePrism);
    controller.buildTowerAt(1, TowerLibrary.greenPrism);
    controller.selectSlot(0);

    await _pumpShell(tester, controller);

    expect(find.textContaining('Pattern '), findsOneWidget);
    expect(find.textContaining('Storm Chain'), findsOneWidget);
  });

  testWidgets(
    'enemy management stays in bottom navigation without pull buttons',
    (tester) async {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      await _pumpShell(tester, controller);

      expect(
        find.descendant(
          of: find.byTooltip('Anomalies'),
          matching: find.byIcon(LightcoreIcons.anomalies),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Anomalies').first);
      await _pumpTransition(tester);

      expect(find.text('Threat Library'), findsOneWidget);
      expect(find.text('Anomaly Assignment'), findsOneWidget);
      expect(find.text('Main Apex'), findsOneWidget);
      expect(find.text('Main Anomaly', skipOffstage: false), findsNothing);
      expect(find.text('Open 1', skipOffstage: false), findsNothing);
      expect(find.text('Threat Scans', skipOffstage: false), findsNothing);
    },
  );

  testWidgets('reopening anomaly management starts at the top', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(430, 932));

    final controller = LightcoreController();
    addTearDown(controller.dispose);
    const enemyScrollKey = PageStorageKey<String>('enemy-management-scroll');

    await _pumpShell(tester, controller);

    await tester.tap(find.byTooltip('Anomalies').first);
    await _pumpTransition(tester);

    expect(_scrollOffsetForKey(tester, enemyScrollKey), 0);

    await tester.drag(find.byKey(enemyScrollKey), const Offset(0, -520));
    await tester.pump();

    expect(_scrollOffsetForKey(tester, enemyScrollKey), greaterThan(0));

    await tester.tap(find.byTooltip('Return to Base Game'));
    await _pumpTransition(tester);
    await tester.tap(find.byTooltip('Anomalies').first);
    await _pumpTransition(tester);

    expect(_scrollOffsetForKey(tester, enemyScrollKey), 0);
  });

  testWidgets('requires confirmation before resetting progress', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);
    controller.handleBattleCenterTap();

    await _pumpShell(tester, controller);

    expect(controller.outerRingRevealed, isTrue);

    await _openSettingsFromHeaderMenu(tester);
    await _scrollSettingsUntilVisible(tester, find.text('Game Reset'));
    await tester.ensureVisible(find.text('Game Reset'));
    await tester.pump();
    await tester.tap(find.text('Game Reset'));
    await _pumpTransition(tester);

    expect(find.text('Reset All Progress?'), findsOneWidget);
    expect(controller.outerRingRevealed, isTrue);

    await tester.tap(find.text('Cancel'));
    await _pumpTransition(tester);

    expect(controller.outerRingRevealed, isTrue);

    await _openSettingsFromHeaderMenu(tester);
    await _scrollSettingsUntilVisible(tester, find.text('Game Reset'));
    await tester.ensureVisible(find.text('Game Reset'));
    await tester.pump();
    await tester.tap(find.text('Game Reset'));
    await _pumpTransition(tester);
    await tester.tap(find.text('Reset Everything'));
    await _pumpTransition(tester);

    expect(controller.outerRingRevealed, isFalse);
    expect(controller.bannerMessage, contains('Cycle reset'));
  });

  testWidgets('battle panel lets the player retarget the selected tower', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(900, 1100));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    controller.kills = LightcoreController.unlockKillsForOuterSlot(0);
    controller.selectSlot(0);
    controller.buildTowerForSelected(TowerLibrary.redPrism);

    await _pumpShell(tester, controller);

    expect(find.text('Live Projectile Target'), findsOneWidget);
    expect(
      controller.towerTargetPriority(controller.slots[0]),
      TargetPriority.close,
    );

    final strongTargetChip = find.widgetWithText(ChoiceChip, 'Strong');
    await tester.ensureVisible(strongTargetChip);
    await tester.tap(strongTargetChip);
    await tester.pump();

    expect(
      controller.towerTargetPriority(controller.slots[0]),
      TargetPriority.strong,
    );
    expect(controller.bannerMessage, contains('prioritizes strong targets'));
  });

  testWidgets(
    'battle pass sheet keeps the free-progress-paid layout on mobile',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(const Size(430, 932));

      final controller = LightcoreController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightcoreTheme(),
          home: Scaffold(
            body: LightcoreBattlePassSheet(controller: controller),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Choose a Pass'), findsOneWidget);
      expect(find.text('Unlock Premium • 120 Shards'), findsOneWidget);
      expect(find.text('Claim All'), findsOneWidget);
      expect(find.text('Selected'), findsNothing);
      expect(find.text('View'), findsNothing);
      expect(find.text('Core Managers'), findsOneWidget);

      await tester.tap(find.text('Core Managers'));
      await tester.pumpAndSettle();

      expect(find.text('Core Manager Pass'), findsOneWidget);
      expect(find.text('Unlock Premium • 90 Shards'), findsOneWidget);

      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();

      expect(find.text('Daily Kill Pass'), findsOneWidget);
      expect(find.text('Unlock Premium • 120 Shards'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('PAID'), findsOneWidget);
      final freeRewardTopLeft = tester.getTopLeft(find.text('+10 Flux').first);
      final premiumRewardTopLeft = tester.getTopLeft(
        find.text('+18 Flux').first,
      );
      expect(premiumRewardTopLeft.dx, greaterThan(freeRewardTopLeft.dx));
      expect(
        (premiumRewardTopLeft.dy - freeRewardTopLeft.dy).abs(),
        lessThan(80),
      );

      final passScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('+35 Flux'),
        320,
        scrollable: passScrollable,
      );

      expect(find.text('+35 Flux'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ExpiringSessionBackend extends FirebaseLightcoreBackend {
  _ExpiringSessionBackend({this.expireOnSync = true})
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  int syncCalls = 0;
  bool expireOnSync;
  bool expireOnClaim = false;

  @override
  bool get canUseCloudSave => true;

  @override
  Future<LightcoreBootstrapReport> bootstrap({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
  }) async {
    final manifest = LightcoreContentManifest(
      firebaseProjectId: 'lumicore-test',
      seasonKey: 'test-season',
      contentEpoch: 1,
      minimumSupportedVersion: clientVersion,
      minimumSupportedBuildNumber: clientBuildNumber,
      recommendedVersion: clientVersion,
      recommendedBuildNumber: clientBuildNumber,
      backendMode: LightcoreBackendMode.firebaseBacked,
    );
    return LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: clientVersion,
      clientBuildNumber: clientBuildNumber,
      manifest: manifest,
      profile: LightcorePlayerProfileSummary(
        playerId: guestSession.playerId,
        authUid: 'test-auth',
        isAnonymous: false,
      ),
      offlineClaim: LightcoreOfflineClaimResult.empty(
        statusMessage: 'No offline rewards available yet.',
      ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: true,
      appCheckActive: true,
      sessionId: 'expired-session',
      serverTime: DateTime(2026),
      cloudSave: LightcoreCloudSaveEnvelope(
        schemaVersion: lightcoreCloudSaveSchemaVersion,
        revision: 1,
        payload: <String, dynamic>{
          'player': <String, dynamic>{
            'playerId': guestSession.playerId,
            'guideId': LightcoreGuideProfile.lumo.storageId,
          },
        },
      ),
    );
  }

  @override
  Future<LightcoreServerSyncResult> syncOfflineSnapshot(
    LightcoreOfflineProgressSnapshot snapshot, {
    String? clientVersion,
    String? clientBuildNumber,
  }) async {
    syncCalls += 1;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (expireOnSync) {
      throw const LightcoreSessionExpiredException('Session expired.');
    }
    return LightcoreServerSyncResult(
      manifest: LightcoreContentManifest(
        firebaseProjectId: 'lumicore-test',
        seasonKey: 'test-season',
        contentEpoch: 1,
        minimumSupportedVersion: clientVersion ?? '1.0.6',
        minimumSupportedBuildNumber: clientBuildNumber,
        recommendedVersion: clientVersion ?? '1.0.6',
        recommendedBuildNumber: clientBuildNumber,
        backendMode: LightcoreBackendMode.firebaseBacked,
      ),
      profile: const LightcorePlayerProfileSummary(
        playerId: 'test-auth',
        authUid: 'test-auth',
        isAnonymous: false,
      ),
      serverTime: DateTime(2026),
      accepted: true,
      sessionId: 'active-session',
    );
  }

  @override
  Future<LightcoreOfflineClaimResult> claimOfflineProgress() async {
    if (expireOnClaim) {
      throw const LightcoreSessionExpiredException('Session expired.');
    }
    return LightcoreOfflineClaimResult.empty();
  }

  @override
  Future<LightcoreCloudSaveEnvelope> savePlayerSave(
    Map<String, dynamic> payload, {
    String? clientVersion,
    String? clientBuildNumber,
  }) async {
    return LightcoreCloudSaveEnvelope(
      schemaVersion: lightcoreCloudSaveSchemaVersion,
      revision: 1,
      payload: payload,
    );
  }

  @override
  Future<LightcoreSocialOverview> fetchSocialOverview() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return const LightcoreSocialOverview(
      self: LightcoreSocialPlayer(
        uid: 'test-auth',
        playerId: 'test-auth',
        displayName: 'Test Pilot',
        level: 1,
        progressToNextLevel: 0,
        performanceScore: 0,
      ),
    );
  }
}

class _GoogleSignInFailureBackend extends FirebaseLightcoreBackend {
  _GoogleSignInFailureBackend()
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  @override
  bool get canUseCloudSave => true;

  @override
  Future<LightcoreBootstrapReport> bootstrap({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
  }) async {
    return LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: clientVersion,
      clientBuildNumber: clientBuildNumber,
      manifest: _testManifest(clientVersion, clientBuildNumber),
      profile: LightcorePlayerProfileSummary(
        playerId: guestSession.playerId,
        authUid: 'anonymous-auth',
        isAnonymous: true,
      ),
      offlineClaim: LightcoreOfflineClaimResult.empty(
        statusMessage: 'No offline rewards available yet.',
      ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: true,
      appCheckActive: true,
      sessionId: 'menu-session',
      serverTime: DateTime(2026),
    );
  }

  @override
  Future<void> signInWithGoogle({bool requireAnonymousLink = false}) async {
    throw StateError('Simulated Google sign-in failure.');
  }
}

class _PendingGoogleSignInBackend extends FirebaseLightcoreBackend {
  _PendingGoogleSignInBackend()
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  final Completer<void> _googleSignInCompleter = Completer<void>();
  int bootstrapCalls = 0;
  int signInCalls = 0;
  bool _signedIn = false;

  @override
  bool get canUseCloudSave => true;

  @override
  bool get hasRecoverableAccount => _signedIn;

  void completeGoogleSignIn() {
    if (!_googleSignInCompleter.isCompleted) {
      _googleSignInCompleter.complete();
    }
  }

  @override
  Future<LightcoreBootstrapReport> bootstrap({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
  }) async {
    bootstrapCalls += 1;
    final playerId = _signedIn ? 'GOOGLE-PLAYER' : guestSession.playerId;
    return LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: clientVersion,
      clientBuildNumber: clientBuildNumber,
      manifest: _testManifest(clientVersion, clientBuildNumber),
      profile: LightcorePlayerProfileSummary(
        playerId: playerId,
        authUid: _signedIn ? 'google-auth' : 'anonymous-auth',
        isAnonymous: !_signedIn,
      ),
      offlineClaim: LightcoreOfflineClaimResult.empty(
        statusMessage: 'No offline rewards available yet.',
      ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: true,
      appCheckActive: true,
      sessionId: _signedIn ? 'google-menu-session' : 'guest-menu-session',
      serverTime: DateTime(2026),
    );
  }

  @override
  Future<void> signInWithGoogle({bool requireAnonymousLink = false}) async {
    signInCalls += 1;
    await _googleSignInCompleter.future;
    _signedIn = true;
  }
}

class _RefreshingLaunchBackend extends FirebaseLightcoreBackend {
  _RefreshingLaunchBackend({this.failCloudRestore = false})
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  final bool failCloudRestore;
  final Map<String, dynamic> restoredPayload = _buildLaunchRestorePayload();
  int bootstrapCalls = 0;
  int saveCalls = 0;

  @override
  bool get canUseCloudSave => true;

  @override
  Future<LightcoreBootstrapReport> bootstrap({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
  }) async {
    bootstrapCalls += 1;
    final restoreReady = !failCloudRestore;
    return LightcoreBootstrapReport(
      guestSession: guestSession,
      clientVersion: clientVersion,
      clientBuildNumber: clientBuildNumber,
      manifest: _testManifest(clientVersion, clientBuildNumber),
      profile: LightcorePlayerProfileSummary(
        playerId: guestSession.playerId,
        authUid: 'test-auth',
        isAnonymous: false,
      ),
      offlineClaim: restoreReady
          ? const LightcoreOfflineClaimResult(
              secondsClaimed: 3600,
              lumensGranted: 25,
              fluxGranted: 0,
              enemyTicketsGranted: 0,
              killsGranted: 0,
              serverValidated: true,
              statusMessage: 'Offline rewards restored.',
            )
          : LightcoreOfflineClaimResult.empty(
              statusMessage: 'No offline rewards available yet.',
            ),
      integrityLevel: LightcoreIntegrityLevel.secure,
      firebaseReady: true,
      serverValidated: true,
      appCheckActive: true,
      sessionId: 'launch-session',
      serverTime: DateTime(2026),
      cloudSave: restoreReady
          ? LightcoreCloudSaveEnvelope(
              schemaVersion: lightcoreCloudSaveSchemaVersion,
              revision: 4,
              payload: restoredPayload,
            )
          : null,
      cloudRestoreRequired: true,
      cloudRestoreComplete: restoreReady,
      warnings: failCloudRestore
          ? const <String>['Cloud save load failed: simulated outage']
          : const <String>[],
    );
  }

  @override
  Future<LightcoreServerSyncResult> syncOfflineSnapshot(
    LightcoreOfflineProgressSnapshot snapshot, {
    String? clientVersion,
    String? clientBuildNumber,
  }) async {
    return LightcoreServerSyncResult(
      manifest: _testManifest(clientVersion ?? '1.0.6', clientBuildNumber),
      profile: const LightcorePlayerProfileSummary(
        playerId: 'test-auth',
        authUid: 'test-auth',
        isAnonymous: false,
      ),
      serverTime: DateTime(2026),
      accepted: true,
      sessionId: 'launch-session',
    );
  }

  @override
  Future<LightcoreCloudSaveEnvelope> savePlayerSave(
    Map<String, dynamic> payload, {
    String? clientVersion,
    String? clientBuildNumber,
  }) async {
    saveCalls += 1;
    return LightcoreCloudSaveEnvelope(
      schemaVersion: lightcoreCloudSaveSchemaVersion,
      revision: 5,
      payload: payload,
    );
  }

  @override
  Future<LightcoreSocialOverview> fetchSocialOverview() async {
    return const LightcoreSocialOverview(
      self: LightcoreSocialPlayer(
        uid: 'test-auth',
        playerId: 'test-auth',
        displayName: 'Test Pilot',
        level: 1,
        progressToNextLevel: 0,
        performanceScore: 0,
      ),
    );
  }
}

class _CloudRestoreFailureLaunchBackend extends _RefreshingLaunchBackend {
  _CloudRestoreFailureLaunchBackend() : super(failCloudRestore: true);
}

class _ThrowingBootstrapBackend extends FirebaseLightcoreBackend {
  _ThrowingBootstrapBackend()
    : super(runtimeConfig: lightcoreFirebaseRuntimeConfig);

  @override
  Future<LightcoreBootstrapReport> bootstrap({
    required LightcoreGuestSession guestSession,
    required String clientVersion,
    String? clientBuildNumber,
  }) async {
    throw StateError('Simulated startup failure.');
  }
}

LightcoreContentManifest _testManifest(
  String clientVersion,
  String? clientBuildNumber,
) {
  return LightcoreContentManifest(
    firebaseProjectId: 'lumicore-test',
    seasonKey: 'test-season',
    contentEpoch: 1,
    minimumSupportedVersion: clientVersion,
    minimumSupportedBuildNumber: clientBuildNumber,
    recommendedVersion: clientVersion,
    recommendedBuildNumber: clientBuildNumber,
    backendMode: LightcoreBackendMode.firebaseBacked,
  );
}

Map<String, dynamic> _buildLaunchRestorePayload() {
  final controller = LightcoreController(
    guideProfile: LightcoreGuideProfile.lumo,
    playerId: 'GX-SERVER-SAVE',
    screenName: 'Server Pilot',
  );
  controller.debugDisableTutorial();
  controller.lumens = 777;
  controller.selectCenter();
  final payload = controller.buildCloudSavePayload();
  controller.dispose();
  return payload;
}
