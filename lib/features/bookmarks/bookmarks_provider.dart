import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';

final bookmarkFilterProvider = NotifierProvider<BookmarkFilterNotifier, BookmarkFilter>(BookmarkFilterNotifier.new);

class BookmarkFilterNotifier extends Notifier<BookmarkFilter> {
  @override
  BookmarkFilter build() => BookmarkFilter.all;
  @override
  set state(BookmarkFilter value) => super.state = value;
}

final sortOptionProvider = NotifierProvider<SortOptionNotifier, SortOption>(SortOptionNotifier.new);

class SortOptionNotifier extends Notifier<SortOption> {
  @override
  SortOption build() => SortOption.dateNewest;
  @override
  set state(SortOption value) => super.state = value;
}

final bookmarksStreamProvider = StreamProvider<List<Bookmark>>((ref) {
  final db = ref.watch(databaseProvider);
  final filter = ref.watch(bookmarkFilterProvider);
  Stream<List<Bookmark>> stream;
  switch (filter) {
    case BookmarkFilter.all:
      stream = db.watchAllBookmarks();
      break;
    case BookmarkFilter.unread:
      stream = db.watchUnread();
      break;
    case BookmarkFilter.favorites:
      stream = db.watchFavorites();
      break;
    case BookmarkFilter.archived:
      stream = db.watchArchived();
      break;
  }

  final sort = ref.watch(sortOptionProvider);
  return stream.map((list) {
    final sorted = List<Bookmark>.from(list);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (sort) {
        case SortOption.dateNewest:
        case SortOption.dateOldest:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case SortOption.titleAZ:
        case SortOption.titleZA:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortOption.domainAZ:
        case SortOption.domainZA:
          cmp = a.domain.toLowerCase().compareTo(b.domain.toLowerCase());
          break;
        case SortOption.mostVisited:
          cmp = a.visitCount.compareTo(b.visitCount);
          break;
        case SortOption.shortestRead:
        case SortOption.longestRead:
          cmp = (a.estimatedReadingTimeMinutes ?? 0).compareTo(b.estimatedReadingTimeMinutes ?? 0);
          break;
      }
      return sort.ascending ? cmp : -cmp;
    });
    return sorted;
  });
});

class SelectedBookmarksNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  void selectAll(List<int> ids) => state = {...ids};
  void clear() => state = {};
}

final selectedBookmarksProvider =
    NotifierProvider<SelectedBookmarksNotifier, Set<int>>(
  SelectedBookmarksNotifier.new,
);

final recentlyOpenedProvider = StreamProvider<List<Bookmark>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentlyOpened(limit: 5);
});

final folderBookmarkCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getFolderBookmarkCounts();
});
