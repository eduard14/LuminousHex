import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/lightcore_bootstrap.dart';
import '../app/lightcore_build_info.dart';
import '../models/lightcore_guide.dart';
import '../services/lightcore_web_refresh.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/auth_provider_button.dart';
import '../widgets/lightcore_guide_badge.dart';
import '../widgets/tower_ring_icon.dart';

part 'lightcore_main_menu/header_visuals.dart';
part 'lightcore_main_menu/guide_selection_sheet.dart';
part 'lightcore_main_menu/version_status_widgets.dart';
part 'lightcore_main_menu/action_auth_widgets.dart';
part 'lightcore_main_menu/menu_painters.dart';

class LightcoreMainMenuScreen extends StatefulWidget {
  const LightcoreMainMenuScreen({
    super.key,
    required this.guestSession,
    required this.bootstrapReport,
    required this.guideProfile,
    required this.isLoading,
    required this.onEnterGame,
    required this.onSelectGuide,
    required this.onRetryBootstrap,
    this.authBusy = false,
    this.sessionNotice,
    this.skipGuestSignInPrompt = false,
    this.guestSignInPromptShownThisSession = false,
    this.onGoogleSignIn,
    this.onEmailSignIn,
    this.onGuestSignInPromptShownChanged,
    this.onSkipGuestSignInPromptChanged,
  });

  final LightcoreGuestSession guestSession;
  final LightcoreBootstrapReport? bootstrapReport;
  final LightcoreGuideProfile? guideProfile;
  final bool isLoading;
  final VoidCallback onEnterGame;
  final ValueChanged<LightcoreGuideProfile> onSelectGuide;
  final VoidCallback onRetryBootstrap;
  final bool authBusy;
  final String? sessionNotice;
  final bool skipGuestSignInPrompt;
  final bool guestSignInPromptShownThisSession;
  final Future<bool> Function()? onGoogleSignIn;
  final Future<bool> Function()? onEmailSignIn;
  final ValueChanged<bool>? onGuestSignInPromptShownChanged;
  final ValueChanged<bool>? onSkipGuestSignInPromptChanged;

  @override
  State<LightcoreMainMenuScreen> createState() =>
      _LightcoreMainMenuScreenState();
}

enum _GuestSignInPromptAction {
  signInWithGoogle,
  signInWithEmail,
  continueAsGuest,
}

class _GuestSignInPromptResult {
  const _GuestSignInPromptResult({
    required this.action,
    this.dontAskAgain = false,
  });

  final _GuestSignInPromptAction action;
  final bool dontAskAgain;
}

class _LightcoreMainMenuScreenState extends State<LightcoreMainMenuScreen>
    with SingleTickerProviderStateMixin {
  static const _menuBackgroundAsset = 'lib/Menu_Background.png';
  static const _pulseCycleDuration = Duration(milliseconds: 7200);
  static const _loadingStageDuration = Duration(milliseconds: 1800);
  static const List<String> _loadingStages = ['Load'];

  late final AnimationController _pulseController;
  Timer? _sequenceTimer;
  int _sequenceIndex = 0;
  bool _guideSheetOpen = false;
  bool _launchFlowOpen = false;
  bool _guestSignInPromptShownThisSession = false;
  bool _isRefreshingWebVersion = false;
  String? _queuedWebRefreshVersion;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseCycleDuration,
    )..repeat();
    _resetSequenceForState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeRefreshWebApp();
    });
  }

  @override
  void didUpdateWidget(covariant LightcoreMainMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      _resetSequenceForState();
    }
    if (oldWidget.bootstrapReport != widget.bootstrapReport ||
        oldWidget.isLoading != widget.isLoading) {
      _maybeRefreshWebApp();
    }
    if (widget.guestSignInPromptShownThisSession &&
        !_guestSignInPromptShownThisSession) {
      _guestSignInPromptShownThisSession = true;
    }
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _resetSequenceForState() {
    _sequenceTimer?.cancel();
    if (!widget.isLoading) {
      if (_sequenceIndex != _loadingStages.length - 1) {
        setState(() => _sequenceIndex = _loadingStages.length - 1);
      }
      return;
    }

    if (_sequenceIndex != 0) {
      setState(() => _sequenceIndex = 0);
    }

    _sequenceTimer = Timer.periodic(_loadingStageDuration, (timer) {
      if (!mounted || !widget.isLoading) {
        timer.cancel();
        return;
      }
      setState(() {
        _sequenceIndex = (_sequenceIndex + 1) % _loadingStages.length;
      });
    });
  }

  Future<void> _presentGuideSelection({bool continueToGame = false}) async {
    if (_guideSheetOpen) {
      return;
    }
    _guideSheetOpen = true;
    final selection = await showModalBottomSheet<LightcoreGuideProfile>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      backgroundColor: LightcorePalette.panel,
      builder: (context) => const _GuideSelectionSheet(),
    );
    _guideSheetOpen = false;

    if (!mounted || selection == null) {
      return;
    }

    widget.onSelectGuide(selection);
    if (continueToGame) {
      widget.onEnterGame();
    }
  }

  void _maybeRefreshWebApp() {
    final report = widget.bootstrapReport;
    if (!isWebCacheRefreshSupported || widget.isLoading || report == null) {
      return;
    }

    if (report.latestVersionSatisfied) {
      clearWebCacheRefreshAttempt();
      _queuedWebRefreshVersion = null;
      if (_isRefreshingWebVersion && mounted) {
        setState(() => _isRefreshingWebVersion = false);
      }
      return;
    }

    if (!report.versionResolved) {
      return;
    }

    final targetVersion = report.requiredServerVersion;
    if (hasAttemptedWebCacheRefresh(targetVersion)) {
      if (_isRefreshingWebVersion && mounted) {
        setState(() => _isRefreshingWebVersion = false);
      }
      return;
    }
    if (_queuedWebRefreshVersion == targetVersion) {
      return;
    }

    _queuedWebRefreshVersion = targetVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _refreshWebAppVersion(targetVersion: targetVersion, automatic: true),
      );
    });
  }

  Future<void> _refreshWebAppVersion({
    required String targetVersion,
    bool automatic = false,
  }) async {
    if (!isWebCacheRefreshSupported || _isRefreshingWebVersion) {
      return;
    }

    setState(() => _isRefreshingWebVersion = true);
    final didReload = await clearCachesAndReloadWebApp(
      targetVersion: targetVersion,
    );
    if (!mounted || didReload) {
      return;
    }

    setState(() => _isRefreshingWebVersion = false);
    _queuedWebRefreshVersion = null;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          automatic
              ? 'Automatic web refresh failed. Try Refresh Web App.'
              : 'Web refresh failed. Try again.',
        ),
      ),
    );
  }

  Future<void> _openIosAppStore() async {
    final uri = Uri.parse(LightcoreBuildInfo.iosAppStoreUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || launched) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Could not open the App Store.')),
    );
  }

  Future<void> _handleEnterGame(bool canStart) async {
    if (!canStart || _launchFlowOpen) {
      return;
    }

    _launchFlowOpen = true;
    try {
      final report = widget.bootstrapReport;
      final shouldShowGuestPrompt =
          report != null &&
          report.profile.isAnonymous &&
          !widget.skipGuestSignInPrompt &&
          !widget.guestSignInPromptShownThisSession &&
          !_guestSignInPromptShownThisSession &&
          (widget.onGoogleSignIn != null || widget.onEmailSignIn != null);

      if (shouldShowGuestPrompt) {
        _markGuestSignInPromptShownThisSession();
        final result = await _presentGuestSignInPrompt(
          canUseGoogleSignIn: report.firebaseReady,
        );
        if (!mounted || result == null) {
          return;
        }
        if (result.action == _GuestSignInPromptAction.continueAsGuest) {
          if (result.dontAskAgain) {
            widget.onSkipGuestSignInPromptChanged?.call(true);
          }
        } else if (result.action == _GuestSignInPromptAction.signInWithGoogle) {
          final signedIn = await widget.onGoogleSignIn!.call();
          if (!mounted || !signedIn) {
            return;
          }
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) {
            return;
          }
        } else if (result.action == _GuestSignInPromptAction.signInWithEmail) {
          final signedIn = await widget.onEmailSignIn!.call();
          if (!mounted || !signedIn) {
            return;
          }
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) {
            return;
          }
        }
      }

      _continueIntoGame();
    } finally {
      _launchFlowOpen = false;
    }
  }

  void _markGuestSignInPromptShownThisSession() {
    if (!_guestSignInPromptShownThisSession) {
      _guestSignInPromptShownThisSession = true;
    }
    widget.onGuestSignInPromptShownChanged?.call(true);
  }

  void _continueIntoGame() {
    if (widget.guideProfile == null) {
      unawaited(_presentGuideSelection(continueToGame: true));
      return;
    }
    widget.onEnterGame();
  }

  Future<_GuestSignInPromptResult?> _presentGuestSignInPrompt({
    required bool canUseGoogleSignIn,
  }) async {
    var dontAskAgain = false;
    return showDialog<_GuestSignInPromptResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textTheme = Theme.of(context).textTheme;
            final googleEnabled =
                canUseGoogleSignIn &&
                !widget.authBusy &&
                widget.onGoogleSignIn != null;
            final emailEnabled =
                canUseGoogleSignIn &&
                !widget.authBusy &&
                widget.onEmailSignIn != null;

            return AlertDialog(
              key: const ValueKey<String>('guest-sign-in-prompt'),
              backgroundColor: LightcorePalette.panel,
              surfaceTintColor: Colors.transparent,
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: LightcorePalette.aether.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LightcorePalette.aether.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: LightcorePalette.aether.withValues(alpha: 0.94),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Save Recovery',
                      style: textTheme.titleLarge?.copyWith(
                        color: LightcorePalette.layer2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in with Google or email to keep this save recoverable across devices and reinstalls, or continue with guest cloud sync on this install.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.86),
                        height: 1.34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      key: const ValueKey<String>(
                        'guest-sign-in-dont-ask-toggle',
                      ),
                      value: dontAskAgain,
                      onChanged: (value) {
                        setDialogState(() {
                          dontAskAgain = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: LightcorePalette.aether,
                      checkColor: Colors.black,
                      title: Text(
                        "Don't ask again",
                        style: textTheme.bodyMedium?.copyWith(
                          color: LightcorePalette.layer2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AuthProviderButton(
                      key: const ValueKey<String>(
                        'guest-sign-in-google-button',
                      ),
                      kind: AuthProviderButtonKind.google,
                      label: 'Sign In With Google',
                      busy: widget.authBusy,
                      onPressed: googleEnabled
                          ? () {
                              Navigator.of(context).pop(
                                const _GuestSignInPromptResult(
                                  action:
                                      _GuestSignInPromptAction.signInWithGoogle,
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    AuthProviderButton(
                      key: const ValueKey<String>('guest-sign-in-email-button'),
                      kind: AuthProviderButtonKind.email,
                      label: 'Sign In With Email',
                      busy: widget.authBusy,
                      onPressed: emailEnabled
                          ? () {
                              Navigator.of(context).pop(
                                const _GuestSignInPromptResult(
                                  action:
                                      _GuestSignInPromptAction.signInWithEmail,
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    AuthProviderButton(
                      key: const ValueKey<String>('guest-sign-in-apple-button'),
                      kind: AuthProviderButtonKind.apple,
                      label: 'Apple ID Soon',
                      filled: false,
                      onPressed: null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        key: const ValueKey<String>(
                          'guest-sign-in-continue-button',
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(
                            _GuestSignInPromptResult(
                              action: _GuestSignInPromptAction.continueAsGuest,
                              dontAskAgain: dontAskAgain,
                            ),
                          );
                        },
                        child: const Text('Continue As Guest'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.bootstrapReport;
    final sessionNotice = widget.sessionNotice?.trim();
    final hasSessionNotice = sessionNotice != null && sessionNotice.isNotEmpty;
    final canStart =
        !hasSessionNotice &&
        !widget.isLoading &&
        (report?.canEnterGame ?? false);
    final canLaunch = canStart && !_isRefreshingWebVersion;
    final authUid = report?.profile.authUid;
    final authId = authUid != null && authUid.isNotEmpty
        ? authUid
        : widget.guestSession.playerId;
    final hasOfflineClaim = report?.offlineClaim.hasRewards ?? false;
    final showVersionNotice =
        !widget.isLoading && report != null && !report.canEnterGame;
    final outdatedVersion =
        report != null &&
        report.versionResolved &&
        !report.latestVersionSatisfied;
    final showWebRefreshAction =
        outdatedVersion &&
        isWebCacheRefreshSupported &&
        !report.manifest.maintenanceMode;
    final showAppStoreAction =
        outdatedVersion &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        !report.manifest.maintenanceMode;
    final statusLine = _statusLine(canStart: canStart, report: report);
    final statusNote = _statusNote(
      canStart: canStart,
      hasOfflineClaim: hasOfflineClaim,
      report: report,
    );
    final statusAccent = _menuStatusAccent(
      isLoading: widget.isLoading,
      canStart: canStart,
      canLaunch: canLaunch,
      report: report,
    );
    final clientVersion = _clientDisplayVersion(report);
    final screenSize = MediaQuery.sizeOf(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final backgroundCacheWidth = (screenSize.width * devicePixelRatio)
        .ceil()
        .clamp(640, 1600)
        .toInt();

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF010409)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _menuBackgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: backgroundCacheWidth,
                filterQuality: FilterQuality.high,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xD9040A11),
                      Color(0x7A030911),
                      Color(0xED02060D),
                    ],
                    stops: [0, 0.32, 1],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xA8010408),
                      Colors.transparent,
                      Color(0x77010408),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _MenuAtmospherePainter(
                      phase: _pulseController.value,
                      isLoading: widget.isLoading,
                      canStart: canStart,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final isWide = size.width > size.height * 1.05;
                  final isCompact = size.width < 900;
                  final isNarrow = size.width < 430;
                  final isUltraNarrow = size.width < 380;

                  final horizontalPadding = isCompact
                      ? (isUltraNarrow ? 14.0 : 18.0)
                      : 28.0;
                  final topPadding = isCompact
                      ? (isUltraNarrow ? 14.0 : 18.0)
                      : 28.0;
                  final bottomPadding = isCompact ? 14.0 : 18.0;
                  final footerBottom =
                      bottomPadding + (isCompact ? 52.0 : 42.0);

                  final buttonSize = isWide
                      ? math.min(size.height * 0.22, 188.0)
                      : isUltraNarrow
                      ? 116.0
                      : isNarrow
                      ? 132.0
                      : isCompact
                      ? 152.0
                      : 172.0;
                  final clusterWidth = isWide
                      ? math.min(size.width * 0.4, 430.0)
                      : math.min(size.width * 0.84, 460.0);

                  final clusterBaseTop =
                      size.height * (isWide ? 0.34 : 0.56) -
                      (buttonSize * 0.56);
                  final maxClusterTop = math.max(
                    size.height - buttonSize - (isCompact ? 220.0 : 250.0),
                    isWide ? 170.0 : 250.0,
                  );
                  final clusterTop = clusterBaseTop
                      .clamp(isWide ? 150.0 : 250.0, maxClusterTop)
                      .toDouble();

                  final infoBottomInset = math.max(
                    size.height - clusterTop + (isWide ? 18.0 : 34.0),
                    isWide ? 180.0 : 240.0,
                  );

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topPadding,
                            horizontalPadding,
                            infoBottomInset,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 560 : 620,
                                minHeight: math.max(
                                  size.height -
                                      topPadding -
                                      bottomPadding -
                                      infoBottomInset,
                                  0,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: isWide ? 6 : 10),
                                  _HeaderBlock(
                                    titleSize: isUltraNarrow
                                        ? 42
                                        : isNarrow
                                        ? 50
                                        : isCompact
                                        ? 62
                                        : 82,
                                    titleLetterSpacing: isUltraNarrow
                                        ? 1.2
                                        : isNarrow
                                        ? 1.6
                                        : isCompact
                                        ? 2.2
                                        : 3.2,
                                    compact: isCompact,
                                  ),
                                  SizedBox(height: isCompact ? 18 : 22),
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, _) {
                                      return _StatusGlassCard(
                                        phase: _pulseController.value,
                                        isLoading: widget.isLoading,
                                        canStart: canStart,
                                        canLaunch: canLaunch,
                                        report: report,
                                        compact: isCompact,
                                      );
                                    },
                                  ),
                                  if (showVersionNotice) ...[
                                    SizedBox(height: isCompact ? 14 : 18),
                                    _VersionNoticeCard(
                                      report: report,
                                      showRefreshAction: showWebRefreshAction,
                                      showAppStoreAction: showAppStoreAction,
                                      isRefreshing: _isRefreshingWebVersion,
                                      onRefresh: () => _refreshWebAppVersion(
                                        targetVersion:
                                            report.requiredServerVersion,
                                      ),
                                      onOpenAppStore: () =>
                                          unawaited(_openIosAppStore()),
                                      compact: isCompact,
                                    ),
                                  ],
                                  if (sessionNotice != null &&
                                      sessionNotice.isNotEmpty) ...[
                                    SizedBox(height: isCompact ? 14 : 18),
                                    _SessionNoticeCard(
                                      message: sessionNotice,
                                      compact: isCompact,
                                      onReconnect: widget.onRetryBootstrap,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: clusterTop,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: clusterWidth),
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, _) {
                                return _CoreActionCluster(
                                  phase: _pulseController.value,
                                  enabled: canLaunch,
                                  isLoading: widget.isLoading,
                                  compact: isCompact,
                                  buttonSize: buttonSize,
                                  onTap: canLaunch
                                      ? () => _handleEnterGame(canLaunch)
                                      : null,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        bottom: footerBottom,
                        child: IgnorePointer(
                          child: Center(
                            child: _RailFooter(
                              compact: isCompact,
                              statusLine: statusLine,
                              statusNote: statusNote,
                              accent: statusAccent,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: horizontalPadding,
                        bottom: bottomPadding,
                        child: IgnorePointer(
                          child: _VersionAnchor(
                            compact: isCompact,
                            clientVersion: clientVersion,
                          ),
                        ),
                      ),
                      Positioned(
                        left: horizontalPadding,
                        bottom: bottomPadding + (isCompact ? 34.0 : 40.0),
                        child: AnimatedOpacity(
                          opacity: !canStart && !widget.isLoading ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: IgnorePointer(
                            ignoring: canStart || widget.isLoading,
                            child: TextButton.icon(
                              onPressed: widget.onRetryBootstrap,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: TextButton.styleFrom(
                                foregroundColor: LightcorePalette.mist
                                    .withValues(alpha: 0.78),
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: horizontalPadding,
                        bottom: bottomPadding,
                        child: _AuthCornerBadge(
                          authId: _compactAuthId(authId),
                          isReady: canStart,
                          compact: isCompact,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLine({
    required bool canStart,
    required LightcoreBootstrapReport? report,
  }) {
    if (widget.isLoading) {
      return _loadingStages[_sequenceIndex];
    }
    if (widget.sessionNotice?.trim().isNotEmpty == true) {
      return 'Expired';
    }
    if (canStart) {
      return 'Live';
    }
    if (report == null) {
      return 'Hold';
    }
    if (report.manifest.maintenanceMode) {
      return 'Pause';
    }
    if (!report.versionResolved) {
      return 'Verify';
    }
    if (!report.latestVersionSatisfied) {
      return 'Update';
    }
    if (!report.restoreResolved) {
      return 'Restore';
    }
    return 'Hold';
  }

  String _statusNote({
    required bool canStart,
    required bool hasOfflineClaim,
    required LightcoreBootstrapReport? report,
  }) {
    if (widget.isLoading) {
      return 'opening menu';
    }
    if (widget.sessionNotice?.trim().isNotEmpty == true) {
      return 'reconnect to claim progress';
    }
    if (canStart) {
      if (hasOfflineClaim) {
        return 'cache restored';
      }
      if (report != null && report.requiresServerValidation) {
        return 'server ${report.requiredServerVersion}';
      }
      return 'preview ready';
    }
    if (report == null) {
      return 'awaiting manifest';
    }
    if (report.manifest.maintenanceMode) {
      return 'live server paused';
    }
    if (!report.versionResolved) {
      return 'internet required';
    }
    if (!report.latestVersionSatisfied) {
      return 'need ${report.requiredServerVersion}';
    }
    if (!report.restoreResolved) {
      return 'retry cloud restore';
    }
    return 'retry sync';
  }

  static String _clientDisplayVersion(LightcoreBootstrapReport? report) {
    final reportVersion = report?.clientDisplayVersion.trim();
    if (reportVersion != null && reportVersion.isNotEmpty) {
      return reportVersion;
    }

    final version = LightcoreBuildInfo.versionName.trim();
    final build = LightcoreBuildInfo.buildNumber.trim();
    if (build.isEmpty) {
      return version;
    }
    return '$version+$build';
  }

  static String _compactAuthId(String authId) {
    if (authId.length <= 16) {
      return authId;
    }
    return '${authId.substring(0, 4)}…${authId.substring(authId.length - 8)}';
  }
}

Color _menuStatusAccent({
  required bool isLoading,
  required bool canStart,
  required bool canLaunch,
  required LightcoreBootstrapReport? report,
}) {
  if (canLaunch) {
    return LightcorePalette.success;
  }
  if (isLoading) {
    return LightcorePalette.aether;
  }
  if (canStart) {
    return LightcorePalette.violet;
  }
  final versionClear =
      (report?.versionResolved ?? true) &&
      (report?.latestVersionSatisfied ?? true);
  return versionClear ? LightcorePalette.aether : LightcorePalette.warning;
}
