import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dsm_helper/apis/dsm_api/dsm_exception.dart';
import 'package:dsm_helper/pages/file/enums/sort_enums.dart';

import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_browse_controller.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:dsm_helper/new_ui/files/file_browse_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

List<FileItem> items(int start, int length, {String prefix = '/share'}) =>
    List<FileItem>.generate(length, (i) => FileItem(
      path: '$prefix/${start + i}',
      name: 'file-${start + i}',
      isdir: false,
    ));

FileBrowsePage page(FileBrowseRequest request, List<FileItem> files, {int? total}) =>
    FileBrowsePage(
      path: request.path,
      offset: request.offset,
      limit: request.limit,
      items: files,
      total: total,
    );

FileBrowseDataSource source(
  Future<FileBrowsePage> Function(FileBrowseRequest) responder,
  List<FileBrowseRequest> calls,
) => FileBrowseDataSource(
  loadShares: ({required offset, required limit, required sortBy, required sortDirection}) async {
    final request = FileBrowseRequest(path: null, offset: offset,
      limit: limit, sortBy: sortBy, sortDirection: sortDirection);
    calls.add(request);
    final response = await responder(request);
    return FileStationList(files: response.items,
      offset: response.offset, total: response.total);
  },
  loadFolder: ({required path, required offset, required limit, required sortBy, required sortDirection}) async {
    final request = FileBrowseRequest(path: path, offset: offset,
      limit: limit, sortBy: sortBy, sortDirection: sortDirection);
    calls.add(request);
    final response = await responder(request);
    return FileStationList(files: response.items,
      offset: response.offset, total: response.total);
  },
);

void main() {
  test('root is null, valid empty is complete, and only the first page auto-loads', () async {
    final calls = <FileBrowseRequest>[];
    final controller = FileBrowseController(
      dataSource: source((r) async => page(r, [], total: 0), calls),
      contextId: 'NAS-A/user', path: null,
    );
    expect(controller.phase, FileBrowsePhase.initial);
    await controller.loadInitial();
    expect(calls, hasLength(1));
    expect(calls.single.path, isNull);
    expect(calls.single.offset, 0);
    expect(calls.single.limit, 100);
    expect(controller.phase, FileBrowsePhase.valid);
    expect(controller.visibleItems, isEmpty);
    expect(controller.total, 0);
    expect(controller.isComplete, isTrue);
    expect(controller.hasMore, isFalse);
    controller.dispose();
  });

  test('250 records require one explicit page request at a time, no 100 cap', () async {
    final calls = <FileBrowseRequest>[];
    final controller = FileBrowseController(
      dataSource: source((r) async =>
        page(r, items(r.offset, r.offset == 200 ? 50 : 100), total: 250), calls),
      contextId: 'NAS-A/user', path: '/share/汉字 and space',
    );
    await controller.loadInitial();
    expect(calls.map((c) => c.offset), [0]);
    expect(calls.single.path, '/share/汉字 and space');
    expect(controller.visibleItems, hasLength(100));
    expect(controller.hasMore, isTrue);
    expect(controller.isComplete, isFalse);
    await controller.loadNext();
    expect(calls.map((c) => c.offset), [0, 100]);
    expect(controller.visibleItems, hasLength(200));
    await controller.loadNext();
    expect(calls.map((c) => c.offset), [0, 100, 200]);
    expect(controller.visibleItems, hasLength(250));
    expect(controller.isComplete, isTrue);
    expect(controller.hasMore, isFalse);
    await controller.loadNext();
    expect(calls, hasLength(3));
    controller.dispose();
  });

  test('exact 100, 101, and unknown-total short page terminate correctly', () async {
    for (final count in [100, 101]) {
      final calls = <FileBrowseRequest>[];
      final controller = FileBrowseController(
        dataSource: source((r) async => page(r,
          items(r.offset, count - r.offset > 100 ? 100 : count - r.offset),
          total: count), calls),
        contextId: 'NAS-A/user', path: '/share',
      );
      await controller.loadInitial();
      expect(controller.isComplete, count == 100);
      if (count == 101) await controller.loadNext();
      expect(controller.visibleItems, hasLength(count));
      expect(controller.isComplete, isTrue);
      expect(calls.map((r) => r.offset), count == 100 ? [0] : [0, 100]);
      controller.dispose();
    }
    final unknownCalls = <FileBrowseRequest>[];
    final unknown = FileBrowseController(
      dataSource: source((r) async => page(
        r, items(r.offset, r.offset == 200 ? 37 : 100)), unknownCalls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await unknown.loadInitial();
    expect(unknown.total, isNull);
    expect(unknown.hasMore, isTrue);
    await unknown.loadNext();
    await unknown.loadNext();
    expect(unknown.visibleItems, hasLength(237));
    expect(unknown.isComplete, isTrue);
    expect(unknownCalls.map((r) => r.offset), [0, 100, 200]);
    unknown.dispose();
  });

  test('in-flight next page coalesces duplicate calls', () async {
    final calls = <FileBrowseRequest>[];
    final second = Completer<FileBrowsePage>();
    final controller = FileBrowseController(
      dataSource: source((r) => r.offset == 0
        ? Future.value(page(r, items(0, 100), total: 200))
        : second.future, calls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await controller.loadInitial();
    final first = controller.loadNext();
    final concurrent = controller.loadNext();
    expect(calls.map((r) => r.offset), [0, 100]);
    second.complete(page(calls.last, items(100, 100), total: 200));
    await Future.wait([first, concurrent]);
    expect(controller.visibleItems, hasLength(200));
    expect(controller.isComplete, isTrue);
    controller.dispose();
  });

  test('full repeated page is incomplete, not success or an endless fetch', () async {
    final calls = <FileBrowseRequest>[];
    final controller = FileBrowseController(
      dataSource: source((r) async => page(r, items(0, 100), total: 250), calls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await controller.loadInitial();
    await controller.loadNext();
    expect(controller.phase, FileBrowsePhase.partial);
    expect(controller.visibleItems, hasLength(100));
    expect(controller.visibleItems.map((r) => r.path).toSet(), hasLength(100));
    expect(controller.isComplete, isFalse);
    expect(controller.error, isNotNull);
    expect(calls.map((r) => r.offset), [0, 100]);
    controller.dispose();
  });

  test('conflicting totals cannot falsely complete listing', () async {
    final calls = <FileBrowseRequest>[];
    final controller = FileBrowseController(
      dataSource: source((r) async => page(
        r, items(r.offset, 100), total: r.offset == 0 ? 250 : 150), calls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await controller.loadInitial();
    await controller.loadNext();
    expect(controller.phase, FileBrowsePhase.partial);
    expect(controller.isComplete, isFalse);
    expect(controller.error, isNotNull);
    controller.dispose();
  });
  test('last completed snapshot survives failed multi-page refresh and is replaced only by complete V2', () async {
    final calls = <FileBrowseRequest>[];
    var revision = 1;
    var failSecondPage = false;
    final controller = FileBrowseController(
      dataSource: source((r) async {
        if (failSecondPage && r.offset == 100) {
          throw const DsmException(403);
        }
        return page(r,
          items(r.offset, r.offset == 0 ? 100 : 50,
            prefix: revision == 1 ? '/V1' : '/V2'),
          total: 150);
      }, calls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await controller.loadInitial();
    await controller.loadNext();
    expect(controller.visibleItems, hasLength(150));
    expect(controller.isComplete, isTrue);
    revision = 2;
    failSecondPage = true;
    await controller.refresh();
    expect(controller.phase, FileBrowsePhase.refreshing);
    expect(controller.visibleItems.map((e) => e.path).every((p) => p!.startsWith('/V1/')), isTrue);
    expect(controller.isComplete, isFalse);
    await controller.loadNext();
    expect(controller.phase, FileBrowsePhase.stale);
    expect(controller.error, isA<DsmException>());
    expect(controller.visibleItems, hasLength(150));
    expect(controller.visibleItems.every((e) => e.path!.startsWith('/V1/')), isTrue);
    failSecondPage = false;
    await controller.refresh();
    expect(controller.visibleItems.every((e) => e.path!.startsWith('/V1/')), isTrue);
    await controller.loadNext();
    expect(controller.isComplete, isTrue);
    expect(controller.phase, FileBrowsePhase.valid);
    expect(controller.visibleItems.every((e) => e.path!.startsWith('/V2/')), isTrue);
    controller.dispose();
  });

  test('initial offline, permission and auth-invalid are distinct from valid empty', () async {
    final failures = <Object>[
      DioException(requestOptions: RequestOptions(path: '/webapi/entry.cgi'),
        type: DioExceptionType.connectionTimeout),
      const DsmException(403),
      const DsmException(119),
    ];
    final phases = <FileBrowsePhase>[
      FileBrowsePhase.offline,
      FileBrowsePhase.unavailable,
      FileBrowsePhase.reauthNeeded,
    ];
    for (var i = 0; i < failures.length; i++) {
      var reauthCount = 0;
      final calls = <FileBrowseRequest>[];
      final failure = failures[i];
      final controller = FileBrowseController(
        dataSource: source((r) async => throw failure, calls),
        contextId: 'NAS-A/user', path: '/share',
        onReauthNeeded: () => reauthCount++,
      );
      await controller.loadInitial();
      expect(controller.phase, phases[i]);
      expect(controller.visibleItems, isEmpty);
      expect(controller.isComplete, isFalse);
      expect(controller.error, same(failure));
      await controller.refresh();
      expect(reauthCount, i == 2 ? 1 : 0);
      controller.dispose();
    }
  });

  test('late success and errors from an earlier sort generation cannot overwrite current sort', () async {
    for (final oldRequestFails in [false, true]) {
      final oldPage = Completer<FileBrowsePage>();
      final calls = <FileBrowseRequest>[];
      final controller = FileBrowseController(
        dataSource: source((r) => r.sortBy == 'name'
          ? oldPage.future
          : Future.value(page(r, items(0, 1, prefix: '/size'), total: 1)), calls),
        contextId: 'NAS-A/user', path: '/share',
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      final oldLoad = controller.loadInitial();
      await controller.changeSort(SortByEnum.size, SortDirectionEnum.DESC);
      expect(calls.map((r) => r.sortBy), ['name', 'size']);
      expect(calls.last.sortDirection, 'DESC');
      expect(controller.phase, FileBrowsePhase.valid);
      expect(controller.visibleItems.single.path, '/size/0');
      final beforeOldCompletion = notifications;
      if (oldRequestFails) {
        oldPage.completeError(const DsmException(403));
      } else {
        oldPage.complete(page(calls.first, items(0, 1, prefix: '/name'), total: 1));
      }
      await oldLoad;
      expect(controller.visibleItems.single.path, '/size/0');
      expect(controller.error, isNull);
      expect(notifications, beforeOldCompletion);
      controller.dispose();
    }
  });

  test('leaving a parent directory cancels late work while retaining its prior complete view', () async {
    final later = Completer<FileBrowsePage>();
    final calls = <FileBrowseRequest>[];
    var loadingRefresh = false;
    final parent = FileBrowseController(
      dataSource: source((r) => loadingRefresh
          ? later.future
          : Future.value(page(r, items(0, 1), total: 1)), calls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await parent.loadInitial();
    loadingRefresh = true;
    final pending = parent.refresh();
    parent.onLeaveDirectory();
    later.completeError(const DsmException(403));
    await pending;
    expect(parent.visibleItems.single.path, '/share/0');
    expect(parent.phase, FileBrowsePhase.valid);
    expect(parent.error, isNull);
    parent.dispose();
  });

  test('disposed NAS A cannot deliver late page or notify NAS B on the same path', () async {
    final lateA = Completer<FileBrowsePage>();
    final callsA = <FileBrowseRequest>[];
    final callsB = <FileBrowseRequest>[];
    final a = FileBrowseController(
      dataSource: source((r) => lateA.future, callsA),
      contextId: 'NAS-A/user', path: '/share',
    );
    final b = FileBrowseController(
      dataSource: source((r) async => page(r, items(0, 1, prefix: '/B'), total: 1), callsB),
      contextId: 'NAS-B/user', path: '/share',
    );
    var aNotifies = 0;
    a.addListener(() => aNotifies++);
    final pendingA = a.loadInitial();
    a.dispose();
    final afterDispose = aNotifies;
    await b.loadInitial();
    lateA.complete(page(callsA.first, items(0, 1, prefix: '/A'), total: 1));
    await pendingA;
    expect(aNotifies, afterDispose);
    expect(b.visibleItems.single.path, '/B/0');
    expect(b.contextId, 'NAS-B/user');
    b.dispose();
  });

  test('oversized response page is rejected, not accepted as valid completed data', () async {
    final calls = <FileBrowseRequest>[];
    final controller = FileBrowseController(
      dataSource: source((r) async => page(r, items(0, 101)), calls),
      contextId: 'NAS-A/user', path: '/share',
    );
    await controller.loadInitial();
    expect(controller.isComplete, isFalse);
    expect(controller.phase, FileBrowsePhase.unavailable);
    expect(controller.error, isNotNull);
    expect(controller.visibleItems, isEmpty);
    controller.dispose();
  });

}
