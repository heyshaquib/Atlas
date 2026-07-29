// GENERATED CODE - DO NOT MODIFY BY HAND
// Database schema for Atlas Bookmark Manager
// Uses drift (SQLite) for type-safe local persistence

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#3D5A80'))();
  TextColumn get icon =>
      text().withDefault(const Constant('folder'))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get url => text()();
  TextColumn get domain => text()();
  TextColumn get pageDescription => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get notesPlainText => text().nullable()();
  TextColumn get faviconUrl => text().nullable()();
  TextColumn get previewImageUrl => text().nullable()();
  IntColumn get folderId =>
      integer().nullable().references(Folders, #id)();
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isUnread =>
      boolean().withDefault(const Constant(true))();

  BoolColumn get isDead =>
      boolean().withDefault(const Constant(false))();
  IntColumn get deadCheckFailCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get estimatedReadingTimeMinutes => integer().nullable()();
  IntColumn get estimatedWordCount => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get visitCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get customOrder =>
      integer().withDefault(const Constant(0))();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class BookmarkTagJoin extends Table {
  IntColumn get bookmarkId =>
      integer().references(Bookmarks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {bookmarkId, tagId};
}

class BookmarkRelations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceId =>
      integer().references(Bookmarks, #id)();
  IntColumn get targetId =>
      integer().references(Bookmarks, #id)();
  TextColumn get relationType => text()();
}

class RecentSearches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()();
  DateTimeColumn get createdAt => dateTime()();
}

// ─── Database ─────────────────────────────────────────────

@DriftDatabase(tables: [
  Bookmarks,
  Folders,
  Tags,
  BookmarkTagJoin,
  BookmarkRelations,
  RecentSearches,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );

  // ─── Bookmark Queries ─────────────────────────────────

  // Get all active bookmarks (not archived, not deleted)
  Future<List<Bookmark>> getAllBookmarks({
    String? sortBy,
    bool ascending = false,
  }) {
    final query = select(bookmarks)
      ..where((b) => b.isDeleted.equals(false) & b.isArchived.equals(false));

    switch (sortBy) {
      case 'title':
        query.orderBy([
          (b) => OrderingTerm(
              expression: b.title,
              mode: ascending ? OrderingMode.asc : OrderingMode.desc)
        ]);
        break;
      case 'domain':
        query.orderBy([
          (b) => OrderingTerm(
              expression: b.domain,
              mode: ascending ? OrderingMode.asc : OrderingMode.desc)
        ]);
        break;
      case 'readingTime':
        query.orderBy([
          (b) => OrderingTerm(
              expression: b.estimatedReadingTimeMinutes,
              mode: ascending ? OrderingMode.asc : OrderingMode.desc)
        ]);
        break;
      case 'visitCount':
        query.orderBy([
          (b) => OrderingTerm(
              expression: b.visitCount, mode: OrderingMode.desc)
        ]);
        break;
      default:
        query.orderBy([
          (b) =>
              OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
        ]);
    }

    return query.get();
  }

  // Watch active bookmarks stream
  Stream<List<Bookmark>> watchAllBookmarks() {
    return (select(bookmarks)
          ..where(
              (b) => b.isDeleted.equals(false) & b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get bookmarks by folder
  Stream<List<Bookmark>> watchBookmarksByFolder(int folderId) {
    return (select(bookmarks)
          ..where((b) =>
              b.folderId.equals(folderId) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get favorites
  Stream<List<Bookmark>> watchFavorites() {
    return (select(bookmarks)
          ..where((b) =>
              b.isFavorite.equals(true) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get unread
  Stream<List<Bookmark>> watchUnread() {
    return (select(bookmarks)
          ..where((b) =>
              b.isUnread.equals(true) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }



  // Get archived
  Stream<List<Bookmark>> watchArchived() {
    return (select(bookmarks)
          ..where(
              (b) => b.isArchived.equals(true) & b.isDeleted.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get deleted (trash)
  Stream<List<Bookmark>> watchTrash() {
    return (select(bookmarks)
          ..where((b) => b.isDeleted.equals(true))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.deletedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get dead links
  Stream<List<Bookmark>> watchDeadLinks() {
    return (select(bookmarks)
          ..where((b) =>
              b.isDead.equals(true) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get recently added (last 7 days)
  Stream<List<Bookmark>> watchRecentlyAdded() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return (select(bookmarks)
          ..where((b) =>
              b.createdAt.isBiggerOrEqualValue(sevenDaysAgo) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Get most visited
  Stream<List<Bookmark>> watchMostVisited({int limit = 10}) {
    return (select(bookmarks)
          ..where(
              (b) => b.isDeleted.equals(false) & b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.visitCount, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .watch();
  }

  // Get recently opened
  Stream<List<Bookmark>> watchRecentlyOpened({int limit = 10}) {
    return (select(bookmarks)
          ..where((b) =>
              b.lastOpenedAt.isNotNull() &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) => OrderingTerm(
                expression: b.lastOpenedAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .watch();
  }

  // Get bookmark by id
  Future<Bookmark> getBookmarkById(int id) {
    return (select(bookmarks)..where((b) => b.id.equals(id))).getSingle();
  }

  // Watch single bookmark
  Stream<Bookmark> watchBookmarkById(int id) {
    return (select(bookmarks)..where((b) => b.id.equals(id))).watchSingle();
  }

  // Insert bookmark
  Future<int> insertBookmark(BookmarksCompanion entry) {
    return into(bookmarks).insert(entry);
  }

  // Update bookmark
  Future<bool> updateBookmark(BookmarksCompanion entry) {
    return (update(bookmarks)..where((b) => b.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  // Toggle favorite
  Future<void> toggleFavorite(int id, bool isFavorite) {
    return (update(bookmarks)..where((b) => b.id.equals(id)))
        .write(BookmarksCompanion(isFavorite: Value(isFavorite)));
  }

  // Move to trash
  Future<void> moveToTrash(int id) {
    return (update(bookmarks)..where((b) => b.id.equals(id))).write(
        BookmarksCompanion(
            isDeleted: const Value(true), deletedAt: Value(DateTime.now())));
  }

  // Restore from trash
  Future<void> restoreFromTrash(int id) {
    return (update(bookmarks)..where((b) => b.id.equals(id))).write(
        const BookmarksCompanion(
            isDeleted: Value(false), deletedAt: Value(null)));
  }

  // Permanently delete
  Future<void> permanentlyDelete(int id) {
    return (delete(bookmarks)..where((b) => b.id.equals(id))).go();
  }

  // Archive
  Future<void> archiveBookmark(int id) {
    return (update(bookmarks)..where((b) => b.id.equals(id)))
        .write(const BookmarksCompanion(isArchived: Value(true)));
  }

  // Unarchive
  Future<void> unarchiveBookmark(int id) {
    return (update(bookmarks)..where((b) => b.id.equals(id)))
        .write(const BookmarksCompanion(isArchived: Value(false)));
  }



  // Mark as read (not unread)
  Future<void> markAsRead(int id) {
    return (update(bookmarks)..where((b) => b.id.equals(id)))
        .write(const BookmarksCompanion(isUnread: Value(false)));
  }

  // Record visit
  Future<void> recordVisit(int id, {bool markAsRead = false}) {
    return transaction(() async {
      final bookmark = await getBookmarkById(id);
      final companion = BookmarksCompanion(
          visitCount: Value(bookmark.visitCount + 1),
          lastOpenedAt: Value(DateTime.now()));
          
      await (update(bookmarks)..where((b) => b.id.equals(id))).write(
          markAsRead ? companion.copyWith(isUnread: const Value(false)) : companion);
    });
  }

  // Find by URL (for duplicate detection)
  Future<Bookmark?> findByUrl(String url) {
    return (select(bookmarks)..where((b) => b.url.equals(url)))
        .getSingleOrNull();
  }

  // Search bookmarks
  Future<List<Bookmark>> searchBookmarks(String query) {
    final pattern = '%$query%';
    return (select(bookmarks)
          ..where((b) =>
              b.isDeleted.equals(false) &
              b.isArchived.equals(false) &
              (b.title.like(pattern) |
                  b.url.like(pattern) |
                  b.domain.like(pattern) |
                  b.notesPlainText.like(pattern)))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // Get all active bookmarks (for dead link checking)
  Future<List<Bookmark>> getAllActiveBookmarks() {
    return (select(bookmarks)
          ..where(
              (b) => b.isDeleted.equals(false)))
        .get();
  }

  // Update dead status
  Future<void> updateDeadStatus(
      int id, bool isDead, int failCount) {
    return (update(bookmarks)..where((b) => b.id.equals(id))).write(
        BookmarksCompanion(
            isDead: Value(isDead),
            deadCheckFailCount: Value(failCount)));
  }

  // Purge old trash
  Future<int> purgeOldTrash(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(bookmarks)
          ..where((b) =>
              b.isDeleted.equals(true) &
              b.deletedAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  // Empty trash
  Future<int> emptyTrash() {
    return (delete(bookmarks)..where((b) => b.isDeleted.equals(true))).go();
  }

  // Get domain summaries
  Future<List<DomainSummaryData>> getDomainSummaries() async {
    final query = customSelect(
      'SELECT domain, '
      'COUNT(*) as bookmark_count, '
      'SUM(visit_count) as total_visits, '
      'MAX(created_at) as latest_created, '
      'MIN(favicon_url) as favicon_url '
      'FROM bookmarks '
      'WHERE is_deleted = 0 AND is_archived = 0 '
      'GROUP BY domain '
      'ORDER BY bookmark_count DESC',
      readsFrom: {bookmarks},
    );
    final rows = await query.get();
    return rows
        .map((row) => DomainSummaryData(
              domain: row.read<String>('domain'),
              bookmarkCount: row.read<int>('bookmark_count'),
              totalVisits: row.read<int>('total_visits'),
              latestCreated:
                  DateTime.fromMillisecondsSinceEpoch(row.read<int>('latest_created') * 1000),
              faviconUrl: row.readNullable<String>('favicon_url'),
            ))
        .toList();
  }

  // Get bookmarks by domain
  Stream<List<Bookmark>> watchBookmarksByDomain(String domain) {
    return (select(bookmarks)
          ..where((b) =>
              b.domain.equals(domain) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..orderBy([
            (b) =>
                OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // Update notes
  Future<void> updateNotes(int id, String? notes, String? plainText) {
    return (update(bookmarks)..where((b) => b.id.equals(id))).write(
        BookmarksCompanion(
            notes: Value(notes), notesPlainText: Value(plainText)));
  }

  // Move to folder
  Future<void> moveToFolder(int bookmarkId, int? folderId) {
    return (update(bookmarks)..where((b) => b.id.equals(bookmarkId)))
        .write(BookmarksCompanion(folderId: Value(folderId)));
  }

  // Bulk operations
  Future<void> bulkMoveToFolder(List<int> ids, int? folderId) {
    return (update(bookmarks)..where((b) => b.id.isIn(ids)))
        .write(BookmarksCompanion(folderId: Value(folderId)));
  }

  Future<void> bulkDelete(List<int> ids) {
    return (update(bookmarks)..where((b) => b.id.isIn(ids))).write(
        BookmarksCompanion(
            isDeleted: const Value(true), deletedAt: Value(DateTime.now())));
  }

  Future<void> bulkArchive(List<int> ids) {
    return (update(bookmarks)..where((b) => b.id.isIn(ids)))
        .write(const BookmarksCompanion(isArchived: Value(true)));
  }



  Future<void> bulkMarkRead(List<int> ids) {
    return (update(bookmarks)..where((b) => b.id.isIn(ids)))
        .write(const BookmarksCompanion(isUnread: Value(false)));
  }

  Future<void> bulkMarkUnread(List<int> ids) {
    return (update(bookmarks)..where((b) => b.id.isIn(ids)))
        .write(const BookmarksCompanion(isUnread: Value(true)));
  }

  // ─── Folder Queries ───────────────────────────────────

  Stream<List<Folder>> watchAllFolders() {
    return (select(folders)
          ..orderBy([
            (f) => OrderingTerm(
                expression: f.displayOrder, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  Future<List<Folder>> getAllFolders() {
    return (select(folders)
          ..orderBy([
            (f) => OrderingTerm(
                expression: f.displayOrder, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> insertFolder(FoldersCompanion entry) {
    return into(folders).insert(entry);
  }

  Future<bool> updateFolder(FoldersCompanion entry) {
    return (update(folders)..where((f) => f.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<void> deleteFolder(int id) {
    return (delete(folders)..where((f) => f.id.equals(id))).go();
  }

  Future<int> getBookmarkCountForFolder(int folderId) async {
    final count = bookmarks.id.count();
    final query = selectOnly(bookmarks)
      ..addColumns([count])
      ..where(bookmarks.folderId.equals(folderId) &
          bookmarks.isDeleted.equals(false) &
          bookmarks.isArchived.equals(false));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ─── Tag Queries ──────────────────────────────────────

  Future<List<Tag>> getAllTags() => select(tags).get();

  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  Future<int> insertTag(String name) {
    return into(tags).insert(TagsCompanion(name: Value(name)));
  }

  Future<Tag?> findTagByName(String name) {
    return (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<int> getOrCreateTag(String name) async {
    final existing = await findTagByName(name);
    if (existing != null) return existing.id;
    return insertTag(name);
  }

  Future<List<Tag>> getTagsForBookmark(int bookmarkId) {
    final query = select(tags).join([
      innerJoin(
          bookmarkTagJoin, bookmarkTagJoin.tagId.equalsExp(tags.id)),
    ])
      ..where(bookmarkTagJoin.bookmarkId.equals(bookmarkId));
    return query.map((row) => row.readTable(tags)).get();
  }

  Future<void> setTagsForBookmark(int bookmarkId, List<String> tagNames) {
    return transaction(() async {
      await (delete(bookmarkTagJoin)
            ..where((j) => j.bookmarkId.equals(bookmarkId)))
          .go();
      for (final name in tagNames) {
        final tagId = await getOrCreateTag(name.trim());
        await into(bookmarkTagJoin).insert(BookmarkTagJoinCompanion(
            bookmarkId: Value(bookmarkId), tagId: Value(tagId)));
      }
    });
  }

  // ─── Relation Queries ─────────────────────────────────

  Future<List<Bookmark>> getBacklinksTo(int bookmarkId) async {
    final query = select(bookmarks).join([
      innerJoin(bookmarkRelations,
          bookmarkRelations.sourceId.equalsExp(bookmarks.id)),
    ])
      ..where(bookmarkRelations.targetId.equals(bookmarkId) &
          bookmarkRelations.relationType.equals('backlink') &
          bookmarks.isDeleted.equals(false));
    return query.map((row) => row.readTable(bookmarks)).get();
  }

  Future<void> updateBacklinks(
      int sourceId, List<int> targetIds) {
    return transaction(() async {
      await (delete(bookmarkRelations)
            ..where((r) =>
                r.sourceId.equals(sourceId) &
                r.relationType.equals('backlink')))
          .go();
      for (final targetId in targetIds) {
        await into(bookmarkRelations).insert(BookmarkRelationsCompanion(
            sourceId: Value(sourceId),
            targetId: Value(targetId),
            relationType: const Value('backlink')));
      }
    });
  }

  // Get related bookmarks (same domain, shared tags, same folder)
  Future<List<Bookmark>> getRelatedBookmarks(int bookmarkId,
      {int limit = 5}) async {
    final bookmark = await getBookmarkById(bookmarkId);

    // Same domain
    final sameDomain = await (select(bookmarks)
          ..where((b) =>
              b.domain.equals(bookmark.domain) &
              b.id.isNotValue(bookmarkId) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false))
          ..limit(limit))
        .get();

    // Same folder
    List<Bookmark> sameFolder = [];
    if (bookmark.folderId != null) {
      sameFolder = await (select(bookmarks)
            ..where((b) =>
                b.folderId.equals(bookmark.folderId!) &
                b.id.isNotValue(bookmarkId) &
                b.isDeleted.equals(false) &
                b.isArchived.equals(false))
            ..limit(limit))
          .get();
    }

    // Merge and deduplicate
    final seen = <int>{};
    final result = <Bookmark>[];
    for (final b in [...sameDomain, ...sameFolder]) {
      if (seen.add(b.id) && result.length < limit) {
        result.add(b);
      }
    }
    return result;
  }

  // ─── Recent Searches ──────────────────────────────────

  Stream<List<RecentSearche>> watchRecentSearches() {
    return (select(recentSearches)
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(10))
        .watch();
  }

  Future<void> addRecentSearch(String query) {
    return transaction(() async {
      // Remove duplicates
      await (delete(recentSearches)
            ..where((s) => s.query.equals(query)))
          .go();
      await into(recentSearches).insert(RecentSearchesCompanion(
          query: Value(query), createdAt: Value(DateTime.now())));
      // Keep max 10
      final all = await (select(recentSearches)
            ..orderBy([
              (s) => OrderingTerm(
                  expression: s.createdAt, mode: OrderingMode.desc)
            ]))
          .get();
      if (all.length > 10) {
        final toDelete = all.sublist(10);
        for (final s in toDelete) {
          await (delete(recentSearches)..where((r) => r.id.equals(s.id))).go();
        }
      }
    });
  }

  Future<void> deleteRecentSearch(int id) {
    return (delete(recentSearches)..where((s) => s.id.equals(id))).go();
  }

  Future<void> clearRecentSearches() {
    return delete(recentSearches).go();
  }

  // ─── Statistics ───────────────────────────────────────

  Future<Map<String, int>> getStatistics() async {
    final all = await (select(bookmarks)
          ..where((b) => b.isDeleted.equals(false) & b.isArchived.equals(false)))
        .get();
    final archived = await (select(bookmarks)
          ..where((b) => b.isArchived.equals(true) & b.isDeleted.equals(false)))
        .get();

    int totalFavorites = all.where((b) => b.isFavorite).length;
    int totalUnread = all.where((b) => b.isUnread).length;
    int totalDead = all.where((b) => b.isDead).length;
    int totalArchived = archived.length;

    final allFolders = await getAllFolders();
    final allTags = await getAllTags();

    return {
      'total': all.length,
      'favorites': totalFavorites,
      'unread': totalUnread,
      'dead': totalDead,
      'archived': totalArchived,
      'folders': allFolders.length,
      'tags': allTags.length,
    };
  }

  // Get total unread reading time
  Future<int> getTotalUnreadReadingTime() async {
    final all = await (select(bookmarks)
          ..where((b) =>
              b.isUnread.equals(true) &
              b.isDeleted.equals(false) &
              b.isArchived.equals(false)))
        .get();
    return all.fold<int>(
        0, (sum, b) => sum + (b.estimatedReadingTimeMinutes ?? 0));
  }

  // Count bookmarks for all folders (map of folderId -> count)
  Future<Map<int, int>> getFolderBookmarkCounts() async {
    final results = await customSelect(
      'SELECT folder_id, COUNT(*) as cnt FROM bookmarks '
      'WHERE is_deleted = 0 AND is_archived = 0 AND folder_id IS NOT NULL '
      'GROUP BY folder_id',
      readsFrom: {bookmarks},
    ).get();
    final map = <int, int>{};
    for (final row in results) {
      map[row.read<int>('folder_id')] = row.read<int>('cnt');
    }
    return map;
  }

  // Watch count of bookmarks for all folders
  Stream<Map<int, int>> watchFolderBookmarkCounts() {
    return customSelect(
      'SELECT folder_id, COUNT(*) as cnt FROM bookmarks '
      'WHERE is_deleted = 0 AND is_archived = 0 AND folder_id IS NOT NULL '
      'GROUP BY folder_id',
      readsFrom: {bookmarks},
    ).watch().map((rows) {
      final map = <int, int>{};
      for (final row in rows) {
        map[row.read<int>('folder_id')] = row.read<int>('cnt');
      }
      return map;
    });
  }

  // Get all data for export
  Future<Map<String, dynamic>> exportAllData() async {
    final allBookmarks = await select(bookmarks).get();
    final allFolders = await select(folders).get();
    final allTags = await select(tags).get();
    final allJoins = await select(bookmarkTagJoin).get();
    final allRelations = await select(bookmarkRelations).get();

    return {
      'bookmarks': allBookmarks
          .map((b) => {
                'id': b.id,
                'title': b.title,
                'url': b.url,
                'domain': b.domain,
                'pageDescription': b.pageDescription,
                'notes': b.notes,
                'notesPlainText': b.notesPlainText,
                'faviconUrl': b.faviconUrl,
                'previewImageUrl': b.previewImageUrl,
                'folderId': b.folderId,
                'isFavorite': b.isFavorite,
                'isArchived': b.isArchived,
                'isDeleted': b.isDeleted,
                'isUnread': b.isUnread,

                'isDead': b.isDead,
                'deadCheckFailCount': b.deadCheckFailCount,
                'estimatedReadingTimeMinutes': b.estimatedReadingTimeMinutes,
                'estimatedWordCount': b.estimatedWordCount,
                'createdAt': b.createdAt.toIso8601String(),
                'lastOpenedAt': b.lastOpenedAt?.toIso8601String(),
                'deletedAt': b.deletedAt?.toIso8601String(),
                'visitCount': b.visitCount,
                'customOrder': b.customOrder,
              })
          .toList(),
      'folders': allFolders
          .map((f) => {
                'id': f.id,
                'name': f.name,
                'colorHex': f.colorHex,
                'icon': f.icon,
                'displayOrder': f.displayOrder,
              })
          .toList(),
      'tags': allTags.map((t) => {'id': t.id, 'name': t.name}).toList(),
      'bookmarkTagJoins': allJoins
          .map((j) => {'bookmarkId': j.bookmarkId, 'tagId': j.tagId})
          .toList(),
      'bookmarkRelations': allRelations
          .map((r) => {
                'id': r.id,
                'sourceId': r.sourceId,
                'targetId': r.targetId,
                'relationType': r.relationType,
              })
          .toList(),
    };
  }

  // Clear all data
  Future<void> clearAllData() {
    return transaction(() async {
      await delete(bookmarkRelations).go();
      await delete(bookmarkTagJoin).go();
      await delete(recentSearches).go();
      await delete(bookmarks).go();
      await delete(tags).go();
      await delete(folders).go();
    });
  }
}

// ─── Domain Summary Data Class ────────────────────────────

class DomainSummaryData {
  final String domain;
  final int bookmarkCount;
  final int totalVisits;
  final DateTime latestCreated;
  final String? faviconUrl;

  DomainSummaryData({
    required this.domain,
    required this.bookmarkCount,
    required this.totalVisits,
    required this.latestCreated,
    this.faviconUrl,
  });
}

// ─── Database Connection ──────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'atlas.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
