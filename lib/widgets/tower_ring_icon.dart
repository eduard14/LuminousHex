import 'dart:math' as math;

import 'package:flutter/material.dart';

class TowerRingIcon extends StatelessWidget {
  const TowerRingIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor =
        color ??
        iconTheme.color ??
        DefaultTextStyle.of(context).style.color ??
        Colors.white;

    return SizedBox.square(
      dimension: resolvedSize,
      child: CustomPaint(painter: _TowerRingIconPainter(color: resolvedColor)),
    );
  }
}

class _TowerRingIconPainter extends CustomPainter {
  const _TowerRingIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = shortestSide * 0.36;
    final innerRadius = shortestSide * 0.17;
    final nodeRadius = shortestSide * 0.105;
    final outerNodes = List<Offset>.generate(
      6,
      (index) => Offset(
        center.dx + (outerRadius * math.cos(_angleForIndex(index))),
        center.dy + (outerRadius * math.sin(_angleForIndex(index))),
      ),
    );
    final innerNodes = List<Offset>.generate(
      6,
      (index) => Offset(
        center.dx + (innerRadius * math.cos(_angleForIndex(index))),
        center.dy + (innerRadius * math.sin(_angleForIndex(index))),
      ),
    );
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortestSide * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.88);
    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortestSide * 0.055
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.52);
    final nodePaint = Paint()..color = color;

    for (var index = 0; index < outerNodes.length; index += 1) {
      canvas.drawLine(innerNodes[index], outerNodes[index], spokePaint);
    }

    canvas.drawPath(_polygonPath(outerNodes), ringPaint);
    canvas.drawPath(_polygonPath(innerNodes), ringPaint);

    for (final node in outerNodes) {
      canvas.drawCircle(node, nodeRadius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TowerRingIconPainter oldDelegate) =>
      oldDelegate.color != color;

  double _angleForIndex(int index) => (-math.pi / 2) + (index * (math.pi / 3));

  Path _polygonPath(List<Offset> vertices) {
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (final vertex in vertices.skip(1)) {
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();
    return path;
  }
}
