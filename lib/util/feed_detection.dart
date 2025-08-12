import 'dart:convert';

import 'package:xml/xml.dart';

/// Feed type enumeration
enum FeedType {
  /// RSS Feed type (RSS 2.0)
  rss,

  /// Atom Feed type
  atom,

  /// RDF Feed type (RSS 1.0)
  rdf,

  /// JSON Feed type
  json,

  /// Unknown feed type
  unknown
}

/// Detects the type of feed from XML content using efficient string parsing
///
/// This optimized version avoids full XML parsing and instead uses string
/// operations to quickly identify the root element. This is significantly
/// faster for large XML files where full parsing would take seconds.
///
/// Returns a [FeedType] enum indicating the detected feed type:
/// - [FeedType.rss] for RSS 2.0 feeds
/// - [FeedType.atom] for Atom feeds
/// - [FeedType.rdf] for RSS 1.0 (RDF) feeds
/// - [FeedType.json] for JSON feeds
/// - [FeedType.unknown] if the feed type cannot be determined
///
/// Example:
/// ```dart
/// final response = await http.get(feedUrl);
/// final feedType = detectFeedTypeEfficiently(response.body);
///
/// switch (feedType) {
///   case FeedType.rss:
///     final feed = RssFeed.parse(response.body);
///     // Process RSS feed
///     break;
///   case FeedType.atom:
///     final feed = AtomFeed.parse(response.body);
///     // Process Atom feed
///     break;
///   case FeedType.rdf:
///     final feed = RssFeed.parse(response.body); // RDF uses the same parser
///     // Process RDF/RSS 1.0 feed
///     break;
///   case FeedType.json:
///     final feed = JsonFeed.fromJson(response.body);
///     // Process JSON feed
///     break;
///   case FeedType.unknown:
///     // Handle unknown feed type
///     break;
/// }
/// ```
FeedType detectFeedTypeEfficiently(String xml) {
  try {
    // Check for JSON Feed first (most efficient check)
    final trimmedContent = xml.trim();
    if (trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) {
      // Validate that it's properly formed JSON
      if (_isValidJsonStructure(trimmedContent)) {
        return FeedType.json;
      }
    }

    // Remove XML declaration and whitespace at the beginning
    var cleanedXml = xml.trim();

    // Skip XML declaration if present
    if (cleanedXml.startsWith('<?xml')) {
      final declarationEnd = cleanedXml.indexOf('?>');
      if (declarationEnd != -1) {
        cleanedXml = cleanedXml.substring(declarationEnd + 2).trim();
      }
    }

    // Skip any remaining whitespace and find the first opening tag
    final firstTagStart = cleanedXml.indexOf('<');
    if (firstTagStart == -1) {
      return FeedType.unknown;
    }

    // Find the end of the first tag
    final firstTagEnd = cleanedXml.indexOf('>', firstTagStart);
    if (firstTagEnd == -1) {
      return FeedType.unknown;
    }

    // Extract the tag name
    final tagContent =
        cleanedXml.substring(firstTagStart + 1, firstTagEnd).trim();

    // Handle self-closing tags and extract just the tag name
    final tagName =
        tagContent.split(' ').first.split('/').first.trim().toLowerCase();

    // Check for RSS 2.0 (case insensitive)
    if (tagName == 'rss') {
      // Validate that it's properly formed RSS
      if (!_isValidRssStructure(cleanedXml)) {
        return FeedType.unknown;
      }
      return FeedType.rss;
    }

    // Check for Atom (case insensitive)
    if (tagName == 'feed') {
      // Validate that it's properly formed Atom
      if (!_isValidAtomStructure(cleanedXml)) {
        return FeedType.unknown;
      }
      return FeedType.atom;
    }

    // Check for RSS 1.0 (RDF) - handle both 'RDF' and 'rdf:RDF' (case insensitive)
    if (tagName == 'rdf' || tagName == 'rdf:rdf') {
      return FeedType.rdf;
    }

    return FeedType.unknown;
  } catch (e) {
    return FeedType.unknown;
  }
}

/// Validates that XML has proper RSS structure
bool _isValidRssStructure(String xml) {
  // Check for proper opening and closing tags
  final rssOpenCount =
      RegExp(r'<rss[^>]*>', caseSensitive: false).allMatches(xml).length;
  final rssCloseCount =
      RegExp(r'</rss>', caseSensitive: false).allMatches(xml).length;
  final channelOpenCount =
      RegExp(r'<channel[^>]*>', caseSensitive: false).allMatches(xml).length;
  final channelCloseCount =
      RegExp(r'</channel>', caseSensitive: false).allMatches(xml).length;

  return rssOpenCount == rssCloseCount && channelOpenCount == channelCloseCount;
}

/// Validates that XML has proper Atom structure
bool _isValidAtomStructure(String xml) {
  // Check for proper opening and closing tags
  final feedOpenCount =
      RegExp(r'<feed[^>]*>', caseSensitive: false).allMatches(xml).length;
  final feedCloseCount =
      RegExp(r'</feed>', caseSensitive: false).allMatches(xml).length;

  return feedOpenCount == feedCloseCount;
}

/// Validates that content has proper JSON structure
bool _isValidJsonStructure(String content) {
  try {
    // Check for basic JSON structure
    if (!content.startsWith('{') || !content.endsWith('}')) {
      return false;
    }

    // Check for required JSON Feed fields
    final hasVersion =
        content.contains('"version"') || content.contains("'version'");
    final hasItems = content.contains('"items"') || content.contains("'items'");

    // JSON Feed must have version and items
    return hasVersion && hasItems;
  } catch (e) {
    return false;
  }
}

/// Detects the type of feed from XML content
///
/// Returns a [FeedType] enum indicating the detected feed type:
/// - [FeedType.rss] for RSS 2.0 feeds
/// - [FeedType.atom] for Atom feeds
/// - [FeedType.rdf] for RSS 1.0 (RDF) feeds
/// - [FeedType.json] for JSON feeds
/// - [FeedType.unknown] if the feed type cannot be determined
///
/// Example:
/// ```dart
/// final response = await http.get(feedUrl);
/// final feedType = detectFeedType(response.body);
///
/// switch (feedType) {
///   case FeedType.rss:
///     final feed = RssFeed.parse(response.body);
///     // Process RSS feed
///     break;
///   case FeedType.atom:
///     final feed = AtomFeed.parse(response.body);
///     // Process Atom feed
///     break;
///   case FeedType.rdf:
///     final feed = RssFeed.parse(response.body); // RDF uses the same parser
///     break;
///   case FeedType.json:
///     final feed = JsonFeed.fromJson(response.body);
///     // Process JSON feed
///     break;
///   case FeedType.unknown:
///     // Handle unknown feed type
///     break;
/// }
/// ```
FeedType detectFeedType(String xml) {
  try {
    // Check for JSON Feed first (most efficient check)
    try {
      jsonDecode(xml);
      return FeedType.json;
    } catch (e) {
      //Continue with checks
    }

    final document = XmlDocument.parse(xml);
    final rootElement = document.rootElement;

    // Check for RSS 2.0 (case insensitive)
    if (rootElement.name.local.toLowerCase() == 'rss') {
      return FeedType.rss;
    }

    // Check for Atom (case insensitive)
    if (rootElement.name.local.toLowerCase() == 'feed') {
      return FeedType.atom;
    }

    // Check for RSS 1.0 (RDF) - case insensitive
    final localName = rootElement.name.local.toLowerCase();
    final qualifiedName = rootElement.name.qualified.toLowerCase();
    if (localName == 'rdf' || qualifiedName == 'rdf:rdf') {
      return FeedType.rdf;
    }

    return FeedType.unknown;
  } catch (e) {
    // If XML parsing fails, try the efficient method as fallback
    return detectFeedTypeEfficiently(xml);
  }
}
