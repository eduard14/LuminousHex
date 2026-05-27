import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';

enum AuthProviderButtonKind { google, email, apple }

class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    super.key,
    required this.kind,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.filled = true,
  });

  final AuthProviderButtonKind kind;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.black : LightcorePalette.layer2;
    final disabledForeground = LightcorePalette.mist.withValues(alpha: 0.46);
    final ButtonStyle style;
    if (filled) {
      style = FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: LightcorePalette.layer2,
        foregroundColor: foreground,
        disabledBackgroundColor: LightcorePalette.stroke.withValues(alpha: 0.3),
        disabledForegroundColor: disabledForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    } else {
      style = OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: foreground,
        disabledForegroundColor: disabledForeground,
        side: BorderSide(color: LightcorePalette.stroke.withValues(alpha: 0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }

    final child = _AuthProviderButtonContent(
      kind: kind,
      label: label,
      busy: busy,
      enabled: onPressed != null,
      foreground: foreground,
      disabledForeground: disabledForeground,
    );

    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton(
              onPressed: busy ? null : onPressed,
              style: style,
              child: child,
            )
          : OutlinedButton(
              onPressed: busy ? null : onPressed,
              style: style,
              child: child,
            ),
    );
  }
}

class _AuthProviderButtonContent extends StatelessWidget {
  const _AuthProviderButtonContent({
    required this.kind,
    required this.label,
    required this.busy,
    required this.enabled,
    required this.foreground,
    required this.disabledForeground,
  });

  final AuthProviderButtonKind kind;
  final String label;
  final bool busy;
  final bool enabled;
  final Color foreground;
  final Color disabledForeground;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? foreground : disabledForeground;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : _AuthProviderLogo(kind: kind, color: iconColor),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: enabled ? foreground : disabledForeground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthProviderLogo extends StatelessWidget {
  const _AuthProviderLogo({required this.kind, required this.color});

  final AuthProviderButtonKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case AuthProviderButtonKind.google:
        return CustomPaint(
          size: const Size.square(20),
          painter: _GoogleLogoPainter(),
        );
      case AuthProviderButtonKind.email:
        return Icon(Icons.alternate_email_rounded, size: 21, color: color);
      case AuthProviderButtonKind.apple:
        return Icon(Icons.apple_rounded, size: 22, color: color);
    }
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void arc(Color color, double start, double sweep) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    arc(const Color(0xFF4285F4), -0.18, 1.34);
    arc(const Color(0xFF34A853), 1.16, 1.18);
    arc(const Color(0xFFFBBC05), 2.34, 1.12);
    arc(const Color(0xFFEA4335), 3.46, 1.56);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * 0.54, size.height * 0.52);
    canvas.drawLine(
      center,
      Offset(size.width * 0.88, size.height * 0.52),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
