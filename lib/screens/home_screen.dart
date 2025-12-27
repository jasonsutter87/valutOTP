import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/selected_folder_provider.dart';
import '../widgets/account_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/folder_chip.dart';
import 'add_account_screen.dart';
import 'export_screen.dart';
import 'folder_management_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedAccountIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedAccountIds.clear();
      }
    });
  }

  void _toggleAccountSelection(String accountId) {
    setState(() {
      if (_selectedAccountIds.contains(accountId)) {
        _selectedAccountIds.remove(accountId);
        if (_selectedAccountIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAccountIds.add(accountId);
      }
    });
  }

  void _selectAll(List<Account> accounts) {
    setState(() {
      _selectedAccountIds.addAll(accounts.map((a) => a.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final selectedFolderId = ref.watch(selectedFolderProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedAccountIds.length} selected')
            : const Text('VaultOTP'),
        centerTitle: true,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode)
            accountsAsync.when(
              data: (accounts) {
                final filteredAccounts = selectedFolderId == null
                    ? accounts
                    : accounts.where((a) => a.folderId == selectedFolderId).toList();
                return IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => _selectAll(filteredAccounts),
                  tooltip: 'Select All',
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'folders':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FolderManagementScreen(),
                      ),
                    );
                    break;
                  case 'export':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportScreen(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'folders',
                  child: ListTile(
                    leading: Icon(Icons.folder_outlined),
                    title: Text('Manage Folders'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.qr_code),
                    title: Text('Export Accounts'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Folder tabs
          foldersAsync.when(
            data: (folders) => _buildFolderTabs(context, ref, folders, selectedFolderId),
            loading: () => const SizedBox(height: 56),
            error: (_, __) => const SizedBox(height: 56),
          ),

          // Account list
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                final filteredAccounts = selectedFolderId == null
                    ? accounts
                    : accounts.where((a) => a.folderId == selectedFolderId).toList();

                if (accounts.isEmpty) {
                  return EmptyState(
                    title: 'No accounts yet',
                    subtitle: 'Add your first account by scanning a QR code or entering details manually.',
                    icon: Icons.security,
                    buttonText: 'Add Account',
                    onButtonPressed: () => _navigateToAddAccount(context),
                  );
                }

                if (filteredAccounts.isEmpty) {
                  return EmptyState(
                    title: 'No accounts in this folder',
                    subtitle: 'Move accounts here or add new ones.',
                    icon: Icons.folder_open,
                  );
                }

                return _buildAccountList(context, ref, filteredAccounts);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _showBulkMoveDialog(context, ref),
              icon: const Icon(Icons.drive_file_move),
              label: const Text('Move to folder'),
            )
          : FloatingActionButton(
              onPressed: () => _navigateToAddAccount(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildFolderTabs(
    BuildContext context,
    WidgetRef ref,
    List folders,
    String? selectedFolderId,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" tab
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FolderChip(
              label: 'All',
              isSelected: selectedFolderId == null,
              onTap: () {
                ref.read(selectedFolderProvider.notifier).select(null);
              },
            ),
          ),
          // Folder tabs
          ...folders.map((folder) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FolderChip(
                  label: folder.name,
                  isSelected: selectedFolderId == folder.id,
                  onTap: () {
                    ref.read(selectedFolderProvider.notifier).select(folder.id);
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAccountList(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        final isSelected = _selectedAccountIds.contains(account.id);

        return Stack(
          children: [
            AccountTile(
              account: account,
              onTap: _isSelectionMode
                  ? () => _toggleAccountSelection(account.id)
                  : null,
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedAccountIds.add(account.id);
                  });
                } else {
                  _showAccountOptions(context, ref, account);
                }
              },
            ),
            if (_isSelectionMode)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleAccountSelection(account.id),
                    shape: const CircleBorder(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _navigateToAddAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAccountScreen(),
      ),
    );
  }

  void _showAccountOptions(BuildContext context, WidgetRef ref, Account account) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Move to folder'),
              onTap: () {
                Navigator.pop(context);
                _showMoveToFolderDialog(context, ref, account);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, account);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveToFolderDialog(BuildContext context, WidgetRef ref, Account account) {
    final folders = ref.read(foldersProvider).value ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('No folder'),
              selected: account.folderId == null,
              onTap: () {
                ref.read(accountsProvider.notifier).moveToFolder(account.id, null);
                Navigator.pop(context);
              },
            ),
            ...folders.map((folder) => ListTile(
                  title: Text(folder.name),
                  selected: account.folderId == folder.id,
                  onTap: () {
                    ref.read(accountsProvider.notifier).moveToFolder(account.id, folder.id);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showBulkMoveDialog(BuildContext context, WidgetRef ref) {
    final folders = ref.read(foldersProvider).value ?? [];
    final count = _selectedAccountIds.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move $count account${count == 1 ? '' : 's'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('No folder'),
              onTap: () async {
                for (final id in _selectedAccountIds) {
                  await ref.read(accountsProvider.notifier).moveToFolder(id, null);
                }
                if (mounted) {
                  Navigator.pop(context);
                  _toggleSelectionMode();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Moved $count account${count == 1 ? '' : 's'}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ...folders.map((folder) => ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder.name),
                  onTap: () async {
                    for (final id in _selectedAccountIds) {
                      await ref.read(accountsProvider.notifier).moveToFolder(id, folder.id);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      _toggleSelectionMode();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Moved $count account${count == 1 ? '' : 's'} to ${folder.name}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Are you sure you want to delete "${account.displayName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(accountsProvider.notifier).deleteAccount(account.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
