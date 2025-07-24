// import 'package:hive/hive.dart';

import 'package:admob_inapp_app/data/databases.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseBox {
  static const purchaseDetailsSave = "purchase_details_save";

  static Box<PurchaseDetailsSave> getPurchaseDetailsSave() =>
      Hive.box(purchaseDetailsSave);

  static Future<bool> hasActiveSubscription() async {
    List<PurchaseDetailsSave> list = DatabaseBox.getPurchaseDetailsSaveList();
    for (var purchase in list) {
      if (purchase.status && purchase.expireDate.isAfter(DateTime.now())) {
        return true;
      }
    }
    return false;
  }

  static Box<PurchaseDetailsSave> get purchaseDetailsSavee =>
      Hive.box<PurchaseDetailsSave>('purchase_details_save');

  static List<PurchaseDetailsSave> getPurchaseDetailsSaveList() {
    return purchaseDetailsSavee.values.toList().cast<PurchaseDetailsSave>();
  }

  static void savePurchaseDetailsSaveList(List<PurchaseDetailsSave> list) {
    for (var element in list) {
      purchaseDetailsSavee.put(element.productID.toString(), element);
    }
  }

  // Step 3
  static getHiveFunction() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(PurchaseDetailsSaveAdapter());
    }
    if (!Hive.isBoxOpen(purchaseDetailsSave)) {
      await Hive.openBox<PurchaseDetailsSave>(purchaseDetailsSave);
    }
  }

  static String getNewKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
