import 'package:flutter/widgets.dart';
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

    expect(find.text('Battle'), findsNothing);
    expect(find.text('Towers'), findsNothing);
    expect(find.text('Managers'), findsNothing);
    expect(find.text('Map'), findsNothing);
    expect(find.text('Anomaly'), findsNothing);
    expect(find.byTooltip('Open Store'), findsNothing);
    expect(find.byTooltip('Open Passes'), findsNothing);
    expect(find.byTooltip('Open Menu'), findsNothing);
    expect(find.byTooltip('Open Profile'), findsNothing);
    expect(find.byTooltip('Opening guide'), findsOneWidget);
    expect(
      find.byTooltip('TS: ${controller.towerStrengthLabel}'),
      findsNothing,
    );
    expect(find.byTooltip('Flux: ${controller.flux}'), findsNothing);
    expect(find.byTooltip('Lumen: ${controller.lumens}'), findsOneWidget);
    expect(
      find.byTooltip(
        'Output Efficiency: ${controller.outputEfficiencyLabel} • Core Stability ${controller.coreStabilityLabel}',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('battle-play-button')));
    await tester.pump(const Duration(milliseconds: 320));

    expect(controller.swarmActivated, isTrue);
    expect(
      find.byKey(const ValueKey<String>('battle-play-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
