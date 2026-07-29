import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';

final foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllFolders();
});

final smartCollectionCountsProvider =
    FutureProvider<List<SmartCollection>>((ref) async {
  final db = ref.read(databaseProvider);
  final stats = await db.getStatistics();
  final allBookmarks = await db.getAllBookmarks();
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final recentCount =
      allBookmarks.where((b) => b.createdAt.isAfter(cutoff)).length;
  return SmartCollection.defaults(
    recentlyAdded: recentCount,
    unread: stats['unread'] ?? 0,
    readLater: stats['readLater'] ?? 0,
    mostVisited: 10,
    recentlyOpened: 10,
    deadLinks: stats['dead'] ?? 0,
  );
});

final folderCountsProvider = StreamProvider<Map<int, int>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchFolderBookmarkCounts();
});
