import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/lightcore_app.dart';
import 'app/lightcore_preview_app.dart';
import 'services/lightcore_rewarded_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (_verboseErrorLoggingEnabled) {
    _installVerboseErrorLogging();
  }
  if (_shouldShowPreview) {
    runApp(LightcorePreviewApp(demoMode: _isDemoPreview));
    return;
  }
  unawaited(LightcoreRewardedAds.instance.initialize());
  runApp(const LightcoreApp());
}

bool get _verboseErrorLoggingEnabled =>
    kDebugMode ||
    const bool.fromEnvironment('LIGHTCORE_VERBOSE_ERRORS') ||
    Uri.base.queryParameters['sessionDebug'] == '1' ||
    Uri.base.queryParameters['debugErrors'] == '1';

void _installVerboseErrorLogging() {
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'Lightcore root error handler',
      ),
      forceReport: true,
    );
    return false;
  };
}

bool get _shouldShowPreview => kIsWeb && (_isMenuPreview || _isDemoPreview);

bool get _isMenuPreview => Uri.base.queryParameters['preview'] == '1';

bool get _isDemoPreview => Uri.base.queryParameters['demo'] == '1';
