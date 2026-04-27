part of '../friend_management_screen.dart';

class _SocialOverviewPanel extends StatelessWidget {
  const _SocialOverviewPanel({
    required this.section,
    required this.overview,
    required this.error,
    required this.loading,
    required this.onRefresh,
  });

  final FriendManagementSection section;
  final LightcoreSocialOverview? overview;
  final String? error;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraPanel(
      tint: section.tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(section.title, style: textTheme.titleLarge)),
              OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: const Text('Sync'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(section.description(overview), style: textTheme.bodyLarge),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: section.pills(overview)),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: textTheme.bodyMedium?.copyWith(
                color: LightcorePalette.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

extension on FriendManagementSection {
  String get title => switch (this) {
    FriendManagementSection.friends => 'Friends',
    FriendManagementSection.mentees ||
    FriendManagementSection.mentors => 'Mentorship',
  };

  Color get tint => switch (this) {
    FriendManagementSection.friends => LightcorePalette.aether,
    FriendManagementSection.mentees ||
    FriendManagementSection.mentors => LightcorePalette.violet,
  };

  String description(LightcoreSocialOverview? overview) => switch (this) {
    FriendManagementSection.friends =>
      'Friend requests unlock daily Apex Scan gifts. Apex Scan gifts reset for everyone at midnight Eastern.',
    FriendManagementSection.mentees || FriendManagementSection.mentors =>
      'You can have one mentor above you and unlimited mentees below you. The best ${overview?.activeMenteeBonusLimit ?? LightcoreSocialLimits.activeMenteeBonusLimit} in-band mentees feed full bonuses.',
  };

  List<Widget> pills(LightcoreSocialOverview? overview) => switch (this) {
    FriendManagementSection.friends => [
      StatusPill(
        label: 'Friends',
        value:
            '${overview?.friends.length ?? 0}/${overview?.maxFriends ?? LightcoreSocialLimits.maxFriends}',
        tint: LightcorePalette.solar,
        icon: Icons.group_rounded,
      ),
      StatusPill(
        label: 'Gifts',
        value: '${overview?.availableBossGiftCount ?? 0} ready',
        tint: LightcorePalette.warning,
        icon: Icons.card_giftcard_rounded,
      ),
      StatusPill(
        label: 'Requests',
        value:
            '${_incomingInviteCount(overview, LightcoreSocialInviteKind.friend)}',
        tint: LightcorePalette.aether,
        icon: Icons.mark_email_unread_rounded,
      ),
    ],
    FriendManagementSection.mentees || FriendManagementSection.mentors => [
      StatusPill(
        label: 'Mentor',
        value: overview?.mentor?.displayName ?? 'None',
        tint: overview?.mentor == null
            ? LightcorePalette.stroke
            : LightcorePalette.aether,
        icon: Icons.school_rounded,
      ),
      StatusPill(
        label: 'Active Mentees',
        value:
            '${overview?.bonusProfile.activeDirectMentees ?? 0}/${overview?.activeMenteeBonusLimit ?? LightcoreSocialLimits.activeMenteeBonusLimit}',
        tint: LightcorePalette.verdant,
        icon: Icons.hub_rounded,
      ),
      StatusPill(
        label: 'Grand Output',
        value: '${overview?.bonusProfile.activeGrandMentees ?? 0}',
        tint: LightcorePalette.violet,
        icon: Icons.account_tree_rounded,
      ),
      StatusPill(
        label: 'Band',
        value:
            '+/-${overview?.levelBand ?? LightcoreSocialLimits.mentorLevelBand}',
        tint: LightcorePalette.solar,
        icon: Icons.social_distance_rounded,
      ),
    ],
  };
}

int _incomingInviteCount(
  LightcoreSocialOverview? overview,
  LightcoreSocialInviteKind kind,
) {
  if (overview == null) {
    return 0;
  }
  return overview.invites.where((invite) {
    return invite.kind == kind &&
        invite.direction == LightcoreSocialInviteDirection.incoming;
  }).length;
}

class _BonusPanel extends StatelessWidget {
  const _BonusPanel({required this.controller, required this.overview});

  final LightcoreController controller;
  final LightcoreSocialOverview? overview;

  @override
  Widget build(BuildContext context) {
    final bonus = overview?.bonusProfile ?? controller.socialBonusProfile;
    return AuroraPanel(
      tint: LightcorePalette.aether,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mentee Bonuses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusPill(
                label: 'EXP',
                value: controller.sharedRelayExperienceMultiplierLabel,
                tint: LightcorePalette.violet,
                icon: Icons.trending_up_rounded,
              ),
              StatusPill(
                label: 'Combat',
                value: controller.friendAllianceCombatMultiplierLabel,
                tint: LightcorePalette.warning,
                icon: Icons.flash_on_rounded,
              ),
              StatusPill(
                label: 'Rewards',
                value: controller.friendAllianceRewardMultiplierLabel,
                tint: LightcorePalette.solar,
                icon: Icons.auto_awesome_rounded,
              ),
              StatusPill(
                label: 'Home Tower',
                value: controller.homeTowerLabel,
                tint:
                    controller.homeTowerAffinity?.color ??
                    LightcorePalette.mist,
                icon: Icons.home_work_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bonus.capped
                ? 'One or more mentee bonuses are currently capped.'
                : 'Current server bonus: ${bonus.experienceLabel}, ${bonus.combatLabel}, ${bonus.rewardLabel}. Home Tower resonance: ${controller.homeTowerMentorBonusLabel}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
