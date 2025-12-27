import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static const String _entitlementId = 'premium';
  static const String _productId = 'vaultotp_premium';

  // TODO: Replace these with your actual RevenueCat API keys
  static const String _androidApiKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';
  static const String _iosApiKey = 'YOUR_REVENUECAT_IOS_API_KEY';

  static final StreamController<CustomerInfo> _customerInfoController =
      StreamController<CustomerInfo>.broadcast();

  static Future<void> initialize() async {
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_androidApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_iosApiKey);
    } else {
      return; // Unsupported platform
    }

    await Purchases.configure(configuration);

    // Listen to customer info updates
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      _customerInfoController.add(customerInfo);
    });
  }

  static Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  static Future<List<StoreProduct>> getProducts() async {
    try {
      final products = await Purchases.getProducts([_productId]);
      return products;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  static Future<bool> purchasePremium() async {
    try {
      final products = await getProducts();
      if (products.isEmpty) {
        debugPrint('No products available');
        return false;
      }

      final product = products.first;
      final result = await Purchases.purchaseStoreProduct(product);

      return result.customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      if (e is PurchasesErrorCode) {
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          debugPrint('Purchase cancelled by user');
          return false;
        }
      }
      debugPrint('Error making purchase: $e');
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  static Stream<CustomerInfo> get customerInfoStream {
    return _customerInfoController.stream;
  }
}
