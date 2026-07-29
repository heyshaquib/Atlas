import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/features/statistics/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final readingTime = ref.watch(totalUnreadReadingTimeProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: stats.when(
        data: (s) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader('OVERVIEW'),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(icon: Icons.bookmarks, label: 'Total', value: s['total'] ?? 0, index: 0),
                  _StatCard(icon: Icons.star, label: 'Favorites', value: s['favorites'] ?? 0, index: 1),
                  _StatCard(icon: Icons.bookmark, label: 'Read Later', value: s['readLater'] ?? 0, index: 2),
                  _StatCard(icon: Icons.mark_email_unread, label: 'Unread', value: s['unread'] ?? 0, index: 3),
                  _StatCard(icon: Icons.link_off, label: 'Dead Links', value: s['dead'] ?? 0, index: 4),
                  _StatCard(icon: Icons.archive, label: 'Archived', value: s['archived'] ?? 0, index: 5),
                ],
              ),
              const SizedBox(height: 24),

              _SectionHeader('ORGANISATION'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(icon: Icons.folder, label: 'Folders', value: s['folders'] ?? 0, index: 6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(icon: Icons.label, label: 'Tags', value: s['tags'] ?? 0, index: 7),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionHeader('READING'),
              const SizedBox(height: 8),
              readingTime.when(
                data: (minutes) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.auto_stories, size: 40, color: cs.primary),
                        const SizedBox(height: 12),
                        Text(
                          formatTotalReadingTime(minutes),
                          style: outfitStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'across all unread bookmarks',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int index;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, val, _) => Text(
                val.toInt().toString(),
                style: outfitStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}
