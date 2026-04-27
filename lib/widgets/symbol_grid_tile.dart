import 'package:flutter/material.dart';

import '../models/lightcore_types.dart';
import '../theme/lightcore_palette.dart';

const double kSymbolGridTileSize = 106;

class SymbolGridTile extends StatelessWidget {
  const SymbolGridTile({
    super.key,
    required this.tint,
    required this.semanticLabel,
    required this.center,
    this.dimension = kSymbolGridTileSize,
    this.onTap,
    this.topLeading,
    this.topTrailing,
    this.bottomChildren = const <Widget>[],
    this.selected = false,
    this.locked = false,
  });

  final Color tint;
  final String semanticLabel;
  final Widget center;
  final double dimension;
  final VoidCallback? onTap;
  final Widget? topLeading;
  final Widget? topTrailing;
  final List<Widget> bottomChildren;
  final bool selected;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final borderColor = selected
        ? LightcorePalette.layer2
        : tint.withValues(alpha: locked ? 0.24 : 0.42);

    return SizedBox.square(
      dimension: dimension,
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: borderColor,
                  width: selected ? 2.2 : 1.1,
                ),
                gradient: LinearGradient(
                  colors: [
                    tint.withValues(
                      alpha: selected
                          ? 0.22
                          : locked
                          ? 0.04
                          : 0.14,
                    ),
                    LightcorePalette.panelRaised.withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (selected ? LightcorePalette.layer2 : tint)
                        .withValues(alpha: selected ? 0.16 : 0.12),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...?(topLeading == null ? null : [topLeading!]),
                        const Spacer(),
                        ...?(topTrailing == null ? null : [topTrailing!]),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: Center(
                        child: Opacity(
                          opacity: locked ? 0.38 : 1,
                          child: center,
                        ),
                      ),
                    ),
                    if (bottomChildren.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < bottomChildren.length;
                                index++
                              ) ...[
                                if (index > 0) const SizedBox(width: 6),
                                bottomChildren[index],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SymbolGridBadge extends StatelessWidget {
  const SymbolGridBadge({
    super.key,
    required this.child,
    required this.tint,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.size,
  });

  final Widget child;
  final Color tint;
  final EdgeInsetsGeometry padding;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: size == null ? padding : null,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(10)),
        color: tint.withValues(alpha: 0.16),
        border: Border.all(color: tint.withValues(alpha: 0.42)),
      ),
      child: IconTheme(
        data: IconThemeData(color: tint, size: 12),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: tint,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SymbolGridPips extends StatelessWidget {
  const SymbolGridPips({
    super.key,
    required this.count,
    required this.tint,
    this.max = 5,
  });

  final int count;
  final int max;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var index = 0; index < max; index += 1)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < count
                  ? tint.withValues(alpha: 0.96)
                  : tint.withValues(alpha: 0.18),
            ),
          ),
      ],
    );
  }
}

class AffinityGlyph extends StatelessWidget {
  const AffinityGlyph({super.key, required this.affinity, this.size = 28});

  final PrototypeAffinity affinity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(_affinityIcon(affinity), color: affinity.color, size: size);
  }
}

IconData _affinityIcon(PrototypeAffinity affinity) => switch (affinity) {
  PrototypeAffinity.neutral => Icons.circle_rounded,
  PrototypeAffinity.ember => Icons.diamond_rounded,
  PrototypeAffinity.flare => Icons.square_rounded,
  PrototypeAffinity.solar => Icons.change_history_rounded,
  PrototypeAffinity.verdant => Icons.hexagon_rounded,
  PrototypeAffinity.aether => Icons.blur_on_rounded,
  PrototypeAffinity.violet => Icons.auto_awesome_rounded,
  PrototypeAffinity.black => Icons.lens_blur_rounded,
};
