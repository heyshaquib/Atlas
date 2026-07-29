import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/utils/utils.dart';

final timelineFilterProvider = NotifierProvider<TimelineFilterNotifier, BookmarkFilter>(TimelineFilterNotifier.new);

class TimelineFilterNotifier extends Notifier<BookmarkFilter> {
  @override
  BookmarkFilter build() => BookmarkFilter.all;
  @override
  set state(BookmarkFilter value) => super.state = value;
}

final timelineBookmarksProvider =
    StreamProvider<Map<String, List<Bookmark>>>((ref) {
  final db = ref.watch(databaseProvider);
  final filter = ref.watch(timelineFilterProvider);

  Stream<List<Bookmark>> stream;
  switch (filter) {
    case BookmarkFilter.unread:
      stream = db.watchUnread();
      break;
    case BookmarkFilter.favorites:
      stream = db.watchFavorites();
      break;

    default:
      stream = db.watchAllBookmarks();
  }

  return stream.map((bookmarks) {
    const order = ['Today', 'Yesterday', 'This Week', 'This Month', 'Earlier'];
    final grouped = <String, List<Bookmark>>{};
    for (final section in order) {
      grouped[section] = [];
    }
    for (final b in bookmarks) {
      final section = getTimelineSection(b.createdAt);
      grouped.putIfAbsent(section, () => []).add(b);
    }
    grouped.removeWhere((_, v) => v.isEmpty);
    return grouped;
  });
});
