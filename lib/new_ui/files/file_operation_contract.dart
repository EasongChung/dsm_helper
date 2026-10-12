import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';

/// File operations are planned only; this module has no UI callers in B1.
enum FileOperationAction {
  rename, createFolder, delete, addFavorite, removeFavorite, shareLink, copy, move,
}

enum FileOperationEligibility { allowed, requiresServerCheck, denied }

class FileOperationTarget {
  const FileOperationTarget({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.canWrite,
    required this.canDelete,
  });

  final String path;
  final String? name;
  final bool isDirectory;
  final bool? canWrite;
  final bool? canDelete;
}

class FileOperationSelection {
  const FileOperationSelection._({
    required this.contextId,
    required this.folderPath,
    required this.isComplete,
    required this.targets,
  });

  final String contextId;
  final String? folderPath;
  final bool isComplete;
  final List<FileOperationTarget> targets;

  factory FileOperationSelection.capture({
    required String contextId,
    required String? folderPath,
    required bool isComplete,
    required Iterable<FileItem> loadedItems,
    required Set<String> selectedPaths,
  }) {
    throw UnimplementedError('T7B-OPS-01 target snapshot');
  }

  FileOperationEligibility eligibility(FileOperationAction action) {
    throw UnimplementedError('T7B-OPS-03 eligibility');
  }
}
