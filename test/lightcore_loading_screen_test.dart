import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/theme/lightcore_theme.dart';
import 'package:lightcore/widgets/lightcore_loading_screen.dart';

void main() {
  testWidgets('loading screen renders branded interstitial copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: const LightcoreLoadingScreen(
          title: 'Opening Shell',
          subtitle: 'Routing command through the tower lattice.',
          statusLabel: 'Screen Link',
          signalLabels: ['SYNC', 'LINK', 'ARM'],
          tips: ['Auto entry starts when the first event run begins.'],
        ),
      ),
    );

    expect(find.text('Opening Shell'), findsOneWidget);
    expect(
      find.text('Routing command through the tower lattice.'),
      findsOneWidget,
    );
    expect(find.text('SCREEN LINK'), findsOneWidget);
    expect(find.text('SYNC'), findsOneWidget);
    expect(find.text('LINK'), findsOneWidget);
    expect(find.text('ARM'), findsOneWidget);
    expect(
      find.text('Auto entry starts when the first event run begins.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
