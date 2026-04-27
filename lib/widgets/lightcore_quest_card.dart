import 'package:flutter/material.dart';

import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import 'aurora_panel.dart';

class LightcoreQuestCard extends StatefulWidget {
  const LightcoreQuestCard({
    super.key,
    required this.controller,
    required this.compact,
    this.initiallyExpanded = false,
  });

  final LightcoreController controller;
  final bool compact;
  final bool initiallyExpanded;

  @override
  State<LightcoreQuestCard> createState() => _LightcoreQuestCardState();
}

class _LightcoreQuestCardState extends State<LightcoreQuestCard> {
  late bool _detailsOpen;
  late LightcoreTutorialStep _trackedStep;

  @override
  void initState() {
    super.initState();
    _detailsOpen = widget.initiallyExpanded;
    _trackedStep = widget.controller.tutorialStep;
  }

  @override
  void didUpdateWidget(covariant LightcoreQuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStep = widget.controller.tutorialStep;
    if (nextStep == _trackedStep) {
      return;
    }
    _trackedStep = nextStep;
    _detailsOpen = widget.initiallyExpanded;
  }

  void _toggleDetails() {
    setState(() {
      _detailsOpen = !_detailsOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final headline = controller.tutorialHeadline;
    final instruction = controller.tutorialPrompt;
    if (headline == null || instruction == null) {
      return const SizedBox.shrink();
    }

    final step = controller.tutorialStep;
    final tint = LightcorePalette.quest;
    final promptIcon = _questPromptIcon(step);
    final mechanicHint = controller.tutorialMechanicHint;
    final storyBeat = controller.tutorialStoryBeat;
    final questId = controller.tutorialQuestId;
    final clickTarget = controller.tutorialPrimaryClickTarget;
    final completion = controller.tutorialCompletionCondition;
    final reward = controller.tutorialLearningReward;
    final triggerSize = widget.compact ? 52.0 : 58.0;
    final detailGap = widget.compact ? 8.0 : 10.0;
    final maxDetailsWidth = widget.compact ? 318.0 : 380.0;
    final availableDetailsWidth =
        MediaQuery.sizeOf(context).width - triggerSize - detailGap - 32;
    final detailsWidth = availableDetailsWidth
        .clamp(widget.compact ? 220.0 : 300.0, maxDetailsWidth)
        .toDouble();
    final contentWidth = _detailsOpen
        ? triggerSize + detailGap + detailsWidth
        : triggerSize;

    final tracker = Tooltip(
      message: _detailsOpen
          ? 'Hide detailed quest steps'
          : 'Open detailed quest steps',
      child: SizedBox(
        key: const ValueKey<String>('battle-quest-card'),
        width: triggerSize,
        height: triggerSize,
        child: AuroraPanel(
          key: const ValueKey<String>('battle-quest-trigger-button'),
          tint: tint,
          radius: widget.compact ? 18 : 20,
          padding: EdgeInsets.zero,
          onTap: _toggleDetails,
          child: Semantics(
            button: true,
            label: 'Guide quest, $headline',
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  _detailsOpen
                      ? Icons.keyboard_arrow_left_rounded
                      : Icons.flag_rounded,
                  key: ValueKey<bool>(_detailsOpen),
                  size: widget.compact ? 25 : 28,
                  color: tint,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final detailsCard = SizedBox(
      width: detailsWidth,
      child: AuroraPanel(
        key: const ValueKey<String>('battle-quest-detail-card'),
        tint: tint,
        radius: widget.compact ? 18 : 20,
        padding: EdgeInsets.fromLTRB(
          widget.compact ? 14 : 16,
          widget.compact ? 12 : 14,
          widget.compact ? 14 : 16,
          widget.compact ? 14 : 16,
        ),
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
                      if (questId != null) ...[
                        Text(
                          questId,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: tint,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                      ],
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
                  tooltip: 'Hide detailed quest steps',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    maximumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _toggleDetails,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tint.withValues(alpha: 0.26)),
              ),
              child: Text(
                instruction,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w800,
                  height: 1.28,
                ),
              ),
            ),
            if (clickTarget != null) ...[
              const SizedBox(height: 12),
              _QuestDetailText(
                icon: Icons.route_rounded,
                title: 'Target',
                text: clickTarget,
                tint: tint,
              ),
            ],
            if (completion != null) ...[
              const SizedBox(height: 10),
              _QuestDetailText(
                icon: Icons.check_circle_outline_rounded,
                title: 'Complete',
                text: completion,
                tint: LightcorePalette.warning,
              ),
            ],
            if (reward != null) ...[
              const SizedBox(height: 10),
              _QuestDetailText(
                icon: Icons.redeem_rounded,
                title: 'Reward',
                text: reward,
                tint: LightcorePalette.success,
              ),
            ],
            if (mechanicHint != null) ...[
              const SizedBox(height: 12),
              _QuestDetailText(
                icon: Icons.lightbulb_rounded,
                title: 'Why it matters',
                text: mechanicHint,
                tint: tint,
              ),
            ],
            if (storyBeat != null) ...[
              const SizedBox(height: 10),
              _QuestDetailText(
                icon: Icons.auto_stories_rounded,
                title: 'Guide note',
                text: storyBeat,
                tint: LightcorePalette.aether,
              ),
            ],
          ],
        ),
      ),
    );

    return SizedBox(
      width: contentWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tracker,
          if (_detailsOpen)
            Padding(
              key: const ValueKey<String>('battle-quest-details-open'),
              padding: EdgeInsets.only(left: detailGap),
              child: detailsCard,
            )
          else
            const SizedBox.shrink(
              key: ValueKey<String>('battle-quest-card-collapsed'),
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
  LightcoreTutorialStep.waitForFirstHex => Icons.hourglass_top_rounded,
  LightcoreTutorialStep.readEffectiveGain => Icons.blur_circular_rounded,
  LightcoreTutorialStep.autoQueueCheck => Icons.all_inclusive_rounded,
  LightcoreTutorialStep.holdOverdrive => Icons.pan_tool_alt_rounded,
  _ => Icons.touch_app_rounded,
};
