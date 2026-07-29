/// Utility functions for Atlas.
/// URL validation, domain extraction, reading time, and formatters.
library;

import 'package:intl/intl.dart';

// ─── URL Utilities ────────────────────────────────────────

/// Validates whether a string is a valid URL.
bool isValidUrl(String input) {
  try {
    final uri = Uri.parse(input);
    return uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Normalizes a URL (ensure scheme, trim trailing slash).
String normalizeUrl(String url) {
  var normalized = url.trim();
  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = 'https://$normalized';
  }
  if (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Extracts the domain from a URL.
String extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    var host = uri.host;
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    return host;
  } catch (_) {
    return url;
  }
}

/// Gets a Google Favicon URL for a domain.
String getFaviconUrl(String domain) {
  return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
}

/// Extracts the first valid URL from a string (useful for share intents).
String? extractUrlFromText(String text) {
  final urlRegex = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );
  final match = urlRegex.firstMatch(text);
  return match?.group(0);
}

// ─── Reading Time ─────────────────────────────────────────

/// Estimates the reading time in minutes from a word count.
/// Average reading speed: 200 words per minute.
int estimateReadingTime(int wordCount) {
  if (wordCount <= 0) return 0;
  return (wordCount / 200).ceil();
}

/// Counts words in a text string.
int countWords(String text) {
  if (text.trim().isEmpty) return 0;
  return text.trim().split(RegExp(r'\s+')).length;
}

/// Formats reading time for display.
String formatReadingTime(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
  if (minutes < 60) return '$minutes min read';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) return '$hours hr read';
  return '$hours hr $remaining min read';
}

// ─── Date Formatters ──────────────────────────────────────

/// Formats a date as relative time (e.g., "2 hours ago", "Yesterday").
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

/// Formats a date for display (e.g., "Jun 15, 2024").
String formatDate(DateTime date) {
  return DateFormat.yMMMd().format(date);
}

/// Formats a date with time (e.g., "Jun 15, 2024, 3:42 PM").
String formatDateTime(DateTime date) {
  return DateFormat.yMMMd().add_jm().format(date);
}

// ─── Timeline Section Headers ─────────────────────────────

/// Gets the timeline section header for a date.
String getTimelineSection(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  final diff = today.difference(dateDay).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff <= 7) return 'This Week';
  if (diff <= 30) return 'This Month';
  return 'Earlier';
}

// ─── Number Formatters ────────────────────────────────────

/// Formats a number with commas (e.g., 1,600).
String formatNumber(int number) {
  return NumberFormat('#,##0').format(number);
}

/// Formats total reading time as hours description.
String formatTotalReadingTime(int totalMinutes) {
  if (totalMinutes < 60) return '~$totalMinutes minutes of reading saved';
  final hours = totalMinutes ~/ 60;
  return '~$hours hours of reading saved';
}

// ─── Netscape HTML Export ─────────────────────────────────

/// Generates a Netscape bookmark HTML file content.
String generateNetscapeHtml({
  required List<Map<String, dynamic>> bookmarks,
  required List<Map<String, dynamic>> folders,
}) {
  final buffer = StringBuffer();
  buffer.writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>');
  buffer.writeln('<!-- This is an automatically generated file. -->');
  buffer.writeln('<!-- It will be read and overwritten. DO NOT EDIT! -->');
  buffer.writeln(
      '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">');
  buffer.writeln('<TITLE>Atlas Bookmarks</TITLE>');
  buffer.writeln('<H1>Atlas Bookmarks</H1>');
  buffer.writeln('<DL><p>');

  // Group bookmarks by folder
  final folderMap = <int?, List<Map<String, dynamic>>>{};
  for (final bm in bookmarks) {
    final folderId = bm['folderId'] as int?;
    folderMap.putIfAbsent(folderId, () => []).add(bm);
  }

  // Bookmarks in folders
  for (final folder in folders) {
    final folderId = folder['id'] as int;
    final folderBookmarks = folderMap[folderId] ?? [];
    if (folderBookmarks.isEmpty) continue;

    buffer.writeln('    <DT><H3>${_escapeHtml(folder['name'] as String)}</H3>');
    buffer.writeln('    <DL><p>');
    for (final bm in folderBookmarks) {
      final timestamp =
          (DateTime.tryParse(bm['createdAt'] as String? ?? '')
                      ?.millisecondsSinceEpoch ??
                  0) ~/
              1000;
      buffer.writeln(
          '        <DT><A HREF="${_escapeHtml(bm['url'] as String)}" ADD_DATE="$timestamp">${_escapeHtml(bm['title'] as String)}</A>');
    }
    buffer.writeln('    </DL><p>');
  }

  // Unfiled bookmarks
  final unfiled = folderMap[null] ?? [];
  for (final bm in unfiled) {
    final timestamp =
        (DateTime.tryParse(bm['createdAt'] as String? ?? '')
                    ?.millisecondsSinceEpoch ??
                0) ~/
            1000;
    buffer.writeln(
        '    <DT><A HREF="${_escapeHtml(bm['url'] as String)}" ADD_DATE="$timestamp">${_escapeHtml(bm['title'] as String)}</A>');
  }

  buffer.writeln('</DL><p>');
  return buffer.toString();
}

String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

// ─── Netscape HTML Import ─────────────────────────────────

/// Parsed bookmark from HTML import.
class ImportedBookmark {
  final String title;
  final String url;
  final String? folderName;
  final DateTime? addDate;

  ImportedBookmark({
    required this.title,
    required this.url,
    this.folderName,
    this.addDate,
  });
}

/// Parses a Netscape bookmark HTML file.
List<ImportedBookmark> parseNetscapeHtml(String html) {
  final results = <ImportedBookmark>[];
  final lines = html.split('\n');
  String? currentFolder;

  final h3Regex = RegExp(r'<H3[^>]*>(.*?)</H3>', caseSensitive: false);
  final aRegex = RegExp(
    r'<A\s+HREF="([^"]+)"(?:\s+ADD_DATE="(\d+)")?[^>]*>(.*?)</A>',
    caseSensitive: false,
  );
  final dlCloseRegex = RegExp(r'</DL>', caseSensitive: false);

  final folderStack = <String?>[];

  for (final line in lines) {
    final h3Match = h3Regex.firstMatch(line);
    if (h3Match != null) {
      currentFolder = h3Match.group(1)?.trim();
      folderStack.add(currentFolder);
      continue;
    }

    if (dlCloseRegex.hasMatch(line) && folderStack.isNotEmpty) {
      folderStack.removeLast();
      currentFolder = folderStack.isNotEmpty ? folderStack.last : null;
      continue;
    }

    final aMatch = aRegex.firstMatch(line);
    if (aMatch != null) {
      final url = aMatch.group(1) ?? '';
      final addDateStr = aMatch.group(2);
      final title = aMatch.group(3)?.trim() ?? url;

      DateTime? addDate;
      if (addDateStr != null) {
        final seconds = int.tryParse(addDateStr);
        if (seconds != null) {
          addDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      }

      results.add(ImportedBookmark(
        title: title,
        url: url,
        folderName: currentFolder,
        addDate: addDate,
      ));
    }
  }

  return results;
}
