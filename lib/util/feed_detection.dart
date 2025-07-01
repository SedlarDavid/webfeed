import 'package:xml/xml.dart';

/// Feed type enumeration
enum FeedType {
  /// RSS Feed type (RSS 2.0)
  rss,

  /// Atom Feed type
  atom,

  /// RDF Feed type (RSS 1.0)
  rdf,

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
///   case FeedType.unknown:
///     // Handle unknown feed type
///     break;
/// }
/// ```
FeedType detectFeedTypeEfficiently(String xml) {
  try {
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
    final tagName = tagContent.split(' ').first.split('/').first.trim();

    // Check for RSS 2.0
    if (tagName == 'rss') {
      return FeedType.rss;
    }

    // Check for Atom
    if (tagName == 'feed') {
      return FeedType.atom;
    }

    // Check for RSS 1.0 (RDF) - handle both 'RDF' and 'rdf:RDF'
    if (tagName == 'RDF' || tagName == 'rdf:RDF') {
      return FeedType.rdf;
    }

    return FeedType.unknown;
  } catch (e) {
    return FeedType.unknown;
  }
}

/// Detects the type of feed from XML content
///
/// Returns a [FeedType] enum indicating the detected feed type:
/// - [FeedType.rss] for RSS 2.0 feeds
/// - [FeedType.atom] for Atom feeds
/// - [FeedType.rdf] for RSS 1.0 (RDF) feeds
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
///   case FeedType.unknown:
///     // Handle unknown feed type
///     break;
/// }
/// ```
FeedType detectFeedType(String xml) {
  try {
    final document = XmlDocument.parse(xml);
    final rootElement = document.rootElement;

    // Check for RSS 2.0
    if (rootElement.name.local == 'rss') {
      return FeedType.rss;
    }

    // Check for Atom
    if (rootElement.name.local == 'feed') {
      return FeedType.atom;
    }

    // Check for RSS 1.0 (RDF)
    if (rootElement.name.local == 'RDF' ||
        (rootElement.name.local == 'rdf:RDF') ||
        (rootElement.name.qualified == 'rdf:RDF')) {
      return FeedType.rdf;
    }

    return FeedType.unknown;
  } catch (e) {
    return FeedType.unknown;
  }
}
