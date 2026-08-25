import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/ad_service.dart';

/// FF-06: adaptive banner for the bottom chrome only — never positioned over
/// the character's face (locked design decision, PRD v3 §7). Renders
/// nothing on iOS or while no ad has loaded yet.
class AdBannerBar extends StatefulWidget {
  final AdService adService;
  const AdBannerBar({super.key, required this.adService});

  @override
  State<AdBannerBar> createState() => _AdBannerBarState();
}

class _AdBannerBarState extends State<AdBannerBar> {
  BannerAd? _bannerAd;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested && widget.adService.isSupported) {
      _requested = true;
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(Orientation.portrait, width);
    if (size == null || !mounted) return;

    final banner = BannerAd(
      adUnitId: widget.adService.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdBannerBar: failed to load: $error');
          ad.dispose();
        },
      ),
    );
    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
