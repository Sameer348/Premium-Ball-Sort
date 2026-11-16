import 'package:flutter_test/flutter_test.dart';
import 'package:sort_sphere/services/ads/ad_config.dart';
import 'package:sort_sphere/services/ads/ad_frequency_manager.dart';

void main() {
  test('interstitials respect launch grace, level count, cooldown, flags', () {
    var now = DateTime(2026, 1, 1, 12);
    final f = AdFrequencyManager(levelsBeforeInterstitial: 4, minimumSecondsBetweenAds: 90, noAdsAfterLaunchSeconds: 120, clock: () => now);
    for (var i = 0; i < 5; i++) {
      f.onLevelCompleted();
    }
    expect(f.shouldShowInterstitial(adsEnabled: true), isFalse, reason: 'launch grace');
    now = now.add(const Duration(minutes: 3));
    expect(f.shouldShowInterstitial(adsEnabled: true), isTrue);
    expect(f.shouldShowInterstitial(adsEnabled: false), isFalse, reason: 'remove-ads flag');
    expect(f.shouldShowInterstitial(adsEnabled: true, inTutorial: true), isFalse);
    f.onAdShown();
    for (var i = 0; i < 4; i++) {
      f.onLevelCompleted();
    }
    expect(f.shouldShowInterstitial(adsEnabled: true), isFalse, reason: 'cooldown');
    now = now.add(const Duration(seconds: 91));
    expect(f.shouldShowInterstitial(adsEnabled: true), isTrue);
    f.onAdShown();
    now = now.add(const Duration(minutes: 10));
    f.onLevelCompleted();
    expect(f.shouldShowInterstitial(adsEnabled: true), isFalse, reason: 'not after every level');
  });

  test('test mode only uses official Google test units', () {
    expect(AdConfig.isTestMode, isTrue);
    for (final id in [AdConfig.bannerId, AdConfig.interstitialId, AdConfig.rewardedId]) {
      expect(id, startsWith('ca-app-pub-3940256099942544/'));
    }
  });
}
