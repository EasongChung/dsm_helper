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
}
