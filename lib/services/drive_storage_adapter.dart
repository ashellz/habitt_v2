import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive_api;
import 'package:http/http.dart' as http;

import 'cloud_storage_adapter.dart';

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// Google Drive implementation of [CloudStorageAdapter].
/// All files live inside a single `habitt_backups/` folder in Drive root.
class DriveStorageAdapter implements CloudStorageAdapter {
  DriveStorageAdapter({required GoogleSignInAccount account})
      : _account = account;

  final GoogleSignInAccount _account;

  // Cached after first lookup to avoid repeated Drive API round-trips.
  String? _cachedFolderId;

  static const _folderName = 'habitt_backups';
  static const _folderMime = 'application/vnd.google-apps.folder';

  Future<drive_api.DriveApi?> _getDrive() async {
    try {
      final headers = await _account.authHeaders;
      return drive_api.DriveApi(_GoogleAuthClient(headers));
    } catch (e) {
      debugPrint('[Drive] _getDrive error: $e');
      return null;
    }
  }

  Future<String?> _getFolderIdInternal(
    drive_api.DriveApi drive, {
    bool create = true,
  }) async {
    if (_cachedFolderId != null) return _cachedFolderId;
    try {
      final found = await drive.files.list(
        q: "mimeType = '$_folderMime' and name = '$_folderName'"
            " and trashed = false and 'root' in parents",
        $fields: 'files(id,name)',
        spaces: 'drive',
      );
      final files = found.files;
      if (files == null) return null;
      if (files.isNotEmpty) {
        _cachedFolderId = files.first.id;
        return _cachedFolderId;
      }
      if (!create) return null;
      final folder =
          drive_api.File()
            ..name = _folderName
            ..mimeType = _folderMime
            ..parents = ['root'];
      final created = await drive.files.create(folder, $fields: 'id');
      _cachedFolderId = created.id;
      return _cachedFolderId;
    } catch (e) {
      debugPrint('[Drive] _getFolderIdInternal error: $e');
      return null;
    }
  }

  Future<Uint8List?> _downloadFileId(
    drive_api.DriveApi drive,
    String fileId,
  ) async {
    final response =
        await drive.files.get(
              fileId,
              downloadOptions: drive_api.DownloadOptions.fullMedia,
            )
            as drive_api.Media;
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> upload(String filename, Uint8List bytes) async {
    final drive = await _getDrive();
    if (drive == null) return;
    final folderId = await _getFolderIdInternal(drive);
    if (folderId == null) return;

    final media = drive_api.Media(Stream.value(bytes.toList()), bytes.length);
    final file =
        drive_api.File()
          ..name = filename
          ..parents = [folderId];
    await drive.files.create(file, uploadMedia: media);
  }

  @override
  Future<Uint8List?> download(String filename) async {
    final drive = await _getDrive();
    if (drive == null) return null;
    final folderId = await _getFolderIdInternal(drive, create: false);
    if (folderId == null) return null;

    final found = await drive.files.list(
      q: "name = '$filename' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );
    if (found.files == null || found.files!.isEmpty) return null;
    final fileId = found.files!.first.id;
    if (fileId == null) return null;
    return _downloadFileId(drive, fileId);
  }

  @override
  Future<Uint8List?> downloadById(String id) async {
    final drive = await _getDrive();
    if (drive == null) return null;
    return _downloadFileId(drive, id);
  }

  @override
  Future<void> delete(String id) async {
    final drive = await _getDrive();
    if (drive == null) return;
    try {
      await drive.files.delete(id);
    } catch (e) {
      debugPrint('[Drive] delete($id) error: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    final drive = await _getDrive();
    if (drive == null) return;
    final folderId = await _getFolderIdInternal(drive, create: false);
    if (folderId == null) return;
    final found = await drive.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );
    for (final f in (found.files ?? [])) {
      if (f.id != null) {
        try {
          await drive.files.delete(f.id!);
        } catch (_) {}
      }
    }
  }

  @override
  Future<List<CloudFileInfo>> listFiles({
    required String nameContains,
    DateTime? modifiedAfter,
    DateTime? createdBefore,
  }) async {
    final drive = await _getDrive();
    if (drive == null) return [];
    final folderId = await _getFolderIdInternal(drive, create: false);
    if (folderId == null) return [];

    var q =
        "name contains '$nameContains' and '$folderId' in parents"
        " and trashed = false";
    if (modifiedAfter != null) {
      q += " and modifiedTime > '${modifiedAfter.toUtc().toIso8601String()}'";
    }
    if (createdBefore != null) {
      q += " and createdTime < '${createdBefore.toUtc().toIso8601String()}'";
    }

    final res = await drive.files.list(
      q: q,
      $fields: 'files(id,name,createdTime,modifiedTime)',
    );

    return (res.files ?? [])
        .where((f) => f.id != null)
        .map(
          (f) => CloudFileInfo(
            id: f.id!,
            name: f.name ?? '',
            createdTime: f.createdTime,
            modifiedTime: f.modifiedTime,
          ),
        )
        .toList();
  }

  @override
  Future<Uint8List?> downloadKeyFile() => download('key.key');

  @override
  Future<void> uploadKeyFile(Uint8List bytes) async {
    await deleteKeyFile();
    await upload('key.key', bytes);
  }

  @override
  Future<void> deleteKeyFile() async {
    final drive = await _getDrive();
    if (drive == null) return;
    final folderId = await _getFolderIdInternal(drive, create: false);
    if (folderId == null) return;
    final found = await drive.files.list(
      q: "name = 'key.key' and '$folderId' in parents and trashed = false",
      $fields: 'files(id)',
    );
    for (final f in (found.files ?? [])) {
      if (f.id != null) await drive.files.delete(f.id!);
    }
  }

  @override
  Future<bool> get isAvailable async {
    final drive = await _getDrive();
    return drive != null;
  }

  @override
  Future<void> dispose() async {
    _cachedFolderId = null;
  }
}
