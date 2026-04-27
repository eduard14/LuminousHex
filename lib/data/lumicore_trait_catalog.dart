import '../models/lightcore_types.dart';

const Map<PrototypeAffinity, ProjectileType> layer1ProjectileByAffinity =
    <PrototypeAffinity, ProjectileType>{
      PrototypeAffinity.neutral: ProjectileType.starBolt,
      PrototypeAffinity.aether: ProjectileType.threadBeam,
      PrototypeAffinity.flare: ProjectileType.heavyShot,
      PrototypeAffinity.ember: ProjectileType.coreBomb,
      PrototypeAffinity.solar: ProjectileType.chainArc,
      PrototypeAffinity.violet: ProjectileType.pulseRing,
      PrototypeAffinity.verdant: ProjectileType.shieldHalo,
    };

const Map<PrototypeAffinity, List<ProjectileType>> layer2ProjectileByAffinity =
    <PrototypeAffinity, List<ProjectileType>>{
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
    };

const Map<PrototypeAffinity, List<ProjectileType>> layer3ProjectileByAffinity =
    <PrototypeAffinity, List<ProjectileType>>{
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
    };

const Map<PrototypeAffinity, List<PayloadType>>
layer2PayloadByAffinity = <PrototypeAffinity, List<PayloadType>>{
  PrototypeAffinity.aether: <PayloadType>[
    PayloadType.chill,
    PayloadType.fracture,
  ],
  PrototypeAffinity.flare: <PayloadType>[PayloadType.rend, PayloadType.force],
  PrototypeAffinity.ember: <PayloadType>[
    PayloadType.overheat,
    PayloadType.detonate,
  ],
  PrototypeAffinity.solar: <PayloadType>[
    PayloadType.shock,
    PayloadType.disrupt,
  ],
  PrototypeAffinity.violet: <PayloadType>[PayloadType.expose, PayloadType.pull],
  PrototypeAffinity.verdant: <PayloadType>[
    PayloadType.corrupt,
    PayloadType.spread,
  ],
};

const Map<PrototypeAffinity, List<PayloadType>> layer3PayloadByAffinity =
    <PrototypeAffinity, List<PayloadType>>{
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
    };

ProjectileType layer1ProjectileForAffinity(PrototypeAffinity affinity) =>
    layer1ProjectileByAffinity[affinity] ?? ProjectileType.threadBeam;

List<ProjectileType> forgedProjectilesForAffinity(
  PrototypeAffinity affinity, {
  required int targetTier,
}) {
  if (targetTier <= 1) {
    return <ProjectileType>[layer1ProjectileForAffinity(affinity)];
  }
  if (targetTier == 2) {
    return layer2ProjectileByAffinity[affinity] ??
        <ProjectileType>[layer1ProjectileForAffinity(affinity)];
  }
  return layer3ProjectileByAffinity[affinity] ??
      layer2ProjectileByAffinity[affinity] ??
      <ProjectileType>[layer1ProjectileForAffinity(affinity)];
}

List<PayloadType> forgedPayloadsForAffinity(
  PrototypeAffinity affinity, {
  required int targetTier,
}) {
  if (targetTier <= 1) {
    return const <PayloadType>[PayloadType.none];
  }
  if (targetTier == 2) {
    return layer2PayloadByAffinity[affinity] ??
        const <PayloadType>[PayloadType.none];
  }
  return layer3PayloadByAffinity[affinity] ??
      layer2PayloadByAffinity[affinity] ??
      const <PayloadType>[PayloadType.none];
}
