import 'dart:io';
import 'dart:async';

import 'package:http/io_client.dart';
import 'package:webfeed/webfeed.dart';

/// Enhanced example showing how to process multiple feeds with robust error handling
void main() async {
  print('WebFeed Example - Processing Multiple Feeds');
  print('==========================================\n');

  // Create a more permissive HTTP client for testing
  final client = IOClient(HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true));

  // Sample feeds to process - taken from feeds.md
  final feedUrls = [
    'https://www.theverge.com/rss/index.xml',
    'https://moxie.foxnews.com/google-publisher/latest.xml',
    'https://www.irozhlas.cz/rss/irozhlas',
    'http://rss.cnn.com/rss/cnn_topstories.rss',
    'http://feeds.bbci.co.uk/news/world/us_and_canada/rss.xml',
  ];

  // Process the feeds
  try {
    await processFeedList(client, feedUrls);
  } finally {
    client.close();
  }
}

Future<void> processFeedList(IOClient client, List<String> urls) async {
  for (var i = 0; i < urls.length; i++) {
    final url = urls[i];
    print('Feed ${i + 1}: $url');
    print('---------------------------------------------');

    try {
      // Always try to use HTTPS
      final secureUrl =
          url.startsWith('http:') ? url.replaceFirst('http:', 'https:') : url;

      // Fetch the feed with a reasonable timeout
      final response =
          await client.get(Uri.parse(secureUrl)).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('  Error: HTTP status ${response.statusCode}');
        continue;
      }

      final content = response.body;

      // Use the feed detection utility to determine the feed type
      final feedType = detectFeedType(content);
      print('  Detected feed type: $feedType');

      try {
        switch (feedType) {
          case FeedType.rss:
          case FeedType.rdf:
            final feed = RssFeed.parse(content);
            await _processRssFeed(feed);
            break;
          case FeedType.atom:
            final feed = AtomFeed.parse(content);
            await _processAtomFeed(feed);
            break;
          case FeedType.json:
            final feed = JsonFeed.fromJson(content);
            await _processJsonFeed(feed);
            break;
          case FeedType.unknown:
            // Fall back to the try-catch approach if type detection fails
            try {
              final feed = RssFeed.parse(content);
              await _processRssFeed(feed);
            } catch (rssError) {
              try {
                final feed = AtomFeed.parse(content);
                await _processAtomFeed(feed);
              } catch (atomError) {
                try {
                  final feed = JsonFeed.fromJson(content);
                  await _processJsonFeed(feed);
                } catch (jsonError) {
                  print('  Failed to parse feed as RSS, Atom, or JSON');
                  print('  RSS error: $rssError');
                  print('  Atom error: $atomError');
                  print('  JSON error: $jsonError');
                }
              }
            }
            break;
        }
      } catch (e) {
        print('  Error parsing feed: $e');
      }
    } catch (e) {
      print('  Error: $e');
    }

    print(''); // Empty line between feeds
  }
}

Future<void> _processRssFeed(RssFeed feed) async {
  print('  Successfully parsed RSS feed');
  print('  Title: ${feed.title}');
  print('  Link: ${feed.link}');
  print(
      '  Description: ${feed.description?.substring(0, feed.description != null && feed.description!.length > 50 ? 50 : feed.description?.length ?? 0)}...');

  final itemCount = feed.items?.length ?? 0;
  print('  Items: $itemCount');

  if (itemCount > 0) {
    print('\n  Latest items:');

    // Process up to 3 items
    for (var i = 0; i < (itemCount > 3 ? 3 : itemCount); i++) {
      final item = feed.items![i];

      print('    ${i + 1}. ${item.title}');
      print('       Published: ${item.pubDate}');

      if (item.content != null) {
        print('       Images: ${item.content!.images.length}');
        print('       Videos: ${item.content!.videos.length}');

        if (item.content!.plainText != null) {
          final preview = item.content!.plainText!.length > 60
              ? '${item.content!.plainText!.substring(0, 60)}...'
              : item.content!.plainText;
          print('       Preview: $preview');
        }
      }

      if (item.enclosure != null) {
        print('       Media: ${item.enclosure!.url} (${item.enclosure!.type})');
      }

      print('');
    }
  }
}

Future<void> _processAtomFeed(AtomFeed feed) async {
  print('  Successfully parsed Atom feed');
  print('  Title: ${feed.title}');
  print('  Updated: ${feed.updated}');

  // Process links
  if (feed.links != null && feed.links!.isNotEmpty) {
    final selfLink = feed.links!.firstWhere((link) => link.rel == 'self',
        orElse: () => feed.links!.first);
    print('  Link: ${selfLink.href}');
  }

  final itemCount = feed.items?.length ?? 0;
  print('  Entries: $itemCount');

  if (itemCount > 0) {
    print('\n  Latest entries:');

    // Process up to 3 items
    for (var i = 0; i < (itemCount > 3 ? 3 : itemCount); i++) {
      final item = feed.items![i];

      print('    ${i + 1}. ${item.title}');
      print('       Updated: ${item.updated}');
      print('       Published: ${item.published}');

      if (item.links != null && item.links!.isNotEmpty) {
        final alternateLink = item.links!.firstWhere(
            (link) => link.rel == 'alternate',
            orElse: () => item.links!.first);
        print('       Link: ${alternateLink.href}');
      }

      if (item.content != null) {
        final contentText = item.content!;
        final preview = contentText.length > 60
            ? '${contentText.substring(0, 60)}...'
            : contentText;
        print('       Content preview: $preview');
      } else if (item.summary != null) {
        final summaryText = item.summary!;
        final preview = summaryText.length > 60
            ? '${summaryText.substring(0, 60)}...'
            : summaryText;
        print('       Summary preview: $preview');
      }

      print('');
    }
  }
}

Future<void> _processJsonFeed(JsonFeed feed) async {
  print('  Successfully parsed JSON Feed');
  print('  Title: ${feed.title}');
  print('  Version: ${feed.version}');

  if (feed.homePageUrl != null) {
    print('  Home Page: ${feed.homePageUrl}');
  }

  if (feed.description != null) {
    final description = feed.description!;
    final preview = description.length > 50
        ? '${description.substring(0, 50)}...'
        : description;
    print('  Description: $preview');
  }

  final itemCount = feed.items?.length ?? 0;
  print('  Items: $itemCount');

  if (itemCount > 0) {
    print('\n  Latest items:');

    // Process up to 3 items
    for (var i = 0; i < (itemCount > 3 ? 3 : itemCount); i++) {
      final item = feed.items![i];

      print('    ${i + 1}. ${item.title}');
      if (item.datePublished != null) {
        print('       Published: ${item.datePublished}');
      }

      if (item.url != null) {
        print('       Link: ${item.url}');
      }

      if (item.contentHtml != null) {
        final contentText = item.contentHtml!;
        final preview = contentText.length > 60
            ? '${contentText.substring(0, 60)}...'
            : contentText;
        print('       Content preview: $preview');
      } else if (item.contentText != null) {
        final contentText = item.contentText!;
        final preview = contentText.length > 60
            ? '${contentText.substring(0, 60)}...'
            : contentText;
        print('       Content preview: $preview');
      } else if (item.summary != null) {
        final summaryText = item.summary!;
        final preview = summaryText.length > 60
            ? '${summaryText.substring(0, 60)}...'
            : summaryText;
        print('       Summary preview: $preview');
      }

      print('');
    }
  }
}
