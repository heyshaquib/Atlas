/// BacklinkDetector — Scans notes for URLs matching existing bookmarks
/// and updates the bookmark_relations table.
library;

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/utils/utils.dart';

class BacklinkDetector {
  final AppDatabase _db;

  BacklinkDetector(this._db);

  /// Scans the plain text notes of a bookmark for URLs that match
  /// other bookmarks in the database. Updates backlink relations.
  Future<void> detectAndUpdateBacklinks(int sourceBookmarkId, String? notesPlainText) async {
    if (notesPlainText == null || notesPlainText.isEmpty) {
      // Clear all existing backlinks for this source
      await _db.updateBacklinks(sourceBookmarkId, []);
      return;
    }

    // Extract all URLs from the notes text
    final urlRegex = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    final matches = urlRegex.allMatches(notesPlainText);
    final foundUrls = matches.map((m) => m.group(0)!).toSet();

    if (foundUrls.isEmpty) {
      await _db.updateBacklinks(sourceBookmarkId, []);
      return;
    }

    // Find bookmarks whose URLs match
    final targetIds = <int>[];
    for (final url in foundUrls) {
      final bookmark = await _db.findByUrl(url);
      if (bookmark != null && bookmark.id != sourceBookmarkId) {
        targetIds.add(bookmark.id);
      }
      // Also try normalized version
      final normalized = normalizeUrl(url);
      if (normalized != url) {
        final normalizedBookmark = await _db.findByUrl(normalized);
        if (normalizedBookmark != null &&
            normalizedBookmark.id != sourceBookmarkId &&
            !targetIds.contains(normalizedBookmark.id)) {
          targetIds.add(normalizedBookmark.id);
        }
      }
    }

    // Update the backlink relations
    await _db.updateBacklinks(sourceBookmarkId, targetIds);
  }
}
