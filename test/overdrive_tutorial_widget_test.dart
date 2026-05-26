import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/screens/battle_screen.dart';
import 'package:lightcore/state/lightcore_controller.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

Future<void> _pumpBattleScreen(
  WidgetTester tester,
  LightcoreController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightcoreTheme(),
      home: Scaffold(
        body: BattleScreen(controller: controller, isActive: true),
      ),
    ),
  );
  await tester.pump();
}

void _promoteRootShell(LightcoreController controller) {
  controller.lumens = 100000;
  controller.kills = LightcoreController.unlockKillsForOuterSlot(
    LightcoreController.slotCount - 1,
  );
  for (var index = 0; index < LightcoreController.slotCount; index++) {
    controller.buildTowerAt(index, TowerLibrary.all[index]);
    while (controller.slots[index].level < LightcoreController.maxTowerLevel) {
      controller.upgradeTower(index);
    }
  }
  controller.unlockLayer2Tower();
}

void _reachOverdriveQuest(LightcoreController controller) {
  _promoteRootShell(controller);
  controller.debugCompleteBossAndEquipmentTutorial();
  expect(controller.tutorialStep, LightcoreTutorialStep.openTowerMatrix);
  controller.markTutorialTowerMatrixOpened();
  expect(controller.createChildLayer(0, PrototypeAffinity.aether), isTrue);
  controller.selectCenter();
  expect(controller.tutorialStep, LightcoreTutorialStep.none);
  expect(controller.buildTowerAt(0, TowerLibrary.redPrism), isTrue);
  expect(controller.debugSetTowerCharge(0, charge: 1), isTrue);
  expect(controller.tutorialStep, LightcoreTutorialStep.tapSecondShellTower);
  controller.tick(0.1);
  expect(controller.pulses, isNotEmpty);
  expect(controller.boostPulseToCore(controller.pulses.last.id), isTrue);
  expect(controller.tutorialStep, LightcoreTutorialStep.holdOverdrive);
}

void main() {
  testWidgets('overdrive tutorial highlights the overdrive button directly', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(1000, 1600));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _reachOverdriveQuest(controller);
    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('battle-quest-show-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-overdrive-frame')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('battle-quest-show-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('holding overdrive survives a notification rebuild', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.binding.setSurfaceSize(const Size(1000, 1600));

    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _reachOverdriveQuest(controller);
    await _pumpBattleScreen(tester, controller);

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey<String>('battle-overdrive-button')),
      ),
    );
    await tester.pump();

    expect(controller.isManualOverdriveHeld, isTrue);

    controller.pushNotification('Relay ping while boosting.');
    await tester.pump();

    expect(controller.isManualOverdriveHeld, isTrue);

    await gesture.up();
    await tester.pump();

    expect(controller.isManualOverdriveHeld, isFalse);
  });

  testWidgets('completed overdrive quest advances to next actionable quest', (
    tester,
  ) async {
    final controller = LightcoreController();
    addTearDown(controller.dispose);

    _reachOverdriveQuest(controller);
    await _pumpBattleScreen(tester, controller);

    expect(
      find.byKey(const ValueKey<String>('battle-quest-card')),
      findsOneWidget,
    );

    controller.startManualOverdrive();
    controller.tick(0.35);
    await tester.pump();

    expect(controller.tutorialStep, LightcoreTutorialStep.upgradeCoreRange);
    expect(
      find.byKey(const ValueKey<String>('battle-quest-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-quest-trigger-button')),
      findsOneWidget,
    );
  });
}
