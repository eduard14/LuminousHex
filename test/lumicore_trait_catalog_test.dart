import 'package:flutter_test/flutter_test.dart';

import 'package:lightcore/data/lumicore_trait_catalog.dart';
import 'package:lightcore/models/lightcore_types.dart';

void main() {
  test('projectile families match the lumicore source-of-truth table', () {
    expect(
      layer1ProjectileByAffinity,
      equals(<PrototypeAffinity, ProjectileType>{
        PrototypeAffinity.neutral: ProjectileType.starBolt,
        PrototypeAffinity.aether: ProjectileType.threadBeam,
        PrototypeAffinity.flare: ProjectileType.heavyShot,
        PrototypeAffinity.ember: ProjectileType.coreBomb,
        PrototypeAffinity.solar: ProjectileType.chainArc,
        PrototypeAffinity.violet: ProjectileType.pulseRing,
        PrototypeAffinity.verdant: ProjectileType.shieldHalo,
      }),
    );

    expect(
      layer2ProjectileByAffinity,
      equals(<PrototypeAffinity, List<ProjectileType>>{
        PrototypeAffinity.aether: <ProjectileType>[
          ProjectileType.pulseBeam,
          ProjectileType.splitBeam,
        ],
        PrototypeAffinity.flare: <ProjectileType>[
          ProjectileType.breakerShot,
          ProjectileType.crushShot,
        ],
        PrototypeAffinity.ember: <ProjectileType>[
          ProjectileType.pulseBomb,
          ProjectileType.clusterBomb,
        ],
        PrototypeAffinity.solar: <ProjectileType>[
          ProjectileType.forkArc,
          ProjectileType.arcNode,
        ],
        PrototypeAffinity.violet: <ProjectileType>[
          ProjectileType.echoRing,
          ProjectileType.collapseRing,
        ],
        PrototypeAffinity.verdant: <ProjectileType>[
          ProjectileType.sweepNode,
          ProjectileType.slingNode,
        ],
      }),
    );

    expect(
      layer3ProjectileByAffinity,
      equals(<PrototypeAffinity, List<ProjectileType>>{
        PrototypeAffinity.aether: <ProjectileType>[
          ProjectileType.sweepBeam,
          ProjectileType.lanceBeam,
          ProjectileType.prismBeam,
          ProjectileType.sentinelBeam,
        ],
        PrototypeAffinity.flare: <ProjectileType>[
          ProjectileType.siegeShot,
          ProjectileType.drillShot,
          ProjectileType.ricochetShot,
          ProjectileType.hunterShip,
        ],
        PrototypeAffinity.ember: <ProjectileType>[
          ProjectileType.novaBomb,
          ProjectileType.cascadeBomb,
          ProjectileType.fieldBomb,
          ProjectileType.bomberShip,
        ],
        PrototypeAffinity.solar: <ProjectileType>[
          ProjectileType.stormArc,
          ProjectileType.webArc,
          ProjectileType.skyArc,
          ProjectileType.interceptorShip,
        ],
        PrototypeAffinity.violet: <ProjectileType>[
          ProjectileType.haloWave,
          ProjectileType.spiralWave,
          ProjectileType.warpWave,
          ProjectileType.shadeSatellite,
        ],
        PrototypeAffinity.verdant: <ProjectileType>[
          ProjectileType.haloNodes,
          ProjectileType.anchorNode,
          ProjectileType.flailNode,
          ProjectileType.familiarShip,
        ],
      }),
    );
  });

  test('payload families stay empty at layer 1 and match promoted tables', () {
    for (final affinity in <PrototypeAffinity>[
      PrototypeAffinity.neutral,
      PrototypeAffinity.aether,
      PrototypeAffinity.flare,
      PrototypeAffinity.ember,
      PrototypeAffinity.solar,
      PrototypeAffinity.violet,
      PrototypeAffinity.verdant,
    ]) {
      expect(
        forgedPayloadsForAffinity(affinity, targetTier: 1),
        const <PayloadType>[PayloadType.none],
      );
    }

    expect(
      layer2PayloadByAffinity,
      equals(<PrototypeAffinity, List<PayloadType>>{
        PrototypeAffinity.aether: <PayloadType>[
          PayloadType.chill,
          PayloadType.fracture,
        ],
        PrototypeAffinity.flare: <PayloadType>[
          PayloadType.rend,
          PayloadType.force,
        ],
        PrototypeAffinity.ember: <PayloadType>[
          PayloadType.overheat,
          PayloadType.detonate,
        ],
        PrototypeAffinity.solar: <PayloadType>[
          PayloadType.shock,
          PayloadType.disrupt,
        ],
        PrototypeAffinity.violet: <PayloadType>[
          PayloadType.expose,
          PayloadType.pull,
        ],
        PrototypeAffinity.verdant: <PayloadType>[
          PayloadType.corrupt,
          PayloadType.spread,
        ],
      }),
    );

    expect(
      layer3PayloadByAffinity,
      equals(<PrototypeAffinity, List<PayloadType>>{
        PrototypeAffinity.aether: <PayloadType>[
          PayloadType.deepChill,
          PayloadType.brittleFracture,
        ],
        PrototypeAffinity.flare: <PayloadType>[
          PayloadType.coreRend,
          PayloadType.concussiveForce,
        ],
        PrototypeAffinity.ember: <PayloadType>[
          PayloadType.meltdown,
          PayloadType.chainDetonate,
        ],
        PrototypeAffinity.solar: <PayloadType>[
          PayloadType.overload,
          PayloadType.empDisrupt,
        ],
        PrototypeAffinity.violet: <PayloadType>[
          PayloadType.collapse,
          PayloadType.singularityPull,
        ],
        PrototypeAffinity.verdant: <PayloadType>[
          PayloadType.cascadeCorrupt,
          PayloadType.viralSpread,
        ],
      }),
    );
  });
}
