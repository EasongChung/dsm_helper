import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:flutter/material.dart';

/// A read-only File Station entry. Only a verified folder path can navigate.
class FileBrowseRow extends StatelessWidget {
  const FileBrowseRow({
    super.key,
    required this.item,
    required this.grid,
    required this.onOpenFolder,
  });

  final FileItem item;
  final bool grid;
  final ValueChanged<FileItem> onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final folder = item.isdir == true;
    final navigable = folder && item.path != null && item.path!.isNotEmpty;
    final label = item.name?.isNotEmpty == true ? item.name! : '未命名项目';
    final icon = folder ? Icons.folder_outlined : Icons.insert_drive_file_outlined;
    final scheme = Theme.of(context).colorScheme;
    final size = item.additional?.size;
    final modified = item.additional?.time?.mtime;
    final metadata = <String>[
      if (size != null && !folder) '$size B',
      if (modified != null) '修改于 $modified',
    ].join(' · ');

    if (grid) {
      return InkWell(
        onTap: navigable ? () => onOpenFolder(item) : null,
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
      );
    }

    return ConstrainedBox(
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
        onTap: navigable ? () => onOpenFolder(item) : null,
      ),
    );
  }
}
