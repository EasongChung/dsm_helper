import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:flutter/material.dart';

/// A read-only File Station entry. Only a verified folder path can navigate.
class FileBrowseRow extends StatelessWidget {
  const FileBrowseRow({
    super.key,
    required this.item,
    required this.grid,
    required this.onOpenFolder,
    this.selectionMode = false,
    this.selected = false,
    this.selectable = false,
    this.onSelect,
    this.onToggle,
  });

  final FileItem item;
  final bool grid;
  final ValueChanged<FileItem> onOpenFolder;
  final bool selectionMode;
  final bool selected;
  final bool selectable;
  final ValueChanged<FileItem>? onSelect;
  final ValueChanged<FileItem>? onToggle;

  @override
  Widget build(BuildContext context) {
    final folder = item.isdir == true;
    final navigable = folder && item.path != null && item.path!.isNotEmpty;
    final label = item.name?.isNotEmpty == true ? item.name! : '未命名项目';
    final icon = folder ? Icons.folder_outlined : Icons.insert_drive_file_outlined;
    final scheme = Theme.of(context).colorScheme;
    final size = item.additional?.size;
    final modified = item.additional?.time?.mtime;
    final canSelect = selectable &&
        item.path != null && item.path!.isNotEmpty;
    final VoidCallback? onTap = selectionMode
        ? (canSelect ? () => onToggle?.call(item) : null)
        : (navigable ? () => onOpenFolder(item) : null);
    final metadata = <String>[
      if (size != null && !folder) '$size B',
      if (modified != null) '修改于 $modified',
    ].join(' · ');

    if (grid) {
      return _withSwipe(
        canSelect: canSelect,
        child: InkWell(
        onTap: onTap,
        splashColor: scheme.secondaryContainer,
        overlayColor: selected
            ? WidgetStatePropertyAll<Color?>(scheme.secondaryContainer)
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: scheme.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
              if (metadata.isNotEmpty)
                Text(metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ),
      );
    }

    return _withSwipe(
      canSelect: canSelect,
      child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
        subtitle: metadata.isEmpty
            ? null
            : Text(metadata, maxLines: 1,
                overflow: TextOverflow.ellipsis),
        onTap: onTap,
        selected: selected,
        selectedTileColor: scheme.secondaryContainer,
      ),
    ),
    );
  }

  /// Horizontal row swipe only; vertical list scrolling and root navigation
  /// keep their existing gestures and no row is ever dismissed.
  Widget _withSwipe({required bool canSelect, required Widget child}) {
    if (!canSelect || selectionMode || onSelect == null) return child;
    double movement = 0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => movement = 0,
      onHorizontalDragUpdate: (details) => movement += details.delta.dx,
      onHorizontalDragEnd: (_) {
        if (movement.abs() >= 48) onSelect?.call(item);
      },
      child: child,
    );
  }
}
