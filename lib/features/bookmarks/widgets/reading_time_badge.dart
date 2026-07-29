import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/core/utils/utils.dart';

class ReadingTimeBadge extends ConsumerWidget {
  final int? minutes;
  const ReadingTimeBadge({super.key, required this.minutes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(showReadingTimeProvider);
    if (!show || minutes == null || minutes! <= 0) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: kShapeTokens.extraSmall,
      ),
      child: Text(
        formatReadingTime(minutes),
        style: outfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
