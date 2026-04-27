part of '../friend_management_screen.dart';

class _SocialPlayerProfilePanel extends StatelessWidget {
  const _SocialPlayerProfilePanel({
    required this.player,
    required this.relationshipLabel,
    required this.branchCount,
    required this.tower,
  });

  final LightcoreSocialPlayer player;
  final String relationshipLabel;
  final int branchCount;
  final FriendRelayTower? tower;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = switch (relationshipLabel) {
      'Mentor' => LightcorePalette.aether,
      'Mentee' => LightcorePalette.verdant,
      'Grand-mentee' => LightcorePalette.violet,
      _ => LightcorePalette.solar,
    };
    final filledTowerCount =
        tower?.filledPieceCount ?? _fallbackFilledTowerCount(player);
    final averagePower =
        tower?.averagePowerScore ?? player.sharedRelayAveragePower;
    final towerLabel = averagePower > 0
        ? '$filledTowerCount/7 tower • ${averagePower.round()} TS'
        : '$filledTowerCount/7 tower';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: LightcorePalette.panelRaised.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SocialTowerGlyph(
              player: player,
              tower: tower,
              tint: tint,
              size: 54,
            ),
            const SizedBox(width: 14),
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
                        player.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      _MiniBadge(label: relationshipLabel, tint: tint),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${player.levelLabel} • ${player.performanceLabel} • Player ${player.playerId}',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniBadge(
                        label: towerLabel,
                        tint: LightcorePalette.solar,
                      ),
                      _MiniBadge(
                        label: branchCount == 1
                            ? '1 branch'
                            : '$branchCount branches',
                        tint: LightcorePalette.aether,
                      ),
                      _MiniBadge(
                        label: player.withinLevelBand
                            ? 'In Band'
                            : 'Band Pending',
                        tint: player.withinLevelBand
                            ? LightcorePalette.success
                            : LightcorePalette.stroke,
                      ),
                      if (player.bonusActive)
                        const _MiniBadge(
                          label: 'Bonus Active',
                          tint: LightcorePalette.verdant,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialHexMap extends StatelessWidget {
  const _SocialHexMap({
    required this.social,
    required this.controller,
    required this.center,
    required this.centerLabel,
    required this.children,
    required this.grandchildren,
    required this.onTapPlayer,
    this.mentor,
  });

  final LightcoreSocialOverview social;
  final LightcoreController controller;
  final LightcoreSocialPlayer center;
  final String centerLabel;
  final List<LightcoreSocialPlayer> children;
  final List<LightcoreSocialPlayer> grandchildren;
  final LightcoreSocialPlayer? mentor;
  final ValueChanged<LightcoreSocialPlayer> onTapPlayer;

  @override
  Widget build(BuildContext context) {
    final orderedChildren = children.toList(growable: true)
      ..sort(_compareSocialBranchPriority);
    final primaryChildren = orderedChildren.take(6).toList(growable: false);
    final reserveChildren = orderedChildren.skip(6).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final centerPoint = Offset(width / 2, height * 0.53);
        final orbitRadius = math.min(width * 0.3, height * 0.27);
        final reserveRadius = math.min(width * 0.43, height * 0.39);
        final tileWidth = math.min(138.0, math.max(116.0, width * 0.31));
        final tileHeight = tileWidth * 1.1;
        final centerTileWidth = math.min(154.0, tileWidth + 18);
        final centerTileHeight = centerTileWidth * 1.08;
        final compactWidth = math.min(108.0, math.max(90.0, width * 0.24));
        final compactHeight = compactWidth * 1.08;
        final nodes = <Widget>[
          _positionedNode(
            centerPoint,
            centerTileWidth,
            centerTileHeight,
            _SocialHexTile(
              player: center,
              tint: LightcorePalette.aether,
              label: centerLabel,
              tower: _towerForPlayer(center),
              branchCount: children.length,
              isCenter: true,
              onTap: () => onTapPlayer(center),
            ),
          ),
        ];

        final parent = mentor;
        if (parent != null) {
          nodes.add(
            _positionedNode(
              Offset(compactWidth * 0.72, compactHeight * 0.72),
              compactWidth,
              compactHeight,
              _SocialHexTile(
                player: parent,
                tint: parent.withinLevelBand
                    ? LightcorePalette.success
                    : LightcorePalette.warning,
                label: 'Mentor',
                tower: _towerForPlayer(parent),
                branchCount: _branchCountFor(parent),
                compact: true,
                onTap: () => onTapPlayer(parent),
              ),
            ),
          );
        }

        for (var index = 0; index < primaryChildren.length; index += 1) {
          final point = _slotPoint(centerPoint, orbitRadius, index);
          final player = primaryChildren[index];
          nodes.add(
            _positionedNode(
              point,
              tileWidth,
              tileHeight,
              _SocialHexTile(
                player: player,
                tint: player.bonusActive
                    ? LightcorePalette.verdant
                    : LightcorePalette.solar,
                label: 'Mentee',
                tower: _towerForPlayer(player),
                branchCount: _branchCountFor(player),
                onTap: () => onTapPlayer(player),
              ),
            ),
          );
        }

        for (var index = 0; index < reserveChildren.length; index += 1) {
          final angle =
              (-math.pi / 2) +
              ((math.pi * 2) * index / math.max(1, reserveChildren.length));
          final rawPoint =
              centerPoint +
              Offset(math.cos(angle), math.sin(angle)) * reserveRadius;
          final point = _clampPoint(
            rawPoint,
            compactWidth,
            compactHeight,
            width,
            height,
          );
          final player = reserveChildren[index];
          nodes.add(
            _positionedNode(
              point,
              compactWidth,
              compactHeight,
              _SocialHexTile(
                player: player,
                tint: player.withinLevelBand
                    ? LightcorePalette.violet
                    : LightcorePalette.warning,
                label: 'Reserve',
                tower: _towerForPlayer(player),
                branchCount: _branchCountFor(player),
                compact: true,
                onTap: () => onTapPlayer(player),
              ),
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: LightcorePalette.violet.withValues(alpha: 0.34),
            ),
            gradient: RadialGradient(
              colors: [
                LightcorePalette.violet.withValues(alpha: 0.2),
                LightcorePalette.panelRaised.withValues(alpha: 0.78),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: CustomPaint(
              painter: _SocialTowerMapPainter(
                tint: LightcorePalette.violet,
                hasMentorAnchor: mentor != null,
              ),
              child: Stack(
                children: [
                  ...nodes,
                  Positioned(
                    right: 14,
                    top: 12,
                    child: _MiniBadge(
                      label:
                          '${children.length} direct • ${grandchildren.length} next',
                      tint: LightcorePalette.aether,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _compareSocialBranchPriority(
    LightcoreSocialPlayer left,
    LightcoreSocialPlayer right,
  ) {
    final activeCompare = _priorityBool(
      right.bonusActive,
    ).compareTo(_priorityBool(left.bonusActive));
    if (activeCompare != 0) {
      return activeCompare;
    }
    final bandCompare = _priorityBool(
      right.withinLevelBand,
    ).compareTo(_priorityBool(left.withinLevelBand));
    if (bandCompare != 0) {
      return bandCompare;
    }
    final branchCompare = _branchCountFor(
      right,
    ).compareTo(_branchCountFor(left));
    if (branchCompare != 0) {
      return branchCompare;
    }
    return right.performanceScore.compareTo(left.performanceScore);
  }

  int _priorityBool(bool value) => value ? 1 : 0;

  int _branchCountFor(LightcoreSocialPlayer player) {
    if (social.mentor?.uid == player.uid) {
      return 1;
    }
    return social.childrenOf(player.uid).length;
  }

  FriendRelayTower? _towerForPlayer(LightcoreSocialPlayer player) {
    if (player.uid == social.self.uid) {
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

  Offset _slotPoint(Offset center, double radius, int index) {
    final angle = (-math.pi / 2) + (index * (math.pi / 3));
    return center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  Offset _clampPoint(
    Offset point,
    double nodeWidth,
    double nodeHeight,
    double mapWidth,
    double mapHeight,
  ) {
    const margin = 12.0;
    return Offset(
      point.dx
          .clamp((nodeWidth / 2) + margin, mapWidth - (nodeWidth / 2) - margin)
          .toDouble(),
      point.dy
          .clamp(
            (nodeHeight / 2) + margin,
            mapHeight - (nodeHeight / 2) - margin,
          )
          .toDouble(),
    );
  }

  Widget _positionedNode(
    Offset point,
    double width,
    double height,
    Widget child,
  ) {
    return Positioned(
      left: point.dx - (width / 2),
      top: point.dy - (height / 2),
      width: width,
      height: height,
      child: child,
    );
  }
}

class _SocialHexTile extends StatelessWidget {
  const _SocialHexTile({
    required this.player,
    required this.tint,
    required this.label,
    required this.tower,
    required this.branchCount,
    required this.onTap,
    this.compact = false,
    this.isCenter = false,
  });

  final LightcoreSocialPlayer player;
  final Color tint;
  final String label;
  final FriendRelayTower? tower;
  final int branchCount;
  final VoidCallback? onTap;
  final bool compact;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filledTowerCount =
        tower?.filledPieceCount ?? _fallbackFilledTowerCount(player);
    final averagePower =
        tower?.averagePowerScore ?? player.sharedRelayAveragePower;
    final towerLabel = averagePower > 0
        ? '$filledTowerCount/7 • ${averagePower.round()} TS'
        : '$filledTowerCount/7 tower';
    final branchLabel = branchCount > 0
        ? '$branchCount branch'
        : player.performanceLabel;
    final tooltip = onTap == null
        ? '${player.displayName} profile'
        : 'View ${player.displayName} profile';

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: onTap != null,
        label: tooltip,
        child: MouseRegion(
          cursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: CustomPaint(
              painter: _SocialHexTilePainter(
                tint: tint,
                enabled: onTap != null,
                isCenter: isCenter,
              ),
              child: ClipPath(
                clipper: const _HexClipper(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 18,
                    vertical: compact ? 10 : 14,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialTowerGlyph(
                        player: player,
                        tower: tower,
                        tint: tint,
                        size: compact ? 30 : 42,
                      ),
                      SizedBox(height: compact ? 3 : 5),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      Text(
                        compact
                            ? '${player.levelLabel} • $branchLabel'
                            : '${player.levelLabel} • $towerLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(height: 1.05),
                      ),
                      if (!compact)
                        Text(
                          branchLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: tint.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialTowerGlyph extends StatelessWidget {
  const _SocialTowerGlyph({
    required this.player,
    required this.tower,
    required this.tint,
    required this.size,
  });

  final LightcoreSocialPlayer player;
  final FriendRelayTower? tower;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _SocialTowerGlyphPainter(
          player: player,
          tower: tower,
          tint: tint,
        ),
      ),
    );
  }
}

class _SocialTowerGlyphPainter extends CustomPainter {
  const _SocialTowerGlyphPainter({
    required this.player,
    required this.tower,
    required this.tint,
  });

  final LightcoreSocialPlayer player;
  final FriendRelayTower? tower;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = shortest * 0.3;
    final nodeRadius = shortest * 0.105;
    final centerRadius = shortest * 0.14;
    final outerPieces = tower?.outerPieces ?? const <FriendRelayPiece?>[];
    final fallbackFilled = _fallbackFilledTowerCount(player);
    final hasRealTower = tower != null && tower!.filledPieceCount > 0;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.035
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: 0.42);
    final emptyFill = Paint()
      ..style = PaintingStyle.fill
      ..color = LightcorePalette.panel.withValues(alpha: 0.64);
    final emptyStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortest * 0.026
      ..color = LightcorePalette.stroke.withValues(alpha: 0.5);

    for (var index = 0; index < 6; index += 1) {
      final point = _hexOrbitPoint(center, orbitRadius, index);
      canvas.drawLine(center, point, linePaint);
    }

    final centerColor =
        tower?.center?.affinity.color ?? _fallbackTowerColor(player.uid, 6);
    _paintTowerNode(
      canvas,
      center,
      centerRadius,
      color: centerColor,
      filled: tower?.center != null || fallbackFilled > 0,
      emptyFill: emptyFill,
      emptyStroke: emptyStroke,
    );

    for (var index = 0; index < 6; index += 1) {
      final point = _hexOrbitPoint(center, orbitRadius, index);
      final piece = index < outerPieces.length ? outerPieces[index] : null;
      final fallbackFilledSlot = !hasRealTower && index < fallbackFilled - 1;
      _paintTowerNode(
        canvas,
        point,
        nodeRadius,
        color: piece?.affinity.color ?? _fallbackTowerColor(player.uid, index),
        filled: piece != null || fallbackFilledSlot,
        emptyFill: emptyFill,
        emptyStroke: emptyStroke,
      );
    }
  }

  void _paintTowerNode(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color color,
    required bool filled,
    required Paint emptyFill,
    required Paint emptyStroke,
  }) {
    final path = _hexagonPath(center, radius);
    if (!filled) {
      canvas.drawPath(path, emptyFill);
      canvas.drawPath(path, emptyStroke);
      return;
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.72),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, radius * 0.18)
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.96),
    );
  }

  @override
  bool shouldRepaint(covariant _SocialTowerGlyphPainter oldDelegate) =>
      oldDelegate.player != player ||
      oldDelegate.tower != tower ||
      oldDelegate.tint != tint;
}

class _SocialHexTilePainter extends CustomPainter {
  const _SocialHexTilePainter({
    required this.tint,
    required this.enabled,
    required this.isCenter,
  });

  final Color tint;
  final bool enabled;
  final bool isCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPathForSize(size, inset: 3);
    final rect = Offset.zero & size;
    canvas.drawShadow(
      path,
      tint.withValues(alpha: enabled ? 0.4 : 0.28),
      isCenter ? 12 : 8,
      false,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(LightcorePalette.night, tint, isCenter ? 0.26 : 0.18)!,
            LightcorePalette.panelRaised.withValues(alpha: 0.9),
            LightcorePalette.night.withValues(alpha: 0.88),
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      _hexPathForSize(size, inset: 9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = LightcorePalette.mist.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCenter ? 3.2 : 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = tint.withValues(alpha: enabled || isCenter ? 0.9 : 0.58),
    );
  }

  @override
  bool shouldRepaint(covariant _SocialHexTilePainter oldDelegate) =>
      oldDelegate.tint != tint ||
      oldDelegate.enabled != enabled ||
      oldDelegate.isCenter != isCenter;
}

class _SocialTowerMapPainter extends CustomPainter {
  const _SocialTowerMapPainter({
    required this.tint,
    required this.hasMentorAnchor,
  });

  final Color tint;
  final bool hasMentorAnchor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.53);
    final orbitRadius = math.min(size.width * 0.3, size.height * 0.27);
    final slotRadius = math.min(size.width, size.height) * 0.058;
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = tint.withValues(alpha: 0.18);
    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: 0.16);

    for (var ring = 1; ring <= 2; ring += 1) {
      canvas.drawPath(
        _hexagonPath(center, orbitRadius * (ring == 1 ? 0.72 : 1.18)),
        guidePaint,
      );
    }

    for (var index = 0; index < 6; index += 1) {
      final point = _hexOrbitPoint(center, orbitRadius, index);
      canvas.drawLine(center, point, spokePaint);
      canvas.drawPath(_hexagonPath(point, slotRadius), guidePaint);
    }

    canvas.drawPath(
      _hexagonPath(center, slotRadius * 1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = LightcorePalette.aether.withValues(alpha: 0.2),
    );

    if (!hasMentorAnchor) {
      return;
    }
    final mentorCenter = Offset(size.width * 0.14, size.height * 0.14);
    canvas.drawLine(
      mentorCenter,
      center,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round
        ..color = LightcorePalette.solar.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _SocialTowerMapPainter oldDelegate) =>
      oldDelegate.tint != tint ||
      oldDelegate.hasMentorAnchor != hasMentorAnchor;
}

class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();

  @override
  Path getClip(Size size) => _hexPathForSize(size, inset: 3);

  @override
  bool shouldReclip(covariant _HexClipper oldClipper) => false;
}

const double _sqrt3 = 1.7320508075688772;

int _fallbackFilledTowerCount(LightcoreSocialPlayer player) {
  if (player.sharedRelayFilledPieceCount > 0) {
    return player.sharedRelayFilledPieceCount.clamp(1, 7);
  }
  return (1 + (player.performanceScore.clamp(0.0, 1.0) * 6).round()).clamp(
    1,
    7,
  );
}

Color _fallbackTowerColor(String uid, int index) {
  const colors = <Color>[
    LightcorePalette.ember,
    LightcorePalette.flare,
    LightcorePalette.solar,
    LightcorePalette.verdant,
    LightcorePalette.aether,
    LightcorePalette.violet,
  ];
  return colors[(_stableSocialHash(uid) + index) % colors.length];
}

int _stableSocialHash(String value) {
  var hash = 0;
  for (final unit in value.codeUnits) {
    hash = ((hash * 31) + unit) & 0x7fffffff;
  }
  return hash;
}

Offset _hexOrbitPoint(Offset center, double radius, int index) {
  final angle = (-math.pi / 2) + (index * (math.pi / 3));
  return center + Offset(math.cos(angle), math.sin(angle)) * radius;
}

Path _hexPathForSize(Size size, {double inset = 0}) {
  final width = math.max(0.0, size.width - (inset * 2));
  final height = math.max(0.0, size.height - (inset * 2));
  final radius = math.min(width / _sqrt3, height / 2);
  return _hexagonPath(Offset(size.width / 2, size.height / 2), radius);
}

Path _hexagonPath(Offset center, double radius) {
  final path = Path();
  for (var index = 0; index < 6; index += 1) {
    final angle = (-math.pi / 2) + (index * (math.pi / 3));
    final point = Offset(
      center.dx + (math.cos(angle) * radius),
      center.dy + (math.sin(angle) * radius),
    );
    if (index == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}
