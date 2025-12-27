import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/totp_service.dart';

/// Global TOTP service provider
final totpServiceProvider = Provider<TOTPService>((ref) {
  return TOTPService();
});

/// Provides current timestamp that updates every second.
/// Widgets watching this will rebuild every second to show live codes.
final tickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});
