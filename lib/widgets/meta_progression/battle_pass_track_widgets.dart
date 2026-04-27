part of '../meta_progression_sheet.dart';

class _MetaSheetFrame extends StatelessWidget {
  const _MetaSheetFrame({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: AuroraPanel(
            radius: 30,
            padding: EdgeInsets.zero,
            tint: tint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattlePassLaneHeader extends StatelessWidget {
  const _BattlePassLaneHeader({
    required this.type,
    required this.pass,
    required this.progress,
    required this.progressCap,
  });

  final BattlePassType type;
  final BattlePassProgress pass;
  final int progress;
  final int progressCap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final paidTint = pass.premiumUnlocked
        ? LightcorePalette.success
        : LightcorePalette.solar;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.redeem_rounded,
                size: 16,
                color: LightcorePalette.aether,
              ),
              const SizedBox(width: 6),
              Text(
                'FREE',
                style: textTheme.labelLarge?.copyWith(
                  color: LightcorePalette.aether,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 112,
          child: Column(
            children: [
              Icon(Icons.timeline_rounded, size: 14, color: _passTint(type)),
              const SizedBox(height: 2),
              Text(
                'PROGRESS',
                style: textTheme.labelMedium?.copyWith(
                  color: _passTint(type),
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$progress / $progressCap',
                style: textTheme.titleMedium?.copyWith(color: _passTint(type)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pass.premiumUnlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  size: 18,
                  color: paidTint,
                ),
                const SizedBox(width: 6),
                Text(
                  'PAID',
                  style: textTheme.labelLarge?.copyWith(
                    color: paidTint,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BattlePassTierCard extends StatelessWidget {
  const _BattlePassTierCard({
    required this.controller,
    required this.type,
    required this.pass,
    required this.tier,
    required this.tierIndex,
    required this.previousGoal,
    required this.compact,
  });

  final LightcoreController controller;
  final BattlePassType type;
  final BattlePassProgress pass;
  final BattlePassTierDefinition tier;
  final int tierIndex;
  final int previousGoal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final remaining = (tier.goal - pass.progress).clamp(0, tier.goal);
    final freeClaimed = controller.isBattlePassRewardClaimedForPass(
      pass,
      tierIndex,
      BattlePassTrack.free,
    );
    final freeClaimable = controller.canClaimBattlePassRewardForPass(
      pass,
      tierIndex,
      BattlePassTrack.free,
    );
    final paidClaimed = controller.isBattlePassRewardClaimedForPass(
      pass,
      tierIndex,
      BattlePassTrack.premium,
    );
    final paidClaimable = controller.canClaimBattlePassRewardForPass(
      pass,
      tierIndex,
      BattlePassTrack.premium,
    );
    final freeCard = _TrackRewardCard(
      key: ValueKey<String>('${pass.seasonKey}-$tierIndex-free'),
      tint: LightcorePalette.aether,
      reward: tier.freeReward,
      status: freeClaimed
          ? 'Claimed'
          : freeClaimable
          ? 'Claim'
          : remaining > 0
          ? '$remaining remaining'
          : 'Unlocked',
      claimed: freeClaimed,
      claimable: freeClaimable,
      locked: false,
      compact: compact,
      onClaim: () => controller.claimBattlePassRewardForPass(
        pass,
        tierIndex,
        BattlePassTrack.free,
      ),
    );
    final premiumCard = _TrackRewardCard(
      key: ValueKey<String>('${pass.seasonKey}-$tierIndex-premium'),
      tint: LightcorePalette.solar,
      reward: tier.premiumReward,
      status: paidClaimed
          ? 'Claimed'
          : !pass.premiumUnlocked
          ? 'Premium track required'
          : paidClaimable
          ? 'Claim'
          : remaining > 0
          ? '$remaining remaining'
          : 'Unlocked',
      claimed: paidClaimed,
      claimable: paidClaimable,
      locked: !pass.premiumUnlocked,
      compact: compact,
      onClaim: () => controller.claimBattlePassRewardForPass(
        pass,
        tierIndex,
        BattlePassTrack.premium,
      ),
    );
    final rail = _BattlePassTierRail(
      type: type,
      pass: pass,
      tier: tier,
      tierIndex: tierIndex,
      previousGoal: previousGoal,
      compact: compact,
    );

    final laneGap = compact ? 8.0 : 16.0;
    final railWidth = compact ? 54.0 : 88.0;
    final cardMaxWidth = compact ? 210.0 : 236.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardMaxWidth),
                child: freeCard,
              ),
            ),
          ),
          SizedBox(width: laneGap),
          SizedBox(width: railWidth, child: rail),
          SizedBox(width: laneGap),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardMaxWidth),
                child: premiumCard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattlePassTierRail extends StatelessWidget {
  const _BattlePassTierRail({
    required this.type,
    required this.pass,
    required this.tier,
    required this.tierIndex,
    required this.previousGoal,
    required this.compact,
  });

  final BattlePassType type;
  final BattlePassProgress pass;
  final BattlePassTierDefinition tier;
  final int tierIndex;
  final int previousGoal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final completed = pass.progress >= tier.goal;
    final tierSpan = tier.goal - previousGoal;
    final segmentProgress = completed
        ? 1.0
        : tierSpan <= 0
        ? 0.0
        : ((pass.progress - previousGoal) / tierSpan).clamp(0.0, 1.0);
    final tint = _passTint(type);
    final textTheme = Theme.of(context).textTheme;
    final markerSize = compact ? 32.0 : 38.0;
    final remaining = (tier.goal - pass.progress).clamp(0, tier.goal);

    final marker = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          compact ? 'T${tierIndex + 1}' : 'Tier ${tierIndex + 1}',
          style: (compact ? textTheme.labelMedium : textTheme.labelLarge)
              ?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.82),
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? 8 : 10),
        SizedBox(
          height: compact ? 96 : 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: compact ? 6 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: LightcorePalette.stroke.withValues(alpha: 0.32),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: segmentProgress,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: compact ? 6 : 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: tint,
                        boxShadow: [
                          BoxShadow(
                            color: tint.withValues(alpha: 0.24),
                            blurRadius: 14,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? tint
                      : LightcorePalette.panel.withValues(alpha: 0.98),
                  border: Border.all(
                    color: completed ? tint : tint.withValues(alpha: 0.52),
                    width: 1.6,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${tierIndex + 1}',
                  style: textTheme.labelLarge?.copyWith(
                    color: completed ? LightcorePalette.night : tint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: tint.withValues(alpha: 0.12),
            border: Border.all(color: tint.withValues(alpha: 0.32)),
          ),
          child: Text(
            compact ? '${tier.goal}' : 'Goal ${tier.goal}',
            style: (compact ? textTheme.labelSmall : textTheme.labelLarge)
                ?.copyWith(color: tint, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          completed ? 'Unlocked' : '$remaining left',
          style: (compact ? textTheme.labelSmall : textTheme.bodySmall)
              ?.copyWith(color: LightcorePalette.mist.withValues(alpha: 0.72)),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 10),
      child: marker,
    );
  }
}

class _TrackRewardCard extends StatefulWidget {
  const _TrackRewardCard({
    super.key,
    required this.tint,
    required this.reward,
    required this.status,
    required this.claimed,
    required this.claimable,
    required this.locked,
    this.compact = false,
    required this.onClaim,
  });

  final Color tint;
  final BattlePassReward reward;
  final String status;
  final bool claimed;
  final bool claimable;
  final bool locked;
  final bool compact;
  final VoidCallback onClaim;

  @override
  State<_TrackRewardCard> createState() => _TrackRewardCardState();
}

class _TrackRewardCardState extends State<_TrackRewardCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final surfaceTint = widget.locked ? LightcorePalette.stroke : widget.tint;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(widget.compact ? 18 : 20);
    final iconExtent = widget.compact ? 40.0 : 42.0;
    final actionStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final rewardAccent = widget.locked ? LightcorePalette.mist : widget.tint;
    final qualifier = _battlePassRewardQualifier(widget.reward);
    final statusTint = widget.claimed
        ? LightcorePalette.success
        : widget.claimable
        ? widget.tint
        : widget.locked
        ? LightcorePalette.warning
        : LightcorePalette.mist.withValues(alpha: 0.74);
    final rewardIcon = Tooltip(
      message: widget.reward.label,
      child: SizedBox(
        width: iconExtent,
        height: iconExtent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: iconExtent,
              height: iconExtent,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rewardAccent.withValues(alpha: 0.16),
                border: Border.all(color: rewardAccent.withValues(alpha: 0.4)),
              ),
              alignment: Alignment.center,
              child: Icon(
                _battlePassRewardIcon(widget.reward),
                size: widget.compact ? 19 : 20,
                color: rewardAccent,
              ),
            ),
            if (widget.locked)
              PositionedDirectional(
                top: -2,
                end: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LightcorePalette.panelRaised,
                    border: Border.all(
                      color: LightcorePalette.stroke.withValues(alpha: 0.86),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.lock_rounded,
                    size: 11,
                    color: LightcorePalette.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final statusPill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 7 : 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: statusTint.withValues(alpha: 0.12),
        border: Border.all(color: statusTint.withValues(alpha: 0.3)),
      ),
      child: Text(
        widget.status,
        style: textTheme.labelSmall?.copyWith(
          color: statusTint,
          fontWeight: FontWeight.w700,
        ),
        maxLines: widget.compact ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        textAlign: widget.compact ? TextAlign.center : TextAlign.start,
      ),
    );
    final compactContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(alignment: Alignment.center, child: rewardIcon),
        const SizedBox(height: 8),
        Text(
          widget.reward.label,
          style: textTheme.labelLarge?.copyWith(
            color: widget.locked ? LightcorePalette.mist : null,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
          maxLines: _expanded ? 3 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (qualifier != null) ...[
          const SizedBox(height: 4),
          Text(
            qualifier,
            style: textTheme.labelSmall?.copyWith(color: rewardAccent),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        if (widget.claimable)
          FilledButton.tonal(
            onPressed: widget.onClaim,
            style: actionStyle,
            child: const Text('Claim'),
          )
        else
          statusPill,
        const SizedBox(height: 6),
        Icon(
          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          size: 18,
          color: LightcorePalette.mist.withValues(alpha: 0.72),
        ),
      ],
    );
    final wideContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            rewardIcon,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reward.label,
                    style: textTheme.titleMedium?.copyWith(
                      color: widget.locked ? LightcorePalette.mist : null,
                    ),
                    maxLines: _expanded ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (qualifier != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      qualifier,
                      style: textTheme.labelMedium?.copyWith(
                        color: rewardAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (widget.claimable) ...[
              FilledButton.tonal(
                onPressed: widget.onClaim,
                style: actionStyle,
                child: const Text('Claim'),
              ),
              const SizedBox(width: 8),
            ],
            Column(
              children: [
                if (widget.claimed) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: LightcorePalette.success,
                  ),
                ] else if (widget.claimable) ...[
                  Icon(Icons.bolt_rounded, size: 18, color: widget.tint),
                ],
                const SizedBox(height: 6),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: LightcorePalette.mist.withValues(alpha: 0.72),
                ),
              ],
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 10),
          if (!widget.claimable) statusPill,
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () => setState(() => _expanded = !_expanded),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: widget.locked
                  ? [
                      LightcorePalette.panelRaised.withValues(alpha: 0.78),
                      LightcorePalette.panel.withValues(alpha: 0.96),
                    ]
                  : [
                      widget.tint.withValues(alpha: 0.18),
                      LightcorePalette.panelRaised.withValues(alpha: 0.72),
                      LightcorePalette.panel.withValues(alpha: 0.95),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: surfaceTint.withValues(alpha: 0.42)),
            boxShadow: [
              if (widget.claimable)
                BoxShadow(
                  color: widget.tint.withValues(alpha: 0.2),
                  blurRadius: 18,
                  spreadRadius: -7,
                ),
            ],
          ),
          child: Padding(
            padding: widget.compact
                ? const EdgeInsets.fromLTRB(8, 9, 8, 8)
                : const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: widget.compact ? compactContent : wideContent,
            ),
          ),
        ),
      ),
    );
  }
}
