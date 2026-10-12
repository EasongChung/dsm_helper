import 'package:dsm_helper/apis/api.dart';
import 'package:dsm_helper/apis/dsm_api/dsm_response.dart';
import 'file_operation_contract.dart';

typedef FileOperationEntry = Future<DsmResponse<dynamic>> Function(
  String api,
  String method, {
  required int version,
  required Map<String, dynamic> data,
});

enum FileOperationResultKind { immediate, taskAccepted, linkCreated }
enum FileOperationErrorKind {
  reauthNeeded, offline, permission, conflict, duplicate, server, malformed,
}

class FileOperationContextException implements Exception {
  const FileOperationContextException();
}

class FileOperationResult {
  const FileOperationResult(this.kind, {this.taskId, this.link});
  final FileOperationResultKind kind;
  final String? taskId;
  final String? link;
}

/// B1 has no mounted UI or automatic writes.
class FileOperationDataSource {
  FileOperationDataSource({
    required this.contextId,
    required this.isContextCurrent,
    required this.entry,
    this.onReauthNeeded,
  });

  final String contextId;
  final bool Function() isContextCurrent;
  final FileOperationEntry entry;
  final void Function()? onReauthNeeded;

  factory FileOperationDataSource.production({
    required String contextId,
    required bool Function() isContextCurrent,
    void Function()? onReauthNeeded,
  }) {
    throw UnimplementedError('T7B-OPS-02 bound transport');
  }

  void invalidate() {
    throw UnimplementedError('T7B-OPS-01 lifecycle');
  }

  static FileOperationErrorKind classify(Object error) {
    throw UnimplementedError('T7B-STATE-01 error taxonomy');
  }

  Future<FileOperationResult> execute({
    required FileOperationSelection selection,
    required FileOperationAction action,
    String? name,
    String? destination,
  }) async {
    throw UnimplementedError('T7B-OPS-02 operation adapter');
  }
}
