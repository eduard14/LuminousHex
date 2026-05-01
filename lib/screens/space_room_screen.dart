import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../data/equipment_configs.dart';
import '../models/lightcore_guide.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../state/lightcore_controller.dart';
import '../theme/lightcore_palette.dart';
import '../widgets/aurora_panel.dart';
import '../widgets/cosmic_guide_avatar.dart';

class SpaceRoomScreen extends StatefulWidget {
  const SpaceRoomScreen({
    super.key,
    required this.controller,
    required this.isActive,
    this.scrollController,
  });

  final LightcoreController controller;
  final bool isActive;
  final ScrollController? scrollController;

  @override
  State<SpaceRoomScreen> createState() => _SpaceRoomScreenState();
}

class _SpaceRoomScreenState extends State<SpaceRoomScreen>
    with SingleTickerProviderStateMixin {
  static const String _localPlayerId = 'local-player';
  static const String _channelChatTarget = 'channel';
  static const double _occupantRadius = 0.048;
  static const double _localSpeed = 0.26;
  static const double _boostMultiplier = 2.05;
  static const List<_SpaceRoomConfig> _roomConfigs = [
    _SpaceRoomConfig(
      id: 'aurora-drift',
      label: 'Aurora Drift',
      capacity: 8,
      tint: LightcorePalette.aether,
      seed: 11,
    ),
    _SpaceRoomConfig(
      id: 'prism-lounge',
      label: 'Prism Lounge',
      capacity: 6,
      tint: LightcorePalette.violet,
      seed: 23,
    ),
    _SpaceRoomConfig(
      id: 'flare-ring',
      label: 'Flare Ring',
      capacity: 5,
      tint: LightcorePalette.flare,
      seed: 37,
    ),
    _SpaceRoomConfig(
      id: 'manager-orbit',
      label: 'Manager Orbit',
      capacity: 8,
      tint: LightcorePalette.verdant,
      seed: 47,
    ),
  ];

  static const List<String> _managerPlaceholders = [
    'Whitney Stardust',
    'Reddie Mercury',
    'Yella Nova',
    'Greta Greenlight',
    'Violet Vortex',
    'Orion Orange',
    'Blueshift Aldrin',
  ];

  static const List<String> _playerPlaceholders = [
    'Astra Vale',
    'Flux Ryder',
    'Nova Penn',
    'Hex Mira',
    'Ion Jace',
    'Kira Beam',
    'Sol Riven',
    'Echo Prism',
  ];

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final math.Random _random = math.Random(1042);
  late final Ticker _ticker;
  late final List<_SpaceChannelRuntime> _channels;

  Duration _lastTick = Duration.zero;
  String _selectedChannelId = _roomConfigs.first.id;
  String _joinedChannelId = _roomConfigs.first.id;
  String _chatTargetId = _channelChatTarget;
  Offset _joystickVector = Offset.zero;
  bool _boosting = false;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _channels = _createInitialChannels();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(covariant SpaceRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
    if (oldWidget.isActive && !widget.isActive) {
      _joystickVector = Offset.zero;
      _boosting = false;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  List<_SpaceChannelRuntime> _createInitialChannels() {
    final channels = <_SpaceChannelRuntime>[];
    for (final config in _roomConfigs) {
      final channel = _SpaceChannelRuntime(
        config: config,
        occupants: _seedOccupantsFor(config),
        messages: <_SpaceChatMessage>[
          _SpaceChatMessage.system(
            text:
                '${config.label} opened with ${config.capacity} active orbit slots.',
          ),
        ],
      );
      channels.add(channel);
    }

    channels.first.occupants.insert(0, _createLocalOccupant());
    return channels;
  }

  List<_SpaceOccupant> _seedOccupantsFor(_SpaceRoomConfig config) {
    final random = math.Random(config.seed);
    final reservedSlots = config.id == _roomConfigs.first.id ? 1 : 0;
    final fillCount = switch (config.id) {
      'aurora-drift' => 4,
      'prism-lounge' => config.capacity,
      'flare-ring' => 2,
      'manager-orbit' => 6,
      _ => 3,
    };
    final count = math.min(fillCount, config.capacity - reservedSlots);
    return List<_SpaceOccupant>.generate(count, (index) {
      final manager = config.id == 'manager-orbit' || index.isEven;
      final label = manager
          ? _managerPlaceholders[index % _managerPlaceholders.length]
          : _playerPlaceholders[index % _playerPlaceholders.length];
      final equipmentSet = EquipmentLibrary
          .all[(config.seed + index) % EquipmentLibrary.all.length];
      return _SpaceOccupant(
        id: '${config.id}-$index',
        label: label,
        role: manager ? _SpaceOccupantRole.manager : _SpaceOccupantRole.player,
        guide: _guideForOccupant(index, manager: manager),
        equipmentLoadout: CosmicEquipmentLoadout.preview(
          setId: equipmentSet.id,
          affinity: equipmentSet.affinity,
          seed: config.seed + index,
          manager: manager,
        ),
        tint: _tintForIndex(index, manager: manager),
        position: Offset(
          0.16 + random.nextDouble() * 0.68,
          0.18 + random.nextDouble() * 0.62,
        ),
        velocity: _randomVelocity(random, manager ? 0.055 : 0.075),
        rotation: random.nextDouble() * math.pi * 2,
        angularVelocity: (random.nextDouble() - 0.5) * 1.8,
      );
    });
  }

  _SpaceOccupant _createLocalOccupant() {
    return _SpaceOccupant(
      id: _localPlayerId,
      label: widget.controller.playerDisplayName,
      role: _SpaceOccupantRole.localPlayer,
      guide: widget.controller.guideProfile,
      equipmentLoadout: _currentEquipmentLoadout(),
      tint: LightcorePalette.aether,
      position: const Offset(0.5, 0.58),
      velocity: Offset.zero,
      rotation: 0,
      angularVelocity: 0.9,
    );
  }

  CosmicEquipmentLoadout _currentEquipmentLoadout() {
    return CosmicEquipmentLoadout.fromItems(<PlayerEquipmentItem?>[
      for (final slot in EquipmentLoadoutSlot.values)
        widget.controller.equippedPlayerItemForSlot(slot),
    ]);
  }

  static LightcoreGuideProfile _guideForOccupant(
    int index, {
    required bool manager,
  }) {
    if (manager) {
      return index.isEven
          ? LightcoreGuideProfile.luma
          : LightcoreGuideProfile.lumo;
    }
    return index.isEven
        ? LightcoreGuideProfile.lumo
        : LightcoreGuideProfile.luma;
  }

  static Offset _randomVelocity(math.Random random, double speed) {
    final angle = random.nextDouble() * math.pi * 2;
    final magnitude = speed * (0.55 + random.nextDouble() * 0.7);
    return Offset(math.cos(angle), math.sin(angle)) * magnitude;
  }

  static Color _tintForIndex(int index, {required bool manager}) {
    final colors = manager
        ? const [
            LightcorePalette.verdant,
            LightcorePalette.solar,
            LightcorePalette.violet,
            LightcorePalette.aether,
          ]
        : const [
            LightcorePalette.flare,
            LightcorePalette.aether,
            LightcorePalette.warning,
            LightcorePalette.layer2,
          ];
    return colors[index % colors.length];
  }

  _SpaceChannelRuntime get _selectedChannel => _channels.firstWhere(
    (channel) => channel.config.id == _selectedChannelId,
  );

  _SpaceChannelRuntime get _joinedChannel =>
      _channels.firstWhere((channel) => channel.config.id == _joinedChannelId);

  bool get _localIsInSelectedChannel => _selectedChannelId == _joinedChannelId;

  _SpaceOccupant? get _localOccupant {
    for (final occupant in _joinedChannel.occupants) {
      if (occupant.id == _localPlayerId) {
        return occupant;
      }
    }
    return null;
  }

  void _tick(Duration elapsed) {
    if (!widget.isActive || !mounted) {
      return;
    }
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == Duration.zero) {
      return;
    }
    final dt = math.min(
      (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond,
      0.05,
    );
    if (dt <= 0) {
      return;
    }

    _phase += dt;
    for (final channel in _channels) {
      _advanceChannel(channel, dt);
    }
    setState(() {});
  }

  void _advanceChannel(_SpaceChannelRuntime channel, double dt) {
    for (final occupant in channel.occupants) {
      if (occupant.id == _localPlayerId) {
        final boost = _boosting && channel.config.id == _joinedChannelId
            ? _boostMultiplier
            : 1.0;
        final targetVelocity = _joystickVector * _localSpeed * boost;
        occupant.velocity = Offset.lerp(
          occupant.velocity,
          targetVelocity,
          1 - math.pow(0.002, dt).toDouble(),
        )!;
        occupant.angularVelocity = _joystickVector.distance > 0.08
            ? 1.8 * boost
            : 0.7;
      } else {
        final wave = math.sin(_phase * 0.8 + occupant.position.dx * 8);
        occupant.velocity += Offset(wave, -wave) * 0.0025 * dt;
      }

      occupant.position += occupant.velocity * dt;
      occupant.rotation += occupant.angularVelocity * dt;
      _bounceOccupant(occupant);
    }
    _resolveBumps(channel.occupants);
  }

  void _bounceOccupant(_SpaceOccupant occupant) {
    var x = occupant.position.dx;
    var y = occupant.position.dy;
    var vx = occupant.velocity.dx;
    var vy = occupant.velocity.dy;
    const min = _occupantRadius;
    const max = 1 - _occupantRadius;

    if (x < min) {
      x = min;
      vx = vx.abs() * 0.86;
    } else if (x > max) {
      x = max;
      vx = -vx.abs() * 0.86;
    }
    if (y < min) {
      y = min;
      vy = vy.abs() * 0.86;
    } else if (y > max) {
      y = max;
      vy = -vy.abs() * 0.86;
    }

    occupant.position = Offset(x, y);
    occupant.velocity = Offset(vx, vy);
  }

  void _resolveBumps(List<_SpaceOccupant> occupants) {
    const minDistance = _occupantRadius * 2.15;
    for (var a = 0; a < occupants.length; a++) {
      for (var b = a + 1; b < occupants.length; b++) {
        final first = occupants[a];
        final second = occupants[b];
        var delta = second.position - first.position;
        var distance = delta.distance;
        if (distance <= 0.0001) {
          delta = Offset(
            _random.nextDouble() - 0.5,
            _random.nextDouble() - 0.5,
          );
          distance = delta.distance;
        }
        if (distance >= minDistance) {
          continue;
        }

        final normal = delta / distance;
        final overlap = (minDistance - distance) * 0.5;
        first.position -= normal * overlap;
        second.position += normal * overlap;

        final firstVelocity = first.velocity;
        final secondVelocity = second.velocity;
        first.velocity = Offset.lerp(firstVelocity, -normal * 0.12, 0.42)!;
        second.velocity = Offset.lerp(secondVelocity, normal * 0.12, 0.42)!;
        first.angularVelocity -= 0.28;
        second.angularVelocity += 0.28;
        _bounceOccupant(first);
        _bounceOccupant(second);
      }
    }
  }

  void _selectChannel(String channelId) {
    if (_selectedChannelId == channelId) {
      return;
    }
    setState(() {
      _selectedChannelId = channelId;
      _chatTargetId = _channelChatTarget;
    });
  }

  void _joinSelectedChannel() {
    final target = _selectedChannel;
    if (_localIsInSelectedChannel || target.isFull) {
      return;
    }

    final local = _localOccupant ?? _createLocalOccupant();
    _joinedChannel.occupants.removeWhere((occupant) => occupant.id == local.id);
    local
      ..label = widget.controller.playerDisplayName
      ..guide = widget.controller.guideProfile
      ..equipmentLoadout = _currentEquipmentLoadout()
      ..position = Offset(0.34 + _random.nextDouble() * 0.32, 0.44)
      ..velocity = Offset.zero;
    target.occupants.insert(0, local);
    target.messages.add(
      _SpaceChatMessage.system(
        text: '${local.label} joined ${target.config.label}.',
      ),
    );
    _trimMessages(target);
    setState(() {
      _joinedChannelId = target.config.id;
      _chatTargetId = _channelChatTarget;
      _joystickVector = Offset.zero;
      _boosting = false;
    });
    _scrollChatToBottom();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty || !_localIsInSelectedChannel) {
      return;
    }

    final channel = _selectedChannel;
    final target = _chatTargetId == _channelChatTarget
        ? null
        : channel.occupants
              .where((occupant) => occupant.id == _chatTargetId)
              .firstOrNull;
    channel.messages.add(
      _SpaceChatMessage(
        id: '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(999)}',
        authorId: _localPlayerId,
        authorLabel: widget.controller.playerDisplayName,
        text: text,
        createdAt: DateTime.now(),
        targetId: target?.id,
        targetLabel: target?.label,
      ),
    );
    _trimMessages(channel);
    _chatController.clear();
    setState(() {});
    _scrollChatToBottom();
  }

  void _trimMessages(_SpaceChannelRuntime channel) {
    if (channel.messages.length <= 60) {
      return;
    }
    channel.messages.removeRange(0, channel.messages.length - 60);
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) {
        return;
      }
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _setBoosting(bool boosting) {
    if (_boosting == boosting || !_localIsInSelectedChannel) {
      return;
    }
    setState(() => _boosting = boosting);
  }

  void _setJoystickVector(Offset vector) {
    if (!_localIsInSelectedChannel) {
      return;
    }
    setState(() => _joystickVector = vector);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    final local = _localOccupant;
    if (local != null) {
      local
        ..label = widget.controller.playerDisplayName
        ..guide = widget.controller.guideProfile
        ..equipmentLoadout = _currentEquipmentLoadout();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        if (wide) {
          return _buildWideLayout(context);
        }
        return _buildCompactLayout(context, constraints);
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChannelRail(
          channels: _channels,
          selectedChannelId: _selectedChannelId,
          joinedChannelId: _joinedChannelId,
          onSelected: _selectChannel,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SpaceArenaPanel(
                  channel: _selectedChannel,
                  joined: _localIsInSelectedChannel,
                  boosting: _boosting,
                  joystickVector: _joystickVector,
                  phase: _phase,
                  onJoin: _joinSelectedChannel,
                  onBoostChanged: _setBoosting,
                  onJoystickChanged: _setJoystickVector,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RosterPanel(
                      channel: _selectedChannel,
                      localPlayerId: _localPlayerId,
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildChatPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context, BoxConstraints constraints) {
    final arenaHeight = math.min(
      420.0,
      math.max(286.0, constraints.maxWidth * 0.74),
    );
    return ListView(
      key: const PageStorageKey<String>('space-room-scroll'),
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      children: [
        _ChannelRail(
          channels: _channels,
          selectedChannelId: _selectedChannelId,
          joinedChannelId: _joinedChannelId,
          onSelected: _selectChannel,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: arenaHeight,
          child: _SpaceArenaPanel(
            channel: _selectedChannel,
            joined: _localIsInSelectedChannel,
            boosting: _boosting,
            joystickVector: _joystickVector,
            phase: _phase,
            onJoin: _joinSelectedChannel,
            onBoostChanged: _setBoosting,
            onJoystickChanged: _setJoystickVector,
          ),
        ),
        const SizedBox(height: 12),
        _RosterPanel(channel: _selectedChannel, localPlayerId: _localPlayerId),
        const SizedBox(height: 12),
        SizedBox(height: 380, child: _buildChatPanel()),
      ],
    );
  }

  Widget _buildChatPanel() {
    final channel = _selectedChannel;
    final occupants = channel.occupants
        .where((occupant) => occupant.id != _localPlayerId)
        .toList(growable: false);
    final targetStillPresent =
        _chatTargetId == _channelChatTarget ||
        occupants.any((occupant) => occupant.id == _chatTargetId);
    if (!targetStillPresent) {
      _chatTargetId = _channelChatTarget;
    }

    return _ChatPanel(
      channel: channel,
      controller: _chatController,
      scrollController: _chatScrollController,
      enabled: _localIsInSelectedChannel,
      chatTargetId: _chatTargetId,
      targetOccupants: occupants,
      onTargetChanged: (value) =>
          setState(() => _chatTargetId = value ?? _channelChatTarget),
      onSubmitted: (_) => _sendChat(),
      onSend: _sendChat,
    );
  }
}

class _SpaceRoomConfig {
  const _SpaceRoomConfig({
    required this.id,
    required this.label,
    required this.capacity,
    required this.tint,
    required this.seed,
  });

  final String id;
  final String label;
  final int capacity;
  final Color tint;
  final int seed;
}

class _SpaceChannelRuntime {
  _SpaceChannelRuntime({
    required this.config,
    required this.occupants,
    required this.messages,
  });

  final _SpaceRoomConfig config;
  final List<_SpaceOccupant> occupants;
  final List<_SpaceChatMessage> messages;

  int get occupancy => occupants.length;
  bool get isFull => occupancy >= config.capacity;
}

enum _SpaceOccupantRole { localPlayer, player, manager }

class _SpaceOccupant {
  _SpaceOccupant({
    required this.id,
    required this.label,
    required this.role,
    required this.guide,
    required this.equipmentLoadout,
    required this.tint,
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.angularVelocity,
  });

  final String id;
  String label;
  final _SpaceOccupantRole role;
  LightcoreGuideProfile guide;
  CosmicEquipmentLoadout equipmentLoadout;
  final Color tint;
  Offset position;
  Offset velocity;
  double rotation;
  double angularVelocity;

  bool get isLocal => role == _SpaceOccupantRole.localPlayer;
  bool get isManager => role == _SpaceOccupantRole.manager;
}

class _SpaceChatMessage {
  const _SpaceChatMessage({
    required this.id,
    required this.authorId,
    required this.authorLabel,
    required this.text,
    required this.createdAt,
    this.targetId,
    this.targetLabel,
    this.system = false,
  });

  factory _SpaceChatMessage.system({required String text}) {
    return _SpaceChatMessage(
      id: 'system-${DateTime.now().microsecondsSinceEpoch}',
      authorId: 'system',
      authorLabel: 'Room',
      text: text,
      createdAt: DateTime.now(),
      system: true,
    );
  }

  final String id;
  final String authorId;
  final String authorLabel;
  final String text;
  final DateTime createdAt;
  final String? targetId;
  final String? targetLabel;
  final bool system;

  bool get isWhisper => targetId != null;
}

class _ChannelRail extends StatelessWidget {
  const _ChannelRail({
    required this.channels,
    required this.selectedChannelId,
    required this.joinedChannelId,
    required this.onSelected,
  });

  final List<_SpaceChannelRuntime> channels;
  final String selectedChannelId;
  final String joinedChannelId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final channel in channels) ...[
              _ChannelChip(
                channel: channel,
                selected: channel.config.id == selectedChannelId,
                joined: channel.config.id == joinedChannelId,
                onTap: () => onSelected(channel.config.id),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.channel,
    required this.selected,
    required this.joined,
    required this.onTap,
  });

  final _SpaceChannelRuntime channel;
  final bool selected;
  final bool joined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = channel.config.tint;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        joined
            ? Icons.radio_button_checked_rounded
            : channel.isFull
            ? Icons.lock_rounded
            : Icons.public_rounded,
        size: 18,
        color: selected ? LightcorePalette.night : tint,
      ),
      label: Text(
        '${channel.config.label} ${channel.occupancy}/${channel.config.capacity}',
      ),
      labelStyle: TextStyle(
        color: selected ? LightcorePalette.night : LightcorePalette.mist,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: tint,
      backgroundColor: LightcorePalette.panelRaised.withValues(alpha: 0.72),
      side: BorderSide(
        color: selected ? tint : LightcorePalette.stroke.withValues(alpha: 0.7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _SpaceArenaPanel extends StatelessWidget {
  const _SpaceArenaPanel({
    required this.channel,
    required this.joined,
    required this.boosting,
    required this.joystickVector,
    required this.phase,
    required this.onJoin,
    required this.onBoostChanged,
    required this.onJoystickChanged,
  });

  final _SpaceChannelRuntime channel;
  final bool joined;
  final bool boosting;
  final Offset joystickVector;
  final double phase;
  final VoidCallback onJoin;
  final ValueChanged<bool> onBoostChanged;
  final ValueChanged<Offset> onJoystickChanged;

  @override
  Widget build(BuildContext context) {
    final tint = channel.config.tint;
    return AuroraPanel(
      tint: tint,
      radius: 24,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpaceRoomPainter(
                  channel: channel,
                  localPlayerId: _SpaceRoomScreenState._localPlayerId,
                  boosting: boosting,
                  phase: phase,
                ),
              ),
            ),
            Positioned.fill(
              child: _SpaceOccupantLayer(
                channel: channel,
                phase: phase,
                boosting: boosting,
                localPlayerId: _SpaceRoomScreenState._localPlayerId,
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: _RoomStatusBar(channel: channel, joined: joined),
            ),
            if (!joined)
              Positioned.fill(
                child: _JoinRoomOverlay(
                  channel: channel,
                  onJoin: channel.isFull ? null : onJoin,
                ),
              ),
            if (joined) ...[
              Positioned(
                left: 16,
                bottom: 16,
                child: _JoystickPad(
                  value: joystickVector,
                  onChanged: onJoystickChanged,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 20,
                child: _BoostButton(
                  active: boosting,
                  onChanged: onBoostChanged,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpaceOccupantLayer extends StatelessWidget {
  const _SpaceOccupantLayer({
    required this.channel,
    required this.phase,
    required this.boosting,
    required this.localPlayerId,
  });

  final _SpaceChannelRuntime channel;
  final double phase;
  final bool boosting;
  final String localPlayerId;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final baseRadius = math.min(size.width, size.height) * 0.045;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final occupant in channel.occupants)
                _SpaceOccupantAvatar(
                  occupant: occupant,
                  phase: phase,
                  boosting: boosting && occupant.id == localPlayerId,
                  baseRadius: baseRadius,
                  roomSize: size,
                  local: occupant.id == localPlayerId,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SpaceOccupantAvatar extends StatelessWidget {
  const _SpaceOccupantAvatar({
    required this.occupant,
    required this.phase,
    required this.boosting,
    required this.baseRadius,
    required this.roomSize,
    required this.local,
  });

  final _SpaceOccupant occupant;
  final double phase;
  final bool boosting;
  final double baseRadius;
  final Size roomSize;
  final bool local;

  @override
  Widget build(BuildContext context) {
    final center = Offset(
      occupant.position.dx * roomSize.width,
      occupant.position.dy * roomSize.height,
    );
    final occupantRadius = local ? baseRadius * 1.12 : baseRadius;
    final avatarSize = occupantRadius * 4.35;
    final label = local ? 'You' : occupant.label;
    final labelWidth = local ? 70.0 : 104.0;
    final labelLeft = (center.dx - labelWidth / 2)
        .clamp(4.0, math.max(4.0, roomSize.width - labelWidth - 4))
        .toDouble();
    final labelTop = (center.dy + avatarSize * 0.36)
        .clamp(4.0, math.max(4.0, roomSize.height - 26))
        .toDouble();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: center.dx - avatarSize / 2,
          top: center.dy - avatarSize / 2,
          width: avatarSize,
          height: avatarSize,
          child: Transform.rotate(
            angle: occupant.rotation * 0.08,
            child: CosmicGuideAvatar(
              guide: occupant.guide,
              loadout: occupant.equipmentLoadout,
              phase: phase + (occupant.id.hashCode * 0.001),
              boosting: boosting,
              size: avatarSize,
              semanticLabel: occupant.label,
            ),
          ),
        ),
        Positioned(
          left: labelLeft,
          top: labelTop,
          width: labelWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LightcorePalette.night.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: LightcorePalette.mist.withValues(alpha: 0.88),
                  fontSize: local ? 12 : 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomStatusBar extends StatelessWidget {
  const _RoomStatusBar({required this.channel, required this.joined});

  final _SpaceChannelRuntime channel;
  final bool joined;

  @override
  Widget build(BuildContext context) {
    final tint = channel.config.tint;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _RoomPill(
          icon: Icons.public_rounded,
          label: channel.config.label,
          tint: tint,
        ),
        _RoomPill(
          icon: channel.isFull ? Icons.lock_rounded : Icons.people_rounded,
          label: '${channel.occupancy}/${channel.config.capacity}',
          tint: channel.isFull
              ? LightcorePalette.warning
              : LightcorePalette.aether,
        ),
        _RoomPill(
          icon: joined ? Icons.sensors_rounded : Icons.visibility_rounded,
          label: joined
              ? 'Live'
              : channel.isFull
              ? 'Full'
              : 'Preview',
          tint: joined ? LightcorePalette.success : LightcorePalette.solar,
        ),
      ],
    );
  }
}

class _RoomPill extends StatelessWidget {
  const _RoomPill({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: LightcorePalette.night.withValues(alpha: 0.66),
        border: Border.all(color: tint.withValues(alpha: 0.48)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LightcorePalette.mist,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinRoomOverlay extends StatelessWidget {
  const _JoinRoomOverlay({required this.channel, required this.onJoin});

  final _SpaceChannelRuntime channel;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final full = channel.isFull;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.night.withValues(alpha: 0.54),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: AuroraPanel(
            tint: full ? LightcorePalette.warning : channel.config.tint,
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      full ? Icons.lock_rounded : Icons.login_rounded,
                      color: full
                          ? LightcorePalette.warning
                          : channel.config.tint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        full ? 'Room at capacity' : 'Join this channel',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  full
                      ? 'This channel is holding ${channel.occupancy} of ${channel.config.capacity} pilots.'
                      : 'Enter ${channel.config.label} to move, boost, bump, chat, and whisper.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LightcorePalette.mist.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onJoin,
                    icon: Icon(full ? Icons.lock_rounded : Icons.login_rounded),
                    label: Text(full ? 'Full' : 'Join Channel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoystickPad extends StatelessWidget {
  const _JoystickPad({required this.value, required this.onChanged});

  final Offset value;
  final ValueChanged<Offset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Move',
      child: GestureDetector(
        onPanStart: (details) => _update(details.localPosition),
        onPanUpdate: (details) => _update(details.localPosition),
        onPanEnd: (_) => onChanged(Offset.zero),
        onPanCancel: () => onChanged(Offset.zero),
        child: SizedBox(
          width: 108,
          height: 108,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LightcorePalette.night.withValues(alpha: 0.62),
              border: Border.all(
                color: LightcorePalette.aether.withValues(alpha: 0.38),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.control_camera_rounded,
                  size: 38,
                  color: LightcorePalette.mist.withValues(alpha: 0.22),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(value.dx, value.dy),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LightcorePalette.aether.withValues(alpha: 0.88),
                      boxShadow: [
                        BoxShadow(
                          color: LightcorePalette.aether.withValues(
                            alpha: 0.28,
                          ),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _update(Offset localPosition) {
    const size = 108.0;
    const radius = 42.0;
    final vector = localPosition - const Offset(size / 2, size / 2);
    final distance = vector.distance;
    if (distance <= 0.001) {
      onChanged(Offset.zero);
      return;
    }
    final limited = distance > radius ? vector / distance * radius : vector;
    onChanged(Offset(limited.dx / radius, limited.dy / radius));
  }
}

class _BoostButton extends StatelessWidget {
  const _BoostButton({required this.active, required this.onChanged});

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onChanged(true),
      onPointerUp: (_) => onChanged(false),
      onPointerCancel: (_) => onChanged(false),
      child: Tooltip(
        message: 'Boost',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 92,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: active
                ? LightcorePalette.flare
                : LightcorePalette.night.withValues(alpha: 0.66),
            border: Border.all(
              color: active
                  ? LightcorePalette.gilded
                  : LightcorePalette.flare.withValues(alpha: 0.5),
            ),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: LightcorePalette.flare.withValues(alpha: 0.32),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Icon(
            Icons.rocket_launch_rounded,
            color: active ? LightcorePalette.night : LightcorePalette.flare,
          ),
        ),
      ),
    );
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({required this.channel, required this.localPlayerId});

  final _SpaceChannelRuntime channel;
  final String localPlayerId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuroraPanel(
      tint: channel.config.tint,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: channel.config.tint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Players and Managers',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${channel.occupancy}/${channel.config.capacity}',
                style: textTheme.labelLarge?.copyWith(
                  color: channel.isFull
                      ? LightcorePalette.warning
                      : LightcorePalette.aether,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final occupant in channel.occupants)
                _OccupantBadge(
                  occupant: occupant,
                  local: occupant.id == localPlayerId,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OccupantBadge extends StatelessWidget {
  const _OccupantBadge({required this.occupant, required this.local});

  final _SpaceOccupant occupant;
  final bool local;

  @override
  Widget build(BuildContext context) {
    final label = local
        ? '${occupant.label} (You)'
        : occupant.isManager
        ? '${occupant.label} (Manager)'
        : occupant.label;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: occupant.tint.withValues(alpha: local ? 0.22 : 0.12),
        border: Border.all(color: occupant.tint.withValues(alpha: 0.46)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CosmicGuideAvatar(
              guide: occupant.guide,
              loadout: occupant.equipmentLoadout,
              size: 22,
              semanticLabel: label,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LightcorePalette.mist,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.channel,
    required this.controller,
    required this.scrollController,
    required this.enabled,
    required this.chatTargetId,
    required this.targetOccupants,
    required this.onTargetChanged,
    required this.onSubmitted,
    required this.onSend,
  });

  final _SpaceChannelRuntime channel;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool enabled;
  final String chatTargetId;
  final List<_SpaceOccupant> targetOccupants;
  final ValueChanged<String?> onTargetChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return AuroraPanel(
      tint: LightcorePalette.aether,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_rounded, color: LightcorePalette.aether),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Room Chat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _WhisperTargetMenu(
                value: chatTargetId,
                occupants: targetOccupants,
                enabled: enabled,
                onChanged: onTargetChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LightcorePalette.night.withValues(alpha: 0.34),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: LightcorePalette.stroke.withValues(alpha: 0.46),
                ),
              ),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: channel.messages.length,
                itemBuilder: (context, index) {
                  final message = channel.messages[index];
                  return _ChatMessageBubble(
                    message: message,
                    author: channel.occupants
                        .where((occupant) => occupant.id == message.authorId)
                        .firstOrNull,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('space-room-chat-field'),
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 3,
                  onSubmitted: enabled ? onSubmitted : null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: enabled
                        ? 'Chat or whisper'
                        : 'Join this channel to chat',
                    prefixIcon: const Icon(Icons.chat_bubble_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send chat',
                onPressed: enabled ? onSend : null,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhisperTargetMenu extends StatelessWidget {
  const _WhisperTargetMenu({
    required this.value,
    required this.occupants,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final List<_SpaceOccupant> occupants;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: LightcorePalette.night.withValues(alpha: 0.38),
          border: Border.all(
            color: LightcorePalette.stroke.withValues(alpha: 0.48),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded),
              dropdownColor: LightcorePalette.panelRaised,
              onChanged: enabled ? onChanged : null,
              items: [
                const DropdownMenuItem<String>(
                  value: _SpaceRoomScreenState._channelChatTarget,
                  child: Text('Channel'),
                ),
                for (final occupant in occupants)
                  DropdownMenuItem<String>(
                    value: occupant.id,
                    child: Text(
                      'Whisper ${occupant.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message, required this.author});

  final _SpaceChatMessage message;
  final _SpaceOccupant? author;

  @override
  Widget build(BuildContext context) {
    final tint = message.system
        ? LightcorePalette.solar
        : message.isWhisper
        ? LightcorePalette.violet
        : LightcorePalette.aether;
    final title = message.system
        ? 'Room'
        : message.isWhisper
        ? '${message.authorLabel} to ${message.targetLabel}'
        : message.authorLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: tint.withValues(alpha: message.system ? 0.08 : 0.12),
          border: Border.all(color: tint.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (author == null)
                    Icon(
                      message.system
                          ? Icons.info_rounded
                          : message.isWhisper
                          ? Icons.lock_rounded
                          : Icons.person_rounded,
                      size: 14,
                      color: tint,
                    )
                  else
                    CosmicGuideAvatar(
                      guide: author!.guide,
                      loadout: author!.equipmentLoadout,
                      size: 18,
                      semanticLabel: author!.label,
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (message.isWhisper)
                    Text(
                      'Whisper',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LightcorePalette.mist.withValues(alpha: 0.86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpaceRoomPainter extends CustomPainter {
  _SpaceRoomPainter({
    required this.channel,
    required this.localPlayerId,
    required this.boosting,
    required this.phase,
  });

  final _SpaceChannelRuntime channel;
  final String localPlayerId;
  final bool boosting;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = math.min(size.width, size.height) * 0.045;
    final background = Paint()
      ..shader = RadialGradient(
        colors: [
          channel.config.tint.withValues(alpha: 0.22),
          LightcorePalette.abyss.withValues(alpha: 0.94),
          LightcorePalette.night,
        ],
        stops: const [0, 0.46, 1],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    _drawStarfield(canvas, size);
    _drawOrbitLanes(canvas, size);
    for (final occupant in channel.occupants) {
      _drawOccupantAura(canvas, size, occupant, radius);
    }
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 86; i++) {
      final x = ((i * 37) % 101) / 101 * size.width;
      final y = ((i * 53) % 97) / 97 * size.height;
      final pulse = 0.35 + 0.38 * math.sin(phase * 1.4 + i * 0.71);
      starPaint.color = LightcorePalette.mist.withValues(alpha: pulse);
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.34, starPaint);
    }
  }

  void _drawOrbitLanes(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.48);
    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = channel.config.tint.withValues(alpha: 0.16);
    for (var i = 0; i < 4; i++) {
      final inset = 30.0 + i * 38;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: math.max(10, size.width - inset * 2),
          height: math.max(10, size.height - inset * 1.55),
        ),
        lanePaint,
      );
    }
  }

  void _drawOccupantAura(
    Canvas canvas,
    Size size,
    _SpaceOccupant occupant,
    double baseRadius,
  ) {
    final center = Offset(
      occupant.position.dx * size.width,
      occupant.position.dy * size.height,
    );
    final occupantRadius = occupant.isLocal ? baseRadius * 1.12 : baseRadius;
    final glow = Paint()
      ..color = occupant.tint.withValues(alpha: occupant.isLocal ? 0.24 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, occupantRadius * 1.8, glow);

    if (occupant.isLocal && boosting) {
      final boostPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = LightcorePalette.flare.withValues(alpha: 0.68);
      canvas.drawCircle(center, occupantRadius * 2.08, boostPaint);
    }

    if (occupant.velocity.distance > 0.02) {
      final direction = occupant.velocity / occupant.velocity.distance;
      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = occupantRadius * 0.18
        ..strokeCap = StrokeCap.round
        ..color = occupant.tint.withValues(alpha: 0.34);
      canvas.drawLine(
        center - (direction * occupantRadius * 2.6),
        center - (direction * occupantRadius * 1.15),
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpaceRoomPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.boosting != boosting ||
        oldDelegate.channel != channel;
  }
}
