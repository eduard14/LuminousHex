import 'package:flutter/material.dart';

import '../models/lightcore_config.dart';
import '../models/lightcore_currency_labels.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';
import 'radiance_stat_allocator.dart';

Future<void> showPlayerManagerSheet(
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
          return _PlayerManagerDialog(controller: controller);
        },
      );
    },
  );
}

class _PlayerManagerDialog extends StatefulWidget {
  const _PlayerManagerDialog({required this.controller});

  final LightcoreController controller;

  @override
  State<_PlayerManagerDialog> createState() => _PlayerManagerDialogState();
}

class _PlayerManagerDialogState extends State<_PlayerManagerDialog> {
  EquipmentLoadoutSlot? _selectedSlot;

  LightcoreController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 480;
    final usableHeight =
        (media.size.height - media.viewInsets.vertical - media.padding.vertical)
            .clamp(360.0, media.size.height)
            .toDouble();
    final selectedSlot = _selectedSlot;
    final inventory = controller.equipmentInventory.toList()
      ..sort((a, b) => _compareInventoryDisplayPriority(controller, a, b));
    final filteredInventory = selectedSlot == null
        ? inventory
        : inventory
              .where((item) => item.slotType == selectedSlot.acceptedType)
              .toList(growable: false);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 20,
        vertical: compact ? 10 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: usableHeight * (compact ? 0.94 : 0.86),
        ),
        child: AuroraPanel(
          tint: LightcorePalette.aether,
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 20,
            compact ? 16 : 20,
            compact ? 16 : 20,
            compact ? 16 : 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Main Manager',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _showManagerHelpDialog(context),
                    tooltip: 'Equipment help',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.help_outline_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${controller.equipmentInventory.length}/${controller.equipmentInventoryCapacity}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compactContent = constraints.maxWidth < 430;
                    final inventoryHeight =
                        (constraints.maxHeight * (compactContent ? 0.48 : 0.58))
                            .clamp(compactContent ? 210.0 : 240.0, 420.0)
                            .toDouble();
                    final loadoutColumns = constraints.maxWidth >= 680 ? 3 : 2;
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        if (controller.totalRadianceStatPointsEarned > 0) ...[
                          RadianceStatAllocator(
                            controller: controller,
                            highlighted:
                                controller.hasUnspentRadianceStatPoints,
                            title: 'Global Attributes',
                          ),
                          const SizedBox(height: 12),
                        ],
                        _EquipmentLoadoutBoard(
                          controller: controller,
                          columns: loadoutColumns,
                          selectedSlot: _selectedSlot,
                          onSelectSlot: (slot) {
                            setState(() {
                              _selectedSlot = _selectedSlot == slot
                                  ? null
                                  : slot;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _EquipmentSetStrip(controller: controller),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: inventoryHeight,
                          child: _InventoryPanel(
                            controller: controller,
                            items: filteredInventory,
                            selectedSlot: selectedSlot,
                          ),
                        ),
                      ],
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

class _EquipmentLoadoutBoard extends StatelessWidget {
  const _EquipmentLoadoutBoard({
    required this.controller,
    required this.columns,
    required this.selectedSlot,
    required this.onSelectSlot,
  });

  final LightcoreController controller;
  final int columns;
  final EquipmentLoadoutSlot? selectedSlot;
  final ValueChanged<EquipmentLoadoutSlot> onSelectSlot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final equippedCount = controller.equippedEquipmentCount;
    final tint = _loadoutTint(controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Equipment', style: textTheme.titleMedium),
            _ManagerStatTag(
              label: '$equippedCount/${EquipmentLoadoutSlot.values.length}',
              tint: tint,
            ),
            _ManagerStatTag(
              label: 'TS ${controller.towerStrengthCompactLabel}',
              tint: LightcorePalette.aether,
            ),
            _ManagerStatTag(
              label: controller.activeEquipmentSets.isEmpty
                  ? 'No set'
                  : controller.activeEquipmentSets.first.config.name,
              tint: tint,
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: EquipmentLoadoutSlot.values.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: columns == 2 ? 76 : 82,
          ),
          itemBuilder: (context, index) {
            final slot = EquipmentLoadoutSlot.values[index];
            return _LoadoutSlotCard(
              slot: slot,
              item: controller.equippedPlayerItemForSlot(slot),
              selected: selectedSlot == slot,
              onTap: () => onSelectSlot(slot),
            );
          },
        ),
      ],
    );
  }
}

class _EquipmentSetStrip extends StatelessWidget {
  const _EquipmentSetStrip({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    final sets = controller.activeEquipmentSets;
    final tint = _loadoutTint(controller);
    final bonusLabels = _bonusLabels(controller.equipmentBonuses);

    if (sets.isEmpty && bonusLabels.isEmpty) {
      return Text(
        'Select a slot, then tap Equip on a matching inventory piece.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: LightcorePalette.mist.withValues(alpha: 0.74),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final set in sets)
          _GearChip(
            label:
                '${set.config.name} ${set.equippedCount}/6${set.unlockedBonuses.isEmpty ? '' : ' • ${set.unlockedBonuses.last.label}'}',
            tint: set.config.affinity.color,
          ),
        for (final label in bonusLabels) _GearChip(label: label, tint: tint),
      ],
    );
  }
}

class _ManagerStatTag extends StatelessWidget {
  const _ManagerStatTag({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: LightcorePalette.layer2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Future<void> _showManagerHelpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: LightcorePalette.night.withValues(alpha: 0.76),
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      final compact = media.size.width < 480;
      final usableHeight =
          (media.size.height -
                  media.viewInsets.vertical -
                  media.padding.vertical)
              .clamp(300.0, media.size.height)
              .toDouble();
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 12 : 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: usableHeight * 0.9,
          ),
          child: AuroraPanel(
            tint: LightcorePalette.aether,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Equipment Help',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap a loadout slot to filter inventory to matching pieces, then tap Equip on the piece you want. Inventory holds up to ${LightcoreController.maxEquipmentInventorySize} pieces. Auto Dismantle removes older lower-priority unequipped gear and converts it into Flux.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LoadoutSlotCard extends StatelessWidget {
  const _LoadoutSlotCard({
    required this.slot,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final EquipmentLoadoutSlot slot;
  final PlayerEquipmentItem? item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = item?.affinity.color ?? LightcorePalette.aether;
    final statusLabel = item == null ? 'Filter' : 'Lv ${item!.level}';
    return Tooltip(
      message: item == null
          ? '${slot.label}: empty. Tap to filter inventory.'
          : '${slot.label}: ${item!.name} Lv ${item!.level}. Tap to filter inventory.',
      child: AuroraPanel(
        tint: selected ? tint : tint.withValues(alpha: 0.88),
        onTap: onTap,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            _GearBadge(item: item, slot: slot, size: 38),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected
                          ? tint
                          : LightcorePalette.mist.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item == null ? slot.acceptedType.label : item!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LightcorePalette.mist,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: item == null
                          ? LightcorePalette.mist.withValues(alpha: 0.7)
                          : tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : item == null
                  ? Icons.add_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected
                  ? tint
                  : LightcorePalette.mist.withValues(alpha: 0.68),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({
    required this.controller,
    required this.items,
    required this.selectedSlot,
  });

  final LightcoreController controller;
  final List<PlayerEquipmentItem> items;
  final EquipmentLoadoutSlot? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final selectedSlot = this.selectedSlot;
    final title = selectedSlot == null
        ? 'Inventory'
        : '${selectedSlot.label} Inventory';
    final subtitle = selectedSlot == null
        ? '${items.length}/${controller.equipmentInventoryCapacity} stored. Tap a slot to filter.'
        : '${items.length} ${selectedSlot.acceptedType.label.toLowerCase()} piece${items.length == 1 ? '' : 's'}. Tap Equip to place.';
    final selectedItem = selectedSlot == null
        ? null
        : controller.equippedPlayerItemForSlot(selectedSlot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 230,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LightcorePalette.mist.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: controller.canAutoDismantleOldEquipment
                  ? controller.autoDismantleOldEquipment
                  : null,
              icon: const Icon(Icons.auto_delete_rounded),
              label: const Text('Auto Dismantle'),
            ),
            if (selectedSlot != null && selectedItem != null)
              FilledButton.tonalIcon(
                onPressed: () => controller.unequipPlayerSlot(selectedSlot),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                label: const Text('Unequip'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    selectedSlot == null
                        ? 'No equipment stored yet.'
                        : 'No ${selectedSlot.acceptedType.label.toLowerCase()} pieces available yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 620
                        ? 4
                        : constraints.maxWidth >= 430
                        ? 3
                        : 2;
                    return GridView.builder(
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 138,
                      ),
                      itemBuilder: (context, index) {
                        return _InventoryItemCard(
                          controller: controller,
                          item: items[index],
                          selectedSlot: selectedSlot,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.controller,
    required this.item,
    required this.selectedSlot,
  });

  final LightcoreController controller;
  final PlayerEquipmentItem item;
  final EquipmentLoadoutSlot? selectedSlot;

  @override
  Widget build(BuildContext context) {
    final equippedSlot = controller.equippedSlotForItem(item.instanceId);
    final selectedSlot = this.selectedSlot;
    final equippedHere = selectedSlot != null && equippedSlot == selectedSlot;
    final canEquip =
        selectedSlot != null &&
        item.slotType == selectedSlot.acceptedType &&
        !equippedHere;
    final statusLabel = equippedHere
        ? 'Equipped'
        : equippedSlot == null
        ? 'Stored'
        : equippedSlot.label;
    final statusTint = equippedSlot == null
        ? LightcorePalette.mist.withValues(alpha: 0.32)
        : LightcorePalette.solar;
    final rarityTint = _equipmentRarityTint(item.rarity);
    final bonusLabels = _bonusLabels(item.bonuses);
    return AuroraPanel(
      tint: rarityTint,
      onTap: canEquip
          ? () => controller.equipPlayerItem(item.instanceId, selectedSlot)
          : null,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactGearTag(
                  label: item.rarity.label,
                  tint: rarityTint,
                ),
              ),
              const SizedBox(width: 6),
              if (selectedSlot == null)
                _CompactGearTag(label: statusLabel, tint: statusTint)
              else
                FilledButton.tonal(
                  onPressed: canEquip
                      ? () => controller.equipPlayerItem(
                          item.instanceId,
                          selectedSlot,
                        )
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(58, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    equippedHere
                        ? 'Equipped'
                        : equippedSlot == null
                        ? 'Equip'
                        : 'Move',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(child: _GearBadge(item: item, size: 44)),
          ),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Lv ${item.level} • ${item.setName}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: item.affinity.color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              if (bonusLabels.isEmpty)
                _CompactGearTag(label: item.slotType.label, tint: statusTint)
              else
                for (final label in bonusLabels.take(2))
                  _CompactGearTag(label: label, tint: item.affinity.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _GearBadge extends StatelessWidget {
  const _GearBadge({this.item, this.slot, required this.size});

  final PlayerEquipmentItem? item;
  final EquipmentLoadoutSlot? slot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = item?.affinity.color ?? LightcorePalette.aether;
    final icon = _iconForSlot(item?.slotType ?? slot?.acceptedType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: item == null ? 0.18 : 0.34),
            LightcorePalette.panelRaised,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: tint.withValues(alpha: 0.7)),
      ),
      child: Icon(
        icon,
        size: size * 0.46,
        color: item == null
            ? LightcorePalette.mist.withValues(alpha: 0.8)
            : tint,
      ),
    );
  }
}

class _GearChip extends StatelessWidget {
  const _GearChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: LightcorePalette.mist,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactGearTag extends StatelessWidget {
  const _CompactGearTag({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

Color _loadoutTint(LightcoreController controller) {
  final sets = controller.activeEquipmentSets;
  if (sets.isNotEmpty) {
    return sets.first.config.affinity.color;
  }
  for (final slot in EquipmentLoadoutSlot.values) {
    final item = controller.equippedPlayerItemForSlot(slot);
    if (item != null) {
      return item.affinity.color;
    }
  }
  return LightcorePalette.aether;
}

Color _equipmentRarityTint(ManagerRarity rarity) => switch (rarity) {
  ManagerRarity.common => LightcorePalette.mist,
  ManagerRarity.uncommon => LightcorePalette.verdant,
  ManagerRarity.rare => LightcorePalette.aether,
  ManagerRarity.epic => LightcorePalette.violet,
  ManagerRarity.legendary => LightcorePalette.gilded,
};

IconData _iconForSlot(EquipmentInventorySlot? slot) => switch (slot) {
  EquipmentInventorySlot.hat => Icons.workspace_premium_rounded,
  EquipmentInventorySlot.top => Icons.shield_rounded,
  EquipmentInventorySlot.pants => Icons.vertical_split_rounded,
  EquipmentInventorySlot.shoes => Icons.route_rounded,
  EquipmentInventorySlot.accessory => Icons.auto_awesome_rounded,
  null => Icons.checkroom_rounded,
};

int _compareInventoryDisplayPriority(
  LightcoreController controller,
  PlayerEquipmentItem a,
  PlayerEquipmentItem b,
) {
  final equippedCompare = _equippedSortWeight(
    controller,
    b.instanceId,
  ).compareTo(_equippedSortWeight(controller, a.instanceId));
  if (equippedCompare != 0) {
    return equippedCompare;
  }
  final slotCompare = a.slotType.index.compareTo(b.slotType.index);
  if (slotCompare != 0) {
    return slotCompare;
  }
  final rarityCompare = b.rarity.score.compareTo(a.rarity.score);
  if (rarityCompare != 0) {
    return rarityCompare;
  }
  final levelCompare = b.level.compareTo(a.level);
  if (levelCompare != 0) {
    return levelCompare;
  }
  final recencyCompare = b.dropOrder.compareTo(a.dropOrder);
  if (recencyCompare != 0) {
    return recencyCompare;
  }
  return a.instanceId.compareTo(b.instanceId);
}

int _equippedSortWeight(LightcoreController controller, String itemId) =>
    controller.isPlayerItemEquipped(itemId) ? 1 : 0;

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
