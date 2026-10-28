// T-002 spike: recovery copy before a migration (MG-02, SP-05 "backup file
// copy"). Native targets only (dart:io).
//
// The schema version is read from the SQLite file header (offset 60,
// big-endian `user_version`), so no connection is opened before the copy.
// A leftover `-wal` or `-journal` file means the last session did not close
// cleanly; the spike refuses to copy then, because the main file alone may
// not be a consistent database.

import 'dart:io';
import 'dart:typed_data';

/// `user_version` from the header of [file], or null if it is not SQLite.
int? headerUserVersion(File file) {
  if (!file.existsSync()) {
    return null;
  }
  final handle = file.openSync();
  try {
    final header = handle.readSync(100);
    const magic = 'SQLite format 3';
    if (header.length < 100 || header[15] != 0) {
      return null;
    }
    for (var i = 0; i < magic.length; i++) {
      if (header[i] != magic.codeUnitAt(i)) {
        return null;
      }
    }
    return ByteData.sublistView(header).getUint32(60);
  } finally {
    handle.closeSync();
  }
}

/// Copies [database] to `<name>.recovery-v<version>-<stamp>` when it is
/// older than [targetVersion] and keeps the newest [keep] copies (MG-02).
/// Returns the copy, or null when no migration is pending.
File? copyForRecovery(
  File database, {
  required int targetVersion,
  required String stamp,
  int keep = 3,
}) {
  final version = headerUserVersion(database);
  if (version == null || version >= targetVersion) {
    return null;
  }
  for (final suffix in const ['-wal', '-journal']) {
    if (File('${database.path}$suffix').existsSync()) {
      throw StateError('${database.path}$suffix exists: unclean shutdown');
    }
  }
  final name = database.uri.pathSegments.last;
  final copy = database.copySync('${database.path}.recovery-v$version-$stamp');
  final copies = database.parent
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('$name.recovery-'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  while (copies.length > keep) {
    copies.removeAt(0).deleteSync();
  }
  return copy;
}
