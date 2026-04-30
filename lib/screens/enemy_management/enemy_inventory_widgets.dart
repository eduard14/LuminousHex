part of '../enemy_management_screen.dart';

String _bossTileProgressLabel(
  LightcoreController controller,
  EnemyCardState card,
) {
  if (!card.isOwned) {
    return 'Pull to unlock';
  }

  final cap = controller.bossLevelCap(card);
  if (card.level < cap) {
    final remaining = math.max(
      0,
      controller.bossUpgradeRequirement(card) - controller.bossCores,
    );
    return remaining == 0
        ? 'Ready for Lv ${card.level + 1}'
        : '$remaining more Heartcores';
  }

  final copiesToNextCap = controller.bossCopiesToNextCapIncrease(card);
  return copiesToNextCap == 0
      ? 'Cap maxed'
      : '$copiesToNextCap copy for +2 cap';
}

class _BulkBossLevelButton extends StatelessWidget {
  const _BulkBossLevelButton({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final readyCount = controller.upgradableBossEnemyCardCount;
    final readyLabel = readyCount == 1 ? '1 Ready' : '$readyCount Ready';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: readyCount == 0
            ? null
            : controller.upgradeAllReadyBossEnemyCards,
        icon: const Icon(Icons.keyboard_double_arrow_up_rounded),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            readyCount == 0
                ? 'Bulk Level Apex'
                : 'Bulk Level Apex • $readyLabel',
          ),
        ),
      ),
    );
  }
}

class _MassEnemyFusePanel extends StatelessWidget {
  const _MassEnemyFusePanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final levelReadyCount = controller.upgradableEnemyCardCount;
    final levelReadyLabel = levelReadyCount == 1
        ? '1 Ready'
        : '$levelReadyCount Ready';
    final readyCount = controller.mergeableEnemyCardCount;
    final readyLabel = readyCount == 1 ? '1 Ready' : '$readyCount Ready';
    final hasBulkAction = levelReadyCount > 0 || readyCount > 0;

    return AuroraPanel(
      tint: LightcorePalette.scanGlow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mass Fuse', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            !hasBulkAction
                ? 'No anomaly cards have enough copies for bulk leveling or fusion yet.'
                : 'Level every ready anomaly card, or fuse max-level cards from the bottom of the deck.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: levelReadyCount == 0
                  ? null
                  : controller.upgradeAllReadyEnemyCards,
              icon: const Icon(Icons.keyboard_double_arrow_up_rounded),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  levelReadyCount == 0
                      ? 'Bulk Level Anomalies'
                      : 'Bulk Level Anomalies • $levelReadyLabel',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _FusionActionButton(
              tint: LightcorePalette.scanGlow,
              style: _FusionActionStyle.tonalIcon,
              enabled: readyCount > 0,
              icon: Icons.merge_type_rounded,
              onPressed: controller.mergeAllReadyEnemyCards,
              label: readyCount == 0
                  ? 'Mass Fuse Anomalies'
                  : 'Mass Fuse Anomalies • $readyLabel',
            ),
          ),
        ],
      ),
    );
  }
}

enum _FusionActionStyle { outlined, tonalIcon }

class _FusionActionButton extends StatefulWidget {
  const _FusionActionButton({
    required this.tint,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.style = _FusionActionStyle.outlined,
  });

  final Color tint;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final IconData? icon;
  final _FusionActionStyle style;

  @override
  State<_FusionActionButton> createState() => _FusionActionButtonState();
}

class _FusionActionButtonState extends State<_FusionActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (_busy || !widget.enabled) {
      return;
    }
    setState(() => _busy = true);
    await _controller.forward(from: 0);
    if (!mounted) {
      return;
    }
    widget.onPressed();
    _controller.reset();
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_busy;
    final buttonLabel = _busy ? 'Fusing' : widget.label;
    final button = switch (widget.style) {
      _FusionActionStyle.outlined => OutlinedButton(
        onPressed: enabled ? _handlePressed : null,
        child: Text(buttonLabel),
      ),
      _FusionActionStyle.tonalIcon => SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: enabled ? _handlePressed : null,
          icon: Icon(widget.icon ?? Icons.merge_type_rounded),
          label: FittedBox(fit: BoxFit.scaleDown, child: Text(buttonLabel)),
        ),
      ),
    };

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        button,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _FusionActionButtonPainter(
                    tint: widget.tint,
                    progress: _busy ? _controller.value : 0,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FusionActionButtonPainter extends CustomPainter {
  const _FusionActionButtonPainter({
    required this.tint,
    required this.progress,
  });

  final Color tint;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0 || size.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOutCubic.transform(clamped);
    final glow = math.sin(clamped * math.pi);
    final radius = math.min(size.width, size.height) * 0.38;
    final targetRadius = radius * (0.12 + (0.18 * eased));
    final sourceRadius = radius * (0.92 - (0.48 * eased));
    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );

    canvas.drawRRect(
      outline.inflate(3 + (5 * eased)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = tint.withValues(alpha: 0.46 * (1 - eased)),
    );

    for (var index = 0; index < 6; index += 1) {
      final angle = (-math.pi / 2) + (index * math.pi / 3);
      final source = Offset(
        center.dx + math.cos(angle) * sourceRadius,
        center.dy + math.sin(angle) * sourceRadius,
      );
      final target = Offset(
        center.dx + math.cos(angle) * targetRadius,
        center.dy + math.sin(angle) * targetRadius,
      );
      canvas.drawLine(
        source,
        target,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + glow
          ..strokeCap = StrokeCap.round
          ..color = tint.withValues(alpha: 0.28 + (glow * 0.4)),
      );
      canvas.drawCircle(
        Offset.lerp(source, target, eased)!,
        math.max(2.0, radius * 0.08),
        Paint()..color = tint.withValues(alpha: 0.5 + (glow * 0.34)),
      );
    }

    canvas.drawCircle(
      center,
      radius * (0.16 + (0.16 * glow)),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..color = tint.withValues(alpha: 0.26 + (glow * 0.3)),
    );
  }

  @override
  bool shouldRepaint(covariant _FusionActionButtonPainter oldDelegate) =>
      oldDelegate.tint != tint || oldDelegate.progress != progress;
}

class _EnemySectionHeader extends StatelessWidget {
  const _EnemySectionHeader({
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

class _InlineEnemyNote extends StatelessWidget {
  const _InlineEnemyNote({required this.message, required this.tint});

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

class _BossEnemyChip extends StatelessWidget {
  const _BossEnemyChip({
    required this.card,
    required this.controller,
    this.dimension = kSymbolGridTileSize,
    required this.onOpenDetails,
  });

  final EnemyCardState card;
  final LightcoreController controller;
  final double dimension;
  final ValueChanged<String> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final active = controller.isBossEnemyCardActive(card.config.id);
    final tint = card.config.affinity.color;

    return GuidedFocusFrame(
      active: controller.tutorialHighlightsBossTile(card.config.id),
      tint: LightcorePalette.quest,
      child: _ThreatSummonCard(
        config: card.config,
        dimension: dimension,
        selected: active && card.isOwned,
        locked: !card.isOwned,
        semanticLabel:
            '${card.config.name}, ${card.isOwned ? 'owned' : 'locked'} Apex tile',
        onTap: () => onOpenDetails(card.config.id),
        artSize: dimension * 0.4,
        topRight: SymbolGridBadge(
          tint: !card.isOwned
              ? LightcorePalette.mist
              : active
              ? LightcorePalette.layer2
              : tint,
          shape: BoxShape.circle,
          size: 22,
          child: Icon(
            !card.isOwned
                ? Icons.lock_rounded
                : active
                ? Icons.check_rounded
                : Icons.open_in_full_rounded,
          ),
        ),
        bottom: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_rounded),
            const SizedBox(width: 2),
            Text('${card.level}'),
            const SizedBox(width: 6),
            const Icon(Icons.content_copy_rounded),
            const SizedBox(width: 2),
            Text('${card.copies}'),
            const SizedBox(width: 6),
            const Icon(Icons.lock_open_rounded),
            const SizedBox(width: 2),
            Text('${controller.bossLevelCap(card)}'),
          ],
        ),
      ),
    );
  }
}

class _BossDetailSheet extends StatelessWidget {
  const _BossDetailSheet({required this.controller, required this.card});

  final LightcoreController controller;
  final EnemyCardState card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = controller.isBossEnemyCardActive(card.config.id);
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;

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
                  Text(card.config.name, style: textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${card.config.rarity.label} Apex • ${card.config.affinity.label}${card.config.secondaryAffinity == null ? '' : ' / ${card.config.secondaryAffinity!.label}'}',
                    style: textTheme.bodyMedium?.copyWith(color: tint),
                  ),
                ],
              ),
            ),
            if (active) const _DialogStatPill(label: 'Armed'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BossGlyph(config: card.config, size: 68, locked: !card.isOwned),
            const SizedBox(width: 14),
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoChip(label: card.isOwned ? 'Owned' : 'Locked'),
                  _InfoChip(
                    label: 'Lv ${card.level}/${controller.bossLevelCap(card)}',
                  ),
                  _InfoChip(label: 'Copies ${card.copies}'),
                  _InfoChip(label: _bossTileProgressLabel(controller, card)),
                  _InfoChip(
                    label:
                        'Threat ${controller.enemyCardThreatRatingLabel(card)}',
                  ),
                  _InfoChip(
                    label: 'HP ${controller.enemyCardPreviewHealthLabel(card)}',
                  ),
                  _InfoChip(
                    label:
                        'Lumens +${controller.enemyCardPreviewRewardLabel(card)}',
                  ),
                  _InfoChip(
                    label:
                        'EXP +${controller.enemyCardPreviewExperience(card)}',
                  ),
                  _InfoChip(
                    label:
                        'Kill +${controller.enemyCardPreviewKillCredit(card)}',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(card.config.summary, style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        Text(card.config.traitLabel, style: textTheme.titleMedium),
        const SizedBox(height: 10),
        _BossEquippedEffectPanel(controller: controller, card: card),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            GuidedFocusFrame(
              active: controller.tutorialHighlightsBossArmButton(
                card.config.id,
              ),
              tint: LightcorePalette.quest,
              child: FilledButton(
                onPressed: !card.isOwned || active
                    ? null
                    : () {
                        final armed = controller.tutorialArmBossEnemyCard(
                          card.config.id,
                        );
                        if (armed) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(
                  !card.isOwned
                      ? 'Pull To Unlock'
                      : active
                      ? 'Apex Armed'
                      : 'Arm As Apex',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BossInventoryEffectPanel(controller: controller, card: card),
      ],
    );
  }
}

class _BossGlyph extends StatelessWidget {
  const _BossGlyph({required this.config, this.size = 40, this.locked = false});

  final EnemyConfig config;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final primary = config.affinity.color;
    final secondary = config.secondaryAffinity?.color ?? primary;
    final badges = <IconData>[
      if (config.immunityAffinities.isNotEmpty) Icons.block_rounded,
      if (config.hasRegen) Icons.favorite_rounded,
      if (config.hasSpawnAbility) Icons.groups_rounded,
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: locked ? 0.5 : 1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AffinityGlyph(affinity: config.affinity, size: size * 0.45),
                  if (config.secondaryAffinity != null)
                    Positioned(
                      right: size * 0.1,
                      bottom: size * 0.08,
                      child: AffinityGlyph(
                        affinity: config.secondaryAffinity!,
                        size: size * 0.24,
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (var index = 0; index < badges.length && index < 2; index++)
            Positioned(
              left: index * (size * 0.24),
              bottom: -4,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LightcorePalette.panelRaised.withValues(alpha: 0.96),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.46),
                    width: 1.1,
                  ),
                ),
                child: Icon(badges[index], size: size * 0.14, color: primary),
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _bossMechanicLabels(EnemyCardState card) {
  return <String>[
    if (card.config.secondaryAffinity != null)
      '${card.config.affinity.label}/${card.config.secondaryAffinity!.label}',
    for (final immunity in card.config.immunityAffinities)
      '${immunity.label} immune',
    if (card.config.hasRegen) 'Regenerates',
    if (card.config.hasSpawnAbility) 'Spawns escorts',
  ];
}

class _BossEquippedEffectPanel extends StatelessWidget {
  const _BossEquippedEffectPanel({
    required this.controller,
    required this.card,
  });

  final LightcoreController controller;
  final EnemyCardState card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = controller.isBossEnemyCardActive(card.config.id);
    final labels = _bossMechanicLabels(card);

    return AuroraPanel(
      tint: card.config.affinity.color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${card.config.name} Equipped Effect',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            card.isOwned
                ? active
                      ? 'Armed now. This Apex replaces the next primed Apex spawn.'
                      : 'Arm this Apex to use these spawn mechanics.'
                : 'Find this Apex before its armed spawn mechanics can be used.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                label:
                    'Every ${LightcoreController.bossSpawnKillRequirement} clears',
              ),
              _InfoChip(label: active ? 'Armed' : 'Not armed'),
              _InfoChip(label: card.config.traitLabel),
              if (labels.isEmpty)
                const _InfoChip(label: 'Single-affinity Apex')
              else
                for (final label in labels) _InfoChip(label: label),
            ],
          ),
        ],
      ),
    );
  }
}

class _BossInventoryEffectPanel extends StatelessWidget {
  const _BossInventoryEffectPanel({
    required this.controller,
    required this.card,
  });

  final LightcoreController controller;
  final EnemyCardState card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canUpgrade = controller.canUpgradeBossEnemyCard(card);
    final cap = controller.bossLevelCap(card);
    final maxed = card.isOwned && card.level >= cap;
    final cost = controller.bossUpgradeRequirement(card);
    final highlights = controller.inventoryEffectHighlightsForCard(
      card,
      maxItems: 4,
    );
    final copiesToNextCap = controller.bossCopiesToNextCapIncrease(card);

    return AuroraPanel(
      tint: card.config.affinity.color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${card.config.name} Inventory Effect',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            card.isOwned
                ? 'This positive tower bonus is active from inventory, even when another Apex is armed. Copies raise the level cap; Heartcores upgrade the bonus.'
                : 'Find this Apex to immediately apply its positive inventory bonus.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                label: card.isOwned ? 'Active from inventory' : 'Not found',
              ),
              if (card.isOwned) ...[
                _InfoChip(label: 'Lv ${card.level}/$cap'),
                _InfoChip(label: 'Copies ${card.copies}'),
              ] else ...[
                const _InfoChip(label: 'Find to activate'),
              ],
              _InfoChip(label: controller.bossTicketLabel),
              _InfoChip(label: controller.bossCoreLabel),
              if (card.isOwned) ...[
                _InfoChip(
                  label: copiesToNextCap == 0
                      ? 'Cap maxed'
                      : '$copiesToNextCap more copy for +2 cap',
                ),
                _InfoChip(label: _bossTileProgressLabel(controller, card)),
              ],
              _InfoChip(
                label: controller.inventoryEffectSummaryLabelForCard(card),
              ),
            ],
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in highlights) _InfoChip(label: label),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: card.isOwned && canUpgrade
                ? () => controller.upgradeBossEnemyCard(card.config.id)
                : null,
            icon: const Icon(Icons.arrow_circle_up_rounded),
            label: Text(
              !card.isOwned
                  ? 'Find Apex To Upgrade'
                  : maxed
                  ? 'Apex Maxed'
                  : 'Upgrade Apex • $cost Heartcores',
            ),
          ),
        ],
      ),
    );
  }
}
