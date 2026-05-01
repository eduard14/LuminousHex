import 'package:flutter/material.dart';

import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

class LightcoreInfoButton extends StatelessWidget {
  const LightcoreInfoButton({
    super.key,
    required this.title,
    required this.message,
    this.tint = LightcorePalette.aether,
    this.tooltip,
  });

  final String title;
  final String message;
  final Color tint;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip ?? title,
      visualDensity: VisualDensity.compact,
      color: tint,
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => _showInfoDialog(context),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: LightcorePalette.night.withValues(alpha: 0.78),
      builder: (dialogContext) {
        final mediaQuery = MediaQuery.of(dialogContext);
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: mediaQuery.size.height * 0.74,
            ),
            child: AuroraPanel(
              tint: tint,
              radius: 24,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: textTheme.titleLarge)),
                      IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(message, style: textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
