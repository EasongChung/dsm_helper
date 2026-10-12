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
}
