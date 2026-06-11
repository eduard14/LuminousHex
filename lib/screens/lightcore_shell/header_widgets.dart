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
    required this.openingMode,
    required this.onProfilePressed,
  });

  final LightcoreController controller;
  final bool compact;
  final String tooltip;
  final bool highlighted;
  final int pulseSignal;
  final bool showNotificationBadge;
  final bool openingMode;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final avatarSize = openingMode
        ? (compact ? 34.0 : 42.0)
        : compact
        ? 40.0
        : 50.0;
    final width = openingMode
        ? (compact ? 112.0 : 156.0)
        : controller.layerRebuildEnabled
        ? (compact ? 150.0 : 228.0)
        : compact
        ? 128.0
        : 218.0;
    final guideLoadout = LightcoreController.equipmentReleaseEnabled
        ? CosmicEquipmentLoadout.fromItems(<PlayerEquipmentItem?>[
            for (final slot in EquipmentLoadoutSlot.values)
              controller.equippedPlayerItemForSlot(slot),
          ])
        : CosmicEquipmentLoadout.empty;

    final guideBadge = LightcoreGuideBadge(
      guide: controller.guideProfile,
      size: avatarSize,
      equipmentLoadout: guideLoadout,
    );

    Widget profileButton = openingMode
        ? guideBadge
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onProfilePressed,
            child: guideBadge,
          );

    if (!openingMode && showNotificationBadge) {
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
      message: openingMode ? 'Opening guide' : tooltip,
      child: Semantics(
        button: !openingMode,
        label: openingMode ? 'Opening guide' : tooltip,
        child: profileButton,
      ),
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
                  if (!compact && !openingMode) ...[
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
                  if (!openingMode) ...[
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
                  ],
                  if (controller.layerRebuildEnabled) ...[
                    _ShellHeaderStatRow(
                      // L1L2_REBUILD_SAFE: Rebuilt Layer 1 currencies live beside the profile instead of inside battle panels.
                      tooltip:
                          '${controller.sparksLabel}: ${controller.sparks}',
                      icon: Icons.bolt_rounded,
                      value: _formatMetricCount(controller.sparks),
                      tint: LightcorePalette.solar,
                      compact: compact,
                      glowSignal: controller.sparks,
                    ),
                    _ShellHeaderStatRow(
                      // L1L2_REBUILD_SAFE: Star Bolts are the persistent Layer 1 currency surfaced in the stable shell header.
                      tooltip:
                          '${controller.starBoltsLabel}: ${controller.starBolts}',
                      icon: Icons.auto_awesome_rounded,
                      value: _formatMetricCount(controller.starBolts),
                      tint: LightcorePalette.violet,
                      compact: compact,
                    ),
                  ] else ...[
                    _ShellHeaderStatRow(
                      tooltip: 'Lumen: ${controller.lumens}',
                      icon: Icons.monetization_on_rounded,
                      value: _formatMetricCount(controller.lumens),
                      tint: LightcorePalette.solar,
                      compact: compact,
                      glowSignal: controller.lumens,
                    ),
                    if (!openingMode)
                      _ShellHeaderStatRow(
                        tooltip: 'Flux: ${controller.flux}',
                        icon: Icons.diamond_rounded,
                        value: _formatMetricCount(controller.flux),
                        tint: LightcorePalette.aether,
                        compact: compact,
                      ),
                  ],
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
    this.glowSignal,
  });

  final String tooltip;
  final IconData icon;
  final String value;
  final Color tint;
  final bool compact;
  final int? glowSignal;

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
    return Tooltip(message: widget.tooltip, child: row);
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
    this.locked = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String? badgeLabel;
  final bool highlighted;
  final Color highlightTint;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton(
              tooltip: tooltip,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                foregroundColor: locked
                    ? LightcorePalette.warning
                    : LightcorePalette.layer2,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(36, 36),
                maximumSize: const Size(36, 36),
              ),
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
            ),
          ),
          if (locked)
            const Positioned(
              right: -1,
              bottom: -1,
              child: Icon(
                Icons.lock_rounded,
                size: 13,
                color: LightcorePalette.warning,
              ),
            ),
        ],
      ),
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
  advancement,
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
    _ShellOverlayDestination.advancement => 'Advance',
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
    _ShellOverlayDestination.advancement => 'Advance',
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
    _ShellOverlayDestination.advancement => LightcorePalette.violet,
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
    _ShellOverlayDestination.advancement => 'Opening Layer Advance.',
  };

  List<String> get loadingTips => switch (this) {
    _ShellOverlayDestination.threatMap => const [
      'Threat Map progress is linear: clear one region route before the next opens.',
      'Locking a farm wave records the region and Threat Director for offline rewards.',
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
      'A well-matched manager can smooth charge cadence across a weaker tower lane.',
    ],
    _ShellOverlayDestination.advancement => const [
      'Complete shell layers become the foundation for deeper prism structures.',
      'Promotion carries build history forward into the next shell class.',
    ],
    _ => const [
      'Tower Health pressure decides how long the current run can keep going.',
      'Sparks reset each run while Star Bolts carry permanent Layer 1 progress.',
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
    _ShellOverlayDestination.advancement => const Icon(
      Icons.stacked_bar_chart_rounded,
    ),
  };

  String? lockedMessage(LightcoreController controller) => switch (this) {
    _
        when controller.layerRebuildEnabled &&
            this != _ShellOverlayDestination.battle =>
      _rebuildDestinationLockMessage(this),
    _ShellOverlayDestination.towers => _towerArchiveLockMessage(controller),
    _ShellOverlayDestination.managers => _managerLockMessage(controller),
    _ShellOverlayDestination.threatMap => _threatMapLockMessage(controller),
    _ShellOverlayDestination.enemies => _enemySuiteLockMessage(controller),
    _ShellOverlayDestination.mentees ||
    _ShellOverlayDestination.mentors => _mentorshipLockMessage(controller),
    _ShellOverlayDestination.dungeons => _dailyDungeonLockMessage(controller),
    _ShellOverlayDestination.tournaments => _tournamentLockMessage(controller),
    _ShellOverlayDestination.advancement => _advancementLockMessage(controller),
    _ => null,
  };

  bool visibleInBottomNavigation(LightcoreController controller) =>
      switch (this) {
        _ when controller.layerRebuildEnabled => true,
        _ShellOverlayDestination.advancement =>
          _advancementLockMessage(controller) == null,
        _ => true,
      };
}

String _rebuildDestinationLockMessage(_ShellOverlayDestination destination) {
  return switch (destination) {
    _ShellOverlayDestination.towers =>
      'Tower archive is locked for this milestone. Build Layer 1 feeders from the battlefield first.',
    _ShellOverlayDestination.managers =>
      'Managers are locked while the Layer 1/2 base loop is rebuilt.',
    _ShellOverlayDestination.threatMap =>
      'Threat Map play unlocks after the Layer 1/2 base loop is stable.',
    _ShellOverlayDestination.enemies =>
      'Anomaly cards are locked until the rebuilt Layer 1 shell loop is stable.',
    _ShellOverlayDestination.dungeons =>
      'Dungeons are locked until Layer 2 has a playable base.',
    _ShellOverlayDestination.tournaments =>
      'Tournaments are locked until Layer 2 has a playable base.',
    _ShellOverlayDestination.advancement =>
      'Layer advancement is locked until completed Layer 1 shells are ready to feed Layer 2.',
    _ShellOverlayDestination.friends ||
    _ShellOverlayDestination.mentees ||
    _ShellOverlayDestination.mentors ||
    _ShellOverlayDestination.spaceRoom =>
      '${destination.label} is locked while the Layer 1/2 base loop is rebuilt.',
    _ShellOverlayDestination.battle => '',
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
    return 'Anomalies unlock after the first regional boss drops suite pieces. Open Map and clear the starter region.';
  }
  return 'Anomalies unlock after regional boss suite pieces exist. Build the first tower, then clear the starter region from Map.';
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
    return 'Tournaments unlock at Prism, full first-ring clear, or Account Radiance Lv ${LightcoreController.tournamentUnlockLevel}. Need $remaining more level${remaining == 1 ? '' : 's'} for the level fallback.';
  }
  if (!controller.hasCustomScreenName) {
    return 'Set a screen name in Settings before entering tournaments.';
  }
  return null;
}
