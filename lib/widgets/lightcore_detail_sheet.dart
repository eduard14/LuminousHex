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
    final compactHeight = media.size.height < 760;
    final usableHeight =
        (media.size.height - media.viewInsets.vertical - media.padding.vertical)
            .clamp(320.0, media.size.height)
            .toDouble();
    final sheetHeightFactor = compactHeight
        ? maxHeightFactor.clamp(0.0, 0.76)
        : maxHeightFactor;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          compactHeight ? 8 : 12,
          14,
          (compactHeight ? 12 : 16) + media.viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: usableHeight * sheetHeightFactor,
          ),
          child: AuroraPanel(
            tint: tint,
            radius: compactHeight ? 24 : 28,
            padding: EdgeInsets.all(compactHeight ? 16 : 20),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}
