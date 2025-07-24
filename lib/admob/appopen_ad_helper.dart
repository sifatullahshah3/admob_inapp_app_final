import 'package:admob_inapp_app/admob/admob_manage.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdHelper {
  AppOpenAd? _appOpenAd;
  bool _isAdShowing = false;

  void loadAppOpenAd() async {
    var isPurchased = await DatabaseBox.hasActiveSubscription();

    if (!isPurchased) {
      AppOpenAd.load(
        adUnitId: AdmobManager.appOpenId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                _appOpenAd = null;
                _isAdShowing = false;
                loadAppOpenAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            //debugPrint('Failed to load an app open ad: $error');
            _appOpenAd = null;
          },
        ),
      );
    }
  }

  void showAdIfAvailable() {
    if (_appOpenAd == null || _isAdShowing) {
      loadAppOpenAd();
      return;
    }

    _isAdShowing = true;
    _appOpenAd!.show();
  }
}

class MyAppState {
  static final MyAppState _instance = MyAppState._internal();
  factory MyAppState() => _instance;
  MyAppState._internal();

  bool isOtherAdsDisabled = false;

  void updateValue(bool newValue) {
    isOtherAdsDisabled = newValue;
  }

  bool get getIsOtherAdsDisabled => isOtherAdsDisabled;
}

// with WidgetsBindingObserver {
// AppOpenAdHelper appOpenAdHelper = AppOpenAdHelper();
//
// @override
// void didChangeAppLifecycleState(AppLifecycleState state) {
//   super.didChangeAppLifecycleState(state);
//   if (state == AppLifecycleState.resumed &&
//       !MyAppState().getIsOtherAdsDisabled) {
//     appOpenAdHelper.showAdIfAvailable();
//   }
// }
//
// @override
// dispose() {
//   super.dispose();
//   WidgetsBinding.instance.removeObserver(this);
// }
//
// @override
// initState() {
//   super.initState();
//   WidgetsBinding.instance.addObserver(this);
//   appOpenAdHelper.loadAppOpenAd();
// }
