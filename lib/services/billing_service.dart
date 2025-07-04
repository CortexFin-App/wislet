import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';
import 'package:sage_wallet_reborn/services/api_client.dart';

class BillingService {
  static const String _proSubscriptionId = 'pro_monthly_sub';

  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiClient _apiClient = getIt<ApiClient>();
  late StreamSubscription<List<PurchaseDetails>> _purchaseStream;
  
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  // Використовуємо ValueNotifier для миттєвого оновлення UI
  final ValueNotifier<bool> isProUserNotifier = ValueNotifier(false);

  Future<void> init() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("Billing service is not available.");
      return;
    }

    // Слухаємо потік покупок
    _purchaseStream = _iap.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _purchaseStream.cancel();
    }, onError: (error) {
      debugPrint("Billing stream error: $error");
    });

    await loadProducts();
  }

  /// Завантажує продукти з Play Console
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

  /// Ініціює покупку Pro-підписки
  Future<void> buyProSubscription() async {
    if (_products.isEmpty) {
      debugPrint("No products to buy. Trying to load them again...");
      await loadProducts();
      if (_products.isEmpty) {
        // Показати помилку користувачу, що продукти не доступні
        return;
      }
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: _products.first);
    // Використовуємо buyNonConsumable, як рекомендує офіційна документація для підписок на Android
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Ініціює процес відновлення покупок
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Обробник подій зі стріму покупок
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        // Якщо покупка успішна або відновлена, запускаємо верифікацію
        _handleAndVerifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("Purchase error: ${purchaseDetails.error}");
      }
    }
  }

  /// Головний метод верифікації та завершення покупки
  Future<void> _handleAndVerifyPurchase(PurchaseDetails purchaseDetails) async {
    final bool isValid = await _verifyPurchaseOnBackend(purchaseDetails);

    if (isValid) {
      // ТІЛЬКИ ЯКЩО БЕКЕНД ПІДТВЕРДИВ ПОКУПКУ, ми завершуємо її
      await _iap.completePurchase(purchaseDetails);
      isProUserNotifier.value = true;
      debugPrint("SUCCESS: Purchase completed and verified.");
    } else {
      // Якщо верифікація не вдалась, ми НЕ завершуємо покупку.
      // Google Play спробує доставити її нам знову пізніше.
      // Тут потрібно показати користувачу повідомлення про помилку.
      debugPrint("ERROR: Backend verification failed. Purchase not completed.");
    }
  }

  /// Надсилає дані на наш сервер для фінальної перевірки
  Future<bool> _verifyPurchaseOnBackend(PurchaseDetails purchaseDetails) async {
    try {
      // Динамічно отримуємо package name
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      await _apiClient.post(
        '/billing/verify-purchase',
        body: {
          'purchase_token': purchaseDetails.verificationData.serverVerificationData,
          'subscription_id': purchaseDetails.productID,
          'package_name': packageName,
        },
      );
      // Якщо запит пройшов без помилок, вважаємо верифікацію успішною
      return true;
    } catch (e) {
      // Якщо наш сервер повернув помилку або недоступний
      debugPrint("API Client Error during verification: $e");
      return false;
    }
  }

  void dispose() {
    _purchaseStream.cancel();
  }
}