import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Central ad configuration. Production IDs live ONLY here.
///
/// While [isTestMode] is true (default in debug/profile and until you set
/// real IDs), only Google's official test units are requested — never
/// live ads during development.
class AdConfig {
  AdConfig._();

  static const bool isTestMode = !kReleaseMode || _productionNotConfigured;

  // Replace with your real IDs before release and set this to false.
  static const bool _productionNotConfigured = true;

  // ---- Production (placeholders: real IDs go here) -----------------------
  static const _prodAndroidBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';
  static const _prodAndroidInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';
  static const _prodAndroidRewarded = 'ca-app-pub-XXXXXXXXXXXXXXXX/RRRRRRRRRR';
  static const _prodIosBanner = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';
  static const _prodIosInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';
  static const _prodIosRewarded = 'ca-app-pub-XXXXXXXXXXXXXXXX/RRRRRRRRRR';

  // ---- Official Google test units ---------------------------------------
  static const _testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAndroidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _testIosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static bool get supportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get _android => !kIsWeb && Platform.isAndroid;

  static String get bannerId => isTestMode
      ? (_android ? _testAndroidBanner : _testIosBanner)
      : (_android ? _prodAndroidBanner : _prodIosBanner);

  static String get interstitialId => isTestMode
      ? (_android ? _testAndroidInterstitial : _testIosInterstitial)
      : (_android ? _prodAndroidInterstitial : _prodIosInterstitial);

  static String get rewardedId => isTestMode
      ? (_android ? _testAndroidRewarded : _testIosRewarded)
      : (_android ? _prodAndroidRewarded : _prodIosRewarded);

  // ---- Frequency ---------------------------------------------------------
  static const int levelsBeforeInterstitial = 4;
  static const int minimumSecondsBetweenAds = 90;
  static const int noAdsAfterLaunchSeconds = 120;
  static const int tutorialLevels = 10;
  static const Duration rewardedLoadTimeout = Duration(seconds: 8);

  // ---- Reward amounts ----------------------------------------------------
  static const int rewardedCoins = 50;
}
