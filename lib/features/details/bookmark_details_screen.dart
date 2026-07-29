import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/features/details/details_provider.dart';
import 'package:atlas/features/bookmarks/widgets/reading_time_badge.dart';
import 'package:atlas/core/widgets/custom_chip.dart';
import 'package:atlas/features/bookmarks/add_edit_bookmark_sheet.dart';
import 'package:atlas/features/note_editor/note_editor_screen.dart';

class BookmarkDetailsScreen extends ConsumerWidget {
  final int bookmarkId;
  const BookmarkDetailsScreen({super.key, required this.bookmarkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookmarkDetailProvider(bookmarkId));
    final related = ref.watch(relatedBookmarksProvider(bookmarkId));
    final backlinks = ref.watch(backlinksProvider(bookmarkId));
    final tags = ref.watch(bookmarkTagsProvider(bookmarkId));
    final db = ref.read(databaseProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return detail.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (bookmark) => Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar with preview image
            SliverAppBar(
              expandedHeight:
                  bookmark.previewImageUrl != null ? 250 : null,
              pinned: true,
              flexibleSpace: bookmark.previewImageUrl != null
                  ? FlexibleSpaceBar(
                      background: CachedNetworkImage(
                        imageUrl: bookmark.previewImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(
                          color: cs.surfaceContainerHighest,
                        ),
                      ),
                    )
                  : null,
              title: bookmark.previewImageUrl == null
                  ? Text(bookmark.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              actions: [
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleAction(action, bookmark, db, context),
                  itemBuilder: (_) => [
                    if (bookmark.isArchived)
                      const PopupMenuItem(
                          value: 'unarchive', child: Text('Unarchive'))
                    else
                      const PopupMenuItem(
                          value: 'archive', child: Text('Archive')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'trash', child: Text('Move to Trash')),
                  ],
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Domain
                    Row(
                      children: [
                        CachedNetworkImage(
                          imageUrl: bookmark.faviconUrl ??
                              getFaviconUrl(bookmark.domain),
                          width: 32,
                          height: 32,
                          errorWidget: (_, _, _) => Icon(
                              Icons.language,
                              size: 24,
                              color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (bookmark.previewImageUrl != null)
                                Text(bookmark.title, style: tt.titleLarge),
                              const SizedBox(height: 4),
                              CustomChip(
                                label: bookmark.domain,
                                isSelected: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Open'),
                            onPressed: () {
                              final markAsRead = ref.read(markAsReadOnOpenProvider);
                              db.recordVisit(bookmark.id, markAsRead: markAsRead);
                              final browser = ref.read(browserChoiceProvider);
                              launchUrl(
                                Uri.parse(bookmark.url),
                                mode: browser == BrowserChoice.inApp
                                    ? LaunchMode.inAppBrowserView
                                    : LaunchMode.externalApplication,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                            onPressed: () =>
                                Share.share(bookmark.url),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy'),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: bookmark.url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('URL copied')),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            onPressed: () => AddEditBookmarkSheet.show(
                                context,
                                bookmark: bookmark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metadata Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bookmark.pageDescription != null) ...[
                              Text(bookmark.pageDescription!,
                                  style: tt.bodyMedium),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                ReadingTimeBadge(
                                    minutes: bookmark
                                        .estimatedReadingTimeMinutes),
                                if (bookmark.estimatedWordCount != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${formatNumber(bookmark.estimatedWordCount!)} words',
                                    style: outfitStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.visibility,
                                    size: 16, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('${bookmark.visitCount} visits',
                                    style: tt.labelSmall),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time,
                                    size: 16, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  bookmark.lastOpenedAt != null
                                      ? formatRelativeDate(
                                          bookmark.lastOpenedAt!)
                                      : 'Never opened',
                                  style: tt.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Added ${formatDate(bookmark.createdAt)}',
                                style: tt.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            tags.when(
                              data: (tagList) => tagList.isEmpty
                                  ? const SizedBox.shrink()
                                  : Wrap(
                                      spacing: 6,
                                      children: tagList
                                          .map((t) => CustomChip(
                                                label: t.name,
                                                isSelected: false,
                                              ))
                                          .toList(),
                                    ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes Card
                    Card(
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteEditorScreen(
                              bookmarkId: bookmark.id,
                              bookmarkTitle: bookmark.title,
                              initialNotesJson: bookmark.notes,
                            ),
                          ),
                        ),
                        borderRadius: kShapeTokens.small,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('My Notes', style: tt.titleSmall),
                                  const Spacer(),
                                  Icon(Icons.edit,
                                      size: 18, color: cs.onSurfaceVariant),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bookmark.notesPlainText?.isNotEmpty == true
                                    ? bookmark.notesPlainText!
                                    : 'Tap to add notes about this bookmark',
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: bookmark.notesPlainText?.isNotEmpty ==
                                          true
                                      ? null
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),



                    // Related Bookmarks
                    related.when(
                      data: (list) => list.isEmpty
                          ? const SizedBox.shrink()
                          : _buildRelatedSection(
                              context, 'Related Bookmarks', list),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // Backlinks
                    backlinks.when(
                      data: (list) => list.isEmpty
                          ? const SizedBox.shrink()
                          : _buildRelatedSection(
                              context, 'Referenced By', list),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // Dead Link Recovery
                    if (bookmark.isDead) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.amber.withValues(alpha: 0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      color: Colors.amber.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This link may no longer be available',
                                      style: tt.titleSmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.history),
                                label:
                                    const Text('Open Wayback Machine'),
                                onPressed: () {
                                  final markAsRead = ref.read(markAsReadOnOpenProvider);
                                  db.recordVisit(bookmark.id, markAsRead: markAsRead);
                                  final browser = ref.read(browserChoiceProvider);
                                  launchUrl(
                                    Uri.parse('https://web.archive.org/web/${bookmark.url}'),
                                    mode: browser == BrowserChoice.inApp
                                        ? LaunchMode.inAppBrowserView
                                        : LaunchMode.externalApplication,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.cached),
                                label:
                                    const Text('Search Cached Version'),
                                onPressed: () {
                                  final markAsRead = ref.read(markAsReadOnOpenProvider);
                                  db.recordVisit(bookmark.id, markAsRead: markAsRead);
                                  final browser = ref.read(browserChoiceProvider);
                                  launchUrl(
                                    Uri.parse('https://webcache.googleusercontent.com/search?q=cache:${bookmark.url}'),
                                    mode: browser == BrowserChoice.inApp
                                        ? LaunchMode.inAppBrowserView
                                        : LaunchMode.externalApplication,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Original URL'),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: bookmark.url));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('URL copied')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedSection(
      BuildContext context, String title, List list) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: tt.titleSmall),
        const SizedBox(height: 8),
        ...list.map((b) => ListTile(
              dense: true,
              leading: CachedNetworkImage(
                imageUrl: b.faviconUrl ?? getFaviconUrl(b.domain),
                width: 24,
                height: 24,
                errorWidget: (_, _, _) =>
                    Icon(Icons.language, size: 20, color: cs.onSurfaceVariant),
              ),
              title: Text(b.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(b.domain, style: tt.labelSmall),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookmarkDetailsScreen(bookmarkId: b.id),
                ),
              ),
            )),
      ],
    );
  }

  void _handleAction(
      String action, dynamic bookmark, dynamic db, BuildContext context) {
    switch (action) {
      case 'unarchive':
        db.unarchiveBookmark(bookmark.id);
        break;
      case 'archive':
        db.archiveBookmark(bookmark.id);
        Navigator.pop(context);
        break;
      case 'trash':
        db.moveToTrash(bookmark.id);
        Navigator.pop(context);
        break;
    }
  }
}
