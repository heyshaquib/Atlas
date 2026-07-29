/// DeadLinkChecker — Checks bookmarks for dead links via HEAD/GET requests.
/// Marks as dead only after 2 consecutive failures.
library;

import 'package:http/http.dart' as http;
import 'package:atlas/core/database/app_database.dart';

class DeadLinkChecker {
  final AppDatabase _db;
  final http.Client _client;

  DeadLinkChecker(this._db, {http.Client? client})
      : _client = client ?? http.Client();

  /// Checks a single URL and returns true if it's alive.
  Future<bool> isAlive(String url) async {
    try {
      // Try HEAD first (cheaper)
      final headResponse = await _client
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (headResponse.statusCode < 400) return true;

      // Fallback to GET
      final getResponse = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return getResponse.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Checks all active bookmarks for dead links.
  /// Returns the number of newly detected dead links.
  Future<int> checkAll({
    Function(int checked, int total)? onProgress,
  }) async {
    final bookmarks = await _db.getAllActiveBookmarks();
    int newDeadCount = 0;
    int checked = 0;

    for (final bookmark in bookmarks) {
      final alive = await isAlive(bookmark.url);
      checked++;

      if (!alive) {
        final newFailCount = bookmark.deadCheckFailCount + 1;
        // Mark as dead only after 2 consecutive failures
        final isDead = newFailCount >= 2;
        await _db.updateDeadStatus(bookmark.id, isDead, newFailCount);
        if (isDead && !bookmark.isDead) {
          newDeadCount++;
        }
      } else {
        // Reset fail count if alive
        if (bookmark.deadCheckFailCount > 0 || bookmark.isDead) {
          await _db.updateDeadStatus(bookmark.id, false, 0);
        }
      }

      onProgress?.call(checked, bookmarks.length);
    }

    return newDeadCount;
  }

  void dispose() {
    _client.close();
  }
}
