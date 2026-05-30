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
          subtitle: 'Preparing the shell view.',
          statusLabel: 'Opening',
          signalLabels: ['OPEN', 'LOAD', 'SHOW'],
          tips: ['Auto entry starts when the first event run begins.'],
          guide: LightcoreGuideProfile.luma,
        ),
      ),
    );

    expect(find.text('Opening Shell'), findsOneWidget);
    expect(find.text('Preparing the shell view.'), findsOneWidget);
    expect(find.text('OPENING'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('LOAD'), findsOneWidget);
    expect(find.text('SHOW'), findsOneWidget);
    expect(find.text('LOADING'), findsAtLeastNWidgets(1));
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
