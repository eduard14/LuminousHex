import 'lightcore_types.dart';

// TODO(full-game): Keep these config records data-only and serializable so the
// checked-in content libraries can later be replaced by downloaded or cached
// balance tables without touching battle/rendering code.
class TowerConfig {
  const TowerConfig({
    required this.id,
    required this.name,
    required this.summary,
    required this.passiveLabel,
    required this.affinity,
    required this.buildCost,
    required this.basePower,
    required this.baseChargeRate,
    required this.baseCooldown,
    required this.jamHitMultiplier,
    required this.jamDecayMultiplier,
    required this.coreCooldownMultiplier,
    required this.lumenPressureGuard,
    required this.affinityBonusMultiplier,
    required this.defaultProjectileType,
    required this.defaultPayloadType,
    required this.baseRange,
    required this.baseGenerationSpeed,
    required this.baseCritChance,
    required this.baseCritMultiplier,
    required this.statVariance,
    required this.critChanceVariance,
    required this.critDamageVariance,
    required this.projectileWeights,
    required this.payloadWeights,
  });

  final String id;
  final String name;
  final String summary;
  final String passiveLabel;
  final PrototypeAffinity affinity;
  final int buildCost;
  final double basePower;
  final double baseChargeRate;
  final double baseCooldown;
  final double jamHitMultiplier;
  final double jamDecayMultiplier;
  final double coreCooldownMultiplier;
  final double lumenPressureGuard;
  final double affinityBonusMultiplier;
  final ProjectileType defaultProjectileType;
  final PayloadType defaultPayloadType;
  final double baseRange;
  final double baseGenerationSpeed;
  final double baseCritChance;
  final double baseCritMultiplier;
  final double statVariance;
  final double critChanceVariance;
  final double critDamageVariance;
  final Map<ProjectileType, int> projectileWeights;
  final Map<PayloadType, int> payloadWeights;
}

class EnemyConfig {
  const EnemyConfig({
    required this.id,
    required this.name,
    required this.summary,
    required this.traitLabel,
    this.encounterType = EnemyEncounterType.normal,
    required this.affinity,
    this.secondaryAffinity,
    required this.rarity,
    required this.baseHealth,
    required this.baseDefense,
    required this.baseSpeed,
    required this.reward,
    required this.baseExperience,
    required this.jamStrength,
    required this.baseSpiralDrift,
    required this.splitsOnDeath,
    this.threatRewardMultiplier = 1,
    this.stabilityDamageMultiplier = 1,
    this.immunityAffinities = const <PrototypeAffinity>[],
    this.regenFractionPerSecond = 0,
    this.spawnIntervalSeconds = 0,
    this.spawnCount = 0,
  });

  final String id;
  final String name;
  final String summary;
  final String traitLabel;
  final EnemyEncounterType encounterType;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final EnemyCardRarity rarity;
  final double baseHealth;
  final double baseDefense;
  final double baseSpeed;
  final int reward;
  final int baseExperience;
  final double jamStrength;
  final double baseSpiralDrift;
  final bool splitsOnDeath;
  final double threatRewardMultiplier;
  final double stabilityDamageMultiplier;
  final List<PrototypeAffinity> immunityAffinities;
  final double regenFractionPerSecond;
  final double spawnIntervalSeconds;
  final int spawnCount;

  bool get isBoss => encounterType == EnemyEncounterType.boss;

  List<PrototypeAffinity> get affinities => secondaryAffinity == null
      ? <PrototypeAffinity>[affinity]
      : <PrototypeAffinity>[affinity, secondaryAffinity!];

  bool get hasRegen => regenFractionPerSecond > 0;

  bool get hasSpawnAbility => spawnIntervalSeconds > 0 && spawnCount > 0;
}

class CardConfig {
  const CardConfig({
    required this.id,
    required this.name,
    required this.summary,
    required this.flavorBio,
    required this.roleLabel,
    required this.powerMultiplier,
    required this.chargeMultiplier,
    required this.cooldownMultiplier,
    required this.advantageMultiplier,
    required this.automationRate,
  });

  final String id;
  final String name;
  final String summary;
  final String flavorBio;
  final String roleLabel;
  final double powerMultiplier;
  final double chargeMultiplier;
  final double cooldownMultiplier;
  final double advantageMultiplier;
  final double automationRate;

  String get portraitAssetPath => 'assets/sprites/managers/core/$id.png';
}

class EnemyManagerConfig {
  const EnemyManagerConfig({
    required this.id,
    required this.name,
    required this.summary,
    required this.flavorBio,
    required this.roleLabel,
    required this.spawnRateMultiplier,
    required this.rewardMultiplier,
    required this.experienceMultiplier,
    required this.healthMultiplier,
    required this.speedMultiplier,
    required this.stabilityDamageMultiplier,
    required this.apexStabilityMultiplier,
    required this.queueDisruptionMultiplier,
  });

  final String id;
  final String name;
  final String summary;
  final String flavorBio;
  final String roleLabel;
  final double spawnRateMultiplier;
  final double rewardMultiplier;
  final double experienceMultiplier;
  final double healthMultiplier;
  final double speedMultiplier;
  final double stabilityDamageMultiplier;
  final double apexStabilityMultiplier;
  final double queueDisruptionMultiplier;

  String get portraitAssetPath => 'assets/sprites/managers/threat/$id.png';
}

class BossTraitConfig {
  const BossTraitConfig({
    required this.id,
    required this.name,
    required this.summary,
    required this.sourceBossId,
    required this.affinity,
    required this.rarity,
    required this.effectLabel,
  });

  final String id;
  final String name;
  final String summary;
  final String sourceBossId;
  final PrototypeAffinity affinity;
  final EnemyCardRarity rarity;
  final String effectLabel;
}

class ThreatRegionConfig {
  const ThreatRegionConfig({
    required this.id,
    required this.name,
    required this.q,
    required this.r,
    required this.ring,
    required this.stabilizationLayers,
    required this.rarity,
    required this.anomalyCardIds,
    required this.primaryBossId,
    this.secondaryBossId,
    this.inventoryEffect = TowerPatternBonusProfile.zero,
  });

  final String id;
  final String name;
  final int q;
  final int r;
  final int ring;
  final int stabilizationLayers;
  final EnemyCardRarity rarity;
  final List<String> anomalyCardIds;
  final String primaryBossId;
  final String? secondaryBossId;
  final TowerPatternBonusProfile inventoryEffect;

  bool get hasDoubleBoss => secondaryBossId != null;
}

class EquipmentBonusProfile {
  const EquipmentBonusProfile({
    this.towerPower = 0,
    this.chargeRate = 0,
    this.critChance = 0,
    this.critDamage = 0,
    this.range = 0,
    this.bossDamage = 0,
    this.lumenGain = 0,
    this.fluxGain = 0,
    this.ticketGain = 0,
    this.dropRate = 0,
  });

  static const zero = EquipmentBonusProfile();

  final double towerPower;
  final double chargeRate;
  final double critChance;
  final double critDamage;
  final double range;
  final double bossDamage;
  final double lumenGain;
  final double fluxGain;
  final double ticketGain;
  final double dropRate;

  bool get isEmpty =>
      towerPower == 0 &&
      chargeRate == 0 &&
      critChance == 0 &&
      critDamage == 0 &&
      range == 0 &&
      bossDamage == 0 &&
      lumenGain == 0 &&
      fluxGain == 0 &&
      ticketGain == 0 &&
      dropRate == 0;

  EquipmentBonusProfile operator +(EquipmentBonusProfile other) {
    return EquipmentBonusProfile(
      towerPower: towerPower + other.towerPower,
      chargeRate: chargeRate + other.chargeRate,
      critChance: critChance + other.critChance,
      critDamage: critDamage + other.critDamage,
      range: range + other.range,
      bossDamage: bossDamage + other.bossDamage,
      lumenGain: lumenGain + other.lumenGain,
      fluxGain: fluxGain + other.fluxGain,
      ticketGain: ticketGain + other.ticketGain,
      dropRate: dropRate + other.dropRate,
    );
  }

  EquipmentBonusProfile scale(double factor) {
    return EquipmentBonusProfile(
      towerPower: towerPower * factor,
      chargeRate: chargeRate * factor,
      critChance: critChance * factor,
      critDamage: critDamage * factor,
      range: range * factor,
      bossDamage: bossDamage * factor,
      lumenGain: lumenGain * factor,
      fluxGain: fluxGain * factor,
      ticketGain: ticketGain * factor,
      dropRate: dropRate * factor,
    );
  }
}

class ProfileMedalConfig {
  const ProfileMedalConfig({
    required this.id,
    required this.name,
    required this.summary,
    required this.requirementLabel,
    required this.requiredValue,
    required this.bonusLabel,
    required this.bonuses,
    required this.affinity,
  });

  final String id;
  final String name;
  final String summary;
  final String requirementLabel;
  final int requiredValue;
  final String bonusLabel;
  final EquipmentBonusProfile bonuses;
  final PrototypeAffinity affinity;
}

class TowerPatternBonusProfile {
  const TowerPatternBonusProfile({
    this.power = 0,
    this.chargeRate = 0,
    this.cooldownReduction = 0,
    this.range = 0,
    this.generationSpeed = 0,
    this.critChance = 0,
    this.critDamage = 0,
    this.finalDamage = 0,
    this.bossDamage = 0,
    this.normalDamage = 0,
    this.defensePenetration = 0,
  });

  static const zero = TowerPatternBonusProfile();

  final double power;
  final double chargeRate;
  final double cooldownReduction;
  final double range;
  final double generationSpeed;
  final double critChance;
  final double critDamage;
  final double finalDamage;
  final double bossDamage;
  final double normalDamage;
  final double defensePenetration;

  bool get isEmpty =>
      power == 0 &&
      chargeRate == 0 &&
      cooldownReduction == 0 &&
      range == 0 &&
      generationSpeed == 0 &&
      critChance == 0 &&
      critDamage == 0 &&
      finalDamage == 0 &&
      bossDamage == 0 &&
      normalDamage == 0 &&
      defensePenetration == 0;

  TowerPatternBonusProfile operator +(TowerPatternBonusProfile other) {
    return TowerPatternBonusProfile(
      power: power + other.power,
      chargeRate: chargeRate + other.chargeRate,
      cooldownReduction: cooldownReduction + other.cooldownReduction,
      range: range + other.range,
      generationSpeed: generationSpeed + other.generationSpeed,
      critChance: critChance + other.critChance,
      critDamage: critDamage + other.critDamage,
      finalDamage: finalDamage + other.finalDamage,
      bossDamage: bossDamage + other.bossDamage,
      normalDamage: normalDamage + other.normalDamage,
      defensePenetration: defensePenetration + other.defensePenetration,
    );
  }

  TowerPatternBonusProfile scale(double factor) {
    return TowerPatternBonusProfile(
      power: power * factor,
      chargeRate: chargeRate * factor,
      cooldownReduction: cooldownReduction * factor,
      range: range * factor,
      generationSpeed: generationSpeed * factor,
      critChance: critChance * factor,
      critDamage: critDamage * factor,
      finalDamage: finalDamage * factor,
      bossDamage: bossDamage * factor,
      normalDamage: normalDamage * factor,
      defensePenetration: defensePenetration * factor,
    );
  }
}

class TowerPatternAchievement {
  const TowerPatternAchievement({
    required this.id,
    required this.name,
    required this.summary,
    required this.bonuses,
  });

  final String id;
  final String name;
  final String summary;
  final TowerPatternBonusProfile bonuses;
}

class EquipmentSetBonusConfig {
  const EquipmentSetBonusConfig({
    required this.pieceCount,
    required this.label,
    required this.bonuses,
  });

  final int pieceCount;
  final String label;
  final EquipmentBonusProfile bonuses;
}

class EquipmentSetConfig {
  const EquipmentSetConfig({
    required this.id,
    required this.name,
    required this.affinity,
    required this.dropLabel,
    required this.pieceNames,
    required this.slotBonuses,
    required this.setBonuses,
  });

  final String id;
  final String name;
  final PrototypeAffinity affinity;
  final String dropLabel;
  final Map<EquipmentInventorySlot, String> pieceNames;
  final Map<EquipmentInventorySlot, EquipmentBonusProfile> slotBonuses;
  final List<EquipmentSetBonusConfig> setBonuses;

  String pieceNameFor(EquipmentInventorySlot slot) =>
      pieceNames[slot] ?? slot.label;

  EquipmentBonusProfile slotBonusFor(EquipmentInventorySlot slot) =>
      slotBonuses[slot] ?? EquipmentBonusProfile.zero;
}
