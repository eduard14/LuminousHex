import 'lightcore_config.dart';
import 'lightcore_types.dart';

const Map<PrototypeAffinity, Map<EnemyCardRarity, String>>
normalEnemyImageAssets = {
  PrototypeAffinity.neutral: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/neutral/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/neutral/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/neutral/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/neutral/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/neutral/legendary.jpeg',
  },
  PrototypeAffinity.ember: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/red/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/red/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/red/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/red/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/red/legendary.jpeg',
  },
  PrototypeAffinity.flare: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/orange/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/orange/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/orange/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/orange/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/orange/legendary.jpeg',
  },
  PrototypeAffinity.solar: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/yellow/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/yellow/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/yellow/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/yellow/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/yellow/legendary.jpeg',
  },
  PrototypeAffinity.verdant: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/green/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/green/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/green/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/green/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/green/legendary.jpeg',
  },
  PrototypeAffinity.aether: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/blue/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/blue/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/blue/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/blue/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/blue/legendary.jpeg',
  },
  PrototypeAffinity.violet: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/purple/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/purple/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/purple/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/purple/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/purple/legendary.jpeg',
  },
  PrototypeAffinity.black: {
    EnemyCardRarity.basic: 'assets/sprites/enemies/black/basic.jpeg',
    EnemyCardRarity.uncommon: 'assets/sprites/enemies/black/uncommon.jpeg',
    EnemyCardRarity.rare: 'assets/sprites/enemies/black/rare.jpeg',
    EnemyCardRarity.epic: 'assets/sprites/enemies/black/epic.jpeg',
    EnemyCardRarity.legendary: 'assets/sprites/enemies/black/legendary.jpeg',
  },
};

const Map<String, String> bossEnemyImageAssetOverrides = {
  'boss_basic_white_warden':
      'assets/sprites/bosses/basic/the_pale_equation.jpeg',
  'boss_basic_ember_colossus': 'assets/sprites/bosses/basic/huskstar_rex.jpeg',
  'boss_basic_verdant_devourer':
      'assets/sprites/bosses/basic/mother_moss_nova.jpeg',
};

String? enemyImageAssetForConfig(EnemyConfig config) {
  if (config.encounterType == EnemyEncounterType.boss) {
    return bossEnemyImageAssetOverrides[config.id] ??
        _generatedBossImageAsset(config);
  }

  return normalEnemyImageAssets[config.affinity]?[config.rarity];
}

String _generatedBossImageAsset(EnemyConfig config) {
  final rarity = config.rarity.name;
  final prefix = 'boss_${rarity}_';
  final stem = config.id.startsWith(prefix)
      ? config.id.substring(prefix.length)
      : config.id.replaceFirst('boss_', '');
  return 'assets/sprites/bosses/$rarity/$stem.jpeg';
}
