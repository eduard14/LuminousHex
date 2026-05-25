import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/lightcore_guide.dart';
import '../models/lightcore_social_invite_link.dart';
import '../screens/lightcore_main_menu_screen.dart';
import '../screens/lightcore_shell.dart';
import '../services/lightcore_audio.dart';
import '../services/lightcore_firebase_backend.dart';
import '../services/lightcore_firebase_runtime_config.dart';
import '../services/lightcore_session_store.dart';
import '../services/lightcore_web_foreground_events.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../theme/lightcore_theme.dart';
import '../widgets/lightcore_loading_screen.dart';
import '../widgets/lightcore_screen_transition.dart';
import '../widgets/lemon_goose_splash_screen.dart';
import 'lightcore_build_info.dart';
import 'lightcore_bootstrap.dart';
import 'lightcore_dev_flags.dart';

enum _GoogleCollisionAction {
  switchToExistingSave,
  replaceExistingSave,
  cancel,
}

class LightcoreApp extends StatefulWidget {
  const LightcoreApp({super.key, this.backend, this.showStudioSplash = true});

  final FirebaseLightcoreBackend? backend;
  final bool showStudioSplash;

  @override
  State<LightcoreApp> createState() => _LightcoreAppState();
}

class _LightcoreAppState extends State<LightcoreApp>
    with WidgetsBindingObserver {
  static const Duration _cloudSaveDebounce = Duration(seconds: 45);
  static const Duration _serverSyncInterval = Duration(minutes: 3);
  static const Duration _socialOverviewRefreshInterval = Duration(minutes: 3);
  static const Duration _screenLinkDuration = Duration(milliseconds: 820);
  static const Duration _studioSplashDuration = Duration(milliseconds: 1650);
  static const int _maxMissedServerSyncs = 2;

  late final LightcoreSessionStore _sessionStore;
  late final FirebaseLightcoreBackend _backend;
  late final LightcoreSocialInviteLink? _startupSocialInvite;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late LightcoreGuestSession _guestSession;

  LightcoreBootstrapReport? _bootstrapReport;
  LightcoreGuideProfile? _guideProfile;
  LightcoreController? _controller;
  LightcoreController? _observedController;
  Timer? _cloudSaveTimer;
  Timer? _serverSyncTimer;
  Timer? _socialOverviewTimer;
  Timer? _studioSplashTimer;
  LightcoreWebForegroundSubscription? _webForegroundSubscription;
  LightcoreOfflineClaimResult? _startupOfflineClaim;
  _ResolvedClientVersion _clientVersion = const _ResolvedClientVersion(
    versionName: LightcoreBuildInfo.versionName,
    buildNumber: LightcoreBuildInfo.buildNumber,
  );
  bool _enteredGame = false;
  bool _showStudioSplash = true;
  bool _isBootstrapping = true;
  bool _isLinkingScreen = false;
  bool _authBusy = false;
  bool _cloudSavePending = false;
  bool _cloudSaveInFlight = false;
  bool _serverSyncInFlight = false;
  bool _socialOverviewSyncInFlight = false;
  bool _serverSyncPending = false;
  bool _serverSyncPendingForceSave = false;
  bool _skipGuestSignInPrompt = false;
  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  LightcoreGraphicsQuality _graphicsQuality = LightcoreGraphicsQuality.high;
  int _missedServerSyncs = 0;
  int _battleSurfaceGeneration = 0;
  int _bootstrapRunId = 0;
  DateTime? _lastForegroundRecoveryAt;
  DateTime? _lastSocialOverviewSyncAt;
  String? _sessionNotice;

  static bool get _localhostAutoTapperEnabled {
    return shouldEnableLocalhostAutoTapper(isWeb: kIsWeb, uri: Uri.base);
  }

  static int? get _devLayerOverride {
    if (!kDebugMode) {
      return null;
    }
    const dartDefineLayer = int.fromEnvironment('LIGHTCORE_DEV_LAYER');
    final parsedLayer = dartDefineLayer > 0
        ? dartDefineLayer
        : int.tryParse(Uri.base.queryParameters['devLayer'] ?? '');
    if (parsedLayer == null || parsedLayer <= 1) {
      return null;
    }
    if (parsedLayer > LightcoreController.maxShellTier) {
      return LightcoreController.maxShellTier;
    }
    return parsedLayer;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStore = LightcoreSessionStore();
    _backend =
        widget.backend ??
        FirebaseLightcoreBackend(runtimeConfig: lightcoreFirebaseRuntimeConfig);
    _webForegroundSubscription = listenForLightcoreWebForeground(
      _handleWebForeground,
    );
    _startupSocialInvite = LightcoreSocialInviteLink.maybeFromUri(Uri.base);
    _guestSession = createGuestSession();
    _showStudioSplash = widget.showStudioSplash;
    if (_showStudioSplash) {
      _studioSplashTimer = Timer(_studioSplashDuration, () {
        if (mounted) {
          setState(() => _showStudioSplash = false);
        }
      });
    }
    unawaited(_bootstrapMainMenu(reason: 'startup'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webForegroundSubscription?.cancel();
    _cloudSaveTimer?.cancel();
    _serverSyncTimer?.cancel();
    _socialOverviewTimer?.cancel();
    _studioSplashTimer?.cancel();
    unawaited(_runServerSync(forceCloudSave: true));
    unawaited(LightcoreAudio.instance.dispose());
    _observedController?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _lastForegroundRecoveryAt = null;
      _stopServerSyncTimer();
      unawaited(_runServerSync(forceCloudSave: true));
      return;
    }

    if (state == AppLifecycleState.resumed && _hasActiveGame) {
      _recoverForegroundGameSession();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        !_enteredGame &&
        !_isLinkingScreen &&
        !_isBootstrapping &&
        !_authBusy) {
      unawaited(_bootstrapMainMenu(reason: 'lifecycle-resumed-main-menu'));
    }
  }

  void _handleWebForeground() {
    if (!mounted) {
      return;
    }
    if (_hasActiveGame) {
      _recoverForegroundGameSession();
      return;
    }
    if (!_enteredGame && !_isLinkingScreen && !_isBootstrapping && !_authBusy) {
      unawaited(_bootstrapMainMenu(reason: 'web-foreground-main-menu'));
    }
  }

  void _recoverForegroundGameSession() {
    final now = DateTime.now();
    final lastRecovery = _lastForegroundRecoveryAt;
    if (lastRecovery != null &&
        now.difference(lastRecovery) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastForegroundRecoveryAt = now;
    _logSession('foreground-recovery-start');
    _controller?.recoverBattleSession();
    _refreshBattleSurface();
    _startServerSyncTimer();
    unawaited(_resumeOnlineGameSession());
  }

  Future<void> _bootstrapMainMenu({String reason = 'manual'}) async {
    final runId = ++_bootstrapRunId;
    _logSession('bootstrap-start', <String, Object?>{'reason': reason});
    if (mounted) {
      setState(() => _isBootstrapping = true);
    }

    var guestSession = _guestSession;
    LightcoreGuideProfile? guideProfile = _guideProfile;
    var skipGuestSignInPrompt = _skipGuestSignInPrompt;
    var musicEnabled = true;
    var soundEffectsEnabled = true;
    var graphicsQuality = _graphicsQuality;
    try {
      final persistedPlayerId = await _sessionStore.readPlayerId();
      if (persistedPlayerId != null && persistedPlayerId.isNotEmpty) {
        guestSession = LightcoreGuestSession(
          playerId: persistedPlayerId,
          createdAt: DateTime.now(),
          authLabel: 'Stored guest session',
        );
      } else {
        await _sessionStore.writePlayerId(guestSession.playerId);
      }
      guideProfile = LightcoreGuideProfile.maybeFromStorageId(
        await _sessionStore.readGuideId(),
      );
      skipGuestSignInPrompt = await _sessionStore.readSkipGuestSignInPrompt();
      musicEnabled = await _sessionStore.readMusicEnabled();
      soundEffectsEnabled = await _sessionStore.readSoundEffectsEnabled();
      graphicsQuality =
          LightcoreGraphicsQuality.maybeFromStorageValue(
            await _sessionStore.readGraphicsQuality(),
          ) ??
          graphicsQuality;
    } catch (error) {
      // Shared preferences are optional for tests and unsupported contexts.
      _logSession('bootstrap-session-store-warning', <String, Object?>{
        'reason': reason,
        'error': error,
      });
    }

    final clientVersion = await _resolveClientVersion();
    if (!_isCurrentBootstrapRun(runId)) {
      _logSession('bootstrap-abandoned', <String, Object?>{
        'reason': reason,
        'cause': 'stale-run',
      });
      return;
    }
    late final LightcoreBootstrapReport report;
    try {
      report = await _backend.bootstrap(
        guestSession: guestSession,
        clientVersion: clientVersion.versionName,
        clientBuildNumber: clientVersion.buildNumber,
      );
    } catch (error) {
      _logSession('bootstrap-backend-error', <String, Object?>{
        'reason': reason,
        'error': error,
      });
      report = LightcoreBootstrapReport(
        guestSession: guestSession,
        clientVersion: clientVersion.versionName,
        clientBuildNumber: clientVersion.buildNumber,
        manifest:
            createDefaultContentManifest(
              firebaseProjectId: lightcoreFirebaseRuntimeConfig.projectId,
            ).copyWith(
              statusMessage:
                  'Startup sync failed. Reconnect and retry from the main menu.',
            ),
        profile: LightcorePlayerProfileSummary(playerId: guestSession.playerId),
        offlineClaim: LightcoreOfflineClaimResult.empty(
          statusMessage: 'Startup sync failed.',
        ),
        integrityLevel: LightcoreIntegrityLevel.localOnly,
        firebaseReady: false,
        serverValidated: false,
        appCheckActive: false,
        warnings: <String>['Bootstrap failed: $error'],
      );
    }
    final cloudGuide = LightcoreGuideProfile.maybeFromStorageId(
      report.cloudSave?.guideStorageId,
    );
    if (!_isCurrentBootstrapRun(runId)) {
      _logSession('bootstrap-abandoned', <String, Object?>{
        'reason': reason,
        'cause': 'stale-run',
      });
      return;
    }
    if (guideProfile == null && cloudGuide != null) {
      guideProfile = cloudGuide;
      try {
        await _sessionStore.writeGuideId(cloudGuide.storageId);
      } catch (_) {
        // Shared preferences are optional for tests and unsupported contexts.
      }
    }
    try {
      await _sessionStore.writePlayerId(report.profile.playerId);
    } catch (error) {
      // Shared preferences are optional for tests and unsupported contexts.
      _logSession('bootstrap-player-store-warning', <String, Object?>{
        'reason': reason,
        'error': error,
      });
    }

    if (!mounted) {
      _logSession('bootstrap-abandoned', <String, Object?>{'reason': reason});
      return;
    }

    if (!_isCurrentBootstrapRun(runId)) {
      _logSession('bootstrap-abandoned', <String, Object?>{
        'reason': reason,
        'cause': 'stale-run',
      });
      return;
    }
    _logBootstrapReport('bootstrap-complete', report, reason: reason);
    setState(() {
      _clientVersion = clientVersion;
      _guestSession = guestSession;
      _bootstrapReport = report;
      _guideProfile = guideProfile;
      _skipGuestSignInPrompt = skipGuestSignInPrompt;
      _musicEnabled = musicEnabled;
      _soundEffectsEnabled = soundEffectsEnabled;
      _graphicsQuality = graphicsQuality;
      if (report.serverValidated) {
        _sessionNotice = null;
      }
      _isBootstrapping = false;
    });
    unawaited(
      LightcoreAudio.instance.initialize(
        musicEnabled: musicEnabled,
        soundEffectsEnabled: soundEffectsEnabled,
      ),
    );
    _syncMusicForCurrentScreen();
  }

  bool _isCurrentBootstrapRun(int runId) => runId == _bootstrapRunId;

  Future<_ResolvedClientVersion> _resolveClientVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return _normalizeClientVersion(
        versionName: info.version,
        buildNumber: info.buildNumber,
      );
    } catch (_) {
      return const _ResolvedClientVersion(
        versionName: LightcoreBuildInfo.versionName,
        buildNumber: LightcoreBuildInfo.buildNumber,
      );
    }
  }

  void _enterGame() {
    LightcoreAudio.instance.noteUserGesture();
    LightcoreAudio.instance.playSfx(LightcoreSfx.uiConfirm);
    unawaited(_enterGameFromServer());
  }

  Future<void> _enterGameFromServer() async {
    final report = _bootstrapReport;
    if (report == null ||
        !report.canEnterGame ||
        _hasActiveGame ||
        _isLinkingScreen) {
      _logSession('enter-game-ignored', <String, Object?>{
        'hasReport': report != null,
        'reportCanEnter': report?.canEnterGame,
        'hasActiveGame': _hasActiveGame,
        'isLinkingScreen': _isLinkingScreen,
        'blocker': _launchBlocker(report),
      });
      return;
    }

    _logBootstrapReport('enter-game-start', report, reason: 'current-report');
    setState(() {
      _isLinkingScreen = true;
      _sessionNotice = null;
    });

    final launchReport = report;
    if (_serverRestoreIncomplete(launchReport)) {
      _logBootstrapReport(
        'enter-game-blocked',
        launchReport,
        reason: 'cloud-restore-incomplete',
      );
      setState(() {
        _isLinkingScreen = false;
        _sessionNotice =
            'Startup sync did not finish. Retry to restore your cloud save and offline progress.';
      });
      return;
    }

    final replacedController = _controller;
    final controller = _createControllerFromReport(launchReport);
    _logBootstrapReport(
      'enter-game-controller-created',
      launchReport,
      reason: _controllerCreationReason(launchReport),
    );
    controller.syncServerDateKeys(
      dayKey: launchReport.serverDayKey,
      weekKey: launchReport.serverWeekKey,
    );
    controller.syncServerClock(launchReport.serverTime);
    controller.syncBalanceTuning(launchReport.manifest.balanceTuning);
    controller.setGraphicsQuality(_graphicsQuality);
    controller.setLocalhostAutoTapperEnabled(_localhostAutoTapperEnabled);
    final startupOfflineClaim = launchReport.offlineClaim.hasProgress
        ? launchReport.offlineClaim
        : null;
    if (startupOfflineClaim != null) {
      controller.applyOfflineClaim(startupOfflineClaim, showBanner: false);
    }
    controller.syncPlayerProfile(launchReport.profile, showBanner: false);
    _applyDevLayerOverride(controller);
    _socialOverviewTimer?.cancel();
    _socialOverviewTimer = null;
    _lastSocialOverviewSyncAt = null;
    unawaited(_syncSocialOverview(controller));
    _observeController(controller);
    _missedServerSyncs = 0;

    setState(() {
      _controller = controller;
      _startupOfflineClaim = startupOfflineClaim;
      _isLinkingScreen = true;
      _sessionNotice = null;
    });
    if (replacedController != null &&
        !identical(replacedController, controller)) {
      replacedController.dispose();
    }
    _markCloudSaveDirty();
    unawaited(_runServerSync(forceCloudSave: true));
    unawaited(_completeScreenLink());
  }

  LightcoreController _createControllerFromReport(
    LightcoreBootstrapReport report,
  ) {
    if (_devLayerOverride == null && report.cloudSave?.hasPayload == true) {
      return LightcoreController.fromCloudSavePayload(
        report.cloudSave!.payload,
        fallbackGuideProfile: _guideProfile ?? LightcoreGuideProfile.lumo,
        balanceTuning: report.manifest.balanceTuning,
      );
    }
    return LightcoreController(
      guideProfile: _guideProfile ?? LightcoreGuideProfile.lumo,
      balanceTuning: report.manifest.balanceTuning,
    );
  }

  void _applyDevLayerOverride(LightcoreController controller) {
    final targetLayer = _devLayerOverride;
    if (targetLayer == null) {
      return;
    }
    final applied = controller.debugSeedProgressionLayer(targetLayer);
    _logSession('dev-layer-override', <String, Object?>{
      'targetLayer': targetLayer,
      'applied': applied,
    });
  }

  String _controllerCreationReason(LightcoreBootstrapReport report) {
    if (_devLayerOverride != null) {
      return 'dev-layer-override';
    }
    if (report.cloudSave?.hasPayload == true) {
      return 'cloud-save';
    }
    return 'fresh-local-controller';
  }

  bool _serverRestoreIncomplete(LightcoreBootstrapReport report) {
    if (!report.cloudRestoreRequired) {
      return false;
    }
    return !report.cloudRestoreComplete;
  }

  Future<void> _completeScreenLink() async {
    await Future<void>.delayed(_screenLinkDuration);
    if (!mounted || !_isLinkingScreen) {
      return;
    }
    if (_controller == null) {
      setState(() {
        _enteredGame = false;
        _isLinkingScreen = false;
      });
      return;
    }
    setState(() {
      _enteredGame = true;
      _isLinkingScreen = false;
    });
    _syncMusicForCurrentScreen();
    _logSession('enter-game-complete');
    _startServerSyncTimer();
  }

  void _selectGuide(LightcoreGuideProfile guideProfile) {
    setState(() => _guideProfile = guideProfile);
    unawaited(_sessionStore.writeGuideId(guideProfile.storageId));
  }

  void _setSkipGuestSignInPrompt(bool skipPrompt) {
    if (_skipGuestSignInPrompt == skipPrompt) {
      return;
    }
    setState(() => _skipGuestSignInPrompt = skipPrompt);
    unawaited(_sessionStore.writeSkipGuestSignInPrompt(skipPrompt));
  }

  void _setMusicEnabled(bool enabled) {
    if (_musicEnabled == enabled) {
      return;
    }
    setState(() => _musicEnabled = enabled);
    unawaited(_sessionStore.writeMusicEnabled(enabled));
    unawaited(_applyMusicEnabled(enabled));
  }

  Future<void> _applyMusicEnabled(bool enabled) async {
    await LightcoreAudio.instance.setMusicEnabled(enabled);
    if (enabled) {
      _syncMusicForCurrentScreen();
    }
  }

  void _setSoundEffectsEnabled(bool enabled) {
    if (_soundEffectsEnabled == enabled) {
      return;
    }
    setState(() => _soundEffectsEnabled = enabled);
    LightcoreAudio.instance.setSoundEffectsEnabled(enabled);
    unawaited(_sessionStore.writeSoundEffectsEnabled(enabled));
  }

  void _syncMusicForCurrentScreen() {
    if (_isLinkingScreen) {
      return;
    }
    final track = _hasActiveGame
        ? LightcoreMusicTrack.battle
        : LightcoreMusicTrack.mainMenu;
    unawaited(LightcoreAudio.instance.playMusic(track));
  }

  Future<LightcoreServerSyncResult?> _syncOfflineSnapshot() async {
    final controller = _controller;
    if (controller == null) {
      return null;
    }

    try {
      return await _backend.syncOfflineSnapshot(
        controller.buildOfflineProgressSnapshot(),
        clientVersion: _clientVersion.versionName,
        clientBuildNumber: _clientVersion.buildNumber,
      );
    } on LightcoreSessionExpiredException {
      rethrow;
    } catch (error) {
      // Snapshot sync is best-effort and should never block app lifecycle.
      _logSession('server-sync-snapshot-error', <String, Object?>{
        'error': error,
      });
      return null;
    }
  }

  void _startServerSyncTimer() {
    if (!_enteredGame || _controller == null) {
      return;
    }
    _serverSyncTimer ??= Timer.periodic(_serverSyncInterval, (_) {
      unawaited(_runServerSync());
    });
  }

  void _stopServerSyncTimer() {
    _serverSyncTimer?.cancel();
    _serverSyncTimer = null;
  }

  Future<void> _resumeOnlineGameSession() async {
    await _claimForegroundOfflineProgress();
    await _runServerSync(forceCloudSave: true);
  }

  Future<void> _claimForegroundOfflineProgress() async {
    final controller = _controller;
    if (controller == null || !_cloudSaveEnabled) {
      _logSession('offline-claim-skipped', <String, Object?>{
        'hasController': controller != null,
        'cloudSaveEnabled': _cloudSaveEnabled,
      });
      return;
    }

    try {
      _logSession('offline-claim-start');
      final claim = await _backend.claimOfflineProgress();
      if (!_isCurrentGameController(controller)) {
        _logSession('offline-claim-abandoned');
        return;
      }
      if (!claim.hasProgress) {
        _logSession('offline-claim-complete', <String, Object?>{
          'hasRewards': false,
          'status': claim.statusMessage,
        });
        return;
      }
      _logSession('offline-claim-complete', <String, Object?>{
        'hasRewards': claim.hasRewards,
        'seconds': claim.secondsClaimed,
        'lumens': claim.lumensGranted,
        'flux': claim.fluxGranted,
        'tickets': claim.enemyTicketsGranted,
      });
      controller.applyOfflineClaim(claim);
      if (mounted) {
        setState(() => _startupOfflineClaim = claim);
      } else {
        _startupOfflineClaim = claim;
      }
      await _flushCloudSave(force: true);
    } on LightcoreSessionExpiredException catch (error) {
      _logSession('offline-claim-session-expired', <String, Object?>{
        'message': error.message,
      });
      _expireActiveSession(error.message);
    } catch (error) {
      // Foreground reward reconciliation retries on the next heartbeat/bootstrap.
      _logSession('offline-claim-error', <String, Object?>{'error': error});
    }
  }

  Future<void> _runServerSync({bool forceCloudSave = false}) async {
    if (_serverSyncInFlight) {
      _serverSyncPending = true;
      _serverSyncPendingForceSave =
          _serverSyncPendingForceSave || forceCloudSave;
      if (forceCloudSave) {
        _cloudSavePending = true;
      }
      return;
    }

    final controller = _controller;
    if (controller == null || !_cloudSaveEnabled) {
      _logSession('server-sync-skipped', <String, Object?>{
        'hasController': controller != null,
        'cloudSaveEnabled': _cloudSaveEnabled,
        'forceCloudSave': forceCloudSave,
      });
      return;
    }

    _serverSyncInFlight = true;
    _logSession('server-sync-start', <String, Object?>{
      'forceCloudSave': forceCloudSave,
    });
    try {
      final syncResult = await _syncOfflineSnapshot();
      if (!_isCurrentGameController(controller)) {
        _logSession('server-sync-abandoned');
        return;
      }
      if (syncResult != null) {
        _markServerSyncHealthy();
        _logSession('server-sync-complete', <String, Object?>{
          'accepted': syncResult.accepted,
          'sessionId': _redact(syncResult.sessionId),
          'versionGate': syncResult.versionGate,
        });
        _applyServerSyncResult(syncResult);
      } else if (_enteredGame) {
        _markServerSyncMissed();
        _logSession('server-sync-missed', <String, Object?>{
          'missedServerSyncs': _missedServerSyncs,
          'maxMissedServerSyncs': _maxMissedServerSyncs,
        });
        if (_sessionShouldExpire) {
          _expireActiveSession();
          return;
        }
      }
      await _flushCloudSave(force: forceCloudSave);
    } on LightcoreSessionExpiredException catch (error) {
      _logSession('server-sync-session-expired', <String, Object?>{
        'message': error.message,
      });
      _expireActiveSession(error.message);
    } finally {
      _serverSyncInFlight = false;
      if (_serverSyncPending && mounted) {
        final pendingForceSave = _serverSyncPendingForceSave;
        _serverSyncPending = false;
        _serverSyncPendingForceSave = false;
        unawaited(_runServerSync(forceCloudSave: pendingForceSave));
      }
    }
  }

  void _applyServerSyncResult(LightcoreServerSyncResult syncResult) {
    final controller = _controller;
    controller?.syncServerDateKeys(
      dayKey: syncResult.serverDayKey,
      weekKey: syncResult.serverWeekKey,
    );
    controller?.syncServerClock(syncResult.serverTime);
    controller?.syncBalanceTuning(syncResult.manifest.balanceTuning);
    controller?.syncPlayerProfile(syncResult.profile, showBanner: false);

    final previous = _bootstrapReport;
    if (previous == null) {
      return;
    }

    final nextReport = LightcoreBootstrapReport(
      guestSession: previous.guestSession,
      clientVersion: _clientVersion.versionName,
      clientBuildNumber: _clientVersion.buildNumber,
      manifest: syncResult.manifest,
      profile: syncResult.profile,
      offlineClaim: previous.offlineClaim,
      integrityLevel:
          previous.integrityLevel == LightcoreIntegrityLevel.localOnly
          ? LightcoreIntegrityLevel.degraded
          : previous.integrityLevel,
      firebaseReady: previous.firebaseReady,
      serverValidated: true,
      appCheckActive: previous.appCheckActive,
      sessionId: syncResult.sessionId ?? previous.sessionId,
      serverTime: syncResult.serverTime,
      serverDayKey: syncResult.serverDayKey ?? previous.serverDayKey,
      serverWeekKey: syncResult.serverWeekKey ?? previous.serverWeekKey,
      cloudSave: _backend.cachedCloudSave,
      cloudRestoreRequired: previous.cloudRestoreRequired,
      cloudRestoreComplete: previous.cloudRestoreComplete,
      warnings: previous.warnings,
    );

    if (!mounted) {
      _bootstrapReport = nextReport;
      return;
    }

    setState(() {
      _bootstrapReport = nextReport;
      if (_enteredGame && nextReport.hardBlocked) {
        _enteredGame = false;
        _isLinkingScreen = false;
        _startupOfflineClaim = null;
        _stopServerSyncTimer();
      }
    });
    _syncMusicForCurrentScreen();
  }

  bool get _sessionShouldExpire => _missedServerSyncs >= _maxMissedServerSyncs;

  bool get _hasActiveGame => _enteredGame && _controller != null;

  bool _isCurrentGameController(LightcoreController controller) =>
      mounted && identical(_controller, controller);

  void _disposeControllerAfterExit(LightcoreController controller) {
    Future<void>.delayed(_screenLinkDuration, () {
      if (!identical(_controller, controller)) {
        controller.dispose();
      }
    });
  }

  void _markServerSyncHealthy() {
    _missedServerSyncs = 0;
  }

  void _markServerSyncMissed() {
    _missedServerSyncs += 1;
  }

  void _expireActiveSession([String? message]) {
    _logSession('session-expired', <String, Object?>{
      'message': message,
      'hadController': _controller != null,
      'enteredGame': _enteredGame,
      'isLinkingScreen': _isLinkingScreen,
      'cloudSavePending': _cloudSavePending,
      'cloudSaveInFlight': _cloudSaveInFlight,
      'serverSyncInFlight': _serverSyncInFlight,
    });
    _stopServerSyncTimer();
    _cloudSaveTimer?.cancel();
    _cloudSaveTimer = null;
    _socialOverviewTimer?.cancel();
    _socialOverviewTimer = null;
    _cloudSavePending = false;
    _serverSyncPending = false;
    _serverSyncPendingForceSave = false;
    _socialOverviewSyncInFlight = false;
    _lastSocialOverviewSyncAt = null;
    _missedServerSyncs = 0;

    final expiredController = _controller;
    _observedController?.removeListener(_handleControllerChanged);
    _observedController = null;

    if (!mounted) {
      _controller = null;
      _enteredGame = false;
      _isLinkingScreen = false;
      _startupOfflineClaim = null;
      _sessionNotice = _sessionExpiredMessage(message);
      expiredController?.dispose();
      return;
    }

    setState(() {
      _controller = null;
      _enteredGame = false;
      _isLinkingScreen = false;
      _startupOfflineClaim = null;
      _sessionNotice = _sessionExpiredMessage(message);
    });
    _syncMusicForCurrentScreen();
    if (expiredController != null) {
      _disposeControllerAfterExit(expiredController);
    }
  }

  void _refreshBattleSurface() {
    if (!mounted) {
      _battleSurfaceGeneration += 1;
      return;
    }
    setState(() {
      _battleSurfaceGeneration += 1;
    });
  }

  String _sessionExpiredMessage(String? message) {
    final normalized = message?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return 'Session expired. Reconnect to claim server-calculated offline progress.';
  }

  void _scheduleSocialOverviewSync(
    LightcoreController controller,
    Duration delay,
  ) {
    if (_socialOverviewTimer != null) {
      return;
    }
    _socialOverviewTimer = Timer(delay, () {
      _socialOverviewTimer = null;
      if (_isCurrentGameController(controller)) {
        unawaited(_flushCloudSave(force: true));
      }
    });
  }

  Future<void> _syncSocialOverview(
    LightcoreController controller, {
    bool force = false,
  }) async {
    if (_socialOverviewSyncInFlight) {
      if (!force) {
        _scheduleSocialOverviewSync(controller, _socialOverviewRefreshInterval);
      }
      return;
    }
    final lastSync = _lastSocialOverviewSyncAt;
    if (!force && lastSync != null) {
      final elapsed = DateTime.now().difference(lastSync);
      final remaining = _socialOverviewRefreshInterval - elapsed;
      if (remaining > Duration.zero) {
        _scheduleSocialOverviewSync(controller, remaining);
        return;
      }
    }
    _socialOverviewTimer?.cancel();
    _socialOverviewTimer = null;
    _socialOverviewSyncInFlight = true;
    try {
      final overview = await _backend.fetchSocialOverview();
      _lastSocialOverviewSyncAt = DateTime.now();
      if (!_isCurrentGameController(controller)) {
        return;
      }
      controller.syncSocialOverview(overview);
    } catch (_) {
      // Social bonuses are online-only and should not block entering the game.
    } finally {
      _socialOverviewSyncInFlight = false;
    }
  }

  Future<bool> _signInWithGoogle() async {
    if (_authBusy) {
      _logSession('google-sign-in-ignored', <String, Object?>{
        'reason': 'auth-busy',
      });
      return false;
    }
    final controller = _controller;
    final linkCurrentGame = _enteredGame && controller != null;
    final replacementPayload = _googleReplacementPayload(controller);
    _logSession('google-sign-in-start', <String, Object?>{
      'linkCurrentGame': linkCurrentGame,
    });
    setState(() => _authBusy = true);
    try {
      if (linkCurrentGame) {
        await _flushCloudSave(force: true);
      }
      await _backend.signInWithGoogle(requireAnonymousLink: linkCurrentGame);
      await _bootstrapMainMenu(reason: 'after-google-sign-in');
      if (linkCurrentGame) {
        final profile = _bootstrapReport?.profile;
        if (profile != null) {
          controller.syncPlayerProfile(profile, showBanner: false);
        }
        try {
          await _backend.savePlayerSave(
            controller.buildCloudSavePayload(),
            clientVersion: _clientVersion.versionName,
            clientBuildNumber: _clientVersion.buildNumber,
          );
          controller.pushNotification(
            'Google account linked. This save can now recover on other devices.',
            duration: 4.2,
          );
        } on LightcoreSessionExpiredException catch (error) {
          _expireActiveSession(error.message);
        } catch (_) {
          controller.pushNotification(
            'Google account linked. Cloud backup will retry when the backend is reachable.',
            duration: 4.2,
          );
        }
        unawaited(_syncSocialOverview(controller));
      }
      _logSession('google-sign-in-complete', <String, Object?>{
        'linkCurrentGame': linkCurrentGame,
      });
      return true;
    } on LightcoreGoogleAccountCollisionException catch (collision) {
      _logSession('google-sign-in-collision', <String, Object?>{
        'email': collision.email == null ? null : _redact(collision.email),
        'linkCurrentGame': linkCurrentGame,
      });
      if (!mounted) {
        return false;
      }
      return await _resolveGoogleAccountCollision(
        collision: collision,
        replacementPayload: replacementPayload,
        activeController: controller,
        linkCurrentGame: linkCurrentGame,
      );
    } catch (error) {
      _logSession('google-sign-in-error', <String, Object?>{'error': error});
      if (!mounted) {
        return false;
      }
      final controller = _controller;
      if (_enteredGame && controller != null) {
        controller.pushNotification(
          'Google sign-in failed: $error',
          duration: 4.8,
        );
      } else {
        _showSnackBar('Google sign-in failed: $error');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  Map<String, dynamic>? _googleReplacementPayload(
    LightcoreController? controller,
  ) {
    if (_enteredGame && controller != null) {
      return controller.buildCloudSavePayload();
    }
    final payload = _bootstrapReport?.cloudSave?.payload;
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(payload);
  }

  Future<bool> _resolveGoogleAccountCollision({
    required LightcoreGoogleAccountCollisionException collision,
    required Map<String, dynamic>? replacementPayload,
    required LightcoreController? activeController,
    required bool linkCurrentGame,
  }) async {
    final action = await _showGoogleAccountCollisionDialog(collision);
    if (!mounted || action == null || action == _GoogleCollisionAction.cancel) {
      _backend.cancelPendingGoogleAccountCollision();
      return false;
    }

    if (action == _GoogleCollisionAction.replaceExistingSave) {
      final confirmed = await _confirmReplaceGoogleAccount(collision);
      if (!mounted || !confirmed) {
        _backend.cancelPendingGoogleAccountCollision();
        return false;
      }
    }

    try {
      switch (action) {
        case _GoogleCollisionAction.switchToExistingSave:
          await _backend.resolvePendingGoogleAccountCollision(
            LightcoreGoogleAccountCollisionResolution.switchToExistingSave,
          );
          await _bootstrapMainMenu(reason: 'after-google-account-switch');
          if (linkCurrentGame) {
            await _replaceActiveGameFromCurrentBootstrapReport(
              reason: 'after-google-account-switch',
            );
          }
          _notifyGoogleCollisionResolved(
            'Switched to the Google-linked LumiHex save.',
          );
          break;
        case _GoogleCollisionAction.replaceExistingSave:
          await _backend.resolvePendingGoogleAccountCollision(
            LightcoreGoogleAccountCollisionResolution.replaceExistingSave,
          );
          await _bootstrapMainMenu(reason: 'after-google-account-replace');
          if (replacementPayload != null) {
            await _backend.savePlayerSave(
              replacementPayload,
              clientVersion: _clientVersion.versionName,
              clientBuildNumber: _clientVersion.buildNumber,
            );
            if (!linkCurrentGame) {
              await _bootstrapMainMenu(
                reason: 'after-google-account-replace-save',
              );
            }
          }
          if (linkCurrentGame && activeController != null) {
            final profile = _bootstrapReport?.profile;
            if (profile != null) {
              activeController.syncPlayerProfile(profile, showBanner: false);
            }
            unawaited(_syncSocialOverview(activeController));
          }
          _notifyGoogleCollisionResolved(
            'Old Google-linked LumiHex save deleted. This save is now linked to Google.',
          );
          break;
        case _GoogleCollisionAction.cancel:
          return false;
      }
      _logSession('google-sign-in-collision-resolved', <String, Object?>{
        'action': action.name,
        'linkCurrentGame': linkCurrentGame,
      });
      return true;
    } catch (error) {
      _logSession('google-sign-in-collision-error', <String, Object?>{
        'action': action.name,
        'error': error,
      });
      if (!mounted) {
        return false;
      }
      final controller = _controller;
      if (_enteredGame && controller != null) {
        controller.pushNotification(
          'Google account update failed: $error',
          duration: 4.8,
        );
      } else {
        _showSnackBar('Google account update failed: $error');
      }
      return false;
    }
  }

  Future<_GoogleCollisionAction?> _showGoogleAccountCollisionDialog(
    LightcoreGoogleAccountCollisionException collision,
  ) {
    final email = collision.email;
    return showDialog<_GoogleCollisionAction>(
      context: _navigatorKey.currentContext ?? context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          key: const ValueKey<String>('google-account-collision-dialog'),
          backgroundColor: LightcorePalette.panel,
          surfaceTintColor: Colors.transparent,
          title: const Text('Google Account Already Linked'),
          content: Text(
            email == null
                ? 'That Google account is already linked to another LumiHex save. Switch to that save, delete it and link this save, or cancel.'
                : 'The Google account $email is already linked to another LumiHex save. Switch to that save, delete it and link this save, or cancel.',
          ),
          actions: [
            TextButton(
              key: const ValueKey<String>('google-collision-cancel-button'),
              onPressed: () {
                Navigator.of(context).pop(_GoogleCollisionAction.cancel);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const ValueKey<String>('google-collision-switch-button'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(_GoogleCollisionAction.switchToExistingSave);
              },
              child: const Text('Switch to Google Save'),
            ),
            FilledButton(
              key: const ValueKey<String>('google-collision-replace-button'),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(_GoogleCollisionAction.replaceExistingSave);
              },
              child: const Text('Delete Old Save & Link This Save'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmReplaceGoogleAccount(
    LightcoreGoogleAccountCollisionException collision,
  ) async {
    final email = collision.email;
    final confirmed = await showDialog<bool>(
      context: _navigatorKey.currentContext ?? context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          key: const ValueKey<String>('google-replace-confirm-dialog'),
          backgroundColor: LightcorePalette.panel,
          surfaceTintColor: Colors.transparent,
          title: const Text('Delete Old Google Save?'),
          content: Text(
            email == null
                ? 'This permanently deletes the old LumiHex account and cloud save linked to that Google account. Your Google account itself will not be deleted.'
                : 'This permanently deletes the old LumiHex account and cloud save linked to $email. Your Google account itself will not be deleted.',
          ),
          actions: [
            TextButton(
              key: const ValueKey<String>('google-replace-cancel-button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey<String>('google-replace-confirm-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete and Link'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _replaceActiveGameFromCurrentBootstrapReport({
    required String reason,
  }) async {
    final report = _bootstrapReport;
    if (report == null || !report.canEnterGame) {
      _expireActiveSession('Google account switched. Reconnect to load it.');
      return;
    }
    if (_serverRestoreIncomplete(report)) {
      _expireActiveSession(
        'Google account switched, but cloud restore did not finish. Reconnect and retry.',
      );
      return;
    }

    _logBootstrapReport('active-game-reload-start', report, reason: reason);
    _stopServerSyncTimer();
    _cloudSaveTimer?.cancel();
    _cloudSaveTimer = null;
    _cloudSavePending = false;
    _serverSyncPending = false;
    _serverSyncPendingForceSave = false;
    _socialOverviewTimer?.cancel();
    _socialOverviewTimer = null;
    _lastSocialOverviewSyncAt = null;

    final previousController = _controller;
    final controller = _createControllerFromReport(report);
    controller.syncServerDateKeys(
      dayKey: report.serverDayKey,
      weekKey: report.serverWeekKey,
    );
    controller.syncBalanceTuning(report.manifest.balanceTuning);
    controller.setGraphicsQuality(_graphicsQuality);
    controller.setLocalhostAutoTapperEnabled(_localhostAutoTapperEnabled);
    final startupOfflineClaim = report.offlineClaim.hasProgress
        ? report.offlineClaim
        : null;
    if (startupOfflineClaim != null) {
      controller.applyOfflineClaim(startupOfflineClaim, showBanner: false);
    }
    controller.syncPlayerProfile(report.profile, showBanner: false);
    _observeController(controller);
    _missedServerSyncs = 0;

    if (!mounted) {
      _controller = controller;
      _startupOfflineClaim = startupOfflineClaim;
      _enteredGame = true;
      _isLinkingScreen = false;
      previousController?.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _startupOfflineClaim = startupOfflineClaim;
      _enteredGame = true;
      _isLinkingScreen = false;
      _sessionNotice = null;
    });
    _refreshBattleSurface();
    if (previousController != null &&
        !identical(previousController, controller)) {
      previousController.dispose();
    }
    unawaited(_syncSocialOverview(controller));
    _startServerSyncTimer();
    _syncMusicForCurrentScreen();
  }

  void _notifyGoogleCollisionResolved(String message) {
    if (!mounted) {
      return;
    }
    final controller = _controller;
    if (_enteredGame && controller != null) {
      controller.pushNotification(message, duration: 4.2);
    } else {
      _showSnackBar(message);
    }
  }

  Future<void> _signInWithGoogleFromSettings() async {
    await _signInWithGoogle();
  }

  Future<void> _signOutToGuest() async {
    if (_authBusy) {
      return;
    }
    final controller = _controller;
    final inGame = _enteredGame && controller != null;
    setState(() => _authBusy = true);
    try {
      if (inGame) {
        await _flushCloudSave(force: true);
      }
      await _backend.signOutToGuest();
      await _bootstrapMainMenu(reason: 'after-sign-out');
      if (inGame) {
        final profile = _bootstrapReport?.profile;
        if (profile != null) {
          controller.syncPlayerProfile(profile, showBanner: false);
        }
        try {
          await _backend.savePlayerSave(
            controller.buildCloudSavePayload(),
            clientVersion: _clientVersion.versionName,
            clientBuildNumber: _clientVersion.buildNumber,
          );
        } on LightcoreSessionExpiredException catch (error) {
          _expireActiveSession(error.message);
        } catch (_) {
          // A fresh guest session can keep playing locally if cloud init fails.
        }
        controller.pushNotification(
          'Signed out of Google. This device is using guest cloud sync again.',
          duration: 4.0,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      final controller = _controller;
      if (_enteredGame && controller != null) {
        controller.pushNotification('Sign-out failed: $error', duration: 4.8);
      } else {
        _showSnackBar('Sign-out failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _authBusy = false);
      }
    }
  }

  void _observeController(LightcoreController controller) {
    if (_observedController == controller) {
      return;
    }
    _observedController?.removeListener(_handleControllerChanged);
    _observedController = controller;
    controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() {
    final graphicsQuality = _controller?.graphicsQuality;
    if (graphicsQuality != null && graphicsQuality != _graphicsQuality) {
      _graphicsQuality = graphicsQuality;
      unawaited(
        _sessionStore.writeGraphicsQuality(graphicsQuality.storageValue),
      );
    }
    _markCloudSaveDirty();
  }

  void _logBootstrapReport(
    String event,
    LightcoreBootstrapReport? report, {
    required String reason,
  }) {
    _logSession(event, <String, Object?>{
      'reason': reason,
      'hasReport': report != null,
      'canEnterGame': report?.canEnterGame,
      'firebaseReady': report?.firebaseReady,
      'serverValidated': report?.serverValidated,
      'appCheckActive': report?.appCheckActive,
      'versionLabel': report?.versionLabel,
      'versionGate': report?.versionGate.name,
      'restoreRequired': report?.cloudRestoreRequired,
      'restoreComplete': report?.cloudRestoreComplete,
      'cloudSaveHasPayload': report?.cloudSave?.hasPayload,
      'sessionId': _redact(report?.sessionId),
      'profilePlayerId': _redact(report?.profile.playerId),
      'authUid': _redact(report?.profile.authUid),
      'warnings': report?.warnings.join(' | '),
    });
  }

  void _logSession(
    String event, [
    Map<String, Object?> values = const <String, Object?>{},
  ]) {
    if (!_sessionDebugLoggingEnabled) {
      return;
    }
    final details = values.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    debugPrint(
      details.isEmpty
          ? '[LightcoreSession] $event'
          : '[LightcoreSession] $event $details',
    );
  }

  void _showSnackBar(String message) {
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _cloudSaveEnabled =>
      _bootstrapReport?.firebaseReady == true &&
      _backend.canUseCloudSave &&
      _devLayerOverride == null &&
      _controller != null;

  static bool get _sessionDebugLoggingEnabled =>
      const bool.fromEnvironment('LIGHTCORE_SESSION_DEBUG') ||
      Uri.base.queryParameters['sessionDebug'] == '1' ||
      Uri.base.queryParameters['debugErrors'] == '1';

  String _launchBlocker(LightcoreBootstrapReport? report) {
    if (report == null) {
      return 'no-bootstrap-report';
    }
    if (report.manifest.maintenanceMode) {
      return 'maintenance-mode';
    }
    if (!report.versionResolved) {
      return 'server-validation-missing';
    }
    if (!report.latestVersionSatisfied) {
      return 'version-blocked:${report.requiredServerVersion}';
    }
    if (!report.contentResolved) {
      return 'content-verification-failed';
    }
    if (!report.restoreResolved) {
      return 'cloud-restore-incomplete';
    }
    if (!report.canEnterGame) {
      return 'can-enter-false';
    }
    return 'none';
  }

  String? _redact(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.length <= 8) {
      return normalized;
    }
    return '${normalized.substring(0, 4)}...${normalized.substring(normalized.length - 4)}';
  }

  void _markCloudSaveDirty() {
    if (!_cloudSaveEnabled) {
      return;
    }
    _cloudSavePending = true;
    _cloudSaveTimer ??= Timer(_cloudSaveDebounce, () {
      _cloudSaveTimer = null;
      unawaited(_flushCloudSave());
    });
  }

  Future<void> _flushCloudSave({bool force = false}) async {
    if (!_cloudSaveEnabled) {
      return;
    }
    if (force) {
      _cloudSavePending = true;
    }
    if (!_cloudSavePending) {
      return;
    }
    if (_cloudSaveInFlight) {
      _cloudSavePending = true;
      return;
    }

    final controller = _controller;
    if (controller == null) {
      return;
    }
    _cloudSaveTimer?.cancel();
    _cloudSaveTimer = null;
    _cloudSavePending = false;
    _cloudSaveInFlight = true;
    try {
      await _backend.savePlayerSave(
        controller.buildCloudSavePayload(),
        clientVersion: _clientVersion.versionName,
        clientBuildNumber: _clientVersion.buildNumber,
      );
      if (!_isCurrentGameController(controller)) {
        return;
      }
      if (controller.globalTowerStrengthRankNeedsRefresh) {
        unawaited(_syncSocialOverview(controller));
      }
    } on LightcoreSessionExpiredException catch (error) {
      _expireActiveSession(error.message);
    } catch (_) {
      _cloudSavePending = true;
      if (mounted) {
        _cloudSaveTimer ??= Timer(_cloudSaveDebounce, () {
          _cloudSaveTimer = null;
          unawaited(_flushCloudSave());
        });
      }
    } finally {
      _cloudSaveInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final hasActiveGame = _enteredGame && controller != null;
    final Widget currentScreen;
    if (_showStudioSplash) {
      currentScreen = const KeyedSubtree(
        key: ValueKey<String>('lemon-goose-splash'),
        child: LemonGooseSplashScreen(),
      );
    } else if (_isLinkingScreen) {
      currentScreen = KeyedSubtree(
        key: const ValueKey<String>('lightcore-screen-link'),
        child: LightcoreLoadingScreen(
          title: 'Opening Shell',
          subtitle: 'Routing command through the tower lattice.',
          statusLabel: 'Screen Link',
          accent: LightcorePalette.aether,
          signalLabels: ['SYNC', 'LINK', 'ARM'],
          guide: _guideProfile ?? LightcoreGuideProfile.lumo,
          tips: const [
            'The optimal growth strategy may not be 100% flow.',
            'Output Efficiency can beat raw reward boosts when stability starts slipping.',
            'Threat Scans are safer when your tower colors already counter the region.',
            'Managers keep relays moving, but manual taps still bail out pressure spikes.',
          ],
        ),
      );
    } else if (hasActiveGame) {
      currentScreen = KeyedSubtree(
        key: const ValueKey<String>('lightcore-shell'),
        child: LightcoreShell(
          controller: controller,
          backend: _backend,
          battleSurfaceGeneration: _battleSurfaceGeneration,
          clientDisplayVersion: _clientVersion.displayVersion,
          initialOfflineClaim: _startupOfflineClaim,
          initialSocialInvite: _startupSocialInvite,
          authBusy: _authBusy,
          musicEnabled: _musicEnabled,
          soundEffectsEnabled: _soundEffectsEnabled,
          onMusicEnabledChanged: _setMusicEnabled,
          onSoundEffectsEnabledChanged: _setSoundEffectsEnabled,
          onGoogleSignIn: _signInWithGoogleFromSettings,
          onSignOut: _signOutToGuest,
        ),
      );
    } else {
      currentScreen = KeyedSubtree(
        key: const ValueKey<String>('lightcore-main-menu'),
        child: LightcoreMainMenuScreen(
          guestSession: _guestSession,
          bootstrapReport: _bootstrapReport,
          guideProfile: _guideProfile,
          isLoading: _isBootstrapping,
          onEnterGame: _enterGame,
          onSelectGuide: _selectGuide,
          onRetryBootstrap: () => unawaited(_bootstrapMainMenu()),
          authBusy: _authBusy,
          sessionNotice: _sessionNotice,
          skipGuestSignInPrompt: _skipGuestSignInPrompt,
          onGoogleSignIn: _signInWithGoogle,
          onSkipGuestSignInPromptChanged: _setSkipGuestSignInPrompt,
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      title: 'LumiHex',
      theme: buildLightcoreTheme(),
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        backgroundColor: LightcorePalette.night,
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => LightcoreAudio.instance.noteUserGesture(),
          child: LightcoreTransitionSwitcher(
            duration: const Duration(milliseconds: 650),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            enterOffset: hasActiveGame ? const Offset(0, 0.045) : Offset.zero,
            tint: hasActiveGame
                ? LightcorePalette.verdant
                : LightcorePalette.aether,
            child: currentScreen,
          ),
        ),
      ),
    );
  }
}

class _ResolvedClientVersion {
  const _ResolvedClientVersion({
    required this.versionName,
    required this.buildNumber,
  });

  final String versionName;
  final String buildNumber;

  String get displayVersion {
    final version = versionName.trim();
    final build = buildNumber.trim();
    if (build.isEmpty) {
      return version;
    }
    return '$version+$build';
  }
}

_ResolvedClientVersion _normalizeClientVersion({
  required String versionName,
  required String buildNumber,
}) {
  const fallback = _ResolvedClientVersion(
    versionName: LightcoreBuildInfo.versionName,
    buildNumber: LightcoreBuildInfo.buildNumber,
  );
  final resolvedVersion = versionName.trim();
  final resolvedBuild = buildNumber.trim();
  if (resolvedVersion.isEmpty) {
    return fallback;
  }

  final versionCompare = compareVersionStrings(
    resolvedVersion,
    fallback.versionName,
  );
  if (versionCompare < 0) {
    return fallback;
  }

  if (versionCompare == 0) {
    final build = resolvedBuild.isEmpty ? fallback.buildNumber : resolvedBuild;
    if (_compareBuildNumbers(build, fallback.buildNumber) < 0) {
      return fallback;
    }
    return _ResolvedClientVersion(
      versionName: resolvedVersion,
      buildNumber: build,
    );
  }

  return _ResolvedClientVersion(
    versionName: resolvedVersion,
    buildNumber: resolvedBuild,
  );
}

int _compareBuildNumbers(String left, String right) {
  return _buildNumberValue(left).compareTo(_buildNumberValue(right));
}

int _buildNumberValue(String value) {
  final digits = RegExp(r'\d+').firstMatch(value.trim())?.group(0);
  return int.tryParse(digits ?? '0') ?? 0;
}
