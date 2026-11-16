import 'ad_config.dart';

/// Decides when an interstitial is allowed. Pure logic → unit-testable.
class AdFrequencyManager {
  AdFrequencyManager({
    this.levelsBeforeInterstitial = AdConfig.levelsBeforeInterstitial,
    this.minimumSecondsBetweenAds = AdConfig.minimumSecondsBetweenAds,
    this.noAdsAfterLaunchSeconds = AdConfig.noAdsAfterLaunchSeconds,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _launch = (clock ?? DateTime.now)();

  final int levelsBeforeInterstitial;
  final int minimumSecondsBetweenAds;
  final int noAdsAfterLaunchSeconds;
  final DateTime Function() _clock;
  final DateTime _launch;
  DateTime? _lastAd;
  int _levelsSinceAd = 0;

  int get levelsSinceAd => _levelsSinceAd;

  void onLevelCompleted() => _levelsSinceAd++;

  /// Rewarded ads also count as "recent ad" to avoid back-to-back ads.
  void onAdShown() {
    _lastAd = _clock();
    _levelsSinceAd = 0;
  }

  bool shouldShowInterstitial({required bool adsEnabled, bool inTutorial = false}) {
    if (!adsEnabled || inTutorial) return false;
    final now = _clock();
    if (now.difference(_launch).inSeconds < noAdsAfterLaunchSeconds) return false;
    if (_levelsSinceAd < levelsBeforeInterstitial) return false;
    final last = _lastAd;
    if (last != null && now.difference(last).inSeconds < minimumSecondsBetweenAds) return false;
    return true;
  }
}
