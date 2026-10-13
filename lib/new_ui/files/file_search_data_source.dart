import 'dart:convert';

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
  }) async {
    if (!isContextCurrent()) {
      throw const FileSearchDataException('Inactive DSM context');
    }
    if (folderPath.isEmpty || pattern.trim().isEmpty) {
      throw const FileSearchDataException('Invalid search request');
    }
    final res = await entry(
      'SYNO.FileStation.Search',
      '"start"',
      version: 2,
      data: {
        'folder_path': jsonEncode(<String>[folderPath]),
        'pattern': jsonEncode(pattern.trim()),
        'recursive': recursive,
        'search_content': searchContent,
        'search_type': '"simple"',
      },
    );
    final data = res.data;
    if (res.success != true || data is! Map || data['taskid'] is! String) {
      throw const FileSearchDataException('Missing search task id');
    }
    return FileSearchStart(data['taskid'] as String);
  }

  Future<FileSearchPage> loadPage({
    required String taskId,
    required int offset,
    required int limit,
  }) async {
    if (!isContextCurrent()) {
      throw const FileSearchDataException('Inactive DSM context');
    }
    if (taskId.isEmpty || offset < 0 || limit <= 0) {
      throw const FileSearchDataException('Invalid search page request');
    }
    final res = await entry(
      'SYNO.FileStation.Search',
      '"list"',
      version: 2,
      data: {
        'taskid': taskId,
        'offset': offset,
        'limit': limit,
        'filetype': 'all',
        'additional': jsonEncode(<String>[
          'real_path',
          'size',
          'owner',
          'time',
          'perm',
          'type',
        ]),
      },
    );
    final data = res.data;
    if (res.success != true || data is! Map || data['files'] is! List ||
        data['finished'] is! bool) {
      throw const FileSearchDataException('Malformed search result');
    }
    try {
      return FileSearchPage(
        offset: data['offset'] is int ? data['offset'] as int : offset,
        total: data['total'] is int ? data['total'] as int : null,
        finished: data['finished'] as bool,
        items: (data['files'] as List)
            .map((item) => FileItem.fromJson(item))
            .toList(),
      );
    } catch (error) {
      throw FileSearchDataException('Malformed search file: $error');
    }
  }
}
