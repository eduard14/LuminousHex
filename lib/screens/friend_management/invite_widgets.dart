part of '../friend_management_screen.dart';

class _ShareInvitePanel extends StatelessWidget {
  const _ShareInvitePanel({
    required this.title,
    required this.description,
    required this.codeLabel,
    required this.code,
    required this.inviteUrl,
    required this.tint,
  });

  final String title;
  final String description;
  final String codeLabel;
  final String code;
  final String inviteUrl;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraPanel(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleLarge)),
              LightcoreInfoButton(
                title: '$title Help',
                message: description,
                tint: tint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final qrSize = compact ? 140.0 : 168.0;
              final fieldWidth = math.min(
                460.0,
                math.max(240.0, constraints.maxWidth),
              );

              return Wrap(
                spacing: compact ? 12 : 16,
                runSpacing: compact ? 12 : 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: tint.withValues(alpha: 0.18),
                          blurRadius: 18,
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: QrImageView(
                        data: inviteUrl,
                        version: QrVersions.auto,
                        size: qrSize,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: LightcorePalette.night,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: LightcorePalette.night,
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: fieldWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InviteLinkField(label: codeLabel, value: code),
                        const SizedBox(height: 10),
                        _InviteLinkField(
                          label: 'Invite Link',
                          value: inviteUrl,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _copyInviteValue(
                                context,
                                'Invite link',
                                inviteUrl,
                              ),
                              icon: const Icon(Icons.link_rounded),
                              label: const Text('Copy Link'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _copyInviteValue(context, codeLabel, code),
                              icon: const Icon(Icons.badge_rounded),
                              label: const Text('Copy Code'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IncomingInviteLinkPanel extends StatelessWidget {
  const _IncomingInviteLinkPanel({
    required this.invite,
    required this.busy,
    required this.onSendFriendRequest,
    required this.onAcceptMentorLink,
  });

  final LightcoreSocialInviteLink invite;
  final bool busy;
  final VoidCallback onSendFriendRequest;
  final VoidCallback onAcceptMentorLink;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isFriend = invite.kind == LightcoreSocialInviteLinkKind.friend;
    final tint = isFriend ? LightcorePalette.aether : LightcorePalette.violet;
    return AuroraPanel(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFriend ? 'Friend Link Ready' : 'Mentor Link Ready',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isFriend
                ? 'This link points to ${invite.target}. Send a friend request when you are ready.'
                : 'This link points to mentor ${invite.target}. Connect under that mentor when you are ready.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : isFriend
                    ? onSendFriendRequest
                    : onAcceptMentorLink,
                icon: Icon(
                  isFriend
                      ? Icons.person_add_alt_1_rounded
                      : Icons.school_rounded,
                ),
                label: Text(
                  isFriend ? 'Send Friend Request' : 'Use Mentor Link',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _copyInviteValue(context, 'Invite target', invite.target),
                icon: const Icon(Icons.badge_rounded),
                label: const Text('Copy Code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteLinkField extends StatelessWidget {
  const _InviteLinkField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: LightcorePalette.mist.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(value, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

void _copyInviteValue(BuildContext context, String label, String value) {
  unawaited(Clipboard.setData(ClipboardData(text: value)));
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text('$label copied.')));
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({
    required this.title,
    required this.description,
    required this.targetController,
    required this.busy,
    this.targetLabel = 'Player id or screen name',
    this.addMentorLabel = 'Use Mentor Link',
    this.onInviteMentee,
    this.onAddFriend,
    this.onAddMentor,
  });

  final String title;
  final String description;
  final TextEditingController targetController;
  final bool busy;
  final String targetLabel;
  final String addMentorLabel;
  final VoidCallback? onInviteMentee;
  final VoidCallback? onAddFriend;
  final VoidCallback? onAddMentor;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.solar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              LightcoreInfoButton(
                title: '$title Help',
                message: description,
                tint: LightcorePalette.solar,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: targetController,
            enabled: !busy,
            decoration: InputDecoration(
              filled: true,
              fillColor: LightcorePalette.panelRaised.withValues(alpha: 0.62),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: LightcorePalette.solar),
              ),
              labelText: targetLabel,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (onInviteMentee != null)
                FilledButton.icon(
                  onPressed: busy ? null : onInviteMentee,
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('Invite as Mentee'),
                ),
              if (onAddFriend != null)
                OutlinedButton.icon(
                  onPressed: busy ? null : onAddFriend,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add Friend'),
                ),
              if (onAddMentor != null)
                FilledButton.icon(
                  onPressed: busy ? null : onAddMentor,
                  icon: const Icon(Icons.link_rounded),
                  label: Text(addMentorLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
