// not just splash , will ask use for their name here

// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:admob_inapp_app/data/database_box.dart';
import 'package:admob_inapp_app/screen_dashboard.dart';
import 'package:admob_inapp_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({super.key});

  @override
  ScreenSplashState createState() => ScreenSplashState();
}

class ScreenSplashState extends State<ScreenSplash> {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void toCheckConsent() {
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(params, () async {
      var req = await ConsentInformation.instance.isConsentFormAvailable();
      if (req) {
        loadForm();
      } else {
        openNextScreen();
      }
    }, (FormError error) => openNextScreen());
  }

  void loadForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          timerCheckResult();
          consentForm.show((FormError? formError) {
            openNextScreen();
          });
        } else {
          openNextScreen();
        }
      },
      (formError) {
        openNextScreen();
      },
    );
  }

  void timerCheckResult() async {
    var status = await ConsentInformation.instance.getConsentStatus();
    if (status == ConsentStatus.obtained) {
    } else {
      await Future.delayed(const Duration(seconds: 2));
      timerCheckResult();
    }
  }

  loadData() {
    Future.delayed(const Duration(seconds: 3)).then((onValue) async {
      bool isAnyActivePlan = await DatabaseBox.hasActiveSubscription();
      if (isAnyActivePlan) {
        print("found purchased plan");
        openNextScreen();
      } else {
        print("no purchased plan found");
        await MobileAds.instance.initialize();
        toCheckConsent();
      }
    });
  }

  void openNextScreen() {
    Navigator.pop(context);
    Navigator.push(context, Constants.openNewActivity(ScreenDashboard()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Splash Screen",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
