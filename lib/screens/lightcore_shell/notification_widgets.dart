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
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final message = widget.controller.bannerMessage.trim();
            final openingPrompt =
                !widget.controller.swarmActivated &&
                message.toLowerCase().startsWith('press play');
            final visible =
                _shown &&
                widget.controller.notificationBannersEnabled &&
                widget.controller.activeThreatRegionChallenge == null &&
                message.isNotEmpty;
            return Align(
              alignment: openingPrompt
                  ? const Alignment(0, -0.72)
                  : Alignment.topCenter,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible
                      ? Offset.zero
                      : Offset(0, openingPrompt ? -0.18 : -0.55),
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: Duration(milliseconds: visible ? 180 : 140),
                    curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
                    child: _ShellNotificationBanner(
                      message: message,
                      openingPrompt: openingPrompt,
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
    required this.openingPrompt,
    required this.onDismiss,
  });

  final String message;
  final bool openingPrompt;
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
            constraints: BoxConstraints(maxWidth: openingPrompt ? 300 : 460),
            child: DecoratedBox(
              key: const ValueKey<String>('shell-notification-banner'),
              decoration: BoxDecoration(
                color: LightcorePalette.night.withValues(
                  alpha: openingPrompt ? 0.76 : 0.88,
                ),
                borderRadius: BorderRadius.circular(openingPrompt ? 999 : 16),
                border: Border.all(
                  color: LightcorePalette.aether.withValues(
                    alpha: openingPrompt ? 0.48 : 0.28,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: LightcorePalette.aether.withValues(
                      alpha: openingPrompt ? 0.22 : 0.14,
                    ),
                    blurRadius: openingPrompt ? 24 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  openingPrompt ? 14 : 12,
                  openingPrompt ? 8 : 9,
                  10,
                  openingPrompt ? 8 : 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      openingPrompt
                          ? Icons.play_arrow_rounded
                          : Icons.notifications_active_rounded,
                      color: LightcorePalette.aether,
                      size: openingPrompt ? 20 : 17,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: LightcorePalette.mist,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.close_rounded,
                      color: LightcorePalette.mist.withValues(alpha: 0.72),
                      size: 16,
                    ),
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
