import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/screens/advancement_screen.dart';
import 'package:lightcore/screens/tower_management_screen.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets(
    'component UI creates Layer 2 component from a promotion-ready shell',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(lightcoreGoldenDesktopSize);

      final controller = createDeterministicController();
      addTearDown(controller.dispose);
      preparePromotionReadyRing(controller);
      controller.activeLayer.bestWaveReached = 25;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTestLightcoreTheme(),
          home: Scaffold(
            body: AdvancementScreen(controller: controller, isActive: true),
          ),
        ),
      );
      await pumpFixedFrame(tester);

      expect(find.text('Layer 2 Components'), findsOneWidget);
      expect(find.text('Layer 1 Component Forecast'), findsOneWidget);
      expect(find.text('Ready to Create Layer 2 Component'), findsOneWidget);
      expect(find.text('Best Wave 25'), findsOneWidget);
      expect(find.text('Tier 25'), findsOneWidget);
      expect(find.text('3 subtraits'), findsOneWidget);
      final createPrismButton = find.text('Create Layer 2 Component');
      final advancementScroll = find.byKey(
        const PageStorageKey<String>('advancement-scroll'),
      );
      expect(advancementScroll, findsOneWidget);
      final advancementScrollable = find.descendant(
        of: advancementScroll,
        matching: find.byType(Scrollable),
      );
      expect(advancementScrollable, findsOneWidget);
      await tester.scrollUntilVisible(
        createPrismButton,
        120,
        scrollable: advancementScrollable,
      );
      await pumpFixedFrame(tester);

      expect(createPrismButton, findsOneWidget);
      expect(find.byTooltip('Show merge rates'), findsOneWidget);

      await tester.tap(find.byTooltip('View all component odds'));
      await pumpFixedFrame(tester);

      expect(find.text('Layer 1 Component Forecast'), findsWidgets);
      expect(find.text('Stat tier'), findsOneWidget);
      expect(find.text('Tier 25'), findsWidgets);

      await tester.tap(find.text('Close'));
      await pumpFixedFrame(tester);

      await tester.tap(find.byTooltip('Show merge rates'));
      await pumpFixedFrame(tester);

      expect(find.text('Component Roll Rates'), findsOneWidget);
      expect(find.text('Rainbow'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('Projectile Odds'), findsOneWidget);
      expect(find.text('Payload Odds'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await pumpFixedFrame(tester);

      await tester.tap(createPrismButton);
      await pumpFixedFrame(tester, duration: const Duration(milliseconds: 700));

      expect(controller.progressionLayer, greaterThanOrEqualTo(2));
      expect(controller.activeLayer.tier, 2);
      expect(controller.activeLayer.label, 'Prism Shell');
      expect(controller.layer2Components, hasLength(1));
      await tester.pump();

      expect(find.text('Component Inventory'), findsOneWidget);
      expect(find.text('0 Component Scrolls'), findsOneWidget);
      expect(find.textContaining('farm output'), findsOneWidget);
      expect(find.text('Assign Area'), findsOneWidget);
    },
  );

  testWidgets('tower screen shows partial Layer 1 component forecast', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(lightcoreGoldenDesktopSize);

    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    controller.lumens = 10000;
    expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTestLightcoreTheme(),
        home: Scaffold(
          body: TowerManagementScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await pumpFixedFrame(tester);

    expect(find.text('Layer 1 Component Forecast'), findsOneWidget);
    expect(find.text('Need 5 more towers'), findsOneWidget);
    expect(find.text('Best Wave 1'), findsOneWidget);
    expect(find.text('Tier 1'), findsOneWidget);
    expect(find.text('Red 100%'), findsWidgets);
  });
}
