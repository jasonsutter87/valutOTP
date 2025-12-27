import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder.dart';
import '../providers/folders_provider.dart';

class FolderManagementScreen extends ConsumerWidget {
  const FolderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Folders'),
      ),
      body: foldersAsync.when(
        data: (allFolders) {
          if (allFolders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No folders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create folders to organize your accounts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Get root folders and sort them
          final rootFolders = allFolders.where((f) => f.isRoot).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rootFolders.length,
            itemBuilder: (context, index) {
              final folder = rootFolders[index];
              final subfolders = allFolders.where((f) => f.parentId == folder.id).toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

              return Column(
                children: [
                  // Parent folder
                  _FolderCard(
                    folder: folder,
                    isSubfolder: false,
                    hasSubfolders: subfolders.isNotEmpty,
                    onEdit: () => _showEditDialog(context, ref, folder),
                    onDelete: () => _confirmDelete(context, ref, folder, subfolders.length),
                    onAddSubfolder: () => _showAddSubfolderDialog(context, ref, folder),
                  ),
                  // Subfolders
                  ...subfolders.map((sub) => _FolderCard(
                        folder: sub,
                        isSubfolder: true,
                        hasSubfolders: false,
                        onEdit: () => _showEditDialog(context, ref, sub),
                        onDelete: () => _confirmDelete(context, ref, sub, 0),
                        onAddSubfolder: null, // Can't add subfolder to a subfolder
                      )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            hintText: 'e.g., Work, Personal',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(foldersProvider.notifier).addFolder(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddSubfolderDialog(BuildContext context, WidgetRef ref, Folder parent) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Subfolder in "${parent.name}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subfolder name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(foldersProvider.notifier).addFolderWithParent(name, parent.id);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Folder folder) {
    final controller = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder.isSubfolder ? 'Rename Subfolder' : 'Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(foldersProvider.notifier)
                    .updateFolder(folder.copyWith(name: name));
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Folder folder, int subfolderCount) {
    final hasSubfolders = subfolderCount > 0;
    final message = hasSubfolders
        ? 'Delete "${folder.name}" and its $subfolderCount subfolder${subfolderCount == 1 ? '' : 's'}? Accounts will be moved to "All".'
        : 'Delete "${folder.name}"? Accounts in this folder will be moved to "All".';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(foldersProvider.notifier).deleteFolder(folder.id);
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

class _FolderCard extends StatelessWidget {
  final Folder folder;
  final bool isSubfolder;
  final bool hasSubfolders;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAddSubfolder;

  const _FolderCard({
    required this.folder,
    required this.isSubfolder,
    required this.hasSubfolders,
    required this.onEdit,
    required this.onDelete,
    this.onAddSubfolder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        left: isSubfolder ? 24 : 0,
        bottom: 8,
      ),
      child: ListTile(
        leading: Icon(
          isSubfolder ? Icons.subdirectory_arrow_right : Icons.folder,
          color: isSubfolder ? Colors.grey : null,
        ),
        title: Text(folder.name),
        subtitle: hasSubfolders
            ? const Text('Has subfolders', style: TextStyle(fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onAddSubfolder != null)
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'Add subfolder',
                onPressed: onAddSubfolder,
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
