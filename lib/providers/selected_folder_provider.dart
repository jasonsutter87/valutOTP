import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';

/// Navigation state for folder drill-down.
class FolderNavigationState {
  /// Stack of folder IDs representing the navigation path.
  /// Empty = at root ("All"), [id1] = in folder id1, [id1, id2] = in subfolder id2
  final List<String> path;

  const FolderNavigationState({this.path = const []});

  /// Current folder ID (null = root/All)
  String? get currentFolderId => path.isEmpty ? null : path.last;

  /// Whether we can go back (are we inside a folder?)
  bool get canGoBack => path.isNotEmpty;

  /// Depth in the folder hierarchy (0 = root)
  int get depth => path.length;

  FolderNavigationState copyWith({List<String>? path}) {
    return FolderNavigationState(path: path ?? this.path);
  }
}

/// Tracks the currently selected folder with navigation stack.
final selectedFolderProvider =
    AsyncNotifierProvider<SelectedFolderNotifier, FolderNavigationState>(
  SelectedFolderNotifier.new,
);

class SelectedFolderNotifier extends AsyncNotifier<FolderNavigationState> {
  @override
  Future<FolderNavigationState> build() async {
    // Load last folder path from storage
    final storage = ref.read(storageServiceProvider);
    final savedPath = await storage.getLastFolderPath();
    return FolderNavigationState(path: savedPath);
  }

  /// Enter a folder (drill down)
  Future<void> enterFolder(String folderId) async {
    final current = state.value ?? const FolderNavigationState();
    final newPath = [...current.path, folderId];
    state = AsyncData(current.copyWith(path: newPath));
    await _persistPath(newPath);
  }

  /// Go back to parent folder
  Future<void> goBack() async {
    final current = state.value ?? const FolderNavigationState();
    if (current.path.isEmpty) return;

    final newPath = current.path.sublist(0, current.path.length - 1);
    state = AsyncData(current.copyWith(path: newPath));
    await _persistPath(newPath);
  }

  /// Go back to root ("All")
  Future<void> goToRoot() async {
    state = const AsyncData(FolderNavigationState());
    await _persistPath([]);
  }

  /// Select a specific folder directly (for tab selection at current level)
  Future<void> selectAtCurrentLevel(String? folderId) async {
    final current = state.value ?? const FolderNavigationState();

    if (folderId == null) {
      // Going to root
      await goToRoot();
    } else if (current.path.isEmpty) {
      // At root, entering a folder
      await enterFolder(folderId);
    } else {
      // Inside a folder, switching to sibling or subfolder at current level
      // Replace the current folder with the new one
      final parentPath = current.path.sublist(0, current.path.length - 1);
      final newPath = [...parentPath, folderId];
      state = AsyncData(current.copyWith(path: newPath));
      await _persistPath(newPath);
    }
  }

  Future<void> _persistPath(List<String> path) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveLastFolderPath(path);
  }
}

/// Convenience provider for current folder ID (for filtering)
final currentFolderIdProvider = Provider<String?>((ref) {
  final navState = ref.watch(selectedFolderProvider);
  return navState.value?.currentFolderId;
});

/// Convenience provider for checking if we can go back
final canGoBackProvider = Provider<bool>((ref) {
  final navState = ref.watch(selectedFolderProvider);
  return navState.value?.canGoBack ?? false;
});
