import 'package:dio/dio.dart';
import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:dsm_helper/new_ui/files/file_browse_page.dart';
import 'package:dsm_helper/new_ui/theme/new_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp_util/sp_util.dart';

FileBrowseDataSource testSource(
  Future<FileStationList> Function(String? path, int offset) fetch,
  List<String> requests,
) => FileBrowseDataSource(
      loadShares: ({
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) {
        requests.add('root:$offset:$limit:$sortBy:$sortDirection');
        return fetch(null, offset);
      },
      loadFolder: ({
        required path,
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) {
        requests.add('$path:$offset:$limit:$sortBy:$sortDirection');
        return fetch(path, offset);
      },
    );

FileItem browseItem(String name, String? path, {bool directory = false}) =>
    FileItem(name: name, path: path, isdir: directory);

Widget browser(
  FileBrowseDataSource source, {
  String? path,
  ThemeData? theme,
  double scale = 1,
  VoidCallback? onReauthNeeded,
}) => MaterialApp(
      theme: theme ?? NewUiTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: FileBrowsePage(
          contextId: 'NAS-A/account',
          dataSource: source,
          path: path,
          onOpenNotifications: () {},
          onReauthNeeded: onReauthNeeded,
        ),
      ),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SpUtil.getInstance();
  });

  testWidgets('root loads shares, handles nullable metadata and navigable rows',
      (tester) async {
    final requests = <String>[];
    final source = testSource((path, offset) async => FileStationList(
      files: [
        browseItem('影音与中文 电影资料夹', '/volume share/影音', directory: true),
        browseItem('没有路径的资料', null),
      ],
      offset: offset,
      total: 2,
    ), requests);
    await tester.pumpWidget(browser(source));
    await tester.pump();
    expect(requests, ['root:0:100:name:ASC']);
    expect(find.text('影音与中文 电影资料夹'), findsOneWidget);
    expect(find.text('没有路径的资料'), findsOneWidget);
    expect(find.byKey(const Key('file-browse-view-toggle')), findsOneWidget);
    expect(find.byKey(const Key('new-ui-notifications')), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('list/grid render same paths in light/dark with scaled Unicode labels',
      (tester) async {
    final requests = <String>[];
    final source = testSource((path, offset) async => FileStationList(
      files: [
        browseItem('很长很长的中文与 Unicode 文件名称 2026.flac', '/share/2026.flac'),
        browseItem('目录', '/share/目录', directory: true),
      ],
      offset: offset,
      total: 2,
    ), requests);
    await tester.pumpWidget(browser(source, path: '/share',
        theme: NewUiTheme.dark(), scale: 1.6));
    await tester.pump();
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('很长很长的中文与 Unicode 文件名称 2026.flac'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    await tester.tap(find.byKey(const Key('file-browse-view-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('很长很长的中文与 Unicode 文件名称 2026.flac'),
        findsOneWidget);
    expect(requests, hasLength(1)); // View changes do not refetch or sort.
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('valid empty differs from first-request offline failure and retry',
      (tester) async {
    final requests = <String>[];
    var unavailable = true;
    final source = testSource((path, offset) async {
      if (unavailable) {
        throw DioException(
          requestOptions: RequestOptions(path: '/file-station'),
          type: DioExceptionType.connectionError,
        );
      }
      return FileStationList(files: [], offset: offset, total: 0);
    }, requests);
    await tester.pumpWidget(browser(source, path: '/share'));
    await tester.pump();
    expect(find.text('无网络连接'), findsWidgets);
    expect(find.byKey(const Key('file-browse-retry')), findsOneWidget);
    expect(find.text('暂无文件'), findsNothing);
    unavailable = false;
    await tester.tap(find.byKey(const Key('file-browse-retry')));
    await tester.pump();
    expect(find.text('暂无文件'), findsOneWidget);
    expect(requests, hasLength(2));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('incremental paging waits for scroll and requests next offset once',
      (tester) async {
    final requests = <String>[];
    final source = testSource((path, offset) async {
      final count = offset == 0 ? 100 : 1;
      return FileStationList(
        files: List<FileItem>.generate(count, (i) =>
          browseItem('item-${offset + i}', '/share/${offset + i}')),
        offset: offset,
        total: 101,
      );
    }, requests);
    await tester.pumpWidget(browser(source, path: '/share'));
    await tester.pump();
    expect(requests, ['/share:0:100:name:ASC']);
    expect(find.byKey(const Key('file-browse-load-more')), findsWidgets);
    await tester.drag(find.byKey(const Key('file-browse-scroll')),
        const Offset(0, -6000));
    await tester.pump();
    await tester.pump();
    expect(requests, ['/share:0:100:name:ASC', '/share:100:100:name:ASC']);
    expect(find.text('item-100'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
