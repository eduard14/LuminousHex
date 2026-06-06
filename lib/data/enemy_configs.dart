import '../models/lightcore_config.dart';
import '../models/lightcore_types.dart';

// TODO(full-game): Replace this library with versioned enemy/card content from
// downloaded manifests so drop tables and balance can change without a client
// redeploy.
class EnemyLibrary {
  static const double _baseSpeedPaceMultiplier = 1.15;

  static const EnemyConfig starterDefault = EnemyConfig(
    id: 'starter_default',
    name: 'Driftling Basic',
    summary:
        'Starter neutral anomaly used for onboarding before true Dustlings enter the deck.',
    traitLabel: 'Training body',
    encounterType: EnemyEncounterType.normal,
    affinity: PrototypeAffinity.neutral,
    rarity: EnemyCardRarity.basic,
    baseHealth: 8,
    baseDefense: 4,
    baseSpeed: 17,
    reward: 2,
    baseExperience: 2,
    jamStrength: 0.16,
    baseSpiralDrift: 0.3,
    splitsOnDeath: false,
    threatRewardMultiplier: 1,
    stabilityDamageMultiplier: 0.75,
  );

  static final List<_EnemyColorSeed> _colors = <_EnemyColorSeed>[
    const _EnemyColorSeed(
      idStem: 'white',
      name: 'White',
      displayName: 'Dustling',
      affinity: PrototypeAffinity.neutral,
      traitLabel: 'Baseline drift',
      summary:
          'White anomalies test fundamentals with clean pathing and no hidden trick.',
      healthMultiplier: 1.0,
      defenseMultiplier: 1.0,
      speedMultiplier: 1.0,
      rewardMultiplier: 1.0,
      experienceMultiplier: 1.0,
      threatRewardMultiplier: 1.0,
      stabilityDamageMultiplier: 1.0,
      jamMultiplier: 1.0,
      spiralMultiplier: 1.0,
      splitsOnDeath: false,
    ),
    const _EnemyColorSeed(
      idStem: 'red',
      name: 'Red',
      displayName: 'Huskflare',
      affinity: PrototypeAffinity.ember,
      traitLabel: 'Husk sink',
      summary:
          'Red anomalies behave like DPS sinks, stressing target priority and overkill control.',
      healthMultiplier: 1.16,
      defenseMultiplier: 1.12,
      speedMultiplier: 0.96,
      rewardMultiplier: 2.9,
      experienceMultiplier: 1.35,
      threatRewardMultiplier: 2.9,
      stabilityDamageMultiplier: 1.28,
      jamMultiplier: 1.12,
      spiralMultiplier: 1.0,
      splitsOnDeath: false,
    ),
    const _EnemyColorSeed(
      idStem: 'orange',
      name: 'Orange',
      displayName: 'Rushling',
      affinity: PrototypeAffinity.flare,
      traitLabel: 'Solar rush',
      summary: 'Orange anomalies sprint inward and punish slow target swaps.',
      healthMultiplier: 0.94,
      defenseMultiplier: 0.92,
      speedMultiplier: 1.34,
      rewardMultiplier: 1.75,
      experienceMultiplier: 2.45,
      threatRewardMultiplier: 1.75,
      stabilityDamageMultiplier: 1.18,
      jamMultiplier: 0.96,
      spiralMultiplier: 1.18,
      splitsOnDeath: false,
    ),
    const _EnemyColorSeed(
      idStem: 'yellow',
      name: 'Yellow',
      displayName: 'Blinkling',
      affinity: PrototypeAffinity.solar,
      traitLabel: 'Phase static',
      summary:
          'Yellow anomalies blink across awkward lanes, stressing accuracy and persistent fire.',
      healthMultiplier: 0.98,
      defenseMultiplier: 0.98,
      speedMultiplier: 1.1,
      rewardMultiplier: 2.05,
      experienceMultiplier: 2.9,
      threatRewardMultiplier: 2.05,
      stabilityDamageMultiplier: 1.2,
      jamMultiplier: 1.04,
      spiralMultiplier: 1.36,
      splitsOnDeath: false,
    ),
    const _EnemyColorSeed(
      idStem: 'green',
      name: 'Green',
      displayName: 'Mossmender',
      affinity: PrototypeAffinity.verdant,
      traitLabel: 'Nebula regen',
      summary:
          'Green anomalies recover if ignored, rewarding anti-regen and sustained focus.',
      healthMultiplier: 1.04,
      defenseMultiplier: 0.96,
      speedMultiplier: 0.98,
      rewardMultiplier: 2.15,
      experienceMultiplier: 2.3,
      threatRewardMultiplier: 2.15,
      stabilityDamageMultiplier: 1.16,
      jamMultiplier: 0.98,
      spiralMultiplier: 1.02,
      splitsOnDeath: false,
      regenFractionPerSecond: 0.012,
    ),
    const _EnemyColorSeed(
      idStem: 'blue',
      name: 'Blue',
      displayName: 'Jammer Cub',
      affinity: PrototypeAffinity.aether,
      traitLabel: 'Ion saboteur',
      summary:
          'Blue anomalies pressure the core through contact disruption and longer disables.',
      healthMultiplier: 1.1,
      defenseMultiplier: 1.08,
      speedMultiplier: 1.02,
      rewardMultiplier: 3.05,
      experienceMultiplier: 1.8,
      threatRewardMultiplier: 3.05,
      stabilityDamageMultiplier: 1.34,
      jamMultiplier: 1.34,
      spiralMultiplier: 1.0,
      splitsOnDeath: false,
    ),
    const _EnemyColorSeed(
      idStem: 'purple',
      name: 'Purple',
      displayName: 'Splitling',
      affinity: PrototypeAffinity.violet,
      traitLabel: 'Splits on kill',
      summary:
          'Purple anomalies split into child bodies and punish narrow single-target builds.',
      healthMultiplier: 1.0,
      defenseMultiplier: 1.05,
      speedMultiplier: 0.98,
      rewardMultiplier: 2.35,
      experienceMultiplier: 3.2,
      threatRewardMultiplier: 2.35,
      stabilityDamageMultiplier: 1.18,
      jamMultiplier: 1.0,
      spiralMultiplier: 1.08,
      splitsOnDeath: true,
    ),
    const _EnemyColorSeed(
      idStem: 'black',
      name: 'Black',
      displayName: 'Wormguard',
      affinity: PrototypeAffinity.black,
      traitLabel: 'Event mass',
      summary:
          'Black anomalies are special warp tanks, approximated by heavy stability pressure until redirect mechanics land.',
      healthMultiplier: 1.34,
      defenseMultiplier: 1.28,
      speedMultiplier: 0.86,
      rewardMultiplier: 4.2,
      experienceMultiplier: 2.6,
      threatRewardMultiplier: 4.2,
      stabilityDamageMultiplier: 1.62,
      jamMultiplier: 1.48,
      spiralMultiplier: 0.82,
      splitsOnDeath: false,
    ),
  ];

  static final List<_EnemyRaritySeed> _rarities = <_EnemyRaritySeed>[
    const _EnemyRaritySeed(
      rarity: EnemyCardRarity.basic,
      name: 'Basic',
      displayPrefix: '',
      baseHealth: 9,
      baseDefense: 6,
      baseSpeed: 19,
      reward: 2,
      baseExperience: 2,
      jamStrength: 0.2,
      baseSpiralDrift: 0.38,
    ),
    const _EnemyRaritySeed(
      rarity: EnemyCardRarity.uncommon,
      name: 'Uncommon',
      displayPrefix: 'Astral',
      baseHealth: 16,
      baseDefense: 10,
      baseSpeed: 20,
      reward: 4,
      baseExperience: 4,
      jamStrength: 0.28,
      baseSpiralDrift: 0.48,
    ),
    const _EnemyRaritySeed(
      rarity: EnemyCardRarity.rare,
      name: 'Rare',
      displayPrefix: 'Nebula',
      baseHealth: 27,
      baseDefense: 15,
      baseSpeed: 21,
      reward: 7,
      baseExperience: 7,
      jamStrength: 0.38,
      baseSpiralDrift: 0.58,
    ),
    const _EnemyRaritySeed(
      rarity: EnemyCardRarity.epic,
      name: 'Epic',
      displayPrefix: 'Antimatter',
      baseHealth: 48,
      baseDefense: 22,
      baseSpeed: 20,
      reward: 12,
      baseExperience: 12,
      jamStrength: 0.5,
      baseSpiralDrift: 0.68,
    ),
    const _EnemyRaritySeed(
      rarity: EnemyCardRarity.legendary,
      name: 'Legendary',
      displayPrefix: 'Singularity',
      baseHealth: 86,
      baseDefense: 32,
      baseSpeed: 19,
      reward: 20,
      baseExperience: 20,
      jamStrength: 0.64,
      baseSpiralDrift: 0.78,
    ),
  ];

  static final List<EnemyConfig> all = [
    for (final rarity in _rarities)
      for (final color in _colors) _buildConfig(color, rarity),
  ];

  static final Map<EnemyCardRarity, List<EnemyConfig>> byRarity = {
    for (final rarity in EnemyCardRarity.values)
      rarity: all.where((config) => config.rarity == rarity).toList(),
  };

  static EnemyConfig get basicWhite => all.firstWhere(
    (config) =>
        config.rarity == EnemyCardRarity.basic &&
        config.id != starterDefault.id &&
        config.affinity == PrototypeAffinity.neutral,
  );

  static EnemyConfig get basicRed => all.firstWhere(
    (config) =>
        config.rarity == EnemyCardRarity.basic &&
        config.affinity == PrototypeAffinity.ember,
  );

  static EnemyConfig _buildConfig(
    _EnemyColorSeed color,
    _EnemyRaritySeed rarity,
  ) {
    final displayName = rarity.displayPrefix.isEmpty
        ? color.displayName
        : '${rarity.displayPrefix} ${color.displayName}';
    return EnemyConfig(
      id: '${color.idStem}_${rarity.name.toLowerCase()}',
      name: displayName,
      summary: color.summary,
      traitLabel: color.traitLabel,
      encounterType: EnemyEncounterType.normal,
      affinity: color.affinity,
      rarity: rarity.rarity,
      baseHealth: rarity.baseHealth * color.healthMultiplier,
      baseDefense: rarity.baseDefense * color.defenseMultiplier,
      baseSpeed:
          rarity.baseSpeed * color.speedMultiplier * _baseSpeedPaceMultiplier,
      reward: (rarity.reward * color.rewardMultiplier).round(),
      baseExperience: (rarity.baseExperience * color.experienceMultiplier)
          .round(),
      jamStrength: rarity.jamStrength * color.jamMultiplier,
      baseSpiralDrift: rarity.baseSpiralDrift * color.spiralMultiplier,
      splitsOnDeath: color.splitsOnDeath,
      threatRewardMultiplier: color.threatRewardMultiplier,
      stabilityDamageMultiplier: color.stabilityDamageMultiplier,
      regenFractionPerSecond:
          color.regenFractionPerSecond * (1 + (rarity.rarity.index * 0.18)),
    );
  }
}

class _EnemyColorSeed {
  const _EnemyColorSeed({
    required this.idStem,
    required this.name,
    required this.displayName,
    required this.affinity,
    required this.traitLabel,
    required this.summary,
    required this.healthMultiplier,
    required this.defenseMultiplier,
    required this.speedMultiplier,
    required this.rewardMultiplier,
    required this.experienceMultiplier,
    required this.threatRewardMultiplier,
    required this.stabilityDamageMultiplier,
    required this.jamMultiplier,
    required this.spiralMultiplier,
    required this.splitsOnDeath,
    this.regenFractionPerSecond = 0,
  });

  final String idStem;
  final String name;
  final String displayName;
  final PrototypeAffinity affinity;
  final String traitLabel;
  final String summary;
  final double healthMultiplier;
  final double defenseMultiplier;
  final double speedMultiplier;
  final double rewardMultiplier;
  final double experienceMultiplier;
  final double threatRewardMultiplier;
  final double stabilityDamageMultiplier;
  final double jamMultiplier;
  final double spiralMultiplier;
  final bool splitsOnDeath;
  final double regenFractionPerSecond;
}

class _EnemyRaritySeed {
  const _EnemyRaritySeed({
    required this.rarity,
    required this.name,
    required this.displayPrefix,
    required this.baseHealth,
    required this.baseDefense,
    required this.baseSpeed,
    required this.reward,
    required this.baseExperience,
    required this.jamStrength,
    required this.baseSpiralDrift,
  });

  final EnemyCardRarity rarity;
  final String name;
  final String displayPrefix;
  final double baseHealth;
  final double baseDefense;
  final double baseSpeed;
  final int reward;
  final int baseExperience;
  final double jamStrength;
  final double baseSpiralDrift;
}

class BossEnemyLibrary {
  static const double _baseSpeedPaceMultiplier = 1.15;

  static const List<_BossRaritySeed> _rarities = <_BossRaritySeed>[
    _BossRaritySeed(
      rarity: EnemyCardRarity.basic,
      titlePrefix: '',
      baseHealth: 1800,
      baseDefense: 72,
      baseSpeed: 12.8,
      reward: 90,
      baseExperience: 90,
      jamStrength: 0.72,
      baseSpiralDrift: 0.24,
    ),
    _BossRaritySeed(
      rarity: EnemyCardRarity.uncommon,
      titlePrefix: 'Awakened',
      baseHealth: 2280,
      baseDefense: 92,
      baseSpeed: 12.3,
      reward: 118,
      baseExperience: 118,
      jamStrength: 0.8,
      baseSpiralDrift: 0.26,
    ),
    _BossRaritySeed(
      rarity: EnemyCardRarity.rare,
      titlePrefix: 'Ascendant',
      baseHealth: 2860,
      baseDefense: 114,
      baseSpeed: 11.9,
      reward: 150,
      baseExperience: 150,
      jamStrength: 0.88,
      baseSpiralDrift: 0.28,
    ),
    _BossRaritySeed(
      rarity: EnemyCardRarity.epic,
      titlePrefix: 'Mythic',
      baseHealth: 3560,
      baseDefense: 142,
      baseSpeed: 11.4,
      reward: 190,
      baseExperience: 190,
      jamStrength: 0.96,
      baseSpiralDrift: 0.3,
    ),
    _BossRaritySeed(
      rarity: EnemyCardRarity.legendary,
      titlePrefix: 'Cataclysm',
      baseHealth: 4380,
      baseDefense: 176,
      baseSpeed: 11.0,
      reward: 238,
      baseExperience: 238,
      jamStrength: 1.04,
      baseSpiralDrift: 0.32,
    ),
  ];

  static const List<_BossArchetypeSeed> _basicSet = <_BossArchetypeSeed>[
    _BossArchetypeSeed(
      idStem: 'white_warden',
      name: 'The Pale Equation',
      summary:
          'Neutral starter boss with stable drift and a lighter front wall.',
      traitLabel: 'Starter fortress',
      primaryAffinity: PrototypeAffinity.neutral,
      healthMultiplier: 0.64,
      defenseMultiplier: 0.62,
      speedMultiplier: 0.82,
      rewardMultiplier: 1.0,
      jamMultiplier: 0.72,
      driftMultiplier: 0.78,
    ),
    _BossArchetypeSeed(
      idStem: 'ember_colossus',
      name: 'Huskstar Rex',
      summary: 'Red boss that crushes lanes and leans hardest into defense.',
      traitLabel: 'Defense wall',
      primaryAffinity: PrototypeAffinity.ember,
      healthMultiplier: 1.08,
      defenseMultiplier: 1.16,
      speedMultiplier: 0.92,
      rewardMultiplier: 1.04,
      jamMultiplier: 1.1,
      driftMultiplier: 0.9,
    ),
    _BossArchetypeSeed(
      idStem: 'flare_tempest',
      name: 'Comet Khan',
      summary: 'Orange boss with wider drift and faster field pressure.',
      traitLabel: 'Wide cyclone',
      primaryAffinity: PrototypeAffinity.flare,
      healthMultiplier: 0.98,
      defenseMultiplier: 0.92,
      speedMultiplier: 1.04,
      rewardMultiplier: 1.02,
      jamMultiplier: 0.96,
      driftMultiplier: 1.18,
    ),
    _BossArchetypeSeed(
      idStem: 'solar_titan',
      name: 'Parallax Jack',
      summary: 'Yellow boss with dense plating and the fattest direct payout.',
      traitLabel: 'Solar bulk',
      primaryAffinity: PrototypeAffinity.solar,
      healthMultiplier: 1.14,
      defenseMultiplier: 1.1,
      speedMultiplier: 0.9,
      rewardMultiplier: 1.12,
      jamMultiplier: 1.02,
      driftMultiplier: 0.88,
    ),
    _BossArchetypeSeed(
      idStem: 'verdant_devourer',
      name: 'Mother Moss Nova',
      summary: 'Green boss that rushes inward and pressures empty lanes hard.',
      traitLabel: 'Rush predator',
      primaryAffinity: PrototypeAffinity.verdant,
      healthMultiplier: 0.96,
      defenseMultiplier: 0.9,
      speedMultiplier: 1.18,
      rewardMultiplier: 1.02,
      jamMultiplier: 0.92,
      driftMultiplier: 1.04,
    ),
    _BossArchetypeSeed(
      idStem: 'aether_seraph',
      name: 'The Ion Warden',
      summary: 'Blue boss with shield-heavy stats and sharp entry lines.',
      traitLabel: 'Shielded arc',
      primaryAffinity: PrototypeAffinity.aether,
      healthMultiplier: 1.06,
      defenseMultiplier: 1.2,
      speedMultiplier: 0.98,
      rewardMultiplier: 1.06,
      jamMultiplier: 1.0,
      driftMultiplier: 0.96,
    ),
    _BossArchetypeSeed(
      idStem: 'violet_overmind',
      name: 'The Gemini Maw',
      summary: 'Purple boss with unstable mass and the deepest loot payload.',
      traitLabel: 'Void core',
      primaryAffinity: PrototypeAffinity.violet,
      healthMultiplier: 1.18,
      defenseMultiplier: 1.02,
      speedMultiplier: 0.94,
      rewardMultiplier: 1.18,
      jamMultiplier: 1.06,
      driftMultiplier: 1.08,
    ),
  ];

  static const List<_BossArchetypeSeed> _advancedSet = <_BossArchetypeSeed>[
    _BossArchetypeSeed(
      idStem: 'ashen_warden',
      name: 'The Eclipse Custodian',
      summary:
          'A white-red gatekeeper that layers fortress armor over ember surge.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.neutral,
      secondaryAffinity: PrototypeAffinity.ember,
      immunityAffinity: PrototypeAffinity.violet,
      regenFractionPerSecond: 0.012,
      healthMultiplier: 1.08,
      defenseMultiplier: 1.14,
      speedMultiplier: 0.96,
      rewardMultiplier: 1.04,
      jamMultiplier: 1.04,
      driftMultiplier: 0.96,
    ),
    _BossArchetypeSeed(
      idStem: 'cindermaw_colossus',
      name: 'The Crash Warden',
      summary:
          'A red-orange raid beast that rolls forward under a burning shield.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.ember,
      secondaryAffinity: PrototypeAffinity.flare,
      immunityAffinity: PrototypeAffinity.verdant,
      spawnIntervalSeconds: 7.0,
      spawnCount: 2,
      healthMultiplier: 1.1,
      defenseMultiplier: 1.08,
      speedMultiplier: 0.98,
      rewardMultiplier: 1.08,
      jamMultiplier: 1.12,
      driftMultiplier: 1.02,
    ),
    _BossArchetypeSeed(
      idStem: 'solburst_tempest',
      name: 'Shatterblink Colossus',
      summary:
          'An orange-yellow storm core that circles wider while banking huge bounty.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.flare,
      secondaryAffinity: PrototypeAffinity.solar,
      immunityAffinity: PrototypeAffinity.aether,
      regenFractionPerSecond: 0.015,
      healthMultiplier: 1.02,
      defenseMultiplier: 0.98,
      speedMultiplier: 1.04,
      rewardMultiplier: 1.12,
      jamMultiplier: 1.0,
      driftMultiplier: 1.16,
    ),
    _BossArchetypeSeed(
      idStem: 'bloom_titan',
      name: 'The Springlight Engine',
      summary:
          'A yellow-green warform that turns into a wall, then spills fresh bodies.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.solar,
      secondaryAffinity: PrototypeAffinity.verdant,
      immunityAffinity: PrototypeAffinity.ember,
      spawnIntervalSeconds: 6.8,
      spawnCount: 2,
      healthMultiplier: 1.14,
      defenseMultiplier: 1.1,
      speedMultiplier: 0.94,
      rewardMultiplier: 1.1,
      jamMultiplier: 1.04,
      driftMultiplier: 0.92,
    ),
    _BossArchetypeSeed(
      idStem: 'tidebriar_devourer',
      name: 'Triage Star Leviathan',
      summary:
          'A green-blue hunter that keeps pace up while knitting itself back together.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.verdant,
      secondaryAffinity: PrototypeAffinity.aether,
      immunityAffinity: PrototypeAffinity.flare,
      regenFractionPerSecond: 0.018,
      healthMultiplier: 1.02,
      defenseMultiplier: 1.04,
      speedMultiplier: 1.14,
      rewardMultiplier: 1.08,
      jamMultiplier: 0.96,
      driftMultiplier: 1.0,
    ),
    _BossArchetypeSeed(
      idStem: 'void_seraph',
      name: 'The Blooming Splitter',
      summary:
          'A blue-purple overseer that shields the lane and releases escort threats.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.aether,
      secondaryAffinity: PrototypeAffinity.violet,
      immunityAffinity: PrototypeAffinity.solar,
      spawnIntervalSeconds: 6.4,
      spawnCount: 3,
      healthMultiplier: 1.06,
      defenseMultiplier: 1.18,
      speedMultiplier: 0.98,
      rewardMultiplier: 1.1,
      jamMultiplier: 1.02,
      driftMultiplier: 0.98,
    ),
    _BossArchetypeSeed(
      idStem: 'overmind_reaver',
      name: 'The Dead Fractal',
      summary:
          'A purple-red apex tyrant that feeds on tempo and stacks every bad trait at once.',
      traitLabel: 'Dual prism body',
      primaryAffinity: PrototypeAffinity.violet,
      secondaryAffinity: PrototypeAffinity.ember,
      immunityAffinity: PrototypeAffinity.aether,
      regenFractionPerSecond: 0.014,
      spawnIntervalSeconds: 6.1,
      spawnCount: 2,
      healthMultiplier: 1.16,
      defenseMultiplier: 1.08,
      speedMultiplier: 1.0,
      rewardMultiplier: 1.16,
      jamMultiplier: 1.1,
      driftMultiplier: 1.1,
    ),
    _BossArchetypeSeed(
      idStem: 'nullstar_cartographer',
      name: 'The Nullstar Cartographer',
      summary:
          'A black-white map tyrant that marks lanes before the wave arrives.',
      traitLabel: 'Surveyed eclipse',
      primaryAffinity: PrototypeAffinity.black,
      secondaryAffinity: PrototypeAffinity.neutral,
      immunityAffinity: PrototypeAffinity.flare,
      spawnIntervalSeconds: 6.6,
      spawnCount: 2,
      healthMultiplier: 1.12,
      defenseMultiplier: 1.16,
      speedMultiplier: 0.92,
      rewardMultiplier: 1.14,
      jamMultiplier: 1.12,
      driftMultiplier: 0.94,
    ),
    _BossArchetypeSeed(
      idStem: 'chronoglass_bastion',
      name: 'Chronoglass Bastion',
      summary:
          'A black-yellow siege mind that slows the lane, then overpays the clear.',
      traitLabel: 'Time-shear armor',
      primaryAffinity: PrototypeAffinity.black,
      secondaryAffinity: PrototypeAffinity.solar,
      immunityAffinity: PrototypeAffinity.verdant,
      regenFractionPerSecond: 0.01,
      spawnIntervalSeconds: 7.2,
      spawnCount: 2,
      healthMultiplier: 1.18,
      defenseMultiplier: 1.2,
      speedMultiplier: 0.86,
      rewardMultiplier: 1.2,
      jamMultiplier: 1.16,
      driftMultiplier: 0.88,
    ),
  ];

  static final List<EnemyConfig> all = <EnemyConfig>[
    for (final seed in _basicSet) _buildConfig(seed, _rarities.first),
    for (final rarity in _rarities.skip(1))
      for (final seed in _advancedSet) _buildConfig(seed, rarity),
  ];

  static final Map<EnemyCardRarity, List<EnemyConfig>> byRarity = {
    for (final rarity in EnemyCardRarity.values)
      rarity: all.where((config) => config.rarity == rarity).toList(),
  };

  static EnemyConfig get starter => byRarity[EnemyCardRarity.basic]!.first;

  static EnemyConfig get starterWhiteWarden => starter;

  static EnemyConfig _buildConfig(
    _BossArchetypeSeed seed,
    _BossRaritySeed rarity,
  ) {
    final advanced = rarity.rarity != EnemyCardRarity.basic;
    final hasImmunity = rarity.rarity.index >= EnemyCardRarity.rare.index;
    final hasAbility = rarity.rarity.index >= EnemyCardRarity.epic.index;
    final legendary = rarity.rarity == EnemyCardRarity.legendary;
    final namePrefix = rarity.titlePrefix.isEmpty
        ? ''
        : '${rarity.titlePrefix} ';
    final summary = advanced
        ? _advancedSummary(
            seed: seed,
            hasImmunity: hasImmunity,
            hasAbility: hasAbility,
            legendary: legendary,
          )
        : seed.summary;

    return EnemyConfig(
      id: 'boss_${rarity.rarity.name}_${seed.idStem}',
      name: '$namePrefix${seed.name}',
      summary: summary,
      traitLabel: _traitLabel(
        seed: seed,
        hasImmunity: hasImmunity,
        hasAbility: hasAbility,
      ),
      encounterType: EnemyEncounterType.boss,
      affinity: seed.primaryAffinity,
      secondaryAffinity: advanced ? seed.secondaryAffinity : null,
      rarity: rarity.rarity,
      baseHealth:
          rarity.baseHealth * seed.healthMultiplier * (legendary ? 1.12 : 1.0),
      baseDefense:
          rarity.baseDefense *
          seed.defenseMultiplier *
          (legendary ? 1.08 : 1.0),
      baseSpeed:
          rarity.baseSpeed *
          seed.speedMultiplier *
          _baseSpeedPaceMultiplier *
          (legendary ? 1.02 : 1.0),
      reward: (rarity.reward * seed.rewardMultiplier * (legendary ? 1.18 : 1.0))
          .round(),
      baseExperience:
          (rarity.baseExperience *
                  seed.rewardMultiplier *
                  (legendary ? 1.18 : 1.0))
              .round(),
      jamStrength:
          rarity.jamStrength * seed.jamMultiplier * (legendary ? 1.05 : 1.0),
      baseSpiralDrift:
          rarity.baseSpiralDrift *
          seed.driftMultiplier *
          (legendary ? 1.04 : 1.0),
      splitsOnDeath: false,
      threatRewardMultiplier: 2.4 + (rarity.rarity.index * 0.55),
      stabilityDamageMultiplier: 1.0,
      immunityAffinities: hasImmunity && seed.immunityAffinity != null
          ? <PrototypeAffinity>[seed.immunityAffinity!]
          : const <PrototypeAffinity>[],
      regenFractionPerSecond: hasAbility
          ? seed.regenFractionPerSecond * (legendary ? 1.4 : 1.0)
          : 0,
      spawnIntervalSeconds: hasAbility
          ? seed.spawnIntervalSeconds * (legendary ? 0.84 : 1.0)
          : 0,
      spawnCount: hasAbility
          ? seed.spawnCount + (legendary && seed.spawnCount > 0 ? 1 : 0)
          : 0,
    );
  }

  static String _traitLabel({
    required _BossArchetypeSeed seed,
    required bool hasImmunity,
    required bool hasAbility,
  }) {
    if (!hasImmunity && !hasAbility) {
      return seed.traitLabel;
    }
    if (hasAbility && seed.regenFractionPerSecond > 0 && seed.spawnCount > 0) {
      return 'Raid tyrant';
    }
    if (hasAbility && seed.regenFractionPerSecond > 0) {
      return hasImmunity ? 'Prism ward • Regen' : 'Regenerating shell';
    }
    if (hasAbility && seed.spawnCount > 0) {
      return hasImmunity ? 'Prism ward • Spawns' : 'Spawner shell';
    }
    return 'Prism ward';
  }

  static String _advancedSummary({
    required _BossArchetypeSeed seed,
    required bool hasImmunity,
    required bool hasAbility,
    required bool legendary,
  }) {
    final colors =
        '${seed.primaryAffinity.label}/${seed.secondaryAffinity?.label ?? seed.primaryAffinity.label}';
    final details = <String>[
      '$colors hybrid boss frame',
      if (hasImmunity && seed.immunityAffinity != null)
        'immune to ${seed.immunityAffinity!.label}',
      if (hasAbility && seed.regenFractionPerSecond > 0) 'slow self-regen',
      if (hasAbility && seed.spawnCount > 0) 'spawns escorts',
      if (legendary) 'cataclysm payout',
    ];
    return '${seed.summary} ${details.join(' • ')}.';
  }
}

class _BossRaritySeed {
  const _BossRaritySeed({
    required this.rarity,
    required this.titlePrefix,
    required this.baseHealth,
    required this.baseDefense,
    required this.baseSpeed,
    required this.reward,
    required this.baseExperience,
    required this.jamStrength,
    required this.baseSpiralDrift,
  });

  final EnemyCardRarity rarity;
  final String titlePrefix;
  final double baseHealth;
  final double baseDefense;
  final double baseSpeed;
  final int reward;
  final int baseExperience;
  final double jamStrength;
  final double baseSpiralDrift;
}

class _BossArchetypeSeed {
  const _BossArchetypeSeed({
    required this.idStem,
    required this.name,
    required this.summary,
    required this.traitLabel,
    required this.primaryAffinity,
    this.secondaryAffinity,
    this.immunityAffinity,
    this.regenFractionPerSecond = 0,
    this.spawnIntervalSeconds = 0,
    this.spawnCount = 0,
    this.healthMultiplier = 1,
    this.defenseMultiplier = 1,
    this.speedMultiplier = 1,
    this.rewardMultiplier = 1,
    this.jamMultiplier = 1,
    this.driftMultiplier = 1,
  });

  final String idStem;
  final String name;
  final String summary;
  final String traitLabel;
  final PrototypeAffinity primaryAffinity;
  final PrototypeAffinity? secondaryAffinity;
  final PrototypeAffinity? immunityAffinity;
  final double regenFractionPerSecond;
  final double spawnIntervalSeconds;
  final int spawnCount;
  final double healthMultiplier;
  final double defenseMultiplier;
  final double speedMultiplier;
  final double rewardMultiplier;
  final double jamMultiplier;
  final double driftMultiplier;
}
