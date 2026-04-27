import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/lightcore_test_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('player can open advancement and forge Prism Shell from the UI', (
    tester,
  ) async {
    final controller = createDeterministicController();
    addTearDown(controller.dispose);
    preparePromotionReadyRing(controller);

    await tester.pumpWidget(buildTestShell(controller));
    await pumpFixedFrame(tester, duration: const Duration(milliseconds: 700));

    await tester.tap(find.byTooltip('Advance').first);
    await pumpFixedFrame(tester, duration: const Duration(milliseconds: 700));

    expect(find.text('Advancement Path'), findsOneWidget);
    await tester.drag(
      find.byKey(const PageStorageKey<String>('prestige-scroll')),
      const Offset(0, -520),
    );
    await pumpFixedFrame(tester);

    final createPrismButton = find.text('Create Prism Shell');
    expect(createPrismButton, findsOneWidget);

    await tester.tap(createPrismButton);
    await pumpFixedFrame(tester, duration: const Duration(milliseconds: 700));

    expect(controller.progressionLayer, greaterThanOrEqualTo(2));
    expect(controller.activeLayer.tier, 2);
    expect(controller.activeLayer.label, 'Prism Shell');

    await tester.pumpWidget(Container());
    await tester.pump();
  });
}
