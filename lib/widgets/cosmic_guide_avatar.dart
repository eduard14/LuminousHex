import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/lightcore_avatar.dart';
import '../models/lightcore_guide.dart';
import '../models/lightcore_state.dart';
import '../models/lightcore_types.dart';
import '../theme/lightcore_palette.dart';

@immutable
class CosmicEquipmentPiece {
  const CosmicEquipmentPiece({
    required this.slotType,
    required this.setId,
    required this.affinity,
    this.rarity = ManagerRarity.common,
  });

  factory CosmicEquipmentPiece.fromItem(PlayerEquipmentItem item) {
    return CosmicEquipmentPiece(
      slotType: item.slotType,
      setId: item.setId,
      affinity: item.affinity,
      rarity: item.rarity,
    );
  }

  factory CosmicEquipmentPiece.fromAvatarPiece(
    LightcoreAvatarEquipmentPiece piece,
  ) {
    return CosmicEquipmentPiece(
      slotType: piece.slotType,
      setId: piece.setId,
      affinity: piece.affinity,
      rarity: piece.rarity,
    );
  }

  final EquipmentInventorySlot slotType;
  final String setId;
  final PrototypeAffinity affinity;
  final ManagerRarity rarity;

  String get assetPath =>
      'assets/sprites/equipment/$setId/${slotType.name}.png';

  Color get tint => affinity.color;
  Color get accent => switch (affinity) {
    PrototypeAffinity.neutral => LightcorePalette.layer2,
    PrototypeAffinity.ember => LightcorePalette.warning,
    PrototypeAffinity.flare => LightcorePalette.gilded,
    PrototypeAffinity.solar => LightcorePalette.gilded,
    PrototypeAffinity.verdant => LightcorePalette.success,
    PrototypeAffinity.aether => LightcorePalette.layer2,
    PrototypeAffinity.violet => LightcorePalette.layer2,
    PrototypeAffinity.black => LightcorePalette.violet,
  };

  double get rarityBoost => 1 + (rarity.score * 0.11);
}

@immutable
class CosmicEquipmentLoadout {
  const CosmicEquipmentLoadout(this.pieces);

  factory CosmicEquipmentLoadout.fromItems(
    Iterable<PlayerEquipmentItem?> items,
  ) {
    return CosmicEquipmentLoadout(<CosmicEquipmentPiece>[
      for (final item in items)
        if (item != null) CosmicEquipmentPiece.fromItem(item),
    ]);
  }

  factory CosmicEquipmentLoadout.fromAvatarPieces(
    Iterable<LightcoreAvatarEquipmentPiece> pieces,
  ) {
    return CosmicEquipmentLoadout(<CosmicEquipmentPiece>[
      for (final piece in pieces) CosmicEquipmentPiece.fromAvatarPiece(piece),
    ]);
  }

  factory CosmicEquipmentLoadout.preview({
    required String setId,
    required PrototypeAffinity affinity,
    required int seed,
    bool manager = false,
  }) {
    final slots = manager
        ? const <EquipmentInventorySlot>[
            EquipmentInventorySlot.hat,
            EquipmentInventorySlot.top,
            EquipmentInventorySlot.accessory,
          ]
        : const <EquipmentInventorySlot>[
            EquipmentInventorySlot.hat,
            EquipmentInventorySlot.top,
            EquipmentInventorySlot.shoes,
          ];
    final count = 2 + (seed % 2);
    return CosmicEquipmentLoadout(<CosmicEquipmentPiece>[
      for (var index = 0; index < count; index++)
        CosmicEquipmentPiece(
          slotType: slots[(seed + index) % slots.length],
          setId: setId,
          affinity: affinity,
          rarity: ManagerRarity.values[(seed + index) % 3],
        ),
    ]);
  }

  static const empty = CosmicEquipmentLoadout(<CosmicEquipmentPiece>[]);

  final List<CosmicEquipmentPiece> pieces;

  bool get isEmpty => pieces.isEmpty;

  bool get isNotEmpty => pieces.isNotEmpty;

  CosmicEquipmentPiece? pieceFor(EquipmentInventorySlot slot) {
    for (final piece in pieces) {
      if (piece.slotType == slot) {
        return piece;
      }
    }
    return null;
  }

  List<CosmicEquipmentPiece> piecesFor(EquipmentInventorySlot slot) {
    return <CosmicEquipmentPiece>[
      for (final piece in pieces)
        if (piece.slotType == slot) piece,
    ];
  }

  Color get primaryTint {
    if (pieces.isEmpty) {
      return LightcorePalette.aether;
    }
    return pieces.first.tint;
  }
}

class CosmicGuideAvatar extends StatelessWidget {
  const CosmicGuideAvatar({
    super.key,
    required this.guide,
    this.size = 48,
    this.loadout = CosmicEquipmentLoadout.empty,
    this.phase = 0,
    this.boosting = false,
    this.pose = LightcoreAvatarPose.idle,
    this.usePortraitAsset = true,
    this.framed = true,
    this.semanticLabel,
  });

  final LightcoreGuideProfile guide;
  final double size;
  final CosmicEquipmentLoadout loadout;
  final double phase;
  final bool boosting;
  final LightcoreAvatarPose pose;
  final bool usePortraitAsset;
  final bool framed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.32);
    Widget body = CustomPaint(
      painter: CosmicGuideAvatarPainter(
        guide: guide,
        loadout: loadout,
        phase: phase,
        boosting: boosting,
        pose: pose,
        drawFrame: framed,
        drawBody: !usePortraitAsset,
      ),
      child: SizedBox.square(dimension: size),
    );

    if (usePortraitAsset) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          body,
          _AvatarPoseTransform(
            pose: pose,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.all(size * 0.04),
                  child: Image.asset(
                    _avatarBaseAssetPath(guide, pose),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return CustomPaint(
                        painter: CosmicGuideAvatarPainter(
                          guide: guide,
                          loadout: loadout,
                          phase: phase,
                          boosting: boosting,
                          pose: pose,
                          drawFrame: false,
                          drawBody: true,
                        ),
                      );
                    },
                  ),
                ),
                _EquipmentSpriteOverlay(loadout: loadout),
              ],
            ),
          ),
        ],
      );
    } else {
      body = Stack(
        fit: StackFit.expand,
        children: [
          _AvatarPoseTransform(
            pose: pose,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: CosmicGuideAvatarPainter(
                    guide: guide,
                    loadout: loadout,
                    phase: phase,
                    boosting: boosting,
                    pose: pose,
                    drawFrame: framed,
                  ),
                ),
                _EquipmentSpriteOverlay(loadout: loadout),
              ],
            ),
          ),
        ],
      );
    }

    return Semantics(
      image: true,
      label: semanticLabel ?? guide.displayName,
      child: framed
          ? ClipRRect(
              borderRadius: radius,
              child: SizedBox.square(dimension: size, child: body),
            )
          : SizedBox.square(dimension: size, child: body),
    );
  }

  static String _avatarBaseAssetPath(
    LightcoreGuideProfile guide,
    LightcoreAvatarPose pose,
  ) {
    final guideKey = switch (guide.id) {
      LightcoreGuideId.luma => 'luma',
      LightcoreGuideId.lumo => 'lumo',
    };
    final poseKey = switch (pose) {
      LightcoreAvatarPose.move => 'move',
      LightcoreAvatarPose.boost || LightcoreAvatarPose.thrust => 'boost',
      LightcoreAvatarPose.idle => 'idle',
    };
    return 'assets/sprites/avatar/base/${guideKey}_$poseKey.png';
  }
}

class _EquipmentSpriteOverlay extends StatelessWidget {
  const _EquipmentSpriteOverlay({required this.loadout});

  final CosmicEquipmentLoadout loadout;

  @override
  Widget build(BuildContext context) {
    if (loadout.isEmpty) {
      return const SizedBox.expand();
    }

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (loadout.pieceFor(EquipmentInventorySlot.pants) case final piece?)
            _EquipmentSprite(
              piece: piece,
              bounds: _equipmentBoundsFor(EquipmentInventorySlot.pants),
            ),
          if (loadout.pieceFor(EquipmentInventorySlot.shoes) case final piece?)
            _EquipmentSprite(
              piece: piece,
              bounds: _equipmentBoundsFor(EquipmentInventorySlot.shoes),
            ),
          if (loadout.pieceFor(EquipmentInventorySlot.top) case final piece?)
            _EquipmentSprite(
              piece: piece,
              bounds: _equipmentBoundsFor(EquipmentInventorySlot.top),
            ),
          if (loadout.pieceFor(EquipmentInventorySlot.hat) case final piece?)
            _EquipmentSprite(
              piece: piece,
              bounds: _equipmentBoundsFor(EquipmentInventorySlot.hat),
            ),
          for (final piece
              in loadout.piecesFor(EquipmentInventorySlot.accessory).take(2))
            _EquipmentSprite(
              piece: piece,
              bounds: _equipmentBoundsFor(EquipmentInventorySlot.accessory),
            ),
        ],
      ),
    );
  }

  static _EquipmentSpriteBounds _equipmentBoundsFor(
    EquipmentInventorySlot slot,
  ) {
    return switch (slot) {
      EquipmentInventorySlot.hat => const _EquipmentSpriteBounds(
        left: 0.22,
        top: -0.03,
        size: 0.5,
      ),
      EquipmentInventorySlot.top => const _EquipmentSpriteBounds(
        left: 0.25,
        top: 0.37,
        size: 0.48,
      ),
      EquipmentInventorySlot.pants => const _EquipmentSpriteBounds(
        left: 0.3,
        top: 0.52,
        size: 0.38,
      ),
      EquipmentInventorySlot.shoes => const _EquipmentSpriteBounds(
        left: 0.28,
        top: 0.65,
        size: 0.44,
      ),
      EquipmentInventorySlot.accessory => const _EquipmentSpriteBounds(
        left: 0.62,
        top: 0.32,
        size: 0.3,
      ),
    };
  }
}

class _AvatarPoseTransform extends StatelessWidget {
  const _AvatarPoseTransform({required this.pose, required this.child});

  final LightcoreAvatarPose pose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _EquipmentSprite extends StatelessWidget {
  const _EquipmentSprite({required this.piece, required this.bounds});

  final CosmicEquipmentPiece piece;
  final _EquipmentSpriteBounds bounds;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth * bounds.size;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: constraints.maxWidth * bounds.left,
                top: constraints.maxHeight * bounds.top,
                width: size,
                height: size,
                child: Image.asset(
                  piece.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EquipmentSpriteBounds {
  const _EquipmentSpriteBounds({
    required this.left,
    required this.top,
    required this.size,
  });

  final double left;
  final double top;
  final double size;
}

class CosmicGuideAvatarPainter extends CustomPainter {
  const CosmicGuideAvatarPainter({
    required this.guide,
    this.loadout = CosmicEquipmentLoadout.empty,
    this.phase = 0,
    this.boosting = false,
    this.pose = LightcoreAvatarPose.idle,
    this.drawFrame = false,
    this.drawBody = true,
  });

  final LightcoreGuideProfile guide;
  final CosmicEquipmentLoadout loadout;
  final double phase;
  final bool boosting;
  final LightcoreAvatarPose pose;
  final bool drawFrame;
  final bool drawBody;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    final offset = Offset(
      (size.width - (100 * scale)) / 2,
      (size.height - (100 * scale)) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    if (drawFrame) {
      _drawFrame(canvas);
    }
    if (drawBody) {
      _drawBody(canvas);
    }

    canvas.restore();
  }

  void _drawFrame(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2, 2, 96, 96),
      const Radius.circular(28),
    );
    final tint = loadout.isEmpty ? _guideTint : loadout.primaryTint;
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.15,
          colors: [
            tint.withValues(alpha: 0.28),
            LightcorePalette.abyss.withValues(alpha: 0.96),
            LightcorePalette.night,
          ],
          stops: const [0, 0.58, 1],
        ).createShader(rect.outerRect),
    );

    final stars = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 18; index++) {
      final x = 10 + ((index * 23) % 78).toDouble();
      final y = 10 + ((index * 31) % 76).toDouble();
      final pulse = 0.36 + 0.26 * math.sin(phase * 1.7 + index);
      stars.color = LightcorePalette.layer2.withValues(alpha: pulse);
      canvas.drawCircle(Offset(x, y), 0.58 + (index % 3) * 0.14, stars);
    }

    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..color = tint.withValues(alpha: 0.58),
    );
  }

  void _drawBody(Canvas canvas) {
    final tint = _guideTint;
    final secondary = guide.id == LightcoreGuideId.lumo
        ? LightcorePalette.gilded
        : LightcorePalette.violet;
    final thrust =
        pose == LightcoreAvatarPose.boost || pose == LightcoreAvatarPose.thrust;
    final bob = math.sin(phase * 2.1) * (thrust ? 0.6 : 1.1);
    canvas.save();
    canvas.translate(0, bob);
    if (thrust) {
      canvas.translate(0, -1.4);
      canvas.rotate(-0.035);
    }

    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = tint.withValues(alpha: boosting ? 0.28 : 0.12);
    canvas.drawOval(const Rect.fromLTWH(23, 17, 54, 66), glow);
    if (boosting) {
      canvas.drawOval(
        const Rect.fromLTWH(17, 11, 66, 78),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = LightcorePalette.flare.withValues(alpha: 0.7),
      );
    }

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 58, 32, 30),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LightcorePalette.layer2.withValues(alpha: 0.95),
            tint.withValues(alpha: 0.68),
            LightcorePalette.abyss.withValues(alpha: 0.96),
          ],
        ).createShader(bodyRect.outerRect),
    );

    final armPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..color = LightcorePalette.layer2.withValues(alpha: 0.72);
    canvas.drawLine(const Offset(36, 63), const Offset(24, 69), armPaint);
    canvas.drawLine(const Offset(64, 63), const Offset(76, 69), armPaint);
    canvas.drawCircle(const Offset(21, 70), 5.2, Paint()..color = tint);
    canvas.drawCircle(const Offset(79, 70), 5.2, Paint()..color = tint);

    final headRect = Rect.fromCircle(center: const Offset(50, 38), radius: 25);
    canvas.drawCircle(
      const Offset(50, 38),
      25,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 0.95,
          colors: [
            LightcorePalette.layer2.withValues(alpha: 0.82),
            tint.withValues(alpha: 0.54),
            LightcorePalette.abyss.withValues(alpha: 0.98),
          ],
        ).createShader(headRect),
    );
    canvas.drawCircle(
      const Offset(50, 38),
      21.2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.32),
          colors: [
            LightcorePalette.panel.withValues(alpha: 0.58),
            Colors.black.withValues(alpha: 0.96),
          ],
        ).createShader(headRect),
    );

    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = LightcorePalette.layer2;
    final eyeGlow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..color = tint.withValues(alpha: 0.54);
    if (guide.id == LightcoreGuideId.lumo) {
      for (final center in const [Offset(42, 39), Offset(58, 39)]) {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 7.8, height: 11.6),
          eyeGlow,
        );
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 5.8, height: 9.3),
          eyePaint,
        );
      }
    } else {
      _drawCrescentEye(canvas, const Offset(41, 39), eyeGlow, eyePaint);
      canvas.save();
      canvas.translate(58, 39);
      canvas.scale(-1, 1);
      _drawCrescentEye(canvas, Offset.zero, eyeGlow, eyePaint);
      canvas.restore();
    }

    canvas.drawArc(
      const Rect.fromLTWH(45, 45, 10, 6),
      0.25,
      math.pi - 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = LightcorePalette.layer2.withValues(alpha: 0.9),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = tint.withValues(alpha: 0.24);
    canvas.drawArc(
      const Rect.fromLTWH(19, 29, 62, 24),
      0.16,
      math.pi * 1.82,
      false,
      ringPaint,
    );
    canvas.drawArc(
      const Rect.fromLTWH(23, 68, 54, 14),
      -0.08,
      math.pi * 1.72,
      false,
      ringPaint..color = secondary.withValues(alpha: 0.2),
    );
    canvas.restore();
  }

  void _drawCrescentEye(Canvas canvas, Offset center, Paint glow, Paint fill) {
    final path = Path()
      ..moveTo(center.dx - 4.8, center.dy + 1)
      ..quadraticBezierTo(center.dx, center.dy - 7, center.dx + 6, center.dy)
      ..quadraticBezierTo(
        center.dx + 0.5,
        center.dy - 1.5,
        center.dx - 4.8,
        center.dy + 1,
      )
      ..close();
    canvas.drawPath(path, glow);
    canvas.drawPath(path, fill);
  }

  Color get _guideTint {
    return guide.id == LightcoreGuideId.lumo
        ? LightcorePalette.aether
        : LightcorePalette.violet;
  }

  @override
  bool shouldRepaint(covariant CosmicGuideAvatarPainter oldDelegate) {
    return oldDelegate.guide != guide ||
        oldDelegate.loadout != loadout ||
        oldDelegate.phase != phase ||
        oldDelegate.boosting != boosting ||
        oldDelegate.pose != pose ||
        oldDelegate.drawFrame != drawFrame ||
        oldDelegate.drawBody != drawBody;
  }
}

class CosmicEquipmentOverlayPainter extends CustomPainter {
  const CosmicEquipmentOverlayPainter({
    required this.guide,
    required this.loadout,
    this.phase = 0,
  });

  final LightcoreGuideProfile guide;
  final CosmicEquipmentLoadout loadout;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    final offset = Offset(
      (size.width - (100 * scale)) / 2,
      (size.height - (100 * scale)) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    paintEquipment(canvas, loadout: loadout, phase: phase);
    canvas.restore();
  }

  static void paintEquipment(
    Canvas canvas, {
    required CosmicEquipmentLoadout loadout,
    required double phase,
  }) {
    if (loadout.isEmpty) {
      return;
    }

    final hat = loadout.pieceFor(EquipmentInventorySlot.hat);
    final top = loadout.pieceFor(EquipmentInventorySlot.top);
    final pants = loadout.pieceFor(EquipmentInventorySlot.pants);
    final shoes = loadout.pieceFor(EquipmentInventorySlot.shoes);
    final accessories = loadout.piecesFor(EquipmentInventorySlot.accessory);

    if (top != null) {
      _drawTop(canvas, top);
    }
    if (pants != null) {
      _drawPants(canvas, pants);
    }
    if (shoes != null) {
      _drawShoes(canvas, shoes);
    }
    if (hat != null) {
      _drawHat(canvas, hat);
    }
    for (var index = 0; index < accessories.length && index < 2; index++) {
      _drawAccessory(canvas, accessories[index], index, phase);
    }
  }

  static void _drawHat(Canvas canvas, CosmicEquipmentPiece piece) {
    final tint = piece.tint;
    final accent = piece.accent;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.3 * piece.rarityBoost
      ..color = accent.withValues(alpha: 0.92);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = tint.withValues(alpha: 0.9);

    switch (piece.setId) {
      case 'ashspike':
        final leftHorn = Path()
          ..moveTo(35, 20)
          ..quadraticBezierTo(29, 9, 24, 20)
          ..quadraticBezierTo(29, 17, 35, 20);
        final rightHorn = Path()
          ..moveTo(65, 20)
          ..quadraticBezierTo(71, 9, 76, 20)
          ..quadraticBezierTo(71, 17, 65, 20);
        canvas.drawPath(leftHorn, fill);
        canvas.drawPath(rightHorn, fill);
        canvas.drawPath(leftHorn, stroke);
        canvas.drawPath(rightHorn, stroke);
        break;
      case 'sunplate':
        final crown = Path()
          ..moveTo(32, 20)
          ..lineTo(40, 12)
          ..lineTo(50, 20)
          ..lineTo(60, 12)
          ..lineTo(68, 20)
          ..lineTo(64, 25)
          ..lineTo(36, 25)
          ..close();
        canvas.drawPath(crown, fill..color = tint.withValues(alpha: 0.88));
        canvas.drawPath(crown, stroke);
        break;
      case 'tideglass':
        canvas.drawArc(
          const Rect.fromLTWH(31, 18, 38, 20),
          math.pi * 1.05,
          math.pi * 0.9,
          false,
          stroke,
        );
        canvas.drawCircle(Offset(50, 19), 3.8, Paint()..color = tint);
        canvas.drawCircle(Offset(50, 19), 2, Paint()..color = accent);
        break;
      case 'voidloom':
        final hood = Path()
          ..moveTo(27, 29)
          ..quadraticBezierTo(50, 2, 73, 29)
          ..quadraticBezierTo(61, 20, 50, 20)
          ..quadraticBezierTo(39, 20, 27, 29)
          ..close();
        canvas.drawPath(hood, fill..color = tint.withValues(alpha: 0.82));
        canvas.drawPath(hood, stroke);
        break;
      case 'thornpath':
        final leaf = Path()
          ..moveTo(50, 15)
          ..quadraticBezierTo(40, 9, 33, 20)
          ..quadraticBezierTo(43, 19, 50, 15)
          ..quadraticBezierTo(60, 8, 68, 21)
          ..quadraticBezierTo(58, 20, 50, 15);
        canvas.drawPath(leaf, fill..color = tint.withValues(alpha: 0.82));
        canvas.drawPath(leaf, stroke);
        break;
      default:
        canvas.drawArc(
          const Rect.fromLTWH(30, 17, 40, 20),
          math.pi * 1.05,
          math.pi * 0.9,
          false,
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(37, 19, 26, 6),
            const Radius.circular(4),
          ),
          fill,
        );
    }
  }

  static void _drawTop(Canvas canvas, CosmicEquipmentPiece piece) {
    final tint = piece.tint;
    final accent = piece.accent;
    final torso = Path()
      ..moveTo(35, 58)
      ..quadraticBezierTo(50, 52, 65, 58)
      ..lineTo(69, 76)
      ..quadraticBezierTo(50, 82, 31, 76)
      ..close();
    canvas.drawPath(
      torso,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tint.withValues(alpha: 0.88),
            LightcorePalette.abyss.withValues(alpha: 0.9),
          ],
        ).createShader(const Rect.fromLTWH(30, 52, 40, 30)),
    );
    canvas.drawPath(
      torso,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * piece.rarityBoost
        ..color = accent.withValues(alpha: 0.88),
    );

    if (piece.setId == 'sunplate' || piece.setId == 'surveyor') {
      _drawSpark(canvas, const Offset(50, 66), accent, 5.4);
    } else if (piece.setId == 'thornpath') {
      canvas.drawLine(
        const Offset(42, 61),
        const Offset(59, 74),
        Paint()
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.88),
      );
      canvas.drawLine(
        const Offset(58, 61),
        const Offset(42, 74),
        Paint()
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.88),
      );
    } else {
      canvas.drawCircle(const Offset(50, 66), 3.3, Paint()..color = accent);
      canvas.drawCircle(
        const Offset(50, 66),
        6.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = accent.withValues(alpha: 0.58),
      );
    }
  }

  static void _drawPants(Canvas canvas, CosmicEquipmentPiece piece) {
    final paint = Paint()
      ..color = piece.tint.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;
    for (final rect in const [
      Rect.fromLTWH(39, 75, 9, 15),
      Rect.fromLTWH(52, 75, 9, 15),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3 * piece.rarityBoost
          ..color = piece.accent.withValues(alpha: 0.82),
      );
    }
  }

  static void _drawShoes(Canvas canvas, CosmicEquipmentPiece piece) {
    for (final center in const [Offset(43, 90), Offset(57, 90)]) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 13, height: 7),
        Paint()..color = piece.tint.withValues(alpha: 0.9),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, 2.3),
          width: 8,
          height: 2.8,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25 * piece.rarityBoost
          ..color = piece.accent.withValues(alpha: 0.86),
      );
    }
  }

  static void _drawAccessory(
    Canvas canvas,
    CosmicEquipmentPiece piece,
    int index,
    double phase,
  ) {
    final side = index == 0 ? -1.0 : 1.0;
    final bob = math.sin(phase * 2.6 + index * math.pi) * 2.2;
    final center = Offset(50 + side * 36, 58 + bob);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * piece.rarityBoost
      ..color = piece.tint.withValues(alpha: 0.9);
    canvas.drawCircle(
      center,
      6.3,
      Paint()..color = piece.tint.withValues(alpha: 0.16),
    );
    if (piece.setId == 'tideglass') {
      canvas.drawCircle(center, 5.4, paint);
      canvas.drawLine(
        center.translate(-3.2, 3.2),
        center.translate(4.6, -4.6),
        paint..color = piece.accent.withValues(alpha: 0.9),
      );
    } else if (piece.setId == 'ashspike') {
      final fang = Path()
        ..moveTo(center.dx, center.dy - 7)
        ..lineTo(center.dx + side * 5, center.dy + 5)
        ..lineTo(center.dx - side * 4, center.dy + 3)
        ..close();
      canvas.drawPath(
        fang,
        Paint()..color = piece.tint.withValues(alpha: 0.86),
      );
      canvas.drawPath(fang, paint);
    } else {
      _drawSpark(canvas, center, piece.accent, 5.8);
      canvas.drawCircle(center, 7.2, paint);
    }
  }

  static void _drawSpark(Canvas canvas, Offset center, Color color, double r) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.32, center.dy - r * 0.32)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx + r * 0.32, center.dy + r * 0.32)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.32, center.dy + r * 0.32)
      ..lineTo(center.dx - r, center.dy)
      ..lineTo(center.dx - r * 0.32, center.dy - r * 0.32)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2)
        ..color = color.withValues(alpha: 0.46),
    );
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.92));
  }

  @override
  bool shouldRepaint(covariant CosmicEquipmentOverlayPainter oldDelegate) {
    return oldDelegate.guide != guide ||
        oldDelegate.loadout != loadout ||
        oldDelegate.phase != phase;
  }
}
