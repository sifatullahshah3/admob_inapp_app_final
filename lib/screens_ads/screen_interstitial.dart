import 'package:admob_inapp_app/admob/appopen_ad_helper.dart';
import 'package:admob_inapp_app/admob/interstitial_ad_helper.dart';
import 'package:flutter/material.dart';

class ScreenInterstitial extends StatefulWidget {
  const ScreenInterstitial({super.key});

  @override
  State<ScreenInterstitial> createState() => _ScreenInterstitialState();
}

class _ScreenInterstitialState extends State<ScreenInterstitial> {
  InterstitialAdHelper interstitialAdHelper = InterstitialAdHelper();

  @override
  void initState() {
    super.initState();

    interstitialAdHelper.loadInterstitialAds(
      onAdDismissed: () {
        Future.delayed(Duration(seconds: 30), () {
          MyAppState().updateValue(false); // enable open ads after 30 sec
        });
        doNextFunctionality();
      },
      onAdShowFullScreen: () {
        MyAppState().updateValue(true); // disabled app open ads
      },
    );
  }

  doNextFunctionality() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            interstitialAdHelper.showAdIfAvailable(doNextFunctionality);
          },
          child: Icon(Icons.arrow_back_rounded),
        ),
      ),
    );
  }
}
