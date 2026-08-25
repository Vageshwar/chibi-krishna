import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// FF-06: thin wrapper around google_mobile_ads.
///
/// Debug/dev builds always use Google's public test ad unit IDs, regardless
/// of what's in .env — real IDs only activate in release builds
/// (kReleaseMode). This repo's AdMob account is live the moment real IDs
/// exist, and a dev device requesting (let alone tapping) a real ad risks
/// the account getting flagged for invalid traffic.
///
/// Ads only run on Android — this project's shipping target (CLAUDE.md).
/// iOS AdMob setup (App Tracking Transparency, SKAdNetwork, a separate iOS
/// App ID) is deliberately not wired up.
class AdService {
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  String get bannerAdUnitId => kReleaseMode
      ? (dotenv.env['ADMOB_BANNER_AD_UNIT_ID']?.isNotEmpty == true
          ? dotenv.env['ADMOB_BANNER_AD_UNIT_ID']!
          : _testBannerAdUnitId)
      : _testBannerAdUnitId;

  String get rewardedAdUnitId => kReleaseMode
      ? (dotenv.env['ADMOB_REWARDED_AD_UNIT_ID']?.isNotEmpty == true
          ? dotenv.env['ADMOB_REWARDED_AD_UNIT_ID']!
          : _testRewardedAdUnitId)
      : _testRewardedAdUnitId;

  bool _initialized = false;
  RewardedAd? _rewardedAd;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _preloadRewardedAd();
    } catch (e) {
      debugPrint('AdService: initialize failed: $e');
    }
  }

  void _preloadRewardedAd() {
    if (!isSupported) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          debugPrint('AdService: rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  /// Shows the preloaded rewarded ad if one is ready. onEarned fires only on
  /// a genuine onUserEarnedReward — never on a plain dismiss/skip, matching
  /// FF-06's "reward only after a completed view". Always preloads the next
  /// ad afterward so the next Support prompt isn't stuck waiting on a load.
  Future<void> showRewardedAd({
    required VoidCallback onEarned,
    required VoidCallback onDismissedWithoutReward,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      onDismissedWithoutReward();
      return;
    }
    _rewardedAd = null;
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadRewardedAd();
        if (!earned) onDismissedWithoutReward();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: rewarded ad failed to show: $error');
        ad.dispose();
        _preloadRewardedAd();
        onDismissedWithoutReward();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        onEarned();
      },
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
