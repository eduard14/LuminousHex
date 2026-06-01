part of '../lightcore_shell.dart';

class _ShellProfileHeaderHud extends StatelessWidget {
  const _ShellProfileHeaderHud({
    super.key,
    required this.controller,
    required this.compact,
    required this.tooltip,
    required this.highlighted,
    required this.pulseSignal,
    required this.showNotificationBadge,
    required this.onProfilePressed,
  });

  final LightcoreController controller;
  final bool compact;
  final String tooltip;
  final bool highlighted;
  final int pulseSignal;
  final bool showNotificationBadge;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final avatarSize = compact ? 40.0 : 50.0;
    final width = compact ? 128.0 : 218.0;
    final outputEfficiency = controller.outputEfficiencyLabel;
    final guideLoadout = LightcoreController.equipmentReleaseEnabled
        ? CosmicEquipmentLoadout.fromItems(<PlayerEquipmentItem?>[
            for (final slot in EquipmentLoadoutSlot.values)
              controller.equippedPlayerItemForSlot(slot),
          ])
        : CosmicEquipmentLoadout.empty;

    Widget profileButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onProfilePressed,
      child: LightcoreGuideBadge(
        guide: controller.guideProfile,
        size: avatarSize,
        equipmentLoadout: guideLoadout,
      ),
    );

    if (showNotificationBadge) {
      profileButton = Badge(
        backgroundColor: LightcorePalette.warning,
        label: const Icon(
          Icons.notifications_active_rounded,
          size: 12,
          color: LightcorePalette.night,
        ),
        child: profileButton,
      );
    }

    profileButton = Tooltip(
      message: tooltip,
      child: Semantics(button: true, label: tooltip, child: profileButton),
    );

    return GuidedFocusFrame(
      active: highlighted,
      tint: LightcorePalette.quest,
      radius: compact ? 16 : 18,
      pulseSignal: pulseSignal,
      child: SizedBox(
        width: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            profileButton,
            SizedBox(width: compact ? 7 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact) ...[
                    Text(
                      controller.playerDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  _ShellHeaderStatRow(
                    tooltip: controller.globalTowerStrengthRankingTooltip,
                    icon: Icons.leaderboard_rounded,
                    value: controller.globalTowerStrengthRankLabel,
                    tint: LightcorePalette.quest,
                    compact: compact,
                  ),
                  _ShellHeaderStatRow(
                    tooltip: 'TS: ${controller.towerStrengthLabel}',
                    icon: Icons.emoji_events_rounded,
                    value: controller.towerStrengthCompactLabel,
                    tint: LightcorePalette.layer2,
                    compact: compact,
                  ),
                  _ShellHeaderStatRow(
                    tooltip: 'Lumen: ${controller.lumens}',
                    icon: Icons.monetization_on_rounded,
                    value: _formatMetricCount(controller.lumens),
                    tint: LightcorePalette.solar,
                    compact: compact,
                    glowSignal: controller.lumens,
                  ),
                  _ShellHeaderStatRow(
                    tooltip: 'Flux: ${controller.flux}',
                    icon: Icons.diamond_rounded,
                    value: _formatMetricCount(controller.flux),
                    tint: LightcorePalette.aether,
                    compact: compact,
                  ),
                  _ShellHeaderStatRow(
                    tooltip:
                        'Output Efficiency: $outputEfficiency • Core Stability ${controller.coreStabilityLabel}',
                    icon: Icons.blur_circular_rounded,
                    value: outputEfficiency,
                    tint: controller.outputEfficiencyMultiplier >= 0.55
                        ? LightcorePalette.success
                        : LightcorePalette.warning,
                    compact: compact,
                    highlighted: controller.tutorialHighlightsCoreStats,
                    onTap: controller.markTutorialStabilityPanelOpened,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellHeaderStatRow extends StatefulWidget {
  const _ShellHeaderStatRow({
    required this.tooltip,
    required this.icon,
    required this.value,
    required this.tint,
    required this.compact,
    this.highlighted = false,
    this.glowSignal,
    this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final String value;
  final Color tint;
  final bool compact;
  final bool highlighted;
  final int? glowSignal;
  final VoidCallback? onTap;

  @override
  State<_ShellHeaderStatRow> createState() => _ShellHeaderStatRowState();
}

class _ShellHeaderStatRowState extends State<_ShellHeaderStatRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _glow = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 34,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 66,
      ),
    ]).animate(_glowController);
  }

  @override
  void didUpdateWidget(covariant _ShellHeaderStatRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.glowSignal;
    final current = widget.glowSignal;
    if (previous != null && current != null && current > previous) {
      _glowController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final glow = _glow.value;
        final textColor = Color.lerp(
          widget.tint,
          LightcorePalette.mist,
          glow * 0.16,
        )!;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 0.5 : 1),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: widget.compact ? 11 : 13,
                color: textColor,
              ),
              SizedBox(width: widget.compact ? 4 : 6),
              Expanded(
                child: Text(
                  widget.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontSize: widget.compact ? 11 : 12,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    shadows: glow <= 0
                        ? null
                        : [
                            Shadow(
                              color: widget.tint.withValues(alpha: 0.34 * glow),
                              blurRadius: 7 * glow,
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: GuidedFocusFrame(
          active: widget.highlighted,
          tint: LightcorePalette.quest,
          label: 'OUTPUT',
          child: row,
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeLabel,
    this.highlighted = false,
    this.highlightTint = LightcorePalette.aether,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String? badgeLabel;
  final bool highlighted;
  final Color highlightTint;

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: LightcorePalette.layer2,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(36, 36),
        maximumSize: const Size(36, 36),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
    );

    if (badgeLabel != null) {
      button = Badge(label: Text(badgeLabel!), child: button);
    }

    return GuidedFocusFrame(
      active: highlighted,
      tint: highlightTint,
      radius: 18,
      child: button,
    );
  }
}

class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton({
    required this.controller,
    required this.friendBadgeLabel,
    required this.highlighted,
    required this.highlightTint,
    required this.onSelected,
  });

  final LightcoreController controller;
  final String? friendBadgeLabel;
  final bool highlighted;
  final Color highlightTint;
  final ValueChanged<_ShellHeaderMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      type: MaterialType.transparency,
      child: PopupMenuButton<_ShellHeaderMenuAction>(
        tooltip: 'Open Menu',
        color: LightcorePalette.panel,
        elevation: 8,
        popUpAnimationStyle: AnimationStyle.noAnimation,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: LightcorePalette.stroke.withValues(alpha: 0.6),
          ),
        ),
        onSelected: onSelected,
        itemBuilder: (context) {
          return [
            for (final action in _ShellHeaderMenuAction.values)
              PopupMenuItem<_ShellHeaderMenuAction>(
                value: action,
                child: _HeaderMenuItemRow(
                  action: action,
                  controller: controller,
                  friendBadgeLabel: friendBadgeLabel,
                ),
              ),
          ];
        },
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(
              Icons.menu_rounded,
              size: 20,
              color: LightcorePalette.layer2,
            ),
          ),
        ),
      ),
    );

    if (friendBadgeLabel != null) {
      button = Badge(label: Text(friendBadgeLabel!), child: button);
    }

    return GuidedFocusFrame(
      active: highlighted,
      tint: highlightTint,
      radius: 18,
      child: button,
    );
  }
}

class _HeaderMenuItemRow extends StatelessWidget {
  const _HeaderMenuItemRow({
    required this.action,
    required this.controller,
    required this.friendBadgeLabel,
  });

  final _ShellHeaderMenuAction action;
  final LightcoreController controller;
  final String? friendBadgeLabel;

  @override
  Widget build(BuildContext context) {
    final destination = action.destination;
    final tint = action.tint(controller);
    final locked =
        destination != null && destination.lockedMessage(controller) != null;
    final badgeLabel = action == _ShellHeaderMenuAction.friends
        ? friendBadgeLabel
        : action == _ShellHeaderMenuAction.medals
        ? '${controller.unlockedProfileMedalCount}/${controller.profileMedals.length}'
        : action == _ShellHeaderMenuAction.leaderboard &&
              controller.globalTowerStrengthRank != null
        ? controller.globalTowerStrengthRankLabel
        : null;

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          Icon(action.icon, color: tint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeLabel != null) ...[
            const SizedBox(width: 10),
            Badge(label: Text(badgeLabel), smallSize: 8),
          ],
          if (locked) ...[
            const SizedBox(width: 10),
            Icon(Icons.lock_rounded, size: 17, color: LightcorePalette.warning),
          ],
        ],
      ),
    );
  }
}

enum _ShellHeaderMenuAction {
  settings,
  medals,
  leaderboard,
  globalChat,
  mentorship,
  dungeons,
  tournaments,
  friends,
}

extension on _ShellHeaderMenuAction {
  String get label => switch (this) {
    _ShellHeaderMenuAction.settings => 'Settings',
    _ShellHeaderMenuAction.medals => 'Medals',
    _ShellHeaderMenuAction.leaderboard => 'Leaderboard',
    _ShellHeaderMenuAction.globalChat => 'Global Chat',
    _ShellHeaderMenuAction.mentorship => 'Mentorship',
    _ShellHeaderMenuAction.dungeons => 'Daily Dungeons',
    _ShellHeaderMenuAction.tournaments => 'Tournaments',
    _ShellHeaderMenuAction.friends => 'Friends',
  };

  IconData get icon => switch (this) {
    _ShellHeaderMenuAction.settings => Icons.settings_rounded,
    _ShellHeaderMenuAction.medals => Icons.military_tech_rounded,
    _ShellHeaderMenuAction.leaderboard => Icons.leaderboard_rounded,
    _ShellHeaderMenuAction.globalChat => Icons.forum_rounded,
    _ShellHeaderMenuAction.mentorship => Icons.account_tree_rounded,
    _ShellHeaderMenuAction.dungeons => Icons.grid_view_rounded,
    _ShellHeaderMenuAction.tournaments => Icons.emoji_events_rounded,
    _ShellHeaderMenuAction.friends => Icons.group_add_rounded,
  };

  _ShellOverlayDestination? get destination => switch (this) {
    _ShellHeaderMenuAction.settings => null,
    _ShellHeaderMenuAction.medals => null,
    _ShellHeaderMenuAction.leaderboard => null,
    _ShellHeaderMenuAction.globalChat => _ShellOverlayDestination.friends,
    _ShellHeaderMenuAction.mentorship => _ShellOverlayDestination.mentees,
    _ShellHeaderMenuAction.dungeons => _ShellOverlayDestination.dungeons,
    _ShellHeaderMenuAction.tournaments => _ShellOverlayDestination.tournaments,
    _ShellHeaderMenuAction.friends => _ShellOverlayDestination.friends,
  };

  Color tint(LightcoreController controller) {
    if (this == _ShellHeaderMenuAction.leaderboard) {
      return LightcorePalette.quest;
    }
    return destination?.tint ?? controller.activeLayer.core.affinity.color;
  }
}

enum _ShellOverlayDestination {
  battle,
  towers,
  managers,
  threatMap,
  spaceRoom,
  friends,
  mentees,
  mentors,
  enemies,
  dungeons,
  tournaments,
  prestige,
}

extension on _ShellOverlayDestination {
  String get label => switch (this) {
    _ShellOverlayDestination.battle => 'Battle',
    _ShellOverlayDestination.towers => 'Towers',
    _ShellOverlayDestination.managers => 'Managers',
    _ShellOverlayDestination.threatMap => 'Threat Map',
    _ShellOverlayDestination.spaceRoom => 'Space Room',
    _ShellOverlayDestination.friends => 'Friends',
    _ShellOverlayDestination.mentees => 'Mentorship',
    _ShellOverlayDestination.mentors => 'Mentors',
    _ShellOverlayDestination.enemies => 'Anomalies',
    _ShellOverlayDestination.dungeons => 'Dungeons',
    _ShellOverlayDestination.tournaments => 'Tournament',
    _ShellOverlayDestination.prestige => 'Advance',
  };

  String get shortLabel => switch (this) {
    _ShellOverlayDestination.battle => 'Battle',
    _ShellOverlayDestination.towers => 'Towers',
    _ShellOverlayDestination.managers => 'Managers',
    _ShellOverlayDestination.threatMap => 'Map',
    _ShellOverlayDestination.spaceRoom => 'Space',
    _ShellOverlayDestination.friends => 'Friends',
    _ShellOverlayDestination.mentees => 'Mentees',
    _ShellOverlayDestination.mentors => 'Mentors',
    _ShellOverlayDestination.enemies => 'Anomaly',
    _ShellOverlayDestination.dungeons => 'Dungeons',
    _ShellOverlayDestination.tournaments => 'Arena',
    _ShellOverlayDestination.prestige => 'Advance',
  };

  Color get tint => switch (this) {
    _ShellOverlayDestination.battle => LightcorePalette.aether,
    _ShellOverlayDestination.towers => LightcorePalette.solar,
    _ShellOverlayDestination.managers => LightcorePalette.verdant,
    _ShellOverlayDestination.threatMap => LightcorePalette.scanGlow,
    _ShellOverlayDestination.spaceRoom => LightcorePalette.aether,
    _ShellOverlayDestination.friends => LightcorePalette.aether,
    _ShellOverlayDestination.mentees => LightcorePalette.violet,
    _ShellOverlayDestination.mentors => LightcorePalette.violet,
    _ShellOverlayDestination.enemies => LightcorePalette.scanGlow,
    _ShellOverlayDestination.dungeons => LightcorePalette.warning,
    _ShellOverlayDestination.tournaments => LightcorePalette.warning,
    _ShellOverlayDestination.prestige => LightcorePalette.violet,
  };

  String get loadingSubtitle => switch (this) {
    _ShellOverlayDestination.battle =>
      'Returning to the active Lightcore shell.',
    _ShellOverlayDestination.towers => 'Opening tower controls.',
    _ShellOverlayDestination.managers => 'Opening manager controls.',
    _ShellOverlayDestination.threatMap => 'Opening the Threat Map.',
    _ShellOverlayDestination.spaceRoom => 'Opening Space Room.',
    _ShellOverlayDestination.friends => 'Opening Friends.',
    _ShellOverlayDestination.mentees => 'Opening Mentees.',
    _ShellOverlayDestination.mentors => 'Opening Mentors.',
    _ShellOverlayDestination.enemies => 'Opening Knowledge Cards.',
    _ShellOverlayDestination.dungeons => 'Opening Daily Dungeons.',
    _ShellOverlayDestination.tournaments => 'Opening Tournaments.',
    _ShellOverlayDestination.prestige => 'Opening Layer Advance.',
  };

  List<String> get loadingTips => switch (this) {
    _ShellOverlayDestination.threatMap => const [
      'Threat Map progress is linear: fully stabilize one region before the next route opens.',
      'Farm Validation proves a region can survive three waves before offline rewards begin.',
    ],
    _ShellOverlayDestination.dungeons => const [
      'Daily dungeon progress persists, so cleared targets stay unlocked.',
      'Match the run route to your strongest Knowledge Card setup before entering.',
    ],
    _ShellOverlayDestination.tournaments => const [
      'Your local rank can move immediately while global tournament data refreshes in batches.',
      'Each tournament mode pressures a different part of the shell build.',
    ],
    _ShellOverlayDestination.enemies => const [
      'Knowledge Cards improve your advantage against matching anomaly families.',
      'Threat Directors raise spawn pressure and enemy strength for better rewards.',
    ],
    _ShellOverlayDestination.towers => const [
      'Tower arrangement matters: pattern bonuses can change a shell more than one upgrade.',
      'Older shells remain useful after promotion as passive support archives.',
    ],
    _ShellOverlayDestination.managers => const [
      'Managers improve auto-fire, but enemy focus clicks still help during pressure spikes.',
      'A well-matched manager can smooth charge flow across a weaker tower lane.',
    ],
    _ShellOverlayDestination.prestige => const [
      'Complete shell layers become the foundation for deeper prism structures.',
      'Promotion carries build history forward into the next shell class.',
    ],
    _ => const [
      'Output Efficiency can beat raw reward boosts when stability starts slipping.',
      'Threat Scans become Knowledge Cards that improve anomaly matchups.',
    ],
  };

  Widget get navigationIcon => switch (this) {
    _ShellOverlayDestination.battle => const Icon(Icons.radar_rounded),
    _ShellOverlayDestination.towers => const TowerRingIcon(),
    _ShellOverlayDestination.managers => const Icon(Icons.style_rounded),
    _ShellOverlayDestination.threatMap => const Icon(LightcoreIcons.threatScan),
    _ShellOverlayDestination.spaceRoom => const Icon(Icons.public_rounded),
    _ShellOverlayDestination.friends => const Icon(Icons.group_add_rounded),
    _ShellOverlayDestination.mentees => const Icon(Icons.account_tree_rounded),
    _ShellOverlayDestination.mentors => const Icon(Icons.school_rounded),
    _ShellOverlayDestination.enemies => const Icon(LightcoreIcons.anomalies),
    _ShellOverlayDestination.dungeons => const Icon(Icons.grid_view_rounded),
    _ShellOverlayDestination.tournaments => const Icon(
      Icons.emoji_events_rounded,
    ),
    _ShellOverlayDestination.prestige => const Icon(
      Icons.stacked_bar_chart_rounded,
    ),
  };

  String? lockedMessage(LightcoreController controller) => switch (this) {
    _ShellOverlayDestination.towers => _towerArchiveLockMessage(controller),
    _ShellOverlayDestination.managers => _managerLockMessage(controller),
    _ShellOverlayDestination.threatMap => _threatMapLockMessage(controller),
    _ShellOverlayDestination.enemies => _enemySuiteLockMessage(controller),
    _ShellOverlayDestination.mentees ||
    _ShellOverlayDestination.mentors => _mentorshipLockMessage(controller),
    _ShellOverlayDestination.dungeons => _dailyDungeonLockMessage(controller),
    _ShellOverlayDestination.tournaments => _tournamentLockMessage(controller),
    _ShellOverlayDestination.prestige => _advancementLockMessage(controller),
    _ => null,
  };

  bool visibleInBottomNavigation(LightcoreController controller) =>
      switch (this) {
        _ShellOverlayDestination.prestige =>
          _advancementLockMessage(controller) == null,
        _ => true,
      };
}

String? _threatMapLockMessage(LightcoreController controller) {
  if (controller.threatRegionsUnlocked) {
    return null;
  }
  return 'Threat Map unlocks after the first tower is online.';
}

String? _enemySuiteLockMessage(LightcoreController controller) {
  if (controller.enemySuiteBuilderUnlocked) {
    return null;
  }
  if (controller.threatRegionsUnlocked) {
    return 'Anomalies unlock after the first regional boss drops suite pieces. Open Map and stabilize the starter region.';
  }
  return 'Anomalies unlock after regional boss suite pieces exist. Build the first tower, then stabilize the starter region from Map.';
}

String? _towerArchiveLockMessage(LightcoreController controller) {
  if (controller.completedShellLibraryUnlocked) {
    return null;
  }
  return 'Towers unlock when Layer 2 is online. Finish the Root Shell and create the Prism Shell first.';
}

String? _managerLockMessage(LightcoreController controller) {
  return null;
}

String? _mentorshipLockMessage(LightcoreController controller) {
  if (controller.mentorshipUnlocked) {
    return null;
  }
  final remaining = controller.mentorshipLevelsRemaining;
  return 'Mentorship unlocks at Account Radiance Lv ${LightcoreController.mentorshipUnlockLevel}. Need $remaining more level${remaining == 1 ? '' : 's'} before mentors and mentees open.';
}

String? _dailyDungeonLockMessage(LightcoreController controller) {
  if (controller.dailyDungeonsUnlocked) {
    return null;
  }
  return 'Daily Dungeons unlock after the first regional boss or at Account Radiance Lv ${LightcoreController.dailyDungeonUnlockLevel}. Need ${controller.dailyDungeonLevelsRemaining} more level${controller.dailyDungeonLevelsRemaining == 1 ? '' : 's'} before the level fallback opens.';
}

String? _advancementLockMessage(LightcoreController controller) {
  final advancementAvailable =
      controller.canUnlockLayer2 ||
      controller.activeLayer.tier > 1 ||
      controller.activeLayer.promotedParentLayerId != null ||
      controller.activeLayerHasParentSlot ||
      controller.activeLayerPromotedIntoParentSlot;
  if (advancementAvailable) {
    return null;
  }

  if (controller.builtTowerCount < LightcoreController.slotCount) {
    final remaining =
        LightcoreController.slotCount - controller.builtTowerCount;
    return 'Advancement unlocks after all ${LightcoreController.slotCount} edge towers are built. Need $remaining more tower${remaining == 1 ? '' : 's'}.';
  }

  final remainingReady =
      LightcoreController.slotCount - controller.promotionReadyTowerCount;
  if (remainingReady > 0) {
    return 'Advancement unlocks after all ${LightcoreController.slotCount} edge towers reach level ${LightcoreController.maxTowerLevel}. Need $remainingReady more tower${remainingReady == 1 ? '' : 's'} at level ${LightcoreController.maxTowerLevel}.';
  }

  return null;
}

String? _tournamentLockMessage(LightcoreController controller) {
  if (!controller.tournamentsUnlocked) {
    final remaining = controller.tournamentLevelsRemaining;
    return 'Tournaments unlock at Prism, full first-ring stabilization, or Account Radiance Lv ${LightcoreController.tournamentUnlockLevel}. Need $remaining more level${remaining == 1 ? '' : 's'} for the level fallback.';
  }
  if (!controller.hasCustomScreenName) {
    return 'Set a screen name in Settings before entering tournaments.';
  }
  return null;
}
