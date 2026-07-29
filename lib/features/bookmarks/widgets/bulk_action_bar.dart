import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/features/bookmarks/bookmarks_provider.dart';

class BulkActionBar extends ConsumerWidget {
  const BulkActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedBookmarksProvider);
    final db = ref.read(databaseProvider);
    final cs = Theme.of(context).colorScheme;

    if (selected.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 6,
      color: cs.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                '${selected.length} selected',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Mark read',
                icon: const Icon(Icons.mark_email_read),
                onPressed: () async {
                  await db.bulkMarkRead(selected.toList());
                  ref.read(selectedBookmarksProvider.notifier).clear();
                },
              ),

              IconButton(
                tooltip: 'Archive',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () async {
                  await db.bulkArchive(selected.toList());
                  ref.read(selectedBookmarksProvider.notifier).clear();
                },
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await db.bulkDelete(selected.toList());
                  ref.read(selectedBookmarksProvider.notifier).clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moved to trash')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
