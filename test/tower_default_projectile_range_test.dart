import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/tower_configs.dart';
import 'package:lightcore/models/lightcore_state.dart';
import 'package:lightcore/models/lightcore_types.dart';
import 'package:lightcore/state/lightcore_controller.dart';

void main() {
  test(
    'default projectile range follows a tower trait override instead of the library default',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      const tower = OuterTowerState(
        slotIndex: 0,
        config: TowerLibrary.redPrism,
        projectileType: ProjectileType.pulseBeam,
        payloadType: PayloadType.none,
      );

      expect(controller.towerDefaultProjectileLabel(tower), 'Pulse Beam');
      expect(
        controller.towerRangeLabel(tower),
        controller
            .towerEffectiveRangeForProjectile(tower, ProjectileType.pulseBeam)
            .toStringAsFixed(0),
      );
      expect(
        controller.towerDefaultProjectileRangeLabel(tower),
        controller
            .towerEffectiveRangeForProjectile(tower, ProjectileType.pulseBeam)
            .toStringAsFixed(0),
      );
    },
  );

  test(
    'default projectile range stays anchored to the base promoted projectile',
    () {
      final controller = LightcoreController();
      addTearDown(controller.dispose);

      const tower = OuterTowerState(
        slotIndex: 0,
        fireSequence: 1,
        childLayerId: 'child-shell',
        childProjectileType: ProjectileType.threadBeam,
        childProjectileLoadout: <ProjectileType>[
          ProjectileType.threadBeam,
          ProjectileType.pulseBeam,
        ],
        childPayloadType: PayloadType.none,
        childPayloadLoadout: <PayloadType>[PayloadType.none],
        childRange: 300,
        childCoreLevel: 1,
        childPromoted: true,
      );

      expect(controller.towerProjectileLabel(tower), 'Pulse Beam');
      expect(
        controller.towerRangeLabel(tower),
        controller
            .towerEffectiveRangeForProjectile(tower, ProjectileType.pulseBeam)
            .toStringAsFixed(0),
      );
      expect(controller.towerDefaultProjectileLabel(tower), 'Thread Beam');
      expect(
        controller.towerDefaultProjectileRangeLabel(tower),
        controller
            .towerEffectiveRangeForProjectile(tower, ProjectileType.threadBeam)
            .toStringAsFixed(0),
      );
    },
  );
}
