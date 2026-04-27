part of '../lightcore_battle_game.dart';

class _ShotFireBurst {
  const _ShotFireBurst({
    required this.id,
    required this.layer2,
    required this.affinity,
    required this.secondaryAffinity,
    required this.projectileType,
    required this.aimAngle,
    this.elapsed = 0,
  });

  factory _ShotFireBurst.fromShot(CoreShotState shot) {
    return _ShotFireBurst(
      id: shot.id,
      layer2: shot.layer2,
      affinity: shot.affinity,
      secondaryAffinity: shot.secondaryAffinity,
      projectileType: shot.projectileType,
      aimAngle: shot.aimAngle,
    );
  }

  final String id;
  final bool layer2;
  final PrototypeAffinity affinity;
  final PrototypeAffinity? secondaryAffinity;
  final ProjectileType projectileType;
  final double aimAngle;
  final double elapsed;

  _ShotFireBurst copyWith({double? elapsed}) {
    return _ShotFireBurst(
      id: id,
      layer2: layer2,
      affinity: affinity,
      secondaryAffinity: secondaryAffinity,
      projectileType: projectileType,
      aimAngle: aimAngle,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

enum _ShotFireBurstStyle {
  spark,
  needle,
  heavy,
  pulse,
  cluster,
  arc,
  split,
  lance,
  blast,
  wave,
  nova,
  node,
}

class _ShotFireBurstSpec {
  const _ShotFireBurstSpec({
    required this.style,
    this.scale = 1,
    this.sparkCount = 3,
    this.ringCount = 1,
    this.spread = 0.36,
  });

  final _ShotFireBurstStyle style;
  final double scale;
  final int sparkCount;
  final int ringCount;
  final double spread;
}
