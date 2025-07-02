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
        decodeHtmlEntities,
        validateXmlForUnclosedTags,
        findDirectElementWithNamespace,
        extractTextContent;
import 'package:xml/xml.dart';
import 'package:webfeed/domain/atom_source.dart';

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
    try {
      // Validate for unclosed tags before parsing
      validateXmlForUnclosedTags(xmlString);

      // Handle multiple XML declarations by keeping only the first one
      var cleanedXml = xmlString;
      final xmlDeclarations = RegExp(r'<\?xml[^>]*\?>').allMatches(xmlString);
      if (xmlDeclarations.length > 1) {
        // Remove all XML declarations and add back only the first one
        cleanedXml = xmlString.replaceAll(RegExp(r'<\?xml[^>]*\?>'), '');
        final firstDeclaration = xmlDeclarations.first.group(0)!;
        cleanedXml = firstDeclaration + cleanedXml;
      }

      var document = XmlDocument.parse(cleanedXml);
      var feedElement = document.findElements('feed').firstOrNull;
      if (feedElement == null) {
        throw ArgumentError('feed not found');
      }
      final entryElements = feedElement.findElements('entry').toList();
      final parsedItems = entryElements.map((e) => AtomItem.parse(e)).toList();
      // Return null for empty lists instead of empty list
      final finalItems = parsedItems.isEmpty ? null : parsedItems;
      return AtomFeed(
        id: _normalizeField(_getDirectTextContent(feedElement, 'id')),
        title: _normalizeField(_getDirectTextContent(feedElement, 'title')),
        updated: parseDateTime(_getDirectTextContent(feedElement, 'updated')),
        items: withArticles ? finalItems : null,
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
        icon: _normalizeField(_getDirectTextContent(feedElement, 'icon')),
        logo: _normalizeField(_getDirectTextContent(feedElement, 'logo')),
        rights: _normalizeField(_getDirectTextContent(feedElement, 'rights')),
        subtitle:
            _normalizeField(_getDirectTextContent(feedElement, 'subtitle')),
      );
    } catch (e) {
      if (e.toString().contains('XmlParserException') ||
          e.toString().contains('XmlTagException') ||
          e.toString().contains('Expected') ||
          e.toString().contains('but found')) {
        throw ArgumentError('Malformed XML: [31m${e.toString()}[0m');
      }
      throw ArgumentError('Failed to parse Atom feed: ${e.toString()}');
    }
  }

  // Helper method to normalize field values (decode HTML entities and handle empty strings)
  static String? _normalizeField(String? text) {
    if (text == null) return null;
    final decoded = decodeHtmlEntities(text);
    final trimmed = decoded.trim();
    // Return empty string for empty content (consistent with CDATA handling)
    return trimmed;
  }

  // Helper method to get text content from direct child elements only (not descendants)
  static String? _getDirectTextContent(XmlElement element, String tagName) {
    final directElement = findDirectElementWithNamespace(element, tagName);
    return extractTextContent(directElement);
  }

  static String? _decodeOrCdata(String? text) {
    if (text == null) return null;
    var result = text;
    // Recursively strip all CDATA markers
    while (result.contains('<![CDATA[') && result.contains(']]>')) {
      result = result
          .replaceAll(RegExp(r'<!\[CDATA\['), '')
          .replaceAll(RegExp(r']]>', dotAll: true), '');
    }
    final decoded = decodeHtmlEntities(result);
    final trimmed = decoded.trim();
    // For CDATA sections, return empty string if empty, not null
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Efficient parsing method for large XML files
  /// Uses regex-based parsing instead of full DOM parsing for better performance
  static AtomFeed parseEfficiently(String xmlString,
      {bool withArticles = true}) {
    try {
      // Validate for unclosed tags before parsing
      validateXmlForUnclosedTags(xmlString);

      // Handle multiple XML declarations by keeping only the first one
      var cleanedXml = xmlString;
      final xmlDeclarations = RegExp(r'<\?xml[^>]*\?>').allMatches(xmlString);
      if (xmlDeclarations.length > 1) {
        // Remove all XML declarations and add back only the first one
        cleanedXml = xmlString.replaceAll(RegExp(r'<\?xml[^>]*\?>'), '');
        final firstDeclaration = xmlDeclarations.first.group(0)!;
        cleanedXml = firstDeclaration + cleanedXml;
      }

      final feedMatch = RegExp(r'<feed[^>]*>(.*?)</feed>', dotAll: true)
          .firstMatch(cleanedXml);
      final feedContent = feedMatch?.group(1) ?? '';
      // Only match feed-level fields before the first <entry> (if any)
      String? feedTitle;
      final entryTagMatch =
          RegExp(r'<entry[\s>]', dotAll: true).firstMatch(feedContent);
      final beforeEntry = entryTagMatch == null
          ? feedContent
          : feedContent.substring(0, entryTagMatch.start);
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
          .firstMatch(beforeEntry);
      feedTitle =
          titleMatch != null ? _decodeOrCdata(titleMatch.group(1)) : null;
      final idMatch =
          RegExp(r'<id[^>]*>(.*?)</id>', dotAll: true).firstMatch(beforeEntry);
      final updatedMatch =
          RegExp(r'<updated[^>]*>(.*?)</updated>', dotAll: true)
              .firstMatch(beforeEntry);
      final iconMatch = RegExp(r'<icon[^>]*>(.*?)</icon>', dotAll: true)
          .firstMatch(beforeEntry);
      final logoMatch = RegExp(r'<logo[^>]*>(.*?)</logo>', dotAll: true)
          .firstMatch(beforeEntry);
      final rightsMatch = RegExp(r'<rights[^>]*>(.*?)</rights>', dotAll: true)
          .firstMatch(beforeEntry);
      final subtitleMatch =
          RegExp(r'<subtitle[^>]*>(.*?)</subtitle>', dotAll: true)
              .firstMatch(beforeEntry);
      // Only parse links, authors, contributors, categories from beforeEntry
      final links = _parseLinksEfficiently(beforeEntry);
      final authors = _parseAuthorsEfficiently(beforeEntry);
      final contributors = _parseContributorsEfficiently(beforeEntry);
      final categories = _parseCategoriesEfficiently(beforeEntry);
      final generator = _parseGeneratorEfficiently(beforeEntry);
      List<AtomItem>? items;
      if (withArticles) {
        items = _parseItemsEfficiently(cleanedXml);
      }
      // Return empty list instead of null for consistency
      final finalItems = items ?? <AtomItem>[];
      return AtomFeed(
        id: _decodeOrCdata(idMatch?.group(1)),
        title: feedTitle,
        updated: parseDateTime(_decodeOrCdata(updatedMatch?.group(1))),
        items: finalItems.isEmpty ? null : finalItems,
        icon: _decodeOrCdata(iconMatch?.group(1)),
        logo: _decodeOrCdata(logoMatch?.group(1)),
        rights: _decodeOrCdata(rightsMatch?.group(1)),
        subtitle: _decodeOrCdata(subtitleMatch?.group(1)),
        links: links.isEmpty ? <AtomLink>[] : links,
        authors: authors.isEmpty ? <AtomPerson>[] : authors,
        contributors: contributors.isEmpty ? <AtomPerson>[] : contributors,
        categories: categories.isEmpty ? <AtomCategory>[] : categories,
        generator: generator,
      );
    } catch (e) {
      if (e.toString().contains('XmlParserException') ||
          e.toString().contains('XmlTagException') ||
          e.toString().contains('Expected') ||
          e.toString().contains('but found')) {
        throw ArgumentError('Malformed XML: ${e.toString()}');
      }
      throw ArgumentError(
          'Failed to parse Atom feed efficiently: ${e.toString()}');
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
      final publishedMatch =
          RegExp(r'<published[^>]*>(.*?)</published>', dotAll: true)
              .firstMatch(entryXml);
      final rightsMatch = RegExp(r'<rights[^>]*>(.*?)</rights>', dotAll: true)
          .firstMatch(entryXml);

      // Parse links, authors, contributors, and categories
      final links = _parseLinksEfficiently(entryXml);
      final authors = _parseAuthorsEfficiently(entryXml);
      final contributors = _parseContributorsEfficiently(entryXml);
      final categories = _parseCategoriesEfficiently(entryXml);
      // Parse source if present
      final sourceMatch = RegExp(r'<source[^>]*>(.*?)</source>', dotAll: true)
          .firstMatch(entryXml);
      final source = sourceMatch != null
          ? _parseSourceEfficiently(sourceMatch.group(0)!)
          : null;

      return AtomItem(
        title: _decodeOrCdata(titleMatch?.group(1)),
        id: _decodeOrCdata(idMatch?.group(1)),
        updated: parseDateTime(_decodeOrCdata(updatedMatch?.group(1))),
        summary: _decodeOrCdata(summaryMatch?.group(1)),
        content: _decodeOrCdata(contentMatch?.group(1)),
        links: links,
        authors: authors,
        contributors: contributors,
        categories: categories,
        published: _decodeOrCdata(publishedMatch?.group(1)),
        rights: _decodeOrCdata(rightsMatch?.group(1)),
        source: source,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse links efficiently using regex
  static List<AtomLink> _parseLinksEfficiently(String xmlString) {
    final links = <AtomLink>[];
    // Match both self-closing <link ... /> and opening/closing <link>...</link> tags
    final linkPattern = RegExp(r'<link[^>]*?(?:/>|>.*?</link>)', dotAll: true);

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
      final hreflangMatch = RegExp(r'hreflang="([^"]*)"').firstMatch(linkXml);
      final lengthMatch = RegExp(r'length="([^"]*)"').firstMatch(linkXml);
      var length = 0;
      if (lengthMatch != null) {
        length = int.tryParse(lengthMatch.group(1) ?? '0') ?? 0;
      }
      return AtomLink(
        hrefMatch?.group(1),
        relMatch?.group(1),
        typeMatch?.group(1),
        hreflangMatch?.group(1),
        titleMatch?.group(1),
        length,
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
    // Match both self-closing <category ... /> and opening/closing <category>...</category> tags
    final categoryPattern =
        RegExp(r'<category[^>]*?(?:/>|>.*?</category>)', dotAll: true);

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

  // _parseSourceEfficiently should return a valid AtomSource or null
  static AtomSource? _parseSourceEfficiently(String sourceXml) {
    try {
      final idMatch =
          RegExp(r'<id[^>]*>(.*?)</id>', dotAll: true).firstMatch(sourceXml);
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
          .firstMatch(sourceXml);
      final updatedMatch =
          RegExp(r'<updated[^>]*>(.*?)</updated>', dotAll: true)
              .firstMatch(sourceXml);
      return AtomSource(
        id: _decodeOrCdata(idMatch?.group(1)),
        title: _decodeOrCdata(titleMatch?.group(1)),
        updated: _decodeOrCdata(updatedMatch?.group(1)),
      );
    } catch (e) {
      return null;
    }
  }
}
