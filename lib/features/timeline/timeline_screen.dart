import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/features/timeline/timeline_provider.dart';
import 'package:atlas/features/bookmarks/widgets/bookmark_card.dart';
import 'package:atlas/features/details/bookmark_details_screen.dart';
import 'package:atlas/core/widgets/custom_chip.dart';
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  static const _filterLabels = {
    BookmarkFilter.all: 'All',
    BookmarkFilter.unread: 'Unread',
    BookmarkFilter.favorites: 'Favorites',

  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(timelineFilterProvider);
    final timeline = ref.watch(timelineBookmarksProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterLabels.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CustomChip(
                      label: e.value,
                      isSelected: filter == e.key,
                      onTap: () => ref.read(timelineFilterProvider.notifier).state = e.key,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Timeline content
          Expanded(
            child: timeline.when(
              data: (grouped) {
                if (grouped.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timeline,
                            size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No bookmarks in this view'),
                      ],
                    ),
                  );
                }
                return CustomScrollView(
                  slivers: grouped.entries.expand((entry) {
                    return [
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          color: cs.surfaceContainerHigh,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(entry.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: entry.value.length,
                        itemBuilder: (ctx, i) {
                          final bm = entry.value[i];
                          return BookmarkCard(
                            bookmark: bm,
                            viewMode: ViewMode.list,
                            index: i,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookmarkDetailsScreen(
                                    bookmarkId: bm.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ];
                  }).toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
