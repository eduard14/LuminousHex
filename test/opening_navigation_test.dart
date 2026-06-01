import 'package:flutter_test/flutter_test.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('guided opening hides locked bottom navigation', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.tutorialUsesBattleOnlyNavigation, isTrue);

    await tester.pumpWidget(buildTestShell(controller));
    await tester.pump();

    expect(find.text('Towers'), findsNothing);
    expect(find.text('Managers'), findsNothing);
    expect(find.text('Map'), findsNothing);
    expect(find.text('Anomaly'), findsNothing);
    expect(find.byTooltip('Open Store'), findsNothing);
    expect(find.byTooltip('Open Passes'), findsNothing);
    expect(find.byTooltip('Open Menu'), findsNothing);

    controller.debugDisableTutorial();
    await tester.pump();

    expect(find.text('Battle'), findsOneWidget);
    expect(find.text('Towers'), findsOneWidget);
    expect(find.text('Managers'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Anomaly'), findsOneWidget);
    expect(find.byTooltip('Open Store'), findsOneWidget);
    expect(find.byTooltip('Open Passes'), findsOneWidget);
    expect(find.byTooltip('Open Menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
