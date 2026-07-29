import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';

final bookmarkDetailProvider =
    StreamProvider.family<Bookmark, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.watchBookmarkById(id);
});

final relatedBookmarksProvider =
    FutureProvider.family<List<Bookmark>, int>((ref, id) async {
  final db = ref.read(databaseProvider);
  return db.getRelatedBookmarks(id);
});

final backlinksProvider =
    FutureProvider.family<List<Bookmark>, int>((ref, id) async {
  final db = ref.read(databaseProvider);
  return db.getBacklinksTo(id);
});

final bookmarkTagsProvider =
    FutureProvider.family<List<Tag>, int>((ref, id) async {
  final db = ref.read(databaseProvider);
  return db.getTagsForBookmark(id);
});
