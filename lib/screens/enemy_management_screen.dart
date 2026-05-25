import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/enemy_configs.dart';
import '../data/threat_region_configs.dart';
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
            Text('Knowledge Build', style: textTheme.titleLarge),
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
              _EnemySuiteBuildPanel(controller: controller),
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
                'Apex Knowledge Cards have an equipped effect when armed and a positive collection bonus that starts as soon as the card is found.',
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

class _EnemySuiteBuildPanel extends StatelessWidget {
  const _EnemySuiteBuildPanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ownedCores = controller.apexCores
        .where((core) => core.isOwned)
        .toList(growable: false);
    final ownedTraits = controller.bossTraits
        .where((trait) => trait.isOwned)
        .toList(growable: false);
    final ownedAnomalies = controller.enemyCards
        .where((card) => card.isOwned)
        .toList(growable: false);
    final tint = controller.hasCompleteEnemySuite
        ? LightcorePalette.success
        : LightcorePalette.warning;

    if (!controller.enemySuiteBuilderUnlocked) {
      return AuroraPanel(
        tint: LightcorePalette.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Knowledge Build Locked', style: textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Portable enemy suites unlock when the first mode that needs them comes online, or when a regional boss drops suite pieces.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoChip(
                  label:
                      controller.overallLevel >=
                          LightcoreController.dailyDungeonUnlockLevel
                      ? 'Dungeons ready'
                      : 'Dungeons locked',
                ),
                _InfoChip(
                  label:
                      controller.overallLevel >=
                          LightcoreController.tournamentUnlockLevel
                      ? 'Arena ready'
                      : 'Arena locked',
                ),
                _InfoChip(
                  label: '${controller.fullyStabilizedRegionCount} regions',
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AuroraPanel(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Knowledge Book', style: textTheme.titleLarge),
              ),
              _InfoChip(
                label: controller.hasCompleteEnemySuite
                    ? 'Complete'
                    : 'Incomplete',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Set the portable Knowledge Book used by Arena, Threat Director Dungeon, and future challenge modes.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(label: '${ownedCores.length} Apex Cores'),
              _InfoChip(label: '${ownedTraits.length} Traits'),
              _InfoChip(label: '${ownedAnomalies.length} Cards'),
              _InfoChip(label: '${controller.threatShards} Threat Shards'),
            ],
          ),
          const SizedBox(height: 16),
          if (ownedCores.isEmpty ||
              ownedTraits.isEmpty ||
              ownedAnomalies.isEmpty)
            _InlineEnemyNote(
              message:
                  'Clear regional bosses to earn Apex Cores, boss traits, and the regional Knowledge Cards used here.',
              tint: LightcorePalette.warning,
            )
          else
            _EnemySuiteSlots(
              controller: controller,
              ownedCores: ownedCores,
              ownedTraits: ownedTraits,
              ownedAnomalies: ownedAnomalies,
            ),
        ],
      ),
    );
  }
}

class _EnemySuiteSlots extends StatelessWidget {
  const _EnemySuiteSlots({
    required this.controller,
    required this.ownedCores,
    required this.ownedTraits,
    required this.ownedAnomalies,
  });

  final LightcoreController controller;
  final List<ApexCoreState> ownedCores;
  final List<BossTraitState> ownedTraits;
  final List<EnemyCardState> ownedAnomalies;

  @override
  Widget build(BuildContext context) {
    final suite = controller.activeEnemySuite;
    final selectedTraits = _fixedSelection(suite.bossTraitIds, 2);
    final selectedAnomalies = _fixedSelection(suite.anomalyCardIds, 3);
    final apexValue = _validApexValue(suite.apexCoreBossId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SuiteDropdown<String>(
          label: 'Apex Core',
          value: apexValue,
          items: [
            for (final core in ownedCores)
              DropdownMenuItem<String>(
                value: core.bossConfig.id,
                child: Text('${core.bossConfig.name} • x${core.copies}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              _setSuite(apexCoreBossId: value);
            }
          },
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < 2; index += 1) ...[
          _SuiteDropdown<String>(
            label: 'Boss Trait ${index + 1}',
            value: _validTraitValue(selectedTraits[index]),
            items: [
              for (final trait in ownedTraits)
                DropdownMenuItem<String>(
                  value: trait.config.id,
                  child: Text('${trait.config.effectLabel} • x${trait.copies}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                final next = List<String?>.from(selectedTraits);
                next[index] = value;
                _setSuite(
                  bossTraitIds: next.whereType<String>().toList(
                    growable: false,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        for (var index = 0; index < 3; index += 1) ...[
          _SuiteDropdown<String>(
            label: 'Knowledge Card ${index + 1}',
            value: _validAnomalyValue(selectedAnomalies[index]),
            items: [
              for (final card in ownedAnomalies)
                DropdownMenuItem<String>(
                  value: card.config.id,
                  child: Text('${card.config.name} • x${card.copies}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                final next = List<String?>.from(selectedAnomalies);
                next[index] = value;
                _setSuite(
                  anomalyCardIds: next.whereType<String>().toList(
                    growable: false,
                  ),
                );
              }
            },
          ),
          if (index < 2) const SizedBox(height: 12),
        ],
        const SizedBox(height: 14),
        _InlineEnemyNote(
          message: controller.hasCompleteEnemySuite
              ? 'Knowledge Book ready. Duplicate trait or card slots consume matching owned copies.'
              : 'Fill 1 Apex Core, 2 boss traits, and 3 Knowledge Cards. Duplicate traits or cards require enough copies.',
          tint: controller.hasCompleteEnemySuite
              ? LightcorePalette.success
              : LightcorePalette.warning,
        ),
      ],
    );
  }

  List<String?> _fixedSelection(List<String> values, int length) {
    return List<String?>.generate(
      length,
      (index) => index < values.length ? values[index] : null,
      growable: false,
    );
  }

  String? _validApexValue(String? value) {
    if (value == null) {
      return null;
    }
    return ownedCores.any((core) => core.bossConfig.id == value) ? value : null;
  }

  String? _validTraitValue(String? value) {
    if (value == null) {
      return null;
    }
    return ownedTraits.any((trait) => trait.config.id == value) ? value : null;
  }

  String? _validAnomalyValue(String? value) {
    if (value == null) {
      return null;
    }
    return ownedAnomalies.any((card) => card.config.id == value) ? value : null;
  }

  void _setSuite({
    String? apexCoreBossId,
    List<String>? bossTraitIds,
    List<String>? anomalyCardIds,
  }) {
    final suite = controller.activeEnemySuite;
    final fallbackApex = ownedCores.isEmpty
        ? null
        : ownedCores.first.bossConfig.id;
    final nextApex = apexCoreBossId ?? suite.apexCoreBossId ?? fallbackApex;
    if (nextApex == null) {
      return;
    }
    controller.setActiveEnemySuite(
      apexCoreBossId: nextApex,
      bossTraitIds: bossTraitIds ?? suite.bossTraitIds,
      anomalyCardIds: anomalyCardIds ?? suite.anomalyCardIds,
    );
  }
}

class _SuiteDropdown<T> extends StatelessWidget {
  const _SuiteDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}

class _ThreatRegionMapPanel extends StatefulWidget {
  const _ThreatRegionMapPanel({required this.controller});

  final LightcoreController controller;

  @override
  State<_ThreatRegionMapPanel> createState() => _ThreatRegionMapPanelState();
}

class _ThreatRegionMapPanelState extends State<_ThreatRegionMapPanel> {
  String? _previewRegionId;

  LightcoreController get controller => widget.controller;

  void _handleRegionTap(ThreatRegionConfig region) {
    final state = controller.threatRegionStateById(region.id);
    if (state?.revealed ?? false) {
      controller.selectThreatRegion(region.id);
      setState(() {
        _previewRegionId = null;
      });
      return;
    }
    setState(() {
      _previewRegionId = region.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedThreatRegionConfig;
    final selectedState = controller.selectedThreatRegionState;
    final previewCandidate = _previewRegionId == null
        ? null
        : ThreatRegionLibrary.byId[_previewRegionId!];
    final previewState = previewCandidate == null
        ? null
        : controller.threatRegionStateById(previewCandidate.id);
    final previewed =
        previewCandidate != null && !(previewState?.revealed ?? false)
        ? previewCandidate
        : null;
    final detailRegion = previewed ?? selected;
    final detailState = previewed == null ? selectedState : previewState;
    final detailRevealed = detailState?.revealed ?? false;
    final textTheme = Theme.of(context).textTheme;
    final displayedRegions = controller.threatRegionConfigs;
    return AuroraPanel(
      tint: previewed != null
          ? _rarityTint(previewed.rarity)
          : selected == null
          ? LightcorePalette.solar
          : _rarityTint(selected.rarity),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Threat Map', style: textTheme.titleMedium),
              const _InfoChip(label: 'Linear route'),
              _InfoChip(label: 'Swarm ${controller.farmSwarmSize}'),
              _InfoChip(
                label: '${controller.fullyStabilizedRegionCount} stabilized',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 286,
            child: _ThreatRegionMapViewport(
              compact: false,
              onRegionTapped: _handleRegionTap,
              painter: _ThreatRegionMapPainter(
                regions: displayedRegions,
                states: {
                  for (final state in controller.threatRegions)
                    state.regionId: state,
                },
                selectedRegionId: controller.selectedThreatRegionId,
                previewRegionId: previewed?.id,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selected?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Selected region'),
            items: [
              for (final region in displayedRegions)
                if (controller.threatRegionStateById(region.id)?.revealed ??
                    false)
                  DropdownMenuItem<String>(
                    value: region.id,
                    child: Text(
                      '${region.name} • Ring ${region.ring}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            onChanged: (value) {
              if (value != null) {
                controller.selectThreatRegion(value);
                setState(() {
                  _previewRegionId = null;
                });
              }
            },
          ),
          if (detailRegion != null && detailState != null) ...[
            const SizedBox(height: 12),
            Text(
              detailRevealed
                  ? '${detailRegion.name}: Lv ${detailState.stabilizedLevel}/${detailRegion.stabilizationLayers} stabilized'
                  : '${detailRegion.name}: locked route step ${controller.threatRegionSpiralIndex(detailRegion.id) + 1}',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _threatRegionLore(detailRegion),
              style: textTheme.bodySmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _threatRegionSignatureLine(detailRegion),
              style: textTheme.bodySmall?.copyWith(
                color: _rarityTint(detailRegion.rarity).withValues(alpha: 0.82),
              ),
            ),
            if (detailRevealed) ...[
              const SizedBox(height: 8),
              _InlineEnemyNote(
                message: controller.validatedFarmRegionId == detailRegion.id
                    ? 'Offline farm validated at swarm ${controller.validatedFarmSwarmSize} • ${controller.threatRegionOfflineKillsPerHour.toStringAsFixed(0)} kills/hr • ${controller.threatRegionOfflineLumensPerHour.toStringAsFixed(0)} Lumens/hr.'
                    : 'Offline rewards unlock after Farm Validation survives 3 waves at this level with its Threat Director.',
                tint: controller.validatedFarmRegionId == detailRegion.id
                    ? LightcorePalette.success
                    : LightcorePalette.warning,
              ),
            ],
            if (detailRevealed) ...[
              const SizedBox(height: 12),
              if (controller.enemyManagers.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue:
                      controller.enemyManagers.any(
                        (manager) =>
                            manager.instanceId ==
                            detailState.assignedThreatDirectorId,
                      )
                      ? detailState.assignedThreatDirectorId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Region Threat Director',
                  ),
                  items: [
                    for (final manager in controller.enemyManagers)
                      DropdownMenuItem<String>(
                        value: manager.instanceId,
                        child: Text(manager.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.assignThreatDirectorToRegion(
                        regionId: detailRegion.id,
                        managerId: value,
                      );
                    }
                  },
                )
              else
                _InlineEnemyNote(
                  message:
                      'Forge a Threat Director to tune this region before Farm Validation.',
                  tint: LightcorePalette.layer2,
                ),
            ],
            if (detailRevealed) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GuidedFocusFrame(
                    active: controller.tutorialHighlightsThreatChallengeButton,
                    tint: LightcorePalette.quest,
                    child: FilledButton.icon(
                      onPressed:
                          controller.canStartThreatRegionChallenge(
                            detailRegion.id,
                          )
                          ? () => controller.startThreatRegionChallenge(
                              detailRegion.id,
                            )
                          : null,
                      icon: const Icon(Icons.flag_rounded),
                      label: Text(
                        detailState.stabilizedLevel >=
                                detailRegion.stabilizationLayers
                            ? 'Stable'
                            : 'Challenge Lv ${detailState.stabilizedLevel + 1}',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        controller.canStartThreatRegionFarmValidation(
                          detailRegion.id,
                        )
                        ? () => controller.startThreatRegionFarmValidation(
                            detailRegion.id,
                          )
                        : null,
                    icon: const Icon(Icons.waves_rounded),
                    label: Text(
                      controller.validatedFarmRegionId == detailRegion.id
                          ? 'Revalidate Farm'
                          : 'Validate Farm',
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (!controller.fullThreatMapUnlocked) ...[
            const SizedBox(height: 10),
            Text(
              controller.threatRegionsUnlocked
                  ? 'The route opens one region at a time. Fully stabilize the current region to unlock the next step.'
                  : 'All regions are fixed for every player. Build the first tower to start the route.',
              style: textTheme.bodySmall?.copyWith(
                color: LightcorePalette.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreatRegionMapViewport extends StatefulWidget {
  const _ThreatRegionMapViewport({
    required this.painter,
    required this.onRegionTapped,
    this.compact = false,
  });

  final _ThreatRegionMapPainter painter;
  final ValueChanged<ThreatRegionConfig> onRegionTapped;
  final bool compact;

  @override
  State<_ThreatRegionMapViewport> createState() =>
      _ThreatRegionMapViewportState();
}

class _ThreatRegionMapViewportState extends State<_ThreatRegionMapViewport> {
  late final TransformationController _transformationController;
  double _zoomScale = 1;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController()
      ..addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController
      ..removeListener(_handleTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final nextScale = _transformationController.value
        .getMaxScaleOnAxis()
        .clamp(0.9, 3.6)
        .toDouble();
    if ((nextScale - _zoomScale).abs() < 0.03) {
      return;
    }
    setState(() {
      _zoomScale = nextScale;
    });
  }

  void _handleTapUp(TapUpDetails details, Size size) {
    final scenePoint = _transformationController.toScene(details.localPosition);
    final region = widget.painter.regionAt(scenePoint, size);
    if (region != null) {
      widget.onRegionTapped(region);
    }
  }

  void _resetTransform() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (widget.compact ? 240.0 : 286.0);
        final size = Size(width, height);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: LightcorePalette.stroke.withValues(alpha: 0.48),
            ),
            gradient: LinearGradient(
              colors: [
                LightcorePalette.night.withValues(alpha: 0.94),
                LightcorePalette.abyss.withValues(alpha: 0.88),
                LightcorePalette.panel.withValues(alpha: 0.76),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.9,
              maxScale: 3.6,
              boundaryMargin: const EdgeInsets.all(96),
              panEnabled: true,
              scaleEnabled: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTapUp(details, size),
                onDoubleTap: _resetTransform,
                child: RepaintBoundary(
                  child: CustomPaint(
                    isComplex: true,
                    painter: widget.painter.copyWithZoom(_zoomScale),
                    child: SizedBox(width: width, height: height),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThreatRegionMapPainter extends CustomPainter {
  const _ThreatRegionMapPainter({
    required this.regions,
    required this.states,
    required this.selectedRegionId,
    this.previewRegionId,
    this.zoomScale = 1,
  });

  final List<ThreatRegionConfig> regions;
  final Map<String, ThreatRegionState> states;
  final String? selectedRegionId;
  final String? previewRegionId;
  final double zoomScale;

  _ThreatRegionMapPainter copyWithZoom(double zoomScale) {
    return _ThreatRegionMapPainter(
      regions: regions,
      states: states,
      selectedRegionId: selectedRegionId,
      previewRegionId: previewRegionId,
      zoomScale: zoomScale,
    );
  }

  ThreatRegionConfig? regionAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = _hexGridRadius(size);
    for (final region in regions.reversed) {
      final point = _axialToPixel(region.q, region.r, radius, center);
      final path = _hexPath(point, radius * 0.92);
      if (path.contains(position)) {
        return region;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = _hexGridRadius(size);
    _drawMapBackdrop(canvas, size, center, radius);
    _drawSpiralPath(canvas, center, radius);
    for (final region in regions) {
      final state = states[region.id];
      final point = _axialToPixel(region.q, region.r, radius, center);
      final hexRadius = radius * 0.92;
      final path = _hexPath(point, hexRadius);
      final revealed = state?.revealed ?? false;
      final full =
          state != null && state.stabilizedLevel >= region.stabilizationLayers;
      final tint = full ? LightcorePalette.success : _rarityTint(region.rarity);
      _drawSectorFill(
        canvas,
        path: path,
        center: point,
        radius: hexRadius,
        tint: tint,
        revealed: revealed,
        full: full,
        previewed: region.id == previewRegionId,
      );
      _drawSectorTexture(
        canvas,
        path: path,
        center: point,
        radius: hexRadius,
        region: region,
        tint: tint,
        revealed: revealed,
      );
      _drawAnomalyMarkers(
        canvas,
        center: point,
        radius: hexRadius,
        region: region,
        revealed: revealed,
      );
      _drawSectorLabels(
        canvas,
        center: point,
        radius: hexRadius,
        region: region,
        state: state,
        revealed: revealed,
      );
      if (region.id == selectedRegionId) {
        final selectedStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..color = LightcorePalette.solar;
        canvas.drawPath(path, selectedStroke);
      }
      if (region.id == previewRegionId) {
        final previewStroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = LightcorePalette.scanGlow.withValues(alpha: 0.88);
        canvas.drawPath(path, previewStroke);
      }
    }
  }

  double _hexGridRadius(Size size) {
    return math.min(size.width / 12.4, size.height / 10.9);
  }

  void _drawMapBackdrop(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final rect = Offset.zero & size;
    final wash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.24, -0.28),
        radius: 1.18,
        colors: [
          LightcorePalette.stroke.withValues(alpha: 0.2),
          LightcorePalette.abyss.withValues(alpha: 0.5),
          LightcorePalette.night.withValues(alpha: 0.9),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect);
    canvas.drawRect(rect, wash);

    final starPaint = Paint()..style = PaintingStyle.fill;
    final starCount = (42 + (zoomScale * 14)).round();
    for (var index = 0; index < starCount; index += 1) {
      final x = _hashUnit(index, 11) * size.width;
      final y = _hashUnit(index, 29) * size.height;
      final alpha = 0.08 + (_hashUnit(index, 47) * 0.22);
      final starRadius = 0.45 + (_hashUnit(index, 71) * 1.05);
      starPaint.color = Color.lerp(
        LightcorePalette.mist,
        LightcorePalette.aether,
        _hashUnit(index, 101),
      )!.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), starRadius, starPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = LightcorePalette.stroke.withValues(alpha: 0.14);
    for (var ring = 1; ring <= 3; ring += 1) {
      canvas.drawCircle(center, radius * (ring * 1.78 + 0.8), ringPaint);
    }
  }

  void _drawSpiralPath(Canvas canvas, Offset center, double radius) {
    if (regions.length < 2) {
      return;
    }
    final points = [
      for (final region in regions)
        _axialToPixel(region.q, region.r, radius, center),
    ];
    final basePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      basePath.lineTo(point.dx, point.dy);
    }
    final width = radius * 0.18;
    canvas.drawPath(
      basePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.stroke.withValues(alpha: 0.3),
    );

    var lastRevealedIndex = 0;
    for (var index = 0; index < regions.length; index += 1) {
      if (states[regions[index].id]?.revealed ?? false) {
        lastRevealedIndex = index;
      }
    }
    if (lastRevealedIndex <= 0) {
      return;
    }
    final revealedPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index <= lastRevealedIndex; index += 1) {
      revealedPath.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(
      revealedPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.68
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = LightcorePalette.solar.withValues(alpha: 0.72),
    );
  }

  void _drawSectorFill(
    Canvas canvas, {
    required Path path,
    required Offset center,
    required double radius,
    required Color tint,
    required bool revealed,
    required bool full,
    required bool previewed,
  }) {
    final bounds = path.getBounds().inflate(radius * 0.14);
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.36, -0.42),
        radius: 1.18,
        colors: revealed
            ? [
                tint.withValues(alpha: full ? 0.5 : 0.36),
                LightcorePalette.panel.withValues(alpha: 0.52),
                LightcorePalette.abyss.withValues(alpha: 0.88),
              ]
            : [
                tint.withValues(alpha: previewed ? 0.16 : 0.08),
                LightcorePalette.panel.withValues(alpha: 0.28),
                LightcorePalette.night.withValues(alpha: 0.86),
              ],
        stops: const [0, 0.48, 1],
      ).createShader(bounds);
    canvas.drawPath(path, fillPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = revealed ? 1.35 : 1.0
      ..strokeJoin = StrokeJoin.round
      ..color = revealed
          ? tint.withValues(alpha: full ? 0.72 : 0.52)
          : LightcorePalette.mist.withValues(alpha: previewed ? 0.28 : 0.14);
    canvas.drawPath(path, rimPaint);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..strokeJoin = StrokeJoin.round
      ..color = LightcorePalette.mist.withValues(alpha: revealed ? 0.18 : 0.08);
    canvas.drawPath(_hexPath(center, radius * 0.72), innerPaint);
  }

  void _drawSectorTexture(
    Canvas canvas, {
    required Path path,
    required Offset center,
    required double radius,
    required ThreatRegionConfig region,
    required Color tint,
    required bool revealed,
  }) {
    canvas.save();
    canvas.clipPath(path);
    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: revealed ? 0.18 : 0.08);
    final laneCount = zoomScale > 1.7 ? 4 : 2;
    for (var lane = -laneCount; lane <= laneCount; lane += 1) {
      final offset = lane * radius * 0.25;
      canvas.drawLine(
        center + Offset(-radius * 0.88, offset - radius * 0.58),
        center + Offset(radius * 0.88, offset + radius * 0.58),
        lanePaint,
      );
    }

    final dustPaint = Paint()..style = PaintingStyle.fill;
    final dustCount = zoomScale > 2.1 ? 11 : 5;
    final seed = (region.q * 31) + (region.r * 47) + (region.ring * 83);
    for (var index = 0; index < dustCount; index += 1) {
      final angle = _hashUnit(seed + index, 17) * math.pi * 2;
      final distance = radius * (0.18 + (_hashUnit(seed + index, 43) * 0.56));
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      dustPaint.color = Color.lerp(
        tint,
        LightcorePalette.layer2,
        0.42,
      )!.withValues(alpha: revealed ? 0.28 : 0.1);
      canvas.drawCircle(
        point,
        0.55 + (_hashUnit(seed + index, 67) * 0.75),
        dustPaint,
      );
    }
    canvas.restore();
  }

  void _drawAnomalyMarkers(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required ThreatRegionConfig region,
    required bool revealed,
  }) {
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = LightcorePalette.mist.withValues(alpha: revealed ? 0.16 : 0.08);
    canvas.drawCircle(center, radius * 0.32, orbitPaint);

    for (var index = 0; index < region.anomalyCardIds.length; index += 1) {
      final config = _enemyConfigById(region.anomalyCardIds[index]);
      final color = config?.affinity.color ?? _rarityTint(region.rarity);
      final angle = (-math.pi / 2) + (index * math.pi * 2 / 3);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.32;
      final markerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = revealed
            ? color.withValues(alpha: 0.9)
            : color.withValues(alpha: 0.22);
      canvas.drawCircle(
        point,
        radius * (revealed ? 0.075 : 0.052),
        markerPaint,
      );
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = color.withValues(alpha: revealed ? 0.48 : 0.14);
      canvas.drawCircle(point, radius * 0.11, glowPaint);
    }

    if (region.hasDoubleBoss) {
      final bossPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = LightcorePalette.warning.withValues(
          alpha: revealed ? 0.88 : 0.24,
        );
      canvas.drawCircle(center, radius * 0.13, bossPaint);
      canvas.drawCircle(
        center + Offset(radius * 0.16, -radius * 0.04),
        radius * 0.09,
        bossPaint,
      );
    }
  }

  void _drawSectorLabels(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required ThreatRegionConfig region,
    required ThreatRegionState? state,
    required bool revealed,
  }) {
    if (zoomScale < 1.45) {
      return;
    }
    final tint = _rarityTint(region.rarity);
    final spiralIndex = regions.indexWhere((item) => item.id == region.id);
    final title = spiralIndex < 0
        ? 'S--'
        : 'S${(spiralIndex + 1).toString().padLeft(2, '0')}';
    _drawCenteredText(
      canvas,
      title,
      center + Offset(0, -radius * 0.54),
      fontSize: radius * 0.18,
      color: revealed
          ? LightcorePalette.mist.withValues(alpha: 0.78)
          : LightcorePalette.mist.withValues(alpha: 0.32),
      weight: FontWeight.w700,
    );
    if (zoomScale < 2.05) {
      return;
    }
    final progress = revealed && state != null
        ? 'Lv ${state.stabilizedLevel}/${region.stabilizationLayers}'
        : 'UNCHARTED';
    _drawCenteredText(
      canvas,
      progress,
      center + Offset(0, radius * 0.5),
      fontSize: radius * 0.16,
      color: revealed
          ? tint.withValues(alpha: 0.92)
          : LightcorePalette.warning.withValues(alpha: 0.58),
      weight: FontWeight.w700,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight weight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  double _hashUnit(int seed, int salt) {
    final raw = math.sin((seed * 12.9898) + (salt * 78.233)) * 43758.5453;
    return raw - raw.floorToDouble();
  }

  Offset _axialToPixel(int q, int r, double radius, Offset center) {
    final x = radius * math.sqrt(3) * (q + (r / 2));
    final y = radius * 1.5 * r;
    return center + Offset(x, y);
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (math.pi / 180) * (60 * index - 30);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _ThreatRegionMapPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.states != states ||
        oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.previewRegionId != previewRegionId ||
        oldDelegate.zoomScale != zoomScale;
  }
}

EnemyConfig? _enemyConfigById(String id) {
  if (EnemyLibrary.starterDefault.id == id) {
    return EnemyLibrary.starterDefault;
  }
  for (final config in EnemyLibrary.all) {
    if (config.id == id) {
      return config;
    }
  }
  return null;
}

EnemyConfig? _bossConfigById(String? id) {
  if (id == null) {
    return null;
  }
  for (final config in BossEnemyLibrary.all) {
    if (config.id == id) {
      return config;
    }
  }
  return null;
}

String _threatRegionSignatureLine(ThreatRegionConfig region) {
  final anomalies = region.anomalyCardIds
      .map(_enemyConfigById)
      .whereType<EnemyConfig>()
      .map((config) => config.name)
      .toList(growable: false);
  final boss = _bossConfigById(region.primaryBossId);
  final secondaryBoss = _bossConfigById(region.secondaryBossId);
  final bossNames = [
    if (boss != null) boss.name,
    if (secondaryBoss != null) secondaryBoss.name,
  ];
  final anomalyLabel = anomalies.isEmpty
      ? 'unresolved anomaly signatures'
      : anomalies.join(' • ');
  final bossLabel = bossNames.isEmpty
      ? 'unresolved apex signature'
      : bossNames.join(' • ');
  return 'Anomalies: $anomalyLabel\nApex: $bossLabel';
}

String _threatRegionLore(ThreatRegionConfig region) {
  final boss = _bossConfigById(region.primaryBossId);
  final secondaryBoss = _bossConfigById(region.secondaryBossId);
  final anomalies = region.anomalyCardIds
      .map(_enemyConfigById)
      .whereType<EnemyConfig>()
      .toList(growable: false);
  final leadAffinity =
      boss?.affinity ??
      (anomalies.isEmpty
          ? PrototypeAffinity.neutral
          : anomalies.first.affinity);
  final myth = _sectorMythFor(leadAffinity, boss?.name ?? 'the apex signature');
  final traits = anomalies
      .map((config) => config.traitLabel.toLowerCase())
      .toSet()
      .take(3)
      .join(', ');
  final anomalyClause = traits.isEmpty
      ? 'soft static and incomplete wake traces'
      : traits;
  final bossClause = secondaryBoss == null
      ? 'The deepest return points to ${boss?.name ?? 'an unnamed apex anomaly'}.'
      : 'Two apex returns overlap: ${boss?.name ?? 'an unnamed apex anomaly'} and ${secondaryBoss.name}.';
  return '$myth Sensor drift shows $anomalyClause. $bossClause';
}

String _sectorMythFor(PrototypeAffinity affinity, String bossName) {
  return switch (affinity) {
    PrototypeAffinity.black =>
      'This region has been avoided because of the myth of a leviathan-sized black hole; no one has seen the shadow behind $bossName and returned with their clocks intact.',
    PrototypeAffinity.ember =>
      'Crews route around this sector because old hulls still glow red on approach, as if $bossName keeps a furnace awake between the lanes.',
    PrototypeAffinity.flare =>
      'Pilots call this a slingshot sector: ships enter fast, exit faster, and leave orange afterimages that point back toward $bossName.',
    PrototypeAffinity.solar =>
      'Navigation charts stutter here, repeating the same yellow coordinates until scouts swear $bossName is blinking through the beacon grid.',
    PrototypeAffinity.verdant =>
      'Derelict stations in this sector bloom with green light after power failure, a sign that $bossName is feeding on abandoned routes.',
    PrototypeAffinity.aether =>
      'Every rescue ping in this sector comes back blue and doubled, like $bossName is turning distress calls into bait.',
    PrototypeAffinity.violet =>
      'Expeditions report violet echoes from trips they never took, and each duplicate log places $bossName one hex closer.',
    PrototypeAffinity.neutral =>
      'This sector looks quiet on first scan, which is why crews distrust it; the clean readings keep bending back toward $bossName.',
  };
}

class EnemyPullSheet extends StatefulWidget {
  const EnemyPullSheet({super.key, required this.controller});

  final LightcoreController controller;

  @override
  State<EnemyPullSheet> createState() => _EnemyPullSheetState();
}

class _EnemyPullSheetState extends State<EnemyPullSheet> {
  static const int _rewardedTicketGrant = 5;

  bool _revealBusy = false;
  bool _rewardAdBusy = false;
  _ThreatPullTab _tab = _ThreatPullTab.enemies;

  LightcoreController get controller => widget.controller;
  bool get _scanBusy => _revealBusy;

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
                    ? 'Regional Bosses'
                    : 'Knowledge Cards';
                final closeTooltip = _tab == _ThreatPullTab.bosses
                    ? 'Close regional bosses'
                    : 'Close knowledge cards';
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
                    const SizedBox(height: 10),
                    _ScanSpendExplanation(
                      selected: _tab,
                      tint: _tab == _ThreatPullTab.bosses
                          ? bossTint
                          : enemyTint,
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
                            ? 'Boss intel tier maxed'
                            : '${controller.pullsToNextBossSummoningLevel} to boss intel tier ${controller.nextBossSummoningLevel}',
                        trailing: IconButton.filledTonal(
                          onPressed: () => _showBossPullRates(context),
                          tooltip: 'Show boss reveal rates',
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
                                    'White Warden is already the starter Apex. Create the Prism Shell to claim ${LightcoreCurrencyLabels.bossScanCount(LightcoreController.bossUnlockTicketGrant)} and start clearing regional Apex bosses.',
                                tint: LightcorePalette.warning,
                              ),
                            ] else if (!controller.fullThreatMapUnlocked) ...[
                              _InlineEnemyNote(
                                message:
                                    'Regional boss pulls unlock after the starter region is fully stabilized and its boss is defeated.',
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
                                                controller
                                                    .fullThreatMapUnlocked &&
                                                !_scanBusy,
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
                                              controller
                                                  .fullThreatMapUnlocked &&
                                              controller.bossTickets >= 10 &&
                                              !controller
                                                  .tutorialHighlightsBossSinglePullButton &&
                                              !_scanBusy,
                                          onPressed: () =>
                                              _openBossBatchTickets(context),
                                        ),
                                      ),
                                      action(
                                        _TicketButton(
                                          label: 'MAX',
                                          enabled:
                                              controller.bossHuntsUnlocked &&
                                              controller
                                                  .fullThreatMapUnlocked &&
                                              controller.bossTickets > 1 &&
                                              !controller
                                                  .tutorialHighlightsBossSinglePullButton &&
                                              !_scanBusy,
                                          onPressed: () =>
                                              _openBossMaxTickets(context),
                                        ),
                                      ),
                                      action(
                                        FilledButton.tonal(
                                          onPressed:
                                              LightcoreRewardedAds
                                                      .isSupportedPlatform &&
                                                  !_scanBusy &&
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
                                'Basic Apex Anomalies start single-color. Higher-ring regions introduce hybrid color frames, warded affinities, live abilities, and double-boss pressure.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (bossUnlocked) const SizedBox(height: 12),
                            if (bossUnlocked) ...[
                              Text(
                                'Regional boss pool',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              if (bossScanPreviewCards.isEmpty)
                                _InlineEnemyNote(
                                  message:
                                      'No regional boss signatures are available in the current scan tier.',
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
                    ] else ...[
                      _ThreatScanSection(
                        title: 'Knowledge Cards',
                        tint: enemyTint,
                        icon: LightcoreIcons.threatScan,
                        progress: controller.summoningLevelProgress,
                        railTopLabel: 'LV ${controller.summoningLevel}',
                        railBottomLabel: controller.isSummoningLevelMaxed
                            ? 'MAX'
                            : '${controller.pullsToNextSummoningLevel}',
                        statusLabel: controller.isSummoningLevelMaxed
                            ? 'Research level maxed'
                            : '${controller.pullsToNextSummoningLevel} to Research Lv ${controller.nextSummoningLevel}',
                        trailing: IconButton.filledTonal(
                          onPressed: () => _showPullRates(context),
                          tooltip: 'Show knowledge rates',
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
                            AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) =>
                                  _EnemyResearchDeckPreview(
                                    controller: controller,
                                  ),
                            ),
                            if (!controller.fullThreatMapUnlocked) ...[
                              const SizedBox(height: 12),
                              _InlineEnemyNote(
                                message:
                                    'Threat Scans resolve Knowledge Cards. Set cards in the Knowledge Book to gain bonuses against matching enemy signatures.',
                                tint: LightcorePalette.warning,
                              ),
                            ],
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
                                              !_scanBusy,
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
                                            !_scanBusy,
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
                                            !_scanBusy,
                                        onPressed: () =>
                                            _openMaxTickets(context),
                                      ),
                                    ),
                                    action(
                                      FilledButton.tonal(
                                        onPressed:
                                            LightcoreRewardedAds
                                                    .isSupportedPlatform &&
                                                !_scanBusy &&
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
    if (_scanBusy || controller.enemyTickets < count) {
      return;
    }
    setState(() => _revealBusy = true);
    try {
      final pulls = controller.tutorialHighlightsEnemySinglePullButton
          ? controller.tutorialOpenEnemyTickets(count)
          : controller.openEnemyTickets(count);
      if (pulls.isEmpty || !context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _EnemyPackRevealDialog(
          pulls: pulls,
          highestAvailableRarity: controller.highestAvailableEnemyPullRarity,
          secondHighestAvailableRarity:
              controller.secondHighestAvailableEnemyPullRarity,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _revealBusy = false);
      }
    }
  }

  Future<void> _openBatchTickets(BuildContext context) async {
    if (_scanBusy || controller.enemyTickets < 10) {
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
    if (_scanBusy || controller.enemyTickets <= 0) {
      return;
    }
    await _openTickets(context, controller.enemyTickets);
  }

  Future<void> _openBossTickets(BuildContext context, int count) async {
    if (_scanBusy || controller.bossTickets < count) {
      return;
    }
    setState(() => _revealBusy = true);
    try {
      final pulls = controller.tutorialHighlightsBossSinglePullButton
          ? controller.tutorialOpenBossTickets(count)
          : controller.openBossTickets(count);
      if (pulls.isEmpty || !context.mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _EnemyPackRevealDialog(
          pulls: pulls,
          highestAvailableRarity: controller.highestAvailableBossPullRarity,
          secondHighestAvailableRarity:
              controller.secondHighestAvailableBossPullRarity,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _revealBusy = false);
      }
    }
  }

  Future<void> _openBossBatchTickets(BuildContext context) async {
    if (_scanBusy || controller.bossTickets < 10) {
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
    if (_scanBusy || controller.bossTickets <= 0) {
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
        sourceLabel: 'Reward ad • Threat Scan resupply',
      );
    } finally {
      if (mounted) {
        setState(() {
          _rewardAdBusy = false;
        });
      }
    }
  }

  void _showPullRates(BuildContext context) {
    final rates = controller.summonRates;
    final maxed = controller.isSummoningLevelMaxed;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: LightcorePalette.panel,
          title: const Text('Knowledge Rates'),
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
                      : '${controller.summoningLevelPullsIntoCurrent}/${controller.currentSummoningLevelPullGap} scans in this level. ${controller.pullsToNextSummoningLevel} more scans unlock Scan Lv ${controller.nextSummoningLevel} and ${LightcoreCurrencyLabels.rewardThreatScans(controller.nextSummoningLevelTicketReward)}.',
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
                const SizedBox(height: 8),
                Text(
                  controller.threatScanRateInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.72),
                  ),
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
          title: const Text('Boss Reveal Rates'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Boss intel tier ${controller.bossSummoningLevel}'),
                Text('Total boss reveals ${controller.bossPullCount}'),
                const SizedBox(height: 12),
                MeterBar(
                  value: controller.bossSummoningLevelProgress,
                  color: LightcorePalette.warning,
                  height: 12,
                ),
                const SizedBox(height: 8),
                Text(
                  maxed
                      ? 'Boss intel tier maxed. Every Apex Anomaly rarity tier is live.'
                      : '${controller.bossSummoningLevelPullsIntoCurrent}/${LightcoreController.bossPullsPerSummoningLevel} clears in this tier. ${controller.pullsToNextBossSummoningLevel} more clears unlock boss intel tier ${controller.nextBossSummoningLevel} and ${LightcoreCurrencyLabels.rewardBossScans(controller.nextBossSummoningLevelTicketReward)}.',
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
                  'Boss intel tier increases every ${LightcoreController.bossPullsPerSummoningLevel} resolved boss clears and caps at tier ${LightcoreController.maxBossSummoningLevel}.',
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
