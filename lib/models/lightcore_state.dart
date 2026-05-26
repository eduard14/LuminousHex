import 'lightcore_config.dart';
import 'lightcore_types.dart';

/// Read-only projection for the active anomaly deck pressure loop.
///
/// The active anomaly deck, active region Threat Director, core stability, and
/// target pressure already lived in separate controller fields. This snapshot
/// gives UI and tests one documented surface to inspect without rebuilding the
/// same calculations in multiple places.
class ThreatScanBundleSnapshot {
  const ThreatScanBundleSnapshot({
    required this.id,
    required this.name,
    required this.summary,
    required this.primaryAffinity,
    required this.cardNames,
    required this.directorNames,
    required this.riskLabel,
    required this.counterplayLabel,
    required this.activeCardCount,
    required this.liveEnemyCount,
    required this.targetCount,
    required this.targetMax,
    required this.threatRewardMultiplier,
    required this.stabilityPressureMultiplier,
    required this.outputEfficiencyMultiplier,
    required this.effectiveGainMultiplier,
  });

  /// Stable, content-derived key for the currently armed bundle.
  final String id;

  /// Player-facing bundle name, usually derived from the dominant affinity.
  final String name;

  /// Compact explanation of what is armed and how much director support exists.
  final String summary;

  /// Dominant anomaly affinity in the active deck, or null when no deck exists.
  final PrototypeAffinity? primaryAffinity;

  /// Names of active anomaly cards contributing to this bundle.
  final List<String> cardNames;

  /// Names of Threat Directors attached to the active region.
  final List<String> directorNames;

  /// Coarse pressure tier after threat reward, stability damage, and target load.
  final String riskLabel;

  /// Tactical counter package recommended for the dominant anomaly affinity.
  final String counterplayLabel;

  final int activeCardCount;
  final int liveEnemyCount;
  final int targetCount;
  final int targetMax;
  final double threatRewardMultiplier;
  final double stabilityPressureMultiplier;
  final double outputEfficiencyMultiplier;
  final double effectiveGainMultiplier;

  bool get hasDirector => directorNames.isNotEmpty;

  int get directorCount => directorNames.length;

  String get directorLabel =>
      hasDirector ? directorNames.join(', ') : 'No Threat Director assigned';

  String get threatRewardLabel =>
      'x${threatRewardMultiplier.toStringAsFixed(2)}';

  String get stabilityPressureLabel =>
      'x${stabilityPressureMultiplier.toStringAsFixed(2)}';

  String get outputEfficiencyLabel =>
      '${outputEfficiencyMultiplier.toStringAsFixed(2)}x';

  String get effectiveGainLabel =>
      'x${effectiveGainMultiplier.toStringAsFixed(2)}';
}

class ThreatAssignmentGroupStatsSnapshot {
  const ThreatAssignmentGroupStatsSnapshot({
    required this.anomalyCount,
    required this.ignoredAnomalyCount,
    required this.spawnIntervalSeconds,
    required this.spawnsPerMinute,
    required this.clearsPerMinute,
    required this.averageLumensPerClear,
    required this.averageExperiencePerClear,
    required this.lumensPerMinute,
    required this.experiencePerMinute,
  });

  final int anomalyCount;
  final int ignoredAnomalyCount;
  final double spawnIntervalSeconds;
  final double spawnsPerMinute;
  final double clearsPerMinute;
  final double averageLumensPerClear;
  final double averageExperiencePerClear;
  final double lumensPerMinute;
  final double experiencePerMinute;

  bool get hasAnomalies => anomalyCount > 0;

  bool get hasIgnoredAnomalies => ignoredAnomalyCount > 0;

  bool get isDpsLimited =>
      hasAnomalies && clearsPerMinute < spawnsPerMinute * 0.98;
}

class PromotionPreviewSnapshot {
  const PromotionPreviewSnapshot({
    required this.canPromote,
    required this.passiveArchive,
    required this.actionLabel,
    required this.resultLabel,
    required this.currentCoreLabel,
    required this.projectileMixLabel,
    required this.payloadMixLabel,
    required this.anomalyBehaviorLabel,
    required this.managerBehaviorLabel,
  });

  final bool canPromote;
  final bool passiveArchive;
  final String actionLabel;
  final String resultLabel;
  final String currentCoreLabel;
  final String projectileMixLabel;
  final String payloadMixLabel;
  final String anomalyBehaviorLabel;
  final String managerBehaviorLabel;
}

class OuterTowerState {
  const OuterTowerState({
    required this.slotIndex,
    this.config,
    this.level = 1,
    this.charge = 0,
    this.cooldownRemaining = 0,
    this.automationCooldownRemaining = 0,
    this.disruption = 0,
    this.equippedCardInstanceId,
    this.projectileType,
    this.payloadType,
    this.targetPriority = TargetPriority.close,
    this.projectileTargetPriorities = const {},
    this.fireSequence = 0,
    this.investedLumens = 0,
    this.fabricationTotalSeconds = 0,
    this.fabricationRemainingSeconds = 0,
    this.fabricationStartedAtServerMillis,
    this.fabricationCompletesAtServerMillis,
    this.powerFactor = 1,
    this.chargeFactor = 1,
    this.cooldownFactor = 1,
    this.rangeFactor = 1,
    this.generationFactor = 1,
    this.critChanceBonus = 0,
    this.critDamageFactor = 1,
    this.finalDamageFactor = 1,
    this.bossDamageFactor = 1,
    this.normalDamageFactor = 1,
    this.defensePenetration = 0,
    this.minDamageFactor = 1,
    this.maxDamageFactor = 1,
    this.dotDamageFactor = 1,
    this.towerUpgradeOptions = const <TowerUpgradeOptionState>[],
    this.childLayerId,
    this.childLayerTier,
    this.childLayerName,
    this.childAffinity,
    this.childSecondaryAffinity,
    this.childProjectileLoadout = const <ProjectileType>[],
    this.childPayloadLoadout = const <PayloadType>[],
    this.childProjectileType,
    this.childPayloadType,
    this.childCoreLevel,
    this.childRange,
    this.childGenerationSpeed,
    this.childCritChance,
    this.childCritMultiplier,
    this.childFinalDamageMultiplier,
    this.childBossDamageMultiplier,
    this.childNormalDamageMultiplier,
    this.childDefensePenetration,
    this.childMinDamageMultiplier,
    this.childMaxDamageMultiplier,
    this.childPowerUpgradeBonus = 0,
    this.childChargeUpgradeBonus = 0,
    this.childCooldownUpgradeBonus = 0,
    this.childRangeUpgradeBonus = 0,
    this.childGenerationUpgradeBonus = 0,
    this.childCritChanceUpgradeBonus = 0,
    this.childCritDamageUpgradeBonus = 0,
    this.childFinalDamageUpgradeBonus = 0,
    this.childBossDamageUpgradeBonus = 0,
    this.childNormalDamageUpgradeBonus = 0,
    this.childDefensePenetrationUpgradeBonus = 0,
    this.childMinDamageUpgradeBonus = 0,
    this.childMaxDamageUpgradeBonus = 0,
    this.childBuiltCount = 0,
    this.childPromoted = false,
  });

  final int slotIndex;
  final TowerConfig? config;
  final int level;
  final double charge;
  final double cooldownRemaining;
  final double automationCooldownRemaining;
  final double disruption;
  final String? equippedCardInstanceId;
  final ProjectileType? projectileType;
  final PayloadType? payloadType;
  final TargetPriority targetPriority;
  final Map<ProjectileType, TargetPriority> projectileTargetPriorities;
  final int fireSequence;
  final int investedLumens;
  final double fabricationTotalSeconds;
  final double fabricationRemainingSeconds;
  final int? fabricationStartedAtServerMillis;
  final int? fabricationCompletesAtServerMillis;
  final double powerFactor;
  final double chargeFactor;
  final double cooldownFactor;
  final double rangeFactor;
  final double generationFactor;
  final double critChanceBonus;
  final double critDamageFactor;
  final double finalDamageFactor;
  final double bossDamageFactor;
  final double normalDamageFactor;
  final double defensePenetration;
  final double minDamageFactor;
  final double maxDamageFactor;
  final double dotDamageFactor;
  final List<TowerUpgradeOptionState> towerUpgradeOptions;
  final String? childLayerId;
  final int? childLayerTier;
  final String? childLayerName;
  final PrototypeAffinity? childAffinity;
  final PrototypeAffinity? childSecondaryAffinity;
  final List<ProjectileType> childProjectileLoadout;
  final List<PayloadType> childPayloadLoadout;
  final ProjectileType? childProjectileType;
  final PayloadType? childPayloadType;
  final int? childCoreLevel;
  final double? childRange;
  final double? childGenerationSpeed;
  final double? childCritChance;
  final double? childCritMultiplier;
  final double? childFinalDamageMultiplier;
  final double? childBossDamageMultiplier;
  final double? childNormalDamageMultiplier;
  final double? childDefensePenetration;
  final double? childMinDamageMultiplier;
  final double? childMaxDamageMultiplier;
  final double childPowerUpgradeBonus;
  final double childChargeUpgradeBonus;
  final double childCooldownUpgradeBonus;
  final double childRangeUpgradeBonus;
  final double childGenerationUpgradeBonus;
  final double childCritChanceUpgradeBonus;
  final double childCritDamageUpgradeBonus;
  final double childFinalDamageUpgradeBonus;
  final double childBossDamageUpgradeBonus;
  final double childNormalDamageUpgradeBonus;
  final double childDefensePenetrationUpgradeBonus;
  final double childMinDamageUpgradeBonus;
  final double childMaxDamageUpgradeBonus;
  final int childBuiltCount;
  final bool childPromoted;

  bool get isChildLayerNode => childLayerId != null;
  bool get isPromotedChildTower => isChildLayerNode && childPromoted;
  bool get isLayerProject => isChildLayerNode && !childPromoted;
  bool get hasTowerProgression => config != null || isPromotedChildTower;
  bool get isFabricating => config != null && fabricationRemainingSeconds > 0;
  double get fabricationProgress => fabricationTotalSeconds <= 0
      ? 1
      : ((fabricationTotalSeconds - fabricationRemainingSeconds) /
                fabricationTotalSeconds)
            .clamp(0.0, 1.0)
            .toDouble();

  bool get isBuilt => config != null || isChildLayerNode;

  OuterTowerState copyForSlot(int nextSlotIndex) {
    return OuterTowerState(
      slotIndex: nextSlotIndex,
      config: config,
      level: level,
      charge: charge,
      cooldownRemaining: cooldownRemaining,
      automationCooldownRemaining: automationCooldownRemaining,
      disruption: disruption,
      equippedCardInstanceId: equippedCardInstanceId,
      projectileType: projectileType,
      payloadType: payloadType,
      targetPriority: targetPriority,
      projectileTargetPriorities: projectileTargetPriorities,
      fireSequence: fireSequence,
      investedLumens: investedLumens,
      fabricationTotalSeconds: fabricationTotalSeconds,
      fabricationRemainingSeconds: fabricationRemainingSeconds,
      fabricationStartedAtServerMillis: fabricationStartedAtServerMillis,
      fabricationCompletesAtServerMillis: fabricationCompletesAtServerMillis,
      powerFactor: powerFactor,
      chargeFactor: chargeFactor,
      cooldownFactor: cooldownFactor,
      rangeFactor: rangeFactor,
      generationFactor: generationFactor,
      critChanceBonus: critChanceBonus,
      critDamageFactor: critDamageFactor,
      finalDamageFactor: finalDamageFactor,
      bossDamageFactor: bossDamageFactor,
      normalDamageFactor: normalDamageFactor,
      defensePenetration: defensePenetration,
      minDamageFactor: minDamageFactor,
      maxDamageFactor: maxDamageFactor,
      dotDamageFactor: dotDamageFactor,
      towerUpgradeOptions: towerUpgradeOptions,
      childLayerId: childLayerId,
      childLayerTier: childLayerTier,
      childLayerName: childLayerName,
      childAffinity: childAffinity,
      childSecondaryAffinity: childSecondaryAffinity,
      childProjectileLoadout: childProjectileLoadout,
      childPayloadLoadout: childPayloadLoadout,
      childProjectileType: childProjectileType,
      childPayloadType: childPayloadType,
      childCoreLevel: childCoreLevel,
      childRange: childRange,
      childGenerationSpeed: childGenerationSpeed,
      childCritChance: childCritChance,
      childCritMultiplier: childCritMultiplier,
      childFinalDamageMultiplier: childFinalDamageMultiplier,
      childBossDamageMultiplier: childBossDamageMultiplier,
      childNormalDamageMultiplier: childNormalDamageMultiplier,
      childDefensePenetration: childDefensePenetration,
      childMinDamageMultiplier: childMinDamageMultiplier,
      childMaxDamageMultiplier: childMaxDamageMultiplier,
      childPowerUpgradeBonus: childPowerUpgradeBonus,
      childChargeUpgradeBonus: childChargeUpgradeBonus,
      childCooldownUpgradeBonus: childCooldownUpgradeBonus,
      childRangeUpgradeBonus: childRangeUpgradeBonus,
      childGenerationUpgradeBonus: childGenerationUpgradeBonus,
      childCritChanceUpgradeBonus: childCritChanceUpgradeBonus,
      childCritDamageUpgradeBonus: childCritDamageUpgradeBonus,
      childFinalDamageUpgradeBonus: childFinalDamageUpgradeBonus,
      childBossDamageUpgradeBonus: childBossDamageUpgradeBonus,
      childNormalDamageUpgradeBonus: childNormalDamageUpgradeBonus,
      childDefensePenetrationUpgradeBonus: childDefensePenetrationUpgradeBonus,
      childMinDamageUpgradeBonus: childMinDamageUpgradeBonus,
      childMaxDamageUpgradeBonus: childMaxDamageUpgradeBonus,
      childBuiltCount: childBuiltCount,
      childPromoted: childPromoted,
    );
  }

  OuterTowerState copyWith({
    TowerConfig? config,
    int? level,
    double? charge,
    double? cooldownRemaining,
    double? automationCooldownRemaining,
    double? disruption,
    String? equippedCardInstanceId,
    ProjectileType? projectileType,
    PayloadType? payloadType,
    TargetPriority? targetPriority,
    Map<ProjectileType, TargetPriority>? projectileTargetPriorities,
    int? fireSequence,
    int? investedLumens,
    double? fabricationTotalSeconds,
    double? fabricationRemainingSeconds,
    int? fabricationStartedAtServerMillis,
    int? fabricationCompletesAtServerMillis,
    double? powerFactor,
    double? chargeFactor,
    double? cooldownFactor,
    double? rangeFactor,
    double? generationFactor,
    double? critChanceBonus,
    double? critDamageFactor,
    double? finalDamageFactor,
    double? bossDamageFactor,
    double? normalDamageFactor,
    double? defensePenetration,
    double? minDamageFactor,
    double? maxDamageFactor,
    double? dotDamageFactor,
    List<TowerUpgradeOptionState>? towerUpgradeOptions,
    String? childLayerId,
    int? childLayerTier,
    String? childLayerName,
    PrototypeAffinity? childAffinity,
    PrototypeAffinity? childSecondaryAffinity,
    List<ProjectileType>? childProjectileLoadout,
    List<PayloadType>? childPayloadLoadout,
    ProjectileType? childProjectileType,
    PayloadType? childPayloadType,
    int? childCoreLevel,
    double? childRange,
    double? childGenerationSpeed,
    double? childCritChance,
    double? childCritMultiplier,
    double? childFinalDamageMultiplier,
    double? childBossDamageMultiplier,
    double? childNormalDamageMultiplier,
    double? childDefensePenetration,
    double? childMinDamageMultiplier,
    double? childMaxDamageMultiplier,
    double? childPowerUpgradeBonus,
    double? childChargeUpgradeBonus,
    double? childCooldownUpgradeBonus,
    double? childRangeUpgradeBonus,
    double? childGenerationUpgradeBonus,
    double? childCritChanceUpgradeBonus,
    double? childCritDamageUpgradeBonus,
    double? childFinalDamageUpgradeBonus,
    double? childBossDamageUpgradeBonus,
    double? childNormalDamageUpgradeBonus,
    double? childDefensePenetrationUpgradeBonus,
    double? childMinDamageUpgradeBonus,
    double? childMaxDamageUpgradeBonus,
    int? childBuiltCount,
    bool? childPromoted,
    bool clearEquippedCard = false,
    bool clearChildLayer = false,
  }) {
    return OuterTowerState(
      slotIndex: slotIndex,
      config: config ?? this.config,
      level: level ?? this.level,
      charge: charge ?? this.charge,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      automationCooldownRemaining:
          automationCooldownRemaining ?? this.automationCooldownRemaining,
      disruption: disruption ?? this.disruption,
      equippedCardInstanceId: clearEquippedCard
          ? null
          : equippedCardInstanceId ?? this.equippedCardInstanceId,
      projectileType: projectileType ?? this.projectileType,
      payloadType: payloadType ?? this.payloadType,
      targetPriority: targetPriority ?? this.targetPriority,
      projectileTargetPriorities:
          projectileTargetPriorities ?? this.projectileTargetPriorities,
      fireSequence: fireSequence ?? this.fireSequence,
      investedLumens: investedLumens ?? this.investedLumens,
      fabricationTotalSeconds:
          fabricationTotalSeconds ?? this.fabricationTotalSeconds,
      fabricationRemainingSeconds:
          fabricationRemainingSeconds ?? this.fabricationRemainingSeconds,
      fabricationStartedAtServerMillis:
          fabricationStartedAtServerMillis ??
          this.fabricationStartedAtServerMillis,
      fabricationCompletesAtServerMillis:
          fabricationCompletesAtServerMillis ??
          this.fabricationCompletesAtServerMillis,
      powerFactor: powerFactor ?? this.powerFactor,
      chargeFactor: chargeFactor ?? this.chargeFactor,
      cooldownFactor: cooldownFactor ?? this.cooldownFactor,
      rangeFactor: rangeFactor ?? this.rangeFactor,
      generationFactor: generationFactor ?? this.generationFactor,
      critChanceBonus: critChanceBonus ?? this.critChanceBonus,
      critDamageFactor: critDamageFactor ?? this.critDamageFactor,
      finalDamageFactor: finalDamageFactor ?? this.finalDamageFactor,
      bossDamageFactor: bossDamageFactor ?? this.bossDamageFactor,
      normalDamageFactor: normalDamageFactor ?? this.normalDamageFactor,
      defensePenetration: defensePenetration ?? this.defensePenetration,
      minDamageFactor: minDamageFactor ?? this.minDamageFactor,
      maxDamageFactor: maxDamageFactor ?? this.maxDamageFactor,
      dotDamageFactor: dotDamageFactor ?? this.dotDamageFactor,
      towerUpgradeOptions: towerUpgradeOptions ?? this.towerUpgradeOptions,
      childLayerId: clearChildLayer ? null : childLayerId ?? this.childLayerId,
      childLayerTier: clearChildLayer
          ? null
          : childLayerTier ?? this.childLayerTier,
      childLayerName: clearChildLayer
          ? null
          : childLayerName ?? this.childLayerName,
      childAffinity: clearChildLayer
          ? null
          : childAffinity ?? this.childAffinity,
      childSecondaryAffinity: clearChildLayer
          ? null
          : childSecondaryAffinity ?? this.childSecondaryAffinity,
      childProjectileLoadout: clearChildLayer
          ? const <ProjectileType>[]
          : childProjectileLoadout ?? this.childProjectileLoadout,
      childPayloadLoadout: clearChildLayer
          ? const <PayloadType>[]
          : childPayloadLoadout ?? this.childPayloadLoadout,
      childProjectileType: clearChildLayer
          ? null
          : childProjectileType ?? this.childProjectileType,
      childPayloadType: clearChildLayer
          ? null
          : childPayloadType ?? this.childPayloadType,
      childCoreLevel: clearChildLayer
          ? null
          : childCoreLevel ?? this.childCoreLevel,
      childRange: clearChildLayer ? null : childRange ?? this.childRange,
      childGenerationSpeed: clearChildLayer
          ? null
          : childGenerationSpeed ?? this.childGenerationSpeed,
      childCritChance: clearChildLayer
          ? null
          : childCritChance ?? this.childCritChance,
      childCritMultiplier: clearChildLayer
          ? null
          : childCritMultiplier ?? this.childCritMultiplier,
      childFinalDamageMultiplier: clearChildLayer
          ? null
          : childFinalDamageMultiplier ?? this.childFinalDamageMultiplier,
      childBossDamageMultiplier: clearChildLayer
          ? null
          : childBossDamageMultiplier ?? this.childBossDamageMultiplier,
      childNormalDamageMultiplier: clearChildLayer
          ? null
          : childNormalDamageMultiplier ?? this.childNormalDamageMultiplier,
      childDefensePenetration: clearChildLayer
          ? null
          : childDefensePenetration ?? this.childDefensePenetration,
      childMinDamageMultiplier: clearChildLayer
          ? null
          : childMinDamageMultiplier ?? this.childMinDamageMultiplier,
      childMaxDamageMultiplier: clearChildLayer
          ? null
          : childMaxDamageMultiplier ?? this.childMaxDamageMultiplier,
      childPowerUpgradeBonus: clearChildLayer
          ? 0
          : childPowerUpgradeBonus ?? this.childPowerUpgradeBonus,
      childChargeUpgradeBonus: clearChildLayer
          ? 0
          : childChargeUpgradeBonus ?? this.childChargeUpgradeBonus,
      childCooldownUpgradeBonus: clearChildLayer
          ? 0
          : childCooldownUpgradeBonus ?? this.childCooldownUpgradeBonus,
      childRangeUpgradeBonus: clearChildLayer
          ? 0
          : childRangeUpgradeBonus ?? this.childRangeUpgradeBonus,
      childGenerationUpgradeBonus: clearChildLayer
          ? 0
          : childGenerationUpgradeBonus ?? this.childGenerationUpgradeBonus,
      childCritChanceUpgradeBonus: clearChildLayer
          ? 0
          : childCritChanceUpgradeBonus ?? this.childCritChanceUpgradeBonus,
      childCritDamageUpgradeBonus: clearChildLayer
          ? 0
          : childCritDamageUpgradeBonus ?? this.childCritDamageUpgradeBonus,
      childFinalDamageUpgradeBonus: clearChildLayer
          ? 0
          : childFinalDamageUpgradeBonus ?? this.childFinalDamageUpgradeBonus,
      childBossDamageUpgradeBonus: clearChildLayer
          ? 0
          : childBossDamageUpgradeBonus ?? this.childBossDamageUpgradeBonus,
      childNormalDamageUpgradeBonus: clearChildLayer
          ? 0
          : childNormalDamageUpgradeBonus ?? this.childNormalDamageUpgradeBonus,
      childDefensePenetrationUpgradeBonus: clearChildLayer
          ? 0
          : childDefensePenetrationUpgradeBonus ??
                this.childDefensePenetrationUpgradeBonus,
      childMinDamageUpgradeBonus: clearChildLayer
          ? 0
          : childMinDamageUpgradeBonus ?? this.childMinDamageUpgradeBonus,
      childMaxDamageUpgradeBonus: clearChildLayer
          ? 0
          : childMaxDamageUpgradeBonus ?? this.childMaxDamageUpgradeBonus,
      childBuiltCount: clearChildLayer
          ? 0
          : childBuiltCount ?? this.childBuiltCount,
      childPromoted: clearChildLayer
          ? false
          : childPromoted ?? this.childPromoted,
    );
  }
}

class TowerUpgradeOptionState {
  const TowerUpgradeOptionState({
    required this.type,
    this.rank = 0,
    this.isOvercharge = false,
    this.isRadiant = false,
  });

  final TowerUpgradeStatType type;
  final int rank;
  final bool isOvercharge;
  final bool isRadiant;

  TowerUpgradeOptionState copyWith({
    TowerUpgradeStatType? type,
    int? rank,
    bool? isOvercharge,
    bool? isRadiant,
  }) {
    return TowerUpgradeOptionState(
      type: type ?? this.type,
      rank: rank ?? this.rank,
      isOvercharge: isOvercharge ?? this.isOvercharge,
      isRadiant: isRadiant ?? this.isRadiant,
    );
  }
}

class ChildTowerUpgradeState {
  const ChildTowerUpgradeState({required this.type, this.rank = 0});

  final ChildTowerUpgradeType type;
  final int rank;

  ChildTowerUpgradeState copyWith({ChildTowerUpgradeType? type, int? rank}) {
    return ChildTowerUpgradeState(
      type: type ?? this.type,
      rank: rank ?? this.rank,
    );
  }
}

class CompletedTowerShellState {
  const CompletedTowerShellState({
    required this.id,
    required this.sourceLayerId,
    required this.sourceLayerLabel,
    required this.sourceLayerTier,
    required this.savedAtMillis,
    required this.layer,
    this.sourceSlotIndex,
    this.archived = true,
  });

  final String id;
  final String sourceLayerId;
  final String sourceLayerLabel;
  final int sourceLayerTier;
  final int? sourceSlotIndex;
  final int savedAtMillis;
  final TowerLayerSnapshot layer;
  final bool archived;

  String get sourceLabel {
    final slotIndex = sourceSlotIndex;
    if (slotIndex == null || slotIndex < 0) {
      return '$sourceLayerLabel set';
    }
    return '$sourceLayerLabel set • Layer 2 Hex ${slotIndex + 1}';
  }
}

class InventoryCard {
  const InventoryCard({
    required this.instanceId,
    required this.config,
    required this.rarity,
    required this.forgeCost,
    required this.powerMultiplier,
    required this.chargeMultiplier,
    required this.cooldownMultiplier,
    required this.advantageMultiplier,
    required this.automationRate,
    required this.primaryTraitLabel,
    required this.secondaryTraitLabel,
    this.favoredAffinity,
    this.projectileFocus,
    this.payloadFocus,
    this.equippedLayerId,
    this.equippedSlotIndex,
  });

  final String instanceId;
  final CardConfig config;
  final ManagerRarity rarity;
  final int forgeCost;
  final double powerMultiplier;
  final double chargeMultiplier;
  final double cooldownMultiplier;
  final double advantageMultiplier;
  final double automationRate;
  final String primaryTraitLabel;
  final String secondaryTraitLabel;
  final PrototypeAffinity? favoredAffinity;
  final ProjectileType? projectileFocus;
  final PayloadType? payloadFocus;
  final String? equippedLayerId;
  final int? equippedSlotIndex;

  String get name => '${rarity.label} ${config.name}';

  String get roleLabel => config.roleLabel;

  int get dismantleFlux => forgeCost ~/ 10;

  String get summary {
    final focus = <String>[
      if (favoredAffinity != null) 'Favours ${favoredAffinity!.label}',
      if (projectileFocus != null) '${projectileFocus!.label} shot bias',
      if (payloadFocus != null) '${payloadFocus!.label} payload bias',
    ];
    return [
      config.summary,
      primaryTraitLabel,
      secondaryTraitLabel,
      if (focus.isNotEmpty) focus.join(' • '),
    ].join('  ');
  }

  InventoryCard copyWith({
    String? equippedLayerId,
    int? equippedSlotIndex,
    bool clearEquippedSlot = false,
    bool clearEquippedSlotIndex = false,
  }) {
    return InventoryCard(
      instanceId: instanceId,
      config: config,
      rarity: rarity,
      forgeCost: forgeCost,
      powerMultiplier: powerMultiplier,
      chargeMultiplier: chargeMultiplier,
      cooldownMultiplier: cooldownMultiplier,
      advantageMultiplier: advantageMultiplier,
      automationRate: automationRate,
      primaryTraitLabel: primaryTraitLabel,
      secondaryTraitLabel: secondaryTraitLabel,
      favoredAffinity: favoredAffinity,
      projectileFocus: projectileFocus,
      payloadFocus: payloadFocus,
      equippedLayerId: clearEquippedSlot
          ? null
          : equippedLayerId ?? this.equippedLayerId,
      equippedSlotIndex: clearEquippedSlot || clearEquippedSlotIndex
          ? null
          : equippedSlotIndex ?? this.equippedSlotIndex,
    );
  }
}

class EnemyState {
  const EnemyState({
    required this.id,
    required this.sourceCardId,
    required this.cardLevel,
    required this.config,
    required this.spawnRadius,
    required this.angle,
    required this.radius,
    required this.health,
    required this.maxHealth,
    required this.defense,
    required this.speed,
    required this.reward,
    required this.experienceReward,
    required this.jamStrength,
    required this.angularVelocity,
    required this.splitDepth,
    required this.sizeScale,
    this.burnRemaining = 0,
    this.burnDamagePerSecond = 0,
    this.slowRemaining = 0,
    this.slowFactor = 1,
    this.shockRemaining = 0,
    this.bountyRemaining = 0,
    this.bountyMultiplier = 1,
    this.age = 0,
  });

  final String id;
  final String sourceCardId;
  final int cardLevel;
  final EnemyConfig config;
  final double spawnRadius;
  final double angle;
  final double radius;
  final double health;
  final double maxHealth;
  final double defense;
  final double speed;
  final int reward;
  final int experienceReward;
  final double jamStrength;
  final double angularVelocity;
  final int splitDepth;
  final double sizeScale;
  final double burnRemaining;
  final double burnDamagePerSecond;
  final double slowRemaining;
  final double slowFactor;
  final double shockRemaining;
  final double bountyRemaining;
  final double bountyMultiplier;
  final double age;

  EnemyState copyWith({
    double? spawnRadius,
    double? angle,
    double? radius,
    double? health,
    double? defense,
    double? speed,
    double? angularVelocity,
    int? reward,
    int? experienceReward,
    double? jamStrength,
    int? splitDepth,
    double? sizeScale,
    double? burnRemaining,
    double? burnDamagePerSecond,
    double? slowRemaining,
    double? slowFactor,
    double? shockRemaining,
    double? bountyRemaining,
    double? bountyMultiplier,
    double? age,
  }) {
    return EnemyState(
      id: id,
      sourceCardId: sourceCardId,
      cardLevel: cardLevel,
      config: config,
      spawnRadius: spawnRadius ?? this.spawnRadius,
      angle: angle ?? this.angle,
      radius: radius ?? this.radius,
      health: health ?? this.health,
      maxHealth: maxHealth,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      reward: reward ?? this.reward,
      experienceReward: experienceReward ?? this.experienceReward,
      jamStrength: jamStrength ?? this.jamStrength,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      splitDepth: splitDepth ?? this.splitDepth,
      sizeScale: sizeScale ?? this.sizeScale,
      burnRemaining: burnRemaining ?? this.burnRemaining,
      burnDamagePerSecond: burnDamagePerSecond ?? this.burnDamagePerSecond,
      slowRemaining: slowRemaining ?? this.slowRemaining,
      slowFactor: slowFactor ?? this.slowFactor,
      shockRemaining: shockRemaining ?? this.shockRemaining,
      bountyRemaining: bountyRemaining ?? this.bountyRemaining,
      bountyMultiplier: bountyMultiplier ?? this.bountyMultiplier,
      age: age ?? this.age,
    );
  }
}

class EnemyCardState {
  const EnemyCardState({
    required this.config,
    this.unlocked = false,
    this.copies = 0,
    this.level = 1,
  });

  final EnemyConfig config;
  final bool unlocked;
  final int copies;
  final int level;

  bool get isOwned => unlocked;

  EnemyCardState copyWith({bool? unlocked, int? copies, int? level}) {
    return EnemyCardState(
      config: config,
      unlocked: unlocked ?? this.unlocked,
      copies: copies ?? this.copies,
      level: level ?? this.level,
    );
  }
}

class PackPullResult {
  const PackPullResult({required this.config, required this.isNew});

  final EnemyConfig config;
  final bool isNew;
}

class ThreatRegionState {
  const ThreatRegionState({
    required this.regionId,
    this.revealed = false,
    this.stabilizedLevel = 0,
    this.assignedThreatDirectorId,
    this.validatedThreatDirectorId,
    this.bestStabilityPercent = 0,
    this.fullyStabilizedAtMillis,
  });

  final String regionId;
  final bool revealed;
  final int stabilizedLevel;
  final String? assignedThreatDirectorId;
  final String? validatedThreatDirectorId;
  final double bestStabilityPercent;
  final int? fullyStabilizedAtMillis;

  bool get hasValidatedThreatDirector =>
      assignedThreatDirectorId != null &&
      assignedThreatDirectorId == validatedThreatDirectorId;

  ThreatRegionState copyWith({
    bool? revealed,
    int? stabilizedLevel,
    String? assignedThreatDirectorId,
    String? validatedThreatDirectorId,
    double? bestStabilityPercent,
    int? fullyStabilizedAtMillis,
    bool clearAssignedThreatDirector = false,
    bool clearValidatedThreatDirector = false,
    bool clearFullyStabilizedAt = false,
  }) {
    return ThreatRegionState(
      regionId: regionId,
      revealed: revealed ?? this.revealed,
      stabilizedLevel: stabilizedLevel ?? this.stabilizedLevel,
      assignedThreatDirectorId: clearAssignedThreatDirector
          ? null
          : assignedThreatDirectorId ?? this.assignedThreatDirectorId,
      validatedThreatDirectorId: clearValidatedThreatDirector
          ? null
          : validatedThreatDirectorId ?? this.validatedThreatDirectorId,
      bestStabilityPercent: bestStabilityPercent ?? this.bestStabilityPercent,
      fullyStabilizedAtMillis: clearFullyStabilizedAt
          ? null
          : fullyStabilizedAtMillis ?? this.fullyStabilizedAtMillis,
    );
  }
}

class RegionEchoState {
  const RegionEchoState({required this.regionId, required this.count});

  final String regionId;
  final int count;

  RegionEchoState copyWith({int? count}) {
    return RegionEchoState(regionId: regionId, count: count ?? this.count);
  }
}

class BossTraitState {
  const BossTraitState({
    required this.config,
    this.unlocked = false,
    this.copies = 0,
  });

  final BossTraitConfig config;
  final bool unlocked;
  final int copies;

  bool get isOwned => unlocked;

  BossTraitState copyWith({bool? unlocked, int? copies}) {
    return BossTraitState(
      config: config,
      unlocked: unlocked ?? this.unlocked,
      copies: copies ?? this.copies,
    );
  }
}

class ApexCoreState {
  const ApexCoreState({
    required this.bossConfig,
    this.unlocked = false,
    this.copies = 0,
  });

  final EnemyConfig bossConfig;
  final bool unlocked;
  final int copies;

  bool get isOwned => unlocked;

  ApexCoreState copyWith({bool? unlocked, int? copies}) {
    return ApexCoreState(
      bossConfig: bossConfig,
      unlocked: unlocked ?? this.unlocked,
      copies: copies ?? this.copies,
    );
  }
}

class EnemySuiteState {
  const EnemySuiteState({
    this.apexCoreBossId,
    this.bossTraitIds = const <String>[],
    this.anomalyCardIds = const <String>[],
  });

  final String? apexCoreBossId;
  final List<String> bossTraitIds;
  final List<String> anomalyCardIds;

  EnemySuiteState copyWith({
    String? apexCoreBossId,
    List<String>? bossTraitIds,
    List<String>? anomalyCardIds,
    bool clearApexCore = false,
  }) {
    return EnemySuiteState(
      apexCoreBossId: clearApexCore
          ? null
          : apexCoreBossId ?? this.apexCoreBossId,
      bossTraitIds: bossTraitIds ?? this.bossTraitIds,
      anomalyCardIds: anomalyCardIds ?? this.anomalyCardIds,
    );
  }
}

class ThreatRegionChallengeState {
  const ThreatRegionChallengeState({
    required this.regionId,
    required this.targetStabilizationLevel,
    required this.finalLayer,
    required this.startedAtMillis,
    this.elapsedSeconds = 0,
    this.waveIndex = 0,
    this.waveElapsedSeconds = 0,
  });

  final String regionId;
  final int targetStabilizationLevel;
  final bool finalLayer;
  final int startedAtMillis;
  final double elapsedSeconds;
  final int waveIndex;
  final double waveElapsedSeconds;

  ThreatRegionChallengeState copyWith({
    double? elapsedSeconds,
    int? waveIndex,
    double? waveElapsedSeconds,
  }) {
    return ThreatRegionChallengeState(
      regionId: regionId,
      targetStabilizationLevel: targetStabilizationLevel,
      finalLayer: finalLayer,
      startedAtMillis: startedAtMillis,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      waveIndex: waveIndex ?? this.waveIndex,
      waveElapsedSeconds: waveElapsedSeconds ?? this.waveElapsedSeconds,
    );
  }
}

class ThreatRegionFarmValidationState {
  const ThreatRegionFarmValidationState({
    required this.regionId,
    required this.targetStabilizationLevel,
    required this.startedAtMillis,
    required this.farmSwarmSize,
    this.threatDirectorId,
    this.waveIndex = 0,
    this.waveElapsedSeconds = 0,
    this.lowestStabilityPercent = 100,
  });

  final String regionId;
  final int targetStabilizationLevel;
  final int startedAtMillis;
  final int farmSwarmSize;
  final String? threatDirectorId;
  final int waveIndex;
  final double waveElapsedSeconds;
  final double lowestStabilityPercent;

  ThreatRegionFarmValidationState copyWith({
    int? waveIndex,
    double? waveElapsedSeconds,
    double? lowestStabilityPercent,
  }) {
    return ThreatRegionFarmValidationState(
      regionId: regionId,
      targetStabilizationLevel: targetStabilizationLevel,
      startedAtMillis: startedAtMillis,
      farmSwarmSize: farmSwarmSize,
      threatDirectorId: threatDirectorId,
      waveIndex: waveIndex ?? this.waveIndex,
      waveElapsedSeconds: waveElapsedSeconds ?? this.waveElapsedSeconds,
      lowestStabilityPercent:
          lowestStabilityPercent ?? this.lowestStabilityPercent,
    );
  }
}

class EnemyManagerState {
  const EnemyManagerState({
    required this.instanceId,
    required this.config,
    required this.rarity,
    required this.forgeCost,
    required this.spawnRateMultiplier,
    required this.rewardMultiplier,
    required this.experienceMultiplier,
    required this.healthMultiplier,
    required this.speedMultiplier,
    required this.stabilityDamageMultiplier,
    required this.apexStabilityMultiplier,
    required this.queueDisruptionMultiplier,
    required this.primaryTraitLabel,
    required this.secondaryTraitLabel,
    this.targetAffinity,
    this.assignedLayerId,
    this.assignedEnemyCardId,
  });

  final String instanceId;
  final EnemyManagerConfig config;
  final ManagerRarity rarity;
  final int forgeCost;
  final double spawnRateMultiplier;
  final double rewardMultiplier;
  final double experienceMultiplier;
  final double healthMultiplier;
  final double speedMultiplier;
  final double stabilityDamageMultiplier;
  final double apexStabilityMultiplier;
  final double queueDisruptionMultiplier;
  final String primaryTraitLabel;
  final String secondaryTraitLabel;
  final PrototypeAffinity? targetAffinity;
  final String? assignedLayerId;
  final String? assignedEnemyCardId;

  String get name => '${rarity.label} ${config.name}';

  String get roleLabel => config.roleLabel;

  int get dismantleFlux => forgeCost ~/ 10;

  double get strengthMultiplier => (healthMultiplier + speedMultiplier) / 2;

  String get spawnRewardTraitLabel =>
      'Spawn ${_formatEnemyManagerDelta(spawnRateMultiplier - 1)} • Rewards ${_formatEnemyManagerDelta(rewardMultiplier - 1)} • EXP ${_formatEnemyManagerDelta(experienceMultiplier - 1)}';

  String get strengthTraitLabel =>
      'Enemy strength ${_formatEnemyManagerDelta(strengthMultiplier - 1)} • Stability risk ${_formatEnemyManagerDelta(stabilityDamageMultiplier - 1)} • Apex risk ${_formatEnemyManagerDelta(apexStabilityMultiplier - 1)}';

  String get summary {
    final focus = targetAffinity == null
        ? 'Applies to any Spectrum Band'
        : 'Best on ${targetAffinity!.label} anomalies';
    return [
      config.summary,
      spawnRewardTraitLabel,
      strengthTraitLabel,
      focus,
    ].join('  ');
  }

  EnemyManagerState copyWith({
    String? assignedLayerId,
    String? assignedEnemyCardId,
    bool clearAssignment = false,
    bool clearAssignedEnemyCard = false,
  }) {
    return EnemyManagerState(
      instanceId: instanceId,
      config: config,
      rarity: rarity,
      forgeCost: forgeCost,
      spawnRateMultiplier: spawnRateMultiplier,
      rewardMultiplier: rewardMultiplier,
      experienceMultiplier: experienceMultiplier,
      healthMultiplier: healthMultiplier,
      speedMultiplier: speedMultiplier,
      stabilityDamageMultiplier: stabilityDamageMultiplier,
      apexStabilityMultiplier: apexStabilityMultiplier,
      queueDisruptionMultiplier: queueDisruptionMultiplier,
      primaryTraitLabel: primaryTraitLabel,
      secondaryTraitLabel: secondaryTraitLabel,
      targetAffinity: targetAffinity,
      assignedLayerId: clearAssignment
          ? null
          : assignedLayerId ?? this.assignedLayerId,
      assignedEnemyCardId: clearAssignment || clearAssignedEnemyCard
          ? null
          : assignedEnemyCardId ?? this.assignedEnemyCardId,
    );
  }
}

String _formatEnemyManagerDelta(double delta) {
  final value = (delta * 100).round();
  return '${value >= 0 ? '+' : ''}$value%';
}

class ThreatAssignmentPresetState {
  const ThreatAssignmentPresetState({
    required this.id,
    required this.name,
    required this.enemyCardIds,
    this.bossCardId,
  });

  final String id;
  final String name;
  final List<String> enemyCardIds;
  final String? bossCardId;

  ThreatAssignmentPresetState copyWith({
    String? name,
    List<String>? enemyCardIds,
    String? bossCardId,
    bool clearBossCard = false,
  }) {
    return ThreatAssignmentPresetState(
      id: id,
      name: name ?? this.name,
      enemyCardIds: enemyCardIds ?? this.enemyCardIds,
      bossCardId: clearBossCard ? null : bossCardId ?? this.bossCardId,
    );
  }
}

class PlayerEquipmentItem {
  const PlayerEquipmentItem({
    required this.instanceId,
    required this.setId,
    required this.setName,
    required this.slotType,
    required this.name,
    required this.rarity,
    required this.level,
    required this.affinity,
    required this.sourceEnemyId,
    required this.sourceEnemyName,
    required this.bonuses,
    required this.dropOrder,
  });

  final String instanceId;
  final String setId;
  final String setName;
  final EquipmentInventorySlot slotType;
  final String name;
  final ManagerRarity rarity;
  final int level;
  final PrototypeAffinity affinity;
  final String sourceEnemyId;
  final String sourceEnemyName;
  final EquipmentBonusProfile bonuses;
  final int dropOrder;

  String get title => '$name Lv $level';
}

class EquipmentSetStatus {
  const EquipmentSetStatus({
    required this.config,
    required this.equippedCount,
    required this.unlockedBonuses,
  });

  final EquipmentSetConfig config;
  final int equippedCount;
  final List<EquipmentSetBonusConfig> unlockedBonuses;
}

class ProfileMedalStatus {
  const ProfileMedalStatus({
    required this.config,
    required this.unlocked,
    required this.equipped,
    required this.progress,
    required this.target,
  });

  final ProfileMedalConfig config;
  final bool unlocked;
  final bool equipped;
  final int progress;
  final int target;

  double get progressFraction {
    if (target <= 0) {
      return 1;
    }
    return (progress / target).clamp(0.0, 1.0).toDouble();
  }

  String get progressLabel => '${progress.clamp(0, target)}/$target';
}

class EnergyPulseState {
  const EnergyPulseState({
    required this.id,
    required this.sourceSlotIndex,
    required this.affinity,
    this.secondaryAffinity,
    required this.power,
    required this.advantageMultiplier,
    required this.projectileType,
    required this.payloadType,
    required this.targetPriority,
    required this.range,
    required this.generationSpeed,
    required this.critChance,
    required this.critMultiplier,
    required this.finalDamageMultiplier,
    required this.bossDamageMultiplier,
    required this.normalDamageMultiplier,
    required this.defensePenetration,
    required this.minDamageMultiplier,
    required this.maxDamageMultiplier,
    required this.progress,
    this.inboundStartedAtElapsed,
    this.criticalBoosted = false,
  });

  final String id;
  final int? sourceSlotIndex;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final double power;
  final double advantageMultiplier;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final TargetPriority targetPriority;
  final double range;
  final double generationSpeed;
  final double critChance;
  final double critMultiplier;
  final double finalDamageMultiplier;
  final double bossDamageMultiplier;
  final double normalDamageMultiplier;
  final double defensePenetration;
  final double minDamageMultiplier;
  final double maxDamageMultiplier;
  final double progress;
  final double? inboundStartedAtElapsed;
  final bool criticalBoosted;

  EnergyPulseState copyWith({
    double? progress,
    double? inboundStartedAtElapsed,
    bool? criticalBoosted,
  }) {
    return EnergyPulseState(
      id: id,
      sourceSlotIndex: sourceSlotIndex,
      affinity: affinity,
      secondaryAffinity: secondaryAffinity,
      power: power,
      advantageMultiplier: advantageMultiplier,
      projectileType: projectileType,
      payloadType: payloadType,
      targetPriority: targetPriority,
      range: range,
      generationSpeed: generationSpeed,
      critChance: critChance,
      critMultiplier: critMultiplier,
      finalDamageMultiplier: finalDamageMultiplier,
      bossDamageMultiplier: bossDamageMultiplier,
      normalDamageMultiplier: normalDamageMultiplier,
      defensePenetration: defensePenetration,
      minDamageMultiplier: minDamageMultiplier,
      maxDamageMultiplier: maxDamageMultiplier,
      progress: progress ?? this.progress,
      inboundStartedAtElapsed:
          inboundStartedAtElapsed ?? this.inboundStartedAtElapsed,
      criticalBoosted: criticalBoosted ?? this.criticalBoosted,
    );
  }
}

class AmmoPacket {
  const AmmoPacket({
    required this.id,
    required this.sourceSlotIndex,
    required this.affinity,
    this.secondaryAffinity,
    required this.power,
    required this.advantageMultiplier,
    required this.projectileType,
    required this.payloadType,
    required this.targetPriority,
    required this.range,
    required this.critChance,
    required this.critMultiplier,
    required this.finalDamageMultiplier,
    required this.bossDamageMultiplier,
    required this.normalDamageMultiplier,
    required this.defensePenetration,
    required this.minDamageMultiplier,
    required this.maxDamageMultiplier,
    this.criticalBoosted = false,
  });

  final String id;
  final int? sourceSlotIndex;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final double power;
  final double advantageMultiplier;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final TargetPriority targetPriority;
  final double range;
  final double critChance;
  final double critMultiplier;
  final double finalDamageMultiplier;
  final double bossDamageMultiplier;
  final double normalDamageMultiplier;
  final double defensePenetration;
  final double minDamageMultiplier;
  final double maxDamageMultiplier;
  final bool criticalBoosted;
}

class CoreShotState {
  const CoreShotState({
    required this.id,
    required this.enemyId,
    required this.affinity,
    this.secondaryAffinity,
    required this.power,
    required this.projectileType,
    required this.payloadType,
    required this.progress,
    required this.layer2,
    required this.critChance,
    required this.critMultiplier,
    required this.critical,
    required this.aimAngle,
    required this.travelRadius,
    this.sourceSlotIndex,
    this.advantageMultiplier = 1,
    this.bossDamageMultiplier = 1,
    this.normalDamageMultiplier = 1,
    this.defensePenetration = 0,
    this.criticalBoosted = false,
    this.hitEnemyIds = const <String>[],
  });

  final String id;
  final String enemyId;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final double power;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final double progress;
  final bool layer2;
  final double critChance;
  final double critMultiplier;
  final bool critical;
  final double aimAngle;
  final double travelRadius;
  final int? sourceSlotIndex;
  final double advantageMultiplier;
  final double bossDamageMultiplier;
  final double normalDamageMultiplier;
  final double defensePenetration;
  final bool criticalBoosted;
  final List<String> hitEnemyIds;

  CoreShotState copyWith({double? progress, List<String>? hitEnemyIds}) {
    return CoreShotState(
      id: id,
      enemyId: enemyId,
      affinity: affinity,
      secondaryAffinity: secondaryAffinity,
      power: power,
      projectileType: projectileType,
      payloadType: payloadType,
      progress: progress ?? this.progress,
      layer2: layer2,
      critChance: critChance,
      critMultiplier: critMultiplier,
      critical: critical,
      aimAngle: aimAngle,
      travelRadius: travelRadius,
      sourceSlotIndex: sourceSlotIndex,
      advantageMultiplier: advantageMultiplier,
      bossDamageMultiplier: bossDamageMultiplier,
      normalDamageMultiplier: normalDamageMultiplier,
      defensePenetration: defensePenetration,
      criticalBoosted: criticalBoosted,
      hitEnemyIds: hitEnemyIds ?? this.hitEnemyIds,
    );
  }
}

class ImpactState {
  const ImpactState({
    required this.id,
    required this.affinity,
    this.secondaryAffinity,
    required this.projectileType,
    required this.payloadType,
    required this.angle,
    required this.radius,
    required this.progress,
    required this.lethal,
    required this.towerHit,
    required this.critical,
    this.critChance = 0,
    this.critMultiplier = 1,
    this.progressRate = 1,
    this.fieldRadius = 0,
    this.fieldDamagePerSecond = 0,
    this.sweepDamage = 0,
    this.sweepBandWidth = 0,
    this.advantageMultiplier = 1,
    this.bossDamageMultiplier = 1,
    this.normalDamageMultiplier = 1,
    this.defensePenetration = 0,
    this.hitEnemyIds = const <String>[],
    this.sourceSlotIndex,
    this.chainSourceAngle,
    this.chainSourceRadius,
    this.defeatedEnemyAffinity,
    this.defeatedEnemySizeScale = 1,
  });

  final String id;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final double angle;
  final double radius;
  final double progress;
  final bool lethal;
  final bool towerHit;
  final bool critical;
  final double critChance;
  final double critMultiplier;
  final double progressRate;
  final double fieldRadius;
  final double fieldDamagePerSecond;
  final double sweepDamage;
  final double sweepBandWidth;
  final double advantageMultiplier;
  final double bossDamageMultiplier;
  final double normalDamageMultiplier;
  final double defensePenetration;
  final List<String> hitEnemyIds;
  final int? sourceSlotIndex;
  final double? chainSourceAngle;
  final double? chainSourceRadius;
  final PrototypeAffinity? defeatedEnemyAffinity;
  final double defeatedEnemySizeScale;

  bool get hasLingeringField =>
      fieldRadius > 0 &&
      fieldDamagePerSecond > 0 &&
      projectileType != ProjectileType.coreBomb;
  bool get hasImpactSweep =>
      fieldRadius > 0 && sweepDamage > 0 && sweepBandWidth > 0;
  bool get hasChainSource =>
      chainSourceAngle != null && chainSourceRadius != null;

  ImpactState copyWith({double? progress, List<String>? hitEnemyIds}) {
    return ImpactState(
      id: id,
      affinity: affinity,
      secondaryAffinity: secondaryAffinity,
      projectileType: projectileType,
      payloadType: payloadType,
      angle: angle,
      radius: radius,
      progress: progress ?? this.progress,
      lethal: lethal,
      towerHit: towerHit,
      critical: critical,
      critChance: critChance,
      critMultiplier: critMultiplier,
      progressRate: progressRate,
      fieldRadius: fieldRadius,
      fieldDamagePerSecond: fieldDamagePerSecond,
      sweepDamage: sweepDamage,
      sweepBandWidth: sweepBandWidth,
      advantageMultiplier: advantageMultiplier,
      bossDamageMultiplier: bossDamageMultiplier,
      normalDamageMultiplier: normalDamageMultiplier,
      defensePenetration: defensePenetration,
      hitEnemyIds: hitEnemyIds ?? this.hitEnemyIds,
      sourceSlotIndex: sourceSlotIndex,
      chainSourceAngle: chainSourceAngle,
      chainSourceRadius: chainSourceRadius,
      defeatedEnemyAffinity: defeatedEnemyAffinity,
      defeatedEnemySizeScale: defeatedEnemySizeScale,
    );
  }
}

class CoreState {
  const CoreState({
    this.coreStability = 100,
    this.coreEnergy = 100,
    required this.flowEfficiency,
    required this.fireCooldownRemaining,
    this.packetCooldownRemaining = 0,
    this.automationCooldownRemaining = 0,
    required this.level,
    required this.projectileType,
    required this.payloadType,
    required this.affinity,
    this.secondaryAffinity,
    this.projectileLoadout = const <ProjectileType>[],
    this.payloadLoadout = const <PayloadType>[],
    this.fireSequence = 0,
    this.rangeUpgradeLevel = 0,
    this.fireSpeedUpgradeLevel = 0,
    this.multiShotUpgradeLevel = 0,
    this.queueLimitUpgradeLevel = 0,
    this.energyCapacityUpgradeLevel = 0,
    this.energyRecoveryUpgradeLevel = 0,
    this.coreUpgradeOptions = const <TowerUpgradeOptionState>[],
  });

  final double coreStability;
  final double coreEnergy;
  final double flowEfficiency;
  final double fireCooldownRemaining;
  final double packetCooldownRemaining;
  final double automationCooldownRemaining;
  final int level;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final List<ProjectileType> projectileLoadout;
  final List<PayloadType> payloadLoadout;
  final int fireSequence;
  final int rangeUpgradeLevel;
  final int fireSpeedUpgradeLevel;
  final int multiShotUpgradeLevel;
  final int queueLimitUpgradeLevel;
  final int energyCapacityUpgradeLevel;
  final int energyRecoveryUpgradeLevel;
  final List<TowerUpgradeOptionState> coreUpgradeOptions;

  CoreState copyWith({
    double? coreStability,
    double? coreEnergy,
    double? flowEfficiency,
    double? fireCooldownRemaining,
    double? packetCooldownRemaining,
    double? automationCooldownRemaining,
    int? level,
    ProjectileType? projectileType,
    PayloadType? payloadType,
    PrototypeAffinity? affinity,
    PrototypeAffinity? secondaryAffinity,
    List<ProjectileType>? projectileLoadout,
    List<PayloadType>? payloadLoadout,
    int? fireSequence,
    int? rangeUpgradeLevel,
    int? fireSpeedUpgradeLevel,
    int? multiShotUpgradeLevel,
    int? queueLimitUpgradeLevel,
    int? energyCapacityUpgradeLevel,
    int? energyRecoveryUpgradeLevel,
    List<TowerUpgradeOptionState>? coreUpgradeOptions,
  }) {
    return CoreState(
      coreStability: coreStability ?? this.coreStability,
      coreEnergy: coreEnergy ?? this.coreEnergy,
      flowEfficiency: flowEfficiency ?? this.flowEfficiency,
      fireCooldownRemaining:
          fireCooldownRemaining ?? this.fireCooldownRemaining,
      packetCooldownRemaining:
          packetCooldownRemaining ?? this.packetCooldownRemaining,
      automationCooldownRemaining:
          automationCooldownRemaining ?? this.automationCooldownRemaining,
      level: level ?? this.level,
      projectileType: projectileType ?? this.projectileType,
      payloadType: payloadType ?? this.payloadType,
      affinity: affinity ?? this.affinity,
      secondaryAffinity: secondaryAffinity ?? this.secondaryAffinity,
      projectileLoadout: projectileLoadout ?? this.projectileLoadout,
      payloadLoadout: payloadLoadout ?? this.payloadLoadout,
      fireSequence: fireSequence ?? this.fireSequence,
      rangeUpgradeLevel: rangeUpgradeLevel ?? this.rangeUpgradeLevel,
      fireSpeedUpgradeLevel:
          fireSpeedUpgradeLevel ?? this.fireSpeedUpgradeLevel,
      multiShotUpgradeLevel:
          multiShotUpgradeLevel ?? this.multiShotUpgradeLevel,
      queueLimitUpgradeLevel:
          queueLimitUpgradeLevel ?? this.queueLimitUpgradeLevel,
      energyCapacityUpgradeLevel:
          energyCapacityUpgradeLevel ?? this.energyCapacityUpgradeLevel,
      energyRecoveryUpgradeLevel:
          energyRecoveryUpgradeLevel ?? this.energyRecoveryUpgradeLevel,
      coreUpgradeOptions: coreUpgradeOptions ?? this.coreUpgradeOptions,
    );
  }
}

class Layer2TowerState {
  const Layer2TowerState({
    required this.unlocked,
    required this.count,
    required this.fireCooldownRemaining,
    this.projectileType = ProjectileType.threadBeam,
    this.payloadType = PayloadType.none,
    this.affinity = PrototypeAffinity.solar,
    this.sourceSummary = 'Awaiting first ascension',
  });

  final bool unlocked;
  final int count;
  final double fireCooldownRemaining;
  final ProjectileType projectileType;
  final PayloadType payloadType;
  final PrototypeAffinity affinity;
  final String sourceSummary;

  Layer2TowerState copyWith({
    bool? unlocked,
    int? count,
    double? fireCooldownRemaining,
    ProjectileType? projectileType,
    PayloadType? payloadType,
    PrototypeAffinity? affinity,
    String? sourceSummary,
  }) {
    return Layer2TowerState(
      unlocked: unlocked ?? this.unlocked,
      count: count ?? this.count,
      fireCooldownRemaining:
          fireCooldownRemaining ?? this.fireCooldownRemaining,
      projectileType: projectileType ?? this.projectileType,
      payloadType: payloadType ?? this.payloadType,
      affinity: affinity ?? this.affinity,
      sourceSummary: sourceSummary ?? this.sourceSummary,
    );
  }
}

class TowerLayerSnapshot {
  TowerLayerSnapshot({
    required this.id,
    required this.tier,
    required this.label,
    required this.slots,
    required this.core,
    required this.layer2,
    required this.enemies,
    required this.pulses,
    required this.shots,
    required this.impacts,
    required this.ammoQueue,
    required this.activeEnemyCardIds,
    required this.enemyTargetCount,
    required this.enemyTargetUpgradeLevel,
    required this.outerRingRevealed,
    required this.swarmActivated,
    required this.elapsed,
    required this.spawnTimer,
    required this.spawnSequence,
    required this.enemyCounter,
    required this.pulseCounter,
    required this.shotCounter,
    required this.impactCounter,
    required this.normalKillsSinceBoss,
    required this.bossReady,
    required this.childTowerUpgrades,
    this.threatAssignmentPresets = const <ThreatAssignmentPresetState>[],
    this.activeBossEnemyCardId,
    this.selectedThreatAssignmentPresetId,
    this.selectedSlotIndex,
    this.selectedEnemyCardId,
    this.parentLayerId,
    this.parentSlotIndex,
    this.sourceLayerId,
    this.promotedParentLayerId,
    this.promotedIntoParentSlot = false,
    this.promotionTraitRoll = 0,
    this.layer3TrialCleared = false,
    this.layer3TrialActive = false,
    this.layer3TrialSpawnIndex = 0,
  });

  final String id;
  int tier;
  String label;
  List<OuterTowerState> slots;
  CoreState core;
  Layer2TowerState layer2;
  List<EnemyState> enemies;
  List<EnergyPulseState> pulses;
  List<CoreShotState> shots;
  List<ImpactState> impacts;
  List<AmmoPacket> ammoQueue;
  List<String> activeEnemyCardIds;
  int enemyTargetCount;
  int enemyTargetUpgradeLevel;
  bool outerRingRevealed;
  bool swarmActivated;
  int? selectedSlotIndex;
  String? selectedEnemyCardId;
  double elapsed;
  double spawnTimer;
  int spawnSequence;
  int enemyCounter;
  int pulseCounter;
  int shotCounter;
  int impactCounter;
  int normalKillsSinceBoss;
  bool bossReady;
  List<ChildTowerUpgradeState> childTowerUpgrades;
  List<ThreatAssignmentPresetState> threatAssignmentPresets;
  String? activeBossEnemyCardId;
  String? selectedThreatAssignmentPresetId;
  String? parentLayerId;
  int? parentSlotIndex;
  String? sourceLayerId;
  String? promotedParentLayerId;
  bool promotedIntoParentSlot;
  int promotionTraitRoll;
  bool layer3TrialCleared;
  bool layer3TrialActive;
  int layer3TrialSpawnIndex;
}
