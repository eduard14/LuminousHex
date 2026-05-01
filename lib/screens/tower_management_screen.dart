import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_config.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/lightcore_info_button.dart';
import '../widgets/meter_bar.dart';
import '../widgets/symbol_grid_tile.dart';
import '../widgets/tower_level_hex_badge.dart';
import '../widgets/tower_ring_icon.dart';
import 'tower_detail_screen.dart';

const String _completedShellHelp =
    'Layer 2 optimization works from finished Layer 1 sets: one core plus six edge towers. Save strong completed sets, sort them by combat role, then swap older Layer 2 sets when a better core, projectile mix, payload mix, or stat roll is ready.\n\nLayer 2 level tuning spends Shell Cores from daily dungeon clears. Higher dungeon levels award more Shell Cores, and cleared levels can be quick-cleared three times per day.';

const String _towerArchiveLockedHelp =
    'The Towers page becomes a completed-shell archive once Layer 2 is online. Finish the first Root Shell and create the Prism Shell to unlock save and replace tools.';

class TowerManagementScreen extends StatefulWidget {
  const TowerManagementScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.scrollController,
  });

  final LightcoreController controller;
  final bool isActive;
  final ScrollController? scrollController;

  @override
  State<TowerManagementScreen> createState() => _TowerManagementScreenState();
}

class _TowerManagementScreenState extends State<TowerManagementScreen> {
  _TowerSortMode _sortMode = _TowerSortMode.slot;

  LightcoreController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final completedShells = _sortedCompletedShells(controller);
        final nextLayerOneCoreSlotIndex = controller.nextLayerOneCoreSlotIndex;

        return CustomScrollView(
          key: const PageStorageKey<String>('tower-management-scroll'),
          controller: widget.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: AuroraPanel(
                tint: controller.completedShellLibraryUnlocked
                    ? LightcorePalette.layer2
                    : LightcorePalette.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.completedShellLibraryUnlocked
                                ? 'Completed Layer 1 Sets'
                                : 'Tower Archive Locked',
                            style: textTheme.titleLarge,
                          ),
                        ),
                        LightcoreInfoButton(
                          title: controller.completedShellLibraryUnlocked
                              ? 'Tower Archive Help'
                              : 'Tower Archive Locked',
                          message: controller.completedShellLibraryUnlocked
                              ? _completedShellHelp
                              : _towerArchiveLockedHelp,
                          tint: controller.completedShellLibraryUnlocked
                              ? LightcorePalette.layer2
                              : LightcorePalette.violet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MeterBar(
                      value: controller.completedShellLibraryUnlocked
                          ? 1
                          : controller.promotionProgress,
                      color: controller.completedShellLibraryUnlocked
                          ? LightcorePalette.layer2
                          : LightcorePalette.violet,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.completedShellLibraryUnlocked
                          ? '${completedShells.length} completed Layer 1 sets • ${controller.shellCoreLabel}'
                          : 'Layer 2 locked • ${controller.promotionStatusLabel}',
                      style: textTheme.bodyLarge,
                    ),
                    if (controller.showsLayerOneCoreCreation) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                controller.canCreateLayerOneCore &&
                                    nextLayerOneCoreSlotIndex != null
                                ? () => _showChildCoreAffinityPicker(
                                    context,
                                    controller,
                                    nextLayerOneCoreSlotIndex,
                                  )
                                : null,
                            icon: const TowerRingIcon(size: 18),
                            label: const Text('New Layer 1 Set'),
                          ),
                          Text(
                            controller.layerOneCoreBuildStatusLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              color: LightcorePalette.solar,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (controller.completedShellLibraryUnlocked) ...[
                      const SizedBox(height: 14),
                      _SortSelector(
                        value: _sortMode,
                        onChanged: (mode) {
                          setState(() => _sortMode = mode);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (controller.activeLayerHasParentSlot)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ChildTowerGrowthPanel(controller: controller),
                ),
              ),
            if (controller.completedShellLibraryUnlocked &&
                completedShells.isEmpty)
              SliverToBoxAdapter(
                child: AuroraPanel(
                  tint: LightcorePalette.stroke,
                  child: Text(
                    'No completed Layer 1 sets are ready to archive yet.',
                    style: textTheme.bodyMedium,
                  ),
                ),
              )
            else if (controller.completedShellLibraryUnlocked)
              SliverList.builder(
                itemCount: completedShells.length,
                itemBuilder: (context, index) {
                  final shell = completedShells[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CompletedShellCard(
                      controller: controller,
                      shell: shell,
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        );
      },
    );
  }

  List<CompletedTowerShellState> _sortedCompletedShells(
    LightcoreController controller,
  ) {
    final shells = controller.completedTowerShellLibrary.toList(
      growable: false,
    );
    if (_sortMode == _TowerSortMode.slot) {
      return shells;
    }

    int archivedWeight(CompletedTowerShellState shell) =>
        shell.archived ? 1 : 0;

    int compareNum(num left, num right) => right.compareTo(left);

    shells.sort((a, b) {
      final archiveCompare = archivedWeight(a).compareTo(archivedWeight(b));
      if (archiveCompare != 0) {
        return archiveCompare;
      }

      final modeCompare = switch (_sortMode) {
        _TowerSortMode.slot => (a.sourceSlotIndex ?? -1).compareTo(
          b.sourceSlotIndex ?? -1,
        ),
        _TowerSortMode.level => compareNum(
          a.layer.core.level,
          b.layer.core.level,
        ),
        _TowerSortMode.power => compareNum(
          _completedShellTotalPower(controller, a),
          _completedShellTotalPower(controller, b),
        ),
        _TowerSortMode.affinity => a.layer.core.affinity.index.compareTo(
          b.layer.core.affinity.index,
        ),
        _TowerSortMode.projectile =>
          a.layer.core.projectileType.label.compareTo(
            b.layer.core.projectileType.label,
          ),
        _TowerSortMode.payload => a.layer.core.payloadType.label.compareTo(
          b.layer.core.payloadType.label,
        ),
      };

      if (modeCompare != 0) {
        return modeCompare;
      }
      final layerCompare = a.sourceLayerLabel.compareTo(b.sourceLayerLabel);
      if (layerCompare != 0) {
        return layerCompare;
      }
      return (a.sourceSlotIndex ?? -1).compareTo(b.sourceSlotIndex ?? -1);
    });
    return shells;
  }
}

List<OuterTowerState> _completedShellEdgeTowers(
  CompletedTowerShellState shell,
) {
  return shell.layer.slots
      .where((tower) => tower.config != null && !tower.isFabricating)
      .toList(growable: false);
}

double _completedShellTotalPower(
  LightcoreController controller,
  CompletedTowerShellState shell,
) {
  return _completedShellEdgeTowers(
    shell,
  ).fold(0.0, (sum, tower) => sum + controller.towerPower(tower));
}

String _completedShellProjectileSummary(CompletedTowerShellState shell) {
  final labels = <String>{
    shell.layer.core.projectileType.label,
    for (final tower in _completedShellEdgeTowers(shell))
      tower.projectileType?.label ?? tower.config!.defaultProjectileType.label,
  }.toList(growable: false);
  return labels.length <= 3
      ? labels.join(' / ')
      : '${labels.take(3).join(' / ')} +${labels.length - 3}';
}

String _completedShellPayloadSummary(CompletedTowerShellState shell) {
  final labels = <String>{
    shell.layer.core.payloadType.label,
    for (final tower in _completedShellEdgeTowers(shell))
      tower.payloadType?.label ?? tower.config!.defaultPayloadType.label,
  }.toList(growable: false);
  return labels.length <= 3
      ? labels.join(' / ')
      : '${labels.take(3).join(' / ')} +${labels.length - 3}';
}

void _showChildCoreAffinityPicker(
  BuildContext context,
  LightcoreController controller,
  int slotIndex,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      final blockedLabel = controller.childLayerCreationBlockedLabelForSlot(
        slotIndex,
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AuroraPanel(
            tint: LightcorePalette.aether,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core Color', style: textTheme.titleLarge),
                if (blockedLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(blockedLabel, style: textTheme.bodyMedium),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final affinity
                        in LightcoreController.childCoreAffinityChoices)
                      FilledButton.icon(
                        onPressed: blockedLabel == null
                            ? () {
                                Navigator.of(sheetContext).pop();
                                controller.createChildLayer(
                                  slotIndex,
                                  affinity,
                                );
                              }
                            : null,
                        icon: Icon(
                          affinityIconFor(affinity),
                          color: affinity.color,
                        ),
                        label: Text(controller.childCoreChoiceLabel(affinity)),
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
}

void _showShellReplacePicker(
  BuildContext context,
  LightcoreController controller,
  CompletedTowerShellState archive,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      final targets = controller.liveCompletedTowerShells
          .where((shell) => shell.sourceSlotIndex != null)
          .toList(growable: false);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AuroraPanel(
            tint: archive.layer.core.affinity.color,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Swap Layer 1 Set', style: textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Choose a live completed Layer 1 set to replace with ${archive.sourceLabel}.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                if (targets.isEmpty)
                  Text(
                    'No live completed Layer 1 sets are available.',
                    style: textTheme.bodyMedium,
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: targets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final target = targets[index];
                        final tint = target.layer.core.affinity.color;
                        return OutlinedButton.icon(
                          onPressed: () {
                            controller.replaceCompletedShell(
                              archiveId: archive.id,
                              targetId: target.id,
                            );
                            Navigator.of(sheetContext).pop();
                          },
                          icon: Icon(Icons.swap_horiz_rounded, color: tint),
                          label: Text(
                            '${target.sourceLabel} • Core ${target.layer.core.projectileType.label} / ${target.layer.core.payloadType.label} • ${_completedShellEdgeTowers(target).length + 1}/7 towers',
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
}

class _CompletedShellCard extends StatelessWidget {
  const _CompletedShellCard({required this.controller, required this.shell});

  final LightcoreController controller;
  final CompletedTowerShellState shell;

  @override
  Widget build(BuildContext context) {
    final edgeTowers = _completedShellEdgeTowers(shell);
    final textTheme = Theme.of(context).textTheme;
    final tint = shell.layer.core.affinity.color;
    final totalPower = _completedShellTotalPower(controller, shell);
    final towerCount = edgeTowers.length + 1;

    return AuroraPanel(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shell.archived ? 'Saved Shell' : shell.sourceLabel,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shell.layer.core.affinity.label} Layer 1 Set',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Core ${shell.layer.core.projectileType.label} / ${shell.layer.core.payloadType.label} • ${edgeTowers.length} edge towers • ${shell.sourceLayerLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TowerRingIcon(size: 18, color: tint),
                    const SizedBox(width: 8),
                    Text(
                      '$towerCount/7',
                      style: textTheme.titleMedium?.copyWith(color: tint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Total Power',
                value: totalPower.toStringAsFixed(1),
              ),
              _MetricTile(
                label: 'Core Level',
                value: '${shell.layer.core.level}',
              ),
              _MetricTile(
                label: 'Projectiles',
                value: _completedShellProjectileSummary(shell),
              ),
              _MetricTile(
                label: 'Payloads',
                value: _completedShellPayloadSummary(shell),
              ),
              _MetricTile(
                label: 'Range Avg',
                value: edgeTowers.isEmpty
                    ? '0'
                    : (edgeTowers.fold<double>(
                                0,
                                (sum, tower) =>
                                    sum + controller.towerEffectiveRange(tower),
                              ) /
                              edgeTowers.length)
                          .toStringAsFixed(0),
              ),
              _MetricTile(
                label: 'Gen Avg',
                value: edgeTowers.isEmpty
                    ? '0'
                    : (edgeTowers.fold<double>(
                                0,
                                (sum, tower) =>
                                    sum +
                                    controller.towerGenerationSpeed(tower),
                              ) /
                              edgeTowers.length)
                          .toStringAsFixed(2),
              ),
              _MetricTile(
                label: 'Core Fire',
                value: '${shell.layer.core.fireSpeedUpgradeLevel}',
              ),
              _MetricTile(
                label: 'Archive',
                value: shell.archived ? 'Saved' : 'Live',
              ),
            ],
          ),
          if (edgeTowers.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tower in edgeTowers)
                  _ShellTraitChip(
                    label:
                        'Hex ${tower.slotIndex + 1} • ${controller.towerProjectileLabel(tower)}',
                    detail:
                        '${controller.towerDisplayName(tower)} • ${controller.towerPayloadLabel(tower)} • Power ${controller.towerPower(tower).toStringAsFixed(1)}',
                    tint: tower.config?.affinity.color ?? tint,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: shell.archived
                      ? controller.liveCompletedTowerShells
                                .where(
                                  (target) => target.sourceSlotIndex != null,
                                )
                                .isEmpty
                            ? null
                            : () => _showShellReplacePicker(
                                context,
                                controller,
                                shell,
                              )
                      : () => controller.saveCompletedShell(shell.id),
                  icon: Icon(
                    shell.archived
                        ? Icons.swap_horiz_rounded
                        : Icons.save_rounded,
                  ),
                  label: Text(
                    shell.archived ? 'Swap Into Layer 2' : 'Save Set',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (!shell.archived)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      controller.enterLayerById(shell.sourceLayerId);
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Source'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShellTraitChip extends StatelessWidget {
  const _ShellTraitChip({
    required this.label,
    required this.detail,
    required this.tint,
  });

  final String label;
  final String detail;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: detail,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChildTowerGrowthPanel extends StatelessWidget {
  const _ChildTowerGrowthPanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final projection = controller.activeChildTowerProjection;
    if (projection == null) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final tint = projection.childAffinity?.color ?? LightcorePalette.solar;

    return AuroraPanel(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Child Tower Growth', style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '${controller.activeChildTowerAnchorLabel}  •  ${projection.isPromotedChildTower ? 'active in parent shell' : 'previewing until alignment'}',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Each child-tower level now takes four rolled tuning stats from the full offensive pool. Max a stat to 10/10, complete the whole board, and the shell levels up with a fresh reroll while the level boost stays.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Level',
                value: '${projection.childCoreLevel ?? 1}',
              ),
              _MetricTile(
                label: 'Projectile',
                value: controller.towerProjectileLabel(projection),
              ),
              _MetricTile(
                label: 'Payload',
                value: controller.towerPayloadLabel(projection),
              ),
              _MetricTile(
                label: 'Power',
                value: controller.towerPower(projection).toStringAsFixed(1),
              ),
              _MetricTile(
                label: 'Range',
                value: controller.towerRangeLabel(projection),
              ),
              _MetricTile(
                label: 'Gen',
                value: controller.towerGenerationLabel(projection),
              ),
              _MetricTile(
                label: 'Crit',
                value: controller.towerCritLabel(projection),
              ),
              _MetricTile(
                label: 'Apex',
                value: controller.towerBossDamageLabel(projection),
              ),
              _MetricTile(
                label: 'Def Pen',
                value: controller.towerDefensePenetrationLabel(projection),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MeterBar(
            value: controller.activeChildTowerLevelProgress,
            color: tint,
          ),
          const SizedBox(height: 8),
          Text(
            controller.activeChildTowerLevelProgressLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Available tuning currency: ${controller.shellCoreLabel}',
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.solar,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final upgrade in controller.activeChildTowerUpgrades)
                _ChildTowerUpgradeCard(
                  controller: controller,
                  upgrade: upgrade,
                  tint: tint,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _BuiltSlotCard extends StatelessWidget {
  const _BuiltSlotCard({required this.controller, required this.slot});

  final LightcoreController controller;
  final OuterTowerState slot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final manager = controller.cardForSlot(slot);
    final tint =
        slot.config?.affinity.color ??
        slot.childAffinity?.color ??
        LightcorePalette.layer2;
    final isProject = controller.isSlotLayerProject(slot);
    final isPromoted = slot.isPromotedChildTower;
    final isFabricating = slot.isFabricating;
    final showTowerLevelBadge = slot.config != null && !isFabricating;
    final progressValue = isFabricating
        ? slot.fabricationProgress
        : isProject
        ? (slot.childBuiltCount / LightcoreController.slotCount)
              .clamp(0.0, 1.0)
              .toDouble()
        : slot.charge.clamp(0.0, 1.0).toDouble();
    final pipCurrent = isFabricating
        ? 0
        : isProject
        ? slot.childBuiltCount
        : slot.isChildLayerNode
        ? (slot.childCoreLevel ?? 1)
        : slot.level;
    final pipMax = isProject
        ? LightcoreController.slotCount
        : LightcoreController.maxTowerLevel;

    return AuroraPanel(
      tint: tint,
      onTap: () => slot.isChildLayerNode
          ? controller.enterChildLayer(slot.slotIndex)
          : controller.selectSlot(slot.slotIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hex ${slot.slotIndex + 1}',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.towerDisplayName(slot),
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.isChildLayerNode
                          ? isPromoted
                                ? 'Aligned lower shell. Tap this child tower to generate its packet; the source shell is archived as passive support.'
                                : 'Lower-shell project. Tap to enter this shell, rebuild from Root, and align it into an active child tower.'
                          : isFabricating
                          ? 'Fabricating Source Tower. Its rolled projectile, payload, and trainable stats are locked, but combat systems come online when the timer completes.'
                          : slot.config!.summary,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.isChildLayerNode
                          ? isPromoted
                                ? 'Aligned ${controller.towerAffinitySignatureLabel(slot)}  •  ${controller.towerProjectileLabel(slot)} / ${controller.towerPayloadLabel(slot)}  •  Target ${controller.towerTargetLabel(slot)}  •  ${controller.childTowerGrowthLabel(slot)}'
                                : 'Child shell progress ${controller.childShellProgressLabel(slot)}  •  ${controller.childTowerGrowthLabel(slot)}'
                          : isFabricating
                          ? '${controller.towerFabricationProgressLabel(slot)}  •  ${controller.towerProjectileLabel(slot)} / ${controller.towerPayloadLabel(slot)}'
                          : '${slot.config!.passiveLabel}  •  ${controller.towerProjectileLabel(slot)} / ${controller.towerPayloadLabel(slot)}  •  Target ${controller.towerTargetLabel(slot)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!slot.isChildLayerNode && !isFabricating) ...[
                      const SizedBox(height: 4),
                      Text(
                        controller.towerUpgradeBoardSummary(slot),
                        style: textTheme.bodySmall?.copyWith(
                          color: LightcorePalette.mist,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showTowerLevelBadge)
                TowerLevelHexBadge(
                  level: slot.level,
                  maxLevel: LightcoreController.maxTowerLevel,
                  projectileType: controller.towerProjectileType(slot),
                  payloadType: controller.towerPayloadType(slot),
                  tint: tint,
                  complete: controller.isTowerComplete(slot),
                  semanticLabel:
                      '${controller.towerDisplayName(slot)} ${controller.towerCompletionLabel(slot)}',
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFabricating) ...[
                        _FabricationProgressGlyph(
                          tint: tint,
                          progress: slot.fabricationProgress,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        slot.isChildLayerNode && isProject
                            ? '${slot.childBuiltCount}/${LightcoreController.slotCount}'
                            : isFabricating
                            ? 'FAB ${controller.towerFabricationRemainingLabel(slot)}'
                            : slot.isChildLayerNode
                            ? 'LVL ${slot.childCoreLevel ?? 1}'
                            : 'LVL ${slot.level}',
                        style: textTheme.titleMedium?.copyWith(color: tint),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricTile(
                label: 'Power',
                value: controller.towerPower(slot).toStringAsFixed(1),
              ),
              _MetricTile(
                label: isProject || isFabricating ? 'Build' : 'Charge',
                value: isProject
                    ? '${slot.childBuiltCount}/${LightcoreController.slotCount}'
                    : isFabricating
                    ? 'Growing'
                    : controller.towerLiveChargeRate(slot).toStringAsFixed(2),
              ),
              _MetricTile(
                label: isProject
                    ? 'Ready'
                    : isFabricating
                    ? 'Online'
                    : 'Cooldown',
                value: isProject
                    ? '${controller.childPromotionReadyTowerCount(slot)}/${LightcoreController.slotCount}'
                    : isFabricating
                    ? controller.towerFabricationRemainingLabel(slot)
                    : '${controller.towerLiveCooldown(slot).toStringAsFixed(2)}s',
              ),
              _MetricTile(
                label: 'Projectile',
                value: controller.towerProjectileArsenalLabel(slot),
              ),
              _MetricTile(
                label: 'Payload',
                value: controller.towerPayloadArsenalLabel(slot),
              ),
              if (!isProject)
                _MetricTile(
                  label: 'Range',
                  value: controller.towerRangeLabel(slot),
                ),
              if (!isProject)
                _MetricTile(
                  label: 'Gen',
                  value: controller.towerGenerationLabel(slot),
                ),
              if (!isProject)
                _MetricTile(
                  label: 'Crit',
                  value: controller.towerCritLabel(slot),
                ),
              _MetricTile(
                label: isProject ? 'Target' : 'Load',
                value: isProject
                    ? 'Inner shell'
                    : isFabricating
                    ? 'Fabricating'
                    : '${(controller.towerDisruptionFraction(slot) * 100).round()}%',
              ),
              _MetricTile(
                label: 'Core Manager',
                value: slot.isChildLayerNode
                    ? 'Inner Layer'
                    : controller.managerAssignmentUnlocked
                    ? manager?.name ?? 'Open'
                    : 'Locked',
              ),
              if (!isProject && !isFabricating)
                _MetricTile(
                  label: 'Automation',
                  value: controller.towerAutomationLabel(slot),
                ),
            ],
          ),
          const SizedBox(height: 14),
          MeterBar(value: progressValue, color: tint),
          if (isFabricating) ...[
            const SizedBox(height: 8),
            Text(
              controller.towerFabricationProgressLabel(slot),
              style: textTheme.bodyMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _TowerLevelPips(
              current: pipCurrent,
              max: pipMax,
              tint: tint,
              label: isProject ? 'Shell build' : 'Tower level',
            ),
          ],
          if (!isProject && !isFabricating) ...[
            const SizedBox(height: 12),
            Text(
              'Live Projectile Target',
              style: textTheme.bodyMedium?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final priority in TargetPriority.values)
                  ChoiceChip(
                    label: Text(priority.label),
                    selected: controller.towerTargetPriority(slot) == priority,
                    onSelected: (_) => controller.setTowerTargetPriority(
                      slot.slotIndex,
                      priority,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GuidedFocusFrame(
                  active: controller.tutorialHighlightsUpgradeButton(
                    slot.slotIndex,
                  ),
                  tint: LightcorePalette.quest,
                  child: FilledButton(
                    onPressed: isFabricating
                        ? null
                        : slot.isChildLayerNode
                        ? () => controller.enterChildLayer(slot.slotIndex)
                        : slot.level < LightcoreController.maxTowerLevel
                        ? () => controller.tutorialUpgradeTower(slot.slotIndex)
                        : null,
                    child: Text(
                      isFabricating
                          ? 'Fabricating ${controller.towerFabricationRemainingLabel(slot)}'
                          : slot.isChildLayerNode
                          ? isPromoted
                                ? 'Enter Layer'
                                : controller.isSlotPromotionReady(slot)
                                ? 'Inner Shell Ready'
                                : 'Continue Layer'
                          : slot.level < LightcoreController.maxTowerLevel
                          ? 'Upgrade Level ${controller.upgradeCost(slot)} Lumens'
                          : controller.isTowerComplete(slot)
                          ? 'Complete'
                          : 'Level Max',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: slot.isPromotedChildTower
                      ? controller.canRerollPromotedChildTower(slot)
                            ? () => controller.rerollPromotedChildTower(
                                slot.slotIndex,
                              )
                            : null
                      : () {
                          if (slot.isChildLayerNode) {
                            controller.enterChildLayer(slot.slotIndex);
                            return;
                          }
                          controller.selectSlot(slot.slotIndex);
                          showTowerDetailOverlay(
                            context: context,
                            controller: controller,
                            slotIndex: slot.slotIndex,
                          );
                        },
                  child: Text(
                    slot.isPromotedChildTower
                        ? 'Reroll Child • ${controller.promotedChildTowerRerollLabel(slot)}'
                        : slot.isChildLayerNode
                        ? 'Open Layer'
                        : 'Open Detail',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildTowerUpgradeCard extends StatelessWidget {
  const _ChildTowerUpgradeCard({
    required this.controller,
    required this.upgrade,
    required this.tint,
  });

  final LightcoreController controller;
  final ChildTowerUpgradeState upgrade;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final cost = controller.childTowerUpgradeCost(upgrade);
    final isMaxed =
        upgrade.rank >= LightcoreController.childTowerUpgradeMaxRank;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(upgrade.type.label, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            controller.childTowerUpgradeEffectLabel(upgrade),
            style: textTheme.bodyMedium?.copyWith(color: tint),
          ),
          const SizedBox(height: 10),
          MeterBar(
            value: (upgrade.rank / LightcoreController.childTowerUpgradeMaxRank)
                .clamp(0.0, 1.0),
            color: tint,
            height: 10,
          ),
          const SizedBox(height: 8),
          Text(
            '${upgrade.rank}/${LightcoreController.childTowerUpgradeMaxRank}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isMaxed || controller.shellCores < cost
                  ? null
                  : () => controller.upgradeActiveChildTowerStat(upgrade.type),
              child: Text(
                isMaxed
                    ? 'Maxed'
                    : 'Tune ${controller.childTowerUpgradeCostLabel(upgrade)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard({required this.controller, required this.slotIndex});

  final LightcoreController controller;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final childLayerBlockedLabel = controller.isCompositeLayer
        ? controller.childLayerCreationBlockedLabelForSlot(slotIndex)
        : null;

    return AuroraPanel(
      tint: LightcorePalette.aether,
      onTap: () {
        if (controller.isCompositeLayer) {
          if (childLayerBlockedLabel == null) {
            _showChildCoreAffinityPicker(context, controller, slotIndex);
          } else {
            controller.enterChildLayer(slotIndex);
          }
          return;
        }
        controller.selectSlot(slotIndex);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hex ${slotIndex + 1}', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            controller.isCompositeLayer
                ? 'Vacant Child Shell Slot'
                : 'Vacant Relay Slot',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            controller.isCompositeLayer
                ? 'Create a lower-class shell here. It starts as a new run with shared resources and its own anomaly deck.'
                : 'Choose one of the seven Source Towers to start feeding the center tower. Source Towers lock in one Spectrum Band and one projectile family, and payloads appear once that shell is aligned into a Prism Shell.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          controller.isCompositeLayer
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: childLayerBlockedLabel == null
                          ? () => _showChildCoreAffinityPicker(
                              context,
                              controller,
                              slotIndex,
                            )
                          : null,
                      icon: const TowerRingIcon(),
                      label: Text(
                        'Create Layer ${controller.activeLayer.tier - 1} Shell',
                      ),
                    ),
                    if (childLayerBlockedLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(childLayerBlockedLabel, style: textTheme.bodyMedium),
                    ],
                  ],
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final config in controller.tutorialTowerChoices)
                      _TowerChoiceChip(
                        config: config,
                        buildCost: controller.buildCostForConfig(config),
                        fabricationDuration: controller
                            .towerFabricationDurationLabelForConfig(config),
                        traitBias: controller.traitBiasSummary(config),
                        enabled:
                            controller.lumens >=
                            controller.buildCostForConfig(config),
                        highlighted: controller.tutorialHighlightsBuildButton(
                          config,
                        ),
                        onPressed: () => controller
                            .tutorialStartTowerFabricationAt(slotIndex, config),
                      ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _LockedSlotCard extends StatelessWidget {
  const _LockedSlotCard({required this.controller, required this.slotIndex});

  final LightcoreController controller;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final requirement = LightcoreController.unlockExperienceForOuterSlot(
      slotIndex,
    );
    final remaining = controller.experienceRemainingForOuterSlot(slotIndex);

    return AuroraPanel(
      tint: LightcorePalette.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hex ${slotIndex + 1}', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            controller.isCompositeLayer
                ? 'Locked Child Shell Slot'
                : 'Locked Relay Slot',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            controller.isCompositeLayer
                ? 'This edge stays sealed until you reach $requirement total EXP. Push the viewed shell harder or raise the swarm cap to open another child-shell lane.'
                : 'This prism lane unlocks at $requirement total EXP. Let the core farm early pressure, then push a higher anomaly cap to open later hexes faster.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          MeterBar(
            value: controller.slotUnlockProgressForIndex(slotIndex),
            color: LightcorePalette.violet,
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining EXP remaining',
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.violet,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortSelector extends StatelessWidget {
  const _SortSelector({required this.value, required this.onChanged});

  final _TowerSortMode value;
  final ValueChanged<_TowerSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_TowerSortMode>(
          value: value,
          dropdownColor: LightcorePalette.panel,
          isExpanded: true,
          items: [
            for (final mode in _TowerSortMode.values)
              DropdownMenuItem<_TowerSortMode>(
                value: mode,
                child: Text('Sort by ${mode.label}'),
              ),
          ],
          onChanged: (mode) {
            if (mode != null) {
              onChanged(mode);
            }
          },
        ),
      ),
    );
  }
}

class _TowerChoiceChip extends StatelessWidget {
  const _TowerChoiceChip({
    required this.config,
    required this.buildCost,
    required this.fabricationDuration,
    required this.traitBias,
    required this.enabled,
    required this.highlighted,
    required this.onPressed,
  });

  final TowerConfig config;
  final int buildCost;
  final String fabricationDuration;
  final String traitBias;
  final bool enabled;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GuidedFocusFrame(
      active: highlighted,
      tint: LightcorePalette.quest,
      radius: 22,
      child: ActionChip(
        backgroundColor: config.affinity.color.withValues(alpha: 0.16),
        side: BorderSide(color: config.affinity.color.withValues(alpha: 0.4)),
        label: Text(
          '${config.name} • ${buildCost}L • $fabricationDuration • $traitBias',
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

class _FabricationProgressGlyph extends StatelessWidget {
  const _FabricationProgressGlyph({
    required this.tint,
    required this.progress,
    this.size = 22,
  });

  final Color tint;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: clamped, end: clamped),
      builder: (context, animatedProgress, _) {
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _FabricationProgressGlyphPainter(
              tint: tint,
              progress: animatedProgress,
            ),
          ),
        );
      },
    );
  }
}

class _FabricationProgressGlyphPainter extends CustomPainter {
  const _FabricationProgressGlyphPainter({
    required this.tint,
    required this.progress,
  });

  final Color tint;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final eased = Curves.easeOutCubic.transform(clamped);
    final innerRadius = radius * (0.22 + (eased * 0.5));
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.08)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      _polygonPath(center, radius, 6, math.pi / 6),
      borderPaint..color = tint.withValues(alpha: 0.24),
    );
    canvas.drawPath(
      _polygonPath(center, innerRadius, 6, math.pi / 6),
      Paint()
        ..style = PaintingStyle.fill
        ..color = tint.withValues(alpha: 0.12 + (eased * 0.24)),
    );

    final ringRadii = <double>[
      radius * (0.18 + (eased * 0.04)),
      radius * (0.34 + (eased * 0.08)),
      radius * (0.5 + (eased * 0.12)),
    ];
    final ringPoints = <List<Offset>>[];
    for (var ring = 0; ring < ringRadii.length; ring += 1) {
      final reveal = ((clamped - (ring * 0.13)) / 0.52)
          .clamp(0.0, 1.0)
          .toDouble();
      if (reveal <= 0) {
        ringPoints.add(const <Offset>[]);
        continue;
      }
      final rotation = math.pi / 6 + (ring * math.pi / 6);
      final sides = ring == 0 ? 3 : 6;
      final ringRadius = ringRadii[ring];
      ringPoints.add(_polygonPoints(center, ringRadius, 6, rotation));
      canvas.drawPath(
        _polygonPath(center, ringRadius, sides, rotation),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(
            0.8,
            size.shortestSide * (0.035 + ring * 0.01),
          )
          ..strokeCap = StrokeCap.round
          ..color = tint.withValues(alpha: 0.2 + (reveal * 0.28)),
      );
      _drawPolygonProgress(
        canvas,
        center: center,
        radius: ringRadius,
        sides: sides,
        rotation: rotation,
        progress: reveal,
        paint: borderPaint
          ..strokeWidth = math.max(
            1.0,
            size.shortestSide * (0.05 + ring * 0.012),
          )
          ..color = tint.withValues(alpha: 0.48 + (reveal * 0.34)),
      );
    }

    for (var ring = 0; ring < ringPoints.length - 1; ring += 1) {
      if (ringPoints[ring].isEmpty || ringPoints[ring + 1].isEmpty) {
        continue;
      }
      for (var index = 0; index < 6; index += 1) {
        final reveal = ((clamped * 1.22) - (ring * 0.18) - (index * 0.035))
            .clamp(0.0, 1.0)
            .toDouble();
        if (reveal <= 0) {
          continue;
        }
        final start = ringPoints[ring][index];
        final end = ringPoints[ring + 1][(index + (ring.isEven ? 0 : 1)) % 6];
        canvas.drawLine(
          start,
          Offset.lerp(start, end, Curves.easeOutCubic.transform(reveal))!,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, size.shortestSide * 0.035)
            ..strokeCap = StrokeCap.round
            ..color = tint.withValues(alpha: 0.14 + (reveal * 0.24)),
        );
      }
    }

    _drawPolygonProgress(
      canvas,
      center: center,
      radius: radius,
      sides: 6,
      rotation: math.pi / 6,
      progress: clamped,
      paint: borderPaint
        ..strokeWidth = math.max(1.6, size.shortestSide * 0.1)
        ..color = tint.withValues(alpha: 0.92),
    );

    for (var index = 0; index < 6; index += 1) {
      final angle = (-math.pi / 2) + (index * (math.pi * 2 / 6));
      final node = Offset(
        center.dx + math.cos(angle) * (innerRadius * 0.86),
        center.dy + math.sin(angle) * (innerRadius * 0.86),
      );
      canvas.drawCircle(
        node,
        math.max(1.0, size.shortestSide * 0.045),
        Paint()..color = tint.withValues(alpha: 0.52 + (eased * 0.24)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FabricationProgressGlyphPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.progress != progress;

  Path _polygonPath(Offset center, double radius, int sides, double rotation) {
    final path = Path();
    final points = _polygonPoints(center, radius, sides, rotation);
    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawPolygonProgress(
    Canvas canvas, {
    required Offset center,
    required double radius,
    int sides = 6,
    double rotation = math.pi / 6,
    required double progress,
    required Paint paint,
  }) {
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) {
      return;
    }
    final points = _polygonPoints(center, radius, sides, rotation);
    final totalEdges = sides * clamped;
    final fullEdges = totalEdges.floor();
    final partialEdge = totalEdges - fullEdges;

    for (var index = 0; index < fullEdges; index += 1) {
      canvas.drawLine(
        points[index % sides],
        points[(index + 1) % sides],
        paint,
      );
    }
    if (fullEdges < sides && partialEdge > 0) {
      final start = points[fullEdges % sides];
      final end = points[(fullEdges + 1) % sides];
      canvas.drawLine(start, Offset.lerp(start, end, partialEdge)!, paint);
    }
  }

  List<Offset> _polygonPoints(
    Offset center,
    double radius,
    int sides,
    double rotation,
  ) {
    return List<Offset>.generate(sides, (index) {
      final angle = rotation + ((math.pi * 2) / sides) * index;
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    });
  }
}

class _TowerLevelPips extends StatelessWidget {
  const _TowerLevelPips({
    required this.current,
    required this.max,
    required this.tint,
    required this.label,
  });

  final int current;
  final int max;
  final Color tint;
  final String label;

  @override
  Widget build(BuildContext context) {
    final clamped = current.clamp(0, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $clamped/$max',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: tint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var index = 0; index < max; index++)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < clamped
                      ? tint.withValues(alpha: 0.96)
                      : LightcorePalette.stroke.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}

enum _TowerSortMode { slot, level, power, affinity, projectile, payload }

extension on _TowerSortMode {
  String get label => switch (this) {
    _TowerSortMode.slot => 'slot',
    _TowerSortMode.level => 'level',
    _TowerSortMode.power => 'power',
    _TowerSortMode.affinity => 'color',
    _TowerSortMode.projectile => 'projectile',
    _TowerSortMode.payload => 'payload',
  };
}
