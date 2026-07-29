import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/bookmarks/bookmarks_provider.dart';
import 'package:atlas/features/bookmarks/widgets/bookmark_card.dart';
import 'package:atlas/features/bookmarks/widgets/filter_chips.dart';
import 'package:atlas/core/widgets/custom_chip.dart';
import 'package:atlas/features/bookmarks/widgets/folder_chip_row.dart';
import 'package:atlas/features/bookmarks/widgets/bulk_action_bar.dart';
import 'package:atlas/features/bookmarks/add_edit_bookmark_sheet.dart';
import 'package:atlas/features/details/bookmark_details_screen.dart';
import 'package:atlas/features/timeline/timeline_screen.dart';
import 'package:atlas/features/statistics/statistics_screen.dart';
import 'package:atlas/features/domain_hub/domain_hub_screen.dart';
import 'package:atlas/features/archive/archive_screen.dart';
import 'package:atlas/features/trash/trash_screen.dart';
import 'package:atlas/features/settings/settings_screen.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(viewModeProvider);
    final selected = ref.watch(selectedBookmarksProvider);
    final bookmarks = ref.watch(bookmarksStreamProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Atlas', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_viewModeIcon(viewMode)),
            tooltip: 'Switch view',
            onPressed: () => ref.read(viewModeProvider.notifier).cycle(),
          ),
          MenuAnchor(
            alignmentOffset: const Offset(-120, 0),
            style: MenuStyle(
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
            clipBehavior: Clip.antiAlias,
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: [
              MenuItemButton(
                style: const ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero))),
                leadingIcon: const Icon(Icons.sort, size: 22),
                onPressed: () => _handleMenuAction('sort'),
                child: const Text('Sort by'),
              ),
              const Divider(height: 1),
              MenuItemButton(
                style: const ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero))),
                leadingIcon: const Icon(Icons.timeline, size: 22),
                onPressed: () => _handleMenuAction('timeline'),
                child: const Text('Timeline'),
              ),
              MenuItemButton(
                style: const ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero))),
                leadingIcon: const Icon(Icons.bar_chart, size: 22),
                onPressed: () => _handleMenuAction('statistics'),
                child: const Text('Statistics'),
              ),
              MenuItemButton(
                style: const ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero))),
                leadingIcon: const Icon(Icons.public, size: 22),
                onPressed: () => _handleMenuAction('domain_hub'),
                child: const Text('Domain Hub'),
              ),
              const Divider(height: 1),
              MenuItemButton(
                style: const ButtonStyle(shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero))),
                leadingIcon: const Icon(Icons.delete_outline, size: 22),
                onPressed: () => _handleMenuAction('trash'),
                child: const Text('Trash'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const BookmarkFilterChips(),
                  CustomChip(
                    label: 'Archive',
                    isSelected: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArchiveScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FolderChipRow(
                onFolderSelected: (id, name) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FolderBookmarksPage(folderId: id, folderName: name),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: bookmarks.when(
              data: (list) => list.isEmpty
                  ? _buildEmptyState()
                  : _buildBookmarkView(list, viewMode),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: selected.isNotEmpty ? const BulkActionBar() : null,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab',
        onPressed: () => AddEditBookmarkSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookmarkView(List<Bookmark> bookmarks, ViewMode mode) {
    final selected = ref.watch(selectedBookmarksProvider);
    final isMulti = selected.isNotEmpty;
    final db = ref.read(databaseProvider);

    switch (mode) {
      case ViewMode.list:
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: bookmarks.length,
          itemBuilder: (ctx, i) => _buildCard(bookmarks[i], ViewMode.list, i,
              selected, isMulti, db),
        );
      case ViewMode.grid:
        return AlignedGridView.count(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: bookmarks.length,
          itemBuilder: (ctx, i) => _buildCard(bookmarks[i], ViewMode.grid, i,
              selected, isMulti, db),
        );
      case ViewMode.masonry:
        return MasonryGridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2),
          itemCount: bookmarks.length,
          itemBuilder: (ctx, i) => _buildCard(bookmarks[i], ViewMode.masonry,
              i, selected, isMulti, db),
        );
    }
  }

  Widget _buildCard(Bookmark bm, ViewMode mode, int index,
      Set<int> selected, bool isMulti, AppDatabase db) {
    return BookmarkCard(
      bookmark: bm,
      viewMode: mode,
      index: index,
      isSelected: selected.contains(bm.id),
      isMultiSelectMode: isMulti,
      onTap: () {
        if (isMulti) {
          ref.read(selectedBookmarksProvider.notifier).toggle(bm.id);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookmarkDetailsScreen(bookmarkId: bm.id),
            ),
          );
        }
      },
      onLongPress: () =>
          ref.read(selectedBookmarksProvider.notifier).toggle(bm.id),
      onFavoriteToggled: (fav) => db.toggleFavorite(bm.id, fav),
      onDelete: () async {
        await db.moveToTrash(bm.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Moved to trash'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => db.restoreFromTrash(bm.id),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmarks_outlined, size: 80, color: cs.secondary),
          const SizedBox(height: 16),
          Text('No bookmarks yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tap + to add your first one',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  IconData _viewModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.list:
        return Icons.view_list;
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.masonry:
        return Icons.dashboard;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'timeline':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TimelineScreen()));
        break;
      case 'statistics':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()));
        break;
      case 'domain_hub':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DomainHubScreen()));
        break;
      case 'trash':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TrashScreen()));
        break;
      case 'sort':
        _showSortDialog();
        break;
    }
  }

  void _showSortDialog() {
    final currentSort = ref.read(sortOptionProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Sort by',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...SortOption.values.map((s) {
                    final isSelected = s == currentSort;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(
                        s.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(sortOptionProvider.notifier).state = s;
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Simple folder bookmarks sub-page
class _FolderBookmarksPage extends ConsumerWidget {
  final int folderId;
  final String folderName;
  const _FolderBookmarksPage({required this.folderId, required this.folderName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: Text(folderName)),
      body: StreamBuilder<List<Bookmark>>(
        stream: db.watchBookmarksByFolder(folderId),
        builder: (context, snapshot) {
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No bookmarks in this folder'));
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
                  builder: (_) => BookmarkDetailsScreen(bookmarkId: list[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
