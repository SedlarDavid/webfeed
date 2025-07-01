import 'package:webfeed/domain/atom_category.dart';
import 'package:webfeed/domain/atom_generator.dart';
import 'package:webfeed/domain/atom_item.dart';
import 'package:webfeed/domain/atom_link.dart';
import 'package:webfeed/domain/atom_person.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/util/iterable.dart';
import 'package:webfeed/util/xml.dart'
    show
        stripCdata,
        getTextContentWithNamespace,
        stripCdataWithFlag,
        decodeHtmlEntities;
import 'package:xml/xml.dart';

class AtomFeed {
  final String? id;
  final String? title;
  final DateTime? updated;
  final List<AtomItem>? items;

  final List<AtomLink>? links;
  final List<AtomPerson>? authors;
  final List<AtomPerson>? contributors;
  final List<AtomCategory>? categories;
  final AtomGenerator? generator;
  final String? icon;
  final String? logo;
  final String? rights;
  final String? subtitle;

  AtomFeed({
    this.id,
    this.title,
    this.updated,
    this.items,
    this.links,
    this.authors,
    this.contributors,
    this.categories,
    this.generator,
    this.icon,
    this.logo,
    this.rights,
    this.subtitle,
  });

  /// Gets the best available image for the feed.
  ///
  /// This attempts to find the most suitable feed image from these sources:
  /// - Atom logo
  /// - Atom icon
  ///
  /// Returns null if no feed-level image is found.
  FeedImage? get feedImage {
    // Try Atom logo first
    if (logo != null && logo!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(logo!) ?? (null, null);
      return FeedImage(
        url: logo!,
        width: width,
        height: height,
        source: 'atom:logo',
      );
    }

    // Try Atom icon
    if (icon != null && icon!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(icon!) ?? (null, null);
      return FeedImage(
        url: icon!,
        width: width,
        height: height,
        source: 'atom:icon',
      );
    }

    // No feed-level image found
    return null;
  }

  /// Helper function to extract width and height from image URLs
  ///
  /// Looks for common patterns in URLs like:
  /// - /image_100x200.jpg
  /// - /image-width-100-height-200.jpg
  /// - /image_w100_h200.jpg
  /// - /image.jpg?w=100&h=200
  ///
  /// Returns a record with (width, height) if found, null otherwise
  static (int, int)? _extractDimensionsFromUrl(String url) {
    try {
      // Pattern 1: filename_WIDTHxHEIGHT.ext (e.g., image_300x200.jpg)
      final dimensionPattern1 = RegExp(r'_(\d+)x(\d+)\.');
      final match1 = dimensionPattern1.firstMatch(url);
      if (match1 != null) {
        final width = int.tryParse(match1.group(1)!);
        final height = int.tryParse(match1.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 2: filename-width-W-height-H.ext (e.g., image-width-300-height-200.jpg)
      final dimensionPattern2 = RegExp(r'-width-(\d+)-height-(\d+)\.');
      final match2 = dimensionPattern2.firstMatch(url);
      if (match2 != null) {
        final width = int.tryParse(match2.group(1)!);
        final height = int.tryParse(match2.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 3: filename_wW_hH.ext (e.g., image_w300_h200.jpg)
      final dimensionPattern3 = RegExp(r'_w(\d+)_h(\d+)\.');
      final match3 = dimensionPattern3.firstMatch(url);
      if (match3 != null) {
        final width = int.tryParse(match3.group(1)!);
        final height = int.tryParse(match3.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 4: query parameters (e.g., image.jpg?w=300&h=200 or image.jpg?width=300&height=200)
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final widthParam =
            uri.queryParameters['w'] ?? uri.queryParameters['width'];
        final heightParam =
            uri.queryParameters['h'] ?? uri.queryParameters['height'];

        if (widthParam != null && heightParam != null) {
          final width = int.tryParse(widthParam);
          final height = int.tryParse(heightParam);
          if (width != null && height != null) {
            return (width, height);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets the best available image for the feed.
  /// Alias for feedImage to match RSS feed interface.
  FeedImage? get image => feedImage;

  factory AtomFeed.parse(String xmlString, {bool withArticles = true}) {
    var document = XmlDocument.parse(xmlString);
    var feedElement = document.findElements('feed').firstOrNull;
    if (feedElement == null) {
      throw ArgumentError('feed not found');
    }

    final entryElements = feedElement.findElements('entry').toList();
    final parsedItems = entryElements.map((e) => AtomItem.parse(e)).toList();
    return AtomFeed(
      id: _normalizeField(getTextContentWithNamespace(feedElement, 'id')),
      title: _normalizeField(getTextContentWithNamespace(feedElement, 'title')),
      updated:
          parseDateTime(getTextContentWithNamespace(feedElement, 'updated')),
      items: withArticles ? parsedItems : null,
      links: feedElement
          .findElements('link')
          .map((e) => AtomLink.parse(e))
          .toList(),
      authors: feedElement
          .findElements('author')
          .map((e) => AtomPerson.parse(e))
          .toList(),
      contributors: feedElement
          .findElements('contributor')
          .map((e) => AtomPerson.parse(e))
          .toList(),
      categories: feedElement
          .findElements('category')
          .map((e) => AtomCategory.parse(e))
          .toList(),
      generator: feedElement
          .findElements('generator')
          .map((e) => AtomGenerator.parse(e))
          .firstOrNull,
      icon: _normalizeField(getTextContentWithNamespace(feedElement, 'icon')),
      logo: _normalizeField(getTextContentWithNamespace(feedElement, 'logo')),
      rights:
          _normalizeField(getTextContentWithNamespace(feedElement, 'rights')),
      subtitle:
          _normalizeField(getTextContentWithNamespace(feedElement, 'subtitle')),
    );
  }

  // Helper method to normalize field values (decode HTML entities and handle empty strings)
  static String? _normalizeField(String? text) {
    if (text == null) return null;
    final decoded = decodeHtmlEntities(text);
    final trimmed = decoded.trim();
    // Return empty string for empty content (consistent with CDATA handling)
    return trimmed;
  }

  /// Efficient parsing method for large XML files
  /// Uses regex-based parsing instead of full DOM parsing for better performance
  static AtomFeed parseEfficiently(String xmlString,
      {bool withArticles = true}) {
    try {
      // Extract basic metadata using regex for speed with CDATA support
      // Look for feed-level elements specifically within feed element to avoid matching entry elements
      final feedMatch = RegExp(r'<feed[^>]*>(.*?)</feed>', dotAll: true)
          .firstMatch(xmlString);
      final feedContent = feedMatch?.group(1) ?? '';

      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
          .firstMatch(feedContent);
      final idMatch =
          RegExp(r'<id[^>]*>(.*?)</id>', dotAll: true).firstMatch(feedContent);
      final updatedMatch =
          RegExp(r'<updated[^>]*>(.*?)</updated>', dotAll: true)
              .firstMatch(feedContent);
      final iconMatch = RegExp(r'<icon[^>]*>(.*?)</icon>', dotAll: true)
          .firstMatch(feedContent);
      final logoMatch = RegExp(r'<logo[^>]*>(.*?)</logo>', dotAll: true)
          .firstMatch(feedContent);
      final rightsMatch = RegExp(r'<rights[^>]*>(.*?)</rights>', dotAll: true)
          .firstMatch(feedContent);
      final subtitleMatch =
          RegExp(r'<subtitle[^>]*>(.*?)</subtitle>', dotAll: true)
              .firstMatch(feedContent);

      // Parse complex elements efficiently
      final links = _parseLinksEfficiently(xmlString);
      final authors = _parseAuthorsEfficiently(xmlString);
      final contributors = _parseContributorsEfficiently(xmlString);
      final categories = _parseCategoriesEfficiently(xmlString);
      final generator = _parseGeneratorEfficiently(xmlString);

      // Parse items efficiently if requested
      List<AtomItem>? items;
      if (withArticles) {
        items = _parseItemsEfficiently(xmlString);
      }

      return AtomFeed(
        id: _decodeOrCdata(idMatch?.group(1)),
        title: _decodeOrCdata(titleMatch?.group(1)),
        updated: parseDateTime(_decodeOrCdata(updatedMatch?.group(1))),
        items: items,
        icon: _decodeOrCdata(iconMatch?.group(1)),
        logo: _decodeOrCdata(logoMatch?.group(1)),
        rights: _decodeOrCdata(rightsMatch?.group(1)),
        subtitle: _decodeOrCdata(subtitleMatch?.group(1)),
        links: links,
        authors: authors,
        contributors: contributors,
        categories: categories,
        generator: generator,
      );
    } catch (e) {
      throw ArgumentError(
          'Failed to parse Atom feed efficiently: \\${e.toString()}');
    }
  }

  /// Parse items using regex for better performance
  static List<AtomItem> _parseItemsEfficiently(String xmlString) {
    final items = <AtomItem>[];
    final entryPattern =
        RegExp(r'<entry(?![^<]*<!\[CDATA\[)[^>]*>(.*?)</entry>', dotAll: true);

    for (final match in entryPattern.allMatches(xmlString)) {
      final entryXml = match.group(0)!;
      final item = _parseItemEfficiently(entryXml);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Parse a single item efficiently
  static AtomItem? _parseItemEfficiently(String entryXml) {
    try {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
          .firstMatch(entryXml);
      final idMatch =
          RegExp(r'<id[^>]*>(.*?)</id>', dotAll: true).firstMatch(entryXml);
      final updatedMatch =
          RegExp(r'<updated[^>]*>(.*?)</updated>', dotAll: true)
              .firstMatch(entryXml);
      final summaryMatch =
          RegExp(r'<summary[^>]*>(.*?)</summary>', dotAll: true)
              .firstMatch(entryXml);
      final contentMatch =
          RegExp(r'<content[^>]*>(.*?)</content>', dotAll: true)
              .firstMatch(entryXml);

      return AtomItem(
        title: _decodeOrCdata(titleMatch?.group(1)),
        id: _decodeOrCdata(idMatch?.group(1)),
        updated: parseDateTime(_decodeOrCdata(updatedMatch?.group(1))),
        summary: _decodeOrCdata(summaryMatch?.group(1)),
        content: _decodeOrCdata(contentMatch?.group(1)),
        links: null,
        authors: null,
        contributors: null,
        categories: null,
        published: null,
        rights: null,
        source: null,
      );
    } catch (e) {
      return null;
    }
  }

  static String? _decodeOrCdata(String? text) {
    if (text == null) return null;
    final result = stripCdataWithFlag(text);
    final decoded = decodeHtmlEntities(result.value);
    final trimmed = decoded.trim();
    // For CDATA sections, return empty string if empty, not null
    if (result.isCdata) {
      return trimmed;
    }
    // For regular text, return null if empty
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Parse links efficiently using regex
  static List<AtomLink> _parseLinksEfficiently(String xmlString) {
    final links = <AtomLink>[];
    final linkPattern = RegExp(r'<link[^>]*>(.*?)</link>', dotAll: true);

    for (final match in linkPattern.allMatches(xmlString)) {
      final linkXml = match.group(0)!;
      final link = _parseLinkEfficiently(linkXml);
      if (link != null) {
        links.add(link);
      }
    }

    return links;
  }

  /// Parse a single link efficiently
  static AtomLink? _parseLinkEfficiently(String linkXml) {
    try {
      final hrefMatch = RegExp(r'href="([^"]*)"').firstMatch(linkXml);
      final relMatch = RegExp(r'rel="([^"]*)"').firstMatch(linkXml);
      final typeMatch = RegExp(r'type="([^"]*)"').firstMatch(linkXml);
      final titleMatch = RegExp(r'title="([^"]*)"').firstMatch(linkXml);

      return AtomLink(
        hrefMatch?.group(1),
        relMatch?.group(1),
        typeMatch?.group(1),
        null, // hreflang
        titleMatch?.group(1),
        0, // length
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse authors efficiently using regex
  static List<AtomPerson> _parseAuthorsEfficiently(String xmlString) {
    final authors = <AtomPerson>[];
    final authorPattern = RegExp(r'<author[^>]*>(.*?)</author>', dotAll: true);

    for (final match in authorPattern.allMatches(xmlString)) {
      final authorXml = match.group(0)!;
      final author = _parsePersonEfficiently(authorXml);
      if (author != null) {
        authors.add(author);
      }
    }

    return authors;
  }

  /// Parse contributors efficiently using regex
  static List<AtomPerson> _parseContributorsEfficiently(String xmlString) {
    final contributors = <AtomPerson>[];
    final contributorPattern =
        RegExp(r'<contributor[^>]*>(.*?)</contributor>', dotAll: true);

    for (final match in contributorPattern.allMatches(xmlString)) {
      final contributorXml = match.group(0)!;
      final contributor = _parsePersonEfficiently(contributorXml);
      if (contributor != null) {
        contributors.add(contributor);
      }
    }

    return contributors;
  }

  /// Parse a single person efficiently
  static AtomPerson? _parsePersonEfficiently(String personXml) {
    try {
      final nameMatch = RegExp(r'<name[^>]*>(.*?)</name>', dotAll: true)
          .firstMatch(personXml);
      final emailMatch = RegExp(r'<email[^>]*>(.*?)</email>', dotAll: true)
          .firstMatch(personXml);
      final uriMatch =
          RegExp(r'<uri[^>]*>(.*?)</uri>', dotAll: true).firstMatch(personXml);

      return AtomPerson(
        name: _decodeOrCdata(nameMatch?.group(1)),
        email: _decodeOrCdata(emailMatch?.group(1)),
        uri: _decodeOrCdata(uriMatch?.group(1)),
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse categories efficiently using regex
  static List<AtomCategory> _parseCategoriesEfficiently(String xmlString) {
    final categories = <AtomCategory>[];
    final categoryPattern =
        RegExp(r'<category[^>]*>(.*?)</category>', dotAll: true);

    for (final match in categoryPattern.allMatches(xmlString)) {
      final categoryXml = match.group(0)!;
      final category = _parseCategoryEfficiently(categoryXml);
      if (category != null) {
        categories.add(category);
      }
    }

    return categories;
  }

  /// Parse a single category efficiently
  static AtomCategory? _parseCategoryEfficiently(String categoryXml) {
    try {
      final termMatch = RegExp(r'term="([^"]*)"').firstMatch(categoryXml);
      final schemeMatch = RegExp(r'scheme="([^"]*)"').firstMatch(categoryXml);
      final labelMatch = RegExp(r'label="([^"]*)"').firstMatch(categoryXml);

      return AtomCategory(
        termMatch?.group(1),
        schemeMatch?.group(1),
        _decodeOrCdata(labelMatch?.group(1)),
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse generator efficiently using regex
  static AtomGenerator? _parseGeneratorEfficiently(String xmlString) {
    try {
      final generatorMatch =
          RegExp(r'<generator[^>]*>(.*?)</generator>', dotAll: true)
              .firstMatch(xmlString);
      if (generatorMatch == null) return null;

      final generatorXml = generatorMatch.group(0)!;
      final uriMatch = RegExp(r'uri="([^"]*)"').firstMatch(generatorXml);
      final versionMatch =
          RegExp(r'version="([^"]*)"').firstMatch(generatorXml);

      return AtomGenerator(
        uriMatch?.group(1),
        versionMatch?.group(1),
        _decodeOrCdata(generatorMatch.group(1)),
      );
    } catch (e) {
      return null;
    }
  }
}
