import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightcore/screens/advancement_screen.dart';

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
    },
  );
}
