import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'cloud_storage_adapter.dart';

// iCloud Documents implementation of [CloudStorageAdapter].

// Files are stored in `habitt_backups/` within the app's iCloud container
// with `IOSOptions(synchronizable: true)` syncs all keychain slots via iCloud
// keychain automatically

class ICloudStorageAdapter implements CloudStorageAdapter {
  static const _containerId = 'iCloud.com.shellz.habitt';
  static const _folder = 'habitt_backups';

  Future<File> _tmpFile(String filename) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    return File('${dir.path}/${ts}_$filename');
  }

  @override
  Future<void> upload(String filename, Uint8List bytes) async {
    final tmp = await _tmpFile(filename);
    try {
      await tmp.writeAsBytes(bytes);
      final completer = Completer<void>();
      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: tmp.path,
        destinationRelativePath: '$_folder/$filename',
        onProgress: (stream) {
          stream.listen(
            (_) {},
            onDone: completer.complete,
            onError: completer.completeError,
            cancelOnError: true,
          );
        },
      );
      await completer.future;
    } catch (e) {
      debugPrint('[iCloud] upload($filename) error: $e');
      rethrow;
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  @override
  Future<Uint8List?> download(String filename) =>
      downloadById('$_folder/$filename');

  @override
  Future<Uint8List?> downloadById(String id) async {
    // id is the container-relative path, e.g. 'habitt_backups/filename'
    final filename = id.split('/').last;
    final tmp = await _tmpFile(filename);
    try {
      final completer = Completer<void>();
      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: id,
        destinationFilePath: tmp.path,
        onProgress: (stream) {
          stream.listen(
            (_) {},
            onDone: completer.complete,
            onError: completer.completeError,
            cancelOnError: true,
          );
        },
      );
      await completer.future;
      final bytes = await tmp.readAsBytes();
      return bytes;
    } catch (e) {
      debugPrint('[iCloud] downloadById($id) error: $e');
      return null;
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> delete(String id) async {
    // id is the container-relative path
    try {
      await ICloudStorage.delete(containerId: _containerId, relativePath: id);
    } catch (e) {
      debugPrint('[iCloud] delete($id) error: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    final files = await _gatherAll();
    for (final f in files) {
      await delete(f.relativePath);
    }
  }

  @override
  Future<List<CloudFileInfo>> listFiles({
    required String nameContains,
    DateTime? modifiedAfter,
    DateTime? createdBefore,
  }) async {
    final all = await _gatherAll();
    return all
        .where(
          (f) =>
              f.relativePath.startsWith('$_folder/') &&
              f.relativePath.contains(nameContains),
        )
        .where(
          (f) =>
              modifiedAfter == null ||
              f.contentChangeDate.isAfter(modifiedAfter),
        )
        .where(
          (f) =>
              createdBefore == null || f.creationDate.isBefore(createdBefore),
        )
        .map(
          (f) => CloudFileInfo(
            id: f.relativePath,
            name: f.relativePath.split('/').last,
            createdTime: f.creationDate,
            modifiedTime: f.contentChangeDate,
          ),
        )
        .toList();
  }

  Future<List<ICloudFile>> _gatherAll() async {
    try {
      return await ICloudStorage.gather(containerId: _containerId);
    } on PlatformException catch (e) {
      // E_CTR means iCloud is entirely inaccessible — propagate so the caller
      // can deactivate the backend and show the error. Swallow everything else.
      if (e.code == 'E_CTR') rethrow;
      debugPrint('[iCloud] gather error: $e');
      return [];
    } catch (e) {
      debugPrint('[iCloud] gather error: $e');
      return [];
    }
  }

  // ── Key file — iCloud Keychain handles sync; no file needed ──────────────

  @override
  Future<Uint8List?> downloadKeyFile() async => null;

  @override
  Future<void> uploadKeyFile(Uint8List bytes) async {}

  @override
  Future<void> deleteKeyFile() async {}

  @override
  Future<bool> get isAvailable async {
    try {
      await ICloudStorage.gather(containerId: _containerId);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {}

  /// Returns true if [e] is the iCloud "not available" platform error
  /// (container invalid, user not signed in, or iCloud disabled in Settings).
  static bool isUnavailableError(Object e) =>
      e is PlatformException && e.code == 'E_CTR';

  /// Returns true if [e] is an iCloud quota-exceeded error.
  /// Matches NSFileProviderErrorDomain Code=-1003 / CKErrorDomain:25
  /// ("Error uploading asset: Quota exceeded").
  static bool isQuotaExceededError(Object e) {
    if (e is PlatformException && e.code == 'E_NAT') {
      final details = '${e.details}'.toLowerCase();
      return details.contains('quota') ||
          details.contains('ckerrordomain:25') ||
          details.contains('code=-1003');
    }
    return false;
  }
}
