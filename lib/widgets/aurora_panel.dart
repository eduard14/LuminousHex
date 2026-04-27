import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

class AuroraPanel extends StatefulWidget {
  const AuroraPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.tint = LightcorePalette.aether,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color tint;
  final VoidCallback? onTap;

  @override
  State<AuroraPanel> createState() => _AuroraPanelState();
}

class _AuroraPanelState extends State<AuroraPanel> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final highlightStrength = interactive
        ? (_pressed ? 1.0 : (_hovered ? 0.5 : 0.0))
        : 0.0;
    final radius = BorderRadius.circular(widget.radius);
    final leadingSurface = Color.alphaBlend(
      widget.tint.withValues(alpha: 0.10 + (0.06 * highlightStrength)),
      LightcorePalette.panel,
    );
    final middleSurface = Color.alphaBlend(
      widget.tint.withValues(alpha: 0.03 + (0.03 * highlightStrength)),
      LightcorePalette.panel,
    );
    final raisedSurface = Color.alphaBlend(
      widget.tint.withValues(alpha: 0.02 + (0.02 * highlightStrength)),
      LightcorePalette.panelRaised,
    );
    final decoration = BoxDecoration(
      borderRadius: radius,
      border: Border.all(
        color: LightcorePalette.stroke.withValues(
          alpha: 0.92 + (0.08 * highlightStrength),
        ),
        width: 1.2,
      ),
      gradient: LinearGradient(
        colors: [leadingSurface, middleSurface, raisedSurface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: widget.tint.withValues(
            alpha: 0.08 + (0.08 * highlightStrength),
          ),
          blurRadius: 26,
          spreadRadius: -4,
        ),
      ],
    );

    final panel = Ink(
      decoration: decoration,
      child: Padding(padding: widget.padding, child: widget.child),
    );

    final scaledPanel = AnimatedScale(
      scale: interactive && _pressed ? 0.992 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: panel,
    );

    if (!interactive) {
      return Material(color: Colors.transparent, child: scaledPanel);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: widget.onTap,
        onHighlightChanged: (pressed) {
          if (_pressed == pressed) {
            return;
          }
          setState(() => _pressed = pressed);
        },
        onHover: (hovered) {
          if (_hovered == hovered) {
            return;
          }
          setState(() => _hovered = hovered);
        },
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return widget.tint.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return widget.tint.withValues(alpha: 0.06);
          }
          return null;
        }),
        child: scaledPanel,
      ),
    );
  }
}
