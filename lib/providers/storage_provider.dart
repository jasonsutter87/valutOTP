import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Global storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
