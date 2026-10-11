import 'package:dsm_helper/pages/file/enums/list_type_enums.dart';
import 'package:dsm_helper/pages/file/enums/sort_enums.dart';
import 'package:sp_util/sp_util.dart';

class FileBrowsePreferences {
  const FileBrowsePreferences({
    required this.view,
    required this.sortBy,
    required this.direction,
  });

  final ListType view;
  final SortByEnum sortBy;
  final SortDirectionEnum direction;
}

typedef FileBrowsePreferenceRead = String? Function(String key);
typedef FileBrowsePreferenceWrite = Future<bool> Function(
  String key,
  String value,
);

/// Uses the existing File Station preferences without another key namespace.
class SpUtilFileBrowsePreferencesStore {
  SpUtilFileBrowsePreferencesStore({
    FileBrowsePreferenceRead? read,
    FileBrowsePreferenceWrite? write,
  })  : _read = read ?? _readSpUtil,
        _write = write ?? _writeSpUtil;

  final FileBrowsePreferenceRead _read;
  final FileBrowsePreferenceWrite _write;

  static String? _readSpUtil(String key) => SpUtil.getString(key);

  static Future<bool> _writeSpUtil(String key, String value) async =>
      await SpUtil.putString(key, value) ?? false;

  FileBrowsePreferences load() => FileBrowsePreferences(
        view: ListType.fromValue(_read('file_list_type') ?? 'list'),
        sortBy: SortByEnum.fromValue(_read('file_sort_by') ?? 'name'),
        direction: SortDirectionEnum.fromValue(
          _read('file_sort_direction') ?? 'ASC',
        ),
      );

  Future<void> saveView(ListType view) async {
    if (!await _write('file_list_type', view.name)) {
      throw StateError('Failed to save File Station view preference');
    }
  }

  Future<void> saveSort(SortByEnum by, SortDirectionEnum direction) async {
    if (!await _write('file_sort_by', by.name) ||
        !await _write('file_sort_direction', direction.name)) {
      throw StateError('Failed to save File Station sort preference');
    }
  }
}
