import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/player_progress.dart';
import '../services/storage/key_value_store.dart';

/// Persistence boundary for player data. A backend (cloud save) can
/// implement this interface without touching game code.
abstract class ProgressRepository {
  PlayerProgress loadProgress();
  Future<void> saveProgress(PlayerProgress p);
  AppSettings loadSettings();
  Future<void> saveSettings(AppSettings s);
  Future<void> reset();
}

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._store);
  final KeyValueStore _store;

  static const _progressKey = 'sortsphere.progress.v1';
  static const _settingsKey = 'sortsphere.settings.v1';

  @override
  PlayerProgress loadProgress() {
    final raw = _store.getString(_progressKey);
    if (raw == null) return PlayerProgress(firstLaunch: DateTime.now().millisecondsSinceEpoch);
    try {
      return PlayerProgress.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object catch (e) {
      debugPrint('Corrupt progress, starting fresh: $e');
      return PlayerProgress(firstLaunch: DateTime.now().millisecondsSinceEpoch);
    }
  }

  @override
  Future<void> saveProgress(PlayerProgress p) => _store.setString(_progressKey, jsonEncode(p.toJson()));

  @override
  AppSettings loadSettings() {
    final raw = _store.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings s) => _store.setString(_settingsKey, jsonEncode(s.toJson()));

  @override
  Future<void> reset() async {
    await _store.remove(_progressKey);
  }
}
