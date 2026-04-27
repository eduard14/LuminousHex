part of '../lightcore_controller.dart';

extension LightcoreControllerSaveSocialBalance on LightcoreController {
  Map<String, dynamic>? _serializeGuildState(GuildState? guild) {
    if (guild == null) {
      return null;
    }
    return <String, dynamic>{
      'id': guild.id,
      'name': guild.name,
      'motto': guild.motto,
      'memberCap': guild.memberCap,
      'members': guild.members
          .map(
            (member) => <String, dynamic>{
              'playerId': member.playerId,
              'displayName': member.displayName,
              'role': member.role.name,
              'level': member.level,
              'slotIndex': member.slotIndex,
              'readiness': member.readiness,
              'isLocalPlayer': member.isLocalPlayer,
              'isOnline': member.isOnline,
              'contributedTower': _serializeFriendRelayTower(
                member.contributedTower,
              ),
            },
          )
          .toList(growable: false),
      'chatMessages': guild.chatMessages
          .map(
            (message) => <String, dynamic>{
              'id': message.id,
              'authorLabel': message.authorLabel,
              'message': message.message,
              'sentAtSeconds': message.sentAtSeconds,
              'isLocalPlayer': message.isLocalPlayer,
              'isSystem': message.isSystem,
            },
          )
          .toList(growable: false),
    };
  }

  GuildState? _deserializeGuildState(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    return GuildState(
      id: _stringOrNull(data['id']) ?? 'guild',
      name: _stringOrNull(data['name']) ?? 'Recovered Guild',
      motto: _stringOrNull(data['motto']) ?? '',
      memberCap: _intValue(data['memberCap'], fallback: guildMemberCap),
      members: _coerceList(data['members'])
          .map((item) => _deserializeGuildMember(_coerceMap(item)))
          .whereType<GuildMemberSnapshot>()
          .toList(growable: false),
      chatMessages: _coerceList(data['chatMessages'])
          .map((item) => _deserializeGuildChatMessage(_coerceMap(item)))
          .whereType<GuildChatMessage>()
          .toList(growable: false),
    );
  }

  GuildMemberSnapshot? _deserializeGuildMember(Map<String, dynamic> data) {
    final role = _enumByName(
      GuildMemberRole.values,
      _stringOrNull(data['role']),
    );
    if (role == null) {
      return null;
    }
    return GuildMemberSnapshot(
      playerId: _stringOrNull(data['playerId']) ?? 'guild-member',
      displayName: _stringOrNull(data['displayName']) ?? 'Pilot',
      role: role,
      level: _intValue(data['level'], fallback: 1),
      slotIndex: _intValue(data['slotIndex']),
      contributedTower: _deserializeFriendRelayTower(
        _coerceMap(data['contributedTower']),
      ),
      readiness: _doubleValue(data['readiness']),
      isLocalPlayer: _boolValue(data['isLocalPlayer']),
      isOnline: _boolValue(data['isOnline']),
    );
  }

  GuildChatMessage? _deserializeGuildChatMessage(Map<String, dynamic> data) {
    final id = _stringOrNull(data['id']);
    if (id == null) {
      return null;
    }
    return GuildChatMessage(
      id: id,
      authorLabel: _stringOrNull(data['authorLabel']) ?? 'System',
      message: _stringOrNull(data['message']) ?? '',
      sentAtSeconds: _doubleValue(data['sentAtSeconds']),
      isLocalPlayer: _boolValue(data['isLocalPlayer']),
      isSystem: _boolValue(data['isSystem']),
    );
  }

  Map<String, dynamic> _serializeFriendRelayTower(FriendRelayTower tower) {
    return <String, dynamic>{
      'center': tower.center == null
          ? null
          : _serializeFriendRelayPiece(tower.center!),
      'outerPieces': tower.outerPieces
          .map(
            (piece) => piece == null ? null : _serializeFriendRelayPiece(piece),
          )
          .toList(growable: false),
    };
  }

  FriendRelayTower _deserializeFriendRelayTower(Map<String, dynamic> data) {
    return FriendRelayTower(
      center: _deserializeFriendRelayPiece(_coerceMap(data['center'])),
      outerPieces: _coerceList(data['outerPieces'])
          .map(
            (item) => item == null
                ? null
                : _deserializeFriendRelayPiece(_coerceMap(item)),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> _serializeFriendRelayPiece(FriendRelayPiece piece) {
    return <String, dynamic>{
      'id': piece.id,
      'kind': piece.kind.name,
      'title': piece.title,
      'ownerLabel': piece.ownerLabel,
      'sourceLabel': piece.sourceLabel,
      'affinity': piece.affinity.name,
      'level': piece.level,
      'tier': piece.tier,
      'powerScore': piece.powerScore,
      'projectileType': piece.projectileType?.name,
      'payloadType': piece.payloadType?.name,
    };
  }

  FriendRelayPiece? _deserializeFriendRelayPiece(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }
    final kind = _enumByName(
      FriendRelayPieceKind.values,
      _stringOrNull(data['kind']),
    );
    final affinity = _enumByName(
      PrototypeAffinity.values,
      _stringOrNull(data['affinity']),
    );
    if (kind == null || affinity == null) {
      return null;
    }
    return FriendRelayPiece(
      id: _stringOrNull(data['id']) ?? 'relay-piece',
      kind: kind,
      title: _stringOrNull(data['title']) ?? 'Recovered Piece',
      ownerLabel: _stringOrNull(data['ownerLabel']) ?? 'Pilot',
      sourceLabel: _stringOrNull(data['sourceLabel']) ?? '',
      affinity: affinity,
      level: _intValue(data['level'], fallback: 1),
      tier: _intValue(data['tier'], fallback: 1),
      powerScore: _doubleValue(data['powerScore']),
      projectileType: _enumByName(
        ProjectileType.values,
        _stringOrNull(data['projectileType']),
      ),
      payloadType: _enumByName(
        PayloadType.values,
        _stringOrNull(data['payloadType']),
      ),
    );
  }

  TowerLayerSnapshot? _layerForId(String? layerId) {
    if (layerId == null) {
      return null;
    }
    for (final layer in _layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  TowerLayerSnapshot _liveLayerForLayer(TowerLayerSnapshot layer) {
    if (!isLayerPassiveOnly(layer)) {
      return layer;
    }
    return _layerForId(layer.promotedParentLayerId) ??
        _layerForId(layer.parentLayerId) ??
        layer;
  }

  TowerConfig? _towerConfigById(String? configId) {
    if (configId == null) {
      return null;
    }
    for (final config in TowerLibrary.all) {
      if (config.id == configId) {
        return config;
      }
    }
    return null;
  }

  CardConfig? _cardConfigById(String? configId) {
    if (configId == null) {
      return null;
    }
    for (final config in CardLibrary.templates) {
      if (config.id == configId) {
        return config;
      }
    }
    return null;
  }

  EnemyManagerConfig? _enemyManagerConfigById(String? configId) {
    if (configId == null) {
      return null;
    }
    for (final config in EnemyManagerLibrary.all) {
      if (config.id == configId) {
        return config;
      }
    }
    return null;
  }

  EquipmentBonusProfile get _activeProfileBonuses =>
      profileLoadoutBonuses + globalLevelBonuses;

  double get _gearPowerMultiplier => 1 + _activeProfileBonuses.towerPower;

  double get _gearChargeMultiplier => 1 + _activeProfileBonuses.chargeRate;

  double get _gearRangeMultiplier => 1 + _activeProfileBonuses.range;

  double get _gearCritChanceBonus => _activeProfileBonuses.critChance;

  double get _gearCritDamageMultiplier => 1 + _activeProfileBonuses.critDamage;

  double get _gearBossDamageMultiplier => 1 + _activeProfileBonuses.bossDamage;

  double get _gearLumenMultiplier => 1 + _activeProfileBonuses.lumenGain;

  double get _gearFluxMultiplier => 1 + _activeProfileBonuses.fluxGain;

  double get _gearTicketMultiplier => 1 + _activeProfileBonuses.ticketGain;

  double _towerBalanceMultiplier(TowerConfig config, String stat) =>
      _balanceTuning.towerMultiplier(config.id, stat);

  double _enemyBalanceMultiplier(EnemyConfig config, String stat) =>
      _balanceTuning.enemyMultiplier(config.id, stat);

  double _economyBalanceMultiplier(String stat) =>
      _balanceTuning.economyMultiplier(stat);

  double _balancedTowerStat(TowerConfig config, String stat, double value) =>
      value * _towerBalanceMultiplier(config, stat);

  double _balancedEnemyStat(EnemyConfig config, String stat, double value) =>
      value * _enemyBalanceMultiplier(config, stat);

  LightcoreOfflineProgressSnapshot buildOfflineProgressSnapshot() {
    return LightcoreOfflineProgressSnapshot(
      generatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      passiveLumensPerHour: passiveLumenPerSecond * 3600,
      fluxPerHour: 0,
      enemyTicketsPerHour: 0,
      killsPerHour: offlineKillsPerHour,
      activeLayerTier: activeLayer.tier,
      builtTowerCount: builtTowerCount,
      prestigeLevel: prestigeLevel,
    );
  }

  LightcoreTournamentPlayerSnapshot buildTournamentSnapshot() {
    return const LightcoreTournamentPlayerSnapshot(
      overallLevel: evenEntryTournamentLevel,
      prestigeLevel: 0,
      activeLayerTier: 1,
      builtTowerCount: slotCount,
      coreLevel: evenEntryTournamentCoreLevel,
      towerPowerIndex: evenEntryTournamentPowerIndex,
    );
  }
}
