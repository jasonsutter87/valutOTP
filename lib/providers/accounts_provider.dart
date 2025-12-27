import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';
import 'folders_provider.dart';

/// Provides the list of all accounts
final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(AccountsNotifier.new);

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<List<Account>> build() async {
    return _storage.getAccounts();
  }

  Future<void> addAccount(Account account) async {
    await _storage.addAccount(account);

    final accounts = state.value ?? [];
    state = AsyncValue.data([...accounts, account]);
  }

  Future<void> updateAccount(Account account) async {
    await _storage.updateAccount(account);

    final accounts = state.value ?? [];
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      final updated = [...accounts];
      updated[index] = account;
      state = AsyncValue.data(updated);
    }
  }

  Future<void> deleteAccount(String id) async {
    await _storage.deleteAccount(id);

    final accounts = state.value ?? [];
    state = AsyncValue.data(accounts.where((a) => a.id != id).toList());
  }

  Future<void> moveToFolder(String accountId, String? folderId) async {
    final accounts = state.value ?? [];
    final account = accounts.firstWhere((a) => a.id == accountId);
    final updated = account.copyWith(
      folderId: folderId,
      clearFolderId: folderId == null,
    );
    await updateAccount(updated);
  }
}

/// Provides accounts filtered by folder (includes accounts in subfolders)
/// Pass null for "All", or a folder ID to filter
final accountsByFolderProvider =
    Provider.family<List<Account>, String?>((ref, folderId) {
  final accountsAsync = ref.watch(accountsProvider);
  final folders = ref.watch(foldersProvider).value ?? [];

  return accountsAsync.when(
    data: (accounts) {
      if (folderId == null) {
        return accounts;
      }

      // Get all folder IDs that belong to this folder tree
      // (the folder itself + any subfolders)
      final folderIds = <String>{folderId};
      for (final folder in folders) {
        if (folder.parentId == folderId) {
          folderIds.add(folder.id);
        }
      }

      return accounts.where((a) => folderIds.contains(a.folderId)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provides accounts directly in a folder (not including subfolders)
/// Useful for showing accounts at current navigation level only
final accountsDirectlyInFolderProvider =
    Provider.family<List<Account>, String?>((ref, folderId) {
  final accountsAsync = ref.watch(accountsProvider);

  return accountsAsync.when(
    data: (accounts) {
      if (folderId == null) {
        // At root: show only accounts with no folder
        return accounts.where((a) => a.folderId == null).toList();
      }
      return accounts.where((a) => a.folderId == folderId).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
