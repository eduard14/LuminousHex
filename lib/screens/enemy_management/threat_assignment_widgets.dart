part of '../enemy_management_screen.dart';

enum _ThreatAssignmentTab { anomalies, apex }

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
    final isApex = _tab == _ThreatAssignmentTab.apex;
    final list = _tab == _ThreatAssignmentTab.anomalies
        ? controller.enemyCards
        : controller.bossEnemyCards;
    final title = _tab == _ThreatAssignmentTab.anomalies
        ? 'Anomaly List'
        : 'Apex List';
    final tint = _tab == _ThreatAssignmentTab.anomalies
        ? LightcorePalette.scanGlow
        : LightcorePalette.warning;
    final ownedCount = list.where((card) => card.isOwned).length;
    final expandedCard = _expandedCardFor(list, isApex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EnemySectionHeader(
          title: 'Anomaly Assignment',
          tint: LightcorePalette.scanGlow,
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
                onPressed: () => _setTab(_ThreatAssignmentTab.anomalies),
                style: FilledButton.styleFrom(
                  backgroundColor: _tab == _ThreatAssignmentTab.anomalies
                      ? LightcorePalette.scanGlow.withValues(alpha: 0.2)
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
                onPressed: () => _setTab(_ThreatAssignmentTab.apex),
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
        _AssignmentSectionHeader(
          title: title,
          tint: tint,
          ownedCount: ownedCount,
          totalCount: list.length,
        ),
        const SizedBox(height: 8),
        _ThreatAssignmentGrid(
          controller: controller,
          cards: list,
          isApex: isApex,
          expandedId: _expandedId,
          onTap: (card) => _toggleExpandedCard(card, isApex),
        ),
        if (expandedCard != null) ...[
          const SizedBox(height: 10),
          _ThreatAssignmentDetailPanel(
            controller: controller,
            card: expandedCard,
            isApex: isApex,
            onClose: () => setState(() => _expandedId = null),
          ),
        ],
      ],
    );
  }

  void _setTab(_ThreatAssignmentTab tab) {
    if (_tab == tab) {
      return;
    }
    setState(() {
      _tab = tab;
      _expandedId = null;
    });
  }

  void _toggleExpandedCard(EnemyCardState card, bool isApex) {
    final id = _assignmentExpansionId(card, isApex);
    setState(() => _expandedId = _expandedId == id ? null : id);
  }

  EnemyCardState? _expandedCardFor(List<EnemyCardState> cards, bool isApex) {
    final expandedId = _expandedId;
    if (expandedId == null) {
      return null;
    }
    for (final card in cards) {
      if (_assignmentExpansionId(card, isApex) == expandedId) {
        return card;
      }
    }
    return null;
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

String _assignmentExpansionId(EnemyCardState card, bool isApex) {
  return '${isApex ? 'apex' : 'anomaly'}:${card.config.id}';
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
    final selectedStats = selected == null
        ? null
        : controller.threatAssignmentGroupStatsForPreset(selected);
    final picker = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LightcorePalette.scanGlow.withValues(alpha: 0.24),
        ),
      ),
      child: presets.isEmpty
          ? Row(
              children: [
                Icon(
                  Icons.bookmark_add_rounded,
                  size: 18,
                  color: LightcorePalette.scanGlow,
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

    final bar = LayoutBuilder(
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

    if (selected == null || selectedStats == null) {
      return bar;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        const SizedBox(height: 8),
        _ThreatGroupStatsPanel(
          title: '${selected.name} anomaly output',
          stats: selectedStats,
          tint: LightcorePalette.scanGlow,
        ),
      ],
    );
  }
}

class _ThreatGroupStatsPanel extends StatelessWidget {
  const _ThreatGroupStatsPanel({
    required this.title,
    required this.stats,
    required this.tint,
  });

  final String title;
  final ThreatAssignmentGroupStatsSnapshot stats;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: tint,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _ThreatGroupStatsChips(stats: stats),
        ],
      ),
    );
  }
}

class _ThreatGroupStatsChips extends StatelessWidget {
  const _ThreatGroupStatsChips({required this.stats});

  final ThreatAssignmentGroupStatsSnapshot stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasAnomalies) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const _InfoChip(label: 'No owned anomalies'),
          if (stats.hasIgnoredAnomalies)
            _InfoChip(label: '${stats.ignoredAnomalyCount} unavailable'),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(label: '${stats.anomalyCount} anomalies'),
        _InfoChip(
          label: '${_formatThreatStat(stats.lumensPerMinute)} Lumens/minute',
        ),
        _InfoChip(
          label: '${_formatThreatStat(stats.experiencePerMinute)} EXP/min',
        ),
        _InfoChip(
          label: '${_formatThreatStat(stats.clearsPerMinute)} clears/min',
        ),
        _InfoChip(
          label: 'Every ${stats.spawnIntervalSeconds.toStringAsFixed(2)}s',
        ),
        if (stats.isDpsLimited) const _InfoChip(label: 'DPS limited'),
        if (stats.hasIgnoredAnomalies)
          _InfoChip(label: '${stats.ignoredAnomalyCount} unavailable'),
      ],
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
          tint: LightcorePalette.scanGlow,
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

String _formatThreatStat(double value) {
  if (!value.isFinite || value <= 0) {
    return '0';
  }
  if (value >= 1000000) {
    final compact = value / 1000000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}K';
  }
  if (value >= 100) {
    return value.round().toString();
  }
  if (value >= 10) {
    return value.toStringAsFixed(1);
  }
  return value.toStringAsFixed(2);
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
        _ThreatSummonCard(
          config: card.config,
          dimension: 42,
          locked: !card.isOwned,
          selected: true,
          semanticLabel:
              '${card.config.name}, active ${isApex ? 'Apex' : 'anomaly'} art',
        ),
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
    return Tooltip(
      message: '${card.config.name} • active ${isApex ? 'Apex' : 'anomaly'}',
      child: _ThreatSummonCard(
        config: card.config,
        dimension: 48,
        selected: card.isOwned,
        locked: !card.isOwned,
        glowTint: tint,
        glowStrength: 0.28,
        semanticLabel:
            '${card.config.name}, active ${isApex ? 'Apex' : 'anomaly'} tile',
        topRight: SymbolGridBadge(
          tint: card.isOwned ? LightcorePalette.layer2 : LightcorePalette.mist,
          shape: BoxShape.circle,
          size: 18,
          child: Icon(card.isOwned ? Icons.check_rounded : Icons.lock_rounded),
        ),
      ),
    );
  }
}

class _AssignmentSectionHeader extends StatelessWidget {
  const _AssignmentSectionHeader({
    required this.title,
    required this.tint,
    required this.ownedCount,
    required this.totalCount,
  });

  final String title;
  final Color tint;
  final int ownedCount;
  final int totalCount;

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
            '$title • Owned $ownedCount/$totalCount',
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

class _ThreatAssignmentGrid extends StatelessWidget {
  const _ThreatAssignmentGrid({
    required this.controller,
    required this.cards,
    required this.isApex,
    required this.expandedId,
    required this.onTap,
  });

  final LightcoreController controller;
  final List<EnemyCardState> cards;
  final bool isApex;
  final String? expandedId;
  final ValueChanged<EnemyCardState> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension = constraints.maxWidth >= 620
            ? 76.0
            : constraints.maxWidth >= 420
            ? 70.0
            : 64.0;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in cards)
              _ThreatAssignmentTile(
                controller: controller,
                card: card,
                isApex: isApex,
                expanded: expandedId == _assignmentExpansionId(card, isApex),
                dimension: dimension,
                onTap: () => onTap(card),
              ),
          ],
        );
      },
    );
  }
}

class _ThreatAssignmentTile extends StatelessWidget {
  const _ThreatAssignmentTile({
    required this.controller,
    required this.card,
    required this.isApex,
    required this.expanded,
    required this.dimension,
    required this.onTap,
  });

  final LightcoreController controller;
  final EnemyCardState card;
  final bool isApex;
  final bool expanded;
  final double dimension;
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
    final statusTint = locked
        ? LightcorePalette.mist
        : active
        ? LightcorePalette.layer2
        : tint;
    final statusIcon = locked
        ? Icons.lock_rounded
        : active
        ? Icons.check_rounded
        : expanded
        ? Icons.expand_less_rounded
        : isApex
        ? Icons.shield_moon_rounded
        : Icons.radar_rounded;

    return Tooltip(
      message:
          '${card.config.name} • ${card.config.rarity.label} • $status • tap for details',
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: expanded ? 1.04 : 1,
        child: _ThreatSummonCard(
          config: card.config,
          dimension: dimension,
          selected: active && card.isOwned,
          locked: locked,
          emphasized: expanded,
          glowTint: tint,
          glowStrength: expanded
              ? 0.68
              : active
              ? 0.38
              : 0,
          semanticLabel:
              '${card.config.name}, ${card.isOwned ? 'owned' : 'locked'} ${isApex ? 'Apex' : 'anomaly'} tile',
          onTap: onTap,
          topRight: SymbolGridBadge(
            tint: statusTint,
            shape: BoxShape.circle,
            size: 22,
            child: Icon(statusIcon),
          ),
          bottom: card.isOwned
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.layers_rounded),
                    const SizedBox(width: 2),
                    Text('${card.level}'),
                    const SizedBox(width: 5),
                    const Icon(Icons.content_copy_rounded),
                    const SizedBox(width: 2),
                    Text('${card.copies}'),
                  ],
                )
              : const Icon(Icons.lock_rounded),
        ),
      ),
    );
  }
}

class _ThreatAssignmentDetailPanel extends StatelessWidget {
  const _ThreatAssignmentDetailPanel({
    required this.controller,
    required this.card,
    required this.isApex,
    required this.onClose,
  });

  final LightcoreController controller;
  final EnemyCardState card;
  final bool isApex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;
    final active = isApex
        ? controller.isBossEnemyCardActive(card.config.id)
        : controller.isEnemyCardActive(card.config.id);
    final status = !card.isOwned
        ? 'Locked'
        : active
        ? (isApex ? 'Armed' : 'In Deck')
        : 'Available';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.42)),
      ),
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
                      card.config.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                      ),
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
                tint: !card.isOwned
                    ? LightcorePalette.mist
                    : active
                    ? LightcorePalette.layer2
                    : tint,
              ),
              IconButton(
                tooltip: 'Close details',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ThreatAssignmentDetails(
            controller: controller,
            card: card,
            isApex: isApex,
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
        _ThreatAssignmentStatsArt(card: card, isApex: false, active: active),
        const SizedBox(height: 12),
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
        _ThreatAssignmentStatsArt(card: card, isApex: true, active: active),
        const SizedBox(height: 12),
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

class _ThreatAssignmentStatsArt extends StatelessWidget {
  const _ThreatAssignmentStatsArt({
    required this.card,
    required this.isApex,
    required this.active,
  });

  final EnemyCardState card;
  final bool isApex;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tint =
        card.config.secondaryAffinity?.color ?? card.config.affinity.color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final preferredDimension = constraints.maxWidth >= 420 ? 176.0 : 152.0;
        final dimension = math
            .min(preferredDimension, constraints.maxWidth)
            .clamp(112.0, 176.0)
            .toDouble();

        return Center(
          child: _ThreatSummonCard(
            config: card.config,
            dimension: dimension,
            locked: !card.isOwned,
            selected: active && card.isOwned,
            emphasized: true,
            glowTint: tint,
            glowStrength: active ? 0.84 : 0.34,
            semanticLabel:
                '${card.config.name}, expanded ${isApex ? 'Apex' : 'anomaly'} stats art',
            topRight: SymbolGridBadge(
              tint: !card.isOwned
                  ? LightcorePalette.mist
                  : active
                  ? LightcorePalette.layer2
                  : tint,
              shape: BoxShape.circle,
              size: 26,
              child: Icon(
                !card.isOwned
                    ? Icons.lock_rounded
                    : active
                    ? Icons.check_rounded
                    : isApex
                    ? Icons.shield_moon_rounded
                    : Icons.radar_rounded,
              ),
            ),
            bottom: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.layers_rounded),
                const SizedBox(width: 2),
                Text('${card.level}'),
                const SizedBox(width: 7),
                const Icon(Icons.content_copy_rounded),
                const SizedBox(width: 2),
                Text('${card.copies}'),
              ],
            ),
          ),
        );
      },
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
