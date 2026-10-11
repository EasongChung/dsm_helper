import 'package:dsm_helper/new_ui/files/file_browse_breadcrumb.dart';
import 'package:dsm_helper/new_ui/files/file_browse_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('only verified visited ancestors are clickable, not guessed URI segments',
      (tester) async {
    const root = FileBrowseAncestor(label: '共享文件夹', path: null);
    const share = FileBrowseAncestor(label: '共有目录', path: '/share');
    const current = FileBrowseAncestor(
      label: 'scheme://server/汉字 空格',
      path: 'scheme://server/汉字 空格',
    );
    final selected = <String?>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FileBrowseBreadcrumb(
          ancestors: const [root, share, current],
          onNavigate: (ancestor) => selected.add(ancestor.path),
        ),
      ),
    ));
    expect(find.byKey(const Key('file-browse-crumb:root')), findsOneWidget);
    expect(find.byKey(const Key('file-browse-crumb:/share')), findsOneWidget);
    expect(
      find.byKey(const Key('file-browse-crumb:scheme://server/汉字 空格')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('file-browse-crumb:scheme://server')), findsNothing);
    await tester.tap(find.byKey(const Key('file-browse-crumb:/share')));
    expect(selected, ['/share']);
    await tester.tap(find.byKey(const Key('file-browse-crumb:root')));
    expect(selected, ['/share', null]);
    // Current directory is a label only; selecting it must not duplicate its route.
    await tester.tap(
      find.byKey(const Key('file-browse-crumb:scheme://server/汉字 空格')),
    );
    expect(selected, ['/share', null]);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('a single root breadcrumb is rendered and never pushes another route',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: FileBrowseBreadcrumb(
        ancestors: const [FileBrowseAncestor(label: '共享文件夹', path: null)],
        onNavigate: (_) => taps++,
      ),
    )));
    expect(find.text('共享文件夹'), findsOneWidget);
    await tester.tap(find.byKey(const Key('file-browse-crumb:root')));
    expect(taps, 0);
  }, timeout: const Timeout(Duration(seconds: 20)));
}
