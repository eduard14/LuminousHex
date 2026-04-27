import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'lightcore_mobile_platform_stub.dart'
    if (dart.library.io) 'lightcore_mobile_platform_io.dart'
    as mobile_platform;
import '../theme/lightcore_palette.dart';

enum LightcoreRewardedAdResult {
  earned,
  dismissed,
  unavailable,
  unsupported,
  busy,
  failed,
}

typedef LightcoreRewardedAdLauncher =
    Future<LightcoreRewardedAdResult> Function();

class LightcoreRewardedAds {
  LightcoreRewardedAds._();

  static final LightcoreRewardedAds instance = LightcoreRewardedAds._();

  static bool get isSupportedPlatform =>
      !kIsWeb && mobile_platform.isMobileAdPlatform;

  RewardedAd? _rewardedAd;
  Future<void>? _initializeFuture;
  Future<void>? _loadingRewardedAdFuture;
  bool _isShowing = false;

  Future<void> initialize() async {
    if (!isSupportedPlatform) {
      return;
    }
    await (_initializeFuture ??= _initializeInternal());
  }

  Future<void> _initializeInternal() async {
    try {
      await MobileAds.instance.initialize();
      unawaited(_warmRewardedAd());
    } catch (_) {
      // Ads stay optional in test and unsupported environments.
    }
  }

  Future<LightcoreRewardedAdResult> showRewardedAd() async {
    if (!isSupportedPlatform) {
      return LightcoreRewardedAdResult.unsupported;
    }
    if (_isShowing) {
      return LightcoreRewardedAdResult.busy;
    }

    await initialize();
    final ad = await _takeRewardedAd();
    if (ad == null) {
      return LightcoreRewardedAdResult.unavailable;
    }

    _isShowing = true;
    final completer = Completer<LightcoreRewardedAdResult>();
    var rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        unawaited(_warmRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(
            rewardEarned
                ? LightcoreRewardedAdResult.earned
                : LightcoreRewardedAdResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        unawaited(_warmRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(LightcoreRewardedAdResult.failed);
        }
      },
    );

    try {
      ad.setImmersiveMode(true);
      ad.show(
        onUserEarnedReward: (_, reward) {
          rewardEarned = reward.amount >= 0;
        },
      );
    } catch (_) {
      ad.dispose();
      _isShowing = false;
      unawaited(_warmRewardedAd());
      return LightcoreRewardedAdResult.failed;
    }

    return completer.future;
  }

  Future<RewardedAd?> _takeRewardedAd() async {
    if (_rewardedAd != null) {
      final ad = _rewardedAd;
      _rewardedAd = null;
      return ad;
    }

    await _warmRewardedAd();
    final ad = _rewardedAd;
    _rewardedAd = null;
    return ad;
  }

  Future<void> _warmRewardedAd() async {
    if (!isSupportedPlatform ||
        _rewardedAd != null ||
        _loadingRewardedAdFuture != null) {
      return;
    }

    final completer = Completer<void>();
    _loadingRewardedAdFuture = completer.future;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loadingRewardedAdFuture = null;
          completer.complete();
        },
        onAdFailedToLoad: (error) {
          _loadingRewardedAdFuture = null;
          completer.complete();
        },
      ),
    );

    await completer.future;
  }

  String get _rewardedAdUnitId => switch (defaultTargetPlatform) {
    TargetPlatform.android => 'ca-app-pub-3940256099942544/5224354917',
    TargetPlatform.iOS => 'ca-app-pub-3940256099942544/1712485313',
    _ => throw UnsupportedError(
      'Rewarded ads are only configured for Android and iOS.',
    ),
  };
}

Future<bool> showLightcoreRewardedAd(
  BuildContext context, {
  required String rewardLabel,
  LightcoreRewardedAdLauncher? showAdOverride,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final confirmed = await _confirmRewardedAdOffer(
    context,
    rewardLabel: rewardLabel,
  );
  if (!confirmed || !context.mounted) {
    return false;
  }

  final result =
      await (showAdOverride ?? LightcoreRewardedAds.instance.showRewardedAd)();

  switch (result) {
    case LightcoreRewardedAdResult.earned:
      return true;
    case LightcoreRewardedAdResult.dismissed:
      return false;
    case LightcoreRewardedAdResult.unsupported:
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Rewarded ads are wired for Android and iOS builds only.',
          ),
        ),
      );
      return false;
    case LightcoreRewardedAdResult.unavailable:
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'The reward ad for $rewardLabel is still loading. Try again in a moment.',
          ),
        ),
      );
      return false;
    case LightcoreRewardedAdResult.busy:
      messenger?.showSnackBar(
        const SnackBar(content: Text('A rewarded ad is already in progress.')),
      );
      return false;
    case LightcoreRewardedAdResult.failed:
      messenger?.showSnackBar(
        SnackBar(
          content: Text('The reward ad for $rewardLabel failed to open.'),
        ),
      );
      return false;
  }
}

Future<bool> _confirmRewardedAdOffer(
  BuildContext context, {
  required String rewardLabel,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: LightcorePalette.panel,
        icon: const Icon(
          Icons.play_circle_fill_rounded,
          color: LightcorePalette.violet,
        ),
        title: const Text('Watch Rewarded Ad?'),
        content: Text(
          'Watch one rewarded ad to receive $rewardLabel. '
          'The reward is granted only after the ad finishes. '
          'If you close it early, nothing is added.',
          style: Theme.of(dialogContext).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Watch Ad'),
          ),
        ],
      );
    },
  );

  return accepted ?? false;
}
