import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/card_configs.dart';
import '../data/enemy_manager_configs.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_rewarded_ads.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/lightcore_detail_sheet.dart';
import '../widgets/manager_portrait.dart';
import '../widgets/symbol_grid_tile.dart';

class CardManagementScreen extends StatelessWidget {
  const CardManagementScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.scrollController,
  });

  final LightcoreController controller;
  final bool isActive;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const rewardedFluxGrant = 30;

    if (!isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final towerCoreManager = controller.towerCoreManager;
        final enemyCoreManager = controller.enemyCoreManager;
        final lockedTowerManagers = _lockedTowerManagerConfigs(controller);
        final lockedEnemyManagers = _lockedEnemyManagerConfigs(controller);

        return ListView(
          key: const PageStorageKey<String>('card-management-scroll'),
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          children: [
            Text('Main Manager', style: textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              controller.managerAssignmentUnlocked
                  ? 'Socket one Core Manager and one Threat Director into the Tower Core. Core Managers boost every tower, and Threat Directors apply to every enemy spawned by this shell.'
                  : 'Manager assignment unlocks at Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel}. Flux still banks now so the foundry is ready when it opens.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ResourceChip(
                  icon: Icons.bolt_rounded,
                  label: 'Lumens ${controller.lumens}',
                  tint: LightcorePalette.solar,
                ),
                _ResourceChip(
                  icon: Icons.offline_bolt_rounded,
                  label: '${LightcoreCurrencyLabels.flux} ${controller.flux}',
                  tint: LightcorePalette.verdant,
                ),
                _ResourceChip(
                  icon: Icons.grain_rounded,
                  label:
                      '${LightcoreCurrencyLabels.managerShards} ${controller.managerShards}',
                  tint: LightcorePalette.aether,
                ),
                _ResourceChip(
                  icon: Icons.auto_graph_rounded,
                  label: 'Power Lv ${controller.managerPowerLevel}',
                  tint: LightcorePalette.violet,
                ),
                _ResourceChip(
                  icon: Icons.radar_rounded,
                  label:
                      '${LightcoreCurrencyLabels.scansShort} ${controller.enemyTickets}',
                  tint: LightcorePalette.scanGlow,
                ),
                _ResourceChip(
                  icon: Icons.layers_rounded,
                  label: controller.activeLayerLabel,
                  tint: LightcorePalette.mist,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Tower Core Sockets',
              tint: LightcorePalette.aether,
              subtitle: !controller.managerAssignmentUnlocked
                  ? 'Reach Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel} before tower sockets can take managers.'
                  : 'Managers are mounted on the core and broadcast their effects across the whole active shell.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CoreSocketTile(
                  tint: LightcorePalette.aether,
                  icon: towerCoreManager == null
                      ? Icons.auto_awesome_rounded
                      : _towerManagerIcon(towerCoreManager),
                  centerOverride: towerCoreManager == null
                      ? null
                      : ManagerPortrait(
                          seed: towerCoreManager.config.id,
                          name: towerCoreManager.config.name,
                          tint: LightcorePalette.aether,
                          icon: _towerManagerIcon(towerCoreManager),
                          family: ManagerPortraitFamily.core,
                          assetPath: towerCoreManager.config.portraitAssetPath,
                          size: 50,
                        ),
                  badgeIcon: Icons.hexagon_rounded,
                  semanticLabel:
                      'Core Manager socket, ${towerCoreManager?.name ?? 'empty'}',
                  label: 'Towers',
                  value: towerCoreManager?.name ?? 'Open',
                  selected: towerCoreManager != null,
                  onTap: towerCoreManager == null
                      ? null
                      : () => _showTowerManagerDetails(
                          context,
                          towerCoreManager.instanceId,
                        ),
                ),
                _CoreSocketTile(
                  tint: LightcorePalette.flare,
                  icon: enemyCoreManager == null
                      ? Icons.tune_rounded
                      : _enemyManagerIcon(enemyCoreManager),
                  centerOverride: enemyCoreManager == null
                      ? null
                      : ManagerPortrait(
                          seed: enemyCoreManager.config.id,
                          name: enemyCoreManager.config.name,
                          tint: LightcorePalette.flare,
                          icon: _enemyManagerIcon(enemyCoreManager),
                          family: ManagerPortraitFamily.threat,
                          assetPath: enemyCoreManager.config.portraitAssetPath,
                          size: 50,
                        ),
                  badgeIcon: Icons.groups_rounded,
                  semanticLabel:
                      'Threat Director socket, ${enemyCoreManager?.name ?? 'empty'}',
                  label: 'Enemies',
                  value: enemyCoreManager?.name ?? 'Open',
                  selected: enemyCoreManager != null,
                  onTap: enemyCoreManager == null
                      ? null
                      : () => _showEnemyManagerDetails(
                          context,
                          enemyCoreManager.instanceId,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Core Manager: ${towerCoreManager?.name ?? 'Open'}  •  Threat Director: ${enemyCoreManager?.name ?? 'Open'}',
              style: textTheme.bodySmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.74),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Manager Power',
              tint: LightcorePalette.aether,
              subtitle:
                  'Daily Dungeons now award Manager Shards. Spend them here for a permanent lift to every manager roll.',
            ),
            const SizedBox(height: 10),
            _ManagerPowerPanel(controller: controller),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Tower Upgraders',
              tint: LightcorePalette.violet,
              subtitle: !controller.managerAssignmentUnlocked
                  ? 'Reach Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel} before Core Managers can be assigned.'
                  : controller.cards.isEmpty
                  ? 'No Core Managers in inventory yet. Locked roster tiles preview future foundry rolls.'
                  : 'Owned rolls appear first. Locked roster tiles preview managers still missing from inventory.',
            ),
            const SizedBox(height: 10),
            if (controller.cards.isEmpty) ...[
              _InlineSectionNotice(
                message: controller.managersUnlocked
                    ? 'Forge a Core Manager when you have enough Flux.'
                    : 'No Core Managers in inventory. The foundry unlocks at Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel}.',
                tint: LightcorePalette.violet,
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final manager in controller.cards)
                  _TowerManagerGlyphTile(
                    controller: controller,
                    manager: manager,
                    onTap: () =>
                        _showTowerManagerDetails(context, manager.instanceId),
                  ),
                for (final config in lockedTowerManagers)
                  _LockedTowerManagerGlyphTile(
                    config: config,
                    onTap: () =>
                        _showLockedTowerManagerDetails(context, config),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Threat Directors',
              tint: LightcorePalette.warning,
              subtitle: !controller.managerAssignmentUnlocked
                  ? 'Reach Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel} before Threat Directors can be assigned.'
                  : controller.enemyManagers.isEmpty
                  ? 'No Threat Directors in inventory yet. Locked roster tiles preview future foundry rolls.'
                  : 'Owned rolls appear first. Locked roster tiles preview directors still missing from inventory.',
            ),
            const SizedBox(height: 10),
            if (controller.enemyManagers.isEmpty) ...[
              _InlineSectionNotice(
                message: controller.managersUnlocked
                    ? 'Forge a Threat Director when you have enough Flux.'
                    : 'No Threat Directors in inventory. The foundry unlocks at Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel}.',
                tint: LightcorePalette.warning,
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final manager in controller.enemyManagers)
                  _EnemyManagerGlyphTile(
                    controller: controller,
                    manager: manager,
                    onTap: () =>
                        _showEnemyManagerDetails(context, manager.instanceId),
                  ),
                for (final config in lockedEnemyManagers)
                  _LockedEnemyManagerGlyphTile(
                    config: config,
                    onTap: () =>
                        _showLockedEnemyManagerDetails(context, config),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Foundry',
              tint: LightcorePalette.solar,
              subtitle: controller.managersUnlocked
                  ? 'Open single rolls or bulk packs. Bulk packs add Manager Shards and guarantee a floor on the final roll.'
                  : 'The foundry unlocks at Core Lv ${LightcoreController.managerCoreLevelRequirement} or Account Radiance Lv ${LightcoreController.managerUnlockLevel}. Flux still banks now so it has real fuel when it comes online.',
            ),
            const SizedBox(height: 10),
            _ManagerForgePanel(
              controller: controller,
              onRewardedFlux: LightcoreRewardedAds.isSupportedPlatform
                  ? () async {
                      final earned = await showLightcoreRewardedAd(
                        context,
                        rewardLabel: LightcoreCurrencyLabels.rewardFlux(
                          rewardedFluxGrant,
                        ),
                      );
                      if (!earned) {
                        return;
                      }
                      controller.grantRewardedResources(
                        fluxGranted: rewardedFluxGrant,
                        sourceLabel: 'Reward ad • Foundry subsidy',
                      );
                    }
                  : null,
              rewardedFluxGrant: rewardedFluxGrant,
            ),
            const SizedBox(height: 8),
            Text(
              LightcoreRewardedAds.isSupportedPlatform
                  ? 'Rewarded ads can top off the foundry when you are just short on Flux.'
                  : 'Rewarded foundry top-offs are staged for Android and iOS builds only.',
              style: textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  void _showTowerManagerDetails(BuildContext context, String managerId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final manager = controller.inventoryCardById(managerId);
            if (manager == null) {
              return const SizedBox.shrink();
            }

            return LightcoreDetailSheet(
              tint: LightcorePalette.aether,
              child: _TowerManagerDetailSheet(
                controller: controller,
                manager: manager,
                onAssign: () {
                  Navigator.of(sheetContext).pop();
                  controller.equipCardToCore(manager.instanceId);
                },
                onUnequip:
                    controller.towerCoreManager?.instanceId ==
                        manager.instanceId
                    ? () {
                        Navigator.of(sheetContext).pop();
                        controller.unequipCoreTowerManager();
                      }
                    : null,
                onDismantle: () {
                  Navigator.of(sheetContext).pop();
                  controller.dismantleTowerManager(manager.instanceId);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showEnemyManagerDetails(BuildContext context, String managerId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final manager = controller.enemyManagerById(managerId);
            if (manager == null) {
              return const SizedBox.shrink();
            }

            return LightcoreDetailSheet(
              tint: LightcorePalette.flare,
              child: _EnemyManagerDetailSheet(
                controller: controller,
                manager: manager,
                onAssign: () {
                  Navigator.of(sheetContext).pop();
                  controller.assignEnemyManagerToCore(manager.instanceId);
                },
                onRemove:
                    controller.enemyCoreManager?.instanceId ==
                        manager.instanceId
                    ? () {
                        Navigator.of(sheetContext).pop();
                        controller.clearEnemyCoreManager();
                      }
                    : null,
                onDismantle: () {
                  Navigator.of(sheetContext).pop();
                  controller.dismantleEnemyManager(manager.instanceId);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showLockedTowerManagerDetails(BuildContext context, CardConfig config) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return LightcoreDetailSheet(
          tint: LightcorePalette.aether,
          child: _LockedTowerManagerDetailSheet(config: config),
        );
      },
    );
  }

  void _showLockedEnemyManagerDetails(
    BuildContext context,
    EnemyManagerConfig config,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return LightcoreDetailSheet(
          tint: LightcorePalette.flare,
          child: _LockedEnemyManagerDetailSheet(config: config),
        );
      },
    );
  }
}

List<CardConfig> _lockedTowerManagerConfigs(LightcoreController controller) {
  final ownedConfigIds = controller.cards
      .map((manager) => manager.config.id)
      .toSet();
  return CardLibrary.templates
      .where((config) => !ownedConfigIds.contains(config.id))
      .toList(growable: false);
}

List<EnemyManagerConfig> _lockedEnemyManagerConfigs(
  LightcoreController controller,
) {
  final ownedConfigIds = controller.enemyManagers
      .map((manager) => manager.config.id)
      .toSet();
  return EnemyManagerLibrary.all
      .where((config) => !ownedConfigIds.contains(config.id))
      .toList(growable: false);
}

String _towerManagerStatus(
  LightcoreController controller,
  InventoryCard manager,
) {
  if (controller.towerCoreManager?.instanceId == manager.instanceId) {
    return 'Tower Core';
  }
  if (manager.equippedLayerId == null) {
    return 'Ready';
  }
  if (manager.equippedLayerId == controller.activeLayer.id) {
    return 'Tower Core';
  }
  return 'Other Layer';
}

String _enemyManagerStatus(
  LightcoreController controller,
  EnemyManagerState manager,
) {
  if (controller.enemyCoreManager?.instanceId == manager.instanceId) {
    return 'Tower Core';
  }
  if (manager.assignedLayerId == null) {
    return 'Ready';
  }
  if (manager.assignedLayerId != controller.activeLayer.id) {
    return 'Other Layer';
  }
  return 'Tower Core';
}

String _signedPercent(double delta) {
  final value = (delta * 100).round();
  return '${value >= 0 ? '+' : ''}$value%';
}

class _ManagerSectionHeader extends StatelessWidget {
  const _ManagerSectionHeader({
    required this.title,
    required this.tint,
    required this.subtitle,
  });

  final String title;
  final Color tint;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: LightcorePalette.mist,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: textTheme.bodySmall),
      ],
    );
  }
}

class _InlineSectionNotice extends StatelessWidget {
  const _InlineSectionNotice({required this.message, required this.tint});

  final String message;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: tint.withValues(alpha: 0.08),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: LightcorePalette.mist.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: tint),
    );
  }
}

class _ManagerPowerPanel extends StatelessWidget {
  const _ManagerPowerPanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxed =
        controller.managerPowerLevel >=
        LightcoreController.maxManagerPowerLevel;
    final cost = controller.managerPowerUpgradeCost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
        border: Border.all(
          color: LightcorePalette.aether.withValues(alpha: 0.26),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _IconBadge(
            icon: Icons.auto_graph_rounded,
            tint: LightcorePalette.aether,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manager Power Lv ${controller.managerPowerLevel}/${LightcoreController.maxManagerPowerLevel}',
                  style: textTheme.titleMedium?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.managerPowerEffectLabel} to manager stat deltas, trait matches, automation rates, and director tuning.',
                  style: textTheme.bodySmall?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          _ResourceChip(
            icon: Icons.grain_rounded,
            label:
                '${controller.managerShards} ${LightcoreCurrencyLabels.managerShards}',
            tint: LightcorePalette.aether,
          ),
          _ResourceChip(
            icon: maxed ? Icons.verified_rounded : Icons.upgrade_rounded,
            label: maxed
                ? 'Maxed'
                : '${LightcoreCurrencyLabels.managerShardCount(cost)} next',
            tint: maxed ? LightcorePalette.success : LightcorePalette.solar,
          ),
          FilledButton.icon(
            onPressed: controller.canUpgradeManagerPower
                ? controller.upgradeManagerPower
                : null,
            icon: const Icon(Icons.upgrade_rounded),
            label: Text(maxed ? 'Maxed' : 'Upgrade'),
          ),
        ],
      ),
    );
  }
}

class _ManagerForgePanel extends StatelessWidget {
  const _ManagerForgePanel({
    required this.controller,
    required this.onRewardedFlux,
    required this.rewardedFluxGrant,
  });

  final LightcoreController controller;
  final Future<void> Function()? onRewardedFlux;
  final int rewardedFluxGrant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerForgeGroup(
          controller: controller,
          kind: _ManagerForgeKind.tower,
          title: 'Core Manager Packs',
          icon: Icons.auto_awesome_rounded,
          tint: LightcorePalette.aether,
          baseCost: LightcoreController.towerManagerFluxCost,
          tutorialActive: controller.tutorialHighlightsTowerManagerForge,
          canForge: controller.canForgeTowerManagerBatch,
          onForge: controller.forgeTowerManagerBatch,
        ),
        const SizedBox(height: 10),
        _ManagerForgeGroup(
          controller: controller,
          kind: _ManagerForgeKind.enemy,
          title: 'Threat Director Packs',
          icon: Icons.tune_rounded,
          tint: LightcorePalette.flare,
          baseCost: LightcoreController.enemyManagerFluxCost,
          tutorialActive: controller.tutorialHighlightsEnemyManagerForge,
          canForge: controller.canForgeEnemyManagerBatch,
          onForge: controller.forgeEnemyManagerBatch,
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: onRewardedFlux,
          icon: const Icon(Icons.play_circle_fill_rounded),
          label: Text(
            'Watch Ad • ${LightcoreCurrencyLabels.rewardFlux(rewardedFluxGrant)}',
          ),
        ),
      ],
    );
  }
}

enum _ManagerForgeKind { tower, enemy }

class _ManagerForgeGroup extends StatelessWidget {
  const _ManagerForgeGroup({
    required this.controller,
    required this.kind,
    required this.title,
    required this.icon,
    required this.tint,
    required this.baseCost,
    required this.tutorialActive,
    required this.canForge,
    required this.onForge,
  });

  final LightcoreController controller;
  final _ManagerForgeKind kind;
  final String title;
  final IconData icon;
  final Color tint;
  final int baseCost;
  final bool tutorialActive;
  final bool Function(int count) canForge;
  final bool Function(int count) onForge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in const [1, 5, 10])
                GuidedFocusFrame(
                  active: tutorialActive && count == 1,
                  tint: LightcorePalette.quest,
                  child: _ManagerForgeButton(
                    count: count,
                    cost: baseCost * count,
                    tint: tint,
                    enabled: canForge(count),
                    onPressed: () => _handleForge(context, count),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleForge(BuildContext context, int count) {
    final towerStart = controller.cards.length;
    final enemyStart = controller.enemyManagers.length;
    final forged = onForge(count);
    if (!forged) {
      return;
    }

    final pulls = switch (kind) {
      _ManagerForgeKind.tower =>
        controller.cards
            .skip(towerStart)
            .map(_ManagerForgeRevealPull.fromTower)
            .toList(growable: false),
      _ManagerForgeKind.enemy =>
        controller.enemyManagers
            .skip(enemyStart)
            .map(_ManagerForgeRevealPull.fromEnemy)
            .toList(growable: false),
    };
    if (pulls.isEmpty) {
      return;
    }

    _showManagerForgeReveal(
      context,
      kind: kind,
      pulls: pulls,
      bonusLabel: _managerBulkBonusLabel(count),
    );
  }
}

class _ManagerForgeButton extends StatelessWidget {
  const _ManagerForgeButton({
    required this.count,
    required this.cost,
    required this.tint,
    required this.enabled,
    required this.onPressed,
  });

  final int count;
  final int cost;
  final Color tint;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bonus = _managerBulkBonusLabel(count);
    final label = 'x$count • $cost ${LightcoreCurrencyLabels.flux}';
    final button = FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        count == 1 ? Icons.hexagon_rounded : Icons.inventory_2_rounded,
      ),
      label: Text(label),
    );

    if (bonus == null) {
      return button;
    }

    return Tooltip(
      message: bonus,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          button,
          const SizedBox(height: 5),
          _Badge(label: bonus, tint: tint),
        ],
      ),
    );
  }
}

String? _managerBulkBonusLabel(int count) {
  if (count >= 10) {
    return '+${LightcoreController.managerBulkForgeTenBonusShards} shards • Rare floor';
  }
  if (count >= 5) {
    return '+${LightcoreController.managerBulkForgeFiveBonusShards} shards • Uncommon floor';
  }
  return null;
}

void _showManagerForgeReveal(
  BuildContext context, {
  required _ManagerForgeKind kind,
  required List<_ManagerForgeRevealPull> pulls,
  required String? bonusLabel,
}) {
  final tint = switch (kind) {
    _ManagerForgeKind.tower => LightcorePalette.aether,
    _ManagerForgeKind.enemy => LightcorePalette.flare,
  };
  final title = switch (kind) {
    _ManagerForgeKind.tower => 'Core Manager Forged',
    _ManagerForgeKind.enemy => 'Threat Director Forged',
  };
  final subtitle = pulls.length == 1
      ? 'A new roll is ready for the Tower Core.'
      : '${pulls.length} new rolls are ready for the Tower Core.';

  showDialog<void>(
    context: context,
    barrierColor: LightcorePalette.night.withValues(alpha: 0.84),
    builder: (dialogContext) {
      return _ManagerForgeRevealDialog(
        title: title,
        subtitle: subtitle,
        tint: tint,
        pulls: pulls,
        bonusLabel: bonusLabel,
        onClose: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class _ManagerForgeRevealPull {
  const _ManagerForgeRevealPull({
    required this.name,
    required this.portraitSeed,
    required this.portraitName,
    required this.roleLabel,
    required this.rarity,
    required this.icon,
    required this.family,
    required this.tint,
    required this.tags,
  });

  factory _ManagerForgeRevealPull.fromTower(InventoryCard manager) {
    final focus = manager.favoredAffinity;
    return _ManagerForgeRevealPull(
      name: manager.name,
      portraitSeed: manager.config.id,
      portraitName: manager.config.name,
      roleLabel: manager.roleLabel,
      rarity: manager.rarity,
      icon: _towerManagerIcon(manager),
      family: ManagerPortraitFamily.core,
      tint: focus?.color ?? LightcorePalette.aether,
      tags: [
        manager.primaryTraitLabel,
        manager.secondaryTraitLabel,
        if (focus != null) focus.label,
        if (manager.projectileFocus != null) manager.projectileFocus!.label,
        if (manager.payloadFocus != null) manager.payloadFocus!.label,
      ],
    );
  }

  factory _ManagerForgeRevealPull.fromEnemy(EnemyManagerState manager) {
    final focus = manager.targetAffinity;
    return _ManagerForgeRevealPull(
      name: manager.name,
      portraitSeed: manager.config.id,
      portraitName: manager.config.name,
      roleLabel: manager.roleLabel,
      rarity: manager.rarity,
      icon: _enemyManagerIcon(manager),
      family: ManagerPortraitFamily.threat,
      tint: focus?.color ?? LightcorePalette.flare,
      tags: [
        manager.primaryTraitLabel,
        manager.secondaryTraitLabel,
        if (focus != null) focus.label,
      ],
    );
  }

  final String name;
  final String portraitSeed;
  final String portraitName;
  final String roleLabel;
  final ManagerRarity rarity;
  final IconData icon;
  final ManagerPortraitFamily family;
  final Color tint;
  final List<String> tags;
}

class _ManagerForgeRevealDialog extends StatefulWidget {
  const _ManagerForgeRevealDialog({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.pulls,
    required this.bonusLabel,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final List<_ManagerForgeRevealPull> pulls;
  final String? bonusLabel;
  final VoidCallback onClose;

  @override
  State<_ManagerForgeRevealDialog> createState() =>
      _ManagerForgeRevealDialogState();
}

class _ManagerForgeRevealDialogState extends State<_ManagerForgeRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final _ManagerForgeRevealPull _featuredPull;

  @override
  void initState() {
    super.initState();
    _featuredPull = widget.pulls.reduce(
      (best, next) =>
          _managerRarityScore(next.rarity) > _managerRarityScore(best.rarity)
          ? next
          : best,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final accent = _managerRarityTint(_featuredPull.rarity, _featuredPull.tint);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.88,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final panelIn = _curvedInterval(
              progress,
              0,
              0.34,
              Curves.easeOutCubic,
            );
            return Opacity(
              opacity: panelIn,
              child: Transform.scale(
                scale: 0.95 + (panelIn * 0.05),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        LightcorePalette.panelRaised.withValues(alpha: 0.98),
                        LightcorePalette.abyss.withValues(alpha: 0.98),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.58),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 34,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ManagerForgeRevealHeader(
                                  title: widget.title,
                                  subtitle: widget.subtitle,
                                  tint: widget.tint,
                                  accent: accent,
                                ),
                                const SizedBox(height: 10),
                                _ManagerForgeRevealStage(
                                  progress: progress,
                                  pull: _featuredPull,
                                  accent: accent,
                                ),
                                if (widget.bonusLabel != null) ...[
                                  const SizedBox(height: 10),
                                  Center(
                                    child: _Badge(
                                      label: widget.bonusLabel!,
                                      tint: LightcorePalette.solar,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                _ManagerForgeRevealGrid(
                                  progress: progress,
                                  pulls: widget.pulls,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                          child: FilledButton.icon(
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Continue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ManagerForgeRevealHeader extends StatelessWidget {
  const _ManagerForgeRevealHeader({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagerForgeRevealStage extends StatelessWidget {
  const _ManagerForgeRevealStage({
    required this.progress,
    required this.pull,
    required this.accent,
  });

  final double progress;
  final _ManagerForgeRevealPull pull;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final charge = _curvedInterval(progress, 0, 0.42, Curves.easeInOutCubic);
    final reveal = _curvedInterval(progress, 0.25, 0.92, Curves.elasticOut);
    final flash =
        1 - _curvedInterval(progress, 0.38, 0.86, Curves.easeOutCubic);
    final rarityScore = _managerRarityScore(pull.rarity);

    return SizedBox(
      height: 178,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ManagerForgeBurstPainter(
                progress: progress,
                tint: pull.tint,
                accent: accent,
                rarityScore: rarityScore,
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: 18 + (18 * (1 - charge)),
            child: Opacity(
              opacity: charge,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accent.withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, 28 * (1 - reveal)),
            child: Transform.rotate(
              angle: -0.18 * (1 - reveal),
              child: Transform.scale(
                scale: 0.72 + (0.3 * reveal),
                child: _ManagerForgeRevealCard(
                  pull: pull,
                  accent: accent,
                  flash: flash,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerForgeRevealCard extends StatelessWidget {
  const _ManagerForgeRevealCard({
    required this.pull,
    required this.accent,
    required this.flash,
  });

  final _ManagerForgeRevealPull pull;
  final Color accent;
  final double flash;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 136,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.34 + (flash * 0.24)),
            pull.tint.withValues(alpha: 0.16),
            LightcorePalette.panelRaised.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.82), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.26 + (flash * 0.28)),
            blurRadius: 28 + (flash * 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (
                var index = 0;
                index < _managerRarityScore(pull.rarity) + 1;
                index += 1
              )
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const Spacer(),
          ManagerPortrait(
            seed: pull.portraitSeed,
            name: pull.portraitName,
            tint: accent,
            icon: pull.icon,
            family: pull.family,
            size: 64,
          ),
          const Spacer(),
          Text(
            _managerRarityLabel(pull.rarity),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: LightcorePalette.layer2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerForgeRevealGrid extends StatelessWidget {
  const _ManagerForgeRevealGrid({required this.progress, required this.pulls});

  final double progress;
  final List<_ManagerForgeRevealPull> pulls;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 440;
        final spacing = twoColumn ? 8.0 : 0.0;
        final width = twoColumn
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final (index, pull) in pulls.indexed)
              SizedBox(
                width: width,
                child: _ManagerForgeRevealTile(
                  progress: progress,
                  index: index,
                  pull: pull,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ManagerForgeRevealTile extends StatelessWidget {
  const _ManagerForgeRevealTile({
    required this.progress,
    required this.index,
    required this.pull,
  });

  final double progress;
  final int index;
  final _ManagerForgeRevealPull pull;

  @override
  Widget build(BuildContext context) {
    final reveal = _curvedInterval(
      progress,
      (0.42 + (index * 0.035)).clamp(0.42, 0.78).toDouble(),
      1,
      Curves.easeOutBack,
    );
    final accent = _managerRarityTint(pull.rarity, pull.tint);

    return Opacity(
      opacity: reveal.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - reveal)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: LightcorePalette.panel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.34)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ManagerPortrait(
                  seed: pull.portraitSeed,
                  name: pull.portraitName,
                  tint: accent,
                  icon: pull.icon,
                  family: pull.family,
                  size: 44,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pull.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pull.roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _CompactRevealTag(
                          label: _managerRarityLabel(pull.rarity),
                          tint: accent,
                        ),
                        for (final tag in pull.tags.take(2))
                          _CompactRevealTag(label: tag, tint: pull.tint),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRevealTag extends StatelessWidget {
  const _CompactRevealTag({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LightcorePalette.layer2,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _ManagerForgeBurstPainter extends CustomPainter {
  const _ManagerForgeBurstPainter({
    required this.progress,
    required this.tint,
    required this.accent,
    required this.rarityScore,
  });

  final double progress;
  final Color tint;
  final Color accent;
  final int rarityScore;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = math.min(size.width, size.height) * 0.34;
    final pulse = (math.sin(progress * math.pi * 3) + 1) / 2;
    final charge = _curvedInterval(progress, 0, 0.5, Curves.easeOutCubic);
    final burst = _curvedInterval(progress, 0.32, 1, Curves.easeOutCubic);

    final washPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.24 + (pulse * 0.08)),
          tint.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.95));
    canvas.drawCircle(center, radius * 1.95, washPaint);

    for (var index = 0; index < 3; index += 1) {
      final ringProgress = (burst + (index * 0.22)).clamp(0.0, 1.0);
      final ringRadius = radius * (0.58 + (ringProgress * 1.24));
      final ringAlpha = (1 - ringProgress) * (0.34 + (rarityScore * 0.04));
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 + (index * 0.3)
          ..color = accent.withValues(alpha: ringAlpha.clamp(0.0, 0.5)),
      );
    }

    final beamCount = 8 + (rarityScore * 2);
    final beamPaint = Paint()
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: 0.12 + (charge * 0.22));
    for (var index = 0; index < beamCount; index += 1) {
      final angle =
          ((math.pi * 2) / beamCount * index) + (progress * math.pi * 0.9);
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * 22;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.62;
      canvas.drawLine(inner, outer, beamPaint);
    }

    final sparkCount = 18 + (rarityScore * 5);
    for (var index = 0; index < sparkCount; index += 1) {
      final seed = index * 1.618;
      final angle = seed + (progress * math.pi * (0.8 + (index % 3) * 0.12));
      final distance =
          radius * (0.54 + ((index % 7) * 0.12)) * (0.72 + (burst * 0.34));
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final size = 1.4 + ((index + rarityScore) % 4) * 0.45;
      final alpha = (0.18 + (pulse * 0.18) + (burst * 0.2)).clamp(0.0, 0.62);
      canvas.drawCircle(
        point,
        size,
        Paint()
          ..color = (index.isEven ? accent : tint).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ManagerForgeBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tint != tint ||
        oldDelegate.accent != accent ||
        oldDelegate.rarityScore != rarityScore;
  }
}

Color _managerRarityTint(ManagerRarity rarity, Color fallback) {
  return switch (rarity) {
    ManagerRarity.common => fallback,
    ManagerRarity.uncommon => LightcorePalette.verdant,
    ManagerRarity.rare => LightcorePalette.aether,
    ManagerRarity.epic => LightcorePalette.violet,
    ManagerRarity.legendary => LightcorePalette.gilded,
  };
}

double _curvedInterval(double value, double begin, double end, Curve curve) {
  if (value <= begin) {
    return 0;
  }
  if (value >= end) {
    return 1;
  }
  final t = ((value - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
  return curve.transform(t);
}

class _CoreSocketTile extends StatelessWidget {
  const _CoreSocketTile({
    required this.tint,
    required this.icon,
    this.centerOverride,
    required this.badgeIcon,
    required this.semanticLabel,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final Color tint;
  final IconData icon;
  final Widget? centerOverride;
  final IconData badgeIcon;
  final String semanticLabel;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SymbolGridTile(
      tint: tint,
      selected: selected,
      semanticLabel: semanticLabel,
      onTap: onTap,
      topLeading: SymbolGridBadge(tint: tint, child: Text(label)),
      topTrailing: SymbolGridBadge(
        tint: selected ? LightcorePalette.layer2 : tint,
        shape: BoxShape.circle,
        size: 22,
        child: Icon(selected ? Icons.check_rounded : badgeIcon),
      ),
      center: centerOverride ?? Icon(icon, color: tint, size: 40),
      bottomChildren: [
        SymbolGridBadge(
          tint: tint,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 74),
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

class _TowerManagerGlyphTile extends StatelessWidget {
  const _TowerManagerGlyphTile({
    required this.controller,
    required this.manager,
    required this.onTap,
  });

  final LightcoreController controller;
  final InventoryCard manager;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final equippedHere =
        controller.towerCoreManager?.instanceId == manager.instanceId;

    return GuidedFocusFrame(
      active: controller.tutorialHighlightsTowerManager(manager.instanceId),
      tint: LightcorePalette.quest,
      child: SymbolGridTile(
        tint: LightcorePalette.aether,
        selected: equippedHere,
        semanticLabel: manager.name,
        onTap: onTap,
        topLeading: SymbolGridPips(
          count: _managerRarityScore(manager.rarity) + 1,
          tint: LightcorePalette.aether,
        ),
        topTrailing: SymbolGridBadge(
          tint: equippedHere
              ? LightcorePalette.layer2
              : LightcorePalette.aether,
          shape: BoxShape.circle,
          size: 22,
          child: Icon(
            equippedHere ? Icons.check_rounded : Icons.auto_awesome_rounded,
          ),
        ),
        center: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ManagerPortrait(
              seed: manager.config.id,
              name: manager.config.name,
              tint: LightcorePalette.aether,
              icon: _towerManagerIcon(manager),
              family: ManagerPortraitFamily.core,
              assetPath: manager.config.portraitAssetPath,
              size: 50,
            ),
            if (manager.favoredAffinity != null)
              AffinityGlyph(affinity: manager.favoredAffinity!, size: 16),
          ],
        ),
        bottomChildren: [
          _deltaBadge(
            icon: Icons.flash_on_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.powerMultiplier,
                ) -
                1,
          ),
          _deltaBadge(
            icon: Icons.blur_circular_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.chargeMultiplier,
                ) -
                1,
          ),
          _deltaBadge(
            icon: Icons.timer_rounded,
            delta:
                1 -
                controller.managerPowerAdjustedCooldown(
                  manager.cooldownMultiplier,
                ),
          ),
          _deltaBadge(
            icon: Icons.adjust_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.advantageMultiplier,
                ) -
                1,
          ),
          _rateBadge(
            controller.managerPowerAdjustedRate(manager.automationRate),
          ),
        ],
      ),
    );
  }
}

class _EnemyManagerGlyphTile extends StatelessWidget {
  const _EnemyManagerGlyphTile({
    required this.controller,
    required this.manager,
    required this.onTap,
  });

  final LightcoreController controller;
  final EnemyManagerState manager;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final assignedHere =
        controller.enemyCoreManager?.instanceId == manager.instanceId;

    return GuidedFocusFrame(
      active: controller.tutorialHighlightsEnemyManager(manager.instanceId),
      tint: LightcorePalette.quest,
      child: SymbolGridTile(
        tint: LightcorePalette.flare,
        selected: assignedHere,
        semanticLabel: manager.name,
        onTap: onTap,
        topLeading: SymbolGridPips(
          count: _managerRarityScore(manager.rarity) + 1,
          tint: LightcorePalette.flare,
        ),
        topTrailing: SymbolGridBadge(
          tint: assignedHere ? LightcorePalette.layer2 : LightcorePalette.flare,
          shape: BoxShape.circle,
          size: 22,
          child: Icon(assignedHere ? Icons.check_rounded : Icons.tune_rounded),
        ),
        center: Stack(
          alignment: Alignment.bottomRight,
          children: [
            ManagerPortrait(
              seed: manager.config.id,
              name: manager.config.name,
              tint: LightcorePalette.flare,
              icon: _enemyManagerIcon(manager),
              family: ManagerPortraitFamily.threat,
              assetPath: manager.config.portraitAssetPath,
              size: 50,
            ),
            if (manager.targetAffinity != null)
              AffinityGlyph(affinity: manager.targetAffinity!, size: 16),
          ],
        ),
        bottomChildren: [
          _deltaBadge(
            icon: Icons.groups_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.spawnRateMultiplier,
                ) -
                1,
          ),
          _deltaBadge(
            icon: Icons.workspace_premium_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.rewardMultiplier,
                ) -
                1,
          ),
          _deltaBadge(
            icon: Icons.trending_up_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.experienceMultiplier,
                ) -
                1,
          ),
          _deltaBadge(
            icon: Icons.favorite_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.healthMultiplier,
                ) -
                1,
          ),
          _deltaBadge(
            icon: Icons.speed_rounded,
            delta:
                controller.managerPowerAdjustedMultiplier(
                  manager.speedMultiplier,
                ) -
                1,
          ),
        ],
      ),
    );
  }
}

class _LockedTowerManagerGlyphTile extends StatelessWidget {
  const _LockedTowerManagerGlyphTile({
    required this.config,
    required this.onTap,
  });

  final CardConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SymbolGridTile(
      tint: LightcorePalette.aether,
      locked: true,
      semanticLabel: 'Locked Core Manager ${config.name}',
      onTap: onTap,
      topLeading: SymbolGridBadge(
        tint: LightcorePalette.aether,
        child: const Text('Locked'),
      ),
      topTrailing: const SymbolGridBadge(
        tint: LightcorePalette.aether,
        shape: BoxShape.circle,
        size: 22,
        child: Icon(Icons.lock_rounded),
      ),
      center: ManagerPortrait(
        seed: config.id,
        name: config.name,
        tint: LightcorePalette.aether,
        icon: _towerManagerIconForConfigId(config.id),
        family: ManagerPortraitFamily.core,
        assetPath: config.portraitAssetPath,
        size: 50,
      ),
      bottomChildren: [
        SymbolGridBadge(
          tint: LightcorePalette.aether,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 74),
            child: Text(config.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

class _LockedEnemyManagerGlyphTile extends StatelessWidget {
  const _LockedEnemyManagerGlyphTile({
    required this.config,
    required this.onTap,
  });

  final EnemyManagerConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SymbolGridTile(
      tint: LightcorePalette.flare,
      locked: true,
      semanticLabel: 'Locked Threat Director ${config.name}',
      onTap: onTap,
      topLeading: SymbolGridBadge(
        tint: LightcorePalette.flare,
        child: const Text('Locked'),
      ),
      topTrailing: const SymbolGridBadge(
        tint: LightcorePalette.flare,
        shape: BoxShape.circle,
        size: 22,
        child: Icon(Icons.lock_rounded),
      ),
      center: ManagerPortrait(
        seed: config.id,
        name: config.name,
        tint: LightcorePalette.flare,
        icon: _enemyManagerIconForConfigId(config.id),
        family: ManagerPortraitFamily.threat,
        assetPath: config.portraitAssetPath,
        size: 50,
      ),
      bottomChildren: [
        SymbolGridBadge(
          tint: LightcorePalette.flare,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 74),
            child: Text(config.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}

Widget _deltaBadge({required IconData icon, required double delta}) {
  final positive = delta > 0.001;
  final negative = delta < -0.001;
  final tint = positive
      ? LightcorePalette.success
      : negative
      ? LightcorePalette.warning
      : LightcorePalette.mist.withValues(alpha: 0.74);

  return SymbolGridBadge(
    tint: tint,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11),
        const SizedBox(width: 2),
        Icon(
          positive
              ? Icons.arrow_upward_rounded
              : negative
              ? Icons.arrow_downward_rounded
              : Icons.remove_rounded,
          size: 10,
        ),
      ],
    ),
  );
}

Widget _rateBadge(double rate) {
  return SymbolGridBadge(
    tint: LightcorePalette.aether,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.touch_app_rounded, size: 11),
        const SizedBox(width: 2),
        Text(rate.toStringAsFixed(2)),
      ],
    ),
  );
}

String _managerRarityLabel(ManagerRarity rarity) => switch (rarity) {
  ManagerRarity.common => 'Common',
  ManagerRarity.uncommon => 'Uncommon',
  ManagerRarity.rare => 'Rare',
  ManagerRarity.epic => 'Epic',
  ManagerRarity.legendary => 'Legendary',
};

int _managerRarityScore(ManagerRarity rarity) => switch (rarity) {
  ManagerRarity.common => 0,
  ManagerRarity.uncommon => 1,
  ManagerRarity.rare => 2,
  ManagerRarity.epic => 3,
  ManagerRarity.legendary => 4,
};

IconData _towerManagerIcon(InventoryCard manager) =>
    _towerManagerIconForConfigId(manager.config.id);

IconData _towerManagerIconForConfigId(String configId) => switch (configId) {
  'flux_coil' => Icons.hub_rounded,
  'impact_prism' => Icons.flash_on_rounded,
  'quick_relay' => Icons.timer_rounded,
  'spectrum_seal' => Icons.auto_awesome_rounded,
  'anchor_array' => Icons.shield_rounded,
  'pulse_broker' => Icons.blur_circular_rounded,
  'overload_lens' => Icons.center_focus_strong_rounded,
  _ => Icons.auto_awesome_rounded,
};

IconData _enemyManagerIcon(EnemyManagerState manager) =>
    _enemyManagerIconForConfigId(manager.config.id);

IconData _enemyManagerIconForConfigId(String configId) => switch (configId) {
  'swarm_broker' => Icons.groups_rounded,
  'extractor' => Icons.workspace_premium_rounded,
  'phase_script' => Icons.blur_on_rounded,
  'regen_director' => Icons.healing_rounded,
  'gravity_director' => Icons.public_rounded,
  'greed_director' => Icons.diamond_rounded,
  'saboteur_director' => Icons.warning_rounded,
  'volatile_director' => Icons.flare_rounded,
  'apex_herald' => Icons.radio_button_checked_rounded,
  'pursuit_script' => Icons.speed_rounded,
  'ballast_field' => Icons.shield_rounded,
  'fracture_bloom' => Icons.local_fire_department_rounded,
  _ => Icons.tune_rounded,
};

class _ManagerDetailHeader extends StatelessWidget {
  const _ManagerDetailHeader({
    required this.portrait,
    required this.name,
    required this.roleLabel,
    required this.roleTint,
    required this.rarityLabel,
  });

  final Widget portrait;
  final String name;
  final String roleLabel;
  final Color roleTint;
  final String rarityLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        portrait,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                roleLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: roleTint),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _Badge(label: rarityLabel, tint: roleTint),
      ],
    );
  }
}

class _ManagerBioBubble extends StatelessWidget {
  const _ManagerBioBubble({required this.text, required this.tint});

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: LightcorePalette.mist.withValues(alpha: 0.9),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LockedTowerManagerDetailSheet extends StatelessWidget {
  const _LockedTowerManagerDetailSheet({required this.config});

  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerDetailHeader(
          portrait: ManagerPortrait(
            seed: config.id,
            name: config.name,
            tint: LightcorePalette.aether,
            icon: _towerManagerIconForConfigId(config.id),
            family: ManagerPortraitFamily.core,
            assetPath: config.portraitAssetPath,
            size: 86,
          ),
          name: config.name,
          roleLabel: config.roleLabel,
          roleTint: LightcorePalette.aether,
          rarityLabel: 'Locked',
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(label: 'Locked'),
            _InfoChip(label: 'Core Manager'),
            _InfoChip(label: 'Foundry roll'),
          ],
        ),
        const SizedBox(height: 14),
        _ManagerBioBubble(
          text: config.flavorBio,
          tint: LightcorePalette.aether,
        ),
        const SizedBox(height: 14),
        Text(config.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              label: 'Power ${_signedPercent(config.powerMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Charge ${_signedPercent(config.chargeMultiplier - 1)}',
            ),
            _InfoChip(
              label:
                  'Cooldown ${_signedPercent(1 - config.cooldownMultiplier)}',
            ),
            _InfoChip(
              label:
                  'Matchup ${_signedPercent(config.advantageMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Automation ${config.automationRate.toStringAsFixed(2)}/s',
            ),
          ],
        ),
      ],
    );
  }
}

class _LockedEnemyManagerDetailSheet extends StatelessWidget {
  const _LockedEnemyManagerDetailSheet({required this.config});

  final EnemyManagerConfig config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerDetailHeader(
          portrait: ManagerPortrait(
            seed: config.id,
            name: config.name,
            tint: LightcorePalette.flare,
            icon: _enemyManagerIconForConfigId(config.id),
            family: ManagerPortraitFamily.threat,
            assetPath: config.portraitAssetPath,
            size: 86,
          ),
          name: config.name,
          roleLabel: config.roleLabel,
          roleTint: LightcorePalette.flare,
          rarityLabel: 'Locked',
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(label: 'Locked'),
            _InfoChip(label: 'Threat Director'),
            _InfoChip(label: 'Foundry roll'),
          ],
        ),
        const SizedBox(height: 14),
        _ManagerBioBubble(text: config.flavorBio, tint: LightcorePalette.flare),
        const SizedBox(height: 14),
        Text(config.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              label: 'Spawn ${_signedPercent(config.spawnRateMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Reward ${_signedPercent(config.rewardMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'EXP ${_signedPercent(config.experienceMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Health ${_signedPercent(config.healthMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Speed ${_signedPercent(config.speedMultiplier - 1)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _TowerManagerDetailSheet extends StatelessWidget {
  const _TowerManagerDetailSheet({
    required this.controller,
    required this.manager,
    required this.onAssign,
    required this.onUnequip,
    required this.onDismantle,
  });

  final LightcoreController controller;
  final InventoryCard manager;
  final VoidCallback? onAssign;
  final VoidCallback? onUnequip;
  final VoidCallback onDismantle;

  @override
  Widget build(BuildContext context) {
    final assignedHere =
        controller.towerCoreManager?.instanceId == manager.instanceId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerDetailHeader(
          portrait: ManagerPortrait(
            seed: manager.config.id,
            name: manager.config.name,
            tint: LightcorePalette.aether,
            icon: _towerManagerIcon(manager),
            family: ManagerPortraitFamily.core,
            assetPath: manager.config.portraitAssetPath,
            size: 86,
          ),
          name: manager.name,
          roleLabel: manager.roleLabel,
          roleTint: LightcorePalette.aether,
          rarityLabel: _managerRarityLabel(manager.rarity),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(label: _towerManagerStatus(controller, manager)),
            const _InfoChip(label: 'All towers'),
          ],
        ),
        const SizedBox(height: 14),
        _ManagerBioBubble(
          text: manager.config.flavorBio,
          tint: LightcorePalette.aether,
        ),
        const SizedBox(height: 14),
        Text(manager.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              label:
                  'Power ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.powerMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'Charge ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.chargeMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'Cooldown ${_signedPercent(1 - controller.managerPowerAdjustedCooldown(manager.cooldownMultiplier))}',
            ),
            _InfoChip(
              label:
                  'Matchup ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.advantageMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'Automation ${controller.managerPowerAdjustedRate(manager.automationRate).toStringAsFixed(2)}/s',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GuidedFocusFrame(
              active: controller.tutorialHighlightsTowerManagerAssign,
              tint: LightcorePalette.quest,
              child: FilledButton(
                onPressed: !controller.managerAssignmentUnlocked || assignedHere
                    ? null
                    : onAssign,
                child: Text(
                  !controller.managerAssignmentUnlocked
                      ? 'Locked until Core Lv ${LightcoreController.managerCoreLevelRequirement}'
                      : assignedHere
                      ? 'Equipped to Core'
                      : 'Assign to Tower Core',
                ),
              ),
            ),
            if (onUnequip != null)
              OutlinedButton(
                onPressed: onUnequip,
                child: const Text('Unequip'),
              ),
            OutlinedButton(
              onPressed: onDismantle,
              child: Text(
                'Dismantle • ${manager.dismantleFlux} ${LightcoreCurrencyLabels.flux}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EnemyManagerDetailSheet extends StatelessWidget {
  const _EnemyManagerDetailSheet({
    required this.controller,
    required this.manager,
    required this.onAssign,
    required this.onRemove,
    required this.onDismantle,
  });

  final LightcoreController controller;
  final EnemyManagerState manager;
  final VoidCallback? onAssign;
  final VoidCallback? onRemove;
  final VoidCallback onDismantle;

  @override
  Widget build(BuildContext context) {
    final assignedHere =
        controller.enemyCoreManager?.instanceId == manager.instanceId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerDetailHeader(
          portrait: ManagerPortrait(
            seed: manager.config.id,
            name: manager.config.name,
            tint: LightcorePalette.flare,
            icon: _enemyManagerIcon(manager),
            family: ManagerPortraitFamily.threat,
            assetPath: manager.config.portraitAssetPath,
            size: 86,
          ),
          name: manager.name,
          roleLabel: manager.roleLabel,
          roleTint: LightcorePalette.flare,
          rarityLabel: _managerRarityLabel(manager.rarity),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(label: _enemyManagerStatus(controller, manager)),
            const _InfoChip(label: 'All enemies'),
          ],
        ),
        const SizedBox(height: 14),
        _ManagerBioBubble(
          text: manager.config.flavorBio,
          tint: LightcorePalette.flare,
        ),
        const SizedBox(height: 14),
        Text(manager.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              label:
                  'Spawn ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.spawnRateMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'Reward ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.rewardMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'EXP ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.experienceMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'Health ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.healthMultiplier) - 1)}',
            ),
            _InfoChip(
              label:
                  'Speed ${_signedPercent(controller.managerPowerAdjustedMultiplier(manager.speedMultiplier) - 1)}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GuidedFocusFrame(
              active: controller.tutorialHighlightsEnemyManagerAssign,
              tint: LightcorePalette.quest,
              child: FilledButton(
                onPressed: !controller.managerAssignmentUnlocked || assignedHere
                    ? null
                    : onAssign,
                child: Text(
                  !controller.managerAssignmentUnlocked
                      ? 'Locked until Core Lv ${LightcoreController.managerCoreLevelRequirement}'
                      : assignedHere
                      ? 'Assigned to Core'
                      : 'Assign to Tower Core',
                ),
              ),
            ),
            if (onRemove != null)
              OutlinedButton(onPressed: onRemove, child: const Text('Remove')),
            OutlinedButton(
              onPressed: onDismantle,
              child: Text(
                'Dismantle • ${manager.dismantleFlux} ${LightcoreCurrencyLabels.flux}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tint,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
