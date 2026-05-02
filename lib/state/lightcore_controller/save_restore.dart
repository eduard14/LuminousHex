part of '../lightcore_controller.dart';

extension LightcoreControllerSaveRestore on LightcoreController {
  void _forceTournamentEnemyCard(EnemyCardState source) {
    final index = _enemyCards.indexWhere(
      (card) => card.config.id == source.config.id,
    );
    if (index == -1) {
      return;
    }
    _enemyCards[index] = _enemyCards[index].copyWith(
      unlocked: true,
      copies: max(1, source.copies),
      level: max(1, source.level),
    );
  }

  void _forceTournamentBossCard(EnemyCardState source) {
    final index = _bossEnemyCards.indexWhere(
      (card) => card.config.id == source.config.id,
    );
    if (index == -1) {
      return;
    }
    _bossEnemyCards[index] = _bossEnemyCards[index].copyWith(
      unlocked: true,
      copies: max(1, source.copies),
      level: max(1, source.level),
    );
  }

  Map<String, dynamic> _buildSocialPerformanceSnapshot() {
    return <String, dynamic>{
      'playerId': _playerId,
      'screenName': _screenName,
      'displayName': playerDisplayName,
      'overallLevel': overallLevel,
      'progressionExperience': progressionExperience,
      'progressToNextLevel': overallLevelProgress,
      'builtTowerCount': builtTowerCount,
      'coreLevel': _core.level,
      'towerStrength': globalRankingTowerStrength,
      'radianceStats': _serializeRadianceStats(),
      'unspentRadianceStatPoints': unspentRadianceStatPoints,
      'avatar': publicAvatarProfile.toMap(),
      'sharedRelayFilledPieceCount': sharedRelayFilledPieceCount,
      'sharedRelayAveragePower': sharedRelayTower.averagePowerScore,
      'bossesDefeated': _totalBossesDefeated,
      'bossPullCount': bossPullCount,
      'totalPullsOpened': totalPullsOpened,
      'totalBattleSeconds': _totalBattleSeconds,
      'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
