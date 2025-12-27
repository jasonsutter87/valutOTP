import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase_service.dart';

/// Provides the premium status of the user
final premiumProvider =
    AsyncNotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

class PremiumNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Listen to customer info changes from RevenueCat
    PurchaseService.customerInfoStream.listen((customerInfo) {
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;
      state = AsyncValue.data(isPremium);
    });

    return PurchaseService.isPremium();
  }

  Future<bool> purchase() async {
    state = const AsyncValue.loading();
    final success = await PurchaseService.purchasePremium();
    state = AsyncValue.data(success);
    return success;
  }

  Future<bool> restore() async {
    state = const AsyncValue.loading();
    final success = await PurchaseService.restorePurchases();
    state = AsyncValue.data(success);
    return success;
  }
}

/// Simple sync provider for quick checks (defaults to false while loading)
final isPremiumProvider = Provider<bool>((ref) {
  final premiumAsync = ref.watch(premiumProvider);
  return premiumAsync.when(
    data: (isPremium) => isPremium,
    loading: () => false,
    error: (_, __) => false,
  );
});
