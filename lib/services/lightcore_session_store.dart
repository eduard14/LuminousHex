import 'package:shared_preferences/shared_preferences.dart';

class LightcoreSessionStore {
  static const String _playerIdKey = 'lightcore.player_id';
  static const String _guideIdKey = 'lightcore.guide_id';
  static const String _graphicsQualityKey = 'lightcore.graphics_quality';
  static const String _musicEnabledKey = 'lightcore.audio.music_enabled';
  static const String _soundEffectsEnabledKey =
      'lightcore.audio.sound_effects_enabled';
  static const String _skipGuestSignInPromptKey =
      'lightcore.skip_guest_sign_in_prompt';

  Future<String?> readPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playerIdKey);
  }

  Future<void> writePlayerId(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerIdKey, playerId);
  }

  Future<String?> readGuideId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guideIdKey);
  }

  Future<void> writeGuideId(String guideId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guideIdKey, guideId);
  }

  Future<String?> readGraphicsQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_graphicsQualityKey);
  }

  Future<void> writeGraphicsQuality(String graphicsQuality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_graphicsQualityKey, graphicsQuality);
  }

  Future<bool> readMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  Future<void> writeMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);
  }

  Future<bool> readSoundEffectsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEffectsEnabledKey) ?? true;
  }

  Future<void> writeSoundEffectsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsEnabledKey, enabled);
  }

  Future<bool> readSkipGuestSignInPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipGuestSignInPromptKey) ?? false;
  }

  Future<void> writeSkipGuestSignInPrompt(bool skipPrompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipGuestSignInPromptKey, skipPrompt);
  }
}
