import 'package:dsm_helper/new_ui/shell/new_ui_primary_page.dart';
import 'package:dsm_helper/new_ui/theme/new_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary page owns one New UI AppBar and exposes notification globally', (tester) async {
    var notifications = 0;
    var fallback = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: NewUiTheme.light(),
        home: NewUiPrimaryPage(
          title: '文件',
          onOpenNotifications: () => notifications++,
          onOpenLegacyFeature: () => fallback++,
        ),
      ),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('文件'), findsOneWidget);
    expect(find.byKey(const Key('new-ui-notifications')), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-ui-notifications')));
    expect(notifications, 1);

    await tester.tap(find.byKey(const Key('open-legacy-feature')));
    expect(fallback, 1);
  });

  testWidgets('large text keeps the title readable and does not hide primary fallback action', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: MaterialApp(
          theme: NewUiTheme.light(),
          home: NewUiPrimaryPage(
            title: '概览',
            onOpenNotifications: () {},
            onOpenLegacyFeature: () {},
          ),
        ),
      ),
    );

    expect(find.text('概览'), findsOneWidget);
    expect(find.byKey(const Key('open-legacy-feature')), findsOneWidget);
  });
  testWidgets('abnormal connection status is visible without removing global notification', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NewUiTheme.light(),
        home: NewUiPrimaryPage(
          title: '概览',
          connectionStatusText: '离线',
          onOpenNotifications: () {},
          onOpenLegacyFeature: () {},
        ),
      ),
    );

    expect(find.text('概览'), findsOneWidget);
    expect(find.text('离线'), findsOneWidget);
    expect(find.byKey(const Key('new-ui-notifications')), findsOneWidget);
  });
  testWidgets('optional preview follows existing fallback and does not affect other roots',
      (tester) async {
    var preview = 0;
    await tester.pumpWidget(MaterialApp(
      theme: NewUiTheme.light(),
      home: Function.apply(NewUiPrimaryPage.new, const [], {
        #title: '文件',
        #onOpenNotifications: () {},
        #onOpenLegacyFeature: () {},
        #onOpenBrowsePreview: () => preview++,
      }) as NewUiPrimaryPage,
    ));

    expect(find.byKey(const Key('open-legacy-feature')), findsOneWidget);
    expect(find.byKey(const Key('file-browse-preview')), findsOneWidget);
    expect(find.text('试用新版文件浏览（测试）'), findsOneWidget);
    await tester.tap(find.byKey(const Key('file-browse-preview')));
    expect(preview, 1);

    await tester.pumpWidget(MaterialApp(
      theme: NewUiTheme.light(),
      home: NewUiPrimaryPage(
        title: '任务',
        onOpenNotifications: () {},
        onOpenLegacyFeature: () {},
      ),
    ));
    expect(find.byKey(const Key('file-browse-preview')), findsNothing);
    expect(find.byKey(const Key('open-legacy-feature')), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
