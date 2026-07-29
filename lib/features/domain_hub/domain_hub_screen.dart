import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/core/widgets/custom_chip.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/features/domain_hub/domain_hub_provider.dart';
import 'package:atlas/features/domain_hub/domain_details_screen.dart';

class DomainHubScreen extends ConsumerWidget {
  const DomainHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domains = ref.watch(domainSummariesProvider);
    final sortBy = ref.watch(domainSortProvider);
    final searchQuery = ref.watch(domainSearchQueryProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Domain Hub')),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search domains...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) =>
                  ref.read(domainSearchQueryProvider.notifier).state = v,
            ),
          ),

          // Sort chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SortChip('Most Bookmarks', 'bookmarks', sortBy, ref),
                  const SizedBox(width: 8),
                  _SortChip('Most Visited', 'visits', sortBy, ref),
                  const SizedBox(width: 8),
                  _SortChip('Most Recent', 'recent', sortBy, ref),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Domain list
          Expanded(
            child: domains.when(
              data: (list) {
                var filtered = list.where((d) => searchQuery.isEmpty ||
                    d.domain.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();

                switch (sortBy) {
                  case 'bookmarks':
                    filtered.sort((a, b) =>
                        b.bookmarkCount.compareTo(a.bookmarkCount));
                    break;
                  case 'visits':
                    filtered.sort(
                        (a, b) => b.totalVisits.compareTo(a.totalVisits));
                    break;
                  case 'recent':
                    filtered.sort((a, b) =>
                        b.latestCreated.compareTo(a.latestCreated));
                    break;
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language,
                            size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 16),
                        const Text('No domains found'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final d = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: getFaviconUrl(d.domain),
                            width: 40,
                            height: 40,
                            errorWidget: (_, _, _) => Container(
                              width: 40,
                              height: 40,
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.language,
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                        ),
                        title: Text(d.domain),
                        subtitle: Text(
                          '${d.bookmarkCount} bookmarks · ${d.totalVisits} visits',
                          style: outfitStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DomainDetailsScreen(
                              domain: d.domain,
                              faviconUrl: d.faviconUrl,
                              bookmarkCount: d.bookmarkCount,
                              totalVisits: d.totalVisits,
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: i * 30)).fadeIn();
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;
  const _SortChip(this.label, this.value, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      label: label,
      isSelected: current == value,
      onTap: () => ref.read(domainSortProvider.notifier).state = value,
    );
  }
}
