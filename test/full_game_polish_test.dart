import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/enemy_configs.dart';
import 'package:lightcore/screens/card_management_screen.dart';
import 'package:lightcore/screens/enemy_management_screen.dart';
import 'package:lightcore/screens/prestige_screen.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('scan sheet explains threat and apex spending roles', (
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
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () => showEnemyPullSheet(context, controller),
                  child: const Text('Open scans'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scans'));
    await tester.pumpAndSettle();

    expect(find.text('Threat Scans reveal map regions'), findsOneWidget);
    expect(find.textContaining('fixed hex map'), findsOneWidget);
    expect(
      find.text('These are enemies and encounter modifiers, not allies.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Apex'));
    await tester.pumpAndSettle();

    expect(find.text('Threat Scans reveal region bosses'), findsOneWidget);
    expect(find.textContaining('Final clears drop Apex Cores'), findsOneWidget);
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
      expect(find.text('Advance'), findsOneWidget);

      await tester.tap(find.byTooltip('Managers').first);
      await tester.pump();

      expect(controller.bannerMessage, contains('Core Lv 3'));
      expect(controller.bannerMessage, contains('Account Radiance'));
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
      controller.experience = LightcoreController.experienceForOverallLevel(
        LightcoreController.managerUnlockLevel,
      );
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
