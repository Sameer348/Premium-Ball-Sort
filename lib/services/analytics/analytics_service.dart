import 'package:flutter/foundation.dart';

enum AnalyticsEvent {
  levelStarted('level_started'),
  levelCompleted('level_completed'),
  levelFailed('level_failed'),
  ballMoved('ball_moved'),
  hintUsed('hint_used'),
  undoUsed('undo_used'),
  extraTubeUsed('extra_tube_used'),
  shuffleUsed('shuffle_used'),
  rewardedCompleted('rewarded_completed'),
  interstitialShown('interstitial_shown'),
  skinUnlocked('skin_unlocked'),
  dailyCompleted('daily_completed'),
  achievementUnlocked('achievement_unlocked');

  const AnalyticsEvent(this.key);
  final String key;
}

/// Analytics boundary. Plug Firebase / another SDK in by implementing this.
abstract class AnalyticsService {
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]);
}

/// Default: prints in debug builds, no network.
class DebugAnalyticsService implements AnalyticsService {
  @override
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode && event != AnalyticsEvent.ballMoved) debugPrint('[analytics] ${event.key} $params');
  }
}
