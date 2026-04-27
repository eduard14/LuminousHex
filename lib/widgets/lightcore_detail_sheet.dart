import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

class LightcoreDetailSheet extends StatelessWidget {
  const LightcoreDetailSheet({
    super.key,
    required this.child,
    this.tint = LightcorePalette.aether,
    this.maxHeightFactor = 0.84,
  });

  final Widget child;
  final Color tint;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: media.size.height * maxHeightFactor,
          ),
          child: AuroraPanel(
            tint: tint,
            radius: 28,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}
