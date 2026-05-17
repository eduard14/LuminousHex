import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/models/lightcore_guide.dart';
import 'package:lightcore/theme/lightcore_theme.dart';
import 'package:lightcore/widgets/lemon_goose_splash_screen.dart';
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
          guide: LightcoreGuideProfile.luma,
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
    expect(find.text('Luma tip'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('studio splash renders Lemon Goose logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: const LemonGooseSplashScreen(),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      image.image,
      isA<AssetImage>().having(
        (asset) => asset.assetName,
        'assetName',
        LemonGooseSplashScreen.logoAsset,
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
