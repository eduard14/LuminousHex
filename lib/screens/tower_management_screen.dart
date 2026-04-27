import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_config.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/meter_bar.dart';
import '../widgets/radiance_stat_allocator.dart';
import '../widgets/tower_pattern_bonus_panel.dart';
import '../widgets/tower_level_hex_badge.dart';
import '../widgets/tower_ring_icon.dart';
import 'tower_detail_screen.dart';

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
        final sortedSlots = _sortedSlots(controller);
        final rangePreview = controller.canUpgradeCoreRange
            ? '${controller.coreRangeLabel} -> ${controller.nextCoreRangeLabel}'
            : '${controller.coreRangeLabel} max';
        final fireSpeedPreview = controller.canUpgradeCoreFireSpeed
            ? '${controller.coreFireSpeedLabel} -> ${controller.nextCoreFireSpeedLabel}'
            : '${controller.coreFireSpeedLabel} max';
        final queuePreview = controller.canUpgradeCoreQueueLimit
            ? '${controller.coreQueueCapacityLabel} -> ${controller.nextCoreQueueCapacityLabel}'
            : '${controller.coreQueueCapacityLabel} max';
        final multiShotPreview = controller.canUpgradeCoreMultiShot
            ? '${controller.coreMultiShotLabel} -> ${controller.nextCoreMultiShotLabel}'
            : '${controller.coreMultiShotLabel} max';

        return CustomScrollView(
          key: const PageStorageKey<String>('tower-management-scroll'),
          controller: widget.scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: AuroraPanel(
                tint: LightcorePalette.aether,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tower Matrix', style: textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      controller.isCompositeLayer
                          ? 'This is an Aligned Tower shell. Each outer slot grows a playable lower-class shell with its own anomaly deck, Apex cycle, and manager-gated offline progress. When a child shell aligns, it locks one projectile trait and one payload trait into this shell.'
                          : 'Root relays feed the center tower directly. Every buildable prism is a pure projectile seed with no payload. Prism and Nexus towers roll projectile and payload traits from the child shells underneath them.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    MeterBar(
                      value: controller.ringProgress,
                      color: LightcorePalette.aether,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${controller.activeLayerLabel} • ${controller.builtTowerCount}/${LightcoreController.slotCount} edge nodes online',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10),
                    MeterBar(
                      value: controller.promotionProgress,
                      color: LightcorePalette.solar,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alignment gate: ${controller.promotionStatusLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.solar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.outerSlotUnlockStatusLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.layer2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${controller.flowSummary} ${controller.queueSummary}',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    TowerPatternBonusPanel(
                      achievements: controller.activeTowerAchievements,
                      hint: controller.towerAchievementHintLabel,
                      tint: LightcorePalette.violet,
                    ),
                    if (controller.activeLayerHasParentSlot) ...[
                      const SizedBox(height: 10),
                      Text(
                        'This shell is forging a ${controller.activeLayerTargetShellLabel} tower. Costs are ${controller.activeLayerPriceMultiplier.toStringAsFixed(1)}x here.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: LightcorePalette.solar,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _SortSelector(
                      value: _sortMode,
                      onChanged: (mode) {
                        setState(() => _sortMode = mode);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: AuroraPanel(
                tint: controller.coreState.affinity.color,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Core Tower', style: textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Level ${controller.coreState.level}  •  ${controller.coreAffinitySignatureLabel}  •  ${controller.coreProjectileArsenalLabel}  •  ${controller.corePayloadArsenalLabel}  •  Lumen x${controller.lumenTierMultiplier.toStringAsFixed(0)}',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricTile(
                          label: 'Queue',
                          value: controller.coreQueueLoadLabel,
                        ),
                        _MetricTile(
                          label: 'Output',
                          value: controller.outputEfficiencyLabel,
                        ),
                        _MetricTile(
                          label: 'Stability',
                          value: controller.coreStabilityLabel,
                        ),
                        _MetricTile(
                          label: 'Range',
                          value: controller.coreRangeLabel,
                        ),
                        _MetricTile(
                          label: 'Fire Speed',
                          value: controller.coreFireSpeedLabel,
                        ),
                        _MetricTile(
                          label: 'Cooldown',
                          value: controller.coreCooldownLabel,
                        ),
                        _MetricTile(
                          label: 'Shots',
                          value: controller.coreMultiShotLabel,
                        ),
                        _MetricTile(
                          label: 'Passive L/s',
                          value: controller.passiveLumenPerSecond
                              .toStringAsFixed(1),
                        ),
                        if (controller.hasLumenHarvestPressure)
                          _MetricTile(
                            label: 'Recovery',
                            value:
                                '${controller.outputEfficiencyStatusLabel} / ${controller.lumenHarvestRecoveryLabel}',
                          ),
                        _MetricTile(
                          label: 'Sigils / Hearts',
                          value:
                              '${controller.bossTickets}/${controller.bossCores}',
                        ),
                        _MetricTile(
                          label: 'Slots',
                          value:
                              '${controller.unlockedOuterSlotCount}/${LightcoreController.slotCount}',
                        ),
                        _MetricTile(
                          label: 'Cost x',
                          value: controller.activeLayerPriceMultiplier
                              .toStringAsFixed(1),
                        ),
                        _MetricTile(
                          label: 'Global TS',
                          value: controller.towerStrengthCompactLabel,
                        ),
                        _MetricTile(
                          label: 'AR Level',
                          value: '${controller.accountRadianceLevel}',
                        ),
                        if (controller.hasSourceLayer)
                          FilledButton.icon(
                            onPressed: controller.enterSourceLayer,
                            icon: const Icon(Icons.unfold_less_double_rounded),
                            label: const Text('Enter Source'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Main tower upgrades: Range $rangePreview  •  Fire Speed $fireSpeedPreview  •  Queue $queuePreview  •  Multi-Shot $multiShotPreview  •  Next cooldown ${controller.nextCoreCooldownLabel}',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Global TS ranking runs on Total Strength. TS folds live tower stats, equipped gear, and inventory effects from anomalies and Apex cards into one power score. Account Radiance still gates feature unlocks.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.84),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadianceStatAllocator(controller: controller),
                    const SizedBox(height: 8),
                    Text(
                      'Anomaly inventory: ${controller.enemyInventoryBonusSummaryLabel}  •  Apex inventory: ${controller.bossInventoryBonusSummaryLabel}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.solar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        GuidedFocusFrame(
                          active: controller.tutorialHighlightsCoreRangeUpgrade,
                          tint: LightcorePalette.quest,
                          child: FilledButton.icon(
                            onPressed:
                                controller.canUpgradeCoreRange &&
                                    controller.lumens >=
                                        controller.coreRangeUpgradeCost
                                ? controller.upgradeCoreRange
                                : null,
                            icon: const Icon(Icons.radar_rounded),
                            label: Text(
                              controller.canUpgradeCoreRange
                                  ? 'Upgrade Range • ${controller.coreRangeUpgradeCost}L'
                                  : 'Range Maxed',
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              controller.canUpgradeCoreFireSpeed &&
                                  controller.lumens >=
                                      controller.coreFireSpeedUpgradeCost
                              ? controller.upgradeCoreFireSpeed
                              : null,
                          icon: const Icon(Icons.flash_on_rounded),
                          label: Text(
                            controller.canUpgradeCoreFireSpeed
                                ? 'Upgrade Fire Speed • ${controller.coreFireSpeedUpgradeCost}L'
                                : 'Fire Speed Maxed',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              controller.canUpgradeCoreQueueLimit &&
                                  controller.lumens >=
                                      controller.coreQueueUpgradeCost
                              ? controller.upgradeCoreQueueLimit
                              : null,
                          icon: const Icon(Icons.all_inbox_rounded),
                          label: Text(
                            controller.canUpgradeCoreQueueLimit
                                ? 'Upgrade Queue • ${controller.coreQueueUpgradeCost}L'
                                : 'Queue Maxed',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              controller.canUpgradeCoreMultiShot &&
                                  controller.lumens >=
                                      controller.coreMultiShotUpgradeCost
                              ? controller.upgradeCoreMultiShot
                              : null,
                          icon: const Icon(Icons.hub_rounded),
                          label: Text(
                            controller.canUpgradeCoreMultiShot
                                ? 'Upgrade Multi-Shot • ${controller.coreMultiShotUpgradeCost}L'
                                : 'Multi-Shot Maxed',
                          ),
                        ),
                      ],
                    ),
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
            SliverList.builder(
              itemCount: sortedSlots.length,
              itemBuilder: (context, index) {
                final slot = sortedSlots[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: slot.isBuilt
                      ? _BuiltSlotCard(controller: controller, slot: slot)
                      : controller.isOuterSlotUnlocked(slot.slotIndex)
                      ? _EmptySlotCard(
                          controller: controller,
                          slotIndex: slot.slotIndex,
                        )
                      : _LockedSlotCard(
                          controller: controller,
                          slotIndex: slot.slotIndex,
                        ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<OuterTowerState> _sortedSlots(LightcoreController controller) {
    final slots = controller.slots.toList(growable: false);
    if (_sortMode == _TowerSortMode.slot) {
      return slots;
    }

    int statusWeight(OuterTowerState slot) {
      if (!slot.isBuilt) {
        if (!controller.isOuterSlotUnlocked(slot.slotIndex)) {
          return 3;
        }
        return 2;
      }
      if (controller.isSlotLayerProject(slot)) {
        return 1;
      }
      return 0;
    }

    int effectiveLevel(OuterTowerState slot) {
      if (!slot.isBuilt) {
        return 0;
      }
      if (controller.isSlotLayerProject(slot)) {
        return controller.childPromotionReadyTowerCount(slot);
      }
      return slot.config != null ? slot.level : (slot.childCoreLevel ?? 1);
    }

    double progressValue(OuterTowerState slot) {
      if (!slot.isBuilt) {
        return -1;
      }
      if (controller.isSlotLayerProject(slot)) {
        return slot.childBuiltCount / LightcoreController.slotCount;
      }
      return slot.charge;
    }

    double loadValue(OuterTowerState slot) {
      if (!slot.isBuilt || controller.isSlotLayerProject(slot)) {
        return -1;
      }
      return controller.towerDisruptionFraction(slot);
    }

    int affinityValue(OuterTowerState slot) {
      final affinity =
          slot.config?.affinity ??
          slot.childAffinity ??
          PrototypeAffinity.neutral;
      return affinity.index;
    }

    int targetValue(OuterTowerState slot) {
      if (!slot.isBuilt || controller.isSlotLayerProject(slot)) {
        return -1;
      }
      return controller.towerTargetPriority(slot).index;
    }

    int compareNum(num left, num right) => right.compareTo(left);

    slots.sort((a, b) {
      final statusCompare = statusWeight(a).compareTo(statusWeight(b));
      if (statusCompare != 0) {
        return statusCompare;
      }

      final modeCompare = switch (_sortMode) {
        _TowerSortMode.slot => a.slotIndex.compareTo(b.slotIndex),
        _TowerSortMode.level => compareNum(
          effectiveLevel(a),
          effectiveLevel(b),
        ),
        _TowerSortMode.charge => compareNum(progressValue(a), progressValue(b)),
        _TowerSortMode.load => compareNum(loadValue(a), loadValue(b)),
        _TowerSortMode.affinity => affinityValue(a).compareTo(affinityValue(b)),
        _TowerSortMode.target => compareNum(targetValue(a), targetValue(b)),
      };

      if (modeCompare != 0) {
        return modeCompare;
      }
      return a.slotIndex.compareTo(b.slotIndex);
    });
    return slots;
  }
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final affinity
                        in LightcoreController.childCoreAffinityChoices)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          controller.createChildLayer(slotIndex, affinity);
                        },
                        icon: Icon(
                          Icons.hexagon_rounded,
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
                        ? 'Reroll Child • ${controller.echoSeedLabel}'
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
              onPressed: isMaxed || controller.lumens < cost
                  ? null
                  : () => controller.upgradeActiveChildTowerStat(upgrade.type),
              child: Text(isMaxed ? 'Maxed' : 'Tune ${cost}L'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard({required this.controller, required this.slotIndex});

  final LightcoreController controller;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuroraPanel(
      tint: LightcorePalette.aether,
      onTap: () => controller.isCompositeLayer
          ? _showChildCoreAffinityPicker(context, controller, slotIndex)
          : controller.selectSlot(slotIndex),
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
              ? FilledButton.icon(
                  onPressed: () => _showChildCoreAffinityPicker(
                    context,
                    controller,
                    slotIndex,
                  ),
                  icon: const TowerRingIcon(),
                  label: Text(
                    'Create Layer ${controller.activeLayer.tier - 1} Shell',
                  ),
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
                ? 'This edge stays sealed until you reach $requirement total EXP. Push the viewed Home Tower shell harder or raise the swarm cap to open another child-shell lane.'
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

enum _TowerSortMode { slot, level, charge, load, affinity, target }

extension on _TowerSortMode {
  String get label => switch (this) {
    _TowerSortMode.slot => 'slot',
    _TowerSortMode.level => 'level',
    _TowerSortMode.charge => 'charge',
    _TowerSortMode.load => 'load',
    _TowerSortMode.affinity => 'color',
    _TowerSortMode.target => 'target',
  };
}
