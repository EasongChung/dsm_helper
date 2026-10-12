import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dsm_helper/apis/dsm_api/dsm_exception.dart';
import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'package:dsm_helper/new_ui/app/new_ui_app_shell.dart';
import 'package:dsm_helper/new_ui/files/file_browse_data_source.dart';
import 'package:dsm_helper/new_ui/files/file_browse_page.dart';
import 'package:dsm_helper/new_ui/legacy/legacy_page_host.dart';
import 'package:dsm_helper/new_ui/theme/new_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sp_util/sp_util.dart';

Widget _legacy(String name) => Scaffold(
      appBar: AppBar(title: Text('legacy-$name')),
      body: Text('legacy-body-$name'),
    );

FileBrowseDataSource _source(List<String> requests) => FileBrowseDataSource(
      loadShares: ({
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) async {
        requests.add('shares:$offset');
        return FileStationList(
          files: [FileItem(name: '共享', path: '/share', isdir: true)],
          offset: offset, total: 1,
        );
      },
      loadFolder: ({
        required path,
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) async {
        requests.add('$path:$offset');
        final items = path == '/share'
            ? <FileItem>[
                FileItem(name: '子目录', path: '/share/sub', isdir: true),
                FileItem(name: 'track.flac', path: '/share/track.flac', isdir: false),
              ]
            : <FileItem>[FileItem(name: 'nested.txt', path: '$path/nested.txt')];
        return FileStationList(files: items, offset: offset, total: items.length);
      },
    );

List<NewUiAppDestination> _destinations(FileBrowseDataSource source) => [
      NewUiAppDestination.test(label: '概览', legacyBuilder: (_) => _legacy('overview')),
      NewUiAppDestination(
        label: '文件',
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder,
        legacyBuilder: (_) => _legacy('files'),
        browsePreviewBuilder: (
          _, {
          required VoidCallback onOpenNotifications,
          required String? connectionStatusText,
        }) => FileBrowsePage(
          contextId: 'NAS-A/user',
          dataSource: source,
          onOpenNotifications: onOpenNotifications,
          connectionStatusText: connectionStatusText,
        ),
      ),
      NewUiAppDestination.test(label: '应用', legacyBuilder: (_) => _legacy('apps')),
      NewUiAppDestination.test(label: '任务', legacyBuilder: (_) => _legacy('tasks')),
      NewUiAppDestination.test(label: '我的', legacyBuilder: (_) => _legacy('me')),
    ];

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SpUtil.getInstance();
  });

  testWidgets('only Files offers secondary preview; primary legacy remains normal',
      (tester) async {
    final requests = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: NewUiTheme.light(),
      home: NewUiAppShell(
        notificationBuilder: (_) => _legacy('notifications'),
        destinations: _destinations(_source(requests)),
      ),
    ));

    expect(find.byKey(const Key('file-browse-preview')), findsNothing);
    await tester.tap(find.text('任务').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('file-browse-preview')), findsNothing);

    await tester.tap(find.text('文件').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open-legacy-feature')), findsOneWidget);
    expect(find.byKey(const Key('file-browse-preview')), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(find.byKey(const Key('open-legacy-feature')));
    await tester.pumpAndSettle();
    expect(find.byType(LegacyPageHost), findsOneWidget);
    expect(find.text('legacy-files'), findsOneWidget);
    expect(find.byType(FileBrowsePage), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('file-browse-preview')), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(find.byKey(const Key('file-browse-preview')));
    await tester.pumpAndSettle();
    expect(find.byType(FileBrowsePage), findsOneWidget);
    expect(find.text('共享'), findsOneWidget);
    expect(requests, ['shares:0']);
    expect(find.byType(LegacyPageHost), findsNothing);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byKey(const Key('open-legacy-feature')), findsNothing);
    expect(find.byKey(const Key('file-browse-preview')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(FileBrowsePage), findsNothing);
    expect(find.byKey(const Key('open-legacy-feature')), findsOneWidget);
    expect(find.byKey(const Key('file-browse-preview')), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 35)));

  testWidgets('Files tab keeps nested preview and selection through tab change, resume, and theme',
      (tester) async {
    await SpUtil.putString('file_list_type', 'list');
    final calls = <String>[];
    final dark = ValueNotifier<bool>(false);
    addTearDown(dark.dispose);
    await tester.pumpWidget(ValueListenableBuilder<bool>(
      valueListenable: dark,
      builder: (_, isDark, __) => MaterialApp(
        theme: isDark ? NewUiTheme.dark() : NewUiTheme.light(),
        home: NewUiAppShell(
          notificationBuilder: (_) => _legacy('notifications'),
          destinations: _destinations(_source(calls)),
        ),
      ),
    ));
    await tester.tap(find.text('文件').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('file-browse-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共享'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('子目录'));
    await tester.pumpAndSettle();
    expect(find.text('nested.txt'), findsOneWidget);
    await tester.drag(find.text('nested.txt'), const Offset(180, 0));
    await tester.pump();
    expect(find.text('已选择 1 项'), findsOneWidget);

    await tester.tap(find.text('任务').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('文件').last);
    await tester.pumpAndSettle();
    expect(find.text('nested.txt'), findsOneWidget);
    expect(find.text('已选择 1 项'), findsOneWidget);
    dark.value = true;
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('nested.txt'))).brightness,
        Brightness.dark);
    expect(find.text('已选择 1 项'), findsOneWidget);
    await tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('nested.txt'), findsOneWidget);
    expect(find.text('已选择 1 项'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('nested.txt'), findsOneWidget);
    expect(find.text('已选择 1 项'), findsNothing);
    await tester.tap(find.byKey(const Key('new-ui-notifications')));
    await tester.pumpAndSettle();
    expect(find.byType(LegacyPageHost), findsOneWidget);
    expect(find.text('legacy-notifications'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('nested.txt'), findsOneWidget);
    expect(find.byType(FileBrowsePage), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
    expect(calls, ['shares:0', '/share:0', '/share/sub:0']);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('context remount destroys pending A directory and selection and starts B at Overview',
      (tester) async {
    await SpUtil.putString('file_list_type', 'list');
    final account = ValueNotifier<String>('A');
    final pendingA = Completer<FileStationList>();
    addTearDown(account.dispose);

    FileBrowseDataSource sourceFor(String id) => FileBrowseDataSource(
      loadShares: ({
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) async => FileStationList(
        files: [FileItem(name: 'share-$id', path: '/share', isdir: true)],
        offset: offset, total: 1,
      ),
      loadFolder: ({
        required path,
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) {
        if (id == 'A' && path == '/share/slow') return pendingA.future;
        final items = <FileItem>[
          FileItem(name: 'file-$id', path: '/share/file-$id'),
          if (id == 'A')
            FileItem(name: 'slow-directory', path: '/share/slow', isdir: true),
        ];
        return Future.value(FileStationList(
          files: items, offset: offset, total: items.length,
        ));
      },
    );

    await tester.pumpWidget(ValueListenableBuilder<String>(
      valueListenable: account,
      builder: (_, id, __) => MaterialApp(
        theme: NewUiTheme.light(),
        home: KeyedSubtree(
          key: ValueKey<String>(id),
          child: NewUiAppShell(
            notificationBuilder: (_) => _legacy('notifications'),
            destinations: [
              NewUiAppDestination.test(
                label: '概览', legacyBuilder: (_) => _legacy('overview')),
              NewUiAppDestination(
                label: '文件',
                icon: Icons.folder_outlined,
                selectedIcon: Icons.folder,
                legacyBuilder: (_) => _legacy('files'),
                browsePreviewBuilder: (
                  _, {
                  required VoidCallback onOpenNotifications,
                  required String? connectionStatusText,
                }) => FileBrowsePage(
                  contextId: id,
                  dataSource: sourceFor(id),
                  onOpenNotifications: onOpenNotifications,
                  connectionStatusText: connectionStatusText,
                ),
              ),
              for (final label in ['应用', '任务', '我的'])
                NewUiAppDestination.test(
                  label: label, legacyBuilder: (_) => _legacy(label)),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.text('文件').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('file-browse-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('share-A'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('file-A'), const Offset(180, 0));
    await tester.pump();
    expect(find.text('已选择 1 项'), findsOneWidget);

    account.value = 'B';
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
    await tester.tap(find.text('文件').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('file-browse-preview')), findsOneWidget);
    expect(find.text('已选择 1 项'), findsNothing);
    await tester.tap(find.byKey(const Key('file-browse-preview')));
    await tester.pumpAndSettle();
    expect(find.text('share-B'), findsOneWidget);
    expect(find.text('share-A'), findsNothing);
    await tester.tap(find.text('share-B'));
    await tester.pumpAndSettle();
    expect(find.text('file-B'), findsOneWidget);
    expect(find.text('file-A'), findsNothing);

    // A's old context owns no visible UI and cannot overwrite B.
    pendingA.complete(FileStationList(
      files: [FileItem(name: 'late-A', path: '/share/slow/late-A')],
      offset: 0, total: 1,
    ));
    await tester.pump();
    expect(find.text('late-A'), findsNothing);
    expect(find.text('file-B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 40)));

  testWidgets('offline refresh retains last-valid files and only DSM 119 raises reauth',
      (tester) async {
    await SpUtil.putString('file_list_type', 'list');
    var reads = 0;
    var reauth = 0;
    final source = FileBrowseDataSource(
      loadShares: ({
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) async => FileStationList(files: [], offset: offset, total: 0),
      loadFolder: ({
        required path,
        required offset,
        required limit,
        required sortBy,
        required sortDirection,
      }) async {
        reads++;
        if (reads == 1) {
          return FileStationList(
            files: [FileItem(name: 'retained.txt', path: '$path/retained.txt')],
            offset: offset, total: 1,
          );
        }
        if (reads == 2) {
          throw DioException(
            requestOptions: RequestOptions(path: '/webapi/entry.cgi'),
            type: DioExceptionType.connectionTimeout,
          );
        }
        throw const DsmException(119);
      },
    );

    await tester.pumpWidget(MaterialApp(
      theme: NewUiTheme.light(),
      home: FileBrowsePage(
        contextId: 'NAS-A/user',
        path: '/share',
        dataSource: source,
        onOpenNotifications: () {},
        onReauthNeeded: () => reauth++,
      ),
    ));
    await tester.pump();
    expect(find.text('retained.txt'), findsOneWidget);
    await tester.drag(find.byKey(const Key('file-browse-scroll')),
        const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.text('retained.txt'), findsOneWidget);
    expect(find.textContaining('刷新失败'), findsOneWidget);
    expect(reauth, 0);

    await tester.tap(find.byKey(const Key('file-browse-retry')));
    await tester.pump();
    expect(reads, 3);
    expect(find.text('retained.txt'), findsOneWidget);
    expect(find.text('需要重新登录'), findsOneWidget);
    expect(reauth, 1);
    await tester.tap(find.byKey(const Key('file-browse-retry')));
    await tester.pump();
    expect(reads, 4);
    expect(reauth, 1);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 35)));

  test('production seam retains Files legacy and existing external-intent destinations', () {
    final source = File('lib/new_ui/app/dsm_new_ui_shell.dart').readAsStringSync();
    final files = source.substring(
      source.indexOf("label: '文件',"),
      source.indexOf("label: '应用',"),
    );
    expect(files, contains('legacyBuilder: (_) => FilePage('));
    expect(files, contains('browsePreviewBuilder:'));
    expect(files, contains('FileBrowsePage('));
    expect(files, contains('onReauthNeeded: widget.onReauthNeeded'));
    expect(files, isNot(contains('modernBuilder:')));
    expect(source, contains('ExternalIntentListener('));
    expect(source, contains('Upload('));
    expect(source, contains('AddDownloadTask('));
    expect(source, contains('LegacyPageHost('));
  });

}
