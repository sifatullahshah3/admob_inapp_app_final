import 'package:admob_inapp_app/admob/admob_manage.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdHelper {
  NativeAd? _nativeAd;
  bool isLoaded = false;

  void loadNativeAd(
    Function() onAdLoaded, {
    TemplateType type = TemplateType.small,
  }) async {
    bool isPurchased = await DatabaseBox.hasActiveSubscription();

    if (!isPurchased) {
      _nativeAd = NativeAd(
        adUnitId: AdmobManager.nativeId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            isLoaded = true;
            onAdLoaded();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint("NativeAd failed to load: $error");
            ad.dispose();
          },
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: type,
          mainBackgroundColor: const Color(0xfffffbed),
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            style: NativeTemplateFontStyle.monospace,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            style: NativeTemplateFontStyle.italic,
            size: 16.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            style: NativeTemplateFontStyle.normal,
            size: 16.0,
          ),
        ),
      )..load();
    }
  }

  NativeAd? get nativeAd => isLoaded ? _nativeAd : null;

  void dispose() {
    _nativeAd?.dispose();
  }

  static Widget getNativeAdView({
    required bool isLoaded,
    required NativeAd? nativeAd,
    double height = 100,
  }) {
    return isLoaded && nativeAd != null
        ? Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: AdWidget(ad: nativeAd),
          ),
        )
        : const SizedBox(height: 0);
  }
}

// final NativeAdHelper nativeAdHelper = NativeAdHelper();
//
// @override
// void didChangeDependencies() {
//   super.didChangeDependencies();
//   nativeAdHelper.loadNativeAd(() {
//     setState(() {});
//   });
// }
//
// @override
// void dispose() {
//   nativeAdHelper.dispose();
//   super.dispose();
// }
//
// NativeAdHelper.getNativeAdView(
// isLoaded: nativeAdHelper.isLoaded,
// nativeAd: nativeAdHelper.nativeAd,
// height: 120,
// ),
