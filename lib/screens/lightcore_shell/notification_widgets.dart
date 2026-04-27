part of '../lightcore_shell.dart';

class _ShellNotificationOverlay extends StatefulWidget {
  const _ShellNotificationOverlay({required this.controller});

  final LightcoreController controller;

  @override
  State<_ShellNotificationOverlay> createState() =>
      _ShellNotificationOverlayState();
}

class _ShellNotificationOverlayState extends State<_ShellNotificationOverlay> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _shown = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final message = widget.controller.bannerMessage.trim();
            final visible =
                _shown &&
                widget.controller.notificationBannersEnabled &&
                message.isNotEmpty;
            return Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, -0.55),
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: Duration(milliseconds: visible ? 180 : 140),
                    curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                    child: _ShellNotificationBanner(
                      message: message,
                      onDismiss: widget.controller.dismissBanner,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShellNotificationBanner extends StatelessWidget {
  const _ShellNotificationBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dismiss notification',
      onTap: onDismiss,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              key: const ValueKey<String>('shell-notification-banner'),
              decoration: BoxDecoration(
                color: LightcorePalette.night.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: LightcorePalette.mist.withValues(alpha: 0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.36),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LightcorePalette.mist,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
