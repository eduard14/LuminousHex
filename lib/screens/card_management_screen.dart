import 'package:flutter/material.dart';

import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../services/lightcore_rewarded_ads.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/guided_focus_frame.dart';
import '../widgets/lightcore_detail_sheet.dart';
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
                  : 'Manager assignment unlocks as soon as the active core reaches Layer 2. Flux still banks now so the foundry is ready when it opens.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lumens ${controller.lumens}  •  ${LightcoreCurrencyLabels.flux} ${controller.flux}  •  ${LightcoreCurrencyLabels.scansShort} ${controller.enemyTickets}  •  ${controller.activeLayerLabel}',
              style: textTheme.labelLarge?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Tower Core Sockets',
              tint: LightcorePalette.aether,
              subtitle: !controller.managerAssignmentUnlocked
                  ? 'Reach a Layer 2 Core before tower sockets can take managers.'
                  : 'Managers are mounted on the core and broadcast their effects across the whole active shell.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CoreSocketTile(
                  tint: LightcorePalette.aether,
                  icon: Icons.auto_awesome_rounded,
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
                  icon: Icons.tune_rounded,
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
              title: 'Tower Upgraders',
              tint: LightcorePalette.violet,
              subtitle: !controller.managerAssignmentUnlocked
                  ? 'Reach a Layer 2 Core before Core Managers can be assigned.'
                  : controller.cards.isEmpty
                  ? 'No Core Managers in inventory yet.'
                  : 'Tap a tile to inspect the roll, then assign it directly to the Tower Core.',
            ),
            const SizedBox(height: 10),
            if (controller.cards.isEmpty)
              _InlineSectionNotice(
                message: controller.managersUnlocked
                    ? 'Forge a Core Manager when you have enough Flux.'
                    : 'No Core Managers in inventory. The foundry unlocks at Account Radiance Lv ${LightcoreController.managerUnlockLevel}.',
                tint: LightcorePalette.violet,
              )
            else
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
                ],
              ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Threat Directors',
              tint: LightcorePalette.warning,
              subtitle: !controller.managerAssignmentUnlocked
                  ? 'Reach a Layer 2 Core before Threat Directors can be assigned.'
                  : controller.enemyManagers.isEmpty
                  ? 'No Threat Directors in inventory yet.'
                  : 'Tap a tile to inspect the roll, then assign it to the Tower Core for all enemies.',
            ),
            const SizedBox(height: 10),
            if (controller.enemyManagers.isEmpty)
              _InlineSectionNotice(
                message: controller.managersUnlocked
                    ? 'Forge a Threat Director when you have enough Flux.'
                    : 'No Threat Directors in inventory. The foundry unlocks at Account Radiance Lv ${LightcoreController.managerUnlockLevel}.',
                tint: LightcorePalette.warning,
              )
            else
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
                ],
              ),
            const SizedBox(height: 18),
            _ManagerSectionHeader(
              title: 'Foundry',
              tint: LightcorePalette.solar,
              subtitle: controller.managersUnlocked
                  ? 'Forge new rolls or top off Flux after you have already chosen what they should improve.'
                  : 'The foundry unlocks at Account Radiance Lv ${LightcoreController.managerUnlockLevel}. Flux still banks now so it has real fuel when it comes online.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                GuidedFocusFrame(
                  active: controller.tutorialHighlightsTowerManagerForge,
                  tint: LightcorePalette.quest,
                  child: FilledButton.icon(
                    onPressed: controller.canForgeTowerManager
                        ? controller.forgeTowerManager
                        : null,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      'Forge Core Manager • ${LightcoreController.towerManagerFluxCost} ${LightcoreCurrencyLabels.flux}',
                    ),
                  ),
                ),
                GuidedFocusFrame(
                  active: controller.tutorialHighlightsEnemyManagerForge,
                  tint: LightcorePalette.quest,
                  child: FilledButton.icon(
                    onPressed: controller.canForgeEnemyManager
                        ? controller.forgeEnemyManager
                        : null,
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      'Forge Threat Director • ${LightcoreController.enemyManagerFluxCost} ${LightcoreCurrencyLabels.flux}',
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: LightcoreRewardedAds.isSupportedPlatform
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
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: Text(
                    'Watch Ad • ${LightcoreCurrencyLabels.rewardFlux(rewardedFluxGrant)}',
                  ),
                ),
              ],
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

class _CoreSocketTile extends StatelessWidget {
  const _CoreSocketTile({
    required this.tint,
    required this.icon,
    required this.badgeIcon,
    required this.semanticLabel,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final Color tint;
  final IconData icon;
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
      center: Icon(icon, color: tint, size: 40),
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
            Icon(
              _towerManagerIcon(manager),
              size: 38,
              color: LightcorePalette.aether,
            ),
            if (manager.favoredAffinity != null)
              AffinityGlyph(affinity: manager.favoredAffinity!, size: 16),
          ],
        ),
        bottomChildren: [
          _deltaBadge(
            icon: Icons.flash_on_rounded,
            delta: manager.powerMultiplier - 1,
          ),
          _deltaBadge(
            icon: Icons.blur_circular_rounded,
            delta: manager.chargeMultiplier - 1,
          ),
          _deltaBadge(
            icon: Icons.timer_rounded,
            delta: 1 - manager.cooldownMultiplier,
          ),
          _deltaBadge(
            icon: Icons.adjust_rounded,
            delta: manager.advantageMultiplier - 1,
          ),
          _rateBadge(manager.automationRate),
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
            Icon(
              _enemyManagerIcon(manager),
              size: 38,
              color: LightcorePalette.flare,
            ),
            if (manager.targetAffinity != null)
              AffinityGlyph(affinity: manager.targetAffinity!, size: 16),
          ],
        ),
        bottomChildren: [
          _deltaBadge(
            icon: Icons.groups_rounded,
            delta: manager.spawnRateMultiplier - 1,
          ),
          _deltaBadge(
            icon: Icons.workspace_premium_rounded,
            delta: manager.rewardMultiplier - 1,
          ),
          _deltaBadge(
            icon: Icons.trending_up_rounded,
            delta: manager.experienceMultiplier - 1,
          ),
          _deltaBadge(
            icon: Icons.favorite_rounded,
            delta: manager.healthMultiplier - 1,
          ),
          _deltaBadge(
            icon: Icons.speed_rounded,
            delta: manager.speedMultiplier - 1,
          ),
        ],
      ),
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
    switch (manager.config.id) {
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
    switch (manager.config.id) {
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manager.roleLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.aether,
                    ),
                  ),
                ],
              ),
            ),
            _Badge(
              label: _managerRarityLabel(manager.rarity),
              tint: LightcorePalette.aether,
            ),
          ],
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
        Text(manager.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              label: 'Power ${_signedPercent(manager.powerMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Charge ${_signedPercent(manager.chargeMultiplier - 1)}',
            ),
            _InfoChip(
              label:
                  'Cooldown ${_signedPercent(1 - manager.cooldownMultiplier)}',
            ),
            _InfoChip(
              label:
                  'Matchup ${_signedPercent(manager.advantageMultiplier - 1)}',
            ),
            _InfoChip(
              label:
                  'Automation ${manager.automationRate.toStringAsFixed(2)}/s',
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
                      ? 'Locked until Layer 2 Core'
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manager.roleLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LightcorePalette.flare,
                    ),
                  ),
                ],
              ),
            ),
            _Badge(
              label: _managerRarityLabel(manager.rarity),
              tint: LightcorePalette.flare,
            ),
          ],
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
        Text(manager.summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              label: 'Spawn ${_signedPercent(manager.spawnRateMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Reward ${_signedPercent(manager.rewardMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'EXP ${_signedPercent(manager.experienceMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Health ${_signedPercent(manager.healthMultiplier - 1)}',
            ),
            _InfoChip(
              label: 'Speed ${_signedPercent(manager.speedMultiplier - 1)}',
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
                      ? 'Locked until Layer 2 Core'
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
