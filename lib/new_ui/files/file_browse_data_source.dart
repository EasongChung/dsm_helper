import 'package:dsm_helper/models/Syno/FileStation/FileStationList.dart';
import 'file_browse_page_model.dart';

export 'file_browse_page_model.dart' show FileBrowseDataException;

typedef FileSharePageLoader = Future<FileStationList> Function({
  required int offset,
  required int limit,
  required String sortBy,
  required String sortDirection,
});

typedef FileFolderPageLoader = Future<FileStationList> Function({
  required String path,
  required int offset,
  required int limit,
  required String sortBy,
  required String sortDirection,
});

/// Only translates validated read pages; the legacy DSM client owns transport.
class FileBrowseDataSource {
  const FileBrowseDataSource({
    required this.loadShares,
    required this.loadFolder,
  });

  factory FileBrowseDataSource.production() => FileBrowseDataSource(
        loadShares: ({
          required offset,
          required limit,
          required sortBy,
          required sortDirection,
        }) => FileStationList.shareList(
          offset: offset,
          limit: limit,
          sortBy: sortBy,
          sortDirection: sortDirection,
        ),
        loadFolder: ({
          required path,
          required offset,
          required limit,
          required sortBy,
          required sortDirection,
        }) => FileStationList.fileList(
          path: path,
          offset: offset,
          limit: limit,
          sortBy: sortBy,
          sortDirection: sortDirection,
        ),
      );

  final FileSharePageLoader loadShares;
  final FileFolderPageLoader loadFolder;

  Future<FileBrowsePage> loadPage(FileBrowseRequest request) async {
    if (request.offset < 0 || request.limit <= 0 ||
        (request.path != null && request.path!.isEmpty)) {
      throw const FileBrowseDataException('Invalid browse request');
    }

    final FileStationList response;
    try {
      response = request.path == null
          ? await loadShares(
              offset: request.offset,
              limit: request.limit,
              sortBy: request.sortBy,
              sortDirection: request.sortDirection,
            )
          : await loadFolder(
              path: request.path!,
              offset: request.offset,
              limit: request.limit,
              sortBy: request.sortBy,
              sortDirection: request.sortDirection,
            );
    } on NoSuchMethodError catch (error) {
      // Legacy FileStationList.fromJson invokes methods on malformed rows.
      // Only parser-shape failures are normalized; DSM/Dio remain untouched.
      throw FileBrowseDataException('Malformed File Station row: $error');
    } on TypeError catch (error) {
      throw FileBrowseDataException('Malformed File Station field: $error');
    }

    final returnedOffset = response.offset;
    if (returnedOffset != null &&
        (returnedOffset is! int || returnedOffset < 0 ||
            returnedOffset != request.offset)) {
      throw const FileBrowseDataException('Invalid File Station page offset');
    }

    final returnedTotal = response.total;
    if (returnedTotal != null &&
        (returnedTotal is! int || returnedTotal < 0)) {
      throw const FileBrowseDataException('Invalid File Station total');
    }

    final items = response.files;
    if (items == null) {
      throw const FileBrowseDataException('Missing File Station files array');
    }

    return FileBrowsePage(
      path: request.path,
      offset: returnedOffset?.toInt() ?? request.offset,
      limit: request.limit,
      items: items,
      total: returnedTotal?.toInt(),
    );
  }
}
