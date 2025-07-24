import 'package:admob_inapp_app/admob/banner_ad_helper.dart';
import 'package:flutter/material.dart';

class ScreenBanner extends StatefulWidget {
  const ScreenBanner({super.key});

  @override
  State<ScreenBanner> createState() => _ScreenBannerState();
}

class _ScreenBannerState extends State<ScreenBanner> {
  final BannerAdHelper _bannerHelper = BannerAdHelper();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bannerHelper.loadBannerAd(context, () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: _bannerHelper.getBannerView(
        _bannerHelper.bannerAdInstance,
      ),
    );
  }
}
