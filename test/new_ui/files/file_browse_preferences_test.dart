import 'package:dsm_helper/new_ui/files/file_browse_preferences.dart';
import 'package:dsm_helper/pages/file/enums/list_type_enums.dart';
import 'package:dsm_helper/pages/file/enums/sort_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy defaults are list/name/ASC and no new keys are consulted', () {
    final keys = <String>[];
    final store = SpUtilFileBrowsePreferencesStore(
      read: (key) { keys.add(key); return null; },
      write: (key, value) async => true,
    );
    final prefs = store.load();
    expect(prefs.view, ListType.list);
    expect(prefs.sortBy, SortByEnum.name);
    expect(prefs.direction, SortDirectionEnum.ASC);
    expect(keys, ['file_list_type', 'file_sort_by', 'file_sort_direction']);
  });

  test('reads each old key independently and falls back per corrupt value', () {
    final values = <String, String>{
      'file_list_type': 'grid',
      'file_sort_by': 'mtime',
      'file_sort_direction': 'DESC',
    };
    final store = SpUtilFileBrowsePreferencesStore(
      read: (key) => values[key],
      write: (key, value) async { values[key] = value; return true; },
    );
    var prefs = store.load();
    expect(prefs.view, ListType.grid);
    expect(prefs.sortBy, SortByEnum.mtime);
    expect(prefs.direction, SortDirectionEnum.DESC);

    values['file_list_type'] = 'invalid';
    prefs = store.load();
    expect(prefs.view, ListType.list);
    expect(prefs.sortBy, SortByEnum.mtime);
    expect(prefs.direction, SortDirectionEnum.DESC);

    values['file_list_type'] = 'grid';
    values['file_sort_by'] = 'unknown';
    values['file_sort_direction'] = 'asc';
    prefs = store.load();
    expect(prefs.view, ListType.grid);
    expect(prefs.sortBy, SortByEnum.name);
    expect(prefs.direction, SortDirectionEnum.ASC);
  });

  test('sort uses original enum wire values and never changes view', () async {
    final writes = <String, String>{};
    final values = <String, String>{'file_list_type': 'grid'};
    final store = SpUtilFileBrowsePreferencesStore(
      read: (key) => values[key],
      write: (key, value) async {
        writes[key] = value;
        values[key] = value;
        return true;
      },
    );
    await store.saveSort(SortByEnum.size, SortDirectionEnum.DESC);
    expect(writes, {
      'file_sort_by': 'size',
      'file_sort_direction': 'DESC',
    });
    var prefs = store.load();
    expect(prefs.view, ListType.grid);
    expect(prefs.sortBy.name, 'size');
    expect(prefs.direction.name, 'DESC');

    writes.clear();
    await store.saveView(ListType.list);
    expect(writes, {'file_list_type': 'list'});
    prefs = store.load();
    expect(prefs.view, ListType.list);
    expect(prefs.sortBy, SortByEnum.size);
    expect(prefs.direction, SortDirectionEnum.DESC);
  });

  test('failed persistence is not silently presented as success', () async {
    final store = SpUtilFileBrowsePreferencesStore(
      read: (_) => null,
      write: (_, __) async => false,
    );
    await expectLater(store.saveView(ListType.grid), throwsStateError);
    await expectLater(
      store.saveSort(SortByEnum.name, SortDirectionEnum.ASC),
      throwsStateError,
    );
  });
}
