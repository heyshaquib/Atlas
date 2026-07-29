/// MetadataFetcher — Fetches web page metadata using http + html packages.
/// Extracts title, description, favicon, preview image, and reading time.
library;

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/utils/utils.dart';

class MetadataFetcher {
  final http.Client _client;

  MetadataFetcher({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches metadata from a URL.
  Future<ParsedMetadata> fetch(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .get(uri, headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; Atlas/1.0)',
          })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return ParsedMetadata(
          faviconUrl: getFaviconUrl(extractDomain(url)),
        );
      }

      final document = html_parser.parse(response.body);
      final domain = extractDomain(url);

      // Extract title
      final title = _extractTitle(document);

      // Extract description
      final description = _extractDescription(document);

      // Extract favicon
      final favicon = _extractFavicon(document, uri) ??
          getFaviconUrl(domain);

      // Extract preview image
      final previewImage = _extractPreviewImage(document, uri);

      // Extract reading time
      final bodyText = _extractBodyText(document);
      final wordCount = countWords(bodyText);
      final readingTime = estimateReadingTime(wordCount);

      return ParsedMetadata(
        title: title,
        description: description,
        faviconUrl: favicon,
        previewImageUrl: previewImage,
        estimatedWordCount: wordCount > 0 ? wordCount : null,
        estimatedReadingTimeMinutes: readingTime > 0 ? readingTime : null,
      );
    } catch (e) {
      return ParsedMetadata(
        faviconUrl: getFaviconUrl(extractDomain(url)),
      );
    }
  }

  String? _extractTitle(Document document) {
    // Try og:title first
    final ogTitle = document
        .querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    if (ogTitle != null && ogTitle.isNotEmpty) return ogTitle;

    // Fallback to <title>
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.isNotEmpty) {
      return titleElement.text.trim();
    }

    return null;
  }

  String? _extractDescription(Document document) {
    // Try og:description
    final ogDesc = document
        .querySelector('meta[property="og:description"]')
        ?.attributes['content'];
    if (ogDesc != null && ogDesc.isNotEmpty) return ogDesc;

    // Fallback to meta description
    final metaDesc = document
        .querySelector('meta[name="description"]')
        ?.attributes['content'];
    if (metaDesc != null && metaDesc.isNotEmpty) return metaDesc;

    return null;
  }

  String? _extractFavicon(Document document, Uri baseUri) {
    // Try <link rel="icon"> or <link rel="shortcut icon">
    final iconLink = document.querySelector('link[rel="icon"]') ??
        document.querySelector('link[rel="shortcut icon"]') ??
        document.querySelector('link[rel="apple-touch-icon"]');

    if (iconLink != null) {
      final href = iconLink.attributes['href'];
      if (href != null && href.isNotEmpty) {
        return _resolveUrl(href, baseUri);
      }
    }

    return null;
  }

  String? _extractPreviewImage(Document document, Uri baseUri) {
    // Try og:image
    final ogImage = document
        .querySelector('meta[property="og:image"]')
        ?.attributes['content'];
    if (ogImage != null && ogImage.isNotEmpty) {
      return _resolveUrl(ogImage, baseUri);
    }

    // Try twitter:image
    final twitterImage = document
        .querySelector('meta[name="twitter:image"]')
        ?.attributes['content'];
    if (twitterImage != null && twitterImage.isNotEmpty) {
      return _resolveUrl(twitterImage, baseUri);
    }

    return null;
  }

  String _extractBodyText(Document document) {
    // Remove script and style elements
    document.querySelectorAll('script, style, noscript').forEach((e) => e.remove());

    // Get body text
    final body = document.querySelector('body');
    if (body == null) return '';

    return body.text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _resolveUrl(String url, Uri baseUri) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('//')) {
      return '${baseUri.scheme}:$url';
    }
    return baseUri.resolve(url).toString();
  }

  void dispose() {
    _client.close();
  }
}
