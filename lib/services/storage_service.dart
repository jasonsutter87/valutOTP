import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';
import '../models/folder.dart';

/// Handles secure storage of accounts and folders.
/// All data is stored encrypted using platform Keychain/Keystore.
class StorageService {
  static const _accountsKey = 'vault_otp_accounts';
  static const _foldersKey = 'vault_otp_folders';
  static const _lastFolderPathKey = 'vault_otp_last_folder_path';

  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // ============ Accounts ============

  Future<List<Account>> getAccounts() async {
    final json = await _storage.read(key: _accountsKey);
    if (json == null) return [];

    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final json = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _accountsKey, value: json);
  }

  Future<void> addAccount(Account account) async {
    final accounts = await getAccounts();
    accounts.add(account);
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(Account account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
      await saveAccounts(accounts);
    }
  }

  Future<void> deleteAccount(String id) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    await saveAccounts(accounts);
  }

  // ============ Folders ============

  Future<List<Folder>> getFolders() async {
    final json = await _storage.read(key: _foldersKey);
    if (json == null) return [];

    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => Folder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveFolders(List<Folder> folders) async {
    final json = jsonEncode(folders.map((f) => f.toJson()).toList());
    await _storage.write(key: _foldersKey, value: json);
  }

  Future<void> addFolder(Folder folder) async {
    final folders = await getFolders();
    folders.add(folder);
    await saveFolders(folders);
  }

  Future<void> updateFolder(Folder folder) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == folder.id);
    if (index != -1) {
      folders[index] = folder;
      await saveFolders(folders);
    }
  }

  Future<void> deleteFolder(String id) async {
    final folders = await getFolders();

    // Find all subfolders (for cascade delete)
    final folderIdsToDelete = <String>{id};
    for (final folder in folders) {
      if (folder.parentId == id) {
        folderIdsToDelete.add(folder.id);
      }
    }

    // Unassign all accounts from deleted folders
    final accounts = await getAccounts();
    final updatedAccounts = accounts.map((a) {
      if (a.folderId != null && folderIdsToDelete.contains(a.folderId)) {
        return a.copyWith(clearFolderId: true);
      }
      return a;
    }).toList();
    await saveAccounts(updatedAccounts);

    // Delete the folder and its subfolders
    folders.removeWhere((f) => folderIdsToDelete.contains(f.id));
    await saveFolders(folders);
  }

  // ============ Last Folder Path ============

  /// Gets the last folder navigation path (list of folder IDs).
  /// Returns empty list if none saved or if saved folders no longer exist.
  Future<List<String>> getLastFolderPath() async {
    final json = await _storage.read(key: _lastFolderPathKey);
    if (json == null) return [];

    final List<dynamic> decoded = jsonDecode(json);
    final path = decoded.cast<String>();

    // Validate that all folders in path still exist
    final folders = await getFolders();
    final folderIds = folders.map((f) => f.id).toSet();

    // Return the valid portion of the path
    final validPath = <String>[];
    for (final id in path) {
      if (folderIds.contains(id)) {
        validPath.add(id);
      } else {
        break; // Stop at first missing folder
      }
    }
    return validPath;
  }

  /// Saves the current folder navigation path.
  Future<void> saveLastFolderPath(List<String> path) async {
    final json = jsonEncode(path);
    await _storage.write(key: _lastFolderPathKey, value: json);
  }

  // ============ Utility ============

  /// Clears all data - use with caution!
  Future<void> clearAll() async {
    await _storage.delete(key: _accountsKey);
    await _storage.delete(key: _foldersKey);
    await _storage.delete(key: _lastFolderPathKey);
  }
}
