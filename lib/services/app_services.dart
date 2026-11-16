import '../repositories/progress_repository.dart';
import '../state/progress_controller.dart';
import '../state/settings_controller.dart';
import 'ads/admob_service.dart';
import 'analytics/analytics_service.dart';
import 'audio/audio_service.dart';
import 'haptics/haptics_service.dart';
import 'notifications/notification_service.dart';
import 'storage/key_value_store.dart';

/// Composition root: builds every service once at startup.
class AppServices {
  AppServices._({
    required this.repo,
    required this.analytics,
    required this.audio,
    required this.haptics,
    required this.notifications,
    required this.ads,
    required this.progress,
    required this.settings,
  });

  final ProgressRepository repo;
  final AnalyticsService analytics;
  final AudioService audio;
  final HapticsService haptics;
  final NotificationService notifications;
  final AdMobService ads;
  final ProgressController progress;
  final SettingsController settings;

  static Future<AppServices> create({KeyValueStore? store}) async {
    final kv = store ?? await SharedPrefsStore.create();
    final repo = LocalProgressRepository(kv);
    final analytics = DebugAnalyticsService();
    final audio = AudioService();
    final haptics = HapticsService();
    final notifications = LocalPreferenceNotificationService();
    final progress = ProgressController(repo: repo, analytics: analytics);
    final settings = SettingsController(repo: repo, audio: audio, haptics: haptics, notifications: notifications);
    final ads = AdMobService(analytics: analytics)..adsEnabled = !progress.value.removeAds;
    return AppServices._(
      repo: repo,
      analytics: analytics,
      audio: audio,
      haptics: haptics,
      notifications: notifications,
      ads: ads,
      progress: progress,
      settings: settings,
    );
  }
}
