import 'package:admob_inapp_app/admob/admob_manage.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdHelper {
  bool isAdLoaded = false;
  bool isPurchased = false;
  InterstitialAd? interstitialAd;

  void loadInterstitialAds({
    required Function() onAdDismissed,
    required Function() onAdShowFullScreen,
  }) async {
    isPurchased = await DatabaseBox.hasActiveSubscription();

    if (!isPurchased) {
      InterstitialAd.load(
        adUnitId: AdmobManager.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd interstitialAd) {
            isAdLoaded = true;
            this.interstitialAd = interstitialAd;

            interstitialAd
                .fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (InterstitialAd interstitialAd2) {
                isAdLoaded = false;
                this.interstitialAd = null;
                onAdDismissed();
                loadInterstitialAds(
                  onAdDismissed: onAdDismissed,
                  onAdShowFullScreen: onAdShowFullScreen,
                );
              },
              onAdShowedFullScreenContent: (InterstitialAd interstitialAd3) {
                onAdShowFullScreen();
              },
              onAdFailedToShowFullScreenContent: (
                InterstitialAd interstitialAd4,
                AdError adError,
              ) {
                isAdLoaded = false;
                this.interstitialAd?.dispose();
                this.interstitialAd = null;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError loadAdError) {
            isAdLoaded = false;
            debugPrint("loadAdError Code ${loadAdError.code}");
            debugPrint("loadAdError Message ${loadAdError.message}");
          },
        ),
      );
    }
  }

  void showAdIfAvailable(VoidCallback doNextFunctionality) {
    if (interstitialAd != null && isAdLoaded == true) {
      interstitialAd?.show();
      isAdLoaded = false;
    } else {
      doNextFunctionality();
    }
  }
}

// InterstitialAdHelper interstitialAdHelper = InterstitialAdHelper();
//
// @override
// void initState() {
//   super.initState();
//
//   interstitialAdHelper.loadInterstitialAds(
//     onAdDismissed: () {
//       Future.delayed(Duration(seconds: 30), () {
//         MyAppState().updateValue(false); // enable open ads after 30 sec
//       });
//       doNextFunctionality();
//     },
//     onAdShowFullScreen: () {
//       MyAppState().updateValue(true); // disabled app open ads
//     },
//   );
// }
//
// doNextFunctionality() {
//   Navigator.pop(context);
// }

// leading: InkWell(
// onTap: () {
// interstitialAdHelper.showAdIfAvailable(doNextFunctionality);
// },
// child: Icon(Icons.arrow_back_rounded),
// ),
