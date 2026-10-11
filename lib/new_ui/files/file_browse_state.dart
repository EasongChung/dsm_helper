import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';

/// The visible status of a single directory route, not a global DSM session.
enum FileBrowsePhase {
  initial,
  loading,
  valid,
  refreshing,
  stale,
  partial,
  offline,
  unavailable,
  reauthNeeded,
}

/// An immutable, single-generation directory listing snapshot.
class FileBrowseState {
  FileBrowseState({
    required List<FileItem> items,
    required this.nextOffset,
    required this.isComplete,
    required this.total,
  }) : items = List<FileItem>.unmodifiable(items);

  final List<FileItem> items;
  final int nextOffset;
  final bool isComplete;
  final int? total;
}
