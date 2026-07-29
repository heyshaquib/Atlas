import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/core/utils/utils.dart';

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final ViewMode viewMode;
  final int index;
  final String? folderColorHex;
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool disableSwipe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(bool)? onFavoriteToggled;
  final VoidCallback? onDelete;

  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.viewMode,
    required this.index,
    this.folderColorHex,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.disableSwipe = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onFavoriteToggled,
  });

  Color _accentColor(BuildContext context) {
    if (folderColorHex != null) {
      try {
        final hex = folderColorHex!.replaceFirst('#', '');
        return Color(int.parse(hex, radix: 16) + 0xFF000000);
      } catch (_) {}
    }
    return Theme.of(context).colorScheme.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    Widget card;
    switch (viewMode) {
      case ViewMode.list:
        card = _buildListCard(context);
        break;
      case ViewMode.grid:
        card = _buildGridCard(context);
        break;
      case ViewMode.masonry:
        card = _buildMasonryCard(context);
        break;
    }
    return card
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.1);
  }

  Widget _buildListCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: kShapeTokens.small,
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _accentColor(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl:
                        bookmark.faviconUrl ?? getFaviconUrl(bookmark.domain),
                    width: 40,
                    height: 40,
                    placeholder: (_, _) => Container(
                      width: 40,
                      height: 40,
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.language, size: 20, color: cs.onSurfaceVariant),
                    ),
                    errorWidget: (_, _, _) =>
                        Icon(Icons.language, size: 24, color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                bookmark.domain,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMultiSelectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onLongPress?.call(),
                  )
                else
                  IconButton(
                    icon: Icon(
                      bookmark.isFavorite ? Icons.star : Icons.star_border,
                      color: bookmark.isFavorite ? kFavoriteColor : null,
                    ),
                    onPressed: () =>
                        onFavoriteToggled?.call(!bookmark.isFavorite),
                  ),
              ],
            ),
            if (bookmark.isDead)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kDeadLinkColor,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: 600.ms),
              ),
          ],
        ),
      ),
    );

    if (disableSwipe) return cardContent;

    return Dismissible(
      key: ValueKey('dismiss-${bookmark.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: kFavoriteColor.withValues(alpha: 0.2),
        child: Icon(bookmark.isFavorite ? Icons.star_border : Icons.star, color: kFavoriteColor),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.error.withValues(alpha: 0.2),
        child: Icon(Icons.delete, color: cs.error),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          onFavoriteToggled?.call(!bookmark.isFavorite);
          return false;
        } else {
          HapticFeedback.mediumImpact();
          onDelete?.call();
          return false;
        }
      },
      child: cardContent,
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: kShapeTokens.small,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: bookmark.previewImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: bookmark.previewImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        height: 120,
                        color: cs.surfaceContainerHighest,
                      ),
                      errorWidget: (_, _, _) => Container(
                        height: 120,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.image, color: cs.onSurfaceVariant),
                      ),
                    )
                  : Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentColor(context).withValues(alpha: 0.3),
                            cs.surfaceContainerHighest,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.language,
                            size: 32, color: cs.onSurfaceVariant),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: bookmark.faviconUrl ??
                            getFaviconUrl(bookmark.domain),
                        width: 20,
                        height: 20,
                        errorWidget: (_, _, _) => Icon(Icons.language,
                            size: 16, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: kShapeTokens.small,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookmark.previewImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: bookmark.previewImageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    height: 100,
                    color: cs.surfaceContainerHighest,
                  ),
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: bookmark.faviconUrl ??
                            getFaviconUrl(bookmark.domain),
                        width: 20,
                        height: 20,
                        errorWidget: (_, _, _) => Icon(Icons.language,
                            size: 16, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  if (bookmark.notesPlainText != null &&
                      bookmark.notesPlainText!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      bookmark.notesPlainText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
