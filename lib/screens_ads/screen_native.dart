import 'package:admob_inapp_app/admob/native_ad_helper.dart';
import 'package:flutter/material.dart';

class ScreenNative extends StatefulWidget {
  const ScreenNative({super.key});

  @override
  State<ScreenNative> createState() => _ScreenNativeState();
}

class _ScreenNativeState extends State<ScreenNative> {
  final NativeAdHelper nativeAdHelper = NativeAdHelper();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    nativeAdHelper.loadNativeAd(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    nativeAdHelper.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: NativeAdHelper.getNativeAdView(
        isLoaded: nativeAdHelper.isLoaded,
        nativeAd: nativeAdHelper.nativeAd,
        height: 120,
      ),
    );
  }
}
