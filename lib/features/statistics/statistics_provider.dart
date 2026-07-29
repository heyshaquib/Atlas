import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';

final statisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getStatistics();
});

final totalUnreadReadingTimeProvider = FutureProvider<int>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getTotalUnreadReadingTime();
});
