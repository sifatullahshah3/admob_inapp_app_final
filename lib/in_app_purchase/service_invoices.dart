import 'dart:convert';

import 'package:http/http.dart' as http;

class ServicesInAppPurchase {
  static var timeOut = const Duration(seconds: 20);
  static var client = http.Client();

  static Future<http.Response> validateReceiptIos(receiptBody, isTest) async {
    final String url = isTest
        ? 'https://sandbox.itunes.apple.com/verifyReceipt'
        : 'https://buy.itunes.apple.com/verifyReceipt';
    return await client.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: json.encode(receiptBody),
    );
  }
}
