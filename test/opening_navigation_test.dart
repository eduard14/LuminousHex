import 'package:flutter_test/flutter_test.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('opening chrome focuses the first play action', (tester) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(lightcoreGoldenCompactSize);
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    expect(controller.tutorialUsesBattleOnlyNavigation, isFalse);

    await tester.pumpWidget(buildTestShell(controller));
    await tester.pump();

    expect(find.text('Battle'), findsOneWidget);
    expect(find.text('Towers'), findsOneWidget);
    expect(find.text('Managers'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Anomaly'), findsOneWidget);
    expect(find.byTooltip('Store Locked'), findsOneWidget);
    expect(find.byTooltip('Passes Locked'), findsOneWidget);
    expect(find.byTooltip('Open Settings'), findsOneWidget);
    expect(find.byTooltip('Open Menu'), findsOneWidget);
    expect(find.byTooltip('Open Profile'), findsOneWidget);
    expect(find.byTooltip('Opening guide'), findsNothing);
    expect(
      find.byTooltip('TS: ${controller.towerStrengthLabel}'),
      findsOneWidget,
    );
    expect(find.byTooltip('Flux: ${controller.flux}'), findsNothing);
    expect(find.byTooltip('Lumen: ${controller.lumens}'), findsNothing);
    expect(find.byTooltip('Sparks: ${controller.sparks}'), findsOneWidget);
    expect(
      find.byTooltip('Nova Shards: ${controller.starBolts}'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('${controller.enemyTicketLabel} (locked)'),
      findsNothing,
    );
    expect(find.textContaining('Output Efficiency'), findsNothing);
    expect(find.text('Start Run'), findsOneWidget);
    expect(find.textContaining('Sparks'), findsWidgets);
    expect(find.textContaining('Build Feeder'), findsNothing);
    expect(find.textContaining('AR '), findsNothing);
    expect(find.byTooltip('Hide global upgrades'), findsOneWidget);
    expect(find.text('Wave 1'), findsOneWidget);
    expect(find.textContaining('Shell '), findsNothing);
    expect(find.textContaining('Start run to release'), findsNothing);
    expect(find.byTooltip('Release full wave'), findsOneWidget);

    await tester.tap(find.text('Start Run'));
    await tester.pump(const Duration(milliseconds: 320));

    expect(controller.swarmActivated, isTrue);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.textContaining('Next '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
