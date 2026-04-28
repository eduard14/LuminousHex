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

enum _ThreatAssignmentTab { anomalies, apex }

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
            _ThreatAssignmentPanel(controller: controller),
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

class _ThreatAssignmentPanel extends StatefulWidget {
  const _ThreatAssignmentPanel({required this.controller});

  final LightcoreController controller;

  @override
  State<_ThreatAssignmentPanel> createState() => _ThreatAssignmentPanelState();
}

class _ThreatAssignmentPanelState extends State<_ThreatAssignmentPanel> {
  _ThreatAssignmentTab _tab = _ThreatAssignmentTab.anomalies;
  String? _expandedId;

  LightcoreController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final list = _tab == _ThreatAssignmentTab.anomalies
        ? controller.enemyCards
        : controller.bossEnemyCards;
    final title = _tab == _ThreatAssignmentTab.anomalies
        ? 'Anomaly List'
        : 'Apex List';
    final tint = _tab == _ThreatAssignmentTab.anomalies
        ? LightcorePalette.flare
        : LightcorePalette.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ManagerSectionHeader(
          title: 'Anomaly Assignment',
          tint: LightcorePalette.flare,
          subtitle:
              'Set the active anomaly deck and the main Apex for ${controller.activeLayerLabel}. Presets are saved on this core only.',
        ),
        const SizedBox(height: 10),
        _ThreatPresetBar(
          controller: controller,
          onCreate: _createPreset,
          onUpdate: _updateSelectedPreset,
          onRename: _renameSelectedPreset,
          onApply: _applySelectedPreset,
        ),
        const SizedBox(height: 10),
        _ActiveThreatLoadoutSummary(controller: controller),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    setState(() => _tab = _ThreatAssignmentTab.anomalies),
                style: FilledButton.styleFrom(
                  backgroundColor: _tab == _ThreatAssignmentTab.anomalies
                      ? LightcorePalette.flare.withValues(alpha: 0.2)
                      : null,
                ),
                icon: const Icon(Icons.radar_rounded),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Anomalies'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    setState(() => _tab = _ThreatAssignmentTab.apex),
                style: FilledButton.styleFrom(
                  backgroundColor: _tab == _ThreatAssignmentTab.apex
                      ? LightcorePalette.warning.withValues(alpha: 0.2)
                      : null,
                ),
                icon: const Icon(Icons.shield_moon_rounded),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Apex'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _EnemySectionLikeHeader(title: title, tint: tint, count: list.length),
        const SizedBox(height: 8),
        for (final card in list) ...[
          _ThreatAssignmentRow(
            controller: controller,
            card: card,
            isApex: _tab == _ThreatAssignmentTab.apex,
            expanded:
                _expandedId ==
                '${_tab == _ThreatAssignmentTab.apex ? 'apex' : 'anomaly'}:${card.config.id}',
            onTap: () {
              final id =
                  '${_tab == _ThreatAssignmentTab.apex ? 'apex' : 'anomaly'}:${card.config.id}';
              setState(() => _expandedId = _expandedId == id ? null : id);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _createPreset() async {
    final nextName =
        'Preset ${controller.activeThreatAssignmentPresets.length + 1}';
    final name = await _promptPresetName(
      title: 'Save Preset',
      actionLabel: 'Save',
      initialName: nextName,
    );
    if (name == null) {
      return;
    }
    controller.createThreatAssignmentPreset(name: name);
  }

  void _updateSelectedPreset() {
    final preset = controller.selectedThreatAssignmentPreset;
    if (preset == null) {
      return;
    }
    controller.updateThreatAssignmentPreset(preset.id);
  }

  Future<void> _renameSelectedPreset() async {
    final preset = controller.selectedThreatAssignmentPreset;
    if (preset == null) {
      return;
    }
    final name = await _promptPresetName(
      title: 'Rename Preset',
      actionLabel: 'Rename',
      initialName: preset.name,
    );
    if (name == null) {
      return;
    }
    controller.renameThreatAssignmentPreset(preset.id, name);
  }

  void _applySelectedPreset() {
    final preset = controller.selectedThreatAssignmentPreset;
    if (preset == null) {
      return;
    }
    controller.applyThreatAssignmentPreset(preset.id);
  }

  Future<String?> _promptPresetName({
    required String title,
    required String actionLabel,
    required String initialName,
  }) async {
    final textController = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: textController,
            autofocus: true,
            maxLength: 28,
            decoration: const InputDecoration(labelText: 'Preset name'),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    textController.dispose();
    final normalized = result?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class _ThreatPresetBar extends StatelessWidget {
  const _ThreatPresetBar({
    required this.controller,
    required this.onCreate,
    required this.onUpdate,
    required this.onRename,
    required this.onApply,
  });

  final LightcoreController controller;
  final VoidCallback onCreate;
  final VoidCallback onUpdate;
  final VoidCallback onRename;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final presets = controller.activeThreatAssignmentPresets;
    final selected = controller.selectedThreatAssignmentPreset;
    final picker = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LightcorePalette.flare.withValues(alpha: 0.24),
        ),
      ),
      child: presets.isEmpty
          ? Row(
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  size: 18,
                  color: LightcorePalette.flare,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No saved presets',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selected?.id,
                dropdownColor: LightcorePalette.panelRaised,
                iconEnabledColor: LightcorePalette.mist,
                items: [
                  for (final preset in presets)
                    DropdownMenuItem<String>(
                      value: preset.id,
                      child: Text(preset.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.selectThreatAssignmentPreset(value);
                  }
                },
              ),
            ),
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New'),
        ),
        FilledButton.tonalIcon(
          onPressed: selected == null ? null : onUpdate,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save'),
        ),
        IconButton.filledTonal(
          onPressed: selected == null ? null : onRename,
          tooltip: 'Rename preset',
          icon: const Icon(Icons.edit_rounded),
        ),
        FilledButton.icon(
          onPressed: selected == null ? null : onApply,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Apply'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [picker, const SizedBox(height: 8), actions],
          );
        }
        return Row(
          children: [
            Expanded(child: picker),
            const SizedBox(width: 10),
            actions,
          ],
        );
      },
    );
  }
}

class _ActiveThreatLoadoutSummary extends StatelessWidget {
  const _ActiveThreatLoadoutSummary({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final apex = controller.activeBossEnemyCard;
    final deck = controller.activeEnemyDeck;

    return LayoutBuilder(
      builder: (context, constraints) {
        final apexSlot = _ActiveThreatSlot(
          title: 'Main Apex',
          tint:
              apex?.config.secondaryAffinity?.color ??
              apex?.config.affinity.color ??
              LightcorePalette.warning,
          child: apex == null
              ? const Text('No Apex armed')
              : _ActiveThreatCardLine(card: apex, isApex: true),
        );
        final deckSlot = _ActiveThreatSlot(
          title: 'Anomaly Deck',
          tint: LightcorePalette.flare,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final card in deck)
                _MiniThreatChip(card: card, isApex: false),
            ],
          ),
        );
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [apexSlot, const SizedBox(height: 8), deckSlot],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: apexSlot),
            const SizedBox(width: 10),
            Expanded(child: deckSlot),
          ],
        );
      },
    );
  }
}

class _ActiveThreatSlot extends StatelessWidget {
  const _ActiveThreatSlot({
    required this.title,
    required this.tint,
    required this.child,
  });

  final String title;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tint,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ActiveThreatCardLine extends StatelessWidget {
  const _ActiveThreatCardLine({required this.card, required this.isApex});

  final EnemyCardState card;
  final bool isApex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AssignmentThreatGlyph(card: card, isApex: isApex, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.config.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Lv ${card.level} • ${card.config.rarity.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniThreatChip extends StatelessWidget {
  const _MiniThreatChip({required this.card, required this.isApex});

  final EnemyCardState card;
  final bool isApex;

  @override
  Widget build(BuildContext context) {
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;
    return Container(
      constraints: const BoxConstraints(maxWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AssignmentThreatGlyph(card: card, isApex: isApex, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              card.config.name,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnemySectionLikeHeader extends StatelessWidget {
  const _EnemySectionLikeHeader({
    required this.title,
    required this.tint,
    required this.count,
  });

  final String title;
  final Color tint;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Expanded(
          child: Text(
            '$title • $count shown',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThreatAssignmentRow extends StatelessWidget {
  const _ThreatAssignmentRow({
    required this.controller,
    required this.card,
    required this.isApex,
    required this.expanded,
    required this.onTap,
  });

  final LightcoreController controller;
  final EnemyCardState card;
  final bool isApex;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;
    final active = isApex
        ? controller.isBossEnemyCardActive(card.config.id)
        : controller.isEnemyCardActive(card.config.id);
    final locked = !card.isOwned;
    final status = locked
        ? 'Locked'
        : active
        ? (isApex ? 'Armed' : 'In Deck')
        : 'Available';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active || expanded
              ? tint.withValues(alpha: 0.58)
              : LightcorePalette.stroke.withValues(alpha: 0.36),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _AssignmentThreatGlyph(card: card, isApex: isApex, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.config.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${card.config.rarity.label}${isApex ? ' Apex' : ' Anomaly'} • ${card.config.affinity.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AssignmentStatusBadge(
                    label: status,
                    tint: locked
                        ? LightcorePalette.mist
                        : active
                        ? LightcorePalette.layer2
                        : tint,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: LightcorePalette.mist,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _ThreatAssignmentDetails(
                controller: controller,
                card: card,
                isApex: isApex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatAssignmentDetails extends StatelessWidget {
  const _ThreatAssignmentDetails({
    required this.controller,
    required this.card,
    required this.isApex,
  });

  final LightcoreController controller;
  final EnemyCardState card;
  final bool isApex;

  @override
  Widget build(BuildContext context) {
    return isApex ? _buildApexDetails(context) : _buildAnomalyDetails(context);
  }

  Widget _buildAnomalyDetails(BuildContext context) {
    final active = controller.isEnemyCardActive(card.config.id);
    final canUpgrade = controller.canUpgradeEnemyCard(card);
    final canMerge = controller.canMergeEnemyCard(card);
    final tint = card.config.affinity.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.config.summary, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: card.isOwned ? 'Owned' : 'Locked'),
            _InfoChip(
              label: 'Lv ${card.level}/${controller.enemyLevelCap(card)}',
            ),
            _InfoChip(label: 'Copies ${card.copies}'),
            _InfoChip(
              label: 'Threat ${controller.enemyCardThreatRatingLabel(card)}',
            ),
            _InfoChip(
              label: 'HP ${controller.enemyCardPreviewHealthLabel(card)}',
            ),
            _InfoChip(
              label: 'Lumens +${controller.enemyCardPreviewRewardLabel(card)}',
            ),
            _InfoChip(
              label: 'EXP +${controller.enemyCardPreviewExperience(card)}',
            ),
            _InfoChip(label: card.config.traitLabel),
          ],
        ),
        if (card.isOwned) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: controller.inventoryEffectSummaryLabelForCard(card),
              ),
              for (final label in controller.inventoryEffectHighlightsForCard(
                card,
                maxItems: 3,
              ))
                _InfoChip(label: label),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: card.isOwned
                  ? () => controller.toggleEnemyCardSelection(card.config.id)
                  : null,
              icon: Icon(
                active ? Icons.remove_circle_rounded : Icons.add_rounded,
              ),
              label: Text(active ? 'Remove From Deck' : 'Add To Deck'),
            ),
            FilledButton.tonalIcon(
              onPressed: canUpgrade
                  ? () => controller.upgradeEnemyCard(card.config.id)
                  : null,
              icon: const Icon(Icons.arrow_circle_up_rounded),
              label: Text(
                canUpgrade
                    ? 'Upgrade • ${controller.enemyUpgradeRequirement(card)}'
                    : 'Upgrade',
              ),
            ),
            OutlinedButton.icon(
              onPressed: canMerge
                  ? () => controller.mergeEnemyCard(card.config.id)
                  : null,
              icon: Icon(Icons.merge_type_rounded, color: tint),
              label: const Text('Fuse'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApexDetails(BuildContext context) {
    final active = controller.isBossEnemyCardActive(card.config.id);
    final canUpgrade = controller.canUpgradeBossEnemyCard(card);
    final cap = controller.bossLevelCap(card);
    final maxed = card.isOwned && card.level >= cap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.config.summary, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: card.isOwned ? 'Owned' : 'Locked'),
            _InfoChip(label: 'Lv ${card.level}/$cap'),
            _InfoChip(label: 'Copies ${card.copies}'),
            _InfoChip(label: active ? 'Armed' : 'Not armed'),
            _InfoChip(
              label: 'Threat ${controller.enemyCardThreatRatingLabel(card)}',
            ),
            _InfoChip(
              label: 'HP ${controller.enemyCardPreviewHealthLabel(card)}',
            ),
            _InfoChip(
              label: 'Lumens +${controller.enemyCardPreviewRewardLabel(card)}',
            ),
            _InfoChip(label: controller.bossCoreLabel),
            _InfoChip(label: card.config.traitLabel),
            for (final label in _assignmentBossMechanicLabels(card))
              _InfoChip(label: label),
          ],
        ),
        if (card.isOwned) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: controller.inventoryEffectSummaryLabelForCard(card),
              ),
              for (final label in controller.inventoryEffectHighlightsForCard(
                card,
                maxItems: 3,
              ))
                _InfoChip(label: label),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: !card.isOwned || active
                  ? null
                  : () => controller.tutorialArmBossEnemyCard(card.config.id),
              icon: const Icon(Icons.shield_moon_rounded),
              label: Text(
                !card.isOwned
                    ? 'Pull To Unlock'
                    : active
                    ? 'Apex Armed'
                    : 'Arm Apex',
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: canUpgrade
                  ? () => controller.upgradeBossEnemyCard(card.config.id)
                  : null,
              icon: const Icon(Icons.arrow_circle_up_rounded),
              label: Text(
                maxed
                    ? 'Maxed'
                    : 'Lv Up • ${controller.bossUpgradeRequirement(card)}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssignmentThreatGlyph extends StatelessWidget {
  const _AssignmentThreatGlyph({
    required this.card,
    required this.isApex,
    required this.size,
  });

  final EnemyCardState card;
  final bool isApex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = card.config.affinity.color;
    final secondary = card.config.secondaryAffinity?.color ?? primary;
    return Opacity(
      opacity: card.isOwned ? 1 : 0.48,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isApex ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isApex ? null : BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              primary.withValues(alpha: 0.9),
              secondary.withValues(alpha: 0.54),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: _assignmentRarityTint(
              card.config.rarity,
            ).withValues(alpha: 0.72),
            width: 1.4,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AffinityGlyph(affinity: card.config.affinity, size: size * 0.48),
            if (card.config.secondaryAffinity != null)
              Positioned(
                right: size * 0.08,
                bottom: size * 0.08,
                child: AffinityGlyph(
                  affinity: card.config.secondaryAffinity!,
                  size: size * 0.25,
                ),
              ),
            if (!isApex && card.config.splitsOnDeath)
              Positioned(
                right: 2,
                top: 2,
                child: Icon(
                  Icons.call_split_rounded,
                  size: size * 0.24,
                  color: LightcorePalette.mist,
                ),
              ),
            if (!card.isOwned)
              Icon(
                Icons.lock_rounded,
                size: size * 0.34,
                color: LightcorePalette.mist,
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentStatusBadge extends StatelessWidget {
  const _AssignmentStatusBadge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _assignmentRarityTint(EnemyCardRarity rarity) => switch (rarity) {
  EnemyCardRarity.basic => LightcorePalette.mist,
  EnemyCardRarity.uncommon => LightcorePalette.layer2,
  EnemyCardRarity.rare => LightcorePalette.aether,
  EnemyCardRarity.epic => LightcorePalette.violet,
  EnemyCardRarity.legendary => LightcorePalette.solar,
};

List<String> _assignmentBossMechanicLabels(EnemyCardState card) {
  return <String>[
    if (card.config.secondaryAffinity != null)
      '${card.config.affinity.label}/${card.config.secondaryAffinity!.label}',
    for (final immunity in card.config.immunityAffinities)
      '${immunity.label} immune',
    if (card.config.hasRegen) 'Regenerates',
    if (card.config.hasSpawnAbility) 'Spawns escorts',
    if (card.config.secondaryAffinity == null &&
        card.config.immunityAffinities.isEmpty &&
        !card.config.hasRegen &&
        !card.config.hasSpawnAbility)
      'Single-affinity Apex',
  ];
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
