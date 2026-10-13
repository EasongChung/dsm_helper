import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_search_data_source.dart';
import 'package:flutter/foundation.dart';

enum FileSearchPhase {
  idle,
  starting,
  searching,
  partial,
  complete,
  empty,
  incomplete,
  offline,
  unavailable,
  reauthNeeded,
}

typedef FileSearchWait = Future<void> Function(Duration delay);

/// Route-scoped Search controller seam for Task 7B Batch 2.
///
/// Step 2.3 establishes behavior under RED tests before this seam is implemented.
class FileSearchController extends ChangeNotifier {
  FileSearchController({
    required FileSearchDataSource dataSource,
    required String contextId,
    required String folderPath,
    VoidCallback? onReauthNeeded,
    FileSearchWait? wait,
    int pageSize = 100,
    int maxPollAttempts = 5,
  })  : _source = dataSource,
        _contextId = contextId,
        _folderPath = folderPath,
        _onReauthNeeded = onReauthNeeded,
        _wait = wait ?? Future<void>.delayed,
        _pageSize = pageSize,
        _maxPollAttempts = maxPollAttempts;

  final FileSearchDataSource _source;
  final String _contextId;
  final String _folderPath;
  final VoidCallback? _onReauthNeeded;
  final FileSearchWait _wait;
  final int _pageSize;
  final int _maxPollAttempts;

  FileSearchPhase get phase => FileSearchPhase.idle;
  String get contextId => _contextId;
  String get folderPath => _folderPath;
  String get pattern => '';
  String? get taskId => null;
  List<FileItem> get items => const <FileItem>[];
  Object? get error => null;
  bool get isComplete => false;

  Future<void> search(
    String pattern, {
    bool recursive = true,
    bool searchContent = false,
  }) async {
    throw UnimplementedError('Task 7B B2 search controller is not implemented');
  }

  Future<void> retry() async {
    throw UnimplementedError('Task 7B B2 search retry is not implemented');
  }

  void cancelLocal() {
    throw UnimplementedError('Task 7B B2 local search cancel is not implemented');
  }
}
