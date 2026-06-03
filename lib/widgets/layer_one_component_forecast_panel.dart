import 'package:flutter/material.dart';

import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import 'meter_bar.dart';

class LayerOneComponentForecastPanel extends StatelessWidget {
  const LayerOneComponentForecastPanel({
    super.key,
    required this.controller,
    this.compact = false,
    this.showLatestComponent = true,
  });

  final LightcoreController controller;
  final bool compact;
  final bool showLatestComponent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = controller.canUnlockLayer2
        ? LightcorePalette.success
        : LightcorePalette.layer2;
    final projectileRates = controller.promotionProjectileAffinityRates;
    final payloadRates = controller.promotionPayloadAffinityRates;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: compact ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schema_rounded, color: tint, size: compact ? 17 : 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  compact ? 'Component Forecast' : 'Layer 1 Component Forecast',
                  style:
                      (compact ? textTheme.titleSmall : textTheme.titleMedium)
                          ?.copyWith(
                            color: LightcorePalette.mist,
                            fontWeight: FontWeight.w900,
                          ),
                ),
              ),
              if (!compact)
                IconButton.filledTonal(
                  tooltip: 'View all component odds',
                  onPressed: () => _showOddsDialog(context),
                  icon: const Icon(Icons.percent_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.activeLayerComponentForecastReadyLabel,
            style: textTheme.bodySmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          MeterBar(value: controller.promotionProgress, color: tint, height: 8),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ForecastChip(
                label: controller.activeLayerBestWaveLabel,
                tint: LightcorePalette.aether,
                icon: Icons.waves_rounded,
              ),
              _ForecastChip(
                label: 'Tier ${controller.activeLayerComponentStatTier}',
                tint: LightcorePalette.solar,
                icon: Icons.military_tech_rounded,
              ),
              _ForecastChip(
                label:
                    '${controller.activeLayerExpectedSubtraitCount} subtrait${controller.activeLayerExpectedSubtraitCount == 1 ? '' : 's'}',
                tint: LightcorePalette.violet,
                icon: Icons.auto_awesome_rounded,
              ),
              if (!compact)
                _ForecastChip(
                  label: controller.activeLayerNextComponentTierLabel,
                  tint: LightcorePalette.warning,
                  icon: Icons.flag_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _RateSummaryRow(
            title: 'Projectile',
            emptyLabel: 'No projectile odds yet',
            rates: projectileRates,
            compact: compact,
          ),
          const SizedBox(height: 8),
          _RateSummaryRow(
            title: 'Payload',
            emptyLabel: 'Payload unlocks after Layer 1',
            rates: payloadRates,
            compact: compact,
          ),
          if (!compact && showLatestComponent) ...[
            const SizedBox(height: 12),
            _ForecastChip(
              label: 'Latest: ${controller.latestLayer2ComponentSummaryLabel}',
              tint: controller.layer2Components.isEmpty
                  ? LightcorePalette.stroke
                  : LightcorePalette.success,
              icon: Icons.inventory_2_rounded,
            ),
          ],
          if (compact) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showOddsDialog(context),
                icon: const Icon(Icons.percent_rounded, size: 18),
                label: const Text('Odds'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOddsDialog(BuildContext context) {
    final payloadRates = controller.promotionPayloadAffinityRates;
    showDialog<void>(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          title: const Text('Layer 1 Component Forecast'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogLine(
                    label: 'Best wave',
                    value: controller.activeLayerBestWaveLabel,
                  ),
                  _DialogLine(
                    label: 'Stat tier',
                    value: 'Tier ${controller.activeLayerComponentStatTier}',
                  ),
                  _DialogLine(
                    label: 'Subtraits',
                    value:
                        '${controller.activeLayerExpectedSubtraitCount} expected',
                  ),
                  const SizedBox(height: 12),
                  const _DialogSectionLabel(label: 'Projectile Odds'),
                  const SizedBox(height: 6),
                  ...controller.promotionProjectileAffinityRates.entries.map(
                    (entry) => _DialogRateRow(
                      label: entry.key.label,
                      value: entry.value,
                      color: entry.key.color,
                    ),
                  ),
                  if (payloadRates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _DialogSectionLabel(label: 'Payload Odds'),
                    const SizedBox(height: 6),
                    ...payloadRates.entries.map(
                      (entry) => _DialogRateRow(
                        label: entry.key.label,
                        value: entry.value,
                        color: entry.key.color,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Composition controls projectile and payload odds. Best wave controls stat tier and subtrait count.',
                    style: textTheme.bodySmall?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
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
}

class _RateSummaryRow extends StatelessWidget {
  const _RateSummaryRow({
    required this.title,
    required this.emptyLabel,
    required this.rates,
    required this.compact,
  });

  final String title;
  final String emptyLabel;
  final Map<PrototypeAffinity, double> rates;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = rates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.labelMedium?.copyWith(
            color: LightcorePalette.mist.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        if (entries.isEmpty)
          Text(
            emptyLabel,
            style: textTheme.bodySmall?.copyWith(
              color: LightcorePalette.mist.withValues(alpha: 0.62),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in entries.take(compact ? 2 : 3))
                _ForecastChip(
                  label:
                      '${entry.key.label} ${_formatForecastRate(entry.value)}',
                  tint: entry.key.color,
                  compact: true,
                ),
            ],
          ),
      ],
    );
  }
}

class _ForecastChip extends StatelessWidget {
  const _ForecastChip({
    required this.label,
    required this.tint,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color tint;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 180 : 320),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogLine extends StatelessWidget {
  const _DialogLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.72),
              ),
            ),
          ),
          Text(
            value,
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

class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: LightcorePalette.solar,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DialogRateRow extends StatelessWidget {
  const _DialogRateRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            _formatForecastRate(value),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _formatForecastRate(double value) {
  final percent = value * 100;
  if ((percent - percent.round()).abs() < 0.05) {
    return '${percent.round()}%';
  }
  return '${percent.toStringAsFixed(1)}%';
}
