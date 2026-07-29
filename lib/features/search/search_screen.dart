import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/features/search/search_provider.dart';
import 'package:atlas/features/bookmarks/widgets/bookmark_card.dart';
import 'package:atlas/features/details/bookmark_details_screen.dart';
import 'package:atlas/features/domain_hub/domain_hub_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {

    final query = ref.watch(searchQueryProvider);
    final db = ref.read(databaseProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search bookmarks...',
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.search),
                ),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    ),
                ],
                onChanged: _onSearchChanged,
                onSubmitted: (q) {
                  if (q.trim().isNotEmpty) {
                    db.addRecentSearch(q.trim());
                  }
                },
              ),
            ),

            // Content
            Expanded(
              child: query.isEmpty
                  ? _buildEmptySearch(context, ref)
                  : _buildSearchResults(context, ref),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptySearch(BuildContext context, WidgetRef ref) {
    final recentSearches = ref.watch(recentSearchesStreamProvider);
    final db = ref.read(databaseProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: recentSearches.when(
            data: (searches) {
              if (searches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 64, color: cs.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Search your bookmarks',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                );
              }
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Recent Searches',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  ...searches.map((s) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(s.query),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => db.deleteRecentSearch(s.id),
                        ),
                        onTap: () {
                          _searchController.text = s.query;
                          ref.read(searchQueryProvider.notifier).state =
                              s.query;
                        },
                      )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.language),
            label: const Text('Browse by Domain'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DomainHubScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    return results.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No results found',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
