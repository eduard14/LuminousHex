import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/screens/enemy_management_screen.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

void _unlockBossHunts(LightcoreController controller) {
  controller.lumens = 200000;
  controller.kills = 2000;
  controller.experience = 2000;
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    if (!controller.slots[index].isBuilt) {
      controller.buildTowerAt(index, TowerLibrary.all[index]);
    }
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  if (!controller.bossHuntsUnlocked) {
    controller.unlockLayer2Tower();
  }
}

void _unlockThreatMapScans(LightcoreController controller) {
  if (!controller.bossHuntsUnlocked) {
    _unlockBossHunts(controller);
  }
  final starter = controller.threatRegionConfigs.first;
  controller.debugRevealThreatRegion(
    starter.id,
    stabilizedLevel: starter.stabilizationLayers,
  );
  controller.debugGrantApexCore(starter.primaryBossId);
  controller.debugDisableTutorial();
}

void main() {
  test('openEnemyTickets consumes the full requested stash', () {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    _unlockThreatMapScans(controller);
    final startingTickets = controller.enemyTickets;

    final pulls = controller.openEnemyTickets(startingTickets);

    expect(pulls, hasLength(startingTickets));
    expect(controller.enemyTickets, 0);
    expect(controller.lastEnemyPackPulls, hasLength(startingTickets));
  });

  test('openEnemyTickets does not show a pre-reveal result banner', () {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    _unlockThreatMapScans(controller);
    final initialBanner = controller.bannerMessage;

    final pulls = controller.openEnemyTickets(1);

    expect(pulls, hasLength(1));
    expect(controller.bannerMessage, initialBanner);
    expect(controller.bannerMessage, isNot(contains('Resolved')));
  });

  test('openBossTickets does not show a pre-reveal result banner', () {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    _unlockThreatMapScans(controller);
    controller.bossTickets = 1;
    final initialBanner = controller.bannerMessage;

    final pulls = controller.openBossTickets(1);

    expect(pulls, hasLength(1));
    expect(controller.bannerMessage, initialBanner);
    expect(controller.bannerMessage, isNot(contains('Resolved')));
  });

  test('rewarded resources convert apex grants into threat scans', () {
    final controller = LightcoreController();
    final startingTickets = controller.enemyTickets;

    controller.grantRewardedResources(
      bossTicketsGranted: 3,
      sourceLabel: 'Test reward',
    );

    expect(controller.bossTickets, 0);
    expect(controller.enemyTickets, startingTickets + 3);
    expect(controller.bannerMessage, contains('+3 Threat Scans'));
  });

  test('crossing a summoning level grants ticket milestone rewards', () {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    _unlockThreatMapScans(controller);
    controller.enemyPullCount =
        LightcoreController.summoningLevelPullTargetForLevel(2) - 1;
    controller.enemyTickets = 1;

    final reward = LightcoreController.summoningLevelTicketRewardForLevel(2);

    controller.openEnemyTickets(1);

    expect(controller.summoningLevel, 2);
    expect(controller.enemyTickets, reward);
  });

  test('summoning milestone rewards and gaps follow the scan track curve', () {
    expect(LightcoreController.summoningLevelTicketRewardForLevel(2), 100);
    expect(
      LightcoreController.summoningLevelTicketRewardForLevel(
        LightcoreController.maxSummoningLevel,
      ),
      1000,
    );

    final gaps = [
      for (
        var level = 2;
        level <= LightcoreController.maxSummoningLevel;
        level += 1
      )
        LightcoreController.summoningLevelPullGapForLevel(level),
    ];

    for (var index = 1; index < gaps.length; index += 1) {
      expect(gaps[index], greaterThan(gaps[index - 1]));
    }
    expect(gaps.last, 20000);
  });

  test(
    'summon rarity helpers expose top and second-highest available tiers',
    () {
      final controller = LightcoreController();

      expect(controller.highestAvailableEnemyPullRarity, EnemyCardRarity.rare);
      expect(
        controller.secondHighestAvailableEnemyPullRarity,
        EnemyCardRarity.uncommon,
      );

      controller.debugSetSummoningLevel(20);

      expect(
        controller.highestAvailableEnemyPullRarity,
        EnemyCardRarity.legendary,
      );
      expect(
        controller.secondHighestAvailableEnemyPullRarity,
        EnemyCardRarity.epic,
      );
      expect(
        resolveEnemyPackHighlightTier(
          highestDrawnRarity: EnemyCardRarity.legendary,
          highestAvailableRarity: controller.highestAvailableEnemyPullRarity,
          secondHighestAvailableRarity:
              controller.secondHighestAvailableEnemyPullRarity,
        ),
        EnemyPackHighlightTier.highest,
      );
      expect(
        resolveEnemyPackHighlightTier(
          highestDrawnRarity: EnemyCardRarity.epic,
          highestAvailableRarity: controller.highestAvailableEnemyPullRarity,
          secondHighestAvailableRarity:
              controller.secondHighestAvailableEnemyPullRarity,
        ),
        EnemyPackHighlightTier.secondHighest,
      );
    },
  );

  test('summoning progress helpers expose next level state', () {
    final controller = LightcoreController();
    final nextLevelTarget =
        LightcoreController.summoningLevelPullTargetForLevel(2);
    controller.enemyPullCount = nextLevelTarget - 1;

    expect(controller.summoningLevel, 1);
    expect(
      controller.summoningLevelProgress,
      closeTo(
        (nextLevelTarget - 1) / controller.currentSummoningLevelPullGap,
        0.0001,
      ),
    );
    expect(controller.pullsToNextSummoningLevel, 1);
    expect(controller.nextSummoningLevel, 2);
    expect(
      controller.nextSummoningLevelTicketReward,
      LightcoreController.summoningLevelTicketRewardForLevel(2),
    );

    controller.debugSetSummoningLevel(LightcoreController.maxSummoningLevel);

    expect(controller.isSummoningLevelMaxed, isTrue);
    expect(controller.summoningLevelProgress, 1.0);
    expect(controller.pullsToNextSummoningLevel, 0);
    expect(controller.nextSummoningLevelTicketReward, 0);
  });

  test(
    'activeThreatScanBundle exposes armed deck pressure and counterplay',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      controller.debugSetEnemyCardLevel(EnemyLibrary.basicRed.id, level: 1);
      controller.toggleEnemyCardSelection(EnemyLibrary.basicRed.id);
      controller.toggleEnemyCardSelection(EnemyLibrary.basicWhite.id);
      controller.setEnemyTargetCount(controller.enemyTargetMax);

      final bundle = controller.activeThreatScanBundle;

      expect(bundle.primaryAffinity, PrototypeAffinity.ember);
      expect(bundle.name, 'Red Active Threat Bundle');
      expect(bundle.cardNames, contains(EnemyLibrary.basicRed.name));
      expect(
        bundle.threatRewardMultiplier,
        closeTo(EnemyLibrary.basicRed.threatRewardMultiplier, 0.0001),
      );
      expect(
        bundle.stabilityPressureMultiplier,
        closeTo(EnemyLibrary.basicRed.stabilityDamageMultiplier, 0.0001),
      );
      expect(
        bundle.effectiveGainMultiplier,
        closeTo(controller.activeEffectiveGainMultiplier, 0.0001),
      );
      expect(bundle.riskLabel, isNot('Dormant'));
      expect(bundle.counterplayLabel, contains('burst'));
    },
  );

  test('mergeAllReadyEnemyCards fuses every available enemy merge', () {
    final controller = LightcoreController();

    controller.debugSetEnemyCardLevel(
      EnemyLibrary.basicWhite.id,
      level: EnemyCardRarity.basic.levelCap,
      copies: 40,
    );

    expect(controller.mergeableEnemyCardCount, 1);

    final mergedCount = controller.mergeAllReadyEnemyCards();

    expect(mergedCount, 2);
    expect(controller.mergeableEnemyCardCount, 0);
    expect(controller.enemyCardById(EnemyLibrary.basicWhite.id)?.copies, 0);
  });

  test('upgradeAllReadyEnemyCards spends copies until no level-ups remain', () {
    final controller = LightcoreController();

    controller.debugSetEnemyCardLevel(
      EnemyLibrary.starterDefault.id,
      level: 1,
      copies: 0,
    );
    controller.debugSetEnemyCardLevel(
      EnemyLibrary.basicWhite.id,
      level: 1,
      copies: 3,
    );
    controller.debugSetEnemyCardLevel(
      EnemyLibrary.basicRed.id,
      level: 2,
      copies: 1,
    );

    expect(controller.upgradableEnemyCardCount, 2);

    final upgradedCount = controller.upgradeAllReadyEnemyCards();

    expect(upgradedCount, 4);
    expect(controller.upgradableEnemyCardCount, 0);
    expect(controller.enemyCardById(EnemyLibrary.basicWhite.id)?.level, 4);
    expect(controller.enemyCardById(EnemyLibrary.basicWhite.id)?.copies, 0);
    expect(controller.enemyCardById(EnemyLibrary.basicRed.id)?.level, 3);
    expect(controller.enemyCardById(EnemyLibrary.basicRed.id)?.copies, 0);
  });

  testWidgets('pull sheet no longer exposes local fake threat scans', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pump();

    expect(find.text('Threat Scans'), findsOneWidget);
    expect(find.text('Fake Threat Scan'), findsNothing);
    expect(find.text('Preview Only'), findsNothing);
    expect(
      find.textContaining(
        RegExp('preview', caseSensitive: false),
        findRichText: true,
      ),
      findsNothing,
    );
  });

  testWidgets('pull sheet no longer exposes local fake apex scans', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Apex'));
    await tester.pump(const Duration(milliseconds: 300));

    final fakeBossButton = find.text('Fake Boss Reveal');

    expect(find.text('Regional Bosses'), findsOneWidget);
    expect(fakeBossButton, findsNothing);
    expect(find.text('Preview Only'), findsNothing);
    expect(
      find.textContaining(
        RegExp('preview', caseSensitive: false),
        findRichText: true,
      ),
      findsNothing,
    );
  });

  testWidgets('10+ option opens a batch slider', (tester) async {
    final controller = LightcoreController();
    _unlockThreatMapScans(controller);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10+'));
    await tester.pumpAndSettle();

    expect(find.text('Open 10+'), findsOneWidget);
    expect(find.text('10 scans'), findsOneWidget);
    expect(find.text('Open 10'), findsOneWidget);
  });

  testWidgets('max option resolves every available threat scan', (
    tester,
  ) async {
    final controller = LightcoreController();
    _unlockThreatMapScans(controller);
    controller.enemyTickets = 9;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('MAX').last);
    await tester.pump();

    expect(controller.enemyTickets, 0);
    expect(controller.lastEnemyPackPulls, isEmpty);
    expect(controller.enemyPullCount, 9);

    await tester.pump(const Duration(seconds: 13));
    await tester.pump();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('max option resolves every available apex scan', (tester) async {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    _unlockThreatMapScans(controller);
    controller.debugDisableTutorial();
    controller.bossPullCount = 1;
    controller.enemyTickets = 7;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Apex'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ad'), findsOneWidget);

    await tester.tap(find.text('MAX'));
    await tester.pump();

    expect(controller.enemyTickets, 0);
    expect(controller.lastBossPackPulls, isEmpty);
    expect(controller.bossPullCount, 1);

    await tester.pump(const Duration(seconds: 13));
    await tester.pump();
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('rates info button opens summon rates dialog', (tester) async {
    final controller = LightcoreController();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    final infoButton = find.byTooltip('Show threat rates');

    expect(infoButton, findsOneWidget);

    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(find.text('Threat Rates'), findsOneWidget);
    expect(
      find.textContaining('unlock Scan Lv 2 and +100 Threat Scans'),
      findsOneWidget,
    );
  });

  testWidgets('pull sheet separates enemy and boss flows into tabs', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Threat Scans'), findsOneWidget);
    expect(find.text('Regional Bosses Locked'), findsNothing);
    expect(find.byTooltip('Show threat rates'), findsOneWidget);
    expect(find.byTooltip('Show boss reveal rates'), findsNothing);

    await tester.tap(find.text('Apex'));
    await tester.pumpAndSettle();

    expect(find.text('Regional Bosses'), findsOneWidget);
    expect(find.textContaining('Create the Prism Shell'), findsOneWidget);
    expect(find.byTooltip('Show threat rates'), findsNothing);
    expect(find.byTooltip('Show boss reveal rates'), findsOneWidget);
  });

  testWidgets('pull sheet omits recent scan summaries', (tester) async {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    _unlockThreatMapScans(controller);
    controller.openEnemyTickets(1);
    controller.debugAddBossTickets(1);
    controller.openBossTickets(1);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resolved'), findsNothing);

    await tester.tap(find.text('Apex'));
    await tester.pumpAndSettle();

    expect(find.text('Resolved Regional Bosses'), findsNothing);
  });

  testWidgets('apex scan preview hides resolved equipped and future cards', (
    tester,
  ) async {
    final controller = LightcoreController();
    _unlockBossHunts(controller);
    final equipped = BossEnemyLibrary.byRarity[EnemyCardRarity.basic]!.first;
    final resolved = BossEnemyLibrary.byRarity[EnemyCardRarity.basic]![1];
    final available = BossEnemyLibrary.byRarity[EnemyCardRarity.basic]![2];
    final future = BossEnemyLibrary.byRarity[EnemyCardRarity.epic]!.first;

    controller.debugSetEnemyCardLevel(equipped.id, level: 1, boss: true);
    controller.setActiveBossEnemyCard(equipped.id);
    controller.debugSetEnemyCardLevel(resolved.id, level: 1, boss: true);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(body: EnemyPullSheet(controller: controller)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Apex'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('${equipped.name} • tap for details'), findsNothing);
    expect(find.byTooltip('${resolved.name} • tap for details'), findsNothing);
    expect(find.byTooltip('${future.name} • tap for details'), findsNothing);
    expect(
      find.byTooltip('${available.name} • tap for details'),
      findsOneWidget,
    );
  });

  testWidgets('enemy management opens on the locked boss build page', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: EnemyManagementScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boss Build'), findsWidgets);
    expect(find.text('Boss Build Locked'), findsOneWidget);
    expect(find.text('Anomaly Assignment'), findsNothing);
    expect(find.text('Mass Fuse Anomalies'), findsNothing);
  });
}
