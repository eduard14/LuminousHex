import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/lightcore_test_fixtures.dart';

void main() {
  testWidgets('battle tutorial cue renders across compact aspect ratios', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
      Size(640, 360),
      Size(760, 420),
      Size(932, 430),
      Size(1200, 560),
    ];

    for (final size in sizes) {
      final controller = createDeterministicController();
      addTearDown(controller.dispose);
      controller.selectCenter();

      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(buildTestShell(controller));
      await pumpFixedFrame(tester);

      expect(
        tester.takeException(),
        isNull,
        reason: 'tutorial cue should not produce an error overlay at $size',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
