part of '../daily_dungeons_screen.dart';

double _prismRiftMaxStabilityFor(
  LightcoreDailyDungeonTowerProfile towerProfile,
) {
  final level = towerProfile.towerLevel;
  return 460 +
      (level * 82) +
      (math.pow(level, 1.25).toDouble() * 36) +
      (towerProfile.config.basePower * 6);
}

class _PrismRiftDungeonGame extends FlameGame {
  _PrismRiftDungeonGame({
    required this.controller,
    required this.towerProfile,
    required this.timeLimit,
    required this.snapshotNotifier,
    required this.onRunEnded,
  }) : _remainingSeconds = timeLimit.inSeconds.toDouble(),
       _riftStability = _prismRiftMaxStabilityFor(towerProfile),
       _random = math.Random(7301 + (towerProfile.towerLevel * 37));

  final LightcoreController controller;
  final LightcoreDailyDungeonTowerProfile towerProfile;
  final Duration timeLimit;
  final ValueNotifier<_PrismRiftRunSnapshot> snapshotNotifier;
  final void Function({required bool cleared}) onRunEnded;

  final List<_PrismRiftShard> _shards = <_PrismRiftShard>[];
  final List<_PrismRiftBeam> _beams = <_PrismRiftBeam>[];
  final List<_PrismRiftImpact> _impacts = <_PrismRiftImpact>[];
  final math.Random _random;
  late final double _riftMaxStability = _prismRiftMaxStabilityFor(towerProfile);

  double _remainingSeconds;
  double _riftStability;
  double _charge = 1;
  double _heat = 0;
  double _spawnTimer = 0;
  double _elapsed = 0;
  bool _running = true;
  bool _victory = false;
  bool _expired = false;
  bool _resultDispatched = false;
  bool _aiming = false;
  Offset? _aimTarget;
  int _combo = 0;
  int _wave = 1;
  int _shardCounter = 0;
  int _effectCounter = 0;

  @override
  Color backgroundColor() => Colors.transparent;

  void handleAimStart(Offset localPosition) {
    if (!_running || size.x <= 0 || size.y <= 0) {
      return;
    }
    _aiming = true;
    _aimTarget = _clampAimTarget(localPosition);
    _emitSnapshot();
  }

  void handleAimUpdate(Offset localPosition) {
    if (!_aiming || !_running || size.x <= 0 || size.y <= 0) {
      return;
    }
    _aimTarget = _clampAimTarget(localPosition);
    _emitSnapshot();
  }

  void handleAimEnd(Offset localPosition) {
    if (!_aiming || !_running || size.x <= 0 || size.y <= 0) {
      _aiming = false;
      return;
    }
    _aimTarget = _clampAimTarget(localPosition);
    final target = _aimTarget;
    _aiming = false;
    if (target != null) {
      _fireManualShot(target);
    }
    _emitSnapshot();
  }

  void handleAimCancel() {
    _aiming = false;
    _aimTarget = null;
    _emitSnapshot();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final clamped = dt.clamp(0.0, 0.05).toDouble();
    _elapsed += clamped;
    if (_running) {
      _advanceRun(clamped);
    }
    _updateVisualEffects(clamped);
    _emitSnapshot();
  }

  void _advanceRun(double dt) {
    _remainingSeconds = math.max(0.0, _remainingSeconds - dt);
    _wave = 1 + (_elapsed ~/ 11);
    _heat = math.max(0.0, _heat - (dt * 0.18));
    final chargeRate = towerProfile.chargeRate * (0.55 - (_heat * 0.22));
    _charge = math.min(1.0, _charge + (dt * chargeRate.clamp(0.18, 0.78)));
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 || _shards.length < _desiredShardCount) {
      _spawnShard();
    }
    _advanceShards(dt);

    final cleared = _riftStability <= 0;
    final expired = !cleared && _remainingSeconds <= 0;
    if (cleared || expired) {
      _finishRun(cleared: cleared);
    }
  }

  int get _desiredShardCount {
    return math.min(8, 3 + _wave + (towerProfile.towerLevel ~/ 16));
  }

  void _spawnShard() {
    if (_shards.length >= _desiredShardCount + 2) {
      _spawnTimer = _nextSpawnDelay;
      return;
    }
    final affinities = PrototypeAffinity.values;
    final affinity =
        affinities[(towerProfile.towerLevel + _wave + _shardCounter) %
            affinities.length];
    final boss = _wave >= 3 && _shardCounter % 9 == 8;
    final healthScale = boss ? 2.65 : 1.0;
    final shardHealth =
        towerProfile.shotDamage *
        (1.55 + (_wave * 0.18) + (_random.nextDouble() * 0.62)) *
        healthScale;
    final angularSign = _random.nextBool() ? 1.0 : -1.0;
    _shards.add(
      _PrismRiftShard(
        id: 'rift_shard_${_shardCounter++}',
        affinity: affinity,
        angle: _random.nextDouble() * math.pi * 2,
        angularVelocity:
            angularSign *
            (0.42 + (_random.nextDouble() * 0.26) + (_wave * 0.025)),
        orbitFactor: 0.34 + (_random.nextDouble() * 0.34) + (boss ? 0.04 : 0.0),
        maxHealth: shardHealth,
        health: shardHealth,
        radiusFactor: boss ? 0.052 : 0.034 + (_random.nextDouble() * 0.01),
        weakAngle: _random.nextDouble() * math.pi * 2,
        weakSpin: angularSign * (0.9 + (_random.nextDouble() * 0.8)),
        boss: boss,
      ),
    );
    _spawnTimer = _nextSpawnDelay;
  }

  double get _nextSpawnDelay {
    return (1.28 - (_wave * 0.06) - (towerProfile.towerLevel * 0.003))
        .clamp(0.54, 1.28)
        .toDouble();
  }

  void _advanceShards(double dt) {
    final advanced = _shards
        .map(
          (shard) => shard.copyWith(
            angle: shard.angle + (shard.angularVelocity * dt),
            weakAngle: shard.weakAngle + (shard.weakSpin * dt),
          ),
        )
        .toList(growable: false);
    _shards
      ..clear()
      ..addAll(advanced);
  }

  void _fireManualShot(Offset target) {
    if (_charge < 1 || _heat >= 0.98) {
      _addDryPulse(target);
      return;
    }
    final center = _arenaCenter;
    final shortest = math.min(size.x, size.y);
    final spec = _shotSpecFor(towerProfile.projectileType);
    final end = _projectAimEnd(center, target, shortest * spec.rangeFactor);
    final hits = _resolveHits(center, end, shortest, spec);
    final color = towerProfile.affinity.color;
    _beams.add(
      _PrismRiftBeam(
        id: 'rift_beam_${_effectCounter++}',
        start: center,
        end: end,
        color: hits.isEmpty ? LightcorePalette.stroke : color,
        width: shortest * spec.widthFactor * (hits.isEmpty ? 0.72 : 1.0),
        progress: 0,
        critical: hits.any((hit) => hit.weak),
        miss: hits.isEmpty,
      ),
    );

    if (hits.isEmpty) {
      _combo = 0;
      _heat = math.min(1.0, _heat + (spec.heatCost * 1.35));
    } else {
      final weakHit = hits.any((hit) => hit.weak);
      _applyHits(hits, spec);
      _combo = math.min(99, _combo + (weakHit ? 2 : 1));
      _heat = math.min(1.0, _heat + spec.heatCost);
    }
    _charge = 0;
  }

  void _addDryPulse(Offset target) {
    final center = _arenaCenter;
    final shortest = math.min(size.x, size.y);
    final end = _projectAimEnd(center, target, shortest * 0.52);
    _beams.add(
      _PrismRiftBeam(
        id: 'rift_dry_${_effectCounter++}',
        start: center,
        end: end,
        color: LightcorePalette.warning,
        width: shortest * 0.008,
        progress: 0,
        critical: false,
        miss: true,
      ),
    );
  }

  List<_PrismResolvedHit> _resolveHits(
    Offset start,
    Offset end,
    double shortest,
    _PrismManualShotSpec spec,
  ) {
    final candidates = <_PrismResolvedHit>[];
    for (final shard in _shards) {
      final shardPosition = _shardPosition(shard);
      final shardRadius = _shardRadius(shortest, shard);
      final projection = _projectionOnSegment(start, end, shardPosition);
      if (projection < 0 || projection > 1) {
        continue;
      }
      final impact = Offset.lerp(start, end, projection)!;
      final width = shortest * spec.widthFactor;
      final weakPoint = _weakPointPosition(shardPosition, shardRadius, shard);
      final weakDistance = _distanceToSegment(start, end, weakPoint);
      final weakHit = weakDistance <= width + (shardRadius * 0.22);
      final bodyDistance = (shardPosition - impact).distance;
      final bodyHit = bodyDistance <= shardRadius + width;
      if (!bodyHit && !weakHit) {
        continue;
      }
      candidates.add(
        _PrismResolvedHit(
          shardId: shard.id,
          impactPosition: weakHit ? weakPoint : impact,
          weak: weakHit,
          projection: projection,
        ),
      );
    }
    candidates.sort(
      (left, right) => left.projection.compareTo(right.projection),
    );
    if (candidates.isEmpty) {
      return candidates;
    }
    final hits = switch (towerProfile.projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.lance ||
      ProjectileBehaviorProfile.wave => candidates.take(3).toList(),
      ProjectileBehaviorProfile.split => candidates.take(2).toList(),
      ProjectileBehaviorProfile.nova || ProjectileBehaviorProfile.explosion =>
        _includeBlastHits(candidates.first, shortest * spec.blastFactor),
      ProjectileBehaviorProfile.chain => _includeChainHits(
        candidates.first,
        shortest * spec.blastFactor,
      ),
      _ => <_PrismResolvedHit>[candidates.first],
    };
    return hits.toList(growable: false);
  }

  List<_PrismResolvedHit> _includeBlastHits(
    _PrismResolvedHit primary,
    double radius,
  ) {
    final hits = <_PrismResolvedHit>[primary];
    for (final shard in _shards) {
      if (shard.id == primary.shardId) {
        continue;
      }
      final position = _shardPosition(shard);
      if ((position - primary.impactPosition).distance <= radius) {
        hits.add(
          _PrismResolvedHit(
            shardId: shard.id,
            impactPosition: position,
            weak: false,
            projection: primary.projection,
          ),
        );
      }
      if (hits.length >= 4) {
        break;
      }
    }
    return hits;
  }

  List<_PrismResolvedHit> _includeChainHits(
    _PrismResolvedHit primary,
    double radius,
  ) {
    final hits = <_PrismResolvedHit>[primary];
    var anchor = primary.impactPosition;
    for (var jump = 0; jump < 2; jump += 1) {
      _PrismRiftShard? nearest;
      var nearestDistance = double.infinity;
      for (final shard in _shards) {
        if (hits.any((hit) => hit.shardId == shard.id)) {
          continue;
        }
        final position = _shardPosition(shard);
        final distance = (position - anchor).distance;
        if (distance <= radius && distance < nearestDistance) {
          nearest = shard;
          nearestDistance = distance;
        }
      }
      if (nearest == null) {
        break;
      }
      anchor = _shardPosition(nearest);
      hits.add(
        _PrismResolvedHit(
          shardId: nearest.id,
          impactPosition: anchor,
          weak: false,
          projection: primary.projection,
        ),
      );
    }
    return hits;
  }

  void _applyHits(List<_PrismResolvedHit> hits, _PrismManualShotSpec spec) {
    for (final hit in hits) {
      final targetIndex = _shards.indexWhere(
        (shard) => shard.id == hit.shardId,
      );
      if (targetIndex < 0) {
        continue;
      }
      final shard = _shards[targetIndex];
      final comboBonus = math.min(0.68, _combo * 0.035);
      final affinityBonus = shard.affinity == towerProfile.affinity
          ? 1.18
          : 1.0;
      final weakBonus = hit.weak ? 1.88 : 1.0;
      final bossGuard = shard.boss ? 0.78 : 1.0;
      final damage =
          towerProfile.shotDamage *
          spec.damageMultiplier *
          (1 + comboBonus) *
          affinityBonus *
          weakBonus *
          bossGuard;
      final nextHealth = shard.health - damage;
      _riftStability = math.max(
        0.0,
        _riftStability - (damage * (hit.weak ? 0.92 : 0.62)),
      );
      _impacts.add(
        _PrismRiftImpact(
          id: 'rift_impact_${_effectCounter++}',
          position: hit.impactPosition,
          color: hit.weak ? LightcorePalette.solar : shard.affinity.color,
          radius: _shardRadius(math.min(size.x, size.y), shard),
          progress: 0,
          lethal: nextHealth <= 0,
        ),
      );
      if (nextHealth <= 0) {
        _shards.removeAt(targetIndex);
      } else {
        _shards[targetIndex] = shard.copyWith(health: nextHealth);
      }
    }
  }

  void _finishRun({required bool cleared}) {
    _running = false;
    _victory = cleared;
    _expired = !cleared;
    if (_resultDispatched) {
      return;
    }
    _resultDispatched = true;
    onRunEnded(cleared: cleared);
  }

  void _updateVisualEffects(double dt) {
    final nextBeams = _beams
        .map((beam) => beam.copyWith(progress: beam.progress + (dt * 3.4)))
        .where((beam) => beam.progress < 1)
        .toList(growable: false);
    final nextImpacts = _impacts
        .map(
          (impact) => impact.copyWith(
            progress: impact.progress + (dt * (impact.lethal ? 1.45 : 2.0)),
          ),
        )
        .where((impact) => impact.progress < 1)
        .toList(growable: false);
    _beams
      ..clear()
      ..addAll(nextBeams);
    _impacts
      ..clear()
      ..addAll(nextImpacts);
  }

  void _emitSnapshot() {
    snapshotNotifier.value = _PrismRiftRunSnapshot(
      remainingSeconds: _remainingSeconds,
      riftStability: _riftStability,
      riftMaxStability: _riftMaxStability,
      charge: _charge,
      heat: _heat,
      combo: _combo,
      wave: _wave,
      activeShards: _shards.length,
      aiming: _aiming,
      running: _running,
      victory: _victory,
      expired: _expired,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    final center = _arenaCenter;
    final shortest = math.min(size.x, size.y);
    _renderBackground(canvas, center, shortest);
    _renderArena(canvas, center, shortest);
    _renderAimPreview(canvas, center, shortest);
    _renderBeams(canvas);
    _renderShards(canvas, shortest);
    _renderImpacts(canvas);
    _renderCore(canvas, center, shortest);
  }

  void _renderBackground(Canvas canvas, Offset center, double shortest) {
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            LightcorePalette.night,
            LightcorePalette.abyss,
            Color(0xFF201D3C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                LightcorePalette.violet.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: shortest * 0.62),
            ),
    );
  }

  void _renderArena(Canvas canvas, Offset center, double shortest) {
    final pulse = 0.5 + (math.sin(_elapsed * 1.8) * 0.5);
    for (var index = 0; index < 4; index += 1) {
      canvas.drawCircle(
        center,
        shortest * (0.18 + (index * 0.12) + (pulse * 0.008)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 2 ? 2.2 : 1.2
          ..color = LightcorePalette.violet.withValues(
            alpha: index == 2 ? 0.38 : 0.2,
          ),
      );
    }
    final ringPath = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (-math.pi / 2) + (index * math.pi / 3);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * shortest * 0.37;
      if (index == 0) {
        ringPath.moveTo(point.dx, point.dy);
      } else {
        ringPath.lineTo(point.dx, point.dy);
      }
    }
    ringPath.close();
    canvas.drawPath(
      ringPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..color = towerProfile.affinity.color.withValues(alpha: 0.34),
    );
  }

  void _renderAimPreview(Canvas canvas, Offset center, double shortest) {
    final target = _aimTarget;
    if (!_aiming || target == null) {
      return;
    }
    final spec = _shotSpecFor(towerProfile.projectileType);
    final end = _projectAimEnd(center, target, shortest * spec.rangeFactor);
    final ready = _charge >= 1 && _heat < 0.98;
    final color = ready
        ? towerProfile.affinity.color
        : LightcorePalette.warning;
    final width = shortest * spec.widthFactor;
    canvas.drawLine(
      center,
      end,
      Paint()
        ..strokeWidth = (width * 2.1).clamp(3.0, 18.0).toDouble()
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: ready ? 0.18 : 0.12),
    );
    _drawGlowLine(
      canvas,
      center,
      end,
      color,
      width: ready ? 2.2 : 1.5,
      alpha: ready ? 0.72 : 0.42,
    );
    canvas.drawCircle(
      end,
      shortest * 0.028,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.78),
    );
    canvas.drawLine(
      end.translate(-shortest * 0.038, 0),
      end.translate(shortest * 0.038, 0),
      Paint()
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.58),
    );
    canvas.drawLine(
      end.translate(0, -shortest * 0.038),
      end.translate(0, shortest * 0.038),
      Paint()
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.58),
    );
  }

  void _renderShards(Canvas canvas, double shortest) {
    for (final shard in _shards) {
      final position = _shardPosition(shard);
      final radius = _shardRadius(shortest, shard);
      final color = shard.affinity.color;
      final weakPoint = _weakPointPosition(position, radius, shard);
      canvas.drawCircle(
        position,
        radius * 2.0,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..color = color.withValues(alpha: shard.boss ? 0.3 : 0.18),
      );
      canvas.drawPath(
        _hexPath(position, radius),
        Paint()..color = color.withValues(alpha: shard.boss ? 0.34 : 0.24),
      );
      canvas.drawPath(
        _hexPath(position, radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = shard.boss ? 3 : 2
          ..color = color.withValues(alpha: 0.82),
      );
      canvas.drawArc(
        Rect.fromCircle(center: position, radius: radius * 1.34),
        -math.pi / 2,
        math.pi * 2 * shard.healthFraction,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = LightcorePalette.success.withValues(alpha: 0.72),
      );
      canvas.drawCircle(
        weakPoint,
        radius * 0.22,
        Paint()..color = LightcorePalette.solar,
      );
      canvas.drawCircle(
        weakPoint,
        radius * 0.36,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = LightcorePalette.gilded.withValues(alpha: 0.76),
      );
    }
  }

  void _renderBeams(Canvas canvas) {
    for (final beam in _beams) {
      final progress = Curves.easeOut.transform(beam.progress);
      final end = Offset.lerp(beam.start, beam.end, progress)!;
      if (towerProfile.projectileType.behaviorProfile ==
              ProjectileBehaviorProfile.chain &&
          !beam.miss) {
        _drawEnergyBolt(
          canvas,
          beam.start,
          end,
          beam.color,
          width: beam.width.clamp(2.0, 8.0).toDouble(),
          amplitude: math.min(size.x, size.y) * 0.028,
          seed: _elapsed * 12 + beam.id.hashCode,
        );
      } else {
        _drawGlowLine(
          canvas,
          beam.start,
          end,
          beam.color,
          width: beam.width.clamp(2.0, 10.0).toDouble(),
          alpha: beam.miss ? 0.46 : 0.88,
        );
      }
      if (beam.critical) {
        canvas.drawCircle(
          end,
          math.min(size.x, size.y) * 0.026,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = LightcorePalette.solar.withValues(alpha: 0.82),
        );
      }
    }
  }

  void _renderImpacts(Canvas canvas) {
    for (final impact in _impacts) {
      final progress = Curves.easeOut.transform(impact.progress);
      canvas.drawCircle(
        impact.position,
        impact.radius * (0.8 + (progress * (impact.lethal ? 1.25 : 0.82))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = impact.lethal ? 3 : 2
          ..color = impact.color.withValues(alpha: (1 - progress) * 0.78),
      );
      if (impact.lethal) {
        canvas.drawPath(
          _hexPath(impact.position, impact.radius * (0.9 + progress)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = LightcorePalette.gilded.withValues(
              alpha: (1 - progress) * 0.62,
            ),
        );
      }
    }
  }

  void _renderCore(Canvas canvas, Offset center, double shortest) {
    final tint = towerProfile.affinity.color;
    final radius = shortest * 0.112;
    final stability = (_riftStability / _riftMaxStability)
        .clamp(0.0, 1.0)
        .toDouble();
    canvas.drawPath(
      _hexPath(center, radius * (1.16 + (math.sin(_elapsed * 2.4) * 0.03))),
      Paint()..color = LightcorePalette.violet.withValues(alpha: 0.13),
    );
    canvas.drawPath(
      _hexPath(center, radius),
      Paint()..color = LightcorePalette.night.withValues(alpha: 0.72),
    );
    canvas.drawPath(
      _hexPath(center, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = tint.withValues(alpha: 0.82),
    );
    _drawHexChargeIndicator(
      canvas,
      center,
      color: tint,
      radius: radius,
      chargeProgress: _charge,
      heatProgress: _heat,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.42),
      -math.pi / 2,
      math.pi * 2 * stability,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = LightcorePalette.violet.withValues(alpha: 0.84),
    );
    _paintIconGlyph(
      canvas,
      center,
      towerProjectileIcon(towerProfile.projectileType),
      size: radius * 0.58,
      color: tint,
    );
    _paintBadge(
      canvas,
      center.translate(0, radius * 0.72),
      'L${towerProfile.displayLevel}',
      color: LightcorePalette.mist,
      size: radius * 0.2,
    );
  }

  void _drawHexChargeIndicator(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required double chargeProgress,
    required double heatProgress,
  }) {
    final chargeRadius = radius * (0.24 + (chargeProgress * 0.48));
    canvas.drawPath(
      _hexPath(center, chargeRadius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.34 + (chargeProgress * 0.42)),
    );
    if (heatProgress > 0) {
      canvas.drawCircle(
        center,
        radius * (0.4 + (heatProgress * 0.76)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = LightcorePalette.warning.withValues(
            alpha: 0.16 + (heatProgress * 0.38),
          ),
      );
    }
  }

  _PrismManualShotSpec _shotSpecFor(ProjectileType projectileType) {
    return switch (projectileType.behaviorProfile) {
      ProjectileBehaviorProfile.thread => const _PrismManualShotSpec(
        damageMultiplier: 3.85,
        widthFactor: 0.012,
        rangeFactor: 0.62,
        heatCost: 0.2,
        blastFactor: 0.12,
      ),
      ProjectileBehaviorProfile.pulse => const _PrismManualShotSpec(
        damageMultiplier: 3.2,
        widthFactor: 0.019,
        rangeFactor: 0.6,
        heatCost: 0.16,
        blastFactor: 0.16,
      ),
      ProjectileBehaviorProfile.burst => const _PrismManualShotSpec(
        damageMultiplier: 3.55,
        widthFactor: 0.016,
        rangeFactor: 0.62,
        heatCost: 0.22,
        blastFactor: 0.18,
      ),
      ProjectileBehaviorProfile.chain => const _PrismManualShotSpec(
        damageMultiplier: 3.05,
        widthFactor: 0.016,
        rangeFactor: 0.6,
        heatCost: 0.22,
        blastFactor: 0.24,
      ),
      ProjectileBehaviorProfile.split => const _PrismManualShotSpec(
        damageMultiplier: 3.1,
        widthFactor: 0.021,
        rangeFactor: 0.58,
        heatCost: 0.2,
        blastFactor: 0.18,
      ),
      ProjectileBehaviorProfile.lance => const _PrismManualShotSpec(
        damageMultiplier: 4.05,
        widthFactor: 0.011,
        rangeFactor: 0.7,
        heatCost: 0.25,
        blastFactor: 0.14,
      ),
      ProjectileBehaviorProfile.explosion => const _PrismManualShotSpec(
        damageMultiplier: 3.45,
        widthFactor: 0.018,
        rangeFactor: 0.58,
        heatCost: 0.28,
        blastFactor: 0.22,
      ),
      ProjectileBehaviorProfile.wave => const _PrismManualShotSpec(
        damageMultiplier: 2.75,
        widthFactor: 0.03,
        rangeFactor: 0.54,
        heatCost: 0.18,
        blastFactor: 0.18,
      ),
      ProjectileBehaviorProfile.nova => const _PrismManualShotSpec(
        damageMultiplier: 3.75,
        widthFactor: 0.022,
        rangeFactor: 0.6,
        heatCost: 0.32,
        blastFactor: 0.28,
      ),
    };
  }

  Offset _clampAimTarget(Offset localPosition) {
    return Offset(
      localPosition.dx.clamp(0.0, size.x).toDouble(),
      localPosition.dy.clamp(0.0, size.y).toDouble(),
    );
  }

  Offset _projectAimEnd(Offset start, Offset target, double range) {
    final delta = target - start;
    if (delta.distance <= 0.001) {
      return start.translate(0, -range);
    }
    return start + (delta / delta.distance) * range;
  }

  Offset _shardPosition(_PrismRiftShard shard) {
    final shortest = math.min(size.x, size.y);
    final center = _arenaCenter;
    final drift =
        math.sin(_elapsed * 1.35 + shard.angle * 0.7) * shortest * 0.018;
    final radius = (shortest * shard.orbitFactor) + drift;
    return center +
        Offset(math.cos(shard.angle), math.sin(shard.angle)) * radius;
  }

  double _shardRadius(double shortest, _PrismRiftShard shard) {
    return shortest * shard.radiusFactor;
  }

  Offset _weakPointPosition(
    Offset shardPosition,
    double shardRadius,
    _PrismRiftShard shard,
  ) {
    return shardPosition +
        Offset(math.cos(shard.weakAngle), math.sin(shard.weakAngle)) *
            shardRadius *
            0.72;
  }

  double _projectionOnSegment(Offset start, Offset end, Offset point) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared <= 0) {
      return 0;
    }
    final relative = point - start;
    return ((relative.dx * segment.dx) + (relative.dy * segment.dy)) /
        lengthSquared;
  }

  double _distanceToSegment(Offset start, Offset end, Offset point) {
    final projection = _projectionOnSegment(
      start,
      end,
      point,
    ).clamp(0.0, 1.0).toDouble();
    final nearest = Offset.lerp(start, end, projection)!;
    return (point - nearest).distance;
  }

  Offset get _arenaCenter => Offset(size.x / 2, size.y / 2);

  void _drawGlowLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
    double alpha = 0.84,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width + 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: alpha * 0.22),
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha),
    );
  }

  void _drawEnergyBolt(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color, {
    required double width,
    required double amplitude,
    required double seed,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance <= 0) {
      return;
    }
    final normal = Offset(-delta.dy / distance, delta.dx / distance);
    final path = Path()..moveTo(start.dx, start.dy);
    const segments = 7;
    for (var index = 1; index <= segments; index += 1) {
      final t = index / segments;
      final base = Offset.lerp(start, end, t)!;
      final jitter =
          math.sin((seed * 0.017) + (index * 2.23)) *
          amplitude *
          (1 - ((t - 0.5).abs() * 0.9));
      final point = base + (normal * jitter);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = color.withValues(alpha: 0.2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.86),
    );
  }

  void _paintIconGlyph(
    Canvas canvas,
    Offset center,
    IconData icon, {
    required double size,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  void _paintBadge(
    Canvas canvas,
    Offset center,
    String text, {
    required Color color,
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index += 1) {
      final angle = (math.pi / 6) + (index * math.pi / 3);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
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
}

class _PrismRiftShard {
  const _PrismRiftShard({
    required this.id,
    required this.affinity,
    required this.angle,
    required this.angularVelocity,
    required this.orbitFactor,
    required this.maxHealth,
    required this.health,
    required this.radiusFactor,
    required this.weakAngle,
    required this.weakSpin,
    required this.boss,
  });

  final String id;
  final PrototypeAffinity affinity;
  final double angle;
  final double angularVelocity;
  final double orbitFactor;
  final double maxHealth;
  final double health;
  final double radiusFactor;
  final double weakAngle;
  final double weakSpin;
  final bool boss;

  double get healthFraction =>
      maxHealth <= 0 ? 0 : (health / maxHealth).clamp(0.0, 1.0).toDouble();

  _PrismRiftShard copyWith({double? angle, double? weakAngle, double? health}) {
    return _PrismRiftShard(
      id: id,
      affinity: affinity,
      angle: angle ?? this.angle,
      angularVelocity: angularVelocity,
      orbitFactor: orbitFactor,
      maxHealth: maxHealth,
      health: health ?? this.health,
      radiusFactor: radiusFactor,
      weakAngle: weakAngle ?? this.weakAngle,
      weakSpin: weakSpin,
      boss: boss,
    );
  }
}

class _PrismRiftBeam {
  const _PrismRiftBeam({
    required this.id,
    required this.start,
    required this.end,
    required this.color,
    required this.width,
    required this.progress,
    required this.critical,
    required this.miss,
  });

  final String id;
  final Offset start;
  final Offset end;
  final Color color;
  final double width;
  final double progress;
  final bool critical;
  final bool miss;

  _PrismRiftBeam copyWith({double? progress}) {
    return _PrismRiftBeam(
      id: id,
      start: start,
      end: end,
      color: color,
      width: width,
      progress: progress ?? this.progress,
      critical: critical,
      miss: miss,
    );
  }
}

class _PrismRiftImpact {
  const _PrismRiftImpact({
    required this.id,
    required this.position,
    required this.color,
    required this.radius,
    required this.progress,
    required this.lethal,
  });

  final String id;
  final Offset position;
  final Color color;
  final double radius;
  final double progress;
  final bool lethal;

  _PrismRiftImpact copyWith({double? progress}) {
    return _PrismRiftImpact(
      id: id,
      position: position,
      color: color,
      radius: radius,
      progress: progress ?? this.progress,
      lethal: lethal,
    );
  }
}

class _PrismResolvedHit {
  const _PrismResolvedHit({
    required this.shardId,
    required this.impactPosition,
    required this.weak,
    required this.projection,
  });

  final String shardId;
  final Offset impactPosition;
  final bool weak;
  final double projection;
}

class _PrismManualShotSpec {
  const _PrismManualShotSpec({
    required this.damageMultiplier,
    required this.widthFactor,
    required this.rangeFactor,
    required this.heatCost,
    required this.blastFactor,
  });

  final double damageMultiplier;
  final double widthFactor;
  final double rangeFactor;
  final double heatCost;
  final double blastFactor;
}
