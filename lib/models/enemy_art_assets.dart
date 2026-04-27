import 'lightcore_config.dart';
import 'lightcore_types.dart';

const Map<EnemyCardRarity, String> redEnemyImageAssets = {
  EnemyCardRarity.basic: 'assets/Images/EnemyRed1.png',
  EnemyCardRarity.uncommon: 'assets/Images/EnemyRed2.png',
  EnemyCardRarity.rare: 'assets/Images/EnemyRed3.png',
  EnemyCardRarity.epic: 'assets/Images/EnemyRed4.png',
  EnemyCardRarity.legendary: 'assets/Images/EnemyRed5.png',
};

String? enemyImageAssetForConfig(EnemyConfig config) {
  if (config.encounterType != EnemyEncounterType.normal ||
      config.affinity != PrototypeAffinity.ember) {
    return null;
  }

  return redEnemyImageAssets[config.rarity];
}
