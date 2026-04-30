import 'package:flutter/material.dart';

import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/meter_bar.dart';
import '../widgets/tower_ring_icon.dart';
import '../widgets/tower_pattern_bonus_panel.dart';

Future<void> showTowerDetailOverlay({
  required BuildContext context,
  required LightcoreController controller,
  required int slotIndex,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: LightcorePalette.night.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final tower = controller.slots[slotIndex];
          final tint = tower.isBuilt
              ? tower.config?.affinity.color ?? LightcorePalette.aether
              : LightcorePalette.warning;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: AuroraPanel(
                tint: tint,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tower Detail',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tower.isBuilt
                          ? '${controller.towerDisplayName(tower)} stats, tuned upgrades, and projectile controls.'
                          : 'This hex is still empty.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: _TowerDetailContent(
                        controller: controller,
                        slotIndex: slotIndex,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class TowerDetailScreen extends StatelessWidget {
  const TowerDetailScreen({
    super.key,
    required this.controller,
    required this.slotIndex,
  });

  final LightcoreController controller;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tower Detail')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [LightcorePalette.night, LightcorePalette.abyss],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _TowerDetailContent(
              controller: controller,
              slotIndex: slotIndex,
            ),
          ),
        ),
      ),
    );
  }
}

class _TowerDetailContent extends StatelessWidget {
  const _TowerDetailContent({
    required this.controller,
    required this.slotIndex,
  });

  final LightcoreController controller;
  final int slotIndex;

  @override
  Widget build(BuildContext context) {
    final tower = controller.slots[slotIndex];
    final textTheme = Theme.of(context).textTheme;

    if (!tower.isBuilt) {
      return Center(
        child: AuroraPanel(
          tint: LightcorePalette.warning,
          child: Text('This hex is still empty.', style: textTheme.titleLarge),
        ),
      );
    }

    final card = controller.cardForSlot(tower);
    final upgradeOptions = controller.towerUpgradeOptionsFor(tower);
    final lockedTypes = controller.towerLockedUpgradeTypesFor(tower);
    final staticArchive = controller.activeLayerPassiveOnly;
    final hasDotStat =
        tower.dotDamageFactor > 1 ||
        controller.towerHasUpgradeOption(tower, TowerUpgradeStatType.dotDamage);
    final tint = tower.config!.affinity.color;
    final projectiles = controller.towerProjectileArsenal(tower);
    final isMaxed = tower.level >= LightcoreController.maxTowerLevel;
    final statRows = <_TowerStatRowData>[
      _TowerStatRowData(
        label: 'Level',
        value: '${tower.level}/${LightcoreController.maxTowerLevel}',
      ),
      _TowerStatRowData(
        label: 'Stat Ranks',
        value:
            '${controller.towerUpgradePointsSpent(tower)}/${controller.towerUpgradePointsCap(tower)}',
      ),
      _TowerStatRowData(
        label: 'Power',
        value: controller.towerPower(tower).toStringAsFixed(1),
        accent: true,
      ),
      _TowerStatRowData(
        label: 'Live Charge Rate',
        value: controller.towerLiveChargeRate(tower).toStringAsFixed(2),
      ),
      _TowerStatRowData(
        label: 'Live Cooldown',
        value: '${controller.towerLiveCooldown(tower).toStringAsFixed(2)}s',
      ),
      _TowerStatRowData(
        label: 'Lane Load',
        value: '${(controller.towerDisruptionFraction(tower) * 100).round()}%',
      ),
      _TowerStatRowData(
        label: 'Core Manager',
        value: controller.managerAssignmentUnlocked
            ? card?.name ?? 'Open'
            : 'Locked until Core Lv ${LightcoreController.managerCoreLevelRequirement}',
      ),
      _TowerStatRowData(
        label: 'Automation',
        value: controller.towerAutomationLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Affinity Signature',
        value: controller.towerAffinitySignatureLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Projectile Trait',
        value: controller.towerProjectileArsenalLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Payload Trait',
        value: controller.towerPayloadArsenalLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Live Projectile',
        value: controller.towerProjectileLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Live Payload',
        value: controller.towerPayloadLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Live Range',
        value: controller.towerRangeLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Default Projectile Range',
        value:
            '${controller.towerDefaultProjectileRangeLabel(tower)} (${controller.towerDefaultProjectileLabel(tower)})',
      ),
      _TowerStatRowData(
        label: 'Generation Speed',
        value: controller.towerGenerationLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Critical',
        value: controller.towerCritLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Damage Range',
        value: controller.towerDamageRangeLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Final Damage',
        value: controller.towerFinalDamageLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Apex Damage',
        value: controller.towerBossDamageLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Normal Damage',
        value: controller.towerNormalDamageLabel(tower),
      ),
      _TowerStatRowData(
        label: 'Defense Pen',
        value: controller.towerDefensePenetrationLabel(tower),
      ),
      if (hasDotStat)
        _TowerStatRowData(
          label: 'DoT Damage',
          value: controller.towerDotDamageLabel(tower),
        ),
      _TowerStatRowData(
        label: 'Live Target',
        value: controller.towerTargetLabel(tower),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
      children: [
        _TowerPortraitPanel(controller: controller, tower: tower, tint: tint),
        if (staticArchive) ...[
          const SizedBox(height: 14),
          _ConsoleSection(
            title: 'Static Archive',
            subtitle:
                'This merged source shell is passive support. Tower pieces can be inspected, but recalibration, upgrades, targeting, and sales stay on live shells.',
            tint: LightcorePalette.solar,
            child: _TowerInfoChip(
              label: 'Mode',
              value: 'Inspect only',
              tint: LightcorePalette.solar,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _ConsoleSection(
          title: 'Upgrade Board',
          subtitle: controller.isTowerComplete(tower)
              ? 'Tower level and rolled stat ranks are complete. The board remains here for stat comparison.'
              : isMaxed
              ? 'Tower level is maxed. Finish rolled stat ranks to complete the tower.'
              : 'Upgrade tower level separately from rolled stat ranks. Locked stats stay visible below for quick comparison.',
          tint: LightcorePalette.solar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TowerRankSummary(
                controller: controller,
                tower: tower,
                slotIndex: slotIndex,
                rolledCount: upgradeOptions.length,
                lockedCount: lockedTypes.length,
                tint: tint,
              ),
              const SizedBox(height: 14),
              for (final upgrade in upgradeOptions) ...[
                _TowerUpgradeCard(
                  controller: controller,
                  tower: tower,
                  upgrade: upgrade,
                  slotIndex: slotIndex,
                  tint: tint,
                ),
                if (upgrade != upgradeOptions.last) const SizedBox(height: 10),
              ],
              if (lockedTypes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Locked Stats', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in lockedTypes)
                      _LockedStatChip(label: type.label),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: staticArchive
                      ? null
                      : () => controller.sellTower(slotIndex),
                  child: Text('Sell ${(tower.investedLumens * 0.7).round()}L'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _TowerStatsLedger(rows: statRows, tint: tint),
        const SizedBox(height: 14),
        _ConsoleSection(
          title: 'Tower Core Manager',
          subtitle: controller.managerAssignmentUnlocked
              ? card?.summary ??
                    'Open the Managers tab to socket a Core Manager for every tower on this shell.'
              : 'Manager assignment unlocks when this core reaches Lv ${LightcoreController.managerCoreLevelRequirement}. Until then, tap ready towers manually.',
          tint: LightcorePalette.layer2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TowerInfoChip(
                label: 'Manager',
                value: controller.managerAssignmentUnlocked
                    ? card?.name ?? 'Open'
                    : 'Locked',
                tint: LightcorePalette.layer2,
              ),
              if (controller.managerAssignmentUnlocked && card != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: controller.unequipCoreTowerManager,
                    child: const Text('Unequip Core Manager'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ConsoleSection(
          title: 'Projectile Targeting',
          subtitle:
              'Assign a target bias to each projectile trait this prism can fire. Root towers only expose their own fixed projectile.',
          tint: LightcorePalette.mist,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final projectile in projectiles) ...[
                _ProjectileTargetRow(
                  projectileType: projectile,
                  isActive: controller.towerProjectileType(tower) == projectile,
                  selectedPriority: controller.towerTargetPriorityForProjectile(
                    tower,
                    projectile,
                  ),
                  onSelected: staticArchive
                      ? null
                      : (priority) =>
                            controller.setTowerProjectileTargetPriority(
                              slotIndex,
                              projectile,
                              priority,
                            ),
                ),
                if (projectile != projectiles.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ConsoleSection(
          title: 'Pattern Bonus',
          tint: tint,
          child: TowerPatternBonusPanel(
            achievements: controller.activeTowerAchievements,
            hint: controller.towerAchievementHintLabel,
            tint: tint,
            title: 'Tower Pattern',
          ),
        ),
      ],
    );
  }
}

class _TowerPortraitPanel extends StatelessWidget {
  const _TowerPortraitPanel({
    required this.controller,
    required this.tower,
    required this.tint,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chargeLabel =
        '${(tower.charge * 100).clamp(0, 100).toStringAsFixed(0)}%';
    final portrait = Container(
      width: 116,
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
        gradient: RadialGradient(
          colors: [
            tint.withValues(alpha: 0.38),
            LightcorePalette.panel.withValues(alpha: 0.82),
            LightcorePalette.night.withValues(alpha: 0.94),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.hexagon_outlined,
            size: 100,
            color: tint.withValues(alpha: 0.18),
          ),
          TowerRingIcon(size: 74, color: tint),
        ],
      ),
    );
    final towerCopy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HEX ${tower.slotIndex + 1}',
          style: textTheme.labelLarge?.copyWith(
            color: tint,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(tower.config!.name, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(tower.config!.summary, style: textTheme.bodyMedium),
        const SizedBox(height: 10),
        Text(
          tower.config!.passiveLabel,
          style: textTheme.titleMedium?.copyWith(color: tint),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tint.withValues(alpha: 0.34), width: 1.2),
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: 0.18),
            LightcorePalette.panelRaised.withValues(alpha: 0.95),
            LightcorePalette.abyss.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.16),
            blurRadius: 28,
            spreadRadius: -12,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: portrait),
                    const SizedBox(height: 14),
                    towerCopy,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  portrait,
                  const SizedBox(width: 14),
                  Expanded(child: towerCopy),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            controller.payloadsUnlocked
                ? 'Root towers stay single-color and projectile-only after promotion unlocks. This prism feeds ${controller.towerProjectileLabel(tower)}.'
                : 'Root towers stay single-color and projectile-only: ${controller.towerAffinitySignatureLabel(tower)} • ${controller.towerProjectileArsenalLabel(tower)}.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          MeterBar(value: tower.charge.clamp(0, 1), color: tint, height: 12),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TowerInfoChip(label: 'Charge', value: chargeLabel, tint: tint),
              _TowerInfoChip(
                label: 'Target',
                value: controller.towerTargetLabel(tower),
                tint: LightcorePalette.mist,
              ),
              _TowerInfoChip(
                label: 'Projectile',
                value: controller.towerProjectileLabel(tower),
                tint: LightcorePalette.aether,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsoleSection extends StatelessWidget {
  const _ConsoleSection({
    required this.title,
    required this.tint,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightcorePalette.panel.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tint.withValues(alpha: 0.28), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TowerRankSummary extends StatelessWidget {
  const _TowerRankSummary({
    required this.controller,
    required this.tower,
    required this.slotIndex,
    required this.rolledCount,
    required this.lockedCount,
    required this.tint,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final int slotIndex;
  final int rolledCount;
  final int lockedCount;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spent = controller.towerUpgradePointsSpent(tower);
    final remaining = controller.towerUpgradePointsRemaining(tower);
    final cap = controller.towerUpgradePointsCap(tower);
    final isMaxed = tower.level >= LightcoreController.maxTowerLevel;
    final isComplete = controller.isTowerComplete(tower);
    final levelCost = controller.upgradeCost(tower);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LightcorePalette.stroke.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tower Rank',
                  style: textTheme.titleMedium?.copyWith(color: tint),
                ),
              ),
              Text(
                '${tower.level}/${LightcoreController.maxTowerLevel}',
                style: textTheme.titleMedium?.copyWith(
                  color: LightcorePalette.solar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeterBar(
            value: tower.level / LightcoreController.maxTowerLevel,
            color: tint,
            height: 12,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TowerInfoChip(label: 'Stats', value: '$spent/$cap', tint: tint),
              _TowerInfoChip(
                label: 'Ranks Left',
                value: '$remaining',
                tint: LightcorePalette.solar,
              ),
              _TowerInfoChip(
                label: tower.isFabricating ? 'Online' : 'Level Cost',
                value: tower.isFabricating
                    ? controller.towerFabricationRemainingLabel(tower)
                    : isMaxed
                    ? isComplete
                          ? 'Complete'
                          : 'Maxed'
                    : '${levelCost}L',
                tint: LightcorePalette.flare,
              ),
              _TowerInfoChip(
                label: 'Rolled',
                value: '$rolledCount',
                tint: LightcorePalette.aether,
              ),
              _TowerInfoChip(
                label: 'Locked',
                value: '$lockedCount',
                tint: LightcorePalette.mist,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  !tower.isFabricating &&
                      !isMaxed &&
                      !controller.activeLayerPassiveOnly
                  ? () => controller.upgradeTower(slotIndex)
                  : null,
              icon: const Icon(Icons.upgrade_rounded),
              label: Text(
                tower.isFabricating
                    ? 'Fabricating ${controller.towerFabricationRemainingLabel(tower)}'
                    : isMaxed
                    ? isComplete
                          ? 'Complete'
                          : 'Level Max'
                    : 'Upgrade Level • ${levelCost}L',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TowerStatsLedger extends StatelessWidget {
  const _TowerStatsLedger({required this.rows, required this.tint});

  final List<_TowerStatRowData> rows;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return _ConsoleSection(
      title: 'Tower Stats',
      subtitle: 'Scrollable live output, projectile traits, and manager state.',
      tint: LightcorePalette.aether,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index += 1) ...[
            _TowerStatLine(row: rows[index], tint: tint),
            if (index != rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _TowerStatLine extends StatelessWidget {
  const _TowerStatLine({required this.row, required this.tint});

  final _TowerStatRowData row;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: row.accent
            ? tint.withValues(alpha: 0.12)
            : LightcorePalette.abyss.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: row.accent
              ? tint.withValues(alpha: 0.36)
              : LightcorePalette.mist.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(row.label, style: textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                row.value,
                textAlign: TextAlign.right,
                style: textTheme.titleSmall?.copyWith(
                  color: row.accent ? tint : LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TowerInfoChip extends StatelessWidget {
  const _TowerInfoChip({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: Text(
        '$label  $value',
        style: textTheme.bodySmall?.copyWith(
          color: LightcorePalette.mist,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TowerStatRowData {
  const _TowerStatRowData({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;
}

class _ProjectileTargetRow extends StatelessWidget {
  const _ProjectileTargetRow({
    required this.projectileType,
    required this.isActive,
    required this.selectedPriority,
    required this.onSelected,
  });

  final ProjectileType projectileType;
  final bool isActive;
  final TargetPriority selectedPriority;
  final ValueChanged<TargetPriority>? onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? LightcorePalette.solar.withValues(alpha: 0.54)
              : LightcorePalette.mist.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    projectileType.label,
                    style: textTheme.titleMedium?.copyWith(
                      color: isActive
                          ? LightcorePalette.solar
                          : LightcorePalette.mist,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LightcorePalette.solar.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Live',
                      style: textTheme.labelMedium?.copyWith(
                        color: LightcorePalette.solar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final priority in TargetPriority.values)
                  ChoiceChip(
                    label: Text(priority.label),
                    selected: selectedPriority == priority,
                    onSelected: onSelected == null
                        ? null
                        : (_) => onSelected!(priority),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TowerUpgradeCard extends StatelessWidget {
  const _TowerUpgradeCard({
    required this.controller,
    required this.tower,
    required this.upgrade,
    required this.slotIndex,
    required this.tint,
  });

  final LightcoreController controller;
  final OuterTowerState tower;
  final TowerUpgradeOptionState upgrade;
  final int slotIndex;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statMaxed = upgrade.rank >= LightcoreController.maxTowerUpgradeRank;
    final cost = controller.towerStatUpgradeCost(tower, upgrade);
    final canUpgrade =
        !controller.activeLayerPassiveOnly &&
        !tower.isFabricating &&
        !statMaxed &&
        controller.lumens >= cost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.32)),
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: 0.14),
            LightcorePalette.panelRaised.withValues(alpha: 0.9),
            LightcorePalette.abyss.withValues(alpha: 0.62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(upgrade.type.label, style: textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: LightcorePalette.night.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tint.withValues(alpha: 0.28)),
                ),
                child: Text(
                  '${upgrade.rank}/${LightcoreController.maxTowerUpgradeRank}',
                  style: textTheme.labelMedium?.copyWith(
                    color: LightcorePalette.solar,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.towerUpgradeEffectLabel(upgrade),
            style: textTheme.titleLarge?.copyWith(color: tint),
          ),
          const SizedBox(height: 4),
          Text(
            'Current ${controller.towerSubstatValueLabel(tower, upgrade.type)}',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          MeterBar(
            value: (upgrade.rank / LightcoreController.maxTowerUpgradeRank)
                .clamp(0.0, 1.0),
            color: tint,
            height: 10,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canUpgrade
                  ? () => controller.upgradeTowerStat(slotIndex, upgrade.type)
                  : null,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                tower.isFabricating
                    ? 'Fabricating ${controller.towerFabricationRemainingLabel(tower)}'
                    : statMaxed
                    ? 'Stat Max'
                    : 'Enhance • ${cost}L',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedStatChip extends StatelessWidget {
  const _LockedStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: LightcorePalette.abyss.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LightcorePalette.mist.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        '$label  •  Locked',
        style: textTheme.bodySmall?.copyWith(color: LightcorePalette.mist),
      ),
    );
  }
}
