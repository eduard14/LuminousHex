import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/screens/card_management_screen.dart';
import 'package:lightcore/screens/prestige_screen.dart';
import 'package:lightcore/screens/threat_map_screen.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('threat map presents sectors separately from apex builds', (
    tester,
  ) async {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    controller.debugAddEnemyTickets(3);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTestLightcoreTheme(),
        home: Scaffold(
          body: ThreatMapScreen(
            controller: controller,
            isActive: true,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Threat Map'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('threat-map-surface')),
      findsOneWidget,
    );
    expect(find.text('Apex'), findsNothing);
    expect(find.text('Fake Threat Scan'), findsNothing);
  });

  testWidgets(
    'manager foundry appears before collapsed locked rosters on mobile',
    (tester) async {
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);

      final controller = createDeterministicController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTestLightcoreTheme(),
          home: Scaffold(
            body: CardManagementScreen(controller: controller, isActive: true),
          ),
        ),
      );
      await pumpFixedFrame(tester);

      expect(find.text('Foundry'), findsOneWidget);
      expect(find.text('Core Manager Packs'), findsOneWidget);
      expect(find.text('Locked Core Manager Roster'), findsNothing);
    },
  );

  testWidgets(
    'bottom navigation labels stay visible and locked tabs explain why',
    (tester) async {
      addTearDown(() async => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);

      final controller = createDeterministicController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestShell(controller));
      await pumpFixedFrame(tester);

      expect(find.text('Battle'), findsWidgets);
      expect(find.text('Towers'), findsOneWidget);
      expect(find.text('Managers'), findsOneWidget);
      expect(find.text('Anomaly'), findsOneWidget);
      expect(find.text('Advance'), findsNothing);

      await tester.tap(find.byTooltip('Managers').first);
      await tester.pump();

      expect(controller.bannerMessage, contains('all 6 outer towers'));
    },
  );

  testWidgets('passive root shell battle view surfaces passive status', (
    tester,
  ) async {
    addTearDown(() async => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);

    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    forgeLayer2(controller);
    final rootLayerId = controller.activeLayer.sourceLayerId!;
    controller.enterLayerById(rootLayerId);

    await tester.pumpWidget(buildTestShell(controller));
    await pumpFixedFrame(tester);

    expect(controller.activeLayerPassiveOnly, isTrue);
    expect(find.text('PASSIVE'), findsOneWidget);
  });

  testWidgets('advance screen does not call a passive archive live', (
    tester,
  ) async {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    forgeLayer2(controller);
    final rootLayerId = controller.activeLayer.sourceLayerId!;
    controller.enterLayerById(rootLayerId);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTestLightcoreTheme(),
        home: Scaffold(
          body: PrestigeScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await pumpFixedFrame(tester);

    expect(find.text('Viewed shell is passive'), findsOneWidget);
    expect(find.text('Viewed shell runs live'), findsNothing);
    expect(find.text('Promotion Preview'), findsOneWidget);
  });

  testWidgets('promotion preview renders before create prism action', (
    tester,
  ) async {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    preparePromotionReadyRing(controller);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTestLightcoreTheme(),
        home: Scaffold(
          body: PrestigeScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await pumpFixedFrame(tester);

    expect(find.text('Promotion Preview'), findsOneWidget);
    expect(find.text('Action: Create Prism Shell'), findsOneWidget);
    expect(find.text('Result: Prism Shell core'), findsOneWidget);
    expect(find.text('Create Prism Shell'), findsOneWidget);
  });

  test(
    'promotion preview snapshot is read-only and matches promotion output',
    () {
      final controller = createDeterministicController();
      addTearDown(controller.dispose);
      preparePromotionReadyRing(controller);

      final sourceLayerId = controller.activeLayer.id;
      final preview = controller.promotionPreview;

      expect(preview.canPromote, isTrue);
      expect(preview.actionLabel, 'Create Prism Shell');
      expect(preview.resultLabel, 'Prism Shell core');
      expect(preview.projectileMixLabel, isNotEmpty);
      expect(controller.activeLayer.id, sourceLayerId);

      controller.unlockLayer2Tower();

      expect(controller.activeLayer.label, 'Prism Shell');
      expect(preview.resultLabel, contains(controller.activeLayer.label));
    },
  );

  test(
    'active threat bundle labels include deck, director, and target source',
    () {
      final controller = createDeterministicController();
      addTearDown(controller.dispose);
      controller.debugSetEnemyCardLevel(EnemyLibrary.basicRed.id, level: 1);
      controller.toggleEnemyCardSelection(EnemyLibrary.basicRed.id);
      controller.toggleEnemyCardSelection(EnemyLibrary.basicWhite.id);
      controller.setEnemyTargetCount(controller.enemyTargetMax);
      controller
        ..kills = LightcoreController.unlockKillsForOuterSlot(
          LightcoreController.slotCount - 1,
        )
        ..lumens = 1000000;
      for (var index = 0; index < LightcoreController.slotCount; index++) {
        expect(
          controller.buildTowerAt(index, controller.towerConfigs[index]),
          isTrue,
        );
      }
      expect(controller.managerAssignmentUnlocked, isTrue);
      controller.flux = 10000;
      expect(controller.forgeEnemyManagerBatch(1), isTrue);
      controller.assignEnemyManagerToCore(
        controller.enemyManagers.first.instanceId,
      );

      final bundle = controller.activeThreatScanBundle;

      expect(bundle.name, 'Red Active Threat Bundle');
      expect(bundle.summary, contains('Active anomaly deck'));
      expect(bundle.summary, contains('Threat Director'));
      expect(
        bundle.summary,
        contains('${controller.enemyTargetCount} region-managed targets'),
      );
      expect(bundle.activeCardCount, 1);
      expect(bundle.directorCount, 1);
      expect(bundle.targetCount, controller.enemyTargetCount);
    },
  );
}
