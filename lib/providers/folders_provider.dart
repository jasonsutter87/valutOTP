import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

/// Provides the list of folders
final foldersProvider =
    AsyncNotifierProvider<FoldersNotifier, List<Folder>>(FoldersNotifier.new);

class FoldersNotifier extends AsyncNotifier<List<Folder>> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<List<Folder>> build() async {
    return _storage.getFolders();
  }

  Future<void> addFolder(String name) async {
    final folders = state.value ?? [];
    final newFolder = Folder.create(
      name: name,
      sortOrder: folders.length,
    );

    await _storage.addFolder(newFolder);
    state = AsyncValue.data([...folders, newFolder]);
  }

  Future<void> updateFolder(Folder folder) async {
    await _storage.updateFolder(folder);

    final folders = state.value ?? [];
    final index = folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      final updated = [...folders];
      updated[index] = folder;
      state = AsyncValue.data(updated);
    }
  }

  Future<void> deleteFolder(String id) async {
    await _storage.deleteFolder(id);

    final folders = state.value ?? [];
    state = AsyncValue.data(folders.where((f) => f.id != id).toList());

    // Refresh accounts since folder deletion unassigns them
    ref.invalidate(accountsProviderFamily);
  }
}

/// Provider family placeholder - will be defined in accounts_provider.dart
/// This is here to avoid circular dependencies
final accountsProviderFamily = Provider<void>((ref) {});
