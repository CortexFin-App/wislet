import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';

class BillingService {
  // Цей ID має співпадати з тим, що ти створив у Google Play Console
  static const String _proSubscriptionId = 'pro_monthly_sub';

  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiClient _apiClient = getIt<ApiClient>();
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  bool isProUser = false;

  Future<void> init() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("Billing service is not available.");
      return;
    }

    _subscription = _iap.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint("Billing stream error: $error");
    });

    await loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails({_proSubscriptionId});
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Products not found: ${response.notFoundIDs}");
        _products = [];
        return;
      }
      _products = response.productDetails;
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  Future<bool> buyProSubscription() async {
    if (_products.isEmpty) {
      debugPrint("No products to buy.");
      return false;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: _products.first);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("Purchase error: ${purchaseDetails.error}");
      }
      // Завершуємо транзакцію на стороні клієнта
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Викликаємо наш бекенд для верифікації
      await _apiClient.post(
        '/billing/verify-purchase',
        body: {
          'purchase_token': purchaseDetails.verificationData.serverVerificationData,
          'subscription_id': purchaseDetails.productID,
          'package_name': 'com.cortexfin.sage_wallet', // Твоя назва пакету
        },
      );
      // Після успішної верифікації, ProStatusProvider оновить статус при наступному запиті
      // Можна також оновити локально для миттєвого ефекту
      debugPrint("Purchase successfully verified on backend.");

    } catch (e) {
      debugPrint("Backend verification failed: $e");
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}