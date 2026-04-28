part of '../daily_dungeons_screen.dart';

double _dungeonRaidTotalDamage(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  return controller.dailyDungeonRaidTotalDamage(card, apex: apex);
}

double _dungeonRaidDamagePerSecond(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  return controller.dailyDungeonRaidDamagePerSecond(card, apex: apex);
}

double _dungeonRaidMaxHealth(
  LightcoreController controller,
  EnemyCardState card,
  LightcoreDailyDungeonTowerProfile towerProfile, {
  bool apex = false,
}) {
  return controller.dailyDungeonRaidMaxHealth(card, towerProfile, apex: apex);
}

double _dungeonRaidLifetime(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  return controller.dailyDungeonRaidLifetime(card, apex: apex);
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
