// lib/services/receipt_verifier_service.dart (or similar path)
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:admob_inapp_app/data/databases.dart';
import 'package:admob_inapp_app/in_app_purchase/inapp_utils.dart';
import 'package:admob_inapp_app/in_app_purchase/model_receipt_verification.dart';
import 'package:admob_inapp_app/in_app_purchase/service_invoices.dart';
import 'package:admob_inapp_app/utilities/constants.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:in_app_purchase/in_app_purchase.dart';

class ReceiptVerifierService {
  static Future<void> verifyIosReceipt({
    required String verificationData,
    required String fromSCR,
  }) async {
    var receiptBody = {
      'receipt-data': verificationData,
      'exclude-old-transactions': true,
      'password': iosSharedSecret,
    };
    generalPrintLog(
      "INAPPPurchase",
      "Attempting client-side verification: ${verificationData.length} from $fromSCR",
    );

    List<PurchaseDetailsSave> listPurchasedDetails = [];
    try {
      final response = await ServicesInAppPurchase.validateReceiptIos(
        receiptBody,
        kDebugMode,
      );

      final modelReceiptVerification = modelReceiptVerificationFromJson(
        response.body,
      );

      // Apple's status codes: 0 is valid, 21007 is sandbox receipt sent to prod, 21008 is prod receipt sent to sandbox.
      // This client-side verification only checks against one endpoint (determined by ServicesInAppPurchase.validateReceiptIos).
      // A robust backend would handle the 21007/21008 switching.

      if (modelReceiptVerification.receipt != null) {
        generalPrintLog(
          "INAPPPurchase receipt!.inApp.length",
          "${modelReceiptVerification.receipt?.inApp.length}",
        );

        // Find the latest active subscription from the in_app array
        // Assuming 'in_app' contains all purchases, including historical for non-consumables
        // and auto-renewing events for subscriptions.
        // For subscriptions, you typically look at 'latest_receipt_info' if it's available
        // or parse the 'in_app' array to find the latest active subscription.

        // Let's consider both `inApp` and `latest_receipt_info` if the model supports it.
        // The provided snippet only uses `modelReceiptVerification.receipt!.inApp`.
        // If the model has `latest_receipt_info` for subscriptions, it's better to use that.
        // For now, sticking to the provided snippet's logic using `inApp`.

        // Filter for active subscriptions based on expiresDateMs
        final activeTransactions =
            modelReceiptVerification.receipt!.inApp.where((element) {
              try {
                DateTime expiresDateMs = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(
                    element.expiresDateMs!,
                  ), // Use null-safe operator if it can be null
                  isUtc: DateTime.now().isUtc,
                );
                return expiresDateMs.isAfter(DateTime.now());
              } catch (e) {
                generalPrintLog(
                  "INAPPPurchase Error parsing expiresDateMs",
                  "$e for ${element.productId}",
                );
                return false;
              }
            }).toList();

        for (var element in activeTransactions) {
          DateTime transactionDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(element.purchaseDateMs!), // Use null-safe operator
            isUtc: DateTime.now().isUtc,
          );

          listPurchasedDetails.add(
            PurchaseDetailsSave(
              purchaseID: element.transactionId,
              productID: element.productId,
              // You might need to fetch product title from your _availableSubscriptionPlans
              // or have it returned by your ServicesInAppPurchase if possible.
              // For now, it's an empty string as in the original snippet.
              productTitle: "",
              verificationData: verificationData, // Store the full receipt used
              transactionDate: transactionDate,
              expireDate: DateTime.fromMillisecondsSinceEpoch(
                int.parse(element.expiresDateMs!),
                isUtc: DateTime.now().isUtc,
              ),
              status: true, // Marked as active
            ),
          );
        }

        if (listPurchasedDetails.isNotEmpty) {
          // Overwrite the existing list in the database with the newly verified active ones.
          // This approach assumes the client-side verification provides the complete picture
          // of current active subscriptions. For a production app, this should be driven
          // by the backend's authoritative list.
          DatabaseBox.savePurchaseDetailsSaveList(listPurchasedDetails);
        } else {
          // If no active subscriptions are found in the receipt, clear any existing local ones
          // to ensure the local state accurately reflects no active premium.
          DatabaseBox.savePurchaseDetailsSaveList([]);
        }

        generalPrintLog(
          "INAPPPurchase list_purchased length after verification",
          listPurchasedDetails.length,
        );
        for (var element in listPurchasedDetails) {
          // Note: Setting verificationData to "asdf" here seems like a debug placeholder.
          // It's usually better to store the actual verification data or not modify it.
          element.verificationData = "VerifiedClientSide";
          generalPrintLog("INAPPPurchase to Map", element.toMap().toString());
        }
      } else {
        generalPrintLog(
          "INAPPPurchase",
          "Receipt verification failed: No receipt data or invalid status from Apple.",
        );
        // If verification failed, clear existing local premium status as a precaution
        DatabaseBox.savePurchaseDetailsSaveList([]);
      }
    } catch (e) {
      generalPrintLog("INAPPPurchase Verification Error", e.toString());
      // Handle network errors or parsing errors
      // In case of error, it's safer to assume no active subscription until re-verified
      DatabaseBox.savePurchaseDetailsSaveList([]);
    }
  }

  static void callPurchaseStreamFunction(String fromSCR) {
    bool isPurchaseNotCall = true;
    InAppPurchase.instance.purchaseStream.listen((event) {
      if (isPurchaseNotCall) {
        isPurchaseNotCall = false;
        String verificationData =
            event[0].verificationData.localVerificationData;
        verifyIosReceipt(verificationData: verificationData, fromSCR: fromSCR);
      }
    });
  }
}
