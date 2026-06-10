import 'dart:typed_data';

/// Metadata returned by [CloudStorageAdapter.listFiles].
class CloudFileInfo {
  const CloudFileInfo({
    required this.id,
    required this.name,
    this.createdTime,
    this.modifiedTime,
  });

  /// Drive id: file ID string. iCloud id: container-relative path.
  final String id;
  final String name;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
}

/// All sync/conflict/encryption logic lives in BackupProvider — this
/// interface covers only raw file operations.
abstract class CloudStorageAdapter {
  /// Upload [bytes] as a new file named [filename] in the backup folder.
  Future<void> upload(String filename, Uint8List bytes);

  /// Download the (first) file named exactly [filename] from the backup
  /// folder. Returns null when the file does not exist.
  Future<Uint8List?> download(String filename);

  /// Download a file by its opaque [id] (Drive file ID or iCloud relative
  /// path). Returns null on any error.
  Future<Uint8List?> downloadById(String id);

  /// Delete the file identified by [id].
  Future<void> delete(String id);

  /// Delete every file in the backup folder.
  Future<void> deleteAll();

  /// List files whose name contains [nameContains].
  /// [modifiedAfter] / [createdBefore] are hints; Drive applies them
  /// server-side, iCloud filters client-side.
  Future<List<CloudFileInfo>> listFiles({
    required String nameContains,
    DateTime? modifiedAfter,
    DateTime? createdBefore,
  });

  // ── Key file helpers ──────────────────────────────────────────────────────
  // Drive stores key.key in the backup folder.
  // iCloud uses iCloud Keychain (synchronizable: true) — these are no-ops.

  Future<Uint8List?> downloadKeyFile();
  Future<void> uploadKeyFile(Uint8List bytes);
  Future<void> deleteKeyFile();

  Future<bool> get isAvailable;

  Future<void> dispose();
}
