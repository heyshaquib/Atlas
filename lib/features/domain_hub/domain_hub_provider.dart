import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';

final domainSummariesProvider =
    FutureProvider<List<DomainSummaryData>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getDomainSummaries();
});

final domainSortProvider = NotifierProvider<DomainSortNotifier, String>(DomainSortNotifier.new);

class DomainSortNotifier extends Notifier<String> {
  @override
  String build() => 'bookmarks';
  @override
  set state(String value) => super.state = value;
}
final domainSearchQueryProvider = NotifierProvider<DomainSearchQueryNotifier, String>(DomainSearchQueryNotifier.new);

class DomainSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  @override
  set state(String value) => super.state = value;
}
