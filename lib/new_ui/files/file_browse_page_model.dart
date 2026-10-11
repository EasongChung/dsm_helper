import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';

/// A structurally invalid browse request or response, not a DSM/API failure.
class FileBrowseDataException implements Exception {
  const FileBrowseDataException(this.message);

  final String message;

  @override
  String toString() => 'FileBrowseDataException: $message';
}

/// A null path means the File Station share root, not a filesystem path.
class FileBrowseRequest {
  const FileBrowseRequest({
    required this.path,
    required this.offset,
    this.limit = 100,
    required this.sortBy,
    required this.sortDirection,
  });

  final String? path;
  final int offset;
  final int limit;
  final String sortBy;
  final String sortDirection;
}

/// One validated server page. Paging and deduplication belong to Batch 2.
class FileBrowsePage {
  const FileBrowsePage({
    required this.path,
    required this.offset,
    required this.limit,
    required this.items,
    required this.total,
  });

  final String? path;
  final int offset;
  final int limit;
  final List<FileItem> items;
  final int? total;
}
