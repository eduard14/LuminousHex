import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_currency_labels.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/meter_bar.dart';

class PrestigeScreen extends StatelessWidget {
  const PrestigeScreen({
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!isActive) {
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
          key: const PageStorageKey<String>('prestige-scroll'),
          controller: scrollController,
          children: [
            AuroraPanel(
              tint: LightcorePalette.layer2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Advancement Path', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Advancement works more like a job change than a wipe. Promotion forges the next shell class from the current ring traits while archiving the lower shell as passive support. Root Shells are projectile-only seeds, Prism Shells add rolled payload traits, Nexus Shells deepen recursive inheritance, and Ascendant Shell is the final shell tier.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every higher shell is a seven-shell cluster: the source shell plus six edge anchors. Only the highest live shell runs combat. Archived lower shells stay visible in the map and convert managed towers into reduced passive Lumens.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  MeterBar(
                    value: controller.ringProgress,
                    color: LightcorePalette.layer2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.activeLayerLabel} • ${controller.builtTowerCount}/${LightcoreController.slotCount} built',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  MeterBar(
                    value: controller.promotionProgress,
                    color: LightcorePalette.solar,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Promotion requires all ${LightcoreController.slotCount} edge towers at level ${LightcoreController.maxTowerLevel}. ${controller.promotionStatusLabel}.',
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
                  Text(
                    unlocked ? 'Advancement Active' : 'Advancement Gate',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.activeLayerHasParentSlot
                        ? controller.activeLayerPromotedIntoParentSlot
                              ? 'This shell already forged its parent-slot tower. Scrap and rebuild this shell if you want different resulting traits.'
                              : 'Finish and promote this shell to forge one adjacent ${controller.activeLayerTargetShellLabel} tower in the parent shell. Projectile and payload traits roll independently from what this shell contains.'
                        : controller.activeLayer.promotedParentLayerId != null
                        ? 'This shell already forged the next shell class and now contributes passive support.'
                        : unlocked
                        ? 'Your promoted shell is active. Lower shells remain viewable as passive support and keep their assigned anomaly decks.'
                        : 'Build the six surrounding towers, raise every edge tower to level ${LightcoreController.maxTowerLevel}, then promote manually to forge the next shell class.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      const _BenefitChip(label: 'Seven-shell clusters'),
                      const _BenefitChip(label: 'Viewed shell runs live'),
                      _BenefitChip(
                        label: controller.activeLayerHasParentSlot
                            ? 'Target output: ${controller.activeLayerTargetShellLabel}'
                            : controller.activeLayer.promotedParentLayerId !=
                                  null
                            ? 'Source shell is passive'
                            : unlocked
                            ? 'Current core: ${controller.coreProjectileLabel} / ${controller.corePayloadLabel}'
                            : 'Promotion rolls from the shell',
                      ),
                      _BenefitChip(
                        label:
                            'Lower shells: ${controller.passiveLumenPerSecond.toStringAsFixed(1)} passive L/s${controller.hasLumenHarvestPressure ? ' • Output ${controller.lumenHarvestEfficiencyLabel}' : ''}',
                      ),
                      _BenefitChip(label: controller.payloadUnlockLabel),
                      _BenefitChip(label: controller.managerUnlockLabel),
                      _BenefitChip(label: controller.echoSeedLabel),
                      _BenefitChip(
                        label:
                            'Edge slots: ${controller.unlockedOuterSlotCount}/${LightcoreController.slotCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (canUnlock)
                    _PromotionActionButton(
                      tint: LightcorePalette.solar,
                      label: controller.activeLayerHasParentSlot
                          ? 'Promote Into Parent Slot'
                          : 'Create ${controller.nextShellClassLabel}',
                      onPressed:
                          onPromotionRequested ?? controller.unlockLayer2Tower,
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
            AuroraPanel(
              tint: LightcorePalette.aether,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Rules', style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    '${LightcoreCurrencyLabels.lumens}, ${LightcoreCurrencyLabels.flux}, Threat Scans, EXP-gated edge slots, inheritable tower traits, repeatable shell advancement, and manager inventories are all part of the live loop. Promotion preserves the shell-class structure while resetting the active climb into the next build.',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PromotionActionButton extends StatefulWidget {
  const _PromotionActionButton({
    required this.tint,
    required this.label,
    required this.onPressed,
  });

  final Color tint;
  final String label;
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
          FilledButton.icon(
            onPressed: _busy ? null : _handlePressed,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_busy ? 'Aligning Shell' : widget.label),
          ),
        ],
      ),
    );
  }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LightcorePalette.panelRaised.withValues(alpha: 0.78),
      ),
      child: Text(label),
    );
  }
}
