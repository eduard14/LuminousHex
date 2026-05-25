import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../app/lightcore_build_info.dart';
import '../app/lightcore_bootstrap.dart';
import '../battle/shell_promotion_presentation.dart';
import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_types.dart';
import '../models/lightcore_social_invite_link.dart';
import '../models/lightcore_social_state.dart';
import '../models/lightcore_state.dart';
import '../services/lightcore_firebase_backend.dart';
import '../services/lightcore_audio.dart';
import '../services/lightcore_rewarded_ads.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_icons.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/cosmic_guide_avatar.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/lightcore_guide_badge.dart';
import '../widgets/lightcore_screen_transition.dart';
import '../widgets/meter_bar.dart';
import '../widgets/meta_progression_sheet.dart';
import '../widgets/player_manager_sheet.dart';
import '../widgets/profile_medals_sheet.dart';
import '../widgets/status_pill.dart';
import '../widgets/tower_ring_icon.dart';
import 'battle_screen.dart';
import 'card_management_screen.dart';
import 'daily_dungeons_screen.dart';
import 'enemy_management_screen.dart';
import 'friend_management_screen.dart';
import 'prestige_screen.dart';
import 'space_room_screen.dart';
import 'threat_map_screen.dart';
import 'tournament_screen.dart';
import 'tower_management_screen.dart';

part 'lightcore_shell/settings_widgets.dart';
part 'lightcore_shell/leaderboard_sheet.dart';
part 'lightcore_shell/notification_widgets.dart';
part 'lightcore_shell/navigation_widgets.dart';
part 'lightcore_shell/screen_name_dialog.dart';
part 'lightcore_shell/resource_flyout.dart';
part 'lightcore_shell/header_widgets.dart';
part 'lightcore_shell/help_widgets.dart';

class LightcoreShell extends StatefulWidget {
  const LightcoreShell({
    super.key,
    required this.controller,
    required this.backend,
    this.battleSurfaceGeneration = 0,
    this.clientDisplayVersion,
    this.initialOfflineClaim,
    this.initialSocialInvite,
    this.authBusy = false,
    this.musicEnabled,
    this.soundEffectsEnabled,
    this.onMusicEnabledChanged,
    this.onSoundEffectsEnabledChanged,
    this.onGoogleSignIn,
    this.onEmailSignIn,
    this.onSignOut,
  });

  final LightcoreController controller;
  final FirebaseLightcoreBackend backend;
  final int battleSurfaceGeneration;
  final String? clientDisplayVersion;
  final LightcoreOfflineClaimResult? initialOfflineClaim;
  final LightcoreSocialInviteLink? initialSocialInvite;
  final bool authBusy;
  final bool? musicEnabled;
  final bool? soundEffectsEnabled;
  final ValueChanged<bool>? onMusicEnabledChanged;
  final ValueChanged<bool>? onSoundEffectsEnabledChanged;
  final AsyncCallback? onGoogleSignIn;
  final AsyncCallback? onEmailSignIn;
  final AsyncCallback? onSignOut;

  @override
  State<LightcoreShell> createState() => _LightcoreShellState();
}

class _LightcoreShellState extends State<LightcoreShell> {
  static const List<_ShellOverlayDestination> _navigationDestinations = [
    _ShellOverlayDestination.battle,
    _ShellOverlayDestination.towers,
    _ShellOverlayDestination.managers,
    _ShellOverlayDestination.threatMap,
    _ShellOverlayDestination.enemies,
    _ShellOverlayDestination.prestige,
  ];

  List<_ShellOverlayDestination> get _visibleNavigationDestinations =>
      _navigationDestinations
          .where(
            (destination) =>
                destination.visibleInBottomNavigation(widget.controller),
          )
          .toList(growable: false);

  _ShellOverlayDestination? _activeOverlay;
  ShellPromotionPresentation? _activeShellPromotionPresentation;
  bool _shellPromotionHudSuppressed = false;
  bool _eventBattleSurfaceActive = false;
  bool _settingsDialogOpen = false;
  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  int _shellPromotionSequence = 0;
  bool _startupOfflineClaimPresented = false;
  bool _initialSocialInviteOpened = false;
  Timer? _eventOfflineTicker;
  OverlayEntry? _notificationOverlayEntry;
  String? _lastRaisedNotificationMessage;
  late final Map<_ShellOverlayDestination, ScrollController>
  _overlayScrollControllers = {
    _ShellOverlayDestination.towers: ScrollController(keepScrollOffset: false),
    _ShellOverlayDestination.managers: ScrollController(
      keepScrollOffset: false,
    ),
    _ShellOverlayDestination.threatMap: ScrollController(
      keepScrollOffset: false,
    ),
    _ShellOverlayDestination.spaceRoom: ScrollController(
      keepScrollOffset: false,
    ),
    _ShellOverlayDestination.friends: ScrollController(keepScrollOffset: false),
    _ShellOverlayDestination.mentees: ScrollController(keepScrollOffset: false),
    _ShellOverlayDestination.mentors: ScrollController(keepScrollOffset: false),
    _ShellOverlayDestination.enemies: ScrollController(keepScrollOffset: false),
    _ShellOverlayDestination.dungeons: ScrollController(
      keepScrollOffset: false,
    ),
    _ShellOverlayDestination.prestige: ScrollController(
      keepScrollOffset: false,
    ),
  };

  static double _battleHeaderOverlayInset(bool compact) => compact ? 132 : 158;

  static double _battleFooterOverlayInset(bool compact) => compact ? 132 : 160;

  static const Duration _promotionOverlayDismissDelay = Duration(
    milliseconds: 260,
  );

  static const Duration _eventOfflineTickRate = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _musicEnabled = widget.musicEnabled ?? LightcoreAudio.instance.musicEnabled;
    _soundEffectsEnabled =
        widget.soundEffectsEnabled ??
        LightcoreAudio.instance.soundEffectsEnabled;
    widget.controller.addListener(_handleNotificationOverlay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationOverlay();
      _presentStartupOfflineClaim();
      _openInitialSocialInvite();
    });
  }

  @override
  void didUpdateWidget(covariant LightcoreShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.musicEnabled != null &&
        oldWidget.musicEnabled != widget.musicEnabled) {
      _musicEnabled = widget.musicEnabled!;
    }
    if (widget.soundEffectsEnabled != null &&
        oldWidget.soundEffectsEnabled != widget.soundEffectsEnabled) {
      _soundEffectsEnabled = widget.soundEffectsEnabled!;
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleNotificationOverlay);
      widget.controller.addListener(_handleNotificationOverlay);
      _lastRaisedNotificationMessage = null;
      _removeNotificationOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationOverlay();
      });
    }
    if (_startupOfflineClaimPresented) {
      _openInitialSocialInvite();
      return;
    }
    if (widget.initialOfflineClaim == null ||
        oldWidget.initialOfflineClaim == widget.initialOfflineClaim) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presentStartupOfflineClaim();
      _openInitialSocialInvite();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleNotificationOverlay);
    _eventOfflineTicker?.cancel();
    _removeNotificationOverlay();
    for (final controller in _overlayScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleNotificationOverlay() {
    if (!mounted) {
      return;
    }
    if (_shellPromotionHudSuppressed ||
        widget.controller.activeThreatRegionChallenge != null) {
      _lastRaisedNotificationMessage = null;
      _removeNotificationOverlay();
      return;
    }
    if (!widget.controller.notificationBannersEnabled) {
      _lastRaisedNotificationMessage = null;
      _removeNotificationOverlay();
      return;
    }
    final message = widget.controller.bannerMessage.trim();
    if (message.isEmpty) {
      _lastRaisedNotificationMessage = null;
      return;
    }
    if (message == _lastRaisedNotificationMessage &&
        _notificationOverlayEntry != null) {
      return;
    }
    _lastRaisedNotificationMessage = message;
    _raiseNotificationOverlay();
  }

  void _raiseNotificationOverlay() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _removeNotificationOverlay();
    _notificationOverlayEntry = OverlayEntry(
      builder: (context) {
        return _ShellNotificationOverlay(controller: widget.controller);
      },
    );
    overlay.insert(_notificationOverlayEntry!);
  }

  void _removeNotificationOverlay() {
    final entry = _notificationOverlayEntry;
    if (entry == null) {
      return;
    }
    entry.remove();
    entry.dispose();
    _notificationOverlayEntry = null;
  }

  List<_SettingsStatEntry> _buildSettingsStatEntries(
    LightcoreController controller,
  ) {
    return [
      _SettingsStatEntry(
        label: 'Anomalies Resolved',
        value: _formatMetricCount(controller.kills),
        subtitle: 'Enemy clears earned on this save.',
        tint: LightcorePalette.aether,
        icon: Icons.radar_rounded,
      ),
      _SettingsStatEntry(
        label: 'Apex Defeated',
        value: _formatMetricCount(controller.totalBossesDefeated),
        subtitle: 'Apex clears that paid out sigils and heartcores.',
        tint: LightcorePalette.warning,
        icon: Icons.shield_moon_rounded,
      ),
      _SettingsStatEntry(
        label: 'Time In Game',
        value: _formatSettingsDuration(
          Duration(seconds: controller.totalBattleSeconds.round()),
        ),
        subtitle: 'Only live battle runtime counts here.',
        tint: LightcorePalette.verdant,
        icon: Icons.timer_rounded,
      ),
      _SettingsStatEntry(
        label: 'Offline Time Claimed',
        value: _formatSettingsDuration(
          Duration(seconds: controller.totalOfflineSecondsClaimed),
        ),
        subtitle: 'Time converted into startup idle rewards.',
        tint: LightcorePalette.violet,
        icon: Icons.history_toggle_off_rounded,
      ),
      _SettingsStatEntry(
        label: 'Upgrades Bought',
        value: _formatMetricCount(controller.totalUpgradesBought),
        subtitle: 'Tower, core, deck, and swarm upgrades combined.',
        tint: LightcorePalette.flare,
        icon: Icons.upgrade_rounded,
      ),
      _SettingsStatEntry(
        label: 'Towers Anchored',
        value: _formatMetricCount(controller.totalTowersBuilt),
        subtitle: 'Fresh prism anchors placed across all shells.',
        tint: LightcorePalette.aether,
        icon: Icons.hub_rounded,
      ),
      _SettingsStatEntry(
        label: 'Managers Forged',
        value: _formatMetricCount(controller.totalManagersForged),
        subtitle: 'Tower and anomaly foundry pulls combined.',
        tint: LightcorePalette.solar,
        icon: Icons.auto_awesome_rounded,
      ),
      _SettingsStatEntry(
        label: 'Scans Resolved',
        value: _formatMetricCount(controller.totalPullsOpened),
        subtitle: 'Threat Scans resolved into Knowledge Cards.',
        tint: LightcorePalette.scanGlow,
        icon: LightcoreIcons.threatScan,
      ),
      _SettingsStatEntry(
        label: 'Lumens Spent',
        value: _formatMetricCount(controller.totalLumensSpent),
        subtitle: 'Invested into towers, core tuning, and shell pressure.',
        tint: LightcorePalette.aether,
        icon: Icons.hexagon_rounded,
      ),
      _SettingsStatEntry(
        label: 'Flux Spent',
        value: _formatMetricCount(controller.totalFluxSpent),
        subtitle: 'Burned on foundry work, conversions, and premium tracks.',
        tint: LightcorePalette.solar,
        icon: Icons.workspace_premium_rounded,
      ),
    ];
  }

  int get _selectedNavigationIndex {
    final destinations = _visibleNavigationDestinations;
    final index = destinations.indexOf(
      _activeOverlay ?? _ShellOverlayDestination.battle,
    );
    return index < 0 ? 0 : index;
  }

  String get _settingsClientDisplayVersion {
    final resolvedVersion = widget.clientDisplayVersion?.trim();
    if (resolvedVersion != null && resolvedVersion.isNotEmpty) {
      return resolvedVersion;
    }

    final version = LightcoreBuildInfo.versionName.trim();
    final build = LightcoreBuildInfo.buildNumber.trim();
    if (build.isEmpty) {
      return version;
    }
    return '$version+$build';
  }

  void _showOverlay(_ShellOverlayDestination destination) {
    if (_activeOverlay == destination) {
      _syncEventOfflineTicker(destination);
      _resetOverlayScroll(destination);
      return;
    }
    setState(() {
      _activeOverlay = destination;
      if (destination != _ShellOverlayDestination.tournaments) {
        _eventBattleSurfaceActive = false;
      }
    });
    _syncEventOfflineTicker(destination);
    _resetOverlayScroll(destination);
  }

  void _closeOverlay() {
    if (_activeOverlay == null) {
      return;
    }
    setState(() {
      _activeOverlay = null;
      _eventBattleSurfaceActive = false;
    });
    _syncEventOfflineTicker(null);
  }

  void _handlePromotionRequestedFromOverlay() {
    final controller = widget.controller;
    if (!controller.canUnlockLayer2 || controller.activeLayerHasParentSlot) {
      controller.unlockLayer2Tower();
      return;
    }

    final sourceLayerId = controller.activeLayer.id;
    final sourceLayerLabel = controller.activeLayerLabel;
    final sourceTier = controller.activeLayer.tier;
    final sourceCore = controller.coreState;
    final sourceSlots = controller.slots.toList(growable: false);
    final expectedTargetLabel = controller.nextShellClassLabel;

    setState(() {
      _activeOverlay = null;
      _eventBattleSurfaceActive = false;
      _shellPromotionHudSuppressed = true;
      _activeShellPromotionPresentation = null;
    });
    _syncEventOfflineTicker(null);

    Future<void>.delayed(_promotionOverlayDismissDelay, () {
      if (!mounted) {
        return;
      }
      if (controller.activeLayer.id != sourceLayerId) {
        setState(() {
          _shellPromotionHudSuppressed = false;
        });
        return;
      }
      controller.unlockLayer2Tower();
      if (!mounted || controller.activeLayer.id == sourceLayerId) {
        setState(() {
          _shellPromotionHudSuppressed = false;
        });
        return;
      }
      final presentation = ShellPromotionPresentation(
        sequence: ++_shellPromotionSequence,
        sourceLayerLabel: sourceLayerLabel,
        targetLayerLabel: controller.activeLayerLabel.isEmpty
            ? expectedTargetLabel
            : controller.activeLayerLabel,
        sourceTier: sourceTier,
        targetTier: controller.activeLayer.tier,
        sourceCore: sourceCore,
        targetCore: controller.coreState,
        sourceSlots: sourceSlots,
      );
      setState(() {
        _activeShellPromotionPresentation = presentation;
      });
    });
  }

  void _handleShellPromotionComplete() {
    if (!_shellPromotionHudSuppressed &&
        _activeShellPromotionPresentation == null) {
      return;
    }
    setState(() {
      _shellPromotionHudSuppressed = false;
      _activeShellPromotionPresentation = null;
    });
  }

  void _syncEventOfflineTicker(_ShellOverlayDestination? destination) {
    final shouldRun =
        destination == _ShellOverlayDestination.dungeons ||
        destination == _ShellOverlayDestination.tournaments;
    if (!shouldRun) {
      _eventOfflineTicker?.cancel();
      _eventOfflineTicker = null;
      return;
    }
    _eventOfflineTicker ??= Timer.periodic(_eventOfflineTickRate, (_) {
      widget.controller.advanceEventOfflineProgress(
        _eventOfflineTickRate.inMilliseconds / 1000,
      );
    });
  }

  ScrollController? _overlayScrollControllerFor(
    _ShellOverlayDestination destination,
  ) => _overlayScrollControllers[destination];

  void _resetOverlayScroll(_ShellOverlayDestination destination) {
    final controller = _overlayScrollControllerFor(destination);
    if (controller == null) {
      return;
    }

    void jumpToTop() {
      if (!mounted || !controller.hasClients) {
        return;
      }
      controller.jumpTo(0);
    }

    if (controller.hasClients) {
      jumpToTop();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToTop());
  }

  void _openInitialSocialInvite() {
    final invite = widget.initialSocialInvite;
    if (!mounted || _initialSocialInviteOpened || invite == null) {
      return;
    }
    _initialSocialInviteOpened = true;
    final destination = invite.kind == LightcoreSocialInviteLinkKind.friend
        ? _ShellOverlayDestination.friends
        : _ShellOverlayDestination.mentees;
    final lockedMessage = destination.lockedMessage(widget.controller);
    _openOverlayDestination(destination);
    if (lockedMessage != null) {
      return;
    }
    widget.controller.pushNotification(
      'Invite link loaded. Review and confirm the connection.',
      duration: 3.2,
    );
  }

  Future<void> _presentStartupOfflineClaim() async {
    final claim = widget.initialOfflineClaim;
    if (!mounted || _startupOfflineClaimPresented || claim == null) {
      return;
    }
    if (!claim.hasRewards) {
      _startupOfflineClaimPresented = true;
      return;
    }

    _startupOfflineClaimPresented = true;
    await showDialog<void>(
      context: context,
      barrierColor: LightcorePalette.night.withValues(alpha: 0.78),
      builder: (dialogContext) {
        final claimedHours = claim.secondsClaimed / 3600;
        final canUseRewardedAds = LightcoreRewardedAds.isSupportedPlatform;
        final rewardedExperience = widget.controller.boostedExperienceRewardFor(
          claim.killsGranted,
        );
        final rewardedBundle = <String>[
          if (claim.lumensGranted > 0)
            LightcoreCurrencyLabels.rewardLumens(claim.lumensGranted),
          if (claim.fluxGranted > 0)
            LightcoreCurrencyLabels.rewardFlux(claim.fluxGranted),
          if (claim.enemyTicketsGranted > 0)
            LightcoreCurrencyLabels.rewardThreatScans(
              claim.enemyTicketsGranted,
            ),
          if (rewardedExperience > 0) '+$rewardedExperience EXP',
        ].join(', ');
        return _SelectorDialog(
          title: 'Offline Gains',
          subtitle:
              'Your shell kept running while you were away. The base claim is already applied, and a rewarded boost can double it once.',
          tint: LightcorePalette.ember,
          child: ListView(
            shrinkWrap: true,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatusPill(
                    label: 'Lumens',
                    value: '+${claim.lumensGranted}',
                    tint: LightcorePalette.aether,
                    icon: Icons.hexagon_rounded,
                  ),
                  StatusPill(
                    label: LightcoreCurrencyLabels.flux,
                    value: '+${claim.fluxGranted}',
                    tint: LightcorePalette.solar,
                    icon: Icons.workspace_premium_rounded,
                  ),
                  StatusPill(
                    label: LightcoreCurrencyLabels.scansShort,
                    value: '+${claim.enemyTicketsGranted}',
                    tint: LightcorePalette.scanGlow,
                    icon: LightcoreIcons.threatScan,
                  ),
                  StatusPill(
                    label: 'EXP',
                    value: '+$rewardedExperience',
                    tint: LightcorePalette.violet,
                    icon: Icons.ads_click_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AuroraPanel(
                tint: claim.serverValidated
                    ? LightcorePalette.success
                    : LightcorePalette.solar,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${claimedHours.toStringAsFixed(1)}h claimed',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      claim.statusMessage ??
                          (claim.serverValidated
                              ? 'Validated by the backend before the shell opened.'
                              : 'Applied from a reduced-trust startup path.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AuroraPanel(
                tint: LightcorePalette.violet,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Boost',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      canUseRewardedAds
                          ? 'Watch a rewarded ad to claim the same offline bundle a second time.'
                          : 'Rewarded ads are wired for Android and iOS builds. Desktop and web keep this boost disabled.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: canUseRewardedAds
                              ? () async {
                                  final earned = await showLightcoreRewardedAd(
                                    dialogContext,
                                    rewardLabel: rewardedBundle,
                                  );
                                  if (!dialogContext.mounted || !earned) {
                                    return;
                                  }
                                  widget.controller.grantRewardedResources(
                                    lumensGranted: claim.lumensGranted,
                                    fluxGranted: claim.fluxGranted,
                                    enemyTicketsGranted:
                                        claim.enemyTicketsGranted,
                                    killsGranted: claim.killsGranted,
                                    experienceGranted: rewardedExperience,
                                    sourceLabel:
                                        'Reward ad • Offline gains doubled',
                                  );
                                  Navigator.of(dialogContext).pop();
                                }
                              : null,
                          icon: const Icon(Icons.play_circle_fill_rounded),
                          label: const Text('Double Claim • Reward Ad'),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Enter Shell'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectNavigationDestination(int index) {
    final destinations = _visibleNavigationDestinations;
    if (index < 0 || index >= destinations.length) {
      return;
    }
    _openOverlayDestination(destinations[index]);
  }

  void _selectHeaderMenuAction(
    BuildContext context,
    _ShellHeaderMenuAction action,
  ) {
    if (action == _ShellHeaderMenuAction.settings) {
      _openSettings(context);
      return;
    }
    if (action == _ShellHeaderMenuAction.medals) {
      showProfileMedalsSheet(context, widget.controller);
      return;
    }
    if (action == _ShellHeaderMenuAction.leaderboard) {
      _openGlobalLeaderboard(context);
      return;
    }

    _openOverlayDestination(action.destination!);
  }

  void _openOverlayDestination(_ShellOverlayDestination destination) {
    final tutorialStep = widget.controller.tutorialStep;
    if (tutorialStep == LightcoreTutorialStep.armFirstBoss &&
        destination != _ShellOverlayDestination.enemies &&
        destination != _ShellOverlayDestination.battle) {
      widget.controller.pushNotification(
        'Open Anomalies so you can arm the first Apex Anomaly.',
        duration: 4.0,
      );
      return;
    }
    if (tutorialStep == LightcoreTutorialStep.defeatFirstBoss &&
        destination != _ShellOverlayDestination.battle) {
      widget.controller.pushNotification(
        'Return to battle. The first Apex is ready to breach.',
        duration: 4.0,
      );
      return;
    }
    if (destination == _ShellOverlayDestination.battle) {
      _closeOverlay();
      return;
    }
    final lockedMessage = destination.lockedMessage(widget.controller);
    if (lockedMessage != null) {
      widget.controller.pushNotification(lockedMessage, duration: 3.2);
      return;
    }
    switch (destination) {
      case _ShellOverlayDestination.towers:
        widget.controller.markTutorialTowerMatrixOpened();
      case _ShellOverlayDestination.managers:
        widget.controller.markTutorialManagersOpened();
      case _ShellOverlayDestination.threatMap:
        break;
      case _ShellOverlayDestination.spaceRoom:
        break;
      case _ShellOverlayDestination.friends:
        widget.controller.markTutorialFriendsOpened();
      case _ShellOverlayDestination.mentees:
        widget.controller.markTutorialMentorshipOpened();
      case _ShellOverlayDestination.mentors:
        widget.controller.markTutorialMentorshipOpened();
      case _ShellOverlayDestination.battle ||
          _ShellOverlayDestination.enemies ||
          _ShellOverlayDestination.threatMap ||
          _ShellOverlayDestination.dungeons ||
          _ShellOverlayDestination.tournaments ||
          _ShellOverlayDestination.prestige:
        break;
    }
    _showOverlay(destination);
  }

  Widget _buildOverlayScreen(_ShellOverlayDestination destination) {
    final controller = widget.controller;

    return switch (destination) {
      _ShellOverlayDestination.battle => BattleScreen(
        controller: controller,
        isActive: true,
      ),
      _ShellOverlayDestination.towers => TowerManagementScreen(
        controller: controller,
        isActive: true,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.managers => CardManagementScreen(
        controller: controller,
        isActive: true,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.threatMap => ThreatMapScreen(
        controller: controller,
        isActive: true,
        onClose: _closeOverlay,
      ),
      _ShellOverlayDestination.spaceRoom => SpaceRoomScreen(
        controller: controller,
        isActive: true,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.friends => FriendManagementScreen(
        controller: controller,
        backend: widget.backend,
        isActive: true,
        section: FriendManagementSection.friends,
        initialInviteLink: widget.initialSocialInvite,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.mentees => FriendManagementScreen(
        controller: controller,
        backend: widget.backend,
        isActive: true,
        section: FriendManagementSection.mentees,
        initialInviteLink: widget.initialSocialInvite,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.mentors => FriendManagementScreen(
        controller: controller,
        backend: widget.backend,
        isActive: true,
        section: FriendManagementSection.mentors,
        initialInviteLink: widget.initialSocialInvite,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.enemies => EnemyManagementScreen(
        controller: controller,
        isActive: true,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.dungeons => DailyDungeonsScreen(
        controller: controller,
        isActive: true,
        scrollController: _overlayScrollControllerFor(destination),
      ),
      _ShellOverlayDestination.tournaments => TournamentScreen(
        controller: controller,
        backend: widget.backend,
        onBattleSurfaceActiveChanged: _setEventBattleSurfaceActive,
      ),
      _ShellOverlayDestination.prestige => PrestigeScreen(
        controller: controller,
        isActive: true,
        scrollController: _overlayScrollControllerFor(destination),
        onPromotionRequested: _handlePromotionRequestedFromOverlay,
      ),
    };
  }

  void _setEventBattleSurfaceActive(bool active) {
    if (_eventBattleSurfaceActive == active) {
      return;
    }
    setState(() => _eventBattleSurfaceActive = active);
  }

  Future<void> _openStats(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: LightcorePalette.night.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final stats = _buildSettingsStatEntries(controller);

            return _SelectorDialog(
              title: 'Stats',
              subtitle: 'Cumulative run metrics for the current save file.',
              tint: controller.activeLayer.core.affinity.color,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuroraPanel(
                      tint: LightcorePalette.aether,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Run Ledger',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This tracks real activity on the current save: combat time, offline claims, kills, upgrades, spend, and foundry work.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsStatsGrid(entries: stats),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPlayerManager(BuildContext context) {
    if (widget.controller.tutorialStep == LightcoreTutorialStep.openBossPulls ||
        widget.controller.tutorialStep == LightcoreTutorialStep.armFirstBoss ||
        widget.controller.tutorialStep ==
            LightcoreTutorialStep.defeatFirstBoss) {
      widget.controller.pushNotification(
        'Finish the Apex tutorial step first.',
        duration: 4.0,
      );
      return Future<void>.value();
    }
    widget.controller.markTutorialPlayerManagerOpened();
    if (LightcoreController.equipmentReleaseEnabled) {
      widget.controller.markNewEquipmentNotificationsSeen();
    }
    return showPlayerManagerSheet(context, widget.controller);
  }

  Future<void> _saveScreenName(String screenName) async {
    final validationError = widget.controller.validateScreenName(screenName);
    if (validationError != null) {
      throw LightcoreScreenNameUpdateException(validationError);
    }
    if (!widget.backend.canUseCloudSave) {
      widget.controller.setScreenName(screenName, showBanner: false);
      widget.controller.pushNotification(
        'Screen name saved locally. Online uniqueness will be verified when Firebase is available.',
        duration: 4.2,
      );
      return;
    }
    final profile = await widget.backend.updateScreenName(
      screenName: screenName,
    );
    widget.controller.setScreenName(profile.screenName ?? screenName);
    widget.controller.syncPlayerProfile(profile, showBanner: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isCompactLayout = MediaQuery.sizeOf(context).width < 760;
    final challengeActive = controller.activeThreatRegionChallenge != null;
    final effectiveOverlay = challengeActive ? null : _activeOverlay;
    final overlayActive = effectiveOverlay != null;
    final battleSurfaceClosedForEvent =
        effectiveOverlay == _ShellOverlayDestination.dungeons ||
        effectiveOverlay == _ShellOverlayDestination.tournaments;
    final battleHudVisible = !overlayActive && !_shellPromotionHudSuppressed;
    final battleChromeVisible = battleHudVisible && !challengeActive;
    final shellPadding = isCompactLayout ? 12.0 : 16.0;
    final sectionGap = isCompactLayout ? 8.0 : 16.0;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LightcorePalette.night,
              LightcorePalette.abyss,
              Color(0xFF112738),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -60,
              child: _GlowOrb(
                color: LightcorePalette.aether.withValues(alpha: 0.24),
                size: 260,
              ),
            ),
            Positioned(
              bottom: -150,
              left: -80,
              child: _GlowOrb(
                color: LightcorePalette.ember.withValues(alpha: 0.18),
                size: 320,
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      shellPadding,
                      12,
                      shellPadding,
                      shellPadding,
                    ),
                    child: Stack(
                      children: [
                        if (battleSurfaceClosedForEvent)
                          const Positioned.fill(child: _EventOfflineBackdrop())
                        else
                          Positioned.fill(
                            child: BattleScreen(
                              key: ValueKey<String>(
                                'battle-${identityHashCode(controller)}-${widget.battleSurfaceGeneration}',
                              ),
                              controller: controller,
                              isActive: !overlayActive && !_settingsDialogOpen,
                              showQuestPanel: battleChromeVisible,
                              showBattleHud: battleChromeVisible,
                              promotionPresentation:
                                  _activeShellPromotionPresentation,
                              onPromotionPresentationComplete:
                                  _handleShellPromotionComplete,
                              topOverlayInset: battleChromeVisible
                                  ? _battleHeaderOverlayInset(isCompactLayout)
                                  : 0,
                              bottomOverlayInset: battleChromeVisible
                                  ? _battleFooterOverlayInset(isCompactLayout)
                                  : 0,
                            ),
                          ),
                        if (battleChromeVisible)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) {
                                if (!controller.layerNavigationUnlocked) {
                                  return const SizedBox.shrink();
                                }
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: isCompactLayout ? 8 : 10,
                                    ),
                                    child: _LayerDockButton(
                                      label:
                                          LightcoreController.shellBadgeForTier(
                                            controller.activeLayer.tier,
                                          ),
                                      statusLabel:
                                          controller.activeLayerPassiveOnly
                                          ? 'PASSIVE'
                                          : 'LIVE',
                                      tint: controller
                                          .activeLayer
                                          .core
                                          .affinity
                                          .color,
                                      onTap: () => _openLayerPicker(context),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (battleChromeVisible)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) {
                                final claimablePassRewards =
                                    controller.totalClaimableBattlePassRewards;
                                final managerAlertLabels = <String>[
                                  if (controller.hasUnspentRadianceStatPoints)
                                    controller.unspentRadianceStatPoints == 1
                                        ? '1 Radiance point ready'
                                        : '${controller.unspentRadianceStatPoints} Radiance points ready',
                                  if (LightcoreController
                                          .equipmentReleaseEnabled &&
                                      controller.hasNewEquipmentNotifications)
                                    controller.newEquipmentNotificationCount ==
                                            1
                                        ? '1 new equipment piece'
                                        : '${controller.newEquipmentNotificationCount} new equipment pieces',
                                ];
                                final managerTooltip =
                                    managerAlertLabels.isNotEmpty
                                    ? 'Open Profile (${managerAlertLabels.join(', ')})'
                                    : 'Open Profile';
                                final friendAlertCount =
                                    _friendTopMenuAlertCount(
                                      controller.socialOverview,
                                    );
                                final friendBadgeLabel = friendAlertCount <= 0
                                    ? null
                                    : friendAlertCount > 9
                                    ? '9+'
                                    : friendAlertCount.toString();
                                final headerActions = <Widget>[
                                  _HeaderActionButton(
                                    icon: Icons.storefront_rounded,
                                    tooltip: 'Open Store',
                                    highlighted: controller
                                        .tutorialHighlightsStoreButton,
                                    highlightTint: LightcorePalette.quest,
                                    onPressed: () => _openStore(context),
                                  ),
                                  _HeaderActionButton(
                                    icon: Icons.workspace_premium_rounded,
                                    tooltip: claimablePassRewards > 0
                                        ? 'Open Passes ($claimablePassRewards claimable)'
                                        : 'Open Passes',
                                    badgeLabel: claimablePassRewards > 0
                                        ? claimablePassRewards.toString()
                                        : null,
                                    highlighted: controller
                                        .tutorialHighlightsBattlePassButton,
                                    highlightTint: LightcorePalette.quest,
                                    onPressed: () => _openBattlePass(context),
                                  ),
                                  _HeaderMenuButton(
                                    controller: controller,
                                    friendBadgeLabel: friendBadgeLabel,
                                    highlighted: controller
                                        .tutorialHighlightsHeaderMenuButton,
                                    highlightTint: LightcorePalette.quest,
                                    onSelected: (action) =>
                                        _selectHeaderMenuAction(
                                          context,
                                          action,
                                        ),
                                  ),
                                ];

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompactLayout ? 2 : 4,
                                    vertical: isCompactLayout ? 2 : 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _ShellProfileHeaderHud(
                                        key: const ValueKey<String>(
                                          'battle-resource-rail',
                                        ),
                                        controller: controller,
                                        compact: isCompactLayout,
                                        tooltip: managerTooltip,
                                        highlighted: controller
                                            .tutorialHighlightsPlayerManagerButton,
                                        pulseSignal: controller
                                            .tutorialPulseSignalFor(
                                              LightcoreTutorialPulseTarget
                                                  .playerManagerButton,
                                            ),
                                        showNotificationBadge: controller
                                            .hasUnspentRadianceStatPoints,
                                        onProfilePressed: () =>
                                            _openPlayerManager(context),
                                      ),
                                      SizedBox(width: isCompactLayout ? 6 : 12),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Wrap(
                                            alignment: WrapAlignment.end,
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: headerActions,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        if (battleChromeVisible)
                          Positioned.fill(
                            child: _BattleResourceFlyoutLayer(
                              controller: controller,
                              compact: isCompactLayout,
                            ),
                          ),
                        if (battleHudVisible)
                          Positioned(
                            top: isCompactLayout ? 78 : 86,
                            left: isCompactLayout ? 8 : 120,
                            right: isCompactLayout ? 8 : 120,
                            child: AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) {
                                final challenge =
                                    controller.activeThreatRegionChallenge;
                                if (challenge == null) {
                                  return const SizedBox.shrink();
                                }
                                return _ThreatChallengeHudBanner(
                                  controller: controller,
                                  onTap: () => showThreatRegionIntelDialog(
                                    context,
                                    controller,
                                    challenge.regionId,
                                  ),
                                );
                              },
                            ),
                          ),
                        if (battleChromeVisible)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, _) {
                                    return GuidedFocusFrame(
                                      active:
                                          controller.tutorialHighlightsBossBar,
                                      tint: LightcorePalette.quest,
                                      showTapCue: false,
                                      child: _OverallProgressBarPanel(
                                        controller: controller,
                                        compact: isCompactLayout,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: sectionGap),
                                AnimatedBuilder(
                                  animation: controller,
                                  builder: (context, _) {
                                    return _ShellBottomNavigation(
                                      controller: controller,
                                      compact: isCompactLayout,
                                      destinations:
                                          _visibleNavigationDestinations,
                                      selectedIndex: _selectedNavigationIndex,
                                      tint:
                                          (effectiveOverlay ??
                                                  _ShellOverlayDestination
                                                      .battle)
                                              .tint,
                                      onSelected: _selectNavigationDestination,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: effectiveOverlay == null,
                      child: LightcoreTransitionSwitcher(
                        duration: const Duration(milliseconds: 320),
                        reverseDuration: const Duration(milliseconds: 240),
                        enterOffset: const Offset(0.025, 0),
                        tint:
                            (effectiveOverlay ??
                                    _ShellOverlayDestination.battle)
                                .tint,
                        child: effectiveOverlay == null
                            ? const SizedBox.shrink(
                                key: ValueKey<String>('battle-default'),
                              )
                            : KeyedSubtree(
                                key: ValueKey<_ShellOverlayDestination>(
                                  effectiveOverlay,
                                ),
                                child: _ShellOverlayFrame(
                                  controller: controller,
                                  destination: effectiveOverlay,
                                  onClose: _closeOverlay,
                                  onOpenLayers: () => _openLayerPicker(context),
                                  fullscreen:
                                      _eventBattleSurfaceActive ||
                                      effectiveOverlay ==
                                          _ShellOverlayDestination.threatMap,
                                  child: _buildOverlayScreen(effectiveOverlay),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStore(BuildContext context) {
    widget.controller.markTutorialStoreOpened();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return LightcoreStoreSheet(
          controller: widget.controller,
          backend: widget.backend,
        );
      },
    );
  }

  void _openBattlePass(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 960),
      builder: (context) {
        return LightcoreBattlePassSheet(controller: widget.controller);
      },
    );
  }

  void _openGlobalLeaderboard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: LightcorePalette.panel,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (context) {
        return _GlobalLeaderboardSheet(
          controller: widget.controller,
          backend: widget.backend,
        );
      },
    );
  }

  Widget _buildAccountSettingsPanel(BuildContext context) {
    final linked = widget.backend.hasRecoverableAccount;
    final canUseCloud = widget.backend.canUseCloudSave;
    final canShowGoogleLinkAction = widget.onGoogleSignIn != null;
    final canShowEmailLinkAction = widget.onEmailSignIn != null;
    final authEmail = widget.backend.currentAuthEmail;
    final providerLabel = widget.backend.currentAuthProviderLabel;
    final tint = linked ? LightcorePalette.success : LightcorePalette.aether;
    final title = linked
        ? '$providerLabel Recovery Linked'
        : canUseCloud
        ? 'Guest Cloud Sync'
        : canShowGoogleLinkAction || canShowEmailLinkAction
        ? 'Guest Save'
        : 'Local Save Mode';
    final summary = linked
        ? 'This save is recoverable with $providerLabel${authEmail == null ? '' : ' ($authEmail)'}.'
        : canUseCloud
        ? 'This anonymous save is synced for this install. Link Google or email to keep the same save across devices or reinstalls.'
        : canShowGoogleLinkAction || canShowEmailLinkAction
        ? 'Link Google or email to sync this anonymous save for recovery across devices or reinstalls.'
        : 'Online cloud save is unavailable on this platform or session.';
    final canLinkGoogle =
        !linked && !widget.authBusy && widget.onGoogleSignIn != null;
    final canLinkEmail =
        !linked && !widget.authBusy && widget.onEmailSignIn != null;

    return AuroraPanel(
      tint: tint,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                linked ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                color: tint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.authBusy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(tint),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!linked)
                FilledButton.icon(
                  key: const ValueKey<String>('settings-google-sign-in-button'),
                  onPressed: canLinkGoogle
                      ? () {
                          widget.onGoogleSignIn!.call();
                        }
                      : null,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In With Google'),
                ),
              if (!linked)
                FilledButton.icon(
                  key: const ValueKey<String>('settings-email-sign-in-button'),
                  onPressed: canLinkEmail
                      ? () {
                          widget.onEmailSignIn!.call();
                        }
                      : null,
                  icon: const Icon(Icons.mark_email_read_rounded),
                  label: const Text('Link Email Save'),
                ),
              if (!linked)
                OutlinedButton.icon(
                  key: const ValueKey<String>(
                    'settings-apple-placeholder-button',
                  ),
                  onPressed: null,
                  icon: const Icon(Icons.apple_rounded),
                  label: const Text('Apple ID Soon'),
                ),
              if (linked && widget.onSignOut != null)
                TextButton.icon(
                  onPressed: widget.authBusy
                      ? null
                      : () {
                          widget.onSignOut!.call();
                        },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsPanel(
    BuildContext context,
    LightcoreController controller,
  ) {
    return AuroraPanel(
      tint: LightcorePalette.quest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Tune the in-game prompts without changing progression, rewards, or cloud saves.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _SettingsToggleRow(
            switchKey: const ValueKey<String>('notification-banners-switch'),
            icon: Icons.notifications_active_rounded,
            title: 'Notification Banners',
            subtitle:
                'Show top-of-screen messages for rewards, blocked actions, and sync updates.',
            value: controller.notificationBannersEnabled,
            tint: LightcorePalette.quest,
            onChanged: controller.setNotificationBannersEnabled,
          ),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            switchKey: const ValueKey<String>('battle-alert-banners-switch'),
            icon: Icons.sensors_rounded,
            title: 'Battle Alerts',
            subtitle:
                'Show passive combat messages like lane leaks, Apex approaches, fabrication completions, and Core Stability pressure.',
            value: controller.battleNotificationBannersEnabled,
            tint: LightcorePalette.warning,
            onChanged: controller.setBattleNotificationBannersEnabled,
          ),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            switchKey: const ValueKey<String>('tutorial-prompts-switch'),
            icon: Icons.route_rounded,
            title: 'Tutorial Prompt Banners',
            subtitle:
                'Show guide text when tutorial focus changes. Highlight frames stay active.',
            value: controller.tutorialPromptsEnabled,
            tint: LightcorePalette.aether,
            onChanged: controller.setTutorialPromptsEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSettingsPanel(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.solar,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Tune soundtrack and tap feedback for long runs.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _SettingsToggleRow(
            switchKey: const ValueKey<String>('music-enabled-switch'),
            icon: Icons.music_note_rounded,
            title: 'Music',
            subtitle: 'Play the main menu and battle loops.',
            value: _musicEnabled,
            tint: LightcorePalette.solar,
            onChanged: _setMusicEnabledFromSettings,
          ),
          const SizedBox(height: 10),
          _SettingsToggleRow(
            switchKey: const ValueKey<String>('sound-effects-enabled-switch'),
            icon: Icons.graphic_eq_rounded,
            title: 'Sound Effects',
            subtitle: 'Play UI taps, rewards, hits, warnings, and build cues.',
            value: _soundEffectsEnabled,
            tint: LightcorePalette.aether,
            onChanged: _setSoundEffectsEnabledFromSettings,
          ),
        ],
      ),
    );
  }

  void _setMusicEnabledFromSettings(bool enabled) {
    if (_musicEnabled == enabled) {
      return;
    }
    LightcoreAudio.instance.noteUserGesture();
    setState(() => _musicEnabled = enabled);
    final handler = widget.onMusicEnabledChanged;
    if (handler != null) {
      handler(enabled);
    } else {
      unawaited(LightcoreAudio.instance.setMusicEnabled(enabled));
    }
  }

  void _setSoundEffectsEnabledFromSettings(bool enabled) {
    if (_soundEffectsEnabled == enabled) {
      return;
    }
    LightcoreAudio.instance.noteUserGesture();
    setState(() => _soundEffectsEnabled = enabled);
    final handler = widget.onSoundEffectsEnabledChanged;
    if (handler != null) {
      handler(enabled);
    } else {
      LightcoreAudio.instance.setSoundEffectsEnabled(enabled);
    }
  }

  Widget _buildGraphicsSettingsPanel(
    BuildContext context,
    LightcoreController controller,
  ) {
    final selectedQuality = controller.graphicsQuality;

    return AuroraPanel(
      tint: LightcorePalette.aether,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battle Visuals',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            selectedQuality.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 440;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<LightcoreGraphicsQuality>(
                  key: const ValueKey<String>('graphics-quality-control'),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                  ),
                  segments: const [
                    ButtonSegment<LightcoreGraphicsQuality>(
                      value: LightcoreGraphicsQuality.high,
                      icon: Icon(Icons.auto_awesome_rounded),
                      label: Text('High'),
                    ),
                    ButtonSegment<LightcoreGraphicsQuality>(
                      value: LightcoreGraphicsQuality.balanced,
                      icon: Icon(Icons.tune_rounded),
                      label: Text('Balanced'),
                    ),
                    ButtonSegment<LightcoreGraphicsQuality>(
                      value: LightcoreGraphicsQuality.lowPower,
                      icon: Icon(Icons.battery_saver_rounded),
                      label: Text('Low Power'),
                    ),
                  ],
                  selected: <LightcoreGraphicsQuality>{selectedQuality},
                  onSelectionChanged: (selection) {
                    controller.setGraphicsQuality(selection.single);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    if (_settingsDialogOpen) {
      return;
    }
    LightcoreAudio.instance.playSfx(LightcoreSfx.panelOpen);
    setState(() => _settingsDialogOpen = true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: LightcorePalette.night.withValues(alpha: 0.72),
        builder: (dialogContext) {
          return AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;

              return _SelectorDialog(
                title: 'Settings',
                subtitle:
                    'Account sync, audio, notifications, stats, help, and reset controls stay here.',
                tint: controller.activeLayer.core.affinity.color,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey<String>('settings-scroll-view'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuroraPanel(
                              tint: controller.activeLayer.core.affinity.color,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Control Room',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Use Account Sync to link this save to Google, Audio to tune music and effects, Notifications to tune in-game banners, Change Name for your tournament callsign, Stats for the save ledger, and Help for Lightcore terms. Full reset restarts Lumens, Flux, Threat Scans, managers, outfit gear, Knowledge Cards, towers, EXP, and advancement progress.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAccountSettingsPanel(context),
                            const SizedBox(height: 12),
                            _buildAudioSettingsPanel(context),
                            const SizedBox(height: 12),
                            _buildNotificationSettingsPanel(
                              context,
                              controller,
                            ),
                            const SizedBox(height: 12),
                            _buildGraphicsSettingsPanel(context, controller),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () => _openStats(dialogContext),
                                  icon: const Icon(Icons.query_stats_rounded),
                                  label: const Text('Stats'),
                                ),
                                GuidedFocusFrame(
                                  active:
                                      controller.tutorialStep ==
                                      LightcoreTutorialStep.setScreenName,
                                  tint: LightcorePalette.quest,
                                  radius: 18,
                                  label: 'NAME',
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _openScreenNameDialog(dialogContext),
                                    icon: const Icon(Icons.badge_rounded),
                                    label: const Text('Change Name'),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Open Help',
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _openHelp(dialogContext),
                                    icon: const Icon(
                                      Icons.help_outline_rounded,
                                    ),
                                    label: const Text('Help'),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    await _confirmReset(context);
                                  },
                                  child: const Text('Game Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsVersionFooter(
                      version: _settingsClientDisplayVersion,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        if (!mounted) {
          return;
        }
        setState(() => _settingsDialogOpen = false);
      }),
    );
  }

  Future<void> _openScreenNameDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: LightcorePalette.night.withValues(alpha: 0.76),
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            return _ScreenNameDialog(
              controller: widget.controller,
              onSaveScreenName: _saveScreenName,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: LightcorePalette.panel,
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: LightcorePalette.warning,
          ),
          title: const Text('Reset All Progress?'),
          content: Text(
            'This wipes Lumens, Flux, Threat Scans, managers, outfit gear, Knowledge Cards, tower progress, and shell progression. This cannot be undone.',
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LightcorePalette.warning,
                foregroundColor: LightcorePalette.night,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset Everything'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await widget.backend.resetPlayerSave();
    } catch (_) {
      widget.controller.pushNotification(
        'Local reset applied. Cloud reset will retry on the next online sync.',
        duration: 4.2,
      );
    }
    widget.controller.hardResetGame();
    if (widget.backend.canUseCloudSave) {
      try {
        await widget.backend.savePlayerSave(
          widget.controller.buildCloudSavePayload(),
        );
      } catch (_) {
        widget.controller.pushNotification(
          'Reset saved locally. Cloud backup will retry when the backend is reachable.',
          duration: 4.2,
        );
      }
    }
  }

  void _openHelp(BuildContext context) {
    final controller = widget.controller;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: LightcorePalette.panel,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final helpSections = _helpSections;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.84,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${controller.guideProfile.displayName} Field Guide',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: LightcorePalette.solar.withValues(
                                alpha: 0.16,
                              ),
                            ),
                            child: Text(
                              '${controller.totalHelpSectionsRead}/${helpSections.length} read',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: LightcorePalette.solar,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open any briefing below. The first time you review one, command grants ${LightcoreController.helpSectionTicketReward} Threat Scans.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: helpSections.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final section = helpSections[index];
                            final isRead = controller.hasReadHelpSection(
                              section.id,
                            );
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRead
                                      ? LightcorePalette.success.withValues(
                                          alpha: 0.5,
                                        )
                                      : LightcorePalette.stroke.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                                color: LightcorePalette.panelRaised.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                onExpansionChanged: (expanded) {
                                  if (!expanded) {
                                    return;
                                  }
                                  if (controller.markHelpSectionRead(
                                    section.id,
                                  )) {
                                    setSheetState(() {});
                                  }
                                },
                                title: Text(
                                  section.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                subtitle: Text(section.summary),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color:
                                        (isRead
                                                ? LightcorePalette.success
                                                : LightcorePalette.solar)
                                            .withValues(alpha: 0.16),
                                  ),
                                  child: Text(
                                    isRead
                                        ? 'Claimed'
                                        : '+${LightcoreController.helpSectionTicketReward} Scans',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: isRead
                                              ? LightcorePalette.success
                                              : LightcorePalette.solar,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                children: [
                                  Text(
                                    section.body,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLayerPicker(BuildContext context) {
    if (!widget.controller.layerNavigationUnlocked) {
      return Future<void>.value();
    }
    return showDialog<void>(
      context: context,
      barrierColor: LightcorePalette.night.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final route = _layerRoute(controller);
            final connected = _connectedLayers(controller);
            final excludedIds = <String>{
              controller.activeLayer.id,
              ...route.map((layer) => layer.id),
              ...connected.map((layer) => layer.id),
            };
            final others = _orderedLayers(
              controller,
            ).where((layer) => !excludedIds.contains(layer.id)).toList();
            final activeBuilt = _layerBuiltCount(
              controller,
              controller.activeLayer,
            );
            final activeReady = controller.promotionReadyCountForLayer(
              controller.activeLayer,
            );

            return _SelectorDialog(
              title: 'Shell Map',
              subtitle:
                  'Switch shells without losing your current workspace. If Towers or Advance is open, shell changes retarget that upgrade surface immediately.',
              tint: controller.activeLayer.core.affinity.color,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  AuroraPanel(
                    tint: controller.activeLayer.core.affinity.color,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Shell Focus',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.activeLayerPassiveOnly
                              ? '${controller.activeLayerLabel} is open as a static archive. Its merged pieces can be inspected here while ${controller.runtimeLayerLabel} remains the live shell.'
                              : '${controller.activeLayerLabel} is live now. Move between connected shells here, then keep upgrading in the same screen instead of backing out through multiple menus.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            StatusPill(
                              label: controller.activeLayerPassiveOnly
                                  ? 'Passive'
                                  : 'Live',
                              value: LightcoreController.shellBadgeForTier(
                                controller.activeLayer.tier,
                              ),
                              tint: controller.activeLayer.core.affinity.color,
                              icon: controller.activeLayerPassiveOnly
                                  ? Icons.archive_rounded
                                  : Icons.visibility_rounded,
                            ),
                            StatusPill(
                              label: 'Built',
                              value:
                                  '$activeBuilt/${LightcoreController.slotCount}',
                              tint: LightcorePalette.aether,
                              icon: Icons.hub_rounded,
                            ),
                            StatusPill(
                              label: 'Ready',
                              value:
                                  '$activeReady/${LightcoreController.slotCount}',
                              tint: LightcorePalette.solar,
                              icon: Icons.upgrade_rounded,
                            ),
                          ],
                        ),
                        if (route.length > 1) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Active Route',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: LightcorePalette.mist,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final layer in route)
                                ActionChip(
                                  avatar: Icon(
                                    Icons.layers_rounded,
                                    size: 16,
                                    color: layer.id == controller.activeLayer.id
                                        ? layer.core.affinity.color
                                        : LightcorePalette.mist.withValues(
                                            alpha: 0.72,
                                          ),
                                  ),
                                  backgroundColor: LightcorePalette.panelRaised
                                      .withValues(alpha: 0.86),
                                  side: BorderSide(
                                    color:
                                        (layer.id == controller.activeLayer.id
                                                ? layer.core.affinity.color
                                                : LightcorePalette.stroke)
                                            .withValues(alpha: 0.44),
                                  ),
                                  label: Text(
                                    controller.layerDisplayLabel(layer),
                                  ),
                                  onPressed:
                                      layer.id == controller.activeLayer.id
                                      ? null
                                      : () {
                                          Navigator.of(dialogContext).pop();
                                          controller.enterLayerById(layer.id);
                                        },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (connected.isNotEmpty) ...[
                    _LayerPickerSectionHeader(
                      title: 'Connected Shells',
                      subtitle:
                          'Closest shells first: source, parent, promoted, and child branches tied to the current run.',
                    ),
                    const SizedBox(height: 10),
                    for (var index = 0; index < connected.length; index++) ...[
                      _buildLayerChoiceCard(
                        context: context,
                        dialogContext: dialogContext,
                        controller: controller,
                        layer: connected[index],
                      ),
                      if (index != connected.length - 1)
                        const SizedBox(height: 10),
                    ],
                    if (others.isNotEmpty) const SizedBox(height: 18),
                  ],
                  if (others.isNotEmpty) ...[
                    const _LayerPickerSectionHeader(
                      title: 'All Shells',
                      subtitle:
                          'Everything else in the shell tree, ordered from higher-level routes down into lower branches.',
                    ),
                    const SizedBox(height: 10),
                    for (var index = 0; index < others.length; index++) ...[
                      _buildLayerChoiceCard(
                        context: context,
                        dialogContext: dialogContext,
                        controller: controller,
                        layer: others[index],
                      ),
                      if (index != others.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLayerChoiceCard({
    required BuildContext context,
    required BuildContext dialogContext,
    required LightcoreController controller,
    required TowerLayerSnapshot layer,
  }) {
    final isViewed = layer.id == controller.activeLayer.id;
    final built = _layerBuiltCount(controller, layer);
    final ready = controller.promotionReadyCountForLayer(layer);
    final tint = isViewed
        ? layer.core.affinity.color
        : layer.core.affinity.color.withValues(alpha: 0.92);
    final markerLabel = _layerMarkerLabel(controller, layer);
    final passiveOnly = controller.isLayerPassiveOnly(layer);
    final relationLabel = passiveOnly
        ? 'Passive support'
        : _layerRelationLabel(controller, layer);

    return _SelectorChoiceCard(
      title: controller.layerDisplayLabel(layer),
      subtitle:
          '$relationLabel  •  $built/${LightcoreController.slotCount} built  •  $ready/${LightcoreController.slotCount} ready',
      tint: tint,
      selected: isViewed,
      leading: _LayerChoiceLeading(
        label: LightcoreController.shellBadgeForTier(layer.tier),
        tint: tint,
      ),
      trailing: _LayerChoiceTrailing(
        tint: tint,
        markerLabel: markerLabel,
        progressLabel: '$built/${LightcoreController.slotCount}',
      ),
      onTap: isViewed
          ? null
          : () {
              Navigator.of(dialogContext).pop();
              controller.enterLayerById(layer.id);
            },
    );
  }
}

List<TowerLayerSnapshot> _layerRoute(LightcoreController controller) {
  final route = <TowerLayerSnapshot>[];
  final seen = <String>{};
  TowerLayerSnapshot? cursor = controller.activeLayer;

  while (cursor != null && seen.add(cursor.id)) {
    route.add(cursor);
    cursor =
        _findLayerById(controller, cursor.parentLayerId) ??
        _findLayerById(controller, cursor.sourceLayerId);
  }

  return route.reversed.toList(growable: false);
}

List<TowerLayerSnapshot> _connectedLayers(LightcoreController controller) {
  final active = controller.activeLayer;
  final connected = <TowerLayerSnapshot>[];
  final seen = <String>{active.id};

  void addLayer(TowerLayerSnapshot? layer) {
    if (layer == null || !seen.add(layer.id)) {
      return;
    }
    connected.add(layer);
  }

  addLayer(_findLayerById(controller, active.parentLayerId));
  addLayer(_findLayerById(controller, active.sourceLayerId));
  addLayer(_findLayerById(controller, active.promotedParentLayerId));

  final childLayers =
      controller.layers
          .where((layer) => layer.parentLayerId == active.id)
          .toList(growable: false)
        ..sort((a, b) {
          final slotCompare =
              (a.parentSlotIndex ?? LightcoreController.slotCount).compareTo(
                b.parentSlotIndex ?? LightcoreController.slotCount,
              );
          if (slotCompare != 0) {
            return slotCompare;
          }
          return a.label.compareTo(b.label);
        });

  for (final layer in childLayers) {
    addLayer(layer);
  }

  return connected;
}

List<TowerLayerSnapshot> _orderedLayers(LightcoreController controller) {
  final layers = controller.layers.toList(growable: false)
    ..sort((a, b) {
      final depthCompare = _layerDepth(
        controller,
        a,
      ).compareTo(_layerDepth(controller, b));
      if (depthCompare != 0) {
        return depthCompare;
      }
      final slotCompare = (a.parentSlotIndex ?? -1).compareTo(
        b.parentSlotIndex ?? -1,
      );
      if (slotCompare != 0) {
        return slotCompare;
      }
      final tierCompare = b.tier.compareTo(a.tier);
      if (tierCompare != 0) {
        return tierCompare;
      }
      return a.label.compareTo(b.label);
    });

  return layers;
}

TowerLayerSnapshot? _findLayerById(
  LightcoreController controller,
  String? layerId,
) {
  if (layerId == null) {
    return null;
  }
  for (final layer in controller.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

int _layerDepth(LightcoreController controller, TowerLayerSnapshot layer) {
  var depth = 0;
  final seen = <String>{layer.id};
  var cursor = _findLayerById(
    controller,
    layer.parentLayerId ?? layer.sourceLayerId,
  );
  while (cursor != null && seen.add(cursor.id)) {
    depth += 1;
    cursor = _findLayerById(
      controller,
      cursor.parentLayerId ?? cursor.sourceLayerId,
    );
  }
  return depth;
}

int _layerBuiltCount(LightcoreController controller, TowerLayerSnapshot layer) {
  return layer.slots.where(controller.isSlotActiveTower).length;
}

String _layerRelationLabel(
  LightcoreController controller,
  TowerLayerSnapshot layer,
) {
  final active = controller.activeLayer;
  if (layer.id == active.id) {
    return 'Current shell';
  }
  if (layer.id == active.parentLayerId) {
    return 'Parent shell';
  }
  if (layer.id == active.sourceLayerId) {
    return 'Source shell';
  }
  if (layer.id == active.promotedParentLayerId) {
    return 'Higher shell';
  }
  if (layer.parentLayerId == active.id) {
    final slotIndex = layer.parentSlotIndex;
    return slotIndex == null
        ? 'Child shell'
        : 'Child shell • Hex ${slotIndex + 1}';
  }
  if (layer.sourceLayerId == active.id) {
    return 'Forged from current';
  }
  if (layer.parentLayerId != null) {
    final slotIndex = layer.parentSlotIndex;
    return slotIndex == null
        ? 'Child shell'
        : 'Child shell • Hex ${slotIndex + 1}';
  }
  if (layer.sourceLayerId != null) {
    return 'Ascended shell';
  }
  return 'Root shell';
}

String? _layerMarkerLabel(
  LightcoreController controller,
  TowerLayerSnapshot layer,
) {
  if (layer.id == controller.activeLayer.id) {
    return 'LIVE';
  }
  if (controller.isLayerPassiveOnly(layer)) {
    return 'PASSIVE';
  }
  if (_layerBuiltCount(controller, layer) == LightcoreController.slotCount &&
      controller.promotionReadyCountForLayer(layer) ==
          LightcoreController.slotCount) {
    return 'READY';
  }
  if (layer.id == controller.activeLayer.sourceLayerId) {
    return 'SOURCE';
  }
  if (layer.id == controller.activeLayer.promotedParentLayerId) {
    return 'HIGHER';
  }
  if (layer.parentLayerId == controller.activeLayer.id) {
    return 'CHILD';
  }
  return null;
}

int _friendTopMenuAlertCount(LightcoreSocialOverview? overview) {
  if (overview == null) {
    return 0;
  }
  final incomingFriendRequests = overview.invites.where((invite) {
    return invite.kind == LightcoreSocialInviteKind.friend &&
        invite.direction == LightcoreSocialInviteDirection.incoming;
  }).length;
  return overview.availableBossGiftCount + incomingFriendRequests;
}

String _formatMetricCount(int value) {
  final absolute = value.abs();
  if (absolute < 1000) {
    return value.toString();
  }
  if (absolute >= 1000000000000000) {
    return _formatCompactMetricUnit(value, 1000000000000000, 'q');
  }
  if (absolute >= 1000000000000) {
    return _formatCompactMetricUnit(value, 1000000000000, 't');
  }
  if (absolute >= 1000000000) {
    return _formatCompactMetricUnit(value, 1000000000, 'b');
  }
  if (absolute >= 1000000) {
    return _formatCompactMetricUnit(value, 1000000, 'm');
  }
  return _formatCompactMetricUnit(value, 1000, 'k');
}

String _formatCompactMetricUnit(int value, int divisor, String suffix) {
  final absolute = value.abs();
  final compact = value / divisor;
  return _trimCompactDecimal(
    '${compact.toStringAsFixed(absolute < divisor * 10 ? 1 : 0)}$suffix',
  );
}

String _trimCompactDecimal(String value) => value.replaceFirst('.0', '');

String _formatSettingsDuration(Duration duration) {
  if (duration.inHours > 0) {
    final minutes = duration.inMinutes.remainder(60);
    return '${duration.inHours}h ${minutes}m';
  }
  if (duration.inMinutes > 0) {
    final seconds = duration.inSeconds.remainder(60);
    return '${duration.inMinutes}m ${seconds}s';
  }
  return '${duration.inSeconds}s';
}
