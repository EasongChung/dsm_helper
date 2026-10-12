import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_browse_controller.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:dsm_helper/pages/file/enums/sort_enums.dart';
import 'package:flutter_test/flutter_test.dart';

FileItem file(String name, String? path, {bool folder = false}) =>
    FileItem(name: name, path: path, isdir: folder);

FileBrowseDataSource selectionSource(
  Future<FileStationList> Function(String? path, int offset, String sort) load,
) => FileBrowseDataSource(
      loadShares: ({
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) => load(null, offset, sortBy),
      loadFolder: ({
        required path,
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) => load(path, offset, sortBy),
    );

void main() {
  test('exact paths survive model replacement and sort; equal names differ',
      () async {
    final browse = FileBrowseController(
      contextId: 'NAS-A/user',
      path: '/share',
      dataSource: selectionSource((path, offset, sort) async =>
          FileStationList(
            files: sort == 'size'
                ? [
                    file('duplicate', '/share/C'),
                    file('duplicate', '/share/B'),
                    file('duplicate', '/share/A'),
                  ]
                : [
                    file('duplicate', '/share/A'),
                    file('duplicate', '/share/B'),
                    file('duplicate', '/share/C'),
                  ],
            offset: offset,
            total: 3,
          )),
    );
    await browse.loadInitial();
    // Dynamic only for the RED phase: the production selection API does not
    // exist at this commit. GREEN makes these calls statically typed.
    final dynamic selection = browse;
    selection.selectPath('/share/A');
    selection.selectPath('/share/C');
    expect(selection.isSelectionMode, isTrue);
    expect(selection.selectedPaths, <String>{'/share/A', '/share/C'});
    await browse.changeSort(SortByEnum.size, SortDirectionEnum.DESC);
    expect(selection.selectedPaths, <String>{'/share/A', '/share/C'});
    selection.togglePath('/share/B');
    expect(selection.selectedPaths,
        <String>{'/share/A', '/share/B', '/share/C'});
    selection.togglePath('/share/B');
    expect(selection.selectedPaths, <String>{'/share/A', '/share/C'});
    final outward = selection.selectedPaths as Set<String>;
    expect(() => outward.add('/share/unloaded'), throwsUnsupportedError);
    browse.dispose();
  });

  test('root and missing or unrelated paths cannot enter selection', () async {
    final data = selectionSource((path, offset, sort) async =>
        FileStationList(files: [
          file('share', '/share', folder: true),
          file('missing', null),
          file('empty', ''),
        ], offset: offset, total: 3));
    final root = FileBrowseController(
      contextId: 'NAS-A/user', path: null, dataSource: data);
    await root.loadInitial();
    final dynamic rootSelection = root;
    rootSelection.selectPath('/share');
    expect(rootSelection.isSelectionMode, isFalse);
    expect(rootSelection.selectedPaths, isEmpty);
    root.dispose();

    final folder = FileBrowseController(
      contextId: 'NAS-A/user', path: '/share', dataSource: data);
    await folder.loadInitial();
    final dynamic folderSelection = folder;
    folderSelection.selectPath('');
    folderSelection.selectPath('/outside');
    folderSelection.selectPath('/share');
    expect(folderSelection.selectedPaths, <String>{'/share'});
    folder.dispose();
  });

  test('only fully completed refresh prunes; incomplete and failed retain',
      () async {
    var revision = 0;
    var failSecond = false;
    final data = selectionSource((path, offset, sort) async {
      if (failSecond && offset == 100) throw StateError('page 2 unavailable');
      final entries = List<FileItem>.generate(150, (i) =>
          file('same-$i', revision == 2 ? '/share/new-$i' : '/share/$i'));
      return FileStationList(
        files: entries.skip(offset).take(100).toList(),
        offset: offset, total: 150);
    });
    final browse = FileBrowseController(
      contextId: 'NAS-A/user', path: '/share', dataSource: data);
    await browse.loadInitial();
    await browse.loadNext();
    final dynamic selection = browse;
    selection.selectPath('/share/0');
    selection.selectPath('/share/120');
    revision = 1;
    failSecond = true;
    await browse.refresh();
    expect(selection.selectedPaths, <String>{'/share/0', '/share/120'});
    await browse.loadNext();
    expect(browse.phase, FileBrowsePhase.stale);
    expect(selection.selectedPaths, <String>{'/share/0', '/share/120'});
    revision = 2;
    failSecond = false;
    await browse.refresh();
    expect(selection.selectedPaths, <String>{'/share/0', '/share/120'});
    await browse.loadNext();
    expect(browse.isComplete, isTrue);
    expect(selection.selectedPaths, isEmpty);
    expect(selection.isSelectionMode, isTrue); // Exit remains explicit.
    selection.clearSelection();
    expect(selection.isSelectionMode, isFalse);
    browse.dispose();
  });

  test('selection is route-and-context scoped; leaving directory clears',
      () async {
    final data = selectionSource((path, offset, sort) async =>
        FileStationList(
          files: [file('same', '/share/A', folder: true)],
          offset: offset, total: 1));
    final a = FileBrowseController(
      contextId: 'NAS-A/user', path: '/share', dataSource: data);
    final b = FileBrowseController(
      contextId: 'NAS-B/user', path: '/share', dataSource: data);
    await a.loadInitial();
    await b.loadInitial();
    final dynamic aSelection = a;
    final dynamic bSelection = b;
    aSelection.selectPath('/share/A');
    expect(bSelection.selectedPaths, isEmpty);
    a.onLeaveDirectory();
    expect(aSelection.isSelectionMode, isFalse);
    expect(aSelection.selectedPaths, isEmpty);
    expect(bSelection.selectedPaths, isEmpty);
    a.dispose();
    b.dispose();
  });

  test('250 selectable items plus null path select only loaded exact paths',
      () async {
    final requests = <int>[];
    final source = selectionSource((path, offset, sort) async {
      requests.add(offset);
      final count = offset == 200 ? 51 : 100;
      final entries = List<FileItem>.generate(count, (i) {
        final index = offset + i;
        return file('file-$index', index == 250 ? null : '/share/$index');
      });
      return FileStationList(files: entries, offset: offset, total: 251);
    });
    final browse = FileBrowseController(
      contextId: 'NAS-A/user', path: '/share', dataSource: source);
    await browse.loadInitial();
    expect(browse.isComplete, isFalse);
    expect(browse.visibleItems, hasLength(100));
    browse.selectLoaded();
    expect(browse.isSelectionMode, isTrue);
    expect(browse.selectedPaths, hasLength(100));
    await browse.loadNext();
    expect(browse.visibleItems, hasLength(200));
    expect(browse.selectedPaths, hasLength(100),
        reason: 'Unseen second-page paths must not be auto-selected');
    await browse.loadNext();
    expect(browse.isComplete, isTrue);
    expect(browse.visibleItems, hasLength(251));
    expect(browse.selectedPaths, hasLength(100));
    browse.selectLoaded();
    expect(browse.selectedPaths, hasLength(250));
    expect(browse.selectedPaths.contains('/share/249'), isTrue);
    expect(browse.selectedPaths.contains(''), isFalse);
    expect(requests, <int>[0, 100, 200]);
    browse.clearSelection();
    expect(browse.selectedPaths, isEmpty);
    expect(browse.isSelectionMode, isFalse);
    browse.dispose();
  });

  test('failed second sort page preserves selected paths from valid listing',
      () async {
    final requests = <String>[];
    final source = selectionSource((path, offset, sort) async {
      requests.add('$sort:$offset');
      if (sort == 'size' && offset == 100) {
        throw StateError('sort continuation failed');
      }
      final count = offset == 200 ? 50 : 100;
      return FileStationList(
        files: List<FileItem>.generate(count, (i) =>
            file('file-${offset + i}', '/share/${offset + i}')),
        offset: offset,
        total: 250,
      );
    });
    final browse = FileBrowseController(
      contextId: 'NAS-A/user', path: '/share', dataSource: source);
    await browse.loadInitial();
    await browse.loadNext();
    await browse.loadNext();
    expect(browse.isComplete, isTrue);
    browse.selectPath('/share/210');
    browse.selectLoaded();
    expect(browse.selectedPaths, hasLength(250));
    await browse.changeSort(SortByEnum.size, SortDirectionEnum.DESC);
    expect(browse.isComplete, isFalse);
    expect(browse.selectedPaths, hasLength(250));
    await browse.loadNext();
    expect(browse.phase, FileBrowsePhase.stale);
    expect(browse.selectedPaths, hasLength(250));
    expect(browse.visibleItems, hasLength(250));
    expect(requests, ['name:0', 'name:100', 'name:200',
      'size:0', 'size:100']);
    browse.dispose();
  });
}
