import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/features/bookmarks/bookmarks_provider.dart';
import 'package:atlas/core/widgets/custom_chip.dart';

class BookmarkFilterChips extends ConsumerWidget {
  const BookmarkFilterChips({super.key});

  static const _labels = {
    BookmarkFilter.all: 'All',
    BookmarkFilter.unread: 'Unread',
    BookmarkFilter.favorites: 'Favorites',
    BookmarkFilter.archived: 'Archived',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(bookmarkFilterProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: BookmarkFilter.values
          .where((f) => f != BookmarkFilter.archived)
          .map((filter) {
          final isSelected = current == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: CustomChip(
              label: _labels[filter]!,
              isSelected: isSelected,
              onTap: () => ref.read(bookmarkFilterProvider.notifier).state = filter,
            ),
        );
      }).toList(),
    );
  }
}
