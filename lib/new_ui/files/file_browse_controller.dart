import 'package:dio/dio.dart';
import 'package:dsm_helper/apis/dsm_api/dsm_exception.dart';
import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:dsm_helper/new_ui/files/file_browse_page_model.dart';
import 'package:dsm_helper/new_ui/files/file_browse_state.dart';
import 'package:dsm_helper/pages/file/enums/sort_enums.dart';
import 'package:flutter/foundation.dart';

export 'file_browse_state.dart' show FileBrowsePhase;

/// Owns one directory route. The tab Navigator, not this object, owns routes.
class FileBrowseController extends ChangeNotifier {
  FileBrowseController({
    required FileBrowseDataSource dataSource,
    required String contextId,
    required String? path,
    SortByEnum sortBy = SortByEnum.name,
    SortDirectionEnum sortDirection = SortDirectionEnum.ASC,
    VoidCallback? onReauthNeeded,
  })  : _source = dataSource,
        _contextId = contextId,
        _path = path,
        _sortBy = sortBy,
        _sortDirection = sortDirection,
        _onReauthNeeded = onReauthNeeded;

  static const int _pageSize = 100;

  final FileBrowseDataSource _source;
  final String _contextId;
  final String? _path;
  final VoidCallback? _onReauthNeeded;
  SortByEnum _sortBy;
  SortDirectionEnum _sortDirection;

  FileBrowsePhase _phase = FileBrowsePhase.initial;
  FileBrowseState _working = FileBrowseState(
    items: <FileItem>[], nextOffset: 0, isComplete: false, total: null,
  );
  FileBrowseState? _completed;
  bool _showCompleted = false;
  Future<void>? _pending;
  Object? _error;
  int _generation = 0;
  bool _disposed = false;
  bool _reauthSignalled = false;

  FileBrowsePhase get phase => _phase;
  String get contextId => _contextId;
  String? get path => _path;
  List<FileItem> get visibleItems =>
      (_showCompleted ? _completed : null)?.items ?? _working.items;
  bool get hasMore => !_working.isComplete;
  int? get total =>
      (_showCompleted ? _completed : null)?.total ?? _working.total;
  Object? get error => _error;
  bool get isComplete => _working.isComplete;

  Future<void> loadInitial() {
    if (_disposed) return Future<void>.value();
    return _restart();
  }

  Future<void> refresh() {
    if (_disposed) return Future<void>.value();
    return _restart();
  }

  Future<void> changeSort(SortByEnum by, SortDirectionEnum direction) {
    if (_disposed) return Future<void>.value();
    if (_sortBy == by && _sortDirection == direction) {
      return Future<void>.value();
    }
    _sortBy = by;
    _sortDirection = direction;
    return _restart();
  }

  Future<void> _restart() {
    _generation++;
    _pending = null; // Old futures cannot publish into this generation.
    _working = FileBrowseState(
      items: <FileItem>[], nextOffset: 0, isComplete: false, total: null,
    );
    _showCompleted = _completed != null;
    _error = null;
    _phase = _showCompleted ? FileBrowsePhase.refreshing : FileBrowsePhase.loading;
    notifyListeners();
    return _requestPage();
  }

  Future<void> loadNext() {
    if (_disposed) return Future<void>.value();
    if (_pending != null) return _pending!;
    if (_working.isComplete) return Future<void>.value();
    if (_phase == FileBrowsePhase.initial) return loadInitial();
    return _requestPage();
  }

  Future<void> _requestPage() {
    if (_disposed || _working.isComplete) return Future<void>.value();
    if (_pending != null) return _pending!;
    final generation = _generation;
    final request = FileBrowseRequest(
      path: _path,
      offset: _working.nextOffset,
      limit: _pageSize,
      sortBy: _sortBy.name,
      sortDirection: _sortDirection.name,
    );
    final task = _fetch(request, generation);
    _pending = task;
    task.whenComplete(() {
      if (identical(_pending, task)) _pending = null;
    });
    return task;
  }

  Future<void> _fetch(FileBrowseRequest request, int generation) async {
    try {
      final page = await _source.loadPage(request);
      if (!_isActive(generation)) return;
      _accept(page, request);
    } catch (exception) {
      if (!_isActive(generation)) return;
      _fail(exception);
    }
  }

  bool _isActive(int generation) => !_disposed && generation == _generation;

  void _accept(FileBrowsePage page, FileBrowseRequest request) {
    if (page.items.length > request.limit) {
      _fail(const FileBrowseDataException('File Station page exceeds requested limit'));
      return;
    }
    final previous = _working;
    final nextOffset = request.offset + page.items.length;
    final total = page.total ?? previous.total;
    // A total cannot change mid-generation or contradict received positions.
    if ((previous.total != null &&
            page.total != null && page.total != previous.total) ||
        (total != null && (total < nextOffset ||
            total < previous.items.length)) ||
        (page.items.isEmpty && total != null && nextOffset < total)) {
      _fail(const FileBrowseDataException('Inconsistent File Station page total'));
      return;
    }

    final seen = <String>{};
    for (final item in previous.items) {
      final path = item.path;
      if (path != null && path.isNotEmpty) seen.add(path);
    }
    final merged = <FileItem>[...previous.items];
    int newPaths = 0;
    for (final item in page.items) {
      final path = item.path;
      if (path == null || path.isEmpty) {
        // Keep an unreadable item visible; do not invent an identity for it.
        merged.add(item);
      } else if (seen.add(path)) {
        merged.add(item);
        newPaths++;
      }
    }
    final full = page.items.length >= request.limit;
    if (full && newPaths == 0) {
      _fail(const FileBrowseDataException('File Station page did not advance'));
      return;
    }

    // A known total cannot be proven complete by a short/duplicated page.
    // An unknown total, including a final empty page, can end on a short page.
    final inconsistentCompletion = total != null &&
        ((!full && nextOffset < total) ||
            (nextOffset >= total && merged.length < total));
    final isComplete = !inconsistentCompletion &&
        ((total != null && nextOffset >= total) || !full);
    _working = FileBrowseState(
      items: merged,
      nextOffset: nextOffset,
      isComplete: isComplete,
      total: total,
    );
    if (inconsistentCompletion) {
      _fail(const FileBrowseDataException('Incomplete File Station page'),
        incomplete: true);
      return;
    }
    _error = null;
    if (isComplete) {
      _completed = _working;
      _showCompleted = false;
      _phase = FileBrowsePhase.valid;
    } else {
      _phase = _showCompleted
          ? FileBrowsePhase.refreshing
          : FileBrowsePhase.valid;
    }
    notifyListeners();
  }

  void _fail(Object exception, {bool incomplete = false}) {
    _error = exception;
    if (exception is DsmException && exception.code == 119) {
      _phase = FileBrowsePhase.reauthNeeded;
      if (!_reauthSignalled) {
        _reauthSignalled = true;
        _onReauthNeeded?.call();
      }
    } else if (_showCompleted) {
      _phase = FileBrowsePhase.stale;
    } else if (incomplete || _working.items.isNotEmpty) {
      _phase = FileBrowsePhase.partial;
    } else if (exception is DioException) {
      _phase = FileBrowsePhase.offline;
    } else {
      _phase = FileBrowsePhase.unavailable;
    }
    notifyListeners();
  }

  /// Invalidate requests when pushing a child, preserving a completed parent.
  void onLeaveDirectory() {
    if (_disposed) return;
    _generation++;
    _pending = null;
    if (_completed != null) {
      _working = _completed!;
      _showCompleted = false;
      _phase = FileBrowsePhase.valid;
      _error = null;
    } else if (_working.items.isNotEmpty) {
      _phase = FileBrowsePhase.partial;
    } else {
      _phase = FileBrowsePhase.initial;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    _disposed = true;
    _pending = null;
    super.dispose();
  }
}
