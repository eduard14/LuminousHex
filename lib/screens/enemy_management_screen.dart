import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/enemy_configs.dart';
import '../models/enemy_art_assets.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_rewarded_ads.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_icons.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/lightcore_detail_sheet.dart';
import '../widgets/meter_bar.dart';
import '../widgets/symbol_grid_tile.dart';

part 'enemy_management/threat_pull_widgets.dart';
part 'enemy_management/enemy_reveal_dialog.dart';
part 'enemy_management/enemy_command_widgets.dart';
part 'enemy_management/boss_widgets.dart';
part 'enemy_management/enemy_inventory_widgets.dart';
part 'enemy_management/pack_summary_widgets.dart';
part 'enemy_management/threat_assignment_widgets.dart';

Future<void> showEnemyPullSheet(
  BuildContext context,
  LightcoreController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) => EnemyPullSheet(controller: controller),
  );
}

void _showBossCardDetailsSheet(
  BuildContext context,
  LightcoreController controller,
  String cardId,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final card = controller.bossEnemyCardById(cardId);
          if (card == null) {
            return const SizedBox.shrink();
          }

          return LightcoreDetailSheet(
            tint:
                card.config.secondaryAffinity?.color ??
                card.config.affinity.color,
            child: _BossDetailSheet(controller: controller, card: card),
          );
        },
      );
    },
  );
}

enum _ThreatLibraryTab { enemies, bosses }

enum _ThreatPullTab { enemies, bosses }

class EnemyManagementScreen extends StatefulWidget {
  const EnemyManagementScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.scrollController,
  });

  final LightcoreController controller;
  final bool isActive;
  final ScrollController? scrollController;

  @override
  State<EnemyManagementScreen> createState() => _EnemyManagementScreenState();
}

class _EnemyManagementScreenState extends State<EnemyManagementScreen> {
  _ThreatLibraryTab _tab = _ThreatLibraryTab.enemies;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return ListView(
          key: const PageStorageKey<String>('enemy-management-scroll'),
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          children: [
            Text('Threat Library', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            _ThreatLibraryTabs(
              controller: controller,
              selected: _tab,
              bossesUnlocked: controller.bossHuntsUnlocked,
              onChanged: (tab) {
                if (_tab == tab) {
                  return;
                }
                setState(() => _tab = tab);
              },
            ),
            const SizedBox(height: 8),
            if (_tab == _ThreatLibraryTab.enemies) ...[
              _SwarmPressurePanel(controller: controller),
              const SizedBox(height: 18),
              _ThreatAssignmentPanel(controller: controller),
              const SizedBox(height: 18),
              _MassEnemyFusePanel(controller: controller),
            ] else ...[
              Text(
                '${controller.activeLayerLabel}  •  Owned ${controller.ownedBossEnemyCardCount}/${controller.bossEnemyCards.length}  •  ${controller.bossTicketLabel}  •  ${controller.bossCoreLabel}',
                style: textTheme.labelLarge?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apex cards have an equipped effect when armed and a positive inventory effect that starts as soon as the card is found.',
                style: textTheme.bodyMedium?.copyWith(
                  color: LightcorePalette.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              if (!controller.bossHuntsUnlocked) ...[
                _BossUnlockPanel(controller: controller),
              ] else ...[
                _BossDeckPanel(
                  controller: controller,
                  onOpenDetails: (cardId) =>
                      _showBossCardDetailsSheet(context, controller, cardId),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class EnemyPullSheet extends StatefulWidget {
  const EnemyPullSheet({super.key, required this.controller});

  final LightcoreController controller;

  @override
  State<EnemyPullSheet> createState() => _EnemyPullSheetState();
}

class _EnemyPullSheetState extends State<EnemyPullSheet> {
  static const int _rewardedTicketGrant = 5;
  static const bool _localFlutterRunFakeScansEnabled = kDebugMode;

  bool _revealBusy = false;
  bool _rewardAdBusy = false;
  _ThreatPullTab _tab = _ThreatPullTab.enemies;

  LightcoreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _tab = _preferredInitialPullTab(widget.controller);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant EnemyPullSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChange);
    _tab = _preferredInitialPullTab(widget.controller);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  _ThreatPullTab _preferredInitialPullTab(LightcoreController controller) {
    return controller.tutorialHighlightsBossSinglePullButton
        ? _ThreatPullTab.bosses
        : _ThreatPullTab.enemies;
  }

  void _handleControllerChange() {
    if (!mounted ||
        !controller.tutorialHighlightsBossSinglePullButton ||
        _tab == _ThreatPullTab.bosses) {
      return;
    }
    setState(() => _tab = _ThreatPullTab.bosses);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: AuroraPanel(
          tint: LightcorePalette.solar,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.82,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final activeBoss = controller.activeBossEnemyCard;
                final bossUnlocked = controller.bossHuntsUnlocked;
                final bossScanPreviewCards = bossUnlocked
                    ? controller.availableUnresolvedBossScanCards
                    : const <EnemyCardState>[];
                final bossTint =
                    activeBoss?.config.secondaryAffinity?.color ??
                    activeBoss?.config.affinity.color ??
                    LightcorePalette.warning;
                final enemyTint = _rarityTint(
                  controller.highestAvailableEnemyPullRarity,
                );
                final sheetTitle = _tab == _ThreatPullTab.bosses
                    ? 'Apex Scans'
                    : 'Threat Scans';
                final closeTooltip = _tab == _ThreatPullTab.bosses
                    ? 'Close apex scans'
                    : 'Close threat scans';
                return ListView(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sheetTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                          tooltip: closeTooltip,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ThreatPullTabs(
                      selected: _tab,
                      bossesUnlocked: bossUnlocked,
                      highlightBossTab:
                          controller.tutorialHighlightsBossSinglePullButton &&
                          _tab != _ThreatPullTab.bosses,
                      onChanged: (tab) {
                        if (_tab == tab) {
                          return;
                        }
                        setState(() => _tab = tab);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_tab == _ThreatPullTab.bosses) ...[
                      _ThreatScanSection(
                        title: 'Apex Anomalies',
                        tint: bossTint,
                        icon: Icons.shield_moon_rounded,
                        progress: controller.bossSummoningLevelProgress,
                        railTopLabel: 'LV ${controller.bossSummoningLevel}',
                        railBottomLabel: controller.isBossSummoningLevelMaxed
                            ? 'MAX'
                            : '${controller.pullsToNextBossSummoningLevel}',
                        statusLabel: controller.isBossSummoningLevelMaxed
                            ? 'Apex Scan level maxed'
                            : '${controller.pullsToNextBossSummoningLevel} to Apex Scan Lv ${controller.nextBossSummoningLevel}',
                        trailing: IconButton.filledTonal(
                          onPressed: () => _showBossPullRates(context),
                          tooltip: 'Show apex scan rates',
                          icon: const Icon(Icons.info_outline_rounded),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BossSignalOrb(card: activeBoss),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _InfoChip(
                                        label:
                                            activeBoss?.config.name ??
                                            'No Apex Anomaly armed',
                                      ),
                                      _InfoChip(
                                        label: controller.bossTicketLabel,
                                      ),
                                      _InfoChip(
                                        label: controller.bossCoreLabel,
                                      ),
                                      _InfoChip(
                                        label: bossUnlocked
                                            ? controller.bossSpawnStatusLabel
                                            : 'Scans unlock in the Prism Shell',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (!bossUnlocked) ...[
                              _InlineEnemyNote(
                                message:
                                    'White Warden is already the starter Apex. Create the Prism Shell to unlock Apex Scans, claim ${LightcoreCurrencyLabels.bossScanCount(LightcoreController.bossUnlockTicketGrant)}, and start changing Apex Anomaly cards.',
                                tint: LightcorePalette.warning,
                              ),
                            ] else ...[
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const spacing = 10.0;
                                  final columns = constraints.maxWidth < 300
                                      ? 2
                                      : 4;
                                  final buttonWidth =
                                      (constraints.maxWidth -
                                          (spacing * (columns - 1))) /
                                      columns;

                                  Widget action(Widget child) {
                                    return SizedBox(
                                      width: buttonWidth,
                                      child: child,
                                    );
                                  }

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: [
                                      action(
                                        GuidedFocusFrame(
                                          active: controller
                                              .tutorialHighlightsBossSinglePullButton,
                                          tint: LightcorePalette.quest,
                                          child: _TicketButton(
                                            label: '1',
                                            enabled:
                                                controller.canOpenBossTickets &&
                                                !_revealBusy,
                                            onPressed: () =>
                                                _openBossTickets(context, 1),
                                          ),
                                        ),
                                      ),
                                      action(
                                        _TicketButton(
                                          label: '10+',
                                          enabled:
                                              controller.bossHuntsUnlocked &&
                                              controller.bossTickets >= 10 &&
                                              !controller
                                                  .tutorialHighlightsBossSinglePullButton &&
                                              !_revealBusy,
                                          onPressed: () =>
                                              _openBossBatchTickets(context),
                                        ),
                                      ),
                                      action(
                                        _TicketButton(
                                          label: 'MAX',
                                          enabled:
                                              controller.bossHuntsUnlocked &&
                                              controller.bossTickets > 1 &&
                                              !controller
                                                  .tutorialHighlightsBossSinglePullButton &&
                                              !_revealBusy,
                                          onPressed: () =>
                                              _openBossMaxTickets(context),
                                        ),
                                      ),
                                      action(
                                        FilledButton.tonal(
                                          onPressed:
                                              LightcoreRewardedAds
                                                      .isSupportedPlatform &&
                                                  !_revealBusy &&
                                                  !_rewardAdBusy
                                              ? () => _claimRewardedBossTickets(
                                                  context,
                                                )
                                              : null,
                                          child: Text(
                                            _rewardAdBusy ? '...' : 'Ad',
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                LightcoreRewardedAds.isSupportedPlatform
                                    ? '${LightcoreCurrencyLabels.rewardBossScans(_rewardedTicketGrant)} per rewarded ad.'
                                    : 'Rewarded ads are available on Android and iOS builds.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Basic Apex Anomalies start single-color. Uncommon+ scans introduce hybrid color frames, Rare+ Apex Anomalies can ward an affinity, and Epic+ Apex Anomalies unlock live abilities.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (bossUnlocked) const SizedBox(height: 12),
                            if (bossUnlocked) ...[
                              Text(
                                'Unresolved Apex scan pool',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              if (bossScanPreviewCards.isEmpty)
                                _InlineEnemyNote(
                                  message:
                                      'No unresolved Apex signatures are available in the current scan tier.',
                                  tint: LightcorePalette.warning,
                                )
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final card in bossScanPreviewCards)
                                      _BossScanPreview(
                                        card: card,
                                        active: false,
                                        onTap: () => _showBossCardDetailsSheet(
                                          context,
                                          controller,
                                          card.config.id,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),
                      if (_localFlutterRunFakeScansEnabled) ...[
                        const SizedBox(height: 18),
                        _LocalRunFakeScanButton(
                          title: 'Local Fake Apex Scan',
                          description:
                              'Preview-only. Does not spend sigils or write Apex cards to inventory.',
                          buttonLabel: 'Fake Apex Scan',
                          revealBusy: _revealBusy,
                          onPressed: () => _fakeBossHunt(context),
                        ),
                      ],
                    ] else ...[
                      _ThreatScanSection(
                        title: 'Anomalies',
                        tint: enemyTint,
                        icon: LightcoreIcons.threatScan,
                        progress: controller.summoningLevelProgress,
                        railTopLabel: 'LV ${controller.summoningLevel}',
                        railBottomLabel: controller.isSummoningLevelMaxed
                            ? 'MAX'
                            : '${controller.pullsToNextSummoningLevel}',
                        statusLabel: controller.isSummoningLevelMaxed
                            ? 'Scan level maxed'
                            : '${controller.pullsToNextSummoningLevel} to Scan Lv ${controller.nextSummoningLevel}',
                        trailing: IconButton.filledTonal(
                          onPressed: () => _showPullRates(context),
                          tooltip: 'Show threat rates',
                          icon: const Icon(Icons.info_outline_rounded),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _InfoChip(
                                  label:
                                      '${LightcoreCurrencyLabels.scansShort} ${controller.enemyTickets}',
                                ),
                                _InfoChip(
                                  label: controller.isSummoningLevelMaxed
                                      ? 'All tiers unlocked'
                                      : '+${controller.nextSummoningLevelTicketReward} at Lv ${controller.nextSummoningLevel}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 10.0;
                                final columns = constraints.maxWidth < 300
                                    ? 2
                                    : 4;
                                final buttonWidth =
                                    (constraints.maxWidth -
                                        (spacing * (columns - 1))) /
                                    columns;

                                Widget action(Widget child) {
                                  return SizedBox(
                                    width: buttonWidth,
                                    child: child,
                                  );
                                }

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    action(
                                      GuidedFocusFrame(
                                        active: controller
                                            .tutorialHighlightsEnemySinglePullButton,
                                        tint: LightcorePalette.quest,
                                        child: _TicketButton(
                                          label: '1',
                                          enabled:
                                              controller.enemyTickets >= 1 &&
                                              !_revealBusy,
                                          onPressed: () =>
                                              _openTickets(context, 1),
                                        ),
                                      ),
                                    ),
                                    action(
                                      _TicketButton(
                                        label: '10+',
                                        enabled:
                                            controller.enemyTickets >= 10 &&
                                            !controller
                                                .tutorialHighlightsEnemySinglePullButton &&
                                            !_revealBusy,
                                        onPressed: () =>
                                            _openBatchTickets(context),
                                      ),
                                    ),
                                    action(
                                      _TicketButton(
                                        label: 'MAX',
                                        enabled:
                                            controller.enemyTickets > 1 &&
                                            !controller
                                                .tutorialHighlightsEnemySinglePullButton &&
                                            !_revealBusy,
                                        onPressed: () =>
                                            _openMaxTickets(context),
                                      ),
                                    ),
                                    action(
                                      FilledButton.tonal(
                                        onPressed:
                                            LightcoreRewardedAds
                                                    .isSupportedPlatform &&
                                                !_revealBusy &&
                                                !_rewardAdBusy
                                            ? () =>
                                                  _claimRewardedTickets(context)
                                            : null,
                                        child: Text(
                                          _rewardAdBusy ? '...' : 'Ad',
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LightcoreRewardedAds.isSupportedPlatform
                                  ? '${LightcoreCurrencyLabels.rewardThreatScans(_rewardedTicketGrant)} per rewarded ad.'
                                  : 'Rewarded ads are available on Android and iOS builds.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (_localFlutterRunFakeScansEnabled) ...[
                        const SizedBox(height: 18),
                        _LocalRunFakeScanButton(
                          title: 'Local Fake Threat Scan',
                          description:
                              'Preview-only. Does not spend scans or write anomaly cards to inventory.',
                          buttonLabel: 'Fake Threat Scan',
                          revealBusy: _revealBusy,
                          onPressed: () => _fakeThreatScan(context),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTickets(BuildContext context, int count) async {
    if (_revealBusy) {
      return;
    }
    final pulls = controller.tutorialOpenEnemyTickets(count);
    if (pulls.isEmpty) {
      return;
    }
    await _showPullReveal(
      context,
      pulls: pulls,
      highestAvailableRarity: controller.highestAvailableEnemyPullRarity,
      secondHighestAvailableRarity:
          controller.secondHighestAvailableEnemyPullRarity,
    );
  }

  Future<void> _openBatchTickets(BuildContext context) async {
    if (_revealBusy || controller.enemyTickets < 10) {
      return;
    }
    final count = await _showBatchOpenSheet(
      context,
      title: 'Open 10+',
      maxTickets: controller.enemyTickets,
      unitLabel: 'scans',
    );
    if (!mounted || count == null) {
      return;
    }
    await _openTickets(this.context, count);
  }

  Future<void> _openMaxTickets(BuildContext context) async {
    if (_revealBusy || controller.enemyTickets <= 0) {
      return;
    }
    await _openTickets(context, controller.enemyTickets);
  }

  Future<void> _openBossTickets(BuildContext context, int count) async {
    if (_revealBusy) {
      return;
    }
    final pulls = controller.tutorialOpenBossTickets(count);
    if (pulls.isEmpty) {
      return;
    }
    await _showPullReveal(
      context,
      pulls: pulls,
      highestAvailableRarity: controller.highestAvailableBossPullRarity,
      secondHighestAvailableRarity:
          controller.secondHighestAvailableBossPullRarity,
      title: 'Apex Scans',
    );
  }

  Future<void> _openBossBatchTickets(BuildContext context) async {
    if (_revealBusy || controller.bossTickets < 10) {
      return;
    }
    final count = await _showBatchOpenSheet(
      context,
      title: 'Open 10+',
      maxTickets: controller.bossTickets,
      unitLabel: 'scans',
    );
    if (!mounted || count == null) {
      return;
    }
    await _openBossTickets(this.context, count);
  }

  Future<void> _openBossMaxTickets(BuildContext context) async {
    if (_revealBusy || controller.bossTickets <= 0) {
      return;
    }
    await _openBossTickets(context, controller.bossTickets);
  }

  Future<int?> _showBatchOpenSheet(
    BuildContext context, {
    required String title,
    required int maxTickets,
    required String unitLabel,
  }) {
    double selectedCount = 10;

    return showModalBottomSheet<int>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentCount = selectedCount.round();
            final divisions = maxTickets > 10 ? maxTickets - 10 : null;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AuroraPanel(
                  tint: LightcorePalette.solar,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            tooltip: 'Close batch picker',
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$currentCount $unitLabel',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: LightcorePalette.layer2),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: selectedCount,
                        min: 10,
                        max: maxTickets.toDouble(),
                        divisions: divisions,
                        label: '$currentCount',
                        activeColor: LightcorePalette.solar,
                        inactiveColor: LightcorePalette.solar.withValues(
                          alpha: 0.2,
                        ),
                        onChanged: maxTickets > 10
                            ? (value) {
                                setModalState(() {
                                  selectedCount = value;
                                });
                              }
                            : null,
                      ),
                      Row(
                        children: [
                          Text(
                            '10',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '$maxTickets',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(currentCount),
                            child: Text('Open $currentCount'),
                          ),
                        ],
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

  Future<void> _claimRewardedTickets(BuildContext context) async {
    if (_rewardAdBusy) {
      return;
    }

    setState(() {
      _rewardAdBusy = true;
    });
    try {
      final earned = await showLightcoreRewardedAd(
        context,
        rewardLabel: LightcoreCurrencyLabels.rewardThreatScans(
          _rewardedTicketGrant,
        ),
      );
      if (!mounted || !earned) {
        return;
      }
      controller.grantRewardedResources(
        enemyTicketsGranted: _rewardedTicketGrant,
        sourceLabel: 'Reward ad • Scan resupply',
      );
    } finally {
      if (mounted) {
        setState(() {
          _rewardAdBusy = false;
        });
      }
    }
  }

  Future<void> _claimRewardedBossTickets(BuildContext context) async {
    if (_rewardAdBusy) {
      return;
    }

    setState(() {
      _rewardAdBusy = true;
    });
    try {
      final earned = await showLightcoreRewardedAd(
        context,
        rewardLabel: LightcoreCurrencyLabels.rewardBossScans(
          _rewardedTicketGrant,
        ),
      );
      if (!mounted || !earned) {
        return;
      }
      controller.grantRewardedResources(
        bossTicketsGranted: _rewardedTicketGrant,
        sourceLabel: 'Reward ad • Apex Scan resupply',
      );
    } finally {
      if (mounted) {
        setState(() {
          _rewardAdBusy = false;
        });
      }
    }
  }

  Future<void> _fakeThreatScan(BuildContext context) async {
    if (_revealBusy) {
      return;
    }
    await _showPullReveal(
      context,
      pulls: _buildFakePulls(
        focusRarity: controller.highestAvailableEnemyPullRarity,
        availableRarities: controller.availableEnemyPullRarities,
        poolsByRarity: EnemyLibrary.byRarity,
      ),
      highestAvailableRarity: controller.highestAvailableEnemyPullRarity,
      secondHighestAvailableRarity:
          controller.secondHighestAvailableEnemyPullRarity,
      previewOnly: true,
    );
  }

  Future<void> _fakeBossHunt(BuildContext context) async {
    if (_revealBusy) {
      return;
    }
    await _showPullReveal(
      context,
      pulls: _buildFakePulls(
        focusRarity: controller.highestAvailableBossPullRarity,
        availableRarities: controller.availableBossPullRarities,
        poolsByRarity: BossEnemyLibrary.byRarity,
      ),
      highestAvailableRarity: controller.highestAvailableBossPullRarity,
      secondHighestAvailableRarity:
          controller.secondHighestAvailableBossPullRarity,
      title: 'Apex Scans',
      previewOnly: true,
    );
  }

  Future<void> _showPullReveal(
    BuildContext context, {
    required List<PackPullResult> pulls,
    required EnemyCardRarity highestAvailableRarity,
    required EnemyCardRarity? secondHighestAvailableRarity,
    String title = 'Threat Scans',
    bool previewOnly = false,
  }) async {
    setState(() {
      _revealBusy = true;
    });
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: LightcorePalette.night.withValues(alpha: 0.92),
        builder: (dialogContext) {
          return _EnemyPackRevealDialog(
            pulls: pulls,
            highestAvailableRarity: highestAvailableRarity,
            secondHighestAvailableRarity: secondHighestAvailableRarity,
            title: title,
            previewOnly: previewOnly,
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _revealBusy = false;
        });
      }
    }
  }

  List<PackPullResult> _buildFakePulls({
    required EnemyCardRarity focusRarity,
    required List<EnemyCardRarity> availableRarities,
    required Map<EnemyCardRarity, List<EnemyConfig>> poolsByRarity,
  }) {
    final allowedRarities = availableRarities
        .where((rarity) => rarity.index <= focusRarity.index)
        .toList(growable: false);
    final floorRarity = allowedRarities.first;
    final bridgeRarity = allowedRarities.length > 1
        ? allowedRarities[allowedRarities.length - 2]
        : floorRarity;
    final focusPool = poolsByRarity[focusRarity]!;
    final bridgePool = poolsByRarity[bridgeRarity]!;
    final floorPool = poolsByRarity[floorRarity]!;
    return <PackPullResult>[
      PackPullResult(config: focusPool[0], isNew: false),
      PackPullResult(config: bridgePool[1 % bridgePool.length], isNew: false),
      PackPullResult(config: focusPool[0], isNew: false),
      PackPullResult(config: floorPool[2 % floorPool.length], isNew: false),
      PackPullResult(config: focusPool[3 % focusPool.length], isNew: false),
      PackPullResult(config: focusPool[0], isNew: false),
      PackPullResult(config: bridgePool[4 % bridgePool.length], isNew: false),
      PackPullResult(config: focusPool[3 % focusPool.length], isNew: false),
    ];
  }

  void _showPullRates(BuildContext context) {
    final rates = controller.summonRates;
    final maxed = controller.isSummoningLevelMaxed;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LightcorePalette.panel,
          title: const Text('Threat Rates'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan Level ${controller.summoningLevel}'),
                Text('Total Scans ${controller.enemyPullCount}'),
                const SizedBox(height: 12),
                MeterBar(
                  value: controller.summoningLevelProgress,
                  color: LightcorePalette.solar,
                  height: 12,
                ),
                const SizedBox(height: 8),
                Text(
                  maxed
                      ? 'Scan level maxed. All threat rarity tiers are already unlocked.'
                      : '${controller.summoningLevelPullsIntoCurrent}/${controller.currentSummoningLevelPullGap} scans in this level. ${controller.pullsToNextSummoningLevel} more scans unlock Scan Lv ${controller.nextSummoningLevel} and +${controller.nextSummoningLevelTicketReward} tickets.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final rarity in EnemyCardRarity.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(rarity.label)),
                        Text(_formatRate(rates[rarity] ?? 0)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Scan milestone gaps increase up to ${LightcoreController.finalSummoningLevelPullGap} resolved scans and cap at level ${LightcoreController.maxSummoningLevel}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showBossPullRates(BuildContext context) {
    final rates = controller.bossSummonRates;
    final maxed = controller.isBossSummoningLevelMaxed;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LightcorePalette.panel,
          title: const Text('Apex Scan Rates'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apex Scan Lv ${controller.bossSummoningLevel}'),
                Text('Total Apex Scans ${controller.bossPullCount}'),
                const SizedBox(height: 12),
                MeterBar(
                  value: controller.bossSummoningLevelProgress,
                  color: LightcorePalette.warning,
                  height: 12,
                ),
                const SizedBox(height: 8),
                Text(
                  maxed
                      ? 'Apex Scan level maxed. Every Apex Anomaly rarity tier is live.'
                      : '${controller.bossSummoningLevelPullsIntoCurrent}/${LightcoreController.bossPullsPerSummoningLevel} scans in this level. ${controller.pullsToNextBossSummoningLevel} more scans unlock Apex Scan Lv ${controller.nextBossSummoningLevel} and ${LightcoreCurrencyLabels.rewardBossScans(controller.nextBossSummoningLevelTicketReward)}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final rarity in EnemyCardRarity.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(rarity.label)),
                        Text(_formatRate(rates[rarity] ?? 0)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Apex Scan level increases every ${LightcoreController.bossPullsPerSummoningLevel} resolved scans and caps at level ${LightcoreController.maxBossSummoningLevel}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatRate(double rate) {
    if (rate == 0) {
      return '0%';
    }
    if (rate < 0.1) {
      return '${rate.toStringAsFixed(2)}%';
    }
    if (rate < 1) {
      return '${rate.toStringAsFixed(1)}%';
    }
    return '${rate.toStringAsFixed(0)}%';
  }
}
