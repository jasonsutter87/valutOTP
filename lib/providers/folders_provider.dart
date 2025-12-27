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

  /// Add a root folder
  Future<void> addFolder(String name) async {
    await addFolderWithParent(name, null);
  }

  /// Add a folder with optional parent (subfolder)
  Future<void> addFolderWithParent(String name, String? parentId) async {
    final folders = state.value ?? [];

    // Check 2-level limit: can't create subfolder in a subfolder
    if (parentId != null) {
      final parent = folders.firstWhere(
        (f) => f.id == parentId,
        orElse: () => throw Exception('Parent folder not found'),
      );
      if (parent.parentId != null) {
        throw Exception('Cannot create subfolder in a subfolder (2 levels max)');
      }
    }

    final newFolder = Folder.create(
      name: name,
      sortOrder: folders.length,
      parentId: parentId,
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

    // Remove deleted folder and its subfolders from state
    final folders = state.value ?? [];
    final idsToRemove = <String>{id};

    // Also find subfolders
    for (final folder in folders) {
      if (folder.parentId == id) {
        idsToRemove.add(folder.id);
      }
    }

    state = AsyncValue.data(
      folders.where((f) => !idsToRemove.contains(f.id)).toList(),
    );

    // Refresh accounts since folder deletion unassigns them
    ref.invalidate(accountsProviderFamily);
  }
}

/// Provider for root folders only (no parent)
final rootFoldersProvider = Provider<List<Folder>>((ref) {
  final folders = ref.watch(foldersProvider).value ?? [];
  return folders.where((f) => f.isRoot).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Provider for subfolders of a given parent
final subFoldersProvider = Provider.family<List<Folder>, String>((ref, parentId) {
  final folders = ref.watch(foldersProvider).value ?? [];
  return folders.where((f) => f.parentId == parentId).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Check if a folder has subfolders
final hasSubfoldersProvider = Provider.family<bool, String>((ref, folderId) {
  final folders = ref.watch(foldersProvider).value ?? [];
  return folders.any((f) => f.parentId == folderId);
});

/// Check if a folder can have subfolders (is it a root folder?)
final canHaveSubfoldersProvider = Provider.family<bool, String>((ref, folderId) {
  final folders = ref.watch(foldersProvider).value ?? [];
  final folder = folders.firstWhere(
    (f) => f.id == folderId,
    orElse: () => Folder(id: '', name: '', sortOrder: 0, createdAt: DateTime.now()),
  );
  return folder.isRoot;
});

/// Provider family placeholder - will be defined in accounts_provider.dart
/// This is here to avoid circular dependencies
final accountsProviderFamily = Provider<void>((ref) {});
