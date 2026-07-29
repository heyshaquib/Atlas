import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String value) => super.state = value;
}

final searchResultsProvider = FutureProvider<List<Bookmark>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final db = ref.read(databaseProvider);
  return db.searchBookmarks(query);
});

final recentSearchesStreamProvider = StreamProvider<List<RecentSearche>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentSearches();
});
