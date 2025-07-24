import 'package:admob_inapp_app/admob/appopen_ad_helper.dart';
import 'package:admob_inapp_app/in_app_purchase/screen_premium_subscription.dart';
import 'package:admob_inapp_app/screens_ads/screen_banner.dart';
import 'package:admob_inapp_app/screens_ads/screen_interstitial.dart';
import 'package:admob_inapp_app/screens_ads/screen_native.dart';
import 'package:admob_inapp_app/screens_ads/screen_rewarded.dart';
import 'package:admob_inapp_app/screens_ads/screen_rewarded_interstitial.dart';
import 'package:admob_inapp_app/utilities/constants.dart';
import 'package:flutter/material.dart';

class ScreenDashboard extends StatefulWidget {
  const ScreenDashboard({super.key});

  @override
  State<ScreenDashboard> createState() => _ScreenDashboardState();
}

class _ScreenDashboardState extends State<ScreenDashboard>
    with WidgetsBindingObserver {
  AppOpenAdHelper appOpenAdHelper = AppOpenAdHelper();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        !MyAppState().getIsOtherAdsDisabled) {
      appOpenAdHelper.showAdIfAvailable();
    }
  }

  @override
  dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appOpenAdHelper.loadAppOpenAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                Constants.openNewActivity(ScreenPremiumSubscription()),
              );
            },
            child: Icon(Icons.workspace_premium, color: Colors.orange),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  Constants.openNewActivity(ScreenBanner()),
                );
              },
              child: Text("Banner"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  Constants.openNewActivity(ScreenInterstitial()),
                );
              },
              child: Text("Interstitial"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  Constants.openNewActivity(ScreenRewarded()),
                );
              },
              child: Text("Reward"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  Constants.openNewActivity(ScreenNative()),
                );
              },
              child: Text("Native"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  Constants.openNewActivity(ScreenRewardedInterstitial()),
                );
              },
              child: Text("Reward Interstital"),
            ),
          ],
        ),
      ),
    );
  }
}
