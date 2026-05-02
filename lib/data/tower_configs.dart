import 'lumicore_trait_catalog.dart';
import '../models/lightcore_config.dart';
import '../models/lightcore_types.dart';

// TODO(full-game): Replace this library with versioned tower definitions loaded
// from bundled JSON or backend-delivered content manifests.
class TowerLibrary {
  static const whitePrism = TowerConfig(
    id: 'white_source_tower',
    name: 'White Source Tower',
    summary:
        'Starbolt Turret. Fires clean kinetic starbolts with reliable priority.',
    passiveLabel: 'Precision seed',
    affinity: PrototypeAffinity.neutral,
    buildCost: 7,
    basePower: 12,
    baseChargeRate: 0.9,
    baseCooldown: 1.04,
    jamHitMultiplier: 0.92,
    jamDecayMultiplier: 1.18,
    coreCooldownMultiplier: 0.88,
    lumenPressureGuard: 0.014,
    affinityBonusMultiplier: 1.0,
    defaultProjectileType: ProjectileType.starBolt,
    defaultPayloadType: PayloadType.none,
    baseRange: 292,
    baseGenerationSpeed: 0.72,
    baseCritChance: 0.07,
    baseCritMultiplier: 1.62,
    statVariance: 0.08,
    critChanceVariance: 0.025,
    critDamageVariance: 0.12,
    projectileWeights: {ProjectileType.starBolt: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const starboltTurret = whitePrism;

  static const redPrism = TowerConfig(
    id: 'red_prism',
    name: 'Red Source Tower',
    summary:
        'Comet Mortar. Launches readable comet bombs for AoE and husk cleanup pressure.',
    passiveLabel: 'Bomb seed',
    affinity: PrototypeAffinity.ember,
    buildCost: 9,
    basePower: 18,
    baseChargeRate: 0.56,
    baseCooldown: 1.62,
    jamHitMultiplier: 1.02,
    jamDecayMultiplier: 0.92,
    coreCooldownMultiplier: 1.05,
    lumenPressureGuard: 0,
    affinityBonusMultiplier: 1.0,
    defaultProjectileType: ProjectileType.coreBomb,
    defaultPayloadType: PayloadType.none,
    baseRange: 272,
    baseGenerationSpeed: 0.64,
    baseCritChance: 0.08,
    baseCritMultiplier: 1.78,
    statVariance: 0.12,
    critChanceVariance: 0.04,
    critDamageVariance: 0.18,
    projectileWeights: {ProjectileType.coreBomb: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const orangePrism = TowerConfig(
    id: 'orange_prism',
    name: 'Orange Source Tower',
    summary:
        'Meteor Driver. Fires slow, heavy meteor slugs that check fast anomaly pressure.',
    passiveLabel: 'Meteor seed',
    affinity: PrototypeAffinity.flare,
    buildCost: 9,
    basePower: 12,
    baseChargeRate: 0.74,
    baseCooldown: 1.14,
    jamHitMultiplier: 0.96,
    jamDecayMultiplier: 1.0,
    coreCooldownMultiplier: 0.72,
    lumenPressureGuard: 0,
    affinityBonusMultiplier: 1.0,
    defaultProjectileType: ProjectileType.heavyShot,
    defaultPayloadType: PayloadType.none,
    baseRange: 316,
    baseGenerationSpeed: 0.69,
    baseCritChance: 0.06,
    baseCritMultiplier: 1.64,
    statVariance: 0.11,
    critChanceVariance: 0.03,
    critDamageVariance: 0.16,
    projectileWeights: {ProjectileType.heavyShot: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const yellowPrism = TowerConfig(
    id: 'yellow_prism',
    name: 'Yellow Source Tower',
    summary:
        'Stormhook Coil. Throws chain arcs for phase pressure and clustered routing.',
    passiveLabel: 'Storm seed',
    affinity: PrototypeAffinity.solar,
    buildCost: 10,
    basePower: 11,
    baseChargeRate: 0.82,
    baseCooldown: 1.16,
    jamHitMultiplier: 0.94,
    jamDecayMultiplier: 1.08,
    coreCooldownMultiplier: 0.94,
    lumenPressureGuard: 0.018,
    affinityBonusMultiplier: 1.0,
    defaultProjectileType: ProjectileType.chainArc,
    defaultPayloadType: PayloadType.none,
    baseRange: 286,
    baseGenerationSpeed: 0.66,
    baseCritChance: 0.05,
    baseCritMultiplier: 1.52,
    statVariance: 0.1,
    critChanceVariance: 0.02,
    critDamageVariance: 0.14,
    projectileWeights: {ProjectileType.chainArc: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const greenPrism = TowerConfig(
    id: 'green_prism',
    name: 'Green Source Tower',
    summary:
        'Thorn Aegis. Maintains a persistent damaging shield halo instead of generating packets.',
    passiveLabel: 'Shield seed',
    affinity: PrototypeAffinity.verdant,
    buildCost: 8,
    basePower: 10,
    baseChargeRate: 0,
    baseCooldown: 1.08,
    jamHitMultiplier: 0.74,
    jamDecayMultiplier: 1.56,
    coreCooldownMultiplier: 0.96,
    lumenPressureGuard: 0,
    affinityBonusMultiplier: 1.0,
    defaultProjectileType: ProjectileType.shieldHalo,
    defaultPayloadType: PayloadType.none,
    baseRange: 258,
    baseGenerationSpeed: 0,
    baseCritChance: 0.05,
    baseCritMultiplier: 1.56,
    statVariance: 0.13,
    critChanceVariance: 0.03,
    critDamageVariance: 0.14,
    projectileWeights: {ProjectileType.shieldHalo: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const cyanPrism = TowerConfig(
    id: 'cyan_prism',
    name: 'Blue Source Tower',
    summary:
        'Rayline Spire. Cuts targets with a clean rayline for slow and disable prevention paths.',
    passiveLabel: 'Rayline seed',
    affinity: PrototypeAffinity.aether,
    buildCost: 8,
    basePower: 8,
    baseChargeRate: 1.12,
    baseCooldown: 0.98,
    jamHitMultiplier: 0.88,
    jamDecayMultiplier: 1.28,
    coreCooldownMultiplier: 0.88,
    lumenPressureGuard: 0,
    affinityBonusMultiplier: 1.0,
    defaultProjectileType: ProjectileType.threadBeam,
    defaultPayloadType: PayloadType.none,
    baseRange: 334,
    baseGenerationSpeed: 0.68,
    baseCritChance: 0.07,
    baseCritMultiplier: 1.68,
    statVariance: 0.11,
    critChanceVariance: 0.03,
    critDamageVariance: 0.17,
    projectileWeights: {ProjectileType.threadBeam: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const bluePrism = cyanPrism;

  static const purplePrism = TowerConfig(
    id: 'purple_prism',
    name: 'Purple Source Tower',
    summary:
        'Quasar Ring. Emits ring pulses for lane coverage and split-fragment control.',
    passiveLabel: 'Quasar seed',
    affinity: PrototypeAffinity.violet,
    buildCost: 10,
    basePower: 13,
    baseChargeRate: 0.72,
    baseCooldown: 1.2,
    jamHitMultiplier: 0.9,
    jamDecayMultiplier: 1.02,
    coreCooldownMultiplier: 0.98,
    lumenPressureGuard: 0,
    affinityBonusMultiplier: 1.22,
    defaultProjectileType: ProjectileType.pulseRing,
    defaultPayloadType: PayloadType.none,
    baseRange: 298,
    baseGenerationSpeed: 0.62,
    baseCritChance: 0.11,
    baseCritMultiplier: 1.92,
    statVariance: 0.14,
    critChanceVariance: 0.05,
    critDamageVariance: 0.2,
    projectileWeights: {ProjectileType.pulseRing: 1},
    payloadWeights: {PayloadType.none: 1},
  );

  static const all = <TowerConfig>[
    redPrism,
    orangePrism,
    yellowPrism,
    greenPrism,
    cyanPrism,
    purplePrism,
    whitePrism,
  ];

  static ProjectileType layer1ProjectileFor(TowerConfig config) =>
      layer1ProjectileForAffinity(config.affinity);
}
