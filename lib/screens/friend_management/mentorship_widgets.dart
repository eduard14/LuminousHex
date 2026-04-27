part of '../friend_management_screen.dart';

class _MenteeListPanel extends StatelessWidget {
  const _MenteeListPanel({
    required this.overview,
    required this.onInspectProfile,
  });

  final LightcoreSocialOverview? overview;
  final ValueChanged<String> onInspectProfile;

  @override
  Widget build(BuildContext context) {
    final social = overview;
    if (social == null) {
      return AuroraPanel(
        tint: LightcorePalette.verdant,
        child: Text(
          'Sync social data to load mentees.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final directMentees = social.directMentees.toList(growable: false);
    final grandMentees = social.grandMentees.toList(growable: false);
    return AuroraPanel(
      tint: LightcorePalette.verdant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mentees',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _MiniBadge(
                label: '${directMentees.length} direct',
                tint: LightcorePalette.verdant,
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                label: '${grandMentees.length} next',
                tint: LightcorePalette.violet,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            directMentees.isEmpty && grandMentees.isEmpty
                ? 'No mentees connected yet.'
                : 'Direct mentees appear first. Next-level mentees remain visible for branch context.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (directMentees.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final mentee in directMentees) ...[
              _MenteeListCard(
                player: mentee,
                relationshipLabel: 'Mentee',
                tint: mentee.bonusActive
                    ? LightcorePalette.verdant
                    : LightcorePalette.solar,
                branchCount: social.childrenOf(mentee.uid).length,
                onInspectProfile: () => onInspectProfile(mentee.uid),
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (grandMentees.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Next Level', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final mentee in grandMentees) ...[
              _MenteeListCard(
                player: mentee,
                relationshipLabel: 'Grand-mentee',
                tint: mentee.withinLevelBand
                    ? LightcorePalette.violet
                    : LightcorePalette.warning,
                branchCount: social.childrenOf(mentee.uid).length,
                onInspectProfile: () => onInspectProfile(mentee.uid),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _MenteeListCard extends StatelessWidget {
  const _MenteeListCard({
    required this.player,
    required this.relationshipLabel,
    required this.tint,
    required this.branchCount,
    required this.onInspectProfile,
  });

  final LightcoreSocialPlayer player;
  final String relationshipLabel;
  final Color tint;
  final int branchCount;
  final VoidCallback onInspectProfile;

  @override
  Widget build(BuildContext context) {
    return _SocialCard(
      title: player.displayName,
      subtitle:
          '$relationshipLabel • ${player.levelLabel} • ${player.performanceLabel} • ${player.sharedRelayLabel}',
      tint: tint,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _MiniBadge(
            label: branchCount == 1 ? '1 branch' : '$branchCount branches',
            tint: LightcorePalette.aether,
          ),
          OutlinedButton.icon(
            onPressed: onInspectProfile,
            icon: const Icon(Icons.badge_rounded),
            label: const Text('Profile'),
          ),
        ],
      ),
    );
  }
}

class _MentorHexPanel extends StatelessWidget {
  const _MentorHexPanel({
    required this.controller,
    required this.overview,
    required this.focusedUid,
    required this.selectedProfileUid,
    required this.onFocusChanged,
    required this.onProfileSelected,
  });

  final LightcoreController controller;
  final LightcoreSocialOverview? overview;
  final String? focusedUid;
  final String? selectedProfileUid;
  final ValueChanged<String?> onFocusChanged;
  final ValueChanged<String> onProfileSelected;

  @override
  Widget build(BuildContext context) {
    final social = overview;
    if (social == null) {
      return AuroraPanel(
        tint: LightcorePalette.violet,
        child: Text(
          'Sync social data to load the mentee hex.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final focusedPlayer = _playerByUid(social, focusedUid) ?? social.self;
    final selectedPlayer =
        _playerByUid(social, selectedProfileUid) ?? focusedPlayer;
    final focusedMentor =
        social.mentor != null && focusedPlayer.uid == social.mentor!.uid;
    final children = focusedMentor
        ? <LightcoreSocialPlayer>[social.self]
        : social.childrenOf(focusedPlayer.uid);
    final grandchildren = focusedMentor
        ? social.directMentees
        : social.grandchildrenOf(focusedPlayer.uid);

    return AuroraPanel(
      tint: LightcorePalette.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  focusedPlayer.uid == social.self.uid
                      ? 'Mentorship Hex Map'
                      : focusedMentor
                      ? 'Mentor Tower Hex'
                      : '${focusedPlayer.displayName} Tower Hex',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (!focusedMentor && social.mentor != null)
                TextButton.icon(
                  onPressed: () => onFocusChanged(social.mentor!.uid),
                  icon: const Icon(Icons.keyboard_double_arrow_up_rounded),
                  label: const Text('Mentor Map'),
                ),
              if (focusedPlayer.uid != social.self.uid)
                TextButton.icon(
                  onPressed: () => onFocusChanged(null),
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: const Text('Your Map'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your profile stays at the core. The mentor map moves one level upward and keeps your branch attached below.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 430,
            child: _SocialHexMap(
              social: social,
              controller: controller,
              center: focusedPlayer,
              centerLabel: focusedPlayer.uid == social.self.uid
                  ? 'Your tower'
                  : focusedMentor
                  ? 'Mentor'
                  : 'Focus',
              children: children,
              grandchildren: grandchildren,
              mentor: focusedPlayer.uid == social.self.uid
                  ? social.mentor
                  : null,
              onTapPlayer: (player) => onProfileSelected(player.uid),
            ),
          ),
          const SizedBox(height: 14),
          _SocialPlayerProfilePanel(
            player: selectedPlayer,
            relationshipLabel: _relationshipLabel(social, selectedPlayer),
            branchCount: _branchCountFor(social, selectedPlayer),
            tower: _towerForPlayer(social, selectedPlayer),
          ),
        ],
      ),
    );
  }

  String _relationshipLabel(
    LightcoreSocialOverview overview,
    LightcoreSocialPlayer player,
  ) {
    if (player.uid == overview.self.uid) {
      return 'You';
    }
    if (overview.mentor?.uid == player.uid) {
      return 'Mentor';
    }
    if (overview.directMentees.any((mentee) => mentee.uid == player.uid)) {
      return 'Mentee';
    }
    if (overview.grandMentees.any((mentee) => mentee.uid == player.uid)) {
      return 'Grand-mentee';
    }
    return 'Profile';
  }

  int _branchCountFor(
    LightcoreSocialOverview overview,
    LightcoreSocialPlayer player,
  ) {
    if (overview.mentor?.uid == player.uid) {
      return 1;
    }
    return overview.childrenOf(player.uid).length;
  }

  FriendRelayTower? _towerForPlayer(
    LightcoreSocialOverview overview,
    LightcoreSocialPlayer player,
  ) {
    if (player.uid == overview.self.uid) {
      return controller.sharedRelayTower;
    }
    for (final profile in controller.friendRelayProfiles) {
      if (profile.playerId == player.uid ||
          profile.playerId == player.playerId) {
        return profile.sharedTower;
      }
    }
    return null;
  }

  LightcoreSocialPlayer? _playerByUid(
    LightcoreSocialOverview overview,
    String? uid,
  ) {
    if (uid == null || uid == overview.self.uid) {
      return overview.self;
    }
    for (final player in [
      if (overview.mentor != null) overview.mentor!,
      ...overview.directMentees,
      ...overview.grandMentees,
    ]) {
      if (player.uid == uid) {
        return player;
      }
    }
    return null;
  }
}

class _MentorStatusPanel extends StatelessWidget {
  const _MentorStatusPanel({
    required this.overview,
    required this.onInspectProfile,
    required this.onViewMentorMap,
  });

  final LightcoreSocialOverview? overview;
  final ValueChanged<String> onInspectProfile;
  final VoidCallback? onViewMentorMap;

  @override
  Widget build(BuildContext context) {
    final social = overview;
    if (social == null) {
      return AuroraPanel(
        tint: LightcorePalette.violet,
        child: Text(
          'Sync social data to load mentor details.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final mentor = social.mentor;
    return AuroraPanel(
      tint: LightcorePalette.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Mentor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            mentor == null
                ? 'No mentor linked yet. Your account can connect to one mentor.'
                : 'Your one mentor slot is linked to ${mentor.displayName}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (mentor == null)
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniBadge(label: 'No Mentor', tint: LightcorePalette.stroke),
                _MiniBadge(label: '0/1 Slot', tint: LightcorePalette.aether),
              ],
            )
          else ...[
            _SocialCard(
              title: mentor.displayName,
              subtitle:
                  '${mentor.levelLabel} • ${mentor.performanceLabel} • Player ${mentor.playerId}',
              tint: mentor.withinLevelBand
                  ? LightcorePalette.success
                  : LightcorePalette.warning,
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onInspectProfile(mentor.uid),
                    icon: const Icon(Icons.badge_rounded),
                    label: const Text('Profile'),
                  ),
                  FilledButton.icon(
                    onPressed: onViewMentorMap,
                    icon: const Icon(Icons.account_tree_rounded),
                    label: const Text('Map'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniBadge(label: '1/1 Mentor', tint: LightcorePalette.aether),
                _MiniBadge(
                  label: mentor.withinLevelBand ? 'In Band' : 'Out of Band',
                  tint: mentor.withinLevelBand
                      ? LightcorePalette.success
                      : LightcorePalette.warning,
                ),
                _MiniBadge(
                  label: mentor.sharedRelayLabel,
                  tint: LightcorePalette.verdant,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
