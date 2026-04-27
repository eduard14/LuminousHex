import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/widgets/guided_focus_frame.dart';

void main() {
  testWidgets('active tutorial frame preserves child constraints', (
    tester,
  ) async {
    BoxConstraints? inactiveConstraints;
    BoxConstraints? activeConstraints;

    Widget buildHarness({
      required bool active,
      required ValueChanged<BoxConstraints> onConstraints,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 48,
              child: GuidedFocusFrame(
                active: active,
                tint: Colors.cyan,
                showTapCue: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    onConstraints(constraints);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildHarness(
        active: false,
        onConstraints: (constraints) => inactiveConstraints = constraints,
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      buildHarness(
        active: true,
        onConstraints: (constraints) => activeConstraints = constraints,
      ),
    );
    await tester.pump();

    expect(activeConstraints, inactiveConstraints);
  });
}
