import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_browse_page_model.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

FileBrowseDataSource source(FileStationList result) => FileBrowseDataSource(
  loadShares: ({required offset, required limit, required sortBy, required sortDirection}) async => result,
  loadFolder: ({required path, required offset, required limit, required sortBy, required sortDirection}) async => result,
);
const root = FileBrowseRequest(path: null, offset: 0, sortBy: 'name', sortDirection: 'ASC');
void main() {
  test('request and page preserve exact URI/path and typed fields', () {
    const request = FileBrowseRequest(path: 'scheme://host/汉字', offset: 100,
      limit: 25, sortBy: 'user', sortDirection: 'DESC');
    expect(request.path, 'scheme://host/汉字');
    expect(request.offset, 100);
    expect(request.limit, 25);
    expect(request.sortBy, 'user');
    expect(request.sortDirection, 'DESC');
    final item = FileItem(path: '/share/space and 汉字');
    final page = FileBrowsePage(path: '/share/space and 汉字', offset: 0,
      limit: 100, items: [item], total: 1);
    expect(identical(page.items.single, item), isTrue);
  });

  test('valid empty shares and files are distinct from missing arrays', () async {
    for (final key in <String>['shares', 'files']) {
      final page = await source(FileStationList.fromJson({
        key: <dynamic>[], 'offset': 0, 'total': 0,
      })).loadPage(root);
      expect(page.items, isEmpty);
      expect(page.total, 0);
    }
    for (final json in <Map<String, dynamic>>[
      {'offset': 0, 'total': 0},
      {'files': null, 'offset': 0, 'total': 0},
    ]) {
      await expectLater(source(FileStationList.fromJson(json)).loadPage(root),
        throwsA(isA<FileBrowseDataException>()));
    }
  });

  test('invalid inputs and non-integer, negative or mismatched response metadata fail', () async {
    final empty = FileStationList(files: [], offset: 0, total: 0);
    for (final request in <FileBrowseRequest>[
      const FileBrowseRequest(path: null, offset: -1, sortBy: 'name', sortDirection: 'ASC'),
      const FileBrowseRequest(path: null, offset: 0, limit: 0, sortBy: 'name', sortDirection: 'ASC'),
      const FileBrowseRequest(path: '', offset: 0, sortBy: 'name', sortDirection: 'ASC'),
    ]) {
      await expectLater(source(empty).loadPage(request), throwsA(isA<FileBrowseDataException>()));
    }
    for (final result in <FileStationList>[
      FileStationList(files: [], offset: -1, total: 0),
      FileStationList(files: [], offset: 0.5, total: 0),
      FileStationList(files: [], offset: 1, total: 0),
      FileStationList(files: [], offset: 0, total: -1),
      FileStationList(files: [], offset: 0, total: 0.5),
    ]) {
      await expectLater(source(result).loadPage(root), throwsA(isA<FileBrowseDataException>()));
    }
  });

  test('absent response offset safely falls back to requested offset', () async {
    final page = await source(FileStationList(files: [], offset: null, total: null))
      .loadPage(const FileBrowseRequest(path: null, offset: 100,
        sortBy: 'name', sortDirection: 'ASC'));
    expect(page.offset, 100);
    expect(page.total, isNull);
  });

  test('distinct equal names and nullable metadata/path remain readable', () async {
    final page = await source(FileStationList.fromJson({
      'files': [
        {'name': '同名', 'path': '/share/甲', 'isdir': false, 'additional': null},
        {'name': '同名', 'path': '/share/乙', 'isdir': false},
        {'name': '无路径', 'path': null, 'isdir': false},
      ], 'offset': 0, 'total': 3,
    })).loadPage(root);
    expect(page.items.map((e) => e.path).toList(), ['/share/甲', '/share/乙', null]);
    expect(page.items.every((e) => e.additional == null), isTrue);
  });

  test('malformed row maps to typed data failure rather than crashing browse', () async {
    final bad = FileBrowseDataSource(
      loadShares: ({required offset, required limit, required sortBy, required sortDirection}) async =>
        FileStationList.fromJson({'files': [null], 'offset': 0, 'total': 1}),
      loadFolder: ({required path, required offset, required limit, required sortBy, required sortDirection}) async =>
        throw StateError('unused'),
    );
    await expectLater(bad.loadPage(root), throwsA(isA<FileBrowseDataException>()));
  });
}
