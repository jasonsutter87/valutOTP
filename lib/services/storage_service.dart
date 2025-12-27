import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';
import '../models/folder.dart';

/// Handles secure storage of accounts and folders.
/// All data is stored encrypted using platform Keychain/Keystore.
class StorageService {
  static const _accountsKey = 'vault_otp_accounts';
  static const _foldersKey = 'vault_otp_folders';

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
    // First, unassign all accounts from this folder
    final accounts = await getAccounts();
    final updatedAccounts = accounts.map((a) {
      if (a.folderId == id) {
        return a.copyWith(clearFolderId: true);
      }
      return a;
    }).toList();
    await saveAccounts(updatedAccounts);

    // Then delete the folder
    final folders = await getFolders();
    folders.removeWhere((f) => f.id == id);
    await saveFolders(folders);
  }

  // ============ Utility ============

  /// Clears all data - use with caution!
  Future<void> clearAll() async {
    await _storage.delete(key: _accountsKey);
    await _storage.delete(key: _foldersKey);
  }
}
