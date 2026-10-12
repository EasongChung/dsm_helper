import 'package:flutter/material.dart';

/// Only browse selection controls: no file mutations or deferred actions.
class FileBrowseSelectionBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FileBrowseSelectionBar({
    super.key,
    required this.selectedCount,
    required this.isComplete,
    required this.onExit,
    required this.onSelectLoaded,
  });

  final int selectedCount;
  final bool isComplete;
  final VoidCallback onExit;
  final VoidCallback onSelectLoaded;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        leading: IconButton(
          key: const Key('file-browse-selection-exit'),
          tooltip: '退出选择',
          icon: const Icon(Icons.close),
          onPressed: onExit,
        ),
        title: Text(
          '已选择 $selectedCount 项',
          key: const Key('file-browse-selection-count'),
        ),
        actions: [
          TextButton(
            key: const Key('file-browse-select-loaded'),
            onPressed: onSelectLoaded,
            child: Text(isComplete ? '全选' : '已加载项全选'),
          ),
        ],
      );
}
