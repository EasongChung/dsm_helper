/// Verified, route-owned File Station navigation identity.
/// [path] is the exact value returned by DSM, never inferred from [label].
class FileBrowseAncestor {
  const FileBrowseAncestor({required this.label, required this.path});

  final String label;
  final String? path;
}

/// Produce breadcrumb targets from routes actually visited.
///
/// This deliberately does not parse a filesystem path or a remote mount URI:
/// an intermediate component is not navigable unless its exact path was
/// previously established as a route by the caller.
List<FileBrowseAncestor> buildBrowseAncestors({
  required List<FileBrowseAncestor> visited,
  required FileBrowseAncestor current,
}) {
  final seen = <String?>{};
  final result = <FileBrowseAncestor>[];
  for (final ancestor in <FileBrowseAncestor>[...visited, current]) {
    if (seen.add(ancestor.path)) {
      result.add(ancestor);
    }
  }
  return List<FileBrowseAncestor>.unmodifiable(result);
}
