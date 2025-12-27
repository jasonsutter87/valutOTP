import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected folder.
/// null = "All" (show all accounts)
/// String = specific folder ID
final selectedFolderProvider = NotifierProvider<SelectedFolderNotifier, String?>(
  SelectedFolderNotifier.new,
);

class SelectedFolderNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? folderId) {
    state = folderId;
  }
}
