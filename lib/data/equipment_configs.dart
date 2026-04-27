import '../models/lightcore_config.dart';
import '../models/lightcore_types.dart';

class EquipmentLibrary {
  static final List<EquipmentSetConfig> all = <EquipmentSetConfig>[
    EquipmentSetConfig(
      id: 'surveyor',
      name: 'Surveyor',
      affinity: PrototypeAffinity.neutral,
      dropLabel: 'White enemies drop Surveyor outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Surveyor Visor',
        top: 'Surveyor Jacket',
        pants: 'Surveyor Slacks',
        shoes: 'Surveyor Boots',
        accessory: 'Surveyor Badge',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(critChance: 0.018, dropRate: 0.01),
        top: EquipmentBonusProfile(towerPower: 0.035, lumenGain: 0.015),
        pants: EquipmentBonusProfile(chargeRate: 0.03, fluxGain: 0.015),
        shoes: EquipmentBonusProfile(range: 0.03, ticketGain: 0.01),
        accessory: EquipmentBonusProfile(critDamage: 0.05, dropRate: 0.008),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Charted Lanes',
          bonuses: EquipmentBonusProfile(range: 0.025, lumenGain: 0.02),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Measured Impact',
          bonuses: EquipmentBonusProfile(towerPower: 0.04, critChance: 0.015),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Full Survey Grid',
          bonuses: EquipmentBonusProfile(dropRate: 0.06, fluxGain: 0.08),
        ),
      ],
    ),
    EquipmentSetConfig(
      id: 'ashspike',
      name: 'Ashspike',
      affinity: PrototypeAffinity.ember,
      dropLabel: 'Red enemies drop Ashspike outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Ashspike Horncap',
        top: 'Ashspike Coat',
        pants: 'Ashspike Chaps',
        shoes: 'Ashspike Boots',
        accessory: 'Ashspike Fang',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(bossDamage: 0.03, critChance: 0.012),
        top: EquipmentBonusProfile(towerPower: 0.045),
        pants: EquipmentBonusProfile(chargeRate: 0.025, bossDamage: 0.02),
        shoes: EquipmentBonusProfile(range: 0.018, fluxGain: 0.02),
        accessory: EquipmentBonusProfile(critDamage: 0.06),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Heat Stack',
          bonuses: EquipmentBonusProfile(towerPower: 0.04),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Apex Breaker',
          bonuses: EquipmentBonusProfile(bossDamage: 0.09),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Volcanic Finish',
          bonuses: EquipmentBonusProfile(critDamage: 0.12, fluxGain: 0.05),
        ),
      ],
    ),
    EquipmentSetConfig(
      id: 'embertrail',
      name: 'Embertrail',
      affinity: PrototypeAffinity.flare,
      dropLabel: 'Orange enemies drop Embertrail outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Embertrail Hood',
        top: 'Embertrail Wrap',
        pants: 'Embertrail Leggings',
        shoes: 'Embertrail Runners',
        accessory: 'Embertrail Charm',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(chargeRate: 0.03, dropRate: 0.01),
        top: EquipmentBonusProfile(towerPower: 0.03, range: 0.02),
        pants: EquipmentBonusProfile(chargeRate: 0.03, ticketGain: 0.015),
        shoes: EquipmentBonusProfile(range: 0.04),
        accessory: EquipmentBonusProfile(critDamage: 0.04, ticketGain: 0.02),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Wide Orbit',
          bonuses: EquipmentBonusProfile(chargeRate: 0.05, range: 0.03),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Trail Burst',
          bonuses: EquipmentBonusProfile(towerPower: 0.05, critChance: 0.012),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Loot Sweep',
          bonuses: EquipmentBonusProfile(ticketGain: 0.08, dropRate: 0.04),
        ),
      ],
    ),
    EquipmentSetConfig(
      id: 'sunplate',
      name: 'Sunplate',
      affinity: PrototypeAffinity.solar,
      dropLabel: 'Yellow enemies drop Sunplate outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Sunplate Crown',
        top: 'Sunplate Cuirass',
        pants: 'Sunplate Greaves',
        shoes: 'Sunplate Sabatons',
        accessory: 'Sunplate Seal',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(fluxGain: 0.03, dropRate: 0.008),
        top: EquipmentBonusProfile(towerPower: 0.04, fluxGain: 0.02),
        pants: EquipmentBonusProfile(bossDamage: 0.025, fluxGain: 0.02),
        shoes: EquipmentBonusProfile(range: 0.025, chargeRate: 0.02),
        accessory: EquipmentBonusProfile(critDamage: 0.05, fluxGain: 0.03),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Gilded Income',
          bonuses: EquipmentBonusProfile(fluxGain: 0.06),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Sun Hammer',
          bonuses: EquipmentBonusProfile(towerPower: 0.06, bossDamage: 0.06),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Treasure Halo',
          bonuses: EquipmentBonusProfile(dropRate: 0.06, ticketGain: 0.05),
        ),
      ],
    ),
    EquipmentSetConfig(
      id: 'thornpath',
      name: 'Thornpath',
      affinity: PrototypeAffinity.verdant,
      dropLabel: 'Green enemies drop Thornpath outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Thornpath Hood',
        top: 'Thornpath Vinecoat',
        pants: 'Thornpath Briars',
        shoes: 'Thornpath Trackboots',
        accessory: 'Thornpath Charm',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(dropRate: 0.015, critChance: 0.014),
        top: EquipmentBonusProfile(chargeRate: 0.03, towerPower: 0.02),
        pants: EquipmentBonusProfile(bossDamage: 0.02, lumenGain: 0.02),
        shoes: EquipmentBonusProfile(range: 0.03, chargeRate: 0.03),
        accessory: EquipmentBonusProfile(critDamage: 0.04, dropRate: 0.012),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Rush Route',
          bonuses: EquipmentBonusProfile(chargeRate: 0.05),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Needle Focus',
          bonuses: EquipmentBonusProfile(critChance: 0.02, range: 0.04),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Wild Harvest',
          bonuses: EquipmentBonusProfile(dropRate: 0.08, lumenGain: 0.06),
        ),
      ],
    ),
    EquipmentSetConfig(
      id: 'tideglass',
      name: 'Tideglass',
      affinity: PrototypeAffinity.aether,
      dropLabel: 'Blue enemies drop Tideglass outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Tideglass Circlet',
        top: 'Tideglass Mantle',
        pants: 'Tideglass Leggings',
        shoes: 'Tideglass Waders',
        accessory: 'Tideglass Lens',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(critChance: 0.016, lumenGain: 0.015),
        top: EquipmentBonusProfile(towerPower: 0.03, range: 0.02),
        pants: EquipmentBonusProfile(fluxGain: 0.02, ticketGain: 0.015),
        shoes: EquipmentBonusProfile(range: 0.04, chargeRate: 0.02),
        accessory: EquipmentBonusProfile(critDamage: 0.05, lumenGain: 0.02),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Clear Sight',
          bonuses: EquipmentBonusProfile(range: 0.05),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Refraction Pulse',
          bonuses: EquipmentBonusProfile(critDamage: 0.1, towerPower: 0.05),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Blue Current',
          bonuses: EquipmentBonusProfile(lumenGain: 0.08, ticketGain: 0.06),
        ),
      ],
    ),
    EquipmentSetConfig(
      id: 'voidloom',
      name: 'Voidloom',
      affinity: PrototypeAffinity.violet,
      dropLabel: 'Purple enemies drop Voidloom outfit pieces.',
      pieceNames: _pieceNames(
        hat: 'Voidloom Hood',
        top: 'Voidloom Raiment',
        pants: 'Voidloom Leggings',
        shoes: 'Voidloom Slippers',
        accessory: 'Voidloom Sigil',
      ),
      slotBonuses: _slotBonuses(
        hat: EquipmentBonusProfile(critChance: 0.02, bossDamage: 0.015),
        top: EquipmentBonusProfile(towerPower: 0.03, critDamage: 0.03),
        pants: EquipmentBonusProfile(chargeRate: 0.025, bossDamage: 0.025),
        shoes: EquipmentBonusProfile(range: 0.025, dropRate: 0.01),
        accessory: EquipmentBonusProfile(critDamage: 0.06, critChance: 0.01),
      ),
      setBonuses: const <EquipmentSetBonusConfig>[
        EquipmentSetBonusConfig(
          pieceCount: 2,
          label: 'Dark Aim',
          bonuses: EquipmentBonusProfile(critChance: 0.02),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 4,
          label: 'Fracture Bloom',
          bonuses: EquipmentBonusProfile(critDamage: 0.12, bossDamage: 0.08),
        ),
        EquipmentSetBonusConfig(
          pieceCount: 6,
          label: 'Rare Bloom',
          bonuses: EquipmentBonusProfile(dropRate: 0.06, towerPower: 0.07),
        ),
      ],
    ),
  ];

  static final Map<String, EquipmentSetConfig> byId =
      <String, EquipmentSetConfig>{for (final set in all) set.id: set};

  static final Map<PrototypeAffinity, EquipmentSetConfig> _byAffinity =
      <PrototypeAffinity, EquipmentSetConfig>{
        for (final set in all) set.affinity: set,
      };

  static EquipmentSetConfig forEnemy(EnemyConfig config) =>
      _byAffinity[config.affinity] ?? all.first;
}

Map<EquipmentInventorySlot, String> _pieceNames({
  required String hat,
  required String top,
  required String pants,
  required String shoes,
  required String accessory,
}) => <EquipmentInventorySlot, String>{
  EquipmentInventorySlot.hat: hat,
  EquipmentInventorySlot.top: top,
  EquipmentInventorySlot.pants: pants,
  EquipmentInventorySlot.shoes: shoes,
  EquipmentInventorySlot.accessory: accessory,
};

Map<EquipmentInventorySlot, EquipmentBonusProfile> _slotBonuses({
  required EquipmentBonusProfile hat,
  required EquipmentBonusProfile top,
  required EquipmentBonusProfile pants,
  required EquipmentBonusProfile shoes,
  required EquipmentBonusProfile accessory,
}) => <EquipmentInventorySlot, EquipmentBonusProfile>{
  EquipmentInventorySlot.hat: hat,
  EquipmentInventorySlot.top: top,
  EquipmentInventorySlot.pants: pants,
  EquipmentInventorySlot.shoes: shoes,
  EquipmentInventorySlot.accessory: accessory,
};
