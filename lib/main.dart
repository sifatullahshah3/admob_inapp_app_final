import 'package:admob_inapp_app/data/database_box.dart';
import 'package:admob_inapp_app/screen_splash.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await DatabaseBox.getHiveFunction();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ScreenSplash(),
    );
  }
}
