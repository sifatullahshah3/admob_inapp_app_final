// lib/services/receipt_verifier_service.dart (or similar path)
import 'dart:async';

import 'package:admob_inapp_app/data/database_box.dart';
import 'package:admob_inapp_app/data/databases.dart';
import 'package:admob_inapp_app/in_app_purchase/inapp_utils.dart';
import 'package:admob_inapp_app/in_app_purchase/model_receipt_verification.dart';
import 'package:admob_inapp_app/in_app_purchase/service_invoices.dart';
import 'package:admob_inapp_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ReceiptVerifierService {
  // This is the primary method to call for verification.
  // It orchestrates the validation and saving process.
  static Future<bool> verifyAndSavePurchase(String verificationData) async {
    generalPrintLog("INAPPPurchase", "Starting receipt verification...");

    final receiptBody = {
      'receipt-data': verificationData,
      'exclude-old-transactions': false,
      'password': iosSharedSecret,
    };

    try {
      final responseModel = await _validateWithApple(receiptBody);

      if (responseModel == null || responseModel.status != 0) {
        generalPrintLog(
          "INAPPPurchase",
          "Verification failed. Status: ${responseModel?.status}",
        );
        await DatabaseBox.savePurchaseDetailsSaveList(
          [],
        ); // Clear local purchases
        return false;
      }

      // *** KEY CHANGE: Prioritize latest_receipt_info for subscriptions ***
      final transactions =
          responseModel.latestReceiptInfo.isNotEmpty
              ? responseModel.latestReceiptInfo
              : responseModel.receipt?.inApp ?? [];

      if (transactions.isEmpty) {
        generalPrintLog("INAPPPurchase", "No transactions found in receipt.");
        await DatabaseBox.savePurchaseDetailsSaveList([]);
        return false;
      }

      // Find the single most recent, active transaction
      LatestReceiptInfo? latestActiveTransaction;
      for (var transaction in transactions) {
        try {
          final expiresDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(transaction.expiresDateMs),
            isUtc: true,
          );
          if (expiresDate.isAfter(DateTime.now().toUtc())) {
            if (latestActiveTransaction == null ||
                int.parse(transaction.purchaseDateMs) >
                    int.parse(latestActiveTransaction.purchaseDateMs)) {
              latestActiveTransaction = transaction;
            }
          }
        } catch (e) {
          // Ignore transactions with invalid date format
        }
      }

      if (latestActiveTransaction != null) {
        final purchaseDetail = PurchaseDetailsSave(
          purchaseID: latestActiveTransaction.transactionId,
          productID: latestActiveTransaction.productId,
          productTitle: "", // Consider fetching this from your product list
          verificationData: verificationData, // Store original receipt
          transactionDate: DateTime.fromMillisecondsSinceEpoch(
            int.parse(latestActiveTransaction.purchaseDateMs),
            isUtc: true,
          ),
          expireDate: DateTime.fromMillisecondsSinceEpoch(
            int.parse(latestActiveTransaction.expiresDateMs),
            isUtc: true,
          ),
          status: true,
        );

        generalPrintLog(
          "INAPPPurchase",
          "Successfully verified active subscription: ${purchaseDetail.productID}",
        );
        await DatabaseBox.savePurchaseDetailsSaveList([purchaseDetail]);
        return true;
      } else {
        generalPrintLog("INAPPPurchase", "No active subscriptions found.");
        await DatabaseBox.savePurchaseDetailsSaveList([]);
        return false;
      }
    } catch (e) {
      generalPrintLog("INAPPPurchase", "Verification Error: $e");
      // Don't clear purchases on network error, as the sub might still be active
      return false;
    }
  }

  // *** NEW: Handles the Production/Sandbox retry logic ***
  static Future<ModelReceiptVerification?> _validateWithApple(
    Map<String, dynamic> receiptBody, {
    bool isRetry = false,
  }) async {
    final useSandbox = isRetry; // Use sandbox only on the retry attempt
    final response = await ServicesInAppPurchase.validateReceiptIos(
      receiptBody,
      useSandbox: useSandbox,
    );
    final responseModel = modelReceiptVerificationFromJson(response.body);

    // If status is 21007, it's a sandbox receipt. Retry against sandbox ONLY if we haven't already.
    if (responseModel.status == 21007 && !isRetry) {
      generalPrintLog(
        "INAPPPurchase",
        "Status 21007. Retrying with Sandbox URL...",
      );
      return _validateWithApple(receiptBody, isRetry: true);
    }

    return responseModel;
  }

  //===== Dashboard Functions Calls ===============

  // Handles new purchases and restorations
  static void handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails
            .verificationData
            .serverVerificationData
            .isNotEmpty) {
          verifyAndSavePurchase(
            purchaseDetails.verificationData.serverVerificationData,
          );
        }
      }
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }
  }

  // Checks local storage on app start
  static Future<void> loadAndVerifyExistingPurchase() async {
    try {
      var list = DatabaseBox.getPurchaseDetailsSaveList();
      if (list.isNotEmpty) {
        String verificationData = list[0].verificationData;
        // Re-verify to ensure the subscription hasn't been cancelled
        await verifyAndSavePurchase(verificationData);
      }
    } catch (e) {
      debugPrint("Failed to load existing purchase: $e");
    }
  }
}
