part of '../lightcore_main_menu_screen.dart';

class _GuideSelectionSheet extends StatelessWidget {
  const _GuideSelectionSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Guide',
                style: textTheme.headlineSmall?.copyWith(
                  color: LightcorePalette.layer2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick the voice for your first launch.',
                style: textTheme.bodyMedium?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.82),
                  height: 1.32,
                ),
              ),
              const SizedBox(height: 16),
              for (final guide in LightcoreGuideProfile.all) ...[
                _GuideChoiceCard(
                  guide: guide,
                  compact: false,
                  isSelected: false,
                  onTap: () => Navigator.of(context).pop(guide),
                ),
                if (guide != LightcoreGuideProfile.all.last)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideChoiceCard extends StatelessWidget {
  const _GuideChoiceCard({
    required this.guide,
    required this.compact,
    required this.isSelected,
    required this.onTap,
  });

  final LightcoreGuideProfile guide;
  final bool compact;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? LightcorePalette.violet.withValues(alpha: 0.46)
        : LightcorePalette.aether.withValues(alpha: 0.2);
    final badgeColor = isSelected
        ? LightcorePalette.success
        : LightcorePalette.aether;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            gradient: LinearGradient(
              colors: [
                (isSelected
                        ? LightcorePalette.violet
                        : LightcorePalette.panelRaised)
                    .withValues(alpha: isSelected ? 0.16 : 0.72),
                LightcorePalette.panelRaised.withValues(alpha: 0.72),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LightcoreGuideBadge(guide: guide, size: compact ? 52 : 58),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          guide.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: LightcorePalette.violet.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            guide.playerProfileLabel,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: LightcorePalette.violet,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      guide.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LightcorePalette.mist.withValues(alpha: 0.82),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Text(
                      isSelected
                          ? '${guide.displayName} selected'
                          : 'Select ${guide.displayName}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
