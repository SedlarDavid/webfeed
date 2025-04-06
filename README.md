# WebFeed

[![Build Status](https://travis-ci.org/witochandra/webfeed.svg?branch=master)](https://travis-ci.org/witochandra/webfeed)
[![Pub](https://img.shields.io/pub/v/webfeed.svg)](https://pub.dartlang.org/packages/webfeed)

A robust Dart package for parsing RSS and Atom feeds with enhanced compatibility for a wide variety of feed formats.

## Features

- [x] RSS Support (versions 0.9, 1.0, & 2.0)
- [x] Atom Support
- [x] Namespace Support
    - [x] Media RSS
    - [x] Dublin Core
    - [x] iTunes
    - [x] Syndication
- [x] Enhanced Compatibility
    - [x] Improved namespace handling
    - [x] Flexible date parsing
    - [x] Robust error recovery
    - [x] Better content extraction
    - [x] Support for inconsistent feed structures
- [x] Feed Type Detection
    - [x] Automatic identification of RSS, Atom, and RDF formats
    - [x] Helper functions for dynamic feed processing

## Installing

Add this line into your `pubspec.yaml`:
```yaml
webfeed: ^0.7.0
```

Import the package into your Dart code using:
```dart
import 'package:webfeed/webfeed.dart';
```

## Usage

### Basic Parsing

To parse XML string into feed objects:

```dart
// For RSS feeds
var rssFeed = RssFeed.parse(xmlString);

// For Atom feeds
var atomFeed = AtomFeed.parse(xmlString);
```

### Feed Type Detection

To automatically detect the feed type before parsing:

```dart
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

Future<void> loadFeed() async {
  final response = await http.get(Uri.parse('https://news.example.com/feed'));
  if (response.statusCode == 200) {
    final feedType = detectFeedType(response.body);
    
    switch (feedType) {
      case FeedType.rss:
      case FeedType.rdf:
        final feed = RssFeed.parse(response.body);
        print('RSS Feed title: ${feed.title}');
        break;
      case FeedType.atom:
        final feed = AtomFeed.parse(response.body);
        print('Atom Feed title: ${feed.title}');
        break;
      case FeedType.unknown:
        print('Unknown feed type');
        break;
    }
  }
}
```

### HTTP Example

```dart
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

Future<void> loadFeed() async {
  final response = await http.get(Uri.parse('https://news.example.com/rss'));
  if (response.statusCode == 200) {
    final feed = RssFeed.parse(response.body);
    print('Feed title: ${feed.title}');
    
    for (final item in feed.items ?? []) {
      print('Item title: ${item.title}');
      print('Published: ${item.pubDate}');
    }
  }
}
```

## Available Properties

### RSS Feed

```dart
feed.title             // Feed title
feed.description       // Feed description
feed.link              // Feed URL
feed.author            // Feed author
feed.items             // List of feed items
feed.image             // Feed image
feed.cloud             // RSS cloud information
feed.categories        // Feed categories
feed.skipDays          // Skip days
feed.skipHours         // Skip hours
feed.lastBuildDate     // Last build date
feed.language          // Feed language
feed.generator         // Feed generator
feed.copyright         // Copyright information
feed.docs              // Feed documentation URL
feed.managingEditor    // Managing editor email
feed.rating            // PICS rating
feed.webMaster         // Webmaster email
feed.ttl               // Time to live
feed.atomLink          // Atom link (if available)
feed.dc                // Dublin Core namespace
feed.itunes            // iTunes namespace
feed.syndication       // Syndication namespace
```

### RSS Item

```dart
item.title             // Item title
item.description       // Item description
item.link              // Item URL
item.categories        // Item categories
item.guid              // Item GUID
item.pubDate           // Publication date
item.author            // Item author
item.comments          // Comments URL
item.source            // Source information
item.content           // Item content (with enhanced features)
item.media             // Media content
item.enclosure         // Enclosure (for podcasts, etc.)
item.dc                // Dublin Core namespace
item.itunes            // iTunes namespace
```

#### Enhanced Content Features

The `RssContent` class now provides richer content extraction:

```dart
RssContent content = item.content;
content.value          // Raw HTML content
content.plainText      // Plain text version (HTML tags removed)
content.images         // List of image URLs extracted from content
content.videos         // List of video URLs extracted from content
content.iframes        // List of iframe URLs (embeds) extracted from content
```

### Atom Feed

```dart
feed.id                // Feed ID
feed.title             // Feed title
feed.updated           // Last updated date
feed.items             // List of feed entries
feed.links             // Feed links
feed.authors           // Feed authors
feed.contributors      // Feed contributors
feed.categories        // Feed categories
feed.generator         // Feed generator
feed.icon              // Feed icon
feed.logo              // Feed logo
feed.rights            // Rights information
feed.subtitle          // Feed subtitle
```

### Atom Item

```dart
item.id                // Item ID
item.title             // Item title
item.updated           // Last updated date
item.authors           // Item authors
item.links             // Item links
item.categories        // Item categories
item.contributors      // Item contributors
item.source            // Source information
item.published         // Publication date
item.content           // Item content
item.summary           // Item summary
item.rights            // Rights information
item.media             // Media content
```

## Robust Parsing

The library includes several improvements to handle a wide variety of RSS and Atom feeds:

1. **Improved namespace handling**: Better support for feeds with different namespace prefixes and structures
2. **Enhanced date parsing**: Support for various date formats used across different feeds
3. **Content extraction**: Better parsing of HTML content with extraction of images, videos, and embeds
4. **Error recovery**: More graceful handling of malformed feeds with fallback options
5. **Plain text conversion**: Automatic conversion of HTML content to plain text

## License

WebFeed is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
