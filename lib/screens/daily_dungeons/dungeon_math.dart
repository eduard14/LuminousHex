part of '../daily_dungeons_screen.dart';

double _dungeonRaidTotalDamage(
  LightcoreController controller,
  EnemyCardState card, {
  bool apex = false,
}) {
  return controller.dailyDungeonRaidTotalDamage(card, apex: apex);
}
