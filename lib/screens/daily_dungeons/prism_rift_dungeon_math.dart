part of '../daily_dungeons_screen.dart';

double _prismRiftMaxStabilityFor(
  LightcoreDailyDungeonTowerProfile towerProfile,
) {
  return towerProfile.maxHealth * 0.78 + (towerProfile.towerLevel * 140);
}
