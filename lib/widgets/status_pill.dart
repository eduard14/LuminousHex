import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.value,
    required this.tint,
    this.icon,
    this.compact = false,
    this.tooltip,
  });

  final String label;
  final String value;
  final Color tint;
  final IconData? icon;
  final bool compact;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: tooltip ?? '$label: $value',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          color: LightcorePalette.panelRaised.withValues(alpha: 0.88),
          border: Border.all(color: tint.withValues(alpha: 0.4)),
        ),
        child: compact
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: tint),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    value,
                    style: textTheme.titleSmall?.copyWith(
                      color: tint,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: tint),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: textTheme.labelSmall?.copyWith(
                          color: LightcorePalette.mist.withValues(alpha: 0.68),
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        value,
                        style: textTheme.titleMedium?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
