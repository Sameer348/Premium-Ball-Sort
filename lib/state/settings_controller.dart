import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../repositories/progress_repository.dart';
import '../services/audio/audio_service.dart';
import '../services/haptics/haptics_service.dart';
import '../services/notifications/notification_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required ProgressRepository repo,
    required this.audio,
    required this.haptics,
    required this.notifications,
  })  : _repo = repo,
        _settings = repo.loadSettings() {
    haptics.enabled = _settings.haptics;
  }

  final ProgressRepository _repo;
  final AudioService audio;
  final HapticsService haptics;
  final NotificationService notifications;
  AppSettings _settings;

  AppSettings get value => _settings;

  void update(AppSettings next) {
    final prev = _settings;
    _settings = next;
    if (prev.music != next.music) audio.setMusic(next.music);
    if (prev.sfx != next.sfx) audio.setSfx(next.sfx);
    if (prev.notifications != next.notifications) notifications.setDailyReminder(next.notifications);
    haptics.enabled = next.haptics;
    _repo.saveSettings(next);
    notifyListeners();
  }
}
