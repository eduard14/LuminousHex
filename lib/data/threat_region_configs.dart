import '../models/lightcore_config.dart';
import '../models/lightcore_types.dart';
import 'enemy_configs.dart';

class ThreatRegionLibrary {
  ThreatRegionLibrary._();

  static final List<ThreatRegionConfig> all = _buildRegions();

  static final Map<String, ThreatRegionConfig> byId = {
    for (final region in all) region.id: region,
  };

  static final List<BossTraitConfig> bossTraits = BossEnemyLibrary.all
      .map(
        (boss) => BossTraitConfig(
          id: 'trait_${boss.id}',
          name: '${boss.traitLabel} Trait',
          summary: 'Portable boss trait recovered from ${boss.name}.',
          sourceBossId: boss.id,
          affinity: boss.affinity,
          rarity: boss.rarity,
          effectLabel: boss.traitLabel,
        ),
      )
      .toList(growable: false);

  static final Map<String, BossTraitConfig> bossTraitsById = {
    for (final trait in bossTraits) trait.id: trait,
  };

  static BossTraitConfig? traitForBoss(String bossId) {
    final traitId = 'trait_$bossId';
    return bossTraitsById[traitId];
  }

  static int stabilizationLayersForRing(int ring) {
    return switch (ring) {
      0 => 3,
      1 => 5,
      2 => 8,
      _ => 13,
    };
  }

  static int hexDistance(int q, int r) {
    return ((q.abs() + r.abs() + (q + r).abs()) / 2).round();
  }

  static List<({int q, int r})> axialRing(int ring) {
    if (ring == 0) {
      return const <({int q, int r})>[(q: 0, r: 0)];
    }
    const directions = <({int q, int r})>[
      (q: 1, r: 0),
      (q: 0, r: 1),
      (q: -1, r: 1),
      (q: -1, r: 0),
      (q: 0, r: -1),
      (q: 1, r: -1),
    ];
    var q = 0;
    var r = -ring;
    final cells = <({int q, int r})>[];
    for (final direction in directions) {
      for (var step = 0; step < ring; step += 1) {
        cells.add((q: q, r: r));
        q += direction.q;
        r += direction.r;
      }
    }
    return List<({int q, int r})>.unmodifiable(cells);
  }

  static List<ThreatRegionConfig> _buildRegions() {
    final coords = _spiralCoords(maxRing: 3);
    final bosses = _orderedBosses();
    final regions = <ThreatRegionConfig>[];
    for (var index = 0; index < coords.length; index += 1) {
      final coord = coords[index];
      final ringIndex = coord.ring == 0
          ? 0
          : index - coords.indexWhere((item) => item.ring == coord.ring);
      final rarity = _rarityForRing(coord.ring, ringIndex);
      final primaryBoss = bosses[index % bosses.length];
      final doubleBoss = coord.ring == 3 && ringIndex >= 15;
      final secondaryBoss = doubleBoss
          ? bosses[(index + 7) % bosses.length]
          : null;
      regions.add(
        ThreatRegionConfig(
          id: 'region_r${coord.ring}_${coord.q}_${coord.r}',
          name: _regionName(coord.ring, ringIndex),
          q: coord.q,
          r: coord.r,
          ring: coord.ring,
          stabilizationLayers: stabilizationLayersForRing(coord.ring),
          rarity: rarity,
          anomalyCardIds: _anomalyIdsFor(coord.ring, ringIndex),
          primaryBossId: primaryBoss.id,
          secondaryBossId: secondaryBoss?.id,
          inventoryEffect: _inventoryEffectFor(coord.ring, rarity, ringIndex),
        ),
      );
    }
    return List<ThreatRegionConfig>.unmodifiable(regions);
  }

  static List<({int q, int r, int ring})> _spiralCoords({
    required int maxRing,
  }) {
    final coords = <({int q, int r, int ring})>[(q: 0, r: 0, ring: 0)];
    var previous = (q: 0, r: 0);
    for (var ring = 1; ring <= maxRing; ring += 1) {
      final ringCoords = axialRing(ring);
      var startIndex = 0;
      var bestDistance = 999;
      for (var index = 0; index < ringCoords.length; index += 1) {
        final coord = ringCoords[index];
        final distance = hexDistance(
          coord.q - previous.q,
          coord.r - previous.r,
        );
        if (distance < bestDistance) {
          bestDistance = distance;
          startIndex = index;
        }
      }
      for (var offset = 0; offset < ringCoords.length; offset += 1) {
        final coord = ringCoords[(startIndex + offset) % ringCoords.length];
        coords.add((q: coord.q, r: coord.r, ring: ring));
        previous = coord;
      }
    }
    return List<({int q, int r, int ring})>.unmodifiable(coords);
  }

  static List<EnemyConfig> _orderedBosses() {
    final byRarity = <EnemyConfig>[
      ...BossEnemyLibrary.byRarity[EnemyCardRarity.basic]!,
      ...BossEnemyLibrary.byRarity[EnemyCardRarity.uncommon]!,
      ...BossEnemyLibrary.byRarity[EnemyCardRarity.rare]!,
      ...BossEnemyLibrary.byRarity[EnemyCardRarity.epic]!,
      ...BossEnemyLibrary.byRarity[EnemyCardRarity.legendary]!,
    ];
    return List<EnemyConfig>.unmodifiable(byRarity);
  }

  static String _regionName(int ring, int index) {
    if (ring == 0) {
      return 'First Stabilizer';
    }
    return 'Ring $ring Hex ${index + 1}';
  }

  static EnemyCardRarity _rarityForRing(int ring, int index) {
    return switch (ring) {
      0 => EnemyCardRarity.basic,
      1 => index < 3 ? EnemyCardRarity.basic : EnemyCardRarity.uncommon,
      2 =>
        index < 4
            ? EnemyCardRarity.uncommon
            : index < 10
            ? EnemyCardRarity.rare
            : EnemyCardRarity.epic,
      _ =>
        index < 7
            ? EnemyCardRarity.rare
            : index < 14
            ? EnemyCardRarity.epic
            : EnemyCardRarity.legendary,
    };
  }

  static List<String> _anomalyIdsFor(int ring, int index) {
    final rarityPattern = switch (ring) {
      0 => const <EnemyCardRarity>[
        EnemyCardRarity.basic,
        EnemyCardRarity.basic,
        EnemyCardRarity.basic,
      ],
      1 => const <EnemyCardRarity>[
        EnemyCardRarity.basic,
        EnemyCardRarity.basic,
        EnemyCardRarity.uncommon,
      ],
      2 => const <EnemyCardRarity>[
        EnemyCardRarity.uncommon,
        EnemyCardRarity.rare,
        EnemyCardRarity.rare,
      ],
      _ => const <EnemyCardRarity>[
        EnemyCardRarity.rare,
        EnemyCardRarity.epic,
        EnemyCardRarity.legendary,
      ],
    };
    return List<String>.unmodifiable([
      for (var slot = 0; slot < 3; slot += 1)
        _enemyFor(rarityPattern[slot], index + slot + (ring * 3)).id,
    ]);
  }

  static EnemyConfig _enemyFor(EnemyCardRarity rarity, int seed) {
    final pool = EnemyLibrary.byRarity[rarity]!;
    return pool[seed % pool.length];
  }

  static TowerPatternBonusProfile _inventoryEffectFor(
    int ring,
    EnemyCardRarity rarity,
    int index,
  ) {
    final scale = 0.0015 + (ring * 0.0012) + (rarity.index * 0.0008);
    return switch (index % 5) {
      0 => TowerPatternBonusProfile(power: scale),
      1 => TowerPatternBonusProfile(chargeRate: scale),
      2 => TowerPatternBonusProfile(normalDamage: scale),
      3 => TowerPatternBonusProfile(bossDamage: scale),
      _ => TowerPatternBonusProfile(defensePenetration: scale),
    };
  }
}
