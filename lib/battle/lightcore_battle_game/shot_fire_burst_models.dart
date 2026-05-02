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
