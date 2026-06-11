import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_config.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/layer_one_component_forecast_panel.dart';
import '../widgets/lightcore_info_button.dart';
import '../widgets/meter_bar.dart';

class AdvancementScreen extends StatefulWidget {
  const AdvancementScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.scrollController,
    this.onPromotionRequested,
  });

  final LightcoreController controller;
  final bool isActive;
  final ScrollController? scrollController;
  final VoidCallback? onPromotionRequested;

  @override
  State<AdvancementScreen> createState() => _AdvancementScreenState();
}

enum _ComponentSortMode { newest, wave, scroll }

class _AdvancementScreenState extends State<AdvancementScreen> {
  _ComponentSortMode _componentSortMode = _ComponentSortMode.wave;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final textTheme = Theme.of(context).textTheme;

    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final canUnlock = controller.canUnlockLayer2;
        final unlocked =
            controller.activeLayer.tier > 1 ||
            controller.activeLayer.promotedParentLayerId != null;

        return ListView(
          key: const PageStorageKey<String>('advancement-scroll'),
          controller: widget.scrollController,
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            AuroraPanel(
              tint: LightcorePalette.layer2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Layer 2 Components',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const LightcoreInfoButton(
                        title: 'Component Merge Help',
                        message: _advancementPathHelp,
                        tint: LightcorePalette.layer2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MeterBar(
                    value: controller.ringProgress,
                    color: LightcorePalette.layer2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.activeLayerLabel} • ${controller.builtTowerCount}/${LightcoreController.slotCount} anchors built',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  MeterBar(
                    value: controller.promotionProgress,
                    color: LightcorePalette.solar,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.promotionStatusLabel,
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            AuroraPanel(
              tint: unlocked
                  ? LightcorePalette.success
                  : LightcorePalette.solar,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unlocked ? 'Advancement Active' : 'Advancement Gate',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      const LightcoreInfoButton(
                        title: 'Component Rules',
                        message: _promotionRulesHelp,
                        tint: LightcorePalette.solar,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const _BenefitChip(label: 'Seven-part merge inputs'),
                      _BenefitChip(
                        label: controller.activeLayerPassiveOnly
                            ? 'Viewed shell is passive'
                            : 'Viewed shell runs live',
                      ),
                      _BenefitChip(
                        label: controller.activeLayerHasParentSlot
                            ? 'Target output: ${controller.activeLayerTargetShellLabel}'
                            : controller.activeLayer.promotedParentLayerId !=
                                  null
                            ? 'Source shell is passive'
                            : unlocked
                            ? 'Current core: ${controller.coreProjectileLabel} / ${controller.corePayloadLabel}'
                            : 'Component rolls from Layer 1',
                      ),
                      _BenefitChip(
                        label:
                            'Lower shells: ${controller.passiveLumenPerSecond.toStringAsFixed(1)} passive L/s',
                      ),
                      _BenefitChip(label: controller.payloadUnlockLabel),
                      _BenefitChip(label: controller.managerUnlockLabel),
                      _BenefitChip(
                        label:
                            'Edge slots: ${controller.unlockedOuterSlotCount}/${LightcoreController.slotCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayerOneComponentForecastPanel(controller: controller),
                  const SizedBox(height: 18),
                  if (canUnlock)
                    _PromotionActionButton(
                      tint: LightcorePalette.solar,
                      label: controller.promotionActionLabel,
                      controller: controller,
                      onPressed:
                          widget.onPromotionRequested ??
                          controller.unlockLayer2Tower,
                    )
                  else if (controller.activeLayerPromotedIntoParentSlot)
                    FilledButton.icon(
                      onPressed: controller.unlockLayer2Tower,
                      icon: const Icon(Icons.unfold_less_double_rounded),
                      label: const Text('Return to Parent Shell'),
                    )
                  else if (controller.activeLayer.promotedParentLayerId != null)
                    FilledButton.icon(
                      onPressed: controller.unlockLayer2Tower,
                      icon: const Icon(Icons.unfold_more_double_rounded),
                      label: const Text('Enter Higher Shell'),
                    )
                  else if (!unlocked)
                    OutlinedButton(
                      onPressed: null,
                      child: Text(
                        controller.builtTowerCount <
                                LightcoreController.slotCount
                            ? 'Need ${LightcoreController.slotCount - controller.builtTowerCount} more surrounding towers'
                            : 'Need ${LightcoreController.slotCount - controller.promotionReadyTowerCount} more towers at level ${LightcoreController.maxTowerLevel}',
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: null,
                      child: Text(
                        'Core Traits • ${controller.coreProjectileLabel} / ${controller.corePayloadLabel}',
                      ),
                    ),
                  if (controller.canScrapActiveLayer) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: controller.scrapActiveLayer,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Scrap This Shell'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Layer2ComponentInventoryPanel(
              controller: controller,
              sortMode: _componentSortMode,
              onSortModeChanged: (mode) {
                setState(() => _componentSortMode = mode);
              },
            ),
          ],
        );
      },
    );
  }
}

const String _advancementPathHelp =
    'Layer 1 tower composition creates Layer 2 components. Projectile and payload roll independently from the completed tower mix, while the best reached wave sets the component Layer 2 level and subtrait count.\n\nCompleted lower shells remain inspectable as source history. The current shell scaffold still opens higher construction space, but the farmable reward is the Layer 2 component roll.';

const String _promotionRulesHelp =
    'Component merges require all six edge towers at max level. Pure tower mixes produce pure projectile and payload odds; mixed colors can create combinations such as one color projectile with another color payload. Higher Layer 1 waves improve the generated component tier.';

class _Layer2ComponentInventoryPanel extends StatelessWidget {
  const _Layer2ComponentInventoryPanel({
    required this.controller,
    required this.sortMode,
    required this.onSortModeChanged,
  });

  final LightcoreController controller;
  final _ComponentSortMode sortMode;
  final ValueChanged<_ComponentSortMode> onSortModeChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final components = controller.layer2Components.toList(growable: false);
    final sorted = components.toList(growable: true);
    sorted.sort((left, right) {
      final equippedCompare = (right.equippedRegionId != null ? 1 : 0)
          .compareTo(left.equippedRegionId != null ? 1 : 0);
      if (equippedCompare != 0) {
        return equippedCompare;
      }
      return switch (sortMode) {
        _ComponentSortMode.newest => right.createdAtMillis.compareTo(
          left.createdAtMillis,
        ),
        _ComponentSortMode.wave => right.reachedWave.compareTo(
          left.reachedWave,
        ),
        _ComponentSortMode.scroll => right.scrollLevel.compareTo(
          left.scrollLevel,
        ),
      };
    });

    return AuroraPanel(
      tint: LightcorePalette.layer2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Component Inventory', style: textTheme.titleLarge),
              ),
              const LightcoreInfoButton(
                title: 'Layer 2 Component Inventory',
                message:
                    'Components are the farmable output of Layer 1 merges. Equip one component to each revealed map area to raise its idle farm output. Bosses from Layer 2 and higher award Component Scrolls, which upgrade good rolls. Favorite components cannot be dismantled.',
                tint: LightcorePalette.layer2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BenefitChip(
                label: '${controller.componentScrolls} Component Scrolls',
              ),
              _BenefitChip(label: '${components.length} stored rolls'),
              SizedBox(
                width: 185,
                child: DropdownButtonFormField<_ComponentSortMode>(
                  initialValue: sortMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: _ComponentSortMode.wave,
                      child: Text('Best wave'),
                    ),
                    DropdownMenuItem(
                      value: _ComponentSortMode.scroll,
                      child: Text('Scroll level'),
                    ),
                    DropdownMenuItem(
                      value: _ComponentSortMode.newest,
                      child: Text('Newest'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSortModeChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            Text(
              'Create a Layer 2 component from a completed Layer 1 shell to begin assigning area farm traits.',
              style: textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.78),
              ),
            )
          else
            ...sorted.map(
              (component) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Layer2ComponentInventoryCard(
                  controller: controller,
                  component: component,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Layer2ComponentInventoryCard extends StatelessWidget {
  const _Layer2ComponentInventoryCard({
    required this.controller,
    required this.component,
  });

  final LightcoreController controller;
  final Layer2ComponentState component;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final equippedRegion = component.equippedRegionId == null
        ? null
        : controller.threatRegionConfigById(component.equippedRegionId!);
    final revealedRegions = controller.threatRegions
        .where((state) => state.revealed)
        .map((state) => controller.threatRegionConfigById(state.regionId))
        .whereType<ThreatRegionConfig>()
        .toList(growable: false);
    final upgradeCost = controller.componentScrollUpgradeCost(component);
    final canUpgrade = controller.canUpgradeLayer2Component(component.id);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: component.favorite
              ? LightcorePalette.solar.withValues(alpha: 0.5)
              : LightcorePalette.stroke.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        component.signatureLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: LightcorePalette.layer2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wave ${component.reachedWave} • Layer 2 Lv ${component.reachedWave ~/ 10} • Scroll ${component.scrollLevel}',
                        style: textTheme.bodySmall?.copyWith(
                          color: LightcorePalette.mist.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: component.favorite
                      ? 'Unfavorite component'
                      : 'Favorite component',
                  onPressed: () =>
                      controller.toggleLayer2ComponentFavorite(component.id),
                  icon: Icon(
                    component.favorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: component.favorite
                        ? LightcorePalette.solar
                        : LightcorePalette.mist,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ComponentStatChip(
                  label: controller.layer2ComponentOutputLabel(component),
                ),
                _ComponentStatChip(
                  label: equippedRegion == null
                      ? 'Unassigned'
                      : 'Assigned: ${equippedRegion.name}',
                ),
                _ComponentStatChip(
                  label:
                      '${component.projectileType.label} / ${component.payloadType.label}',
                ),
              ],
            ),
            if (component.subtraits.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: component.subtraits
                    .map(
                      (trait) => _ComponentStatChip(
                        label:
                            '${trait.type.label} +${(trait.value * 100).toStringAsFixed(1)}%',
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Assign component to an area',
                  onSelected: (value) {
                    if (value.isEmpty) {
                      controller.unequipLayer2Component(component.id);
                    } else {
                      controller.equipLayer2ComponentToRegion(
                        componentId: component.id,
                        regionId: value,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (component.equippedRegionId != null)
                      const PopupMenuItem(value: '', child: Text('Unassign')),
                    for (final region in revealedRegions)
                      PopupMenuItem(value: region.id, child: Text(region.name)),
                  ],
                  child: _ComponentActionShell(
                    icon: Icons.public_rounded,
                    label: equippedRegion == null
                        ? 'Assign Area'
                        : 'Change Area',
                  ),
                ),
                FilledButton.icon(
                  onPressed: canUpgrade
                      ? () => controller.upgradeLayer2Component(component.id)
                      : null,
                  icon: const Icon(Icons.upgrade_rounded),
                  label: Text('Upgrade • $upgradeCost'),
                ),
                OutlinedButton.icon(
                  onPressed: component.favorite
                      ? null
                      : () => _confirmScrap(context, controller, component),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    'Dismantle • ${controller.componentScrapScrollValue(component)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmScrap(
    BuildContext context,
    LightcoreController controller,
    Layer2ComponentState component,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismantle Component?'),
        content: Text(
          'This removes ${component.signatureLabel} and returns ${controller.componentScrapScrollValue(component)} Component Scrolls.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dismantle'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.scrapLayer2Component(component.id);
    }
  }
}

class _ComponentStatChip extends StatelessWidget {
  const _ComponentStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: LightcorePalette.mist,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ComponentActionShell extends StatelessWidget {
  const _ComponentActionShell({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LightcorePalette.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionActionButton extends StatefulWidget {
  const _PromotionActionButton({
    required this.tint,
    required this.label,
    required this.controller,
    required this.onPressed,
  });

  final Color tint;
  final String label;
  final LightcoreController controller;
  final VoidCallback onPressed;

  @override
  State<_PromotionActionButton> createState() => _PromotionActionButtonState();
}

class _PromotionActionButtonState extends State<_PromotionActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    await _controller.forward(from: 0);
    if (!mounted) {
      return;
    }
    widget.onPressed();
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  void _showRatesDialog() {
    final controller = widget.controller;
    showDialog<void>(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        final payloadRates = controller.promotionPayloadAffinityRates;
        return AlertDialog(
          title: const Text('Component Roll Rates'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PromotionRateRow(
                  label: 'Rainbow',
                  value: controller.promotionRainbowResultChance,
                  color: LightcorePalette.layer2,
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 12),
                const _PromotionRatesSectionLabel(label: 'Projectile Odds'),
                const SizedBox(height: 6),
                ...controller.promotionProjectileAffinityRates.entries.map(
                  (entry) => _PromotionRateRow(
                    label: entry.key.label,
                    value: entry.value,
                    color: entry.key.color,
                  ),
                ),
                if (payloadRates.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _PromotionRatesSectionLabel(label: 'Payload Odds'),
                  const SizedBox(height: 6),
                  ...payloadRates.entries.map(
                    (entry) => _PromotionRateRow(
                      label: entry.key.label,
                      value: entry.value,
                      color: entry.key.color,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Projectile and payload roll independently from the Layer 1 tower mix.',
                  style: textTheme.bodySmall?.copyWith(
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

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 310),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _busy
                  ? Curves.easeInOutCubic.transform(_controller.value)
                  : 0.0;
              return _ShellFusionPreview(tint: widget.tint, progress: progress);
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _handlePressed,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(_busy ? 'Creating Component' : widget.label),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Show merge rates',
                onPressed: _busy ? null : _showRatesDialog,
                icon: const Icon(Icons.info_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromotionRatesSectionLabel extends StatelessWidget {
  const _PromotionRatesSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: LightcorePalette.solar,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PromotionRateRow extends StatelessWidget {
  const _PromotionRateRow({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: icon == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LightcorePalette.mist.withValues(alpha: 0.26),
                      ),
                    ),
                  )
                : Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatPromotionRate(value),
            style: textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPromotionRate(double value) {
  final percent = value * 100;
  if ((percent - percent.round()).abs() < 0.05) {
    return '${percent.round()}%';
  }
  return '${percent.toStringAsFixed(1)}%';
}

class _ShellFusionPreview extends StatelessWidget {
  const _ShellFusionPreview({required this.tint, required this.progress});

  final Color tint;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 86,
      child: CustomPaint(
        painter: _ShellFusionPreviewPainter(tint: tint, progress: progress),
      ),
    );
  }
}

class _ShellFusionPreviewPainter extends CustomPainter {
  const _ShellFusionPreviewPainter({
    required this.tint,
    required this.progress,
  });

  final Color tint;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final ringRadius = math.min(size.width, size.height) * 0.34;
    final pull = progress.clamp(0.0, 1.0);
    final glow = math.sin(pull * math.pi);
    final nodeRadius = math.min(size.width, size.height) * 0.075;

    canvas.drawPath(
      _hexPath(center, ringRadius * (0.56 + (pull * 0.18))),
      Paint()
        ..style = PaintingStyle.fill
        ..color = tint.withValues(alpha: 0.08 + (glow * 0.14)),
    );

    for (var index = 0; index < 6; index += 1) {
      final angle = (-math.pi / 2) + (index * math.pi / 3);
      final outer = Offset(
        center.dx + math.cos(angle) * ringRadius,
        center.dy + math.sin(angle) * ringRadius,
      );
      final folded = Offset(
        center.dx + math.cos(angle) * (ringRadius * 0.36),
        center.dy + math.sin(angle) * (ringRadius * 0.36),
      );
      final node = Offset.lerp(outer, folded, pull)!;
      canvas.drawLine(
        outer,
        node,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + (glow * 1.2)
          ..strokeCap = StrokeCap.round
          ..color = tint.withValues(alpha: 0.18 + (glow * 0.28)),
      );
      canvas.drawPath(
        _hexPath(node, nodeRadius * (1 + (glow * 0.28))),
        Paint()
          ..style = PaintingStyle.fill
          ..color = tint.withValues(alpha: 0.3 + (pull * 0.52)),
      );
      canvas.drawPath(
        _hexPath(node, nodeRadius * (1.18 + (glow * 0.28))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = LightcorePalette.layer2.withValues(alpha: 0.32 + glow),
      );
    }

    canvas.drawPath(
      _hexPath(center, nodeRadius * (1.2 + (pull * 1.1))),
      Paint()
        ..style = PaintingStyle.fill
        ..color = Color.lerp(
          LightcorePalette.panelRaised,
          tint,
          0.45 + (pull * 0.5),
        )!,
    );
    canvas.drawPath(
      _hexPath(center, ringRadius * (0.96 - (pull * 0.24))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..color = tint.withValues(alpha: 0.24 + (glow * 0.5)),
    );
  }

  @override
  bool shouldRepaint(covariant _ShellFusionPreviewPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.progress != progress;

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = math.pi / 6 + (index * math.pi / 3);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.max(
      180.0,
      math.min(MediaQuery.sizeOf(context).width - 72, 520.0),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(label),
      ),
    );
  }
}
