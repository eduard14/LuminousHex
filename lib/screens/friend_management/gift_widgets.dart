part of '../friend_management_screen.dart';

class _InviteQueuePanel extends StatelessWidget {
  const _InviteQueuePanel({
    required this.title,
    required this.emptyText,
    required this.overview,
    required this.busy,
    required this.kind,
    required this.onRespondMentor,
    required this.onRespondFriend,
  });

  final String title;
  final String emptyText;
  final LightcoreSocialOverview? overview;
  final bool busy;
  final LightcoreSocialInviteKind kind;
  final void Function(LightcoreSocialInvite invite, bool accept)
  onRespondMentor;
  final void Function(LightcoreSocialInvite invite, bool accept)
  onRespondFriend;

  @override
  Widget build(BuildContext context) {
    final invites = (overview?.invites ?? const <LightcoreSocialInvite>[])
        .where((invite) => invite.kind == kind)
        .toList(growable: false);
    return AuroraPanel(
      tint: LightcorePalette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (invites.isEmpty)
            Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
          else
            for (final invite in invites) ...[
              _InviteCard(
                invite: invite,
                busy: busy,
                onRespond: (accept) {
                  if (invite.kind == LightcoreSocialInviteKind.mentor) {
                    onRespondMentor(invite, accept);
                  } else {
                    onRespondFriend(invite, accept);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.busy,
    required this.onRespond,
  });

  final LightcoreSocialInvite invite;
  final bool busy;
  final ValueChanged<bool> onRespond;

  @override
  Widget build(BuildContext context) {
    final incoming =
        invite.direction == LightcoreSocialInviteDirection.incoming;
    final typeLabel = switch (invite.kind) {
      LightcoreSocialInviteKind.mentor =>
        incoming ? 'Mentor invite' : 'Mentee invite',
      LightcoreSocialInviteKind.friend => 'Friend request',
    };
    return _SocialCard(
      title: incoming
          ? '$typeLabel from ${invite.fromPlayer.displayName}'
          : '$typeLabel to ${invite.toPlayer.displayName}',
      subtitle: incoming
          ? '${invite.fromPlayer.levelLabel} • ${invite.fromPlayer.performanceLabel}'
          : 'Waiting for response',
      tint: invite.kind == LightcoreSocialInviteKind.mentor
          ? LightcorePalette.verdant
          : LightcorePalette.solar,
      trailing: incoming
          ? Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => onRespond(false),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: busy ? null : () => onRespond(true),
                  child: const Text('Accept'),
                ),
              ],
            )
          : const _MiniBadge(label: 'Pending', tint: LightcorePalette.aether),
    );
  }
}

class _FriendGiftPanel extends StatelessWidget {
  const _FriendGiftPanel({
    required this.overview,
    required this.busy,
    required this.onSendGift,
    required this.onSendAllGifts,
    required this.onClaimGift,
    required this.onClaimAllGifts,
  });

  final LightcoreSocialOverview? overview;
  final bool busy;
  final ValueChanged<String> onSendGift;
  final VoidCallback onSendAllGifts;
  final ValueChanged<String> onClaimGift;
  final VoidCallback onClaimAllGifts;

  @override
  Widget build(BuildContext context) {
    final friends = overview?.friends ?? const <LightcoreSocialFriend>[];
    final sendableCount = overview?.sendableBossGiftCount ?? 0;
    final claimableCount = overview?.availableBossGiftCount ?? 0;
    return AuroraPanel(
      tint: LightcorePalette.aether,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Threat Scans',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Each accepted friend can send you one Threat Scan per Eastern-day reset, and you can send one back.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (friends.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy || sendableCount == 0 ? null : onSendAllGifts,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    sendableCount > 0
                        ? 'Send All ($sendableCount)'
                        : 'Send All',
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy || claimableCount == 0
                      ? null
                      : onClaimAllGifts,
                  icon: const Icon(Icons.inventory_2_rounded),
                  label: Text(
                    claimableCount > 0
                        ? 'Claim All ($claimableCount)'
                        : 'Claim All',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (friends.isEmpty)
            Text(
              'No friends yet. Add friends above to start daily Threat Scan exchanges.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final friend in friends) ...[
              _SocialCard(
                title: friend.player.displayName,
                subtitle:
                    '${friend.player.levelLabel} • ${friend.player.performanceLabel} • ${friend.giftStatusLabel}',
                tint: friend.giftAvailable
                    ? LightcorePalette.success
                    : LightcorePalette.aether,
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: busy || friend.giftSentToday
                          ? null
                          : () => onSendGift(friend.player.uid),
                      child: const Text('Send'),
                    ),
                    FilledButton(
                      onPressed: busy || !friend.giftAvailable
                          ? null
                          : () => onClaimGift(friend.player.uid),
                      child: const Text('Claim'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _SharedRelaySummary extends StatelessWidget {
  const _SharedRelaySummary({required this.controller});

  final LightcoreController controller;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.solar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared Relay Loadout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved relay tower is still published with your profile and used by relay-flavored events.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusPill(
                label: 'Shared',
                value:
                    '${controller.sharedRelayFilledPieceCount}/${LightcoreController.slotCount + 1}',
                tint: controller.isSharedRelayComplete
                    ? LightcorePalette.success
                    : LightcorePalette.solar,
                icon: Icons.hub_rounded,
              ),
              OutlinedButton.icon(
                onPressed: controller.autoFillSharedRelayTower,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Auto Fill'),
              ),
              FilledButton.tonalIcon(
                onPressed: controller.clearSharedRelayTower,
                icon: const Icon(Icons.layers_clear_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 540;
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            MeterBar(value: 0.72, color: tint, height: 6),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tint.withValues(alpha: 0.46)),
            color: LightcorePalette.panelRaised.withValues(alpha: 0.84),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [body, const SizedBox(height: 12), trailing],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: body),
                    const SizedBox(width: 12),
                    trailing,
                  ],
                ),
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tint.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: tint,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
