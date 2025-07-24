import 'dart:async';
import 'dart:io';

import 'package:admob_inapp_app/admob/appopen_ad_helper.dart';
import 'package:admob_inapp_app/data/database_box.dart';
import 'package:admob_inapp_app/data/databases.dart';
import 'package:admob_inapp_app/in_app_purchase/constant_inapps.dart';
import 'package:admob_inapp_app/in_app_purchase/inapp_utils.dart';
import 'package:admob_inapp_app/screen_dashboard.dart';
import 'package:admob_inapp_app/utilities/constants.dart';
import 'package:admob_inapp_app/utilities/links_utils.dart';
import 'package:admob_inapp_app/utilities/widgets_reusing.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class ScreenPremiumSubscription extends StatefulWidget {
  const ScreenPremiumSubscription({super.key});

  @override
  ScreenPremiumSubscriptionState createState() =>
      ScreenPremiumSubscriptionState();
}

class ScreenPremiumSubscriptionState extends State<ScreenPremiumSubscription>
    with WidgetsBindingObserver {
  // Add WidgetsBindingObserver to listen to app lifecycle

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  // StreamSubscription to listen for purchase updates from InAppPurchase
  late StreamSubscription<List<PurchaseDetails>> _purchaseStreamSubscription;

  // List to store fetched subscription plans (ProductDetails mapped to SubscriptionPlan)
  List<SubscriptionPlan> _availableSubscriptionPlans = [];
  bool _isAvailable = false; // Indicates if IAP is available on the device
  bool _loadingProducts = true; // Loading state for fetching products
  String? _queryProductError; // Stores error message if product fetching fails

  bool _isPurchased = false; // State for ongoing purchase

  bool _isPurchasing = false;
  bool _isRestoring = false;
  bool _isPremiumUser = false;
  String? _activePremiumProductId;

  // Stores the ID of the currently selected subscription plan
  String selectedProductId = '';

  @override
  void initState() {
    super.initState();

    MyAppState().updateValue(true); // disabled app open ads

    WidgetsBinding.instance.addObserver(this); // Add app lifecycle observer

    _initializeIAP(); // Initialize In-App Purchase
    _checkPremiumStatus(); // Check user's premium status from DatabaseBox now

    selectedProductId =
        currentProductIds.isNotEmpty ? currentProductIds.elementAt(0) : '';
  }

  // Listen to app lifecycle changes (e.g., app resumes from background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPremiumStatus(); // Re-check premium status when app resumes
    }
  }

  // Initialize In-App Purchase setup
  Future<void> _initializeIAP() async {
    setState(() {
      _loadingProducts = true;
      _queryProductError = null;
    });

    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      setState(() {
        _loadingProducts = false;
        _queryProductError = 'In-app purchases not available on this device.';
      });
      WidgetsReusing.getMaterialBar(context, _queryProductError!);
      return;
    }

    // Set up the purchase stream listener
    _purchaseStreamSubscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _purchaseStreamSubscription.cancel();
      },
      onError: (error) {
        // Handle stream errors (e.g., network issues)
        setState(() {
          _queryProductError = 'Error occurred: ${error.toString()}';
          _isPurchasing = false; // Reset purchasing state on error
        });
        WidgetsReusing.getMaterialBar(
          context,
          'Error processing purchase: ${error.toString()}',
        );
      },
    );

    await _loadProducts(); // Load available products
  }

  // Load product details from App Store/Google Play
  Future<void> _loadProducts() async {
    final ProductDetailsResponse productDetailResponse = await _inAppPurchase
        .queryProductDetails(currentProductIds.toSet());

    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _loadingProducts = false;
      });
      WidgetsReusing.getMaterialBar(context, _queryProductError!);
      return;
    }

    if (productDetailResponse.notFoundIDs.isNotEmpty) {
      print('Products not found: ${productDetailResponse.notFoundIDs}');
      // You might want to log this or show a more specific message to the user
    }

    setState(() {
      // Map fetched ProductDetails to your SubscriptionPlan model
      _availableSubscriptionPlans =
          productDetailResponse.productDetails
              .map((details) => SubscriptionPlan.fromProductDetails(details))
              .toList();

      // Sort the plans
      _availableSubscriptionPlans.sort((a, b) {
        final int durationA = _getSubscriptionDurationDays(a.id);
        final int durationB = _getSubscriptionDurationDays(b.id);
        return durationA.compareTo(durationB);
      });

      // Ensure selectedProductId is valid after loading and sorting
      if (selectedProductId.isNotEmpty) {
        final selectedPlan = _availableSubscriptionPlans.firstWhereOrNull(
          (plan) => plan.id == selectedProductId,
        );
        if (selectedPlan == null && _availableSubscriptionPlans.isNotEmpty) {
          selectedProductId = _availableSubscriptionPlans.first.id;
        }
      } else if (_availableSubscriptionPlans.isNotEmpty) {
        selectedProductId = _availableSubscriptionPlans.first.id;
      }
      _loadingProducts = false;
    });
    // After loading and sorting products, re-check premium status to select the correct plan
    // This is crucial to ensure the premium user's active plan is selected if available.
    _checkPremiumStatus(); // Call again to ensure selectedProductId is updated based on premium status
  }

  // Listener for purchase updates (from the _purchaseStreamSubscription)
  void _listenToPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        WidgetsReusing.getMaterialBar(context, 'Purchase pending...');
        setState(() => _isPurchasing = true);
      } else {
        setState(() {
          _isPurchasing = false; // Reset purchasing state
          _isRestoring = false; // Reset restoring state
        });
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handlePurchaseError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _deliverPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          WidgetsReusing.getMaterialBar(context, 'Purchase canceled by user.');
        }
      }
    }
  }

  // Handle purchase errors
  void _handlePurchaseError(IAPError error) {
    print('Purchase Error: ${error.message}, Code: ${error.code}');
    WidgetsReusing.getMaterialBar(context, 'Purchase failed: ${error.message}');
  }

  // --- NEW: Helper to determine subscription duration based on ProductDetails ---
  // You'll need to refine this based on your actual ProductDetails structure
  // and how you define your subscription periods in App Store Connect/Google Play.
  // For example, a weekly subscription might have a 7 day period.
  int _getSubscriptionDurationDays(String productId) {
    final ProductDetails? productDetails =
        _availableSubscriptionPlans
            .firstWhereOrNull((plan) => plan.id == productId)
            ?.productDetails;

    // Fallback if subscription details are not available or parsed
    // This part needs to be accurate based on your product IDs.
    // You might want to map product IDs to their durations explicitly.
    if (productId.contains('weekly')) {
      return 7;
    } else if (productId.contains('monthly')) {
      return 30;
    } else if (productId.contains('quarterly')) {
      return 90;
    } else if (productId.contains('yearly')) {
      return 365;
    }
    return 0; // Default to 0 if duration cannot be determined
  }

  // --- MODIFIED: _deliverPurchase to use DatabaseBox ---
  Future<void> _deliverPurchase(PurchaseDetails purchaseDetails) async {
    print('Delivering purchase for product: ${purchaseDetails.productID}');

    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      // Calculate subscription duration
      final int subscriptionDays = _getSubscriptionDurationDays(
        purchaseDetails.productID,
      );

      // Use the actual transaction date from purchaseDetails if available, otherwise DateTime.now()
      // purchaseDetails.transactionDate might be null on iOS for initial purchases (only for restorationInfo)
      DateTime transactionDate = DateTime.now();

      if (purchaseDetails.transactionDate != null) {
        try {
          transactionDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(purchaseDetails.transactionDate!),
          );
        } catch (e) {
          try {
            transactionDate = DateTime.parse(
              purchaseDetails.transactionDate.toString(),
            );
          } catch (e) {
            debugPrint(
              'Delivering purchase for transactionDate error: ${e.toString()}',
            );
          }
        }
      }

      // Create PurchaseDetailsSave object
      final PurchaseDetailsSave purchaseDetailsSave = PurchaseDetailsSave(
        purchaseID: purchaseDetails.purchaseID,
        productID: purchaseDetails.productID,
        // Use the actual product title from fetched product details if available
        productTitle:
            _availableSubscriptionPlans
                .firstWhereOrNull(
                  (plan) => plan.id == purchaseDetails.productID,
                )
                ?.title ??
            purchaseDetails.productID, // Fallback to productID
        verificationData:
            purchaseDetails.verificationData.serverVerificationData,
        transactionDate: transactionDate,
        expireDate: transactionDate.add(Duration(days: subscriptionDays)),
        status: true, // Mark as active upon successful purchase/restore
      );

      // Get existing list of saved purchases
      List<PurchaseDetailsSave> list =
          await DatabaseBox.getPurchaseDetailsSaveList();

      // Check if this purchaseID already exists to prevent duplicates on restore/re-delivery
      final int existingIndex = list.indexWhere(
        (p) => p.purchaseID == purchaseDetailsSave.purchaseID,
      );
      if (existingIndex != -1) {
        // Update existing entry
        list[existingIndex] = purchaseDetailsSave;
        generalPrintLog(
          "Updating existing purchase details for ID",
          purchaseDetailsSave.purchaseID ?? "N/A",
        );
      } else {
        // Add new purchase
        list.add(purchaseDetailsSave);
        generalPrintLog(
          "Adding new purchase details for ID",
          purchaseDetailsSave.purchaseID ?? "N/A",
        );
      }

      // Save the updated list
      generalPrintLog("INAPPPurchase list length", list.length);
      WidgetsReusing.getMaterialBar(context, "listlistlist ${list.length}");
      await DatabaseBox.savePurchaseDetailsSaveList(list);
      _isPurchased = true;

      // Re-check premium status after saving new purchase
      _checkPremiumStatus();

      WidgetsReusing.getMaterialBar(
        context,
        'Purchase successful! Thank you for going premium.',
      );

      // Acknowledge/Complete the purchase to finalize it with the store.
      // This is crucial for non-consumable products and subscriptions.
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // --- MODIFIED: _checkPremiumStatus to read from DatabaseBox ---
  Future<void> _checkPremiumStatus() async {
    List<PurchaseDetailsSave> savedPurchases =
        await DatabaseBox.getPurchaseDetailsSaveList();
    bool isCurrentlyPremium = false;
    String? activeProductId = null;

    if (savedPurchases.isNotEmpty) {
      for (var purchase in savedPurchases) {
        if (purchase.status == true && purchase.expireDate != null) {
          if (purchase.expireDate!.isAfter(DateTime.now())) {
            isCurrentlyPremium = true;
            activeProductId = purchase.productID;
            break;
          }
        }
      }
    }

    // Use a temporary variable to hold the next selectedProductId
    String? nextSelectedProductId = selectedProductId;

    if (isCurrentlyPremium && activeProductId != null) {
      nextSelectedProductId = activeProductId;
    } else if (_availableSubscriptionPlans.isNotEmpty) {
      // If not premium or no active product, ensure a default is selected
      // This ensures something is selected if products are loaded but no active premium
      nextSelectedProductId = _availableSubscriptionPlans.first.id;
    }

    setState(() {
      _isPremiumUser = isCurrentlyPremium;
      _activePremiumProductId = activeProductId;
      selectedProductId = nextSelectedProductId ?? ''; // Ensure it's never null
    });
    print(
      'Premium status loaded: $_isPremiumUser. Active plan: $_activePremiumProductId. Selected product: $selectedProductId',
    );
  }

  // Initiate a purchase for the selected product
  void _buyProduct(ProductDetails productDetails) async {
    if (!_isAvailable) {
      WidgetsReusing.getMaterialBar(context, 'In-app purchases not available.');
      return;
    }
    if (_isPurchasing) {
      WidgetsReusing.getMaterialBar(
        context,
        'Purchase in progress. Please wait.',
      );
      return;
    }

    setState(() {
      _isPurchasing = true;
    });

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Restore previous purchases
  void _restorePurchases() async {
    if (!_isAvailable) {
      WidgetsReusing.getMaterialBar(context, 'In-app purchases not available.');
      return;
    }
    if (_isRestoring) {
      WidgetsReusing.getMaterialBar(
        context,
        'Restore in progress. Please wait.',
      );
      return;
    }

    setState(() => _isRestoring = true);
    await _inAppPurchase.restorePurchases();
    // The _listenToPurchaseUpdates will catch the restored purchases and call _deliverPurchase
    WidgetsReusing.getMaterialBar(
      context,
      'Attempting to restore purchases...',
    );
  }

  // Callback when a subscription plan card is tapped
  void _onSubscriptionPlanSelected(String id) {
    setState(() {
      selectedProductId = id;
    });
  }

  @override
  void dispose() {
    super.dispose();
    MyAppState().updateValue(false); // enable open ads after 30 sec
    _purchaseStreamSubscription.cancel(); // Cancel the subscription stream
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Step 1: Dynamically decide if the screen can be popped.
      // It can pop normally if the user is NOT a new purchaser.
      canPop: !_isPurchased,

      // Step 2: Handle the pop event.
      onPopInvokedWithResult: (bool didPop, asdc) {
        // `didPop` will be `false` if the pop was blocked (because `canPop` was false).
        // We only need to act if the pop was blocked.
        if (didPop) {
          return; // The pop happened successfully, nothing more to do.
        }

        // If we reach here, it means `didPop` is false, which happens when `_isPurchased` is true.
        // Now, we execute our custom navigation logic.
        Constants.openNewScreenClean(context, ScreenDashboard());
      },
      child: Scaffold(
        backgroundColor: InAppConstants.textColorWhite,
        appBar: AppBar(
          backgroundColor: Colors.purple,
          // Step 3: Use a standard BackButton.
          // It will correctly trigger the PopScope logic.
          leading: BackButton(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () {
                Constants.openUrlSite(context, LinksUtils.privacyPolicyUrl);
              },
              icon: const Icon(Icons.policy, color: Colors.white),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: InAppConstants.screenHorizontalPadding,
            vertical: InAppConstants.screenVerticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),

              // Conditional display based on IAP loading/error/data availability
              if (_loadingProducts)
                Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_queryProductError != null)
                Expanded(
                  child: Center(
                    child: Text(
                      'Error loading plans: $_queryProductError\nPlease check your internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else if (_availableSubscriptionPlans.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No subscription plans available.\nPlease try again later.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else // Display subscription plans if loaded successfully
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Display premium status banner if user is premium
                        if (_isPremiumUser)
                          Container(
                            padding: const EdgeInsets.all(
                              InAppConstants.defaultPadding,
                            ),
                            margin: const EdgeInsets.only(
                              bottom: InAppConstants.defaultPadding,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                InAppConstants.cardBorderRadius,
                              ),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: InAppConstants.defaultPadding),
                                Expanded(
                                  child: Text(
                                    'You are already a premium user! Thank you for your support.',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Subscription Box Container
                        Padding(
                          padding: const EdgeInsets.all(
                            InAppConstants.defaultPadding / 2,
                          ),
                          child: Column(
                            children: [
                              InAppConstantsView.SELECT_YOUR_SUBSCRIPTION_PLAN,
                              const SizedBox(height: 10),
                              // Dynamically display subscription plan cards
                              // Dynamically display subscription plan cards
                              AbsorbPointer(
                                // Apply AbsorbPointer here
                                absorbing: _isPremiumUser, // Disable if premium
                                child: Column(
                                  children:
                                      _availableSubscriptionPlans.map((plan) {
                                        return SubscriptionPlanCard(
                                          plan: plan,
                                          isSelected:
                                              selectedProductId == plan.id,
                                          onTap: _onSubscriptionPlanSelected,
                                          // NEW: Pass a flag indicating if this is the purchased plan
                                          isPurchasedPlan:
                                              _isPremiumUser &&
                                              plan.id ==
                                                  _activePremiumProductId,
                                        );
                                      }).toList(),
                                ),
                              ),

                              if (Platform.isIOS)
                                Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    title: const Text(
                                      "Term of Use",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: InAppConstants.textColorBlack,
                                      ),
                                    ),
                                    children: <Widget>[
                                      getSubscriptionInfoView(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: InAppConstants.defaultPadding),

              // const SizedBox(height: InAppConstants.defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GradientButton(
                      text:
                          _isPremiumUser
                              ? "PREMIUM ACTIVE"
                              : (_isPurchasing
                                  ? "PURCHASING..."
                                  : "SUBSCRIBE NOW"),
                      onPressed:
                          _isPremiumUser ||
                                  _isPurchasing ||
                                  _loadingProducts ||
                                  selectedProductId.isEmpty
                              ? null // Disable button if already premium, purchasing, loading, or no plan selected
                              : () {
                                // Find the ProductDetails for the selected plan
                                final ProductDetails? selectedProductDetails =
                                    _availableSubscriptionPlans
                                        .firstWhereOrNull(
                                          (plan) =>
                                              plan.id == selectedProductId,
                                        )
                                        ?.productDetails;

                                if (selectedProductDetails != null) {
                                  _buyProduct(selectedProductDetails);
                                } else {
                                  WidgetsReusing.getMaterialBar(
                                    context,
                                    'Please select a subscription plan.',
                                  );
                                }
                              },
                      type: GradientButtonType.large,
                    ),
                  ),
                  const SizedBox(width: InAppConstants.defaultPadding),
                  Expanded(
                    child: GradientButton(
                      text: _isRestoring ? "RESTORING..." : "Restore",
                      onPressed:
                          _isRestoring || _loadingProducts || _isPremiumUser
                              ? null // Disable while restoring, loading, or if already premium
                              : _restorePurchases,
                      type: GradientButtonType.small,
                    ),
                  ),
                  const SizedBox(width: InAppConstants.defaultPadding),
                  Expanded(
                    child: GradientButton(
                      text: "Manage",
                      onPressed: () {
                        if (Platform.isIOS) {
                          // Use the 'itms-apps' deep link scheme for a direct path
                          Constants.openUrlSite(
                            context,
                            'itms-apps://apps.apple.com/account/subscriptions',
                          );
                        } else if (Platform.isAndroid) {
                          // This URL is correct for Android
                          Constants.openUrlSite(
                            context,
                            'https://play.google.com/store/account/subscriptions',
                          );
                        } else {
                          WidgetsReusing.getMaterialBar(
                            context,
                            'Managing subscriptions is not supported on this platform.',
                          );
                        }
                      },
                      type: GradientButtonType.small,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to find an element in a list that matches a condition (similar to firstWhereOrNull in newer Dart versions)
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
