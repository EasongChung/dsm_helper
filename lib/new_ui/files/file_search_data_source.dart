import 'package:dsm_helper/apis/api.dart';
import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';

typedef FileSearchEntry = Future<DsmResponse<dynamic>> Function(
  String api,
  String method, {
  required int version,
  required Map<String, dynamic> data,
});

class FileSearchDataException implements Exception {
  const FileSearchDataException(this.message);
  final String message;

  @override
  String toString() => 'FileSearchDataException: $message';
}

class FileSearchStart {
  const FileSearchStart(this.taskId);
  final String taskId;
}

class FileSearchPage {
  const FileSearchPage({
    required this.offset,
    required this.items,
    required this.finished,
    this.total,
  });

  final int offset;
  final List<FileItem> items;
  final bool finished;
  final int? total;
}

/// Route-scoped Task 7B search transport boundary.
///
/// The callable surface is established before behavior-level RED tests so
/// failures prove missing Search protocol behavior rather than missing imports.
class FileSearchDataSource {
  const FileSearchDataSource({
    required this.contextId,
    required this.isContextCurrent,
    required this.entry,
  });

  final String contextId;
  final bool Function() isContextCurrent;
  final FileSearchEntry entry;

  Future<FileSearchStart> startSearch({
    required String folderPath,
    required String pattern,
    bool recursive = true,
    bool searchContent = false,
  }) {
    throw UnimplementedError('Task 7B B2 Search/start is not implemented');
  }

  Future<FileSearchPage> loadPage({
    required String taskId,
    required int offset,
    required int limit,
  }) {
    throw UnimplementedError('Task 7B B2 Search/list is not implemented');
  }
}
