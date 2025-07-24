import 'package:admob_inapp_app/admob/admob_manage.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdHelper {
  bool isAdLoaded = false;
  RewardedAd? _rewardedAd;

  void loadRewardedAd({
    required Function(RewardItem reward) onEarnedReward,
    required Function() onAdShowFullScreen,
    required Function() onAdDismissed,
    required Function(bool isVideoAdsload) onAdLoaded,
  }) async {
    bool isPurchased = await DatabaseBox.hasActiveSubscription();

    if (!isPurchased) {
      RewardedAd.load(
        adUnitId: AdmobManager.rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            isAdLoaded = true;
            _rewardedAd = ad;

            _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd rewardedAd) {
                onAdShowFullScreen();
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                ad.dispose();
                isAdLoaded = false;
                _rewardedAd = null;
                onAdDismissed();
                loadRewardedAd(
                  onEarnedReward: onEarnedReward,
                  onAdDismissed: onAdDismissed,
                  onAdShowFullScreen: onAdShowFullScreen,
                  onAdLoaded: onAdLoaded,
                );
              },
              onAdFailedToShowFullScreenContent: (
                RewardedAd ad,
                AdError error,
              ) {
                ad.dispose();
                _rewardedAd = null;
                isAdLoaded = false;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            // debugPrint("RewardedAd failed to load: $error");
            isAdLoaded = false;
          },
        ),
      );
    }
  }

  void showAdIfAvailable(Function(RewardItem reward) onEarnedReward) {
    if (_rewardedAd != null && isAdLoaded) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          onEarnedReward(rewardItem);
        },
      );
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}

// final RewardedAdHelper rewardedAdHelper = RewardedAdHelper();
//
// @override
// void initState() {
//   super.initState();
//
//   rewardedAdHelper.loadRewardedAd(
//     onEarnedReward: (reward) {
//      debugPrint("User earned reward: ${reward.amount}");
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
//   rewardedAdHelper.dispose();
//
//   super.dispose();
// }

// ElevatedButton(
// onPressed: () {
// rewardedAdHelper.showAdIfAvailable((reward) {
//debugPrint("✔ Rewarded: ${reward.amount} ${reward.type}");
// });
// },
// child: const Text("Show Rewarded Ad"),
// ),
