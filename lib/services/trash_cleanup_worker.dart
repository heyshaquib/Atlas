/// TrashCleanupWorker — Purges old trash items based on user settings.
/// Designed to be called from WorkManager periodic task.
library;

import 'package:atlas/core/database/app_database.dart';

class TrashCleanupWorker {
  final AppDatabase _db;

  TrashCleanupWorker(this._db);

  /// Purges trash items older than the specified number of days.
  /// Returns the number of items permanently deleted.
  Future<int> cleanup(int retentionDays) async {
    if (retentionDays <= 0) return 0; // "Never" setting
    final deleted = await _db.purgeOldTrash(Duration(days: retentionDays));
    return deleted;
  }
}
