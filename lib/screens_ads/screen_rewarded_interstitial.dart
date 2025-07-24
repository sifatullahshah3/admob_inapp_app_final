import 'package:admob_inapp_app/admob/appopen_ad_helper.dart';
import 'package:admob_inapp_app/admob/rewarded_interstitial_ad_helper.dart';
import 'package:flutter/material.dart';

class ScreenRewardedInterstitial extends StatefulWidget {
  const ScreenRewardedInterstitial({super.key});

  @override
  State<ScreenRewardedInterstitial> createState() =>
      _ScreenRewardedInterstitialState();
}

class _ScreenRewardedInterstitialState
    extends State<ScreenRewardedInterstitial> {
  final RewardedInterstitialAdHelper rewardedInterstitialAdHelper =
      RewardedInterstitialAdHelper();

  @override
  void initState() {
    super.initState();

    rewardedInterstitialAdHelper.loadRewardedInterstitialAd(
      onEarnedReward: (reward) {
        debugPrint("User earned reward from interstitial: ${reward.amount}");
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
    );
  }

  @override
  void dispose() {
    rewardedInterstitialAdHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: ElevatedButton(
          onPressed: () {
            rewardedInterstitialAdHelper.showAdIfAvailable((reward) {
              Future.delayed(Duration(seconds: 30), () {
                MyAppState().updateValue(false); // enable open ads after 30 sec
              });
              debugPrint(
                "✔ Rewarded Interstitial: ${reward.amount} ${reward.type}",
              );
            });
          },
          child: const Text("Show Rewarded Interstitial Ad"),
        ),
      ),
    );
  }
}
