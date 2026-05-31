import 'dart:async';

import 'package:flutter/material.dart';

import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

class LightcoreQuestCard extends StatefulWidget {
  const LightcoreQuestCard({
    super.key,
    required this.controller,
    required this.compact,
    this.instructionOverride,
  });

  final LightcoreController controller;
  final bool compact;
  final String? instructionOverride;

  @override
  State<LightcoreQuestCard> createState() => _LightcoreQuestCardState();
}

class _LightcoreQuestCardState extends State<LightcoreQuestCard> {
  static const Duration _stuckHintDelay = Duration(seconds: 10);

  late LightcoreTutorialStep _trackedStep;
  Timer? _stuckHintTimer;
  bool _stuckHintVisible = false;

  @override
  void initState() {
    super.initState();
    _trackedStep = widget.controller.tutorialStep;
    _scheduleStuckHint();
  }

  @override
  void didUpdateWidget(covariant LightcoreQuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStep = widget.controller.tutorialStep;
    if (nextStep == _trackedStep) {
      return;
    }
    _trackedStep = nextStep;
    _stuckHintVisible = false;
    _scheduleStuckHint();
  }

  @override
  void dispose() {
    _stuckHintTimer?.cancel();
    super.dispose();
  }

  void _scheduleStuckHint() {
    _stuckHintTimer?.cancel();
    if (!widget.controller.hasActiveTutorial ||
        widget.controller.tutorialFailureHelp == null) {
      return;
    }
    _stuckHintTimer = Timer(_stuckHintDelay, () {
      if (!mounted || widget.controller.tutorialStep != _trackedStep) {
        return;
      }
      setState(() {
        _stuckHintVisible = true;
      });
    });
  }

  void _toggleDetails() {
    _showDetailsSheet();
  }

  void _showDetailsSheet() {
    final controller = widget.controller;
    final headline = controller.tutorialHeadline;
    final instruction = widget.instructionOverride ?? controller.tutorialPrompt;
    if (headline == null || instruction == null) {
      return;
    }

    final step = controller.tutorialStep;
    final tint = LightcorePalette.quest;
    final promptIcon = _questPromptIcon(step);
    final mechanicHint = controller.tutorialMechanicHint;
    final stuckHelp = controller.tutorialFailureHelp;
    final stuckHintVisible = _stuckHintVisible;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: LightcorePalette.night.withValues(alpha: 0.36),
      isScrollControlled: true,
      builder: (sheetContext) {
        final width = MediaQuery.sizeOf(
          sheetContext,
        ).width.clamp(280.0, 430.0).toDouble();
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
              child: SizedBox(
                width: width,
                child: _QuestDetailsCard(
                  headline: headline,
                  instruction: instruction,
                  promptIcon: promptIcon,
                  mechanicHint: mechanicHint,
                  stuckHelp: stuckHintVisible ? stuckHelp : null,
                  tint: tint,
                  compact: widget.compact,
                  onClose: () => Navigator.of(sheetContext).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final headline = controller.tutorialHeadline;
    final instruction = widget.instructionOverride ?? controller.tutorialPrompt;
    if (headline == null || instruction == null) {
      return const SizedBox.shrink();
    }

    final step = controller.tutorialStep;
    final tint = LightcorePalette.quest;
    final promptIcon = _questPromptIcon(step);
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final notificationWidth = availableWidth
        .clamp(widget.compact ? 228.0 : 252.0, widget.compact ? 286.0 : 320.0)
        .toDouble();

    final tracker = Tooltip(
      message: 'Open guide details',
      child: AuroraPanel(
        key: const ValueKey<String>('battle-quest-trigger-button'),
        tint: tint,
        radius: 999,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 12,
          vertical: widget.compact ? 8 : 10,
        ),
        onTap: _toggleDetails,
        child: Semantics(
          key: const ValueKey<String>('battle-quest-summary-card'),
          button: true,
          label: 'Open guide details for $headline. $instruction',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  promptIcon,
                  size: widget.compact ? 16 : 18,
                  color: tint,
                ),
              ),
              SizedBox(width: widget.compact ? 6 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LightcorePalette.mist,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      key: const ValueKey<String>(
                        'battle-quest-summary-action-row',
                      ),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Tap for next step',
                            key: const ValueKey<String>(
                              'battle-quest-summary-instruction',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: LightcorePalette.mist.withValues(
                                    alpha: 0.74,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: widget.compact ? 4 : 6),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: widget.compact ? 18 : 20,
                  color: LightcorePalette.mist.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      key: const ValueKey<String>('battle-quest-card'),
      width: notificationWidth,
      child: tracker,
    );
  }
}

class _QuestDetailsCard extends StatelessWidget {
  const _QuestDetailsCard({
    required this.headline,
    required this.instruction,
    required this.promptIcon,
    required this.mechanicHint,
    required this.stuckHelp,
    required this.tint,
    required this.compact,
    required this.onClose,
  });

  final String headline;
  final String instruction;
  final IconData promptIcon;
  final String? mechanicHint;
  final String? stuckHelp;
  final Color tint;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      key: const ValueKey<String>('battle-quest-detail-card'),
      tint: tint,
      radius: compact ? 18 : 20,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 12 : 14,
        compact ? 14 : 16,
        compact ? 14 : 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(promptIcon, size: 18, color: tint),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headline,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: LightcorePalette.mist,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('battle-quest-collapse-button'),
                  tooltip: 'Close guide details',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    maximumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _QuestActionBlock(
              instruction: instruction,
              tint: tint,
              compact: compact,
            ),
            if (mechanicHint != null) ...[
              const SizedBox(height: 10),
              _QuestDetailText(
                icon: Icons.lightbulb_rounded,
                title: 'Why',
                text: mechanicHint!,
                tint: tint,
              ),
            ],
            if (stuckHelp != null) ...[
              const SizedBox(height: 10),
              _QuestDetailText(
                icon: Icons.help_outline_rounded,
                title: 'Hint',
                text: stuckHelp!,
                tint: LightcorePalette.warning,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestActionBlock extends StatelessWidget {
  const _QuestActionBlock({
    required this.instruction,
    required this.tint,
    required this.compact,
  });

  final String instruction;
  final Color tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 12,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Do this',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.36,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instruction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LightcorePalette.mist,
              fontWeight: FontWeight.w800,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestDetailText extends StatelessWidget {
  const _QuestDetailText({
    required this.icon,
    required this.title,
    required this.text,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tint),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.36,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _questPromptIcon(LightcoreTutorialStep step) => switch (step) {
  LightcoreTutorialStep.unfoldShell => Icons.touch_app_rounded,
  LightcoreTutorialStep.waitForFirstHex => Icons.hexagon_rounded,
  LightcoreTutorialStep.raiseThreat => Icons.flag_rounded,
  LightcoreTutorialStep.readEffectiveGain => Icons.blur_circular_rounded,
  LightcoreTutorialStep.managerAutoAim => Icons.all_inclusive_rounded,
  LightcoreTutorialStep.holdOverdrive => Icons.pan_tool_alt_rounded,
  _ => Icons.touch_app_rounded,
};
