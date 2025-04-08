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
///     // Process RDF/RSS 1.0 feed
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
      // Check for Atom namespace
      if (rootElement.getAttribute('xmlns:atom') != null) {
        return FeedType.atom;
      }
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
