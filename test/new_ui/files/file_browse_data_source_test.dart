import 'package:dio/dio.dart';
import 'package:dsm_helper/apis/api.dart';
import 'package:dsm_helper/apis/dsm_api/dsm_api.dart';
import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:dsm_helper/new_ui/files/file_browse_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingDsmApi extends DsmApi {
  _RecordingDsmApi() : super(baseUrl: 'https://example.invalid');

  String? lastApi;
  String? lastMethod;
  int? lastVersion;
  Map<String, dynamic>? lastData;

  @override
  Future<DsmResponse> entry<T>(
    String api,
    String method, {
    bool post = true,
    dynamic data,
    String? path,
    int? version,
    Map<String, dynamic>? parameters,
    Options? options,
    T Function(dynamic)? parser,
  }) async {
    lastApi = api;
    lastMethod = method;
    lastVersion = version;
    lastData = Map<String, dynamic>.from(data as Map);
    return DsmResponse(
      success: true,
      data: FileStationList(files: <FileItem>[], offset: 0, total: 0),
    );
  }
}

void main() {
  late DsmApi originalApi;
  late _RecordingDsmApi recorder;

  setUp(() {
    originalApi = Api.dsm;
    recorder = _RecordingDsmApi();
    Api.dsm = recorder;
  });

  tearDown(() {
    Api.dsm = originalApi;
  });

  test('share root keeps legacy method, default 0/100 and quoted sort', () async {
    await FileStationList.shareList();
    expect(recorder.lastApi, 'SYNO.FileStation.List');
    expect(recorder.lastMethod, '"list_share"');
    expect(recorder.lastVersion, 2);
    expect(recorder.lastData, <String, dynamic>{
      'offset': 0,
      'limit': 100,
      'sort_by': '"name"',
      'sort_direction': '"asc"',
      'additional': '["perm","time","size"]',
    });
  });

  test('folder defaults preserve path, filetype and additional fields', () async {
    const path = '/share/space and 汉字';
    await FileStationList.fileList(path: path);
    expect(recorder.lastApi, 'SYNO.FileStation.List');
    expect(recorder.lastMethod, '"list"');
    expect(recorder.lastVersion, 2);
    expect(recorder.lastData, <String, dynamic>{
      'offset': 0,
      'limit': 100,
      'sort_by': '"name"',
      'sort_direction': '"asc"',
      'folder_path': path,
      'filetype': '"all"',
      'additional': '["real_path","size","owner","time","perm","type","mount_point_type","description","indexed"]',
    });
  });

  test('share page forwards offset and exact uppercase sort strings', () async {
    await FileStationList.shareList(
      offset: 100,
      limit: 100,
      sortBy: 'mtime',
      sortDirection: 'DESC',
    );
    expect(recorder.lastApi, 'SYNO.FileStation.List');
    expect(recorder.lastMethod, '"list_share"');
    expect(recorder.lastVersion, 2);
    expect(recorder.lastData, <String, dynamic>{
      'offset': 100,
      'limit': 100,
      'sort_by': '"mtime"',
      'sort_direction': '"DESC"',
      'additional': '["perm","time","size"]',
    });
  });

  test('folder page forwards offset and exact virtual path unchanged', () async {
    const path = 'scheme://server/含 空格';
    await FileStationList.fileList(
      path: path,
      offset: 100,
      limit: 100,
      sortBy: 'size',
      sortDirection: 'ASC',
    );
    expect(recorder.lastApi, 'SYNO.FileStation.List');
    expect(recorder.lastMethod, '"list"');
    expect(recorder.lastVersion, 2);
    expect(recorder.lastData, <String, dynamic>{
      'offset': 100,
      'limit': 100,
      'sort_by': '"size"',
      'sort_direction': '"ASC"',
      'folder_path': path,
      'filetype': '"all"',
      'additional': '["real_path","size","owner","time","perm","type","mount_point_type","description","indexed"]',
    });
  });

  test('injected loaders receive exact root and Unicode folder request fields', () async {
    final calls = <String>[];
    final source = FileBrowseDataSource(
      loadShares: ({required offset, required limit, required sortBy, required sortDirection}) async {
        calls.add('root:$offset:$limit:$sortBy:$sortDirection');
        return FileStationList.fromJson({'shares': [], 'offset': offset, 'total': 0});
      },
      loadFolder: ({required path, required offset, required limit, required sortBy, required sortDirection}) async {
        calls.add('$path:$offset:$limit:$sortBy:$sortDirection');
        return FileStationList.fromJson({'files': [], 'offset': offset, 'total': 0});
      },
    );
    final root = await source.loadPage(const FileBrowseRequest(
      path: null, offset: 100, sortBy: 'mtime', sortDirection: 'DESC'));
    expect(root.items, isEmpty);
    expect(root.offset, 100);
    final folder = await source.loadPage(const FileBrowseRequest(
      path: 'scheme://server/汉字 空格', offset: 0, limit: 50,
      sortBy: 'name', sortDirection: 'ASC'));
    expect(folder.path, 'scheme://server/汉字 空格');
    expect(calls, ['root:100:100:mtime:DESC',
      'scheme://server/汉字 空格:0:50:name:ASC']);
  });

  test('production adapter retains FileStationList root/folder protocol', () async {
    final source = FileBrowseDataSource.production();
    await source.loadPage(const FileBrowseRequest(
      path: null, offset: 0, sortBy: 'name', sortDirection: 'ASC'));
    expect(recorder.lastApi, 'SYNO.FileStation.List');
    expect(recorder.lastMethod, '"list_share"');
    expect(recorder.lastData!['sort_direction'], '"ASC"');
    await source.loadPage(const FileBrowseRequest(
      path: '/share/space and 汉字', offset: 0, sortBy: 'size', sortDirection: 'DESC'));
    expect(recorder.lastMethod, '"list"');
    expect(recorder.lastData!['folder_path'], '/share/space and 汉字');
    expect(recorder.lastData!['sort_by'], '"size"');
  });

  test('119 and other DSM exceptions and Dio timeout preserve identity', () async {
    for (final failure in <Object>[
      const DsmException(119), const DsmException(403),
      DioException(requestOptions: RequestOptions(path: '/webapi/entry.cgi'),
        type: DioExceptionType.connectionTimeout),
    ]) {
      final source = FileBrowseDataSource(
        loadShares: ({required offset, required limit, required sortBy, required sortDirection}) async => throw failure,
        loadFolder: ({required path, required offset, required limit, required sortBy, required sortDirection}) async => throw failure,
      );
      for (final path in <String?>[null, '/share/汉字']) {
        await expectLater(source.loadPage(FileBrowseRequest(
          path: path, offset: 0, sortBy: 'name', sortDirection: 'ASC')),
          throwsA(same(failure)));
      }
    }
  });

}
