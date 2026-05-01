import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lightcore_guide.dart';
import '../screens/lightcore_main_menu_screen.dart';
import '../theme/lightcore_theme.dart';
import 'lightcore_bootstrap.dart';

class LightcorePreviewApp extends StatefulWidget {
  const LightcorePreviewApp({super.key, required this.demoMode});

  final bool demoMode;

  @override
  State<LightcorePreviewApp> createState() => _LightcorePreviewAppState();
}

class _LightcorePreviewAppState extends State<LightcorePreviewApp> {
  Timer? _demoTimer;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.demoMode;
    _startDemoTimerIfNeeded();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  void _startDemoTimerIfNeeded() {
    _demoTimer?.cancel();
    if (!widget.demoMode) {
      return;
    }
    _demoTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
    });
  }

  void _restartDemo() {
    if (!widget.demoMode) {
      return;
    }
    setState(() => _isLoading = true);
    _startDemoTimerIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lightcore Menu Preview',
      theme: buildLightcoreTheme(),
      home: Scaffold(
        body: LightcoreMainMenuScreen(
          guestSession: _previewGuestSession,
          bootstrapReport: _previewReport,
          guideProfile: LightcoreGuideProfile.lumo,
          isLoading: _isLoading,
          onEnterGame: () {},
          onSelectGuide: (_) {},
          onRetryBootstrap: _restartDemo,
        ),
      ),
    );
  }
}

final _previewGuestSession = LightcoreGuestSession(
  playerId: 'GX-74E2-A91C',
  createdAt: DateTime(2026, 4, 21, 12),
  authLabel: 'Preview session',
);

final _previewReport = LightcoreBootstrapReport(
  guestSession: _previewGuestSession,
  clientVersion: '1.0.18',
  clientBuildNumber: '19',
  manifest: const LightcoreContentManifest(
    firebaseProjectId: 'lumicore-95c8a',
    seasonKey: 'season-01',
    contentEpoch: 7,
    minimumSupportedVersion: '1.0.18',
    minimumSupportedBuildNumber: '19',
    recommendedVersion: '1.0.18',
    recommendedBuildNumber: '19',
    backendMode: LightcoreBackendMode.localFallback,
    statusMessage: 'Preview environment',
  ),
  profile: const LightcorePlayerProfileSummary(
    playerId: 'GX-74E2-A91C',
    authUid: 'auth-preview-7F31D9A2',
  ),
  offlineClaim: const LightcoreOfflineClaimResult(
    secondsClaimed: 5400,
    lumensGranted: 320,
    fluxGranted: 190,
    enemyTicketsGranted: 2,
    killsGranted: 74,
    serverValidated: true,
    statusMessage: 'Offline rewards queued.',
  ),
  integrityLevel: LightcoreIntegrityLevel.secure,
  firebaseReady: true,
  serverValidated: true,
  appCheckActive: true,
);
