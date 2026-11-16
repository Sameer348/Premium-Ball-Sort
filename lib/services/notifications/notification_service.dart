/// Reminder scheduling boundary. The default implementation records the
/// preference only (no notification plugin is bundled, keeping the app
/// dependency-light); a platform implementation can be dropped in.
abstract class NotificationService {
  Future<void> setDailyReminder(bool enabled);
}

class LocalPreferenceNotificationService implements NotificationService {
  bool enabled = false;
  @override
  Future<void> setDailyReminder(bool value) async => enabled = value;
}
