import 'package:admob_inapp_app/admob/admob_manage.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedInterstitialAdHelper {
  bool isAdLoaded = false;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  void loadRewardedInterstitialAd({
    required Function(RewardItem reward) onEarnedReward,
    required Function() onAdDismissed,
    required Function() onAdShowFullScreen,
  }) async {
    bool isPurchased = await DatabaseBox.hasActiveSubscription();

    if (!isPurchased) {
      RewardedInterstitialAd.load(
        adUnitId: AdmobManager.rewardedInterstitialId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            isAdLoaded = true;
            _rewardedInterstitialAd = ad;

            _rewardedInterstitialAd
                ?.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (
                RewardedInterstitialAd rewardedInterAds,
              ) {
                onAdShowFullScreen();
              },
              onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
                ad.dispose();
                _rewardedInterstitialAd = null;
                isAdLoaded = false;
                onAdDismissed();
                loadRewardedInterstitialAd(
                  onEarnedReward: onEarnedReward,
                  onAdDismissed: onAdDismissed,
                  onAdShowFullScreen: onAdShowFullScreen,
                );
              },
              onAdFailedToShowFullScreenContent: (
                RewardedInterstitialAd ad,
                AdError error,
              ) {
                ad.dispose();
                _rewardedInterstitialAd = null;
                isAdLoaded = false;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            // debugPrint("RewardedInterstitialAd failed to load: $error");
            isAdLoaded = false;
          },
        ),
      );
    }
  }

  void showAdIfAvailable(Function(RewardItem reward) onEarnedReward) {
    if (_rewardedInterstitialAd != null && isAdLoaded) {
      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, rewardItem) => onEarnedReward(rewardItem),
      );
    }
  }

  void dispose() {
    _rewardedInterstitialAd?.dispose();
  }
}

// final RewardedInterstitialAdHelper rewardedInterstitialAdHelper =
// RewardedInterstitialAdHelper();
//
// @override
// void initState() {
//   super.initState();
//
//   rewardedInterstitialAdHelper.loadRewardedInterstitialAd(
//     onEarnedReward: (reward) {
//      debugPrint("User earned reward from interstitial: ${reward.amount}");
//       Future.delayed(Duration(seconds: 30), () {
//         MyAppState().updateValue(false); // enable open ads after 30 sec
//       });
//     },
//     onAdDismissed: () {
//       Future.delayed(Duration(seconds: 30), () {
//         MyAppState().updateValue(false); // enable open ads after 30 sec
//       });
//     },
//     onAdShowFullScreen: () {
//       MyAppState().updateValue(true); // disabled app open ads
//     },
//   );
// }
//
// @override
// void dispose() {
//   rewardedInterstitialAdHelper.dispose();
//   super.dispose();
// }

// ElevatedButton(
// onPressed: () {
// rewardedInterstitialAdHelper.showAdIfAvailable((reward) {
// Future.delayed(Duration(seconds: 30), () {
// MyAppState()
//     .updateValue(false); // enable open ads after 30 sec
// });
//debugPrint(
// "✔ Rewarded Interstitial: ${reward.amount} ${reward.type}");
// });
// },
// child: const Text("Show Rewarded Interstitial Ad"),
// ),
