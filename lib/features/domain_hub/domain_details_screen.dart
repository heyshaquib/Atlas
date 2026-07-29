import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/features/bookmarks/widgets/bookmark_card.dart';
import 'package:atlas/features/details/bookmark_details_screen.dart';

class DomainDetailsScreen extends ConsumerWidget {
  final String domain;
  final String? faviconUrl;
  final int bookmarkCount;
  final int totalVisits;

  const DomainDetailsScreen({
    super.key,
    required this.domain,
    this.faviconUrl,
    required this.bookmarkCount,
    required this.totalVisits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(domain)),
      body: Column(
        children: [
          // Header card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: faviconUrl ?? getFaviconUrl(domain),
                    width: 48,
                    height: 48,
                    errorWidget: (_, _, _) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.language, color: cs.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(domain, style: tt.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          '$bookmarkCount bookmarks · $totalVisits visits',
                          style: outfitStyle(
                              fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('All Bookmarks', style: tt.titleSmall),
            ),
          ),
          const SizedBox(height: 8),

          // Bookmarks list
          Expanded(
            child: StreamBuilder<List<Bookmark>>(
              stream: db.watchBookmarksByDomain(domain),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('No bookmarks'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => BookmarkCard(
                    bookmark: list[i],
                    viewMode: ViewMode.list,
                    index: i,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookmarkDetailsScreen(bookmarkId: list[i].id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
