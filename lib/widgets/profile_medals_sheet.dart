import 'package:flutter/material.dart';

import '../models/lightcore_config.dart';
import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

Future<void> showProfileMedalsSheet(
  BuildContext context,
  LightcoreController controller,
) {
  return showDialog<void>(
    context: context,
    barrierColor: LightcorePalette.night.withValues(alpha: 0.82),
    builder: (dialogContext) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return _ProfileMedalsDialog(controller: controller);
        },
      );
    },
  );
}

class _ProfileMedalsDialog extends StatelessWidget {
  const _ProfileMedalsDialog({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final medals = controller.profileMedals;
    final equipped = controller.equippedProfileMedal;
    final tint = equipped == null
        ? LightcorePalette.aether
        : _medalTint(equipped);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: AuroraPanel(
          tint: tint,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile Medals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _MedalTag(
                    label:
                        '${controller.unlockedProfileMedalCount}/${medals.length}',
                    tint: tint,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _EquippedMedalPanel(controller: controller),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: medals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _MedalCard(
                      status: medals[index],
                      onEquip: () =>
                          controller.equipProfileMedal(medals[index].config.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquippedMedalPanel extends StatelessWidget {
  const _EquippedMedalPanel({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final equipped = controller.equippedProfileMedal;
    final tint = equipped == null
        ? LightcorePalette.aether
        : _medalTint(equipped);
    final bonusLabels = _bonusLabels(controller.profileMedalBonuses);

    return AuroraPanel(
      tint: tint,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          _MedalBadge(config: equipped, unlocked: equipped != null, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipped?.name ?? 'No Medal Equipped',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (bonusLabels.isEmpty)
                      _MedalTag(label: 'Profile bonus inactive', tint: tint)
                    else
                      for (final label in bonusLabels)
                        _MedalTag(label: label, tint: tint),
                  ],
                ),
              ],
            ),
          ),
          if (equipped != null) ...[
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: controller.unequipProfileMedal,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedalCard extends StatelessWidget {
  const _MedalCard({required this.status, required this.onEquip});

  final ProfileMedalStatus status;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final config = status.config;
    final tint = _medalTint(config);
    final bonusLabels = _bonusLabels(config.bonuses);

    return AuroraPanel(
      tint: status.unlocked ? tint : LightcorePalette.stroke,
      radius: 18,
      onTap: status.unlocked && !status.equipped ? onEquip : null,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MedalBadge(config: config, unlocked: status.unlocked, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: status.unlocked
                                  ? LightcorePalette.mist
                                  : LightcorePalette.mist.withValues(
                                      alpha: 0.68,
                                    ),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MedalTag(
                      label: status.unlocked
                          ? 'Unlocked'
                          : status.progressLabel,
                      tint: status.unlocked ? tint : LightcorePalette.stroke,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  config.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.76),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MedalTag(label: config.requirementLabel, tint: tint),
                    for (final label in bonusLabels)
                      _MedalTag(label: label, tint: tint),
                  ],
                ),
                if (!status.unlocked) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: status.progressFraction,
                      minHeight: 5,
                      color: tint,
                      backgroundColor: LightcorePalette.stroke.withValues(
                        alpha: 0.34,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: status.unlocked && !status.equipped ? onEquip : null,
            icon: Icon(
              status.equipped
                  ? Icons.check_circle_rounded
                  : status.unlocked
                  ? Icons.military_tech_rounded
                  : Icons.lock_rounded,
            ),
            label: Text(
              status.equipped
                  ? 'Equipped'
                  : status.unlocked
                  ? 'Equip'
                  : 'Locked',
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({
    required this.config,
    required this.unlocked,
    required this.size,
  });

  final ProfileMedalConfig? config;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = config == null ? LightcorePalette.aether : _medalTint(config!);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: unlocked ? 0.34 : 0.12),
            LightcorePalette.panelRaised,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: tint.withValues(alpha: unlocked ? 0.72 : 0.26),
        ),
      ),
      child: Icon(
        unlocked ? Icons.military_tech_rounded : Icons.lock_rounded,
        color: unlocked ? tint : LightcorePalette.mist.withValues(alpha: 0.58),
        size: size * 0.48,
      ),
    );
  }
}

class _MedalTag extends StatelessWidget {
  const _MedalTag({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LightcorePalette.layer2,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

Color _medalTint(ProfileMedalConfig config) =>
    config.affinity == PrototypeAffinity.black
    ? LightcorePalette.violet
    : config.affinity.color;

List<String> _bonusLabels(EquipmentBonusProfile bonuses) {
  final labels = <String>[];

  void addPercent(String label, double value) {
    if (value.abs() < 0.0001) {
      return;
    }
    labels.add('$label +${(value * 100).toStringAsFixed(1)}%');
  }

  addPercent('Power', bonuses.towerPower);
  addPercent('Charge', bonuses.chargeRate);
  addPercent('Crit', bonuses.critChance);
  addPercent('Crit Dmg', bonuses.critDamage);
  addPercent('Range', bonuses.range);
  addPercent('Apex Dmg', bonuses.bossDamage);
  addPercent('Lumens', bonuses.lumenGain);
  addPercent(LightcoreCurrencyLabels.flux, bonuses.fluxGain);
  addPercent(LightcoreCurrencyLabels.scansShort, bonuses.ticketGain);
  addPercent('Drops', bonuses.dropRate);
  return labels;
}
