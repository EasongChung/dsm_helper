import 'package:dsm_helper/new_ui/files/file_browse_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('root and each verified ordinary folder preserve exact path and order', () {
    const root = FileBrowseAncestor(label: '共享文件夹', path: null);
    const share = FileBrowseAncestor(label: '共享', path: '/share');
    const nested = FileBrowseAncestor(label: '汉字', path: '/share/汉字');

    final ancestors = buildBrowseAncestors(
      visited: [root, share],
      current: nested,
    );
    expect(ancestors.map((v) => v.label).toList(), [
      '共享文件夹', '共享', '汉字',
    ]);
    expect(ancestors.map((v) => v.path).toList(), [
      null, '/share', '/share/汉字',
    ]);
    // Every navigable ancestor must be one explicitly visited by routing.
    expect(ancestors.take(2).map((v) => v.path).toList(), [null, '/share']);
  });

  test('direct root to deeply nested returned path never fabricates parents', () {
    const root = FileBrowseAncestor(label: '共享文件夹', path: null);
    const current = FileBrowseAncestor(
      label: 'DSM returned', path: '/share/space and 汉字/nested',
    );
    final ancestors = buildBrowseAncestors(
      visited: [root],
      current: current,
    );
    expect(ancestors.map((v) => v.path).toList(),
      [null, '/share/space and 汉字/nested']);
    expect(ancestors, hasLength(2));
  });

  test('scheme URI is kept byte-for-byte without unvisited intermediary', () {
    const root = FileBrowseAncestor(label: 'Root', path: null);
    const remote = FileBrowseAncestor(
      label: 'scheme://server/folder/汉字 空格',
      path: 'scheme://server/folder/汉字 空格',
    );
    final ancestors = buildBrowseAncestors(visited: [root], current: remote);
    expect(ancestors.map((v) => v.path).toList(),
      [null, 'scheme://server/folder/汉字 空格']);
    expect(ancestors.last.label, 'scheme://server/folder/汉字 空格');
  });

  test('equal display names at different visited paths remain distinct', () {
    const root = FileBrowseAncestor(label: 'Root', path: null);
    const one = FileBrowseAncestor(label: '重复名', path: '/share/a');
    const two = FileBrowseAncestor(label: '重复名', path: '/share/a/child');
    final ancestors = buildBrowseAncestors(
      visited: [root, one],
      current: two,
    );
    expect(ancestors.where((v) => v.label == '重复名'), hasLength(2));
    expect(ancestors.map((v) => v.path).toSet(), hasLength(3));
  });

  test('duplicate route identities do not create duplicate breadcrumb targets', () {
    const root = FileBrowseAncestor(label: 'Root', path: null);
    const share = FileBrowseAncestor(label: 'Share', path: '/share');
    final ancestors = buildBrowseAncestors(
      visited: [root, share, share],
      current: share,
    );
    expect(ancestors.map((v) => v.path).toList(), [null, '/share']);
  });

  test('projection is immutable and detached from caller visited collection', () {
    final visited = <FileBrowseAncestor>[
      const FileBrowseAncestor(label: 'Root', path: null),
    ];
    final projected = buildBrowseAncestors(
      visited: visited,
      current: const FileBrowseAncestor(label: 'A', path: '/share/A'),
    );
    visited.add(const FileBrowseAncestor(label: 'X', path: '/share/X'));
    expect(projected.map((v) => v.path).toList(), [null, '/share/A']);
    expect(
      () => projected.add(const FileBrowseAncestor(label: 'X', path: '/share/X')),
      throwsUnsupportedError,
    );
  });
}
