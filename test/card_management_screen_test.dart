import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/screens/card_management_screen.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

void main() {
  testWidgets('manager screen previews locked manager rosters', (tester) async {
    final controller = LightcoreController(
      packRandom: Random(4),
      traitRandom: Random(5),
      managerRandom: Random(6),
    );
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: CardManagementScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Whitney Stardust'), 300);
    await tester.ensureVisible(find.text('Whitney Stardust'));
    await tester.pump();
    expect(find.text('Whitney Stardust'), findsOneWidget);

    await tester.tap(find.text('Whitney Stardust'));
    await tester.pumpAndSettle();

    expect(find.text('Locked'), findsWidgets);
    expect(find.text('Foundry roll'), findsOneWidget);

    Navigator.of(tester.element(find.byType(CardManagementScreen))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Plain Jane Quasar'), 300);
    expect(find.text('Plain Jane Quasar'), findsOneWidget);
  });

  testWidgets('manager forge shows a reveal dialog for new rolls', (
    tester,
  ) async {
    final controller = LightcoreController(
      packRandom: Random(1),
      traitRandom: Random(2),
      managerRandom: Random(3),
    );
    addTearDown(controller.dispose);

    controller.debugDisableTutorial();
    controller.experience = LightcoreController.experienceForOverallLevel(
      LightcoreController.managerUnlockLevel,
    );
    controller.flux = LightcoreController.towerManagerFluxCost;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: CardManagementScreen(controller: controller, isActive: true),
        ),
      ),
    );
    await tester.pump();

    final forgeButton = find.text(
      '${LightcoreController.towerManagerFluxCost} Flux',
    );
    await tester.scrollUntilVisible(forgeButton, 300);
    await tester.tap(forgeButton);
    await tester.pump();

    expect(controller.cards, hasLength(1));
    expect(find.text('Core Manager Forged'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text(controller.cards.single.name), findsWidgets);
  });
}
