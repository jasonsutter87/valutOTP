import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../models/folder.dart';
import '../providers/accounts_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/selected_folder_provider.dart';
import '../widgets/account_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/folder_chip.dart';
import '../widgets/upgrade_modal.dart';
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

  Future<void> _requirePremium(VoidCallback onPremium) async {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      onPremium();
    } else {
      final result = await UpgradeModal.show(context);
      if (result == true) {
        onPremium();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final navStateAsync = ref.watch(selectedFolderProvider);
    final isPremium = ref.watch(isPremiumProvider);

    // Extract current folder ID and navigation state
    final navState = navStateAsync.value ?? const FolderNavigationState();
    final selectedFolderId = navState.currentFolderId;
    final canGoBack = navState.canGoBack;

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
            Builder(
              builder: (context) {
                final filteredAccounts = ref.watch(accountsByFolderProvider(selectedFolderId));
                return IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => _selectAll(filteredAccounts),
                  tooltip: 'Select All',
                );
              },
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'folders':
                    _requirePremium(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FolderManagementScreen(),
                        ),
                      );
                    });
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
                PopupMenuItem(
                  value: 'folders',
                  child: ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('Manage Folders'),
                    trailing: isPremium
                        ? null
                        : Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
          // Folder tabs - only show if premium
          if (isPremium)
            foldersAsync.when(
              data: (folders) => _buildFolderTabs(
                context,
                ref,
                folders,
                navState,
              ),
              loading: () => const SizedBox(height: 56),
              error: (_, __) => const SizedBox(height: 56),
            )
          else
            _buildUpgradeBanner(context),

          // Account list
          Expanded(
            child: accountsAsync.when(
              data: (accounts) {
                // For free users, show all accounts (no folder filtering)
                // For premium, use the folder provider which includes subfolders
                final filteredAccounts = !isPremium
                    ? accounts
                    : ref.watch(accountsByFolderProvider(selectedFolderId));

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
                    title: canGoBack ? 'No accounts in this folder' : 'No accounts',
                    subtitle: canGoBack
                        ? 'Move accounts here or add new ones.'
                        : 'Add your first account.',
                    icon: Icons.folder_open,
                  );
                }

                return _buildAccountList(context, ref, filteredAccounts, isPremium);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _requirePremium(() => _showBulkMoveDialog(context, ref)),
              icon: const Icon(Icons.drive_file_move),
              label: const Text('Move to folder'),
            )
          : FloatingActionButton(
              onPressed: () => _navigateToAddAccount(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildUpgradeBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => UpgradeModal.show(context),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_special,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Folders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Organize your codes into folders',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTabs(
    BuildContext context,
    WidgetRef ref,
    List<Folder> allFolders,
    FolderNavigationState navState,
  ) {
    final currentFolderId = navState.currentFolderId;
    final canGoBack = navState.canGoBack;

    // Determine which folders to show at current level
    List<Folder> foldersToShow;
    Folder? currentFolder;

    if (currentFolderId == null) {
      // At root: show root folders
      foldersToShow = allFolders.where((f) => f.isRoot).toList();
    } else {
      // Inside a folder: show its subfolders
      currentFolder = allFolders.firstWhere(
        (f) => f.id == currentFolderId,
        orElse: () => Folder(id: '', name: '', sortOrder: 0, createdAt: DateTime.now()),
      );
      foldersToShow = allFolders.where((f) => f.parentId == currentFolderId).toList();
    }

    // Sort by sortOrder
    foldersToShow.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Back button (when inside a folder)
          if (canGoBack) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.arrow_back, size: 18),
                label: Text(currentFolder?.name ?? 'Back'),
                onPressed: () {
                  ref.read(selectedFolderProvider.notifier).goBack();
                },
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            // Divider
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 1,
                height: 24,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ] else ...[
            // "All" tab (only at root level)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FolderChip(
                label: 'All',
                isSelected: currentFolderId == null,
                onTap: () {
                  ref.read(selectedFolderProvider.notifier).goToRoot();
                },
              ),
            ),
          ],

          // Folder/subfolder tabs
          ...foldersToShow.map((folder) {
            final hasSubfolders = allFolders.any((f) => f.parentId == folder.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FolderChip(
                label: folder.name,
                isSelected: false, // Never "selected" since clicking enters the folder
                hasSubfolders: hasSubfolders,
                onTap: () {
                  ref.read(selectedFolderProvider.notifier).enterFolder(folder.id);
                },
              ),
            );
          }),

          // Show message if no subfolders
          if (canGoBack && foldersToShow.isEmpty)
            Center(
              child: Text(
                'No subfolders',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountList(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
    bool isPremium,
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
                  _showAccountOptions(context, ref, account, isPremium);
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

  void _showAccountOptions(BuildContext context, WidgetRef ref, Account account, bool isPremium) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Move to folder'),
              trailing: isPremium
                  ? null
                  : Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              onTap: () {
                Navigator.pop(context);
                _requirePremium(() => _showMoveToFolderDialog(context, ref, account));
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
    final allFolders = ref.read(foldersProvider).value ?? [];
    final rootFolders = allFolders.where((f) => f.isRoot).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to folder'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('No folder'),
                selected: account.folderId == null,
                onTap: () {
                  ref.read(accountsProvider.notifier).moveToFolder(account.id, null);
                  Navigator.pop(context);
                },
              ),
              ...rootFolders.expand((folder) {
                final subfolders = allFolders.where((f) => f.parentId == folder.id).toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                return [
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    selected: account.folderId == folder.id,
                    onTap: () {
                      ref.read(accountsProvider.notifier).moveToFolder(account.id, folder.id);
                      Navigator.pop(context);
                    },
                  ),
                  ...subfolders.map((sub) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 40),
                        leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                        title: Text(sub.name),
                        selected: account.folderId == sub.id,
                        onTap: () {
                          ref.read(accountsProvider.notifier).moveToFolder(account.id, sub.id);
                          Navigator.pop(context);
                        },
                      )),
                ];
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkMoveDialog(BuildContext context, WidgetRef ref) {
    final allFolders = ref.read(foldersProvider).value ?? [];
    final rootFolders = allFolders.where((f) => f.isRoot).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final count = _selectedAccountIds.length;

    void moveToFolder(String? folderId, String? folderName) async {
      for (final id in _selectedAccountIds) {
        await ref.read(accountsProvider.notifier).moveToFolder(id, folderId);
      }
      if (mounted) {
        Navigator.pop(context);
        _toggleSelectionMode();
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              folderName != null
                  ? 'Moved $count account${count == 1 ? '' : 's'} to $folderName'
                  : 'Moved $count account${count == 1 ? '' : 's'}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move $count account${count == 1 ? '' : 's'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('No folder'),
                onTap: () => moveToFolder(null, null),
              ),
              ...rootFolders.expand((folder) {
                final subfolders = allFolders.where((f) => f.parentId == folder.id).toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                return [
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    onTap: () => moveToFolder(folder.id, folder.name),
                  ),
                  ...subfolders.map((sub) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 40),
                        leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                        title: Text(sub.name),
                        onTap: () => moveToFolder(sub.id, '${folder.name}/${sub.name}'),
                      )),
                ];
              }),
            ],
          ),
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
