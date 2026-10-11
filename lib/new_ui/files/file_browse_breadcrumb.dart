import 'package:dsm_helper/new_ui/files/file_browse_path.dart';
import 'package:flutter/material.dart';

/// A compact list of route-verified ancestors, never inferred from a path.
class FileBrowseBreadcrumb extends StatelessWidget {
  const FileBrowseBreadcrumb({
    super.key,
    required this.ancestors,
    required this.onNavigate,
  });

  final List<FileBrowseAncestor> ancestors;
  final ValueChanged<FileBrowseAncestor> onNavigate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var index = 0; index < ancestors.length; index++) ...[
              if (index > 0)
                Icon(Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              TextButton(
                key: Key('file-browse-crumb:${ancestors[index].path ?? 'root'}'),
                onPressed: index == ancestors.length - 1
                    ? null
                    : () => onNavigate(ancestors[index]),
                child: Text(
                  ancestors[index].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
