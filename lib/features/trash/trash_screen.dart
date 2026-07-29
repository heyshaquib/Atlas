import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          TextButton(
            child: Text('Empty Trash',
                style: TextStyle(color: cs.error)),
            onPressed: () => _confirmEmptyTrash(context, db),
          ),
        ],
      ),
      body: StreamBuilder<List<Bookmark>>(
        stream: db.watchTrash(),
        builder: (context, snapshot) {
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline,
                      size: 80, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Trash is empty', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text('Deleted bookmarks appear here',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms);
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final bm = list[i];
              final daysLeft = _daysUntilDeletion(bm.deletedAt);
              return Dismissible(
                key: ValueKey('trash-${bm.id}'),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  color: Colors.green.withValues(alpha: 0.2),
                  child: const Icon(Icons.restore, color: Colors.green),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: cs.error.withValues(alpha: 0.2),
                  child: Icon(Icons.delete_forever, color: cs.error),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await db.restoreFromTrash(bm.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restored')));
                    }
                  } else {
                    final confirm = await _confirmPermanentDelete(context);
                    if (confirm == true) {
                      await db.permanentlyDelete(bm.id);
                    }
                  }
                  return false;
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(bm.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      daysLeft > 0
                          ? 'Deletes in $daysLeft days'
                          : 'Pending deletion',
                      style: tt.labelSmall?.copyWith(
                          color: daysLeft <= 3 ? cs.error : cs.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: 'Restore',
                          onPressed: () async {
                            await db.restoreFromTrash(bm.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Restored')));
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: cs.error),
                          tooltip: 'Delete permanently',
                          onPressed: () async {
                            final confirm =
                                await _confirmPermanentDelete(context);
                            if (confirm == true) {
                              await db.permanentlyDelete(bm.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: i * 40)).fadeIn();
            },
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  int _daysUntilDeletion(DateTime? deletedAt) {
    if (deletedAt == null) return 30;
    const retentionDays = 30;
    final daysSince = DateTime.now().difference(deletedAt).inDays;
    return (retentionDays - daysSince).clamp(0, retentionDays);
  }

  Future<bool?> _confirmPermanentDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, dynamic db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
            'All items in trash will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await db.emptyTrash();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trash emptied')));
              }
            },
            child: Text('Empty',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
