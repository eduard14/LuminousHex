import 'package:flutter/material.dart';

import '../models/lightcore_avatar.dart';
import '../models/lightcore_guide.dart';
import 'cosmic_guide_avatar.dart';

class LightcoreGuideBadge extends StatelessWidget {
  const LightcoreGuideBadge({
    super.key,
    required this.guide,
    this.size = 48,
    this.equipmentLoadout = CosmicEquipmentLoadout.empty,
    this.avatarCosmetics = AvatarCosmeticLoadout.empty,
    this.phase = 0,
    this.boosting = false,
    this.pose = LightcoreAvatarPose.idle,
  });

  final LightcoreGuideProfile guide;
  final double size;
  final CosmicEquipmentLoadout equipmentLoadout;
  final AvatarCosmeticLoadout avatarCosmetics;
  final double phase;
  final bool boosting;
  final LightcoreAvatarPose pose;

  @override
  Widget build(BuildContext context) {
    return CosmicGuideAvatar(
      guide: guide,
      size: size,
      loadout: equipmentLoadout,
      avatarCosmetics: avatarCosmetics,
      phase: phase,
      boosting: boosting,
      pose: pose,
      semanticLabel: guide.displayName,
    );
  }
}
