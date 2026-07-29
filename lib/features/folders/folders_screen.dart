import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/features/folders/folders_provider.dart';
import 'package:atlas/features/folders/folder_editor_dialog.dart';
import 'package:atlas/features/bookmarks/widgets/bookmark_card.dart';
import 'package:atlas/features/details/bookmark_details_screen.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  static IconData _mapIcon(String iconName) {
    switch (iconName) {
      case 'schedule': return Icons.schedule;
      case 'mark_email_unread': return Icons.mark_email_unread;
      case 'bookmark': return Icons.bookmark;
      case 'trending_up': return Icons.trending_up;
      case 'history': return Icons.history;
      case 'link_off': return Icons.link_off;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'favorite': return Icons.favorite;
      case 'star': return Icons.star;
      case 'code': return Icons.code;
      case 'science': return Icons.science;
      case 'music_note': return Icons.music_note;
      case 'sports': return Icons.sports_soccer;
      case 'flight': return Icons.flight;
      case 'restaurant': return Icons.restaurant;
      case 'fitness': return Icons.fitness_center;
      case 'book': return Icons.book;
      case 'shopping': return Icons.shopping_bag;
      case 'health': return Icons.local_hospital;
      case 'camera': return Icons.photo_camera;
      default: return Icons.folder;
    }
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse(cleaned, radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF3D5A80);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(smartCollectionCountsProvider);
    final folders = ref.watch(foldersStreamProvider);
    final folderCounts = ref.watch(folderCountsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Collections
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Smart Collections', style: tt.titleSmall),
            ),
            SizedBox(
              height: 110,
              child: collections.when(
                data: (list) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final c = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _SmartCollectionPage(collection: c),
                          ),
                        ),
                        borderRadius: kShapeTokens.small,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_mapIcon(c.iconName), size: 28,
                                  color: cs.primary),
                              const SizedBox(height: 6),
                              Text(c.name, style: tt.labelSmall),
                              const SizedBox(height: 2),
                              Text('${c.count}',
                                  style: outfitStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary)),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: i * 60))
                        .fadeIn()
                        .scale(begin: const Offset(0.8, 0.8));
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),

            // My Folders header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('My Folders', style: tt.titleSmall),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Folder grid
            folders.when(
              data: (folderList) {
                final counts = folderCounts.value ?? {};
                if (folderList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.folder_outlined,
                              size: 64, color: cs.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('No folders yet', style: tt.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: folderList.length,
                  itemBuilder: (ctx, i) {
                    final folder = folderList[i];
                    final color = _parseColor(folder.colorHex);
                    final count = counts[folder.id] ?? 0;
                    return Card(
                      color: color.withValues(alpha: 0.15),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _FolderBookmarksPage(folder: folder),
                          ),
                        ),
                        onLongPress: () =>
                            FolderEditorDialog.show(context, folder: folder),
                        borderRadius: kShapeTokens.small,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_mapIcon(folder.icon), size: 32, color: color),
                              const SizedBox(height: 8),
                              Text(folder.name, style: tt.titleSmall,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('$count',
                                  style: outfitStyle(
                                      fontSize: 14, color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate(delay: Duration(milliseconds: i * 50))
                        .fadeIn()
                        .scale(begin: const Offset(0.9, 0.9));
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_folder',
        onPressed: () => FolderEditorDialog.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Smart collection sub-page
class _SmartCollectionPage extends ConsumerWidget {
  final SmartCollection collection;
  const _SmartCollectionPage({required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    Stream<List<Bookmark>> stream;
    switch (collection.type) {
      case SmartCollectionType.recentlyAdded:
        stream = db.watchRecentlyAdded();
        break;
      case SmartCollectionType.unread:
        stream = db.watchUnread();
        break;

      case SmartCollectionType.mostVisited:
        stream = db.watchMostVisited();
        break;
      case SmartCollectionType.recentlyOpened:
        stream = db.watchRecentlyOpened();
        break;
      case SmartCollectionType.deadLinks:
        stream = db.watchDeadLinks();
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: StreamBuilder<List<Bookmark>>(
        stream: stream,
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
    );
  }
}

// Folder bookmarks sub-page
class _FolderBookmarksPage extends ConsumerWidget {
  final Folder folder;
  const _FolderBookmarksPage({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return Scaffold(
      appBar: AppBar(title: Text(folder.name)),
      body: StreamBuilder<List<Bookmark>>(
        stream: db.watchBookmarksByFolder(folder.id),
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
                  builder: (_) =>
                      BookmarkDetailsScreen(bookmarkId: list[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
