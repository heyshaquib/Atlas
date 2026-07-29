import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/features/bookmarks/widgets/bookmark_card.dart';
import 'package:atlas/features/details/bookmark_details_screen.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
      ),
      body: StreamBuilder<List<Bookmark>>(
        stream: db.watchArchived(),
        builder: (context, snapshot) {
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.archive_outlined,
                      size: 80, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Archive is empty',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Archived bookmarks appear here',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms);
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) => _buildSwipeableCard(context, db, list[i], i, ViewMode.list, cs),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSwipeableCard(BuildContext context, AppDatabase db, Bookmark bookmark, int index, ViewMode viewMode, ColorScheme cs) {
    final card = BookmarkCard(
      bookmark: bookmark,
      viewMode: viewMode,
      index: index,
      disableSwipe: true,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookmarkDetailsScreen(bookmarkId: bookmark.id),
        ),
      ),
    );

    if (viewMode != ViewMode.list) {
      return card;
    }

    return Dismissible(
      key: ValueKey('archive-${bookmark.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green.withValues(alpha: 0.2),
        child: const Icon(Icons.unarchive, color: Colors.green),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error.withValues(alpha: 0.2),
        child: Icon(Icons.delete, color: cs.error),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await db.unarchiveBookmark(bookmark.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restored from archive')));
          }
          return false;
        } else {
          await db.moveToTrash(bookmark.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Moved to trash'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => db.restoreFromTrash(bookmark.id),
                ),
              ),
            );
          }
          return false;
        }
      },
      child: card,
    );
  }
}
