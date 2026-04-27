import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/services/lightcore_rewarded_ads.dart';
import 'package:lightcore/theme/lightcore_theme.dart';

void main() {
  testWidgets('rewarded ads disclose the reward before launch', (tester) async {
    var launchedAds = 0;
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showLightcoreRewardedAd(
                    context,
                    rewardLabel: '+30 Flux',
                    showAdOverride: () async {
                      launchedAds += 1;
                      return LightcoreRewardedAdResult.earned;
                    },
                  );
                },
                child: const Text('Open Reward'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Reward'));
    await tester.pumpAndSettle();

    expect(find.text('Watch Rewarded Ad?'), findsOneWidget);
    expect(find.textContaining('+30 Flux'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Watch Ad'), findsOneWidget);

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(launchedAds, 0);
    expect(result, isFalse);
  });

  testWidgets('rewarded ads launch only after the confirm action', (
    tester,
  ) async {
    var launchedAds = 0;
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightcoreTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () async {
                  result = await showLightcoreRewardedAd(
                    context,
                    rewardLabel: '+5 Threat Scans',
                    showAdOverride: () async {
                      launchedAds += 1;
                      return LightcoreRewardedAdResult.earned;
                    },
                  );
                },
                child: const Text('Open Reward'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Reward'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch Ad'));
    await tester.pumpAndSettle();

    expect(launchedAds, 1);
    expect(result, isTrue);
  });
}
