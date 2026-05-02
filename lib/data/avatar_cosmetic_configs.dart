import '../models/lightcore_avatar.dart';
import '../models/lightcore_types.dart';

class AvatarCosmeticCatalog {
  const AvatarCosmeticCatalog._();

  static const List<AvatarCosmeticConfig> all = <AvatarCosmeticConfig>[
    AvatarCosmeticConfig(
      id: 'comet_cowlick',
      type: AvatarCosmeticType.hair,
      name: 'Comet Cowlick',
      summary: 'A bright cyan tuft tuned for small profile icons.',
      assetPath: 'assets/sprites/avatar/hair/comet_cowlick.png',
      pricePrismShards: 120,
      rarity: ManagerRarity.common,
    ),
    AvatarCosmeticConfig(
      id: 'nebula_sweep',
      type: AvatarCosmeticType.hair,
      name: 'Nebula Sweep',
      summary: 'Purple side-swept bangs with a soft star glow.',
      assetPath: 'assets/sprites/avatar/hair/nebula_sweep.png',
      pricePrismShards: 220,
      rarity: ManagerRarity.rare,
    ),
    AvatarCosmeticConfig(
      id: 'solar_tufts',
      type: AvatarCosmeticType.hair,
      name: 'Solar Tufts',
      summary: 'Gold twin tufts for a louder premium silhouette.',
      assetPath: 'assets/sprites/avatar/hair/solar_tufts.png',
      pricePrismShards: 320,
      rarity: ManagerRarity.epic,
    ),
    AvatarCosmeticConfig(
      id: 'joyful_arc',
      type: AvatarCosmeticType.face,
      name: 'Joyful Arc',
      summary: 'Smiling crescent eyes for friendly room chat.',
      assetPath: 'assets/sprites/avatar/face/joyful_arc.png',
      pricePrismShards: 90,
      rarity: ManagerRarity.common,
    ),
    AvatarCosmeticConfig(
      id: 'focused_glow',
      type: AvatarCosmeticType.face,
      name: 'Focused Glow',
      summary: 'Steady bright eyes for a locked-in manager look.',
      assetPath: 'assets/sprites/avatar/face/focused_glow.png',
      pricePrismShards: 160,
      rarity: ManagerRarity.rare,
    ),
    AvatarCosmeticConfig(
      id: 'spark_wink',
      type: AvatarCosmeticType.face,
      name: 'Spark Wink',
      summary: 'One eye, one spark, and a brighter profile read.',
      assetPath: 'assets/sprites/avatar/face/spark_wink.png',
      pricePrismShards: 240,
      rarity: ManagerRarity.epic,
    ),
  ];

  static final Map<String, AvatarCosmeticConfig> byId =
      <String, AvatarCosmeticConfig>{
        for (final config in all) config.id: config,
      };

  static List<AvatarCosmeticConfig> byType(AvatarCosmeticType type) {
    return all.where((config) => config.type == type).toList(growable: false);
  }
}
