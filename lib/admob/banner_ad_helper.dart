import 'package:admob_inapp_app/admob/admob_manage.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdHelper {
  BannerAd? _bannerAd; // NOT static anymore
  bool isLoaded = false; // NOT static anymore

  Future<void> loadBannerAd(
    BuildContext context,
    Function() onAdLoaded, {
    int height = 100,
  }) async {
    // Ensure any previous ad is disposed before loading a new one for this instance
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
      isLoaded = false;
    }

    bool isPurchased = await DatabaseBox.hasActiveSubscription();
    if (!isPurchased) {
      _bannerAd = BannerAd(
        size: AdSize(
          width: MediaQuery.of(context).size.width.truncate(),
          height: height,
        ),
        adUnitId: AdmobManager.bannerAdaptiveId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            // parameter `ad` is the BannerAd itself
            print('BannerAdHelper: Ad loaded.');
            isLoaded = true;
            onAdLoaded(); // Notify the widget to rebuild
          },
          onAdFailedToLoad: (ad, LoadAdError loadAdError) {
            print("BannerAdHelper: Ad failed to load: ${loadAdError.message}");
            ad.dispose(); // Dispose the failed ad
            _bannerAd = null; // Clear reference
            isLoaded = false; // Mark as not loaded
            onAdLoaded(); // Notify the widget to hide the ad placeholder
          },
          // Add other listeners if needed, e.g., onAdOpened, onAdClosed
        ),
        request: const AdRequest(),
      )..load();
    } else {
      // If purchased, ensure no ad is loaded for this instance
      if (_bannerAd != null) {
        _bannerAd!.dispose();
        _bannerAd = null;
        isLoaded = false;
        onAdLoaded(); // Notify to hide the ad
      }
    }
  }

  BannerAd? get bannerAdInstance =>
      isLoaded ? _bannerAd : null; // Renamed getter

  // This method is now an instance method.
  // It uses the _bannerAd instance managed by *this* helper.
  Widget getBannerView(_bannerAd) {
    if (_bannerAd == null || !isLoaded) {
      return const SizedBox();
    }
    // Only return AdWidget if _bannerAd is not null and loaded
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 5),
      height: _bannerAd!.size.height.toDouble(), // Use the instance's ad size
      width: double.infinity,
      child: AdWidget(ad: _bannerAd!), // Use the instance's ad
    );
  }

  // Add a dispose method to clean up the ad when the helper instance is no longer needed.
  void dispose() {
    if (_bannerAd != null) {
      print("BannerAdHelper: Disposing banner ad.");
      _bannerAd!.dispose();
      _bannerAd = null;
      isLoaded = false;
    }
  }
}

// final BannerAdHelper _bannerHelper = BannerAdHelper();
//
// @override
// void didChangeDependencies() {
//   super.didChangeDependencies();
//   _bannerHelper.loadBannerAd(context, () => setState(() {}));
// }
//
// bottomNavigationBar: _bannerHelper.getBannerView(
// _bannerHelper.bannerAdInstance),
