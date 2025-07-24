import 'dart:io';

class AdmobManager {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isTestingShowAdInDebug => true;

  static const _testIds = {
    "appId": "ca-app-pub-3940256099942544~3347511713",
    "bannerAdaptive": "ca-app-pub-3940256099942544/9214589741",
    "bannerFixed": "ca-app-pub-3940256099942544/6300978111",
    "interstitial": "ca-app-pub-3940256099942544/1033173712",
    "rewardedInterstitial": "ca-app-pub-3940256099942544/5354046379",
    "rewarded": "ca-app-pub-3940256099942544/5224354917",
    "native": "ca-app-pub-3940256099942544/2247696110",
    "nativeVideo": "ca-app-pub-3940256099942544/1044960115",
    "appOpen": "ca-app-pub-3940256099942544/9257395921",
  };

  //=============== Real Android Ids ===========================================
  static const _androidIds = {
    "appId": "",
    "bannerAdaptive": "",
    "bannerFixed": "",
    "interstitial": "",
    "rewardedInterstitial": "",
    "rewarded": "",
    "native": "",
    "nativeVideo": "",
    "appOpen": "",
  };

  //=============== Real Android Ids ===========================================

  //================ Real IOS Ids ================================================
  static const _iosIds = {
    "appId": "",
    "bannerAdaptive": "",
    "bannerFixed": "",
    "interstitial": "",
    "rewardedInterstitial": "",
    "rewarded": "",
    "native": "",
    "nativeVideo": "",
    "appOpen": "",
  };

  //new
  //================ Real IOS Ids ================================================

  static Map<String, String> get _ids => _testIds;
  // kDebugMode
  //     ? (isTestingShowAdInDebug ? _testIds : {})
  //     : (isAndroid ? _androidIds : _iosIds);

  static String get appId => _ids["appId"] ?? "";
  static String get bannerAdaptiveId => _ids["bannerAdaptive"] ?? "";
  static String get bannerFixedId => _ids["bannerFixed"] ?? "";
  static String get interstitialId => _ids["interstitial"] ?? "";
  static String get rewardedInterstitialId =>
      _ids["rewardedInterstitial"] ?? "";
  static String get rewardedId => _ids["rewarded"] ?? "";
  static String get nativeId => _ids["native"] ?? "";
  static String get nativeVideoId => _ids["nativeVideo"] ?? "";
  static String get appOpenId => _ids["appOpen"] ?? "";
}
