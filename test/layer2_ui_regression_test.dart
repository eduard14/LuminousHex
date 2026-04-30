import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/screens/prestige_screen.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets(
    'advancement UI forges Prism Shell from a promotion-ready shell',
    (tester) async {
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });
      await tester.binding.setSurfaceSize(lightcoreGoldenDesktopSize);

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

      expect(find.text('Advancement Path'), findsOneWidget);
      final createPrismButton = find.text('Create Prism Shell');
      final prestigeScroll = find.byKey(
        const PageStorageKey<String>('prestige-scroll'),
      );
      expect(prestigeScroll, findsOneWidget);
      final prestigeScrollable = find.descendant(
        of: prestigeScroll,
        matching: find.byType(Scrollable),
      );
      expect(prestigeScrollable, findsOneWidget);
      await tester.scrollUntilVisible(
        createPrismButton,
        120,
        scrollable: prestigeScrollable,
      );
      await pumpFixedFrame(tester);

      expect(createPrismButton, findsOneWidget);
      expect(find.byTooltip('Show merge rates'), findsOneWidget);

      await tester.tap(find.byTooltip('Show merge rates'));
      await pumpFixedFrame(tester);

      expect(find.text('Merge Rates'), findsOneWidget);
      expect(find.text('Rainbow'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('Projectile Tower'), findsOneWidget);
      expect(find.text('Payload Tower'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await pumpFixedFrame(tester);

      await tester.tap(createPrismButton);
      await pumpFixedFrame(tester, duration: const Duration(milliseconds: 700));

      expect(controller.progressionLayer, greaterThanOrEqualTo(2));
      expect(controller.activeLayer.tier, 2);
      expect(controller.activeLayer.label, 'Prism Shell');
    },
  );
}
