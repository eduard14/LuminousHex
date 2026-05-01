enum PrototypeAffinity {
  neutral,
  ember,
  flare,
  solar,
  verdant,
  aether,
  violet,
  black,
}

enum EnemyCardRarity { basic, uncommon, rare, epic, legendary }

enum EnemyEncounterType { normal, boss }

enum EnemyPackHighlightTier { standard, secondHighest, highest }

enum ManagerRarity { common, uncommon, rare, epic, legendary }

enum ProjectileRarity { common, uncommon, rare, epic, legendary }

enum ProjectileType {
  starBolt,
  threadBeam,
  heavyShot,
  coreBomb,
  chainArc,
  pulseRing,
  orbitNode,
  shieldHalo,
  rapidBolt,
  twinBolt,
  pulseBeam,
  splitBeam,
  breakerShot,
  crushShot,
  pulseBomb,
  clusterBomb,
  forkArc,
  arcNode,
  echoRing,
  collapseRing,
  sweepNode,
  slingNode,
  sweepBeam,
  lanceBeam,
  prismBeam,
  sentinelBeam,
  siegeShot,
  drillShot,
  ricochetShot,
  hunterShip,
  novaBomb,
  cascadeBomb,
  fieldBomb,
  bomberShip,
  stormArc,
  webArc,
  skyArc,
  interceptorShip,
  haloWave,
  spiralWave,
  warpWave,
  shadeSatellite,
  haloNodes,
  anchorNode,
  flailNode,
  familiarShip,
}

enum PayloadType {
  none,
  precision,
  doubleTap,
  chill,
  fracture,
  rend,
  force,
  overheat,
  detonate,
  shock,
  disrupt,
  expose,
  pull,
  corrupt,
  spread,
  deepChill,
  brittleFracture,
  coreRend,
  concussiveForce,
  meltdown,
  chainDetonate,
  overload,
  empDisrupt,
  collapse,
  singularityPull,
  cascadeCorrupt,
  viralSpread,
}

enum ProjectileBehaviorProfile {
  thread,
  pulse,
  burst,
  chain,
  split,
  lance,
  explosion,
  wave,
  nova,
}

enum PayloadEffectProfile { none, burn, freeze, shock, knockback, bounty }

enum TargetPriority { close, strong, weak }

enum EquipmentInventorySlot { hat, top, pants, shoes, accessory }

enum EquipmentLoadoutSlot {
  hat,
  top,
  pants,
  shoes,
  accessoryPrimary,
  accessorySecondary,
}

enum TowerUpgradeStatType {
  power,
  chargeRate,
  cooldown,
  range,
  generationSpeed,
  critChance,
  critDamage,
  finalDamage,
  bossDamage,
  normalDamage,
  defensePenetration,
  minDamage,
  maxDamage,
  dotDamage,
}

enum ChildTowerUpgradeType {
  power,
  chargeRate,
  cooldown,
  range,
  generationSpeed,
  critChance,
  critDamage,
  finalDamage,
  bossDamage,
  normalDamage,
  defensePenetration,
  minDamage,
  maxDamage,
}

extension PrototypeAffinityX on PrototypeAffinity {
  String get label => switch (this) {
    PrototypeAffinity.neutral => 'White',
    PrototypeAffinity.ember => 'Red',
    PrototypeAffinity.flare => 'Orange',
    PrototypeAffinity.solar => 'Yellow',
    PrototypeAffinity.verdant => 'Green',
    PrototypeAffinity.aether => 'Blue',
    PrototypeAffinity.violet => 'Purple',
    PrototypeAffinity.black => 'Black',
  };

  String get shortLabel => switch (this) {
    PrototypeAffinity.neutral => 'WHT',
    PrototypeAffinity.ember => 'RED',
    PrototypeAffinity.flare => 'ORG',
    PrototypeAffinity.solar => 'YEL',
    PrototypeAffinity.verdant => 'GRN',
    PrototypeAffinity.aether => 'BLU',
    PrototypeAffinity.violet => 'PUR',
    PrototypeAffinity.black => 'BLK',
  };

  String get projectileFamilyLabel => switch (this) {
    PrototypeAffinity.neutral => 'Starbolt',
    PrototypeAffinity.aether => 'Rayline',
    PrototypeAffinity.flare => 'Impact',
    PrototypeAffinity.ember => 'Burst',
    PrototypeAffinity.solar => 'Arc',
    PrototypeAffinity.violet => 'Wave',
    PrototypeAffinity.verdant => 'Shield',
    PrototypeAffinity.black => 'Gravity',
  };

  String get payloadFamilyLabel => switch (this) {
    PrototypeAffinity.neutral => 'Precision / Priority',
    PrototypeAffinity.aether => 'Freeze / Slow',
    PrototypeAffinity.flare => 'Knockback / Stagger',
    PrototypeAffinity.ember => 'Burn / Detonate',
    PrototypeAffinity.solar => 'Shock / Disrupt',
    PrototypeAffinity.violet => 'Resonance / Echo',
    PrototypeAffinity.verdant => 'Decay / Anti-Regen',
    PrototypeAffinity.black => 'Redirect / Singularity',
  };
}

extension EnemyCardRarityX on EnemyCardRarity {
  String get label => switch (this) {
    EnemyCardRarity.basic => 'Basic',
    EnemyCardRarity.uncommon => 'Uncommon',
    EnemyCardRarity.rare => 'Rare',
    EnemyCardRarity.epic => 'Epic',
    EnemyCardRarity.legendary => 'Legendary',
  };

  int get levelCap => switch (this) {
    EnemyCardRarity.basic => 100,
    EnemyCardRarity.uncommon => 50,
    EnemyCardRarity.rare => 25,
    EnemyCardRarity.epic => 10,
    EnemyCardRarity.legendary => 5,
  };

  EnemyCardRarity? get nextRarity => switch (this) {
    EnemyCardRarity.basic => EnemyCardRarity.uncommon,
    EnemyCardRarity.uncommon => EnemyCardRarity.rare,
    EnemyCardRarity.rare => EnemyCardRarity.epic,
    EnemyCardRarity.epic => EnemyCardRarity.legendary,
    EnemyCardRarity.legendary => null,
  };
}

extension EnemyEncounterTypeX on EnemyEncounterType {
  String get label => switch (this) {
    EnemyEncounterType.normal => 'Anomaly',
    EnemyEncounterType.boss => 'Apex Anomaly',
  };
}

EnemyPackHighlightTier resolveEnemyPackHighlightTier({
  required EnemyCardRarity highestDrawnRarity,
  required EnemyCardRarity highestAvailableRarity,
  EnemyCardRarity? secondHighestAvailableRarity,
}) {
  if (highestDrawnRarity == highestAvailableRarity) {
    return EnemyPackHighlightTier.highest;
  }
  if (secondHighestAvailableRarity != null &&
      highestDrawnRarity == secondHighestAvailableRarity) {
    return EnemyPackHighlightTier.secondHighest;
  }
  return EnemyPackHighlightTier.standard;
}

extension ManagerRarityX on ManagerRarity {
  String get label => switch (this) {
    ManagerRarity.common => 'Common',
    ManagerRarity.uncommon => 'Uncommon',
    ManagerRarity.rare => 'Rare',
    ManagerRarity.epic => 'Epic',
    ManagerRarity.legendary => 'Legendary',
  };

  int get score => switch (this) {
    ManagerRarity.common => 0,
    ManagerRarity.uncommon => 1,
    ManagerRarity.rare => 2,
    ManagerRarity.epic => 3,
    ManagerRarity.legendary => 4,
  };
}

extension ProjectileRarityX on ProjectileRarity {
  String get label => switch (this) {
    ProjectileRarity.common => 'Root',
    ProjectileRarity.uncommon => 'Prism',
    ProjectileRarity.rare => 'Prism',
    ProjectileRarity.epic => 'Nexus',
    ProjectileRarity.legendary => 'Ascendant',
  };
}

extension ProjectileTypeX on ProjectileType {
  String get label => switch (this) {
    ProjectileType.starBolt => 'Starbolt',
    ProjectileType.threadBeam => 'Thread Beam',
    ProjectileType.heavyShot => 'Heavy Shot',
    ProjectileType.coreBomb => 'Core Bomb',
    ProjectileType.chainArc => 'Chain Arc',
    ProjectileType.pulseRing => 'Pulse Ring',
    ProjectileType.orbitNode => 'Orbit Node',
    ProjectileType.shieldHalo => 'Shield Halo',
    ProjectileType.rapidBolt => 'Rapid Bolt',
    ProjectileType.twinBolt => 'Twin Bolt',
    ProjectileType.pulseBeam => 'Pulse Beam',
    ProjectileType.splitBeam => 'Split Beam',
    ProjectileType.breakerShot => 'Breaker Shot',
    ProjectileType.crushShot => 'Crush Shot',
    ProjectileType.pulseBomb => 'Pulse Bomb',
    ProjectileType.clusterBomb => 'Cluster Bomb',
    ProjectileType.forkArc => 'Fork Arc',
    ProjectileType.arcNode => 'Arc Node',
    ProjectileType.echoRing => 'Echo Ring',
    ProjectileType.collapseRing => 'Collapse Ring',
    ProjectileType.sweepNode => 'Sweep Node',
    ProjectileType.slingNode => 'Sling Node',
    ProjectileType.sweepBeam => 'Sweep Beam',
    ProjectileType.lanceBeam => 'Lance Beam',
    ProjectileType.prismBeam => 'Prism Beam',
    ProjectileType.sentinelBeam => 'Sentinel Beam',
    ProjectileType.siegeShot => 'Siege Shot',
    ProjectileType.drillShot => 'Drill Shot',
    ProjectileType.ricochetShot => 'Ricochet Shot',
    ProjectileType.hunterShip => 'Hunter Ship',
    ProjectileType.novaBomb => 'Nova Bomb',
    ProjectileType.cascadeBomb => 'Cascade Bomb',
    ProjectileType.fieldBomb => 'Field Bomb',
    ProjectileType.bomberShip => 'Bomber Ship',
    ProjectileType.stormArc => 'Storm Arc',
    ProjectileType.webArc => 'Web Arc',
    ProjectileType.skyArc => 'Sky Arc',
    ProjectileType.interceptorShip => 'Interceptor Ship',
    ProjectileType.haloWave => 'Halo Wave',
    ProjectileType.spiralWave => 'Spiral Wave',
    ProjectileType.warpWave => 'Warp Wave',
    ProjectileType.shadeSatellite => 'Shade Satellite',
    ProjectileType.haloNodes => 'Halo Nodes',
    ProjectileType.anchorNode => 'Anchor Node',
    ProjectileType.flailNode => 'Flail Node',
    ProjectileType.familiarShip => 'Familiar Ship',
  };

  PrototypeAffinity get affinity => switch (this) {
    ProjectileType.starBolt ||
    ProjectileType.rapidBolt ||
    ProjectileType.twinBolt => PrototypeAffinity.neutral,
    ProjectileType.threadBeam ||
    ProjectileType.pulseBeam ||
    ProjectileType.splitBeam ||
    ProjectileType.sweepBeam ||
    ProjectileType.lanceBeam ||
    ProjectileType.prismBeam ||
    ProjectileType.sentinelBeam => PrototypeAffinity.aether,
    ProjectileType.heavyShot ||
    ProjectileType.breakerShot ||
    ProjectileType.crushShot ||
    ProjectileType.siegeShot ||
    ProjectileType.drillShot ||
    ProjectileType.ricochetShot ||
    ProjectileType.hunterShip => PrototypeAffinity.flare,
    ProjectileType.coreBomb ||
    ProjectileType.pulseBomb ||
    ProjectileType.clusterBomb ||
    ProjectileType.novaBomb ||
    ProjectileType.cascadeBomb ||
    ProjectileType.fieldBomb ||
    ProjectileType.bomberShip => PrototypeAffinity.ember,
    ProjectileType.chainArc ||
    ProjectileType.forkArc ||
    ProjectileType.arcNode ||
    ProjectileType.stormArc ||
    ProjectileType.webArc ||
    ProjectileType.skyArc ||
    ProjectileType.interceptorShip => PrototypeAffinity.solar,
    ProjectileType.pulseRing ||
    ProjectileType.echoRing ||
    ProjectileType.collapseRing ||
    ProjectileType.haloWave ||
    ProjectileType.spiralWave ||
    ProjectileType.warpWave ||
    ProjectileType.shadeSatellite => PrototypeAffinity.violet,
    ProjectileType.orbitNode ||
    ProjectileType.shieldHalo ||
    ProjectileType.sweepNode ||
    ProjectileType.slingNode ||
    ProjectileType.haloNodes ||
    ProjectileType.anchorNode ||
    ProjectileType.flailNode ||
    ProjectileType.familiarShip => PrototypeAffinity.verdant,
  };

  int get tier => switch (this) {
    ProjectileType.starBolt ||
    ProjectileType.threadBeam ||
    ProjectileType.heavyShot ||
    ProjectileType.coreBomb ||
    ProjectileType.chainArc ||
    ProjectileType.pulseRing ||
    ProjectileType.orbitNode ||
    ProjectileType.shieldHalo => 1,
    ProjectileType.rapidBolt ||
    ProjectileType.twinBolt ||
    ProjectileType.pulseBeam ||
    ProjectileType.splitBeam ||
    ProjectileType.breakerShot ||
    ProjectileType.crushShot ||
    ProjectileType.pulseBomb ||
    ProjectileType.clusterBomb ||
    ProjectileType.forkArc ||
    ProjectileType.arcNode ||
    ProjectileType.echoRing ||
    ProjectileType.collapseRing ||
    ProjectileType.sweepNode ||
    ProjectileType.slingNode => 2,
    _ => 3,
  };

  ProjectileRarity get rarity => switch (tier) {
    1 => ProjectileRarity.common,
    2 => ProjectileRarity.rare,
    _ => ProjectileRarity.epic,
  };

  ProjectileBehaviorProfile get behaviorProfile => switch (this) {
    ProjectileType.starBolt ||
    ProjectileType.threadBeam ||
    ProjectileType.heavyShot ||
    ProjectileType.orbitNode ||
    ProjectileType.anchorNode => ProjectileBehaviorProfile.thread,
    ProjectileType.rapidBolt ||
    ProjectileType.pulseBeam ||
    ProjectileType.breakerShot ||
    ProjectileType.pulseBomb ||
    ProjectileType.arcNode ||
    ProjectileType.echoRing ||
    ProjectileType.slingNode => ProjectileBehaviorProfile.pulse,
    ProjectileType.clusterBomb ||
    ProjectileType.spiralWave ||
    ProjectileType.flailNode => ProjectileBehaviorProfile.burst,
    ProjectileType.chainArc ||
    ProjectileType.sentinelBeam ||
    ProjectileType.ricochetShot ||
    ProjectileType.cascadeBomb ||
    ProjectileType.interceptorShip ||
    ProjectileType.shadeSatellite ||
    ProjectileType.familiarShip ||
    ProjectileType.hunterShip => ProjectileBehaviorProfile.chain,
    ProjectileType.twinBolt ||
    ProjectileType.splitBeam ||
    ProjectileType.forkArc ||
    ProjectileType.webArc => ProjectileBehaviorProfile.split,
    ProjectileType.lanceBeam ||
    ProjectileType.drillShot ||
    ProjectileType.skyArc ||
    ProjectileType.warpWave => ProjectileBehaviorProfile.lance,
    ProjectileType.coreBomb ||
    ProjectileType.crushShot ||
    ProjectileType.collapseRing ||
    ProjectileType.siegeShot => ProjectileBehaviorProfile.explosion,
    ProjectileType.pulseRing ||
    ProjectileType.shieldHalo ||
    ProjectileType.sweepBeam ||
    ProjectileType.fieldBomb ||
    ProjectileType.stormArc ||
    ProjectileType.haloWave ||
    ProjectileType.sweepNode ||
    ProjectileType.haloNodes => ProjectileBehaviorProfile.wave,
    ProjectileType.prismBeam ||
    ProjectileType.novaBomb ||
    ProjectileType.bomberShip => ProjectileBehaviorProfile.nova,
  };

  bool get usesBeamPath => switch (this) {
    ProjectileType.threadBeam ||
    ProjectileType.pulseBeam ||
    ProjectileType.splitBeam ||
    ProjectileType.sweepBeam ||
    ProjectileType.lanceBeam ||
    ProjectileType.prismBeam ||
    ProjectileType.sentinelBeam => true,
    _ => false,
  };

  bool get usesBlueLaser =>
      affinity == PrototypeAffinity.aether && usesBeamPath;

  bool get usesRadialWave =>
      !usesBeamPath && behaviorProfile == ProjectileBehaviorProfile.wave;

  String get summary {
    if (this == ProjectileType.shieldHalo) {
      return 'Damaging guard ring that punishes enemies touching the shield.';
    }
    return switch (behaviorProfile) {
      ProjectileBehaviorProfile.thread =>
        'Stable single-target fire that holds the lane together.',
      ProjectileBehaviorProfile.pulse =>
        'Fast repeat fire that trades weight for cadence.',
      ProjectileBehaviorProfile.burst =>
        'Follow-up bursts that stack extra hits into the same window.',
      ProjectileBehaviorProfile.chain =>
        'Redirects pressure into a nearby secondary target.',
      ProjectileBehaviorProfile.split =>
        'Breaks into side attacks after the first impact.',
      ProjectileBehaviorProfile.lance =>
        'Focused lane pressure with stronger reach.',
      ProjectileBehaviorProfile.explosion =>
        'Heavy impact with a local blast field.',
      ProjectileBehaviorProfile.wave =>
        'Wide sweep that clips multiple nearby targets.',
      ProjectileBehaviorProfile.nova =>
        'Large-area detonation that floods the lane with damage.',
    };
  }
}

extension PayloadTypeX on PayloadType {
  String get label => switch (this) {
    PayloadType.none => 'No Payload',
    PayloadType.precision => 'Precision',
    PayloadType.doubleTap => 'Double Tap',
    PayloadType.chill => 'Chill',
    PayloadType.fracture => 'Fracture',
    PayloadType.rend => 'Rend',
    PayloadType.force => 'Force',
    PayloadType.overheat => 'Overheat',
    PayloadType.detonate => 'Detonate',
    PayloadType.shock => 'Shock',
    PayloadType.disrupt => 'Disrupt',
    PayloadType.expose => 'Expose',
    PayloadType.pull => 'Pull',
    PayloadType.corrupt => 'Corrupt',
    PayloadType.spread => 'Spread',
    PayloadType.deepChill => 'Deep Chill',
    PayloadType.brittleFracture => 'Brittle Fracture',
    PayloadType.coreRend => 'Core Rend',
    PayloadType.concussiveForce => 'Concussive Force',
    PayloadType.meltdown => 'Meltdown',
    PayloadType.chainDetonate => 'Chain Detonate',
    PayloadType.overload => 'Overload',
    PayloadType.empDisrupt => 'EMP Disrupt',
    PayloadType.collapse => 'Collapse',
    PayloadType.singularityPull => 'Singularity Pull',
    PayloadType.cascadeCorrupt => 'Cascade Corrupt',
    PayloadType.viralSpread => 'Viral Spread',
  };

  PrototypeAffinity? get affinity => switch (this) {
    PayloadType.none => null,
    PayloadType.precision || PayloadType.doubleTap => PrototypeAffinity.neutral,
    PayloadType.chill ||
    PayloadType.fracture ||
    PayloadType.deepChill ||
    PayloadType.brittleFracture => PrototypeAffinity.aether,
    PayloadType.rend ||
    PayloadType.force ||
    PayloadType.coreRend ||
    PayloadType.concussiveForce => PrototypeAffinity.flare,
    PayloadType.overheat ||
    PayloadType.detonate ||
    PayloadType.meltdown ||
    PayloadType.chainDetonate => PrototypeAffinity.ember,
    PayloadType.shock ||
    PayloadType.disrupt ||
    PayloadType.overload ||
    PayloadType.empDisrupt => PrototypeAffinity.solar,
    PayloadType.expose ||
    PayloadType.pull ||
    PayloadType.collapse ||
    PayloadType.singularityPull => PrototypeAffinity.violet,
    PayloadType.corrupt ||
    PayloadType.spread ||
    PayloadType.cascadeCorrupt ||
    PayloadType.viralSpread => PrototypeAffinity.verdant,
  };

  int get tier => switch (this) {
    PayloadType.none => 0,
    PayloadType.deepChill ||
    PayloadType.brittleFracture ||
    PayloadType.coreRend ||
    PayloadType.concussiveForce ||
    PayloadType.meltdown ||
    PayloadType.chainDetonate ||
    PayloadType.overload ||
    PayloadType.empDisrupt ||
    PayloadType.collapse ||
    PayloadType.singularityPull ||
    PayloadType.cascadeCorrupt ||
    PayloadType.viralSpread => 3,
    _ => 2,
  };

  PayloadEffectProfile get effectProfile => switch (this) {
    PayloadType.none => PayloadEffectProfile.none,
    PayloadType.precision ||
    PayloadType.doubleTap => PayloadEffectProfile.bounty,
    PayloadType.chill ||
    PayloadType.fracture ||
    PayloadType.deepChill ||
    PayloadType.brittleFracture => PayloadEffectProfile.freeze,
    PayloadType.rend ||
    PayloadType.force ||
    PayloadType.coreRend ||
    PayloadType.concussiveForce => PayloadEffectProfile.knockback,
    PayloadType.overheat ||
    PayloadType.detonate ||
    PayloadType.meltdown ||
    PayloadType.chainDetonate ||
    PayloadType.corrupt ||
    PayloadType.spread ||
    PayloadType.cascadeCorrupt ||
    PayloadType.viralSpread => PayloadEffectProfile.burn,
    PayloadType.shock ||
    PayloadType.disrupt ||
    PayloadType.overload ||
    PayloadType.empDisrupt => PayloadEffectProfile.shock,
    PayloadType.expose ||
    PayloadType.pull ||
    PayloadType.collapse ||
    PayloadType.singularityPull => PayloadEffectProfile.bounty,
  };

  double get potencyMultiplier => tier >= 3 ? 1.35 : 1.0;
}

extension TargetPriorityX on TargetPriority {
  String get label => switch (this) {
    TargetPriority.close => 'Close',
    TargetPriority.strong => 'Strong',
    TargetPriority.weak => 'Weak',
  };
}

extension EquipmentInventorySlotX on EquipmentInventorySlot {
  String get label => switch (this) {
    EquipmentInventorySlot.hat => 'Hat',
    EquipmentInventorySlot.top => 'Top',
    EquipmentInventorySlot.pants => 'Pants',
    EquipmentInventorySlot.shoes => 'Shoes',
    EquipmentInventorySlot.accessory => 'Accessory',
  };
}

extension EquipmentLoadoutSlotX on EquipmentLoadoutSlot {
  String get label => switch (this) {
    EquipmentLoadoutSlot.hat => 'Hat',
    EquipmentLoadoutSlot.top => 'Top',
    EquipmentLoadoutSlot.pants => 'Pants',
    EquipmentLoadoutSlot.shoes => 'Shoes',
    EquipmentLoadoutSlot.accessoryPrimary => 'Accessory A',
    EquipmentLoadoutSlot.accessorySecondary => 'Accessory B',
  };

  EquipmentInventorySlot get acceptedType => switch (this) {
    EquipmentLoadoutSlot.hat => EquipmentInventorySlot.hat,
    EquipmentLoadoutSlot.top => EquipmentInventorySlot.top,
    EquipmentLoadoutSlot.pants => EquipmentInventorySlot.pants,
    EquipmentLoadoutSlot.shoes => EquipmentInventorySlot.shoes,
    EquipmentLoadoutSlot.accessoryPrimary => EquipmentInventorySlot.accessory,
    EquipmentLoadoutSlot.accessorySecondary => EquipmentInventorySlot.accessory,
  };

  bool get isAccessory =>
      this == EquipmentLoadoutSlot.accessoryPrimary ||
      this == EquipmentLoadoutSlot.accessorySecondary;
}

extension TowerUpgradeStatTypeX on TowerUpgradeStatType {
  String get label => switch (this) {
    TowerUpgradeStatType.power => 'Damage',
    TowerUpgradeStatType.chargeRate => 'Charge Rate',
    TowerUpgradeStatType.cooldown => 'Cooldown',
    TowerUpgradeStatType.range => 'Range',
    TowerUpgradeStatType.generationSpeed => 'Generation Speed',
    TowerUpgradeStatType.critChance => 'Crit Chance',
    TowerUpgradeStatType.critDamage => 'Crit Damage',
    TowerUpgradeStatType.finalDamage => 'Final Damage',
    TowerUpgradeStatType.bossDamage => 'Apex Damage',
    TowerUpgradeStatType.normalDamage => 'Normal Damage',
    TowerUpgradeStatType.defensePenetration => 'Def Pen',
    TowerUpgradeStatType.minDamage => 'Min Damage',
    TowerUpgradeStatType.maxDamage => 'Max Damage',
    TowerUpgradeStatType.dotDamage => 'DoT Damage',
  };
}

extension ChildTowerUpgradeTypeX on ChildTowerUpgradeType {
  String get label => switch (this) {
    ChildTowerUpgradeType.power => 'Damage',
    ChildTowerUpgradeType.chargeRate => 'Charge Rate',
    ChildTowerUpgradeType.cooldown => 'Cooldown',
    ChildTowerUpgradeType.range => 'Range',
    ChildTowerUpgradeType.generationSpeed => 'Generation Speed',
    ChildTowerUpgradeType.critChance => 'Crit Chance',
    ChildTowerUpgradeType.critDamage => 'Crit Damage',
    ChildTowerUpgradeType.finalDamage => 'Final Damage',
    ChildTowerUpgradeType.bossDamage => 'Apex Damage',
    ChildTowerUpgradeType.normalDamage => 'Normal Damage',
    ChildTowerUpgradeType.defensePenetration => 'Def Pen',
    ChildTowerUpgradeType.minDamage => 'Min Damage',
    ChildTowerUpgradeType.maxDamage => 'Max Damage',
  };
}
