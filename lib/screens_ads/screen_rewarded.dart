import 'package:admob_inapp_app/admob/appopen_ad_helper.dart';
import 'package:admob_inapp_app/admob/rewarded_ad_helper.dart';
import 'package:flutter/material.dart';

class ScreenRewarded extends StatefulWidget {
  const ScreenRewarded({super.key});

  @override
  State<ScreenRewarded> createState() => _ScreenRewardedState();
}

class _ScreenRewardedState extends State<ScreenRewarded> {
  final RewardedAdHelper rewardedAdHelper = RewardedAdHelper();
  bool isVideoAdsload = false;
  @override
  void initState() {
    super.initState();

    rewardedAdHelper.loadRewardedAd(
      onEarnedReward: (reward) {
        debugPrint("User earned reward: ${reward.amount}");
        Future.delayed(Duration(seconds: 30), () {
          MyAppState().updateValue(false); // enable open ads after 30 sec
        });
      },
      onAdDismissed: () {
        Future.delayed(Duration(seconds: 30), () {
          MyAppState().updateValue(false); // enable open ads after 30 sec
        });
      },
      onAdShowFullScreen: () {
        MyAppState().updateValue(true); // disabled app open ads
      },
      onAdLoaded: (bool isVideoAdsload) {
        this.isVideoAdsload = isVideoAdsload;
        setState(() {});
        debugPrint("isVideoAdsload $isVideoAdsload");
      },
    );
  }

  @override
  void dispose() {
    rewardedAdHelper.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rewarded Ad")),
      body: Container(
        child: ElevatedButton(
          onPressed: () {
            if (isVideoAdsload) {
              rewardedAdHelper.showAdIfAvailable((reward) {
                debugPrint("✔ Rewarded: ${reward.amount} ${reward.type}");
              });
            } else {
              debugPrint("Video ads not loaded");
            }
          },
          child: const Text("Show Rewarded Ad"),
        ),
      ),
    );
  }
}
