import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize RevenueCat for in-app purchases
  await PurchaseService.initialize();

  runApp(
    const ProviderScope(
      child: VaultOTPApp(),
    ),
  );
}
