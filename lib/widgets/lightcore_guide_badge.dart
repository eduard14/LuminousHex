import 'package:flutter/material.dart';

import '../models/lightcore_guide.dart';
import 'cosmic_guide_avatar.dart';

class LightcoreGuideBadge extends StatelessWidget {
  const LightcoreGuideBadge({
    super.key,
    required this.guide,
    this.size = 48,
    this.equipmentLoadout = CosmicEquipmentLoadout.empty,
    this.phase = 0,
    this.boosting = false,
  });

  final LightcoreGuideProfile guide;
  final double size;
  final CosmicEquipmentLoadout equipmentLoadout;
  final double phase;
  final bool boosting;

  @override
  Widget build(BuildContext context) {
    return CosmicGuideAvatar(
      guide: guide,
      size: size,
      loadout: equipmentLoadout,
      phase: phase,
      boosting: boosting,
      semanticLabel: guide.displayName,
    );
  }
}
