import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

// Generated music and friendly cues are centered on A minor; warning/error
// cues intentionally use dissonant intervals so they read as negative feedback.
enum LightcoreMusicTrack { mainMenu, battle }

enum LightcoreSfx {
  uiTap,
  uiConfirm,
  uiCancel,
  uiError,
  panelOpen,
  panelClose,
  rewardClaim,
  relayCharge,
  coreFire,
  hit,
  critHit,
  enemySpawn,
  enemyDeath,
  bossSpawn,
  bossDeath,
  coreDamage,
  buildTower,
  buildUpgrade,
  overdriveStart,
  overdriveEnd,
  promotionComplete,
}

class LightcoreAudio {
  LightcoreAudio._();

  static final LightcoreAudio instance = LightcoreAudio._();

  bool _initialized = false;
  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  bool _userGestureSeen = false;
  bool _musicStartPending = false;
  Future<void>? _initializing;
  LightcoreMusicTrack? _desiredMusicTrack;
  LightcoreMusicTrack? _currentMusicTrack;
  final Map<LightcoreSfx, DateTime> _lastSfxAt = <LightcoreSfx, DateTime>{};

  bool get musicEnabled => _musicEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;

  Future<void> initialize({
    required bool musicEnabled,
    required bool soundEffectsEnabled,
  }) async {
    _musicEnabled = musicEnabled;
    _soundEffectsEnabled = soundEffectsEnabled;
    await _ensureInitialized();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    if (_musicEnabled == enabled) {
      return;
    }
    _musicEnabled = enabled;
    if (!enabled) {
      _musicStartPending = false;
      _currentMusicTrack = null;
      await _stopBgm();
      return;
    }
    final desired = _desiredMusicTrack;
    if (desired != null) {
      await playMusic(desired);
    }
  }

  void setSoundEffectsEnabled(bool enabled) {
    _soundEffectsEnabled = enabled;
  }

  void noteUserGesture() {
    _userGestureSeen = true;
    if (_musicStartPending && _desiredMusicTrack != null && _musicEnabled) {
      unawaited(playMusic(_desiredMusicTrack!));
    }
  }

  Future<void> playMusic(LightcoreMusicTrack track) async {
    _desiredMusicTrack = track;
    if (!_musicEnabled) {
      return;
    }
    if (!_platformAudioAvailable) {
      _musicStartPending = true;
      return;
    }
    if (_currentMusicTrack == track && !_musicStartPending) {
      return;
    }
    await _ensureInitialized();
    try {
      await FlameAudio.bgm.play(track.fileName, volume: track.volume);
      _currentMusicTrack = track;
      _musicStartPending = false;
    } catch (error, stackTrace) {
      _musicStartPending = !_userGestureSeen;
      _logAudioError('music:${track.name}', error, stackTrace);
    }
  }

  Future<void> stopMusic() async {
    _desiredMusicTrack = null;
    _musicStartPending = false;
    _currentMusicTrack = null;
    await _stopBgm();
  }

  void playSfx(LightcoreSfx sfx, {Duration? cooldown}) {
    if (!_soundEffectsEnabled) {
      return;
    }
    final now = DateTime.now();
    final minimumGap = cooldown ?? sfx.cooldown;
    final lastPlayed = _lastSfxAt[sfx];
    if (lastPlayed != null && now.difference(lastPlayed) < minimumGap) {
      return;
    }
    _lastSfxAt[sfx] = now;
    unawaited(_playSfx(sfx));
  }

  Future<void> dispose() async {
    _initializing = null;
    _desiredMusicTrack = null;
    _currentMusicTrack = null;
    _musicStartPending = false;
    _lastSfxAt.clear();
    await _stopBgm();
  }

  Future<void> _playSfx(LightcoreSfx sfx) async {
    if (!_platformAudioAvailable) {
      return;
    }
    await _ensureInitialized();
    if (!_soundEffectsEnabled) {
      return;
    }
    try {
      await FlameAudio.play(sfx.fileName, volume: sfx.volume);
    } catch (error, stackTrace) {
      _logAudioError('sfx:${sfx.name}', error, stackTrace);
    }
  }

  Future<void> _ensureInitialized() {
    if (!_platformAudioAvailable) {
      return Future<void>.value();
    }
    if (_initialized) {
      return Future<void>.value();
    }
    final initializing = _initializing;
    if (initializing != null) {
      return initializing;
    }
    return _initializing = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await FlameAudio.bgm.initialize();
      _initialized = true;
    } catch (error, stackTrace) {
      _initialized = true;
      _logAudioError('initialize', error, stackTrace);
    } finally {
      _initializing = null;
    }
  }

  Future<void> _stopBgm() async {
    if (!_platformAudioAvailable) {
      return;
    }
    try {
      await FlameAudio.bgm.stop();
    } catch (error, stackTrace) {
      _logAudioError('stop', error, stackTrace);
    }
  }

  void _logAudioError(String context, Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[LightcoreAudio] $context failed: $error');
    debugPrintStack(stackTrace: stackTrace, label: 'LightcoreAudio');
  }

  bool get _platformAudioAvailable {
    var available = true;
    assert(() {
      available = BindingBase.debugBindingType() != null;
      return true;
    }());
    return available;
  }
}

extension on LightcoreMusicTrack {
  String get fileName => switch (this) {
    LightcoreMusicTrack.mainMenu => 'music/main_menu_loop.wav',
    LightcoreMusicTrack.battle => 'music/battle_loop.wav',
  };

  double get volume => switch (this) {
    LightcoreMusicTrack.mainMenu => 0.28,
    LightcoreMusicTrack.battle => 0.24,
  };
}

extension on LightcoreSfx {
  String get fileName => switch (this) {
    LightcoreSfx.uiTap => 'sfx/ui_tap.wav',
    LightcoreSfx.uiConfirm => 'sfx/ui_confirm.wav',
    LightcoreSfx.uiCancel => 'sfx/ui_cancel.wav',
    LightcoreSfx.uiError => 'sfx/ui_error.wav',
    LightcoreSfx.panelOpen => 'sfx/panel_open.wav',
    LightcoreSfx.panelClose => 'sfx/panel_close.wav',
    LightcoreSfx.rewardClaim => 'sfx/reward_claim.wav',
    LightcoreSfx.relayCharge => 'sfx/relay_charge.wav',
    LightcoreSfx.coreFire => 'sfx/core_fire.wav',
    LightcoreSfx.hit => 'sfx/hit.wav',
    LightcoreSfx.critHit => 'sfx/crit_hit.wav',
    LightcoreSfx.enemySpawn => 'sfx/enemy_spawn.wav',
    LightcoreSfx.enemyDeath => 'sfx/enemy_death.wav',
    LightcoreSfx.bossSpawn => 'sfx/boss_spawn.wav',
    LightcoreSfx.bossDeath => 'sfx/boss_death.wav',
    LightcoreSfx.coreDamage => 'sfx/core_damage.wav',
    LightcoreSfx.buildTower => 'sfx/build_tower.wav',
    LightcoreSfx.buildUpgrade => 'sfx/build_upgrade.wav',
    LightcoreSfx.overdriveStart => 'sfx/overdrive_start.wav',
    LightcoreSfx.overdriveEnd => 'sfx/overdrive_end.wav',
    LightcoreSfx.promotionComplete => 'sfx/promotion_complete.wav',
  };

  double get volume => switch (this) {
    LightcoreSfx.uiTap => 0.32,
    LightcoreSfx.uiConfirm => 0.42,
    LightcoreSfx.uiCancel => 0.34,
    LightcoreSfx.uiError => 0.46,
    LightcoreSfx.panelOpen => 0.36,
    LightcoreSfx.panelClose => 0.32,
    LightcoreSfx.rewardClaim => 0.48,
    LightcoreSfx.relayCharge => 0.26,
    LightcoreSfx.coreFire => 0.22,
    LightcoreSfx.hit => 0.18,
    LightcoreSfx.critHit => 0.30,
    LightcoreSfx.enemySpawn => 0.18,
    LightcoreSfx.enemyDeath => 0.28,
    LightcoreSfx.bossSpawn => 0.42,
    LightcoreSfx.bossDeath => 0.50,
    LightcoreSfx.coreDamage => 0.46,
    LightcoreSfx.buildTower => 0.42,
    LightcoreSfx.buildUpgrade => 0.38,
    LightcoreSfx.overdriveStart => 0.38,
    LightcoreSfx.overdriveEnd => 0.28,
    LightcoreSfx.promotionComplete => 0.52,
  };

  Duration get cooldown => switch (this) {
    LightcoreSfx.coreFire => const Duration(milliseconds: 65),
    LightcoreSfx.hit => const Duration(milliseconds: 45),
    LightcoreSfx.critHit => const Duration(milliseconds: 80),
    LightcoreSfx.enemySpawn => const Duration(milliseconds: 220),
    LightcoreSfx.enemyDeath => const Duration(milliseconds: 80),
    LightcoreSfx.relayCharge => const Duration(milliseconds: 120),
    LightcoreSfx.coreDamage => const Duration(milliseconds: 260),
    LightcoreSfx.uiTap => const Duration(milliseconds: 45),
    _ => const Duration(milliseconds: 90),
  };
}
