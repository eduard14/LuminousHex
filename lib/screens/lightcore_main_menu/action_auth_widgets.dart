part of '../lightcore_main_menu_screen.dart';

class _CoreActionCluster extends StatelessWidget {
  const _CoreActionCluster({
    required this.phase,
    required this.enabled,
    required this.isLoading,
    required this.compact,
    required this.buttonSize,
    required this.onTap,
  });

  final double phase;
  final bool enabled;
  final bool isLoading;
  final bool compact;
  final double buttonSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final orbitSize = buttonSize + (compact ? 110 : 128);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: orbitSize,
          height: orbitSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CorePulsePainter(
                      phase: phase,
                      enabled: enabled,
                      isLoading: isLoading,
                    ),
                  ),
                ),
              ),
              _HexagonPlayButton(
                enabled: enabled,
                isLoading: isLoading,
                phase: phase,
                compact: compact,
                size: buttonSize,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HexagonPlayButton extends StatelessWidget {
  const _HexagonPlayButton({
    required this.enabled,
    required this.isLoading,
    required this.phase,
    required this.compact,
    required this.size,
    required this.onTap,
  });

  final bool enabled;
  final bool isLoading;
  final double phase;
  final bool compact;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final accent = enabled
        ? LightcorePalette.aether
        : (isLoading ? LightcorePalette.aether : LightcorePalette.warning);
    final glowTint = enabled
        ? LightcorePalette.solar
        : (isLoading ? LightcorePalette.violet : LightcorePalette.stroke);
    final scale = enabled ? 1.0 + (pulse * 0.024) : 1.0;
    final primaryLabel = enabled ? 'PLAY' : (isLoading ? 'WAIT' : 'LOCKED');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + (compact ? 56 : 68),
              height: size + (compact ? 56 : 68),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: enabled ? 0.24 : 0.13),
                    glowTint.withValues(alpha: 0.06 + (pulse * 0.1)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TowerRingIcon(
                    size: compact ? 22 : 30,
                    color: accent.withValues(alpha: enabled ? 0.98 : 0.74),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  Text(
                    primaryLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: compact ? 21 : 28,
                      color: LightcorePalette.layer2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.5 : 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCornerBadge extends StatelessWidget {
  const _AuthCornerBadge({
    required this.authId,
    required this.isReady,
    required this.compact,
  });

  final String authId;
  final bool isReady;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = isReady
        ? LightcorePalette.success
        : LightcorePalette.layer2.withValues(alpha: 0.74);
    final label = Text(
      'Authentication ID',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: compact ? 8 : 9,
        color: accent.withValues(alpha: 0.7),
        letterSpacing: compact ? 0.7 : 0.9,
        fontWeight: FontWeight.w700,
        height: 1,
      ),
    );
    final authValue = SelectableText(
      'AUTH $authId',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: compact ? 9.5 : 10.5,
        color: accent.withValues(alpha: 0.78),
        letterSpacing: compact ? 0.8 : 1,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
        height: 1.05,
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [label, const SizedBox(height: 1), authValue],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [label, const SizedBox(width: 8), authValue],
            ),
    );
  }
}
