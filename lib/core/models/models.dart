/// Data models for Atlas bookmark manager.
/// These are plain Dart classes used across the app for
/// type-safe data passing beyond what drift generates.
library;

// ─── Parsed Metadata ──────────────────────────────────────

/// Result of fetching and parsing a web page's metadata.
class ParsedMetadata {
  final String? title;
  final String? description;
  final String? faviconUrl;
  final String? previewImageUrl;
  final int? estimatedWordCount;
  final int? estimatedReadingTimeMinutes;

  const ParsedMetadata({
    this.title,
    this.description,
    this.faviconUrl,
    this.previewImageUrl,
    this.estimatedWordCount,
    this.estimatedReadingTimeMinutes,
  });
}

// ─── Smart Collection ─────────────────────────────────────

enum SmartCollectionType {
  recentlyAdded,
  unread,
  mostVisited,
  recentlyOpened,
  deadLinks,
}

class SmartCollection {
  final SmartCollectionType type;
  final String name;
  final String iconName;
  final int count;

  const SmartCollection({
    required this.type,
    required this.name,
    required this.iconName,
    required this.count,
  });

  static List<SmartCollection> defaults({
    int recentlyAdded = 0,
    int unread = 0,
    int readLater = 0,
    int mostVisited = 0,
    int recentlyOpened = 0,
    int deadLinks = 0,
  }) {
    return [
      SmartCollection(
        type: SmartCollectionType.recentlyAdded,
        name: 'Recently Added',
        iconName: 'schedule',
        count: recentlyAdded,
      ),
      SmartCollection(
        type: SmartCollectionType.unread,
        name: 'Unread',
        iconName: 'mark_email_unread',
        count: unread,
      ),
      SmartCollection(
        type: SmartCollectionType.mostVisited,
        name: 'Most Visited',
        iconName: 'trending_up',
        count: mostVisited,
      ),
      SmartCollection(
        type: SmartCollectionType.recentlyOpened,
        name: 'Recently Opened',
        iconName: 'history',
        count: recentlyOpened,
      ),
      SmartCollection(
        type: SmartCollectionType.deadLinks,
        name: 'Dead Links',
        iconName: 'link_off',
        count: deadLinks,
      ),
    ];
  }
}

// ─── Bookmark Filter ──────────────────────────────────────

enum BookmarkFilter {
  all,
  unread,
  favorites,
  archived,
}

// ─── Sort Option ──────────────────────────────────────────

enum SortOption {
  dateNewest('Newest First', 'createdAt', false),
  dateOldest('Oldest First', 'createdAt', true),
  titleAZ('Title A–Z', 'title', true),
  titleZA('Title Z–A', 'title', false),
  domainAZ('Domain A–Z', 'domain', true),
  domainZA('Domain Z–A', 'domain', false),
  mostVisited('Most Visited', 'visitCount', false),
  shortestRead('Shortest Read', 'readingTime', true),
  longestRead('Longest Read', 'readingTime', false);

  final String label;
  final String field;
  final bool ascending;
  const SortOption(this.label, this.field, this.ascending);
}

// ─── View Mode ────────────────────────────────────────────

enum ViewMode {
  list,
  grid,
  masonry,
}

// ─── Reading Time Range ───────────────────────────────────

enum ReadingTimeRange {
  any('Any', null, null),
  under5('Under 5 min', 0, 5),
  fiveToFifteen('5–15 min', 5, 15),
  fifteenToThirty('15–30 min', 15, 30),
  thirtyPlus('30+ min', 30, null);

  final String label;
  final int? minMinutes;
  final int? maxMinutes;
  const ReadingTimeRange(this.label, this.minMinutes, this.maxMinutes);
}

// ─── Theme Mode (extended for AMOLED) ─────────────────────

enum AtlasThemeMode {
  system,
  light,
  dark,
  amoled,
}

// ─── Browser Choice ───────────────────────────────────────

enum BrowserChoice {
  inApp,
  external_,
}

// ─── Trash Auto Clear ─────────────────────────────────────

enum TrashAutoClear {
  sevenDays(7, '7 days'),
  fourteenDays(14, '14 days'),
  thirtyDays(30, '30 days'),
  never(0, 'Never');

  final int days;
  final String label;
  const TrashAutoClear(this.days, this.label);
}

// ─── Dead Link Check Frequency ────────────────────────────

enum DeadLinkCheckFrequency {
  daily('Daily'),
  weekly('Weekly'),
  never('Never');

  final String label;
  const DeadLinkCheckFrequency(this.label);
}

// ─── Widget Source ────────────────────────────────────────

enum WidgetSource {
  favorites('Favorites'),
  recentlyAdded('Recently Added'),
  specificFolder('Specific Folder');

  final String label;
  const WidgetSource(this.label);
}
