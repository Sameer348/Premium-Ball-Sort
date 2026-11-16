import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx {
  select('select'),
  pickup('pickup'),
  move('move'),
  drop('drop'),
  invalid('invalid'),
  tubeComplete('tube_complete'),
  levelComplete('level_complete'),
  coin('coin'),
  star('star'),
  button('button'),
  booster('booster'),
  achievement('achievement');

  const Sfx(this.file);
  final String file;
  String get asset => 'sounds/$file.wav';
}

/// Ambient music + pooled low-latency effects. Fire-and-forget and
/// failure-tolerant: audio must never crash or stall gameplay.
class AudioService {
  bool _musicOn = true;
  bool _sfxOn = true;
  bool _ready = false;
  final Map<Sfx, AudioPool> _pools = {};
  AudioPlayer? _music;
  int _dropPitch = 0;

  Future<void> init({required bool music, required bool sfx}) async {
    _musicOn = music;
    _sfxOn = sfx;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
      for (final s in Sfx.values) {
        _pools[s] = await AudioPool.createFromAsset(
          path: s.asset,
          maxPlayers: s == Sfx.drop || s == Sfx.select ? 4 : 2,
          playerMode: PlayerMode.lowLatency,
        );
      }
      _music = AudioPlayer(playerId: 'music');
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.28);
      _ready = true;
      if (_musicOn) unawaited(_startMusic());
    } on Object catch (e) {
      debugPrint('Audio unavailable: $e');
    }
  }

  Future<void> _startMusic() async {
    try {
      await _music?.play(AssetSource('music/ambient_loop.wav'));
    } on Object catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  void setMusic(bool on) {
    _musicOn = on;
    if (!_ready) return;
    on ? unawaited(_startMusic()) : unawaited(_music?.pause());
  }

  void setSfx(bool on) => _sfxOn = on;

  void play(Sfx s, {double volume = 0.8}) {
    if (!_sfxOn || !_ready) return;
    final pool = _pools[s];
    if (pool == null) return;
    pool.start(volume: volume).catchError((Object e) {
      debugPrint('Sfx $s failed: $e');
      return () async {};
    });
  }

  /// Landing sound; volume varies slightly so repeated drops feel organic.
  void drop() {
    _dropPitch = (_dropPitch + 1) % 3;
    play(Sfx.drop, volume: 0.6 + _dropPitch * 0.08);
  }

  void onBackground() => unawaited(_music?.pause());
  void onForeground() {
    if (_musicOn && _ready) unawaited(_music?.resume());
  }

  Future<void> dispose() async {
    for (final p in _pools.values) {
      await p.dispose();
    }
    await _music?.dispose();
  }
}
