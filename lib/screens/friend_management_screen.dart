import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/lightcore_global_chat.dart';
import '../models/lightcore_friend_state.dart';
import '../models/lightcore_social_invite_link.dart';
import '../models/lightcore_social_state.dart';
import '../services/lightcore_firebase_backend.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/lightcore_info_button.dart';
import '../widgets/meter_bar.dart';
import '../widgets/status_pill.dart';

part 'friend_management/overview_widgets.dart';
part 'friend_management/invite_widgets.dart';
part 'friend_management/mentorship_widgets.dart';
part 'friend_management/profile_widgets.dart';
part 'friend_management/gift_widgets.dart';
part 'friend_management/global_chat_widgets.dart';

enum FriendManagementSection { friends, mentees, mentors }

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({
    super.key,
    required this.controller,
    required this.backend,
    required this.isActive,
    this.section = FriendManagementSection.friends,
    this.initialInviteLink,
    this.scrollController,
  });

  final LightcoreController controller;
  final FirebaseLightcoreBackend backend;
  final bool isActive;
  final FriendManagementSection section;
  final LightcoreSocialInviteLink? initialInviteLink;
  final ScrollController? scrollController;

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _globalChatController = TextEditingController();
  LightcoreSocialOverview? _overview;
  LightcoreGlobalChatOverview? _globalChatOverview;
  String? _focusedUid;
  String? _selectedProfileUid;
  String? _globalChatError;
  String? _error;
  bool _initialInviteConsumed = false;
  bool _loading = false;
  bool _busy = false;
  bool _globalChatLoading = false;
  bool _globalChatSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      unawaited(_refreshSocial());
      unawaited(_refreshGlobalChat());
    }
  }

  @override
  void didUpdateWidget(covariant FriendManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && _overview == null) {
      unawaited(_refreshSocial());
    }
    if (!oldWidget.isActive && widget.isActive && _globalChatOverview == null) {
      unawaited(_refreshGlobalChat());
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    _globalChatController.dispose();
    super.dispose();
  }

  Future<void> _refreshGlobalChat() async {
    if (_globalChatLoading) {
      return;
    }
    setState(() {
      _globalChatLoading = true;
      _globalChatError = null;
    });
    try {
      final overview = await widget.backend.fetchGlobalChat();
      if (!mounted) {
        return;
      }
      setState(() => _globalChatOverview = overview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalChatError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _globalChatLoading = false);
      }
    }
  }

  Future<void> _sendGlobalChatMessage({String? whisperTargetUid}) async {
    if (_globalChatSending) {
      return;
    }
    var message = _globalChatController.text.trim();
    if (message.isEmpty) {
      setState(() => _globalChatError = 'Enter a message first.');
      return;
    }
    final whisperMatch = RegExp(
      r'^/w\s+([A-Za-z0-9:_-]+)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(message);
    final parsedWhisperTargetUid =
        whisperTargetUid ?? whisperMatch?.group(1)?.trim();
    if (whisperMatch != null) {
      message = whisperMatch.group(2)?.trim() ?? '';
    }
    setState(() {
      _globalChatSending = true;
      _globalChatError = null;
    });
    try {
      final overview = await widget.backend.sendGlobalChatMessage(
        message: message,
        whisperTargetUid: parsedWhisperTargetUid,
      );
      if (!mounted) {
        return;
      }
      _globalChatController.clear();
      setState(() {
        _globalChatOverview = overview;
        _globalChatError = overview.warningMessage;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _globalChatError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _globalChatSending = false);
      }
    }
  }

  Future<void> _refreshSocial() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await widget.backend.fetchSocialOverview();
      if (!mounted) {
        return;
      }
      widget.controller.syncSocialOverview(overview);
      setState(() => _overview = overview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runSocialAction(
    Future<LightcoreSocialOverview> Function() action, {
    bool clearInitialInvite = false,
  }) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final overview = await action();
      if (!mounted) {
        return;
      }
      widget.controller.syncSocialOverview(overview, showBanner: true);
      setState(() {
        _overview = overview;
        if (clearInitialInvite) {
          _initialInviteConsumed = true;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _claimBossGift(String fromUid) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final claim = await widget.backend.claimBossPullGift(fromUid: fromUid);
      if (!mounted) {
        return;
      }
      widget.controller.applySocialBossGiftClaim(claim);
      setState(() => _overview = claim.overview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendAllBossGifts() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final send = await widget.backend.sendAllBossPullGifts();
      if (!mounted) {
        return;
      }
      widget.controller.applySocialBossGiftSend(send);
      setState(() => _overview = send.overview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _claimAllBossGifts() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final claim = await widget.backend.claimAllBossPullGifts();
      if (!mounted) {
        return;
      }
      widget.controller.applySocialBossGiftClaim(claim);
      setState(() => _overview = claim.overview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendMentorInvite({String? targetOverride}) async {
    final target = _normalizeTargetInput(
      targetOverride ?? _targetController.text,
    );
    if (target.isEmpty) {
      setState(
        () => _error = 'Enter a player id, screen name, or player link first.',
      );
      return;
    }
    await _runSocialAction(
      () => widget.backend.sendMentorInvite(target: target),
    );
  }

  Future<void> _sendFriendRequest({String? targetOverride}) async {
    final target = _normalizeTargetInput(
      targetOverride ?? _targetController.text,
    );
    if (target.isEmpty) {
      setState(
        () => _error = 'Enter a player id, screen name, or invite link first.',
      );
      return;
    }
    await _runSocialAction(
      () => widget.backend.sendFriendRequest(target: target),
    );
  }

  Future<void> _acceptMentorLink({String? targetOverride}) async {
    final mentor = _normalizeTargetInput(
      targetOverride ?? _targetController.text,
    );
    if (mentor.isEmpty) {
      setState(
        () => _error = 'Enter a mentor player id, screen name, or link first.',
      );
      return;
    }
    await _runSocialAction(
      () => widget.backend.acceptMentorLink(mentor: mentor),
    );
  }

  String _normalizeTargetInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final invite = LightcoreSocialInviteLink.maybeFromUri(uri);
      if (invite != null && invite.target.isNotEmpty) {
        return invite.target;
      }
    }
    return trimmed;
  }

  LightcoreSocialInviteLink? get _activeInitialInviteLink {
    final invite = widget.initialInviteLink;
    if (invite == null || _initialInviteConsumed) {
      return null;
    }
    return switch (widget.section) {
      FriendManagementSection.friends
          when invite.kind == LightcoreSocialInviteLinkKind.friend =>
        invite,
      FriendManagementSection.mentees || FriendManagementSection.mentors
          when invite.kind == LightcoreSocialInviteLinkKind.mentor =>
        invite,
      _ => null,
    };
  }

  String _shareInviteUrl(LightcoreSocialInviteLinkKind kind) {
    final fallbackHost = widget.backend.runtimeConfig.webAuthDomain.trim();
    return buildLightcoreSocialInviteUrl(
      currentUri: Uri.base,
      fallbackHost: fallbackHost.isEmpty
          ? '${widget.backend.runtimeConfig.projectId}.firebaseapp.com'
          : fallbackHost,
      kind: kind,
      target: widget.controller.playerId,
    );
  }

  List<Widget> _sectionPanels(LightcoreSocialOverview? overview) {
    final initialInvite = _activeInitialInviteLink;
    return switch (widget.section) {
      FriendManagementSection.friends => [
        _GlobalChatPanel(
          controller: _globalChatController,
          overview: _globalChatOverview,
          error: _globalChatError,
          loading: _globalChatLoading,
          sending: _globalChatSending,
          onRefresh: () => unawaited(_refreshGlobalChat()),
          onSend: () => unawaited(_sendGlobalChatMessage()),
        ),
        const SizedBox(height: 14),
        const _GuildsComingSoonPanel(),
        const SizedBox(height: 14),
        if (initialInvite != null) ...[
          _IncomingInviteLinkPanel(
            invite: initialInvite,
            busy: _busy,
            onSendFriendRequest: () => unawaited(
              _runSocialAction(
                () => widget.backend.sendFriendRequest(
                  target: initialInvite.target,
                ),
                clearInitialInvite: true,
              ),
            ),
            onAcceptMentorLink: () => unawaited(
              _runSocialAction(
                () => widget.backend.acceptMentorLink(
                  mentor: initialInvite.target,
                ),
                clearInitialInvite: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _ShareInvitePanel(
          title: 'Your Friend QR',
          description:
              'Share this QR or link so another player can send you a friend request. You still choose whether to accept it.',
          codeLabel: 'Friend Code',
          code: widget.controller.playerId,
          inviteUrl: _shareInviteUrl(LightcoreSocialInviteLinkKind.friend),
          tint: LightcorePalette.aether,
        ),
        const SizedBox(height: 14),
        _InvitePanel(
          title: 'Add Friend Manually',
          description:
              'Use a player id, screen name, or pasted friend link. Friend requests unlock daily Threat Scan gifts.',
          targetController: _targetController,
          busy: _busy,
          targetLabel: 'Player id, screen name, or friend link',
          onAddFriend: () => unawaited(_sendFriendRequest()),
        ),
        const SizedBox(height: 14),
        _InviteQueuePanel(
          title: 'Friend Requests',
          emptyText: 'No pending friend requests.',
          overview: overview,
          busy: _busy,
          kind: LightcoreSocialInviteKind.friend,
          onRespondMentor: _respondMentorInvite,
          onRespondFriend: _respondFriendRequest,
        ),
        const SizedBox(height: 14),
        _FriendGiftPanel(
          overview: overview,
          busy: _busy,
          onSendGift: (friendUid) => unawaited(
            _runSocialAction(
              () => widget.backend.sendBossPullGift(friendUid: friendUid),
            ),
          ),
          onSendAllGifts: () => unawaited(_sendAllBossGifts()),
          onClaimGift: (friendUid) => unawaited(_claimBossGift(friendUid)),
          onClaimAllGifts: () => unawaited(_claimAllBossGifts()),
        ),
      ],
      FriendManagementSection.mentees || FriendManagementSection.mentors =>
        _mentorshipPanels(overview, initialInvite),
    };
  }

  List<Widget> _mentorshipPanels(
    LightcoreSocialOverview? overview,
    LightcoreSocialInviteLink? initialInvite,
  ) {
    final hasMentor = overview?.mentor != null;
    return [
      _MentorStatusPanel(
        overview: overview,
        onInspectProfile: (uid) => setState(() => _selectedProfileUid = uid),
        onViewMentorMap: overview?.mentor == null
            ? null
            : () => setState(() => _focusedUid = overview!.mentor!.uid),
      ),
      const SizedBox(height: 14),
      if (initialInvite != null) ...[
        _IncomingInviteLinkPanel(
          invite: initialInvite,
          busy: _busy || hasMentor,
          onSendFriendRequest: () => unawaited(
            _runSocialAction(
              () => widget.backend.sendFriendRequest(
                target: initialInvite.target,
              ),
              clearInitialInvite: true,
            ),
          ),
          onAcceptMentorLink: () => unawaited(
            _runSocialAction(
              () =>
                  widget.backend.acceptMentorLink(mentor: initialInvite.target),
              clearInitialInvite: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      if (!hasMentor) ...[
        _InvitePanel(
          title: 'Add Mentor Manually',
          description:
              'Use one mentor player id, screen name, QR link, or invite link to connect upward.',
          targetController: _targetController,
          busy: _busy,
          targetLabel: 'Mentor player id, screen name, or link',
          onAddMentor: () => unawaited(_acceptMentorLink()),
          addMentorLabel: 'Add Mentor',
        ),
        const SizedBox(height: 14),
      ],
      _BonusPanel(controller: widget.controller, overview: overview),
      const SizedBox(height: 14),
      _MenteeListPanel(
        overview: overview,
        onInspectProfile: (uid) => setState(() => _selectedProfileUid = uid),
      ),
      const SizedBox(height: 14),
      _MentorHexPanel(
        controller: widget.controller,
        overview: overview,
        focusedUid: _focusedUid,
        selectedProfileUid: _selectedProfileUid,
        onFocusChanged: (uid) => setState(() => _focusedUid = uid),
        onProfileSelected: (uid) => setState(() => _selectedProfileUid = uid),
      ),
      const SizedBox(height: 14),
      _ShareInvitePanel(
        title: 'Your Mentor QR',
        description:
            'Share this QR or link with a player who wants you as their mentor.',
        codeLabel: 'Mentor Code',
        code: widget.controller.playerId,
        inviteUrl: _shareInviteUrl(LightcoreSocialInviteLinkKind.mentor),
        tint: LightcorePalette.verdant,
      ),
      const SizedBox(height: 14),
      _InvitePanel(
        title: 'Invite Mentee Manually',
        description:
            'Use a player id, screen name, or pasted player link. Mentor invites make you their mentor after they accept.',
        targetController: _targetController,
        busy: _busy,
        targetLabel: 'Player id, screen name, or player link',
        onInviteMentee: () => unawaited(_sendMentorInvite()),
      ),
      const SizedBox(height: 14),
      _InviteQueuePanel(
        title: 'Mentor Invites',
        emptyText: 'No pending mentor or mentee invites.',
        overview: overview,
        busy: _busy,
        kind: LightcoreSocialInviteKind.mentor,
        onRespondMentor: _respondMentorInvite,
        onRespondFriend: _respondFriendRequest,
      ),
      const SizedBox(height: 14),
      _SharedRelaySummary(controller: widget.controller),
    ];
  }

  void _respondMentorInvite(LightcoreSocialInvite invite, bool accept) {
    unawaited(
      _runSocialAction(
        () => widget.backend.respondMentorInvite(
          inviteId: invite.id,
          accept: accept,
        ),
      ),
    );
  }

  void _respondFriendRequest(LightcoreSocialInvite invite, bool accept) {
    unawaited(
      _runSocialAction(
        () => widget.backend.respondFriendRequest(
          requestId: invite.id,
          accept: accept,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final overview = widget.controller.socialOverview ?? _overview;

        return ListView(
          key: PageStorageKey<String>('social-${widget.section.name}-scroll'),
          controller: widget.scrollController,
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _SocialOverviewPanel(
              section: widget.section,
              overview: overview,
              error: _error,
              loading: _loading,
              onRefresh: () => unawaited(_refreshSocial()),
            ),
            const SizedBox(height: 14),
            ..._sectionPanels(overview),
          ],
        );
      },
    );
  }
}
