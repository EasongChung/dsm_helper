import 'package:dsm_helper/new_ui/files/file_search_data_source.dart';
import 'package:flutter/material.dart';

/// Task 7B Batch 2 search route seam.
///
/// Widget behavior is intentionally added only after the Step 2.5 RED suite.
class FileSearchPage extends StatelessWidget {
  const FileSearchPage({
    super.key,
    required this.contextId,
    required this.folderPath,
    required this.onOpenNotifications,
    this.connectionStatusText,
    this.dataSource,
    this.onReauthNeeded,
  });

  final String contextId;
  final String folderPath;
  final VoidCallback onOpenNotifications;
  final String? connectionStatusText;
  final FileSearchDataSource? dataSource;
  final VoidCallback? onReauthNeeded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: const Center(child: Text('Search UI pending')),
    );
  }
}
