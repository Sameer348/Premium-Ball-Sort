import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_service.dart';
import 'ad_config.dart';
import 'ad_frequency_manager.dart';

/// Owns AdMob lifecycles. Every method is failure-safe: offline, no-fill
/// or SDK errors simply resolve to "no ad" — gameplay always continues.
class AdMobService extends ChangeNotifier {
  AdMobService({required AnalyticsService analytics, AdFrequencyManager? frequency})
      : _analytics = analytics, // ignore: prefer_initializing_formals
        frequency = frequency ?? AdFrequencyManager();

  final AnalyticsService _analytics;
  final AdFrequencyManager frequency;

  bool _initialized = false;
  bool _adsEnabled = true;
  bool _showingFullScreen = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  Completer<bool>? _rewardedLoad;

  /// Non-rewarded ads switch (false after a "Remove Ads" entitlement).
  bool get adsEnabled => _adsEnabled;
  set adsEnabled(bool v) {
    if (_adsEnabled == v) return;
    _adsEnabled = v;
    if (!v) {
      _interstitial?.dispose();
      _interstitial = null;
    }
    notifyListeners();
  }

  bool get ready => _initialized;
  bool get bannersAllowed => _initialized && _adsEnabled;
  bool get isShowingFullScreen => _showingFullScreen;
  bool get rewardedReady => _rewarded != null;

  Future<void> init() async {
    if (!AdConfig.supportedPlatform) return;
    try {
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _initialized = true;
      notifyListeners();
      _loadInterstitial();
      unawaited(_loadRewarded());
    } on Object catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
            if (!done.isCompleted) done.complete();
          });
        },
        (FormError e) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
    } on Object catch (e) {
      debugPrint('Consent unavailable: $e');
    }
  }

  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } on Object {
      return false;
    }
  }

  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? e) {});
    } on Object catch (e) {
      debugPrint('Privacy options unavailable: $e');
    }
  }

  // --------------------------------------------------------- Interstitial

  void _loadInterstitial() {
    if (!ready || !_adsEnabled || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (err) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed: ${err.message}');
        },
      ),
    );
  }

  void onLevelCompleted() => frequency.onLevelCompleted();

  /// Called only at natural breaks (after the result screen, never during
  /// play or animations). Completes when the ad closes, or immediately.
  Future<void> maybeShowInterstitial({bool inTutorial = false}) async {
    if (!frequency.shouldShowInterstitial(adsEnabled: _adsEnabled && ready, inTutorial: inTutorial)) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final closed = Completer<void>();
    void finish(Ad a) {
      a.dispose();
      _showingFullScreen = false;
      if (!closed.isCompleted) closed.complete();
      _loadInterstitial();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _showingFullScreen = true;
        frequency.onAdShown();
        _analytics.log(AnalyticsEvent.interstitialShown);
      },
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, _) => finish(a),
    );
    try {
      await ad.show();
      await closed.future.timeout(const Duration(minutes: 2), onTimeout: () {});
    } on Object catch (e) {
      debugPrint('Interstitial show failed: $e');
      _showingFullScreen = false;
    }
  }

  // ------------------------------------------------------------- Rewarded

  Future<bool> _loadRewarded() {
    if (_rewarded != null) return Future.value(true);
    if (_rewardedLoad != null) return _rewardedLoad!.future;
    if (!ready) return Future.value(false);
    final c = _rewardedLoad = Completer<bool>();
    RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoad = null;
          if (!c.isCompleted) c.complete(true);
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed: ${err.message}');
          _rewardedLoad = null;
          if (!c.isCompleted) c.complete(false);
        },
      ),
    );
    return c.future;
  }

  /// Resolves true ONLY when the SDK's onUserEarnedReward fired.
  Future<bool> showRewarded({required String placement}) async {
    if (!ready) return false;
    final loaded = await _loadRewarded().timeout(AdConfig.rewardedLoadTimeout, onTimeout: () => false);
    final ad = _rewarded;
    if (!loaded || ad == null) return false;
    _rewarded = null;
    var earned = false;
    final closed = Completer<void>();
    void finish(Ad a) {
      a.dispose();
      _showingFullScreen = false;
      if (!closed.isCompleted) closed.complete();
      unawaited(_loadRewarded());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _showingFullScreen = true;
        frequency.onAdShown();
      },
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, _) => finish(a),
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
      await closed.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    } on Object catch (e) {
      debugPrint('Rewarded show failed: $e');
      _showingFullScreen = false;
      return false;
    }
    if (earned) _analytics.log(AnalyticsEvent.rewardedCompleted, {'placement': placement});
    return earned;
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    super.dispose();
  }
}
