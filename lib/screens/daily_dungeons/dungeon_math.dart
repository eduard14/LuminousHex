part of '../daily_dungeons_screen.dart';

double _dungeonRaidTotalDamage(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  return _dungeonRaidDamagePerSecond(controller, card, apex: apex) *
      _dungeonRaidLifetime(card, apex: apex);
}

double _dungeonRaidDamagePerSecond(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  final config = card.config;
  final manager = apex ? null : controller.enemyManagerForCard(config.id);
  final levelMultiplier = 1 + ((card.level - 1) * (apex ? 0.075 : 0.055));
  final rarityMultiplier = 1 + (config.rarity.index * (apex ? 0.28 : 0.18));
  final splitBonus = config.splitsOnDeath ? 1.12 : 1.0;
  final managerMultiplier = manager == null
      ? 1.0
      : ((manager.spawnRateMultiplier +
                    manager.healthMultiplier +
                    manager.speedMultiplier +
                    manager.experienceMultiplier) /
                4)
            .clamp(0.82, 1.42)
            .toDouble();
  final bodyPressure =
      16 +
      (config.baseHealth * (apex ? 0.12 : 0.3)) +
      (config.baseDefense * (apex ? 0.34 : 0.2)) +
      (config.baseSpeed * (apex ? 1.35 : 0.9)) +
      (config.jamStrength * (apex ? 44 : 28));
  return bodyPressure *
      levelMultiplier *
      rarityMultiplier *
      splitBonus *
      managerMultiplier *
      (apex ? 0.72 : 1.0);
}

double _dungeonRaidMaxHealth(
  LightcoreController controller,
  EnemyCardState card,
  LightcoreDailyDungeonTowerProfile towerProfile, {
  bool apex = false,
}) {
  final config = card.config;
  final manager = apex ? null : controller.enemyManagerForCard(config.id);
  final managerMultiplier = manager == null
      ? 1.0
      : ((manager.healthMultiplier + manager.speedMultiplier) / 2)
            .clamp(0.86, 1.36)
            .toDouble();
  final levelMultiplier = 1 + ((card.level - 1) * (apex ? 0.1 : 0.075));
  final rarityMultiplier = 1 + (config.rarity.index * (apex ? 0.42 : 0.24));
  final towerPressure =
      1 + ((towerProfile.towerLevel - 1) * 0.018).clamp(0.0, 0.75);
  final body =
      58 +
      (config.baseHealth * (apex ? 7.5 : 4.2)) +
      (config.baseDefense * (apex ? 3.8 : 2.4)) +
      (config.baseSpeed * (apex ? 1.9 : 1.1)) +
      (config.jamStrength * (apex ? 72 : 38));
  return body *
      levelMultiplier *
      rarityMultiplier *
      managerMultiplier *
      towerPressure *
      (apex ? 1.85 : 1.0);
}

double _dungeonRaidLifetime(EnemyCardState card, {bool apex = false}) {
  final speedFactor = (card.config.baseSpeed / 28).clamp(0.62, 1.18).toDouble();
  final rarityBonus = card.config.rarity.index * (apex ? 0.24 : 0.16);
  return (apex ? 6.4 : 4.9) + speedFactor + rarityBonus;
}

double _dungeonDeployCooldown(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  if (apex) {
    final rarityPenalty = card.config.rarity.index * 0.65;
    return (8.8 + rarityPenalty).clamp(7.2, 12.0).toDouble();
  }
  final manager = controller.enemyManagerForCard(card.config.id);
  final speedRelief = (card.config.baseSpeed / 70).clamp(0.0, 0.42).toDouble();
  final managerRelief = manager == null
      ? 0.0
      : ((manager.spawnRateMultiplier - 1) * 1.4).clamp(-0.25, 0.45).toDouble();
  return (3.35 - speedRelief - managerRelief).clamp(1.6, 3.8).toDouble();
}

String _dungeonLaunchKey(EnemyCardState card, {required bool apex}) {
  return '${apex ? 'apex' : 'anomaly'}:${card.config.id}';
}
