import 'dart:core';

import 'package:webfeed/domain/dublin_core/dublin_core.dart';
import 'package:webfeed/domain/itunes/itunes.dart';
import 'package:webfeed/domain/rss_category.dart';
import 'package:webfeed/domain/rss_cloud.dart';
import 'package:webfeed/domain/rss_image.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/domain/syndication/syndication.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/util/iterable.dart';
import 'package:webfeed/util/xml.dart';
import 'package:xml/xml.dart';

class RssFeed {
  final String? title;
  final String? author;
  final String? description;
  final String? link;
  final List<RssItem>? items;

  final RssImage? image;
  final RssCloud? cloud;
  final List<RssCategory>? categories;
  final List<String>? skipDays;
  final List<int>? skipHours;
  final String? lastBuildDate;
  final String? language;
  final String? generator;
  final String? copyright;
  final String? docs;
  final String? managingEditor;
  final String? rating;
  final String? webMaster;
  final String? atomLink;
  final int? ttl;
  final DublinCore? dc;
  final Itunes? itunes;
  final Syndication? syndication;

  RssFeed({
    this.title,
    this.author,
    this.description,
    this.link,
    this.items,
    this.image,
    this.cloud,
    this.categories,
    this.skipDays,
    this.skipHours,
    this.lastBuildDate,
    this.language,
    this.generator,
    this.copyright,
    this.docs,
    this.managingEditor,
    this.rating,
    this.webMaster,
    this.atomLink,
    this.ttl,
    this.dc,
    this.itunes,
    this.syndication,
  });

  /// Gets the best available image for the feed.
  ///
  /// This attempts to find the most suitable feed image from various possible sources:
  /// - RSS image
  /// - iTunes image
  ///
  /// Returns null if no feed-level image is found.
  FeedImage? get feedImage {
    // Try RSS feed image first
    if (image != null && image!.url != null && image!.url!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(image!.url!) ??
          (image!.width, image!.height);
      return FeedImage(
        url: image!.url!,
        title: image!.title,
        width: width,
        height: height,
        source: 'rss:image',
      );
    }

    // Try iTunes image
    if (itunes != null &&
        itunes!.image != null &&
        itunes!.image!.href != null) {
      final (width, height) =
          _extractDimensionsFromUrl(itunes!.image!.href!) ?? (null, null);
      return FeedImage(
        url: itunes!.image!.href!,
        width: width,
        height: height,
        source: 'itunes:image',
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

  factory RssFeed.parse(String xmlString, {bool withArticles = true}) {
    try {
      var document = XmlDocument.parse(xmlString);

      // Find RSS element - check for standard RSS or RDF-based RSS
      var rss = document.findElements('rss').firstOrNull;
      var rdf = document.findElements('rdf:RDF').firstOrNull;

      // Fallback to checking for RDF without namespace if not found with namespace
      if (rdf == null) {
        var allRdf = document.findAllElements('RDF');
        if (allRdf.isNotEmpty) {
          rdf = allRdf.first;
        }
      }

      if (rss == null && rdf == null) {
        throw ArgumentError('not a rss feed');
      }

      // Find channel element
      var channelElement = (rss ?? rdf)!.findElements('channel').firstOrNull;
      if (channelElement == null) {
        throw ArgumentError('channel not found');
      }

      // Find RSS items - they can be under channel in RSS 2.0 or directly under RDF in RSS 1.0
      var itemContainer = rdf ?? channelElement;

      // Parse the feed
      final items = withArticles
          ? itemContainer
              .findElements('item')
              .map((e) => RssItem.parse(e))
              .toList()
          : null;
      if (items != null) {
        for (var i = 0; i < items.length; i++) {}
      }
      return RssFeed(
        title: _normalizeField(_getTextContent(channelElement, 'title')),
        author: _normalizeField(_getTextContent(channelElement, 'author') ??
            _getTextContent(channelElement, 'creator')),
        description:
            _normalizeField(_getTextContent(channelElement, 'description')),
        link: _normalizeField(_getTextContent(channelElement, 'link')),
        atomLink: _normalizeField(_findAtomLink(channelElement)),
        items: items,
        image: _parseImage(rdf, channelElement),
        cloud: channelElement
            .findElements('cloud')
            .map((e) => RssCloud.parse(e))
            .firstOrNull,
        categories: findAllElementsWithNamespace(channelElement, 'category')
            .map((e) => RssCategory.parse(e))
            .toList(),
        skipDays: _parseSkipDays(channelElement),
        skipHours: _parseSkipHours(channelElement),
        lastBuildDate:
            _normalizeField(_getTextContent(channelElement, 'lastBuildDate')),
        language: _normalizeField(_getTextContent(channelElement, 'language')),
        generator:
            _normalizeField(_getTextContent(channelElement, 'generator')),
        copyright: _normalizeField(
            _getTextContent(channelElement, 'copyright') ??
                _getTextContent(channelElement, 'rights')),
        docs: _normalizeField(_getTextContent(channelElement, 'docs')),
        managingEditor:
            _normalizeField(_getTextContent(channelElement, 'managingEditor')),
        rating: _normalizeField(_getTextContent(channelElement, 'rating')),
        webMaster:
            _normalizeField(_getTextContent(channelElement, 'webMaster')),
        ttl: int.tryParse(
                _normalizeField(_getTextContent(channelElement, 'ttl')) ??
                    '0') ??
            0,
        dc: DublinCore.parse(channelElement),
        itunes: Itunes.parse(channelElement),
        syndication: Syndication.parse(channelElement),
      );
    } catch (e) {
      // Provide a more helpful error message
      throw ArgumentError('Failed to parse RSS feed: ${e.toString()}');
    }
  }

  // Helper to get text content with namespace support
  static String? _getTextContent(XmlElement element, String tagName) {
    final foundElement = findDirectElementWithNamespace(element, tagName);
    return extractTextContent(foundElement);
  }

  // Helper method to normalize field values (decode HTML entities and handle empty strings)
  static String? _normalizeField(String? text) {
    if (text == null) return null;
    final decoded = decodeHtmlEntities(text);
    final trimmed = decoded.trim();
    // Return empty string for empty content (consistent with CDATA handling)
    return trimmed;
  }

  // Parse atom:link with improved namespace handling
  static String? _findAtomLink(XmlElement element) {
    var atomLinks = findAllElementsWithNamespace(element, 'link')
        .where((link) => link.name.qualified.contains(':'))
        .toList();

    // First check for a link with rel="self"
    for (var link in atomLinks) {
      if (getAttributeWithNamespace(link, 'rel') == 'self') {
        return getAttributeWithNamespace(link, 'href') ??
            link.getAttribute('href');
      }
    }

    // Fall back to any atom:link if no self link is found
    return atomLinks.isNotEmpty
        ? getAttributeWithNamespace(atomLinks.first, 'href') ??
            atomLinks.first.getAttribute('href')
        : null;
  }

  // Parse skipDays with robust error handling
  static List<String> _parseSkipDays(XmlElement channelElement) {
    try {
      final skipDaysElement =
          findElementWithNamespace(channelElement, 'skipDays');
      if (skipDaysElement == null) return [];

      return findAllElementsWithNamespace(skipDaysElement, 'day')
          .map((e) => e.value?.trim() ?? e.innerText.trim())
          .where((text) => text.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Parse skipHours with robust error handling
  static List<int> _parseSkipHours(XmlElement channelElement) {
    try {
      final skipHoursElement =
          findElementWithNamespace(channelElement, 'skipHours');
      if (skipHoursElement == null) return [];

      return findAllElementsWithNamespace(skipHoursElement, 'hour')
          .map((e) => int.tryParse(e.value?.trim() ?? e.innerText.trim()) ?? -1)
          .where((hour) => hour >= 0 && hour <= 23)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Parse image with fallback for different locations
  static RssImage? _parseImage(XmlElement? rdf, XmlElement channelElement) {
    // Try RDF location first (RSS 1.0)
    if (rdf != null) {
      final rdfImage = findElementWithNamespace(rdf, 'image');
      if (rdfImage != null) {
        return RssImage.parse(rdfImage);
      }
    }

    // Try channel location (RSS 2.0)
    final channelImage = findElementWithNamespace(channelElement, 'image');
    if (channelImage != null) {
      return RssImage.parse(channelImage);
    }

    return null;
  }

  /// Efficient parsing method for large XML files
  /// Uses regex-based parsing instead of full DOM parsing for better performance
  static RssFeed parseEfficiently(String xmlString,
      {bool withArticles = true}) {
    try {
      // Extract basic metadata using regex for speed with CDATA support
      // Look for title specifically within channel element to avoid matching item titles
      final channelMatch =
          RegExp(r'<channel[^>]*>(.*?)</channel>', dotAll: true)
              .firstMatch(xmlString);
      final titleMatch = channelMatch != null
          ? RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
              .firstMatch(channelMatch.group(1)!.split(RegExp(r'<item[ >]'))[0])
          : null;
      final channelContent = channelMatch?.group(1) ?? '';
      final descriptionMatch =
          RegExp(r'<description[^>]*>(.*?)</description>', dotAll: true)
              .firstMatch(channelContent);
      final linkMatch = RegExp(r'<link[^>]*>(.*?)</link>', dotAll: true)
          .firstMatch(channelContent);
      final languageMatch =
          RegExp(r'<language[^>]*>(.*?)</language>', dotAll: true)
              .firstMatch(channelContent);
      final generatorMatch =
          RegExp(r'<generator[^>]*>(.*?)</generator>', dotAll: true)
              .firstMatch(channelContent);
      final copyrightMatch =
          RegExp(r'<copyright[^>]*>(.*?)</copyright>', dotAll: true)
              .firstMatch(channelContent);
      final lastBuildDateMatch =
          RegExp(r'<lastBuildDate[^>]*>(.*?)</lastBuildDate>', dotAll: true)
              .firstMatch(channelContent);
      final authorMatch = RegExp(r'<author[^>]*>(.*?)</author>', dotAll: true)
          .firstMatch(channelContent);
      final managingEditorMatch =
          RegExp(r'<managingEditor[^>]*>(.*?)</managingEditor>', dotAll: true)
              .firstMatch(channelContent);
      final ratingMatch = RegExp(r'<rating[^>]*>(.*?)</rating>', dotAll: true)
          .firstMatch(channelContent);
      final webMasterMatch =
          RegExp(r'<webMaster[^>]*>(.*?)</webMaster>', dotAll: true)
              .firstMatch(channelContent);
      final docsMatch = RegExp(r'<docs[^>]*>(.*?)</docs>', dotAll: true)
          .firstMatch(channelContent);
      final ttlMatch = RegExp(r'<ttl[^>]*>(.*?)</ttl>', dotAll: true)
          .firstMatch(channelContent);

      // Parse complex elements efficiently
      final image = _parseImageEfficiently(xmlString);
      final cloud = _parseCloudEfficiently(xmlString);
      final categories = _parseCategoriesEfficiently(xmlString);
      final skipDays = _parseSkipDaysEfficiently(xmlString);
      final skipHours = _parseSkipHoursEfficiently(xmlString);
      final atomLink = _parseAtomLinkEfficiently(xmlString);
      final dc = _parseDublinCoreEfficiently(xmlString);
      final itunes = _parseItunesEfficiently(xmlString);
      final syndication = _parseSyndicationEfficiently(xmlString);

      // Parse items efficiently if requested
      List<RssItem>? items;
      if (withArticles) {
        items = _parseItemsEfficiently(xmlString);
      }

      if (items != null) {}

      return RssFeed(
        title: _decodeOrCdata(titleMatch?.group(1)),
        description: _decodeOrCdata(descriptionMatch?.group(1)),
        link: _decodeOrCdata(linkMatch?.group(1)),
        language: _decodeOrCdata(languageMatch?.group(1)),
        generator: _decodeOrCdata(generatorMatch?.group(1)),
        copyright: _decodeOrCdata(copyrightMatch?.group(1)),
        lastBuildDate: _decodeOrCdata(lastBuildDateMatch?.group(1)),
        author: _decodeOrCdata(authorMatch?.group(1)),
        managingEditor: _decodeOrCdata(managingEditorMatch?.group(1)),
        rating: _decodeOrCdata(ratingMatch?.group(1)),
        webMaster: _decodeOrCdata(webMasterMatch?.group(1)),
        docs: _decodeOrCdata(docsMatch?.group(1)),
        ttl: int.tryParse(_decodeOrCdata(ttlMatch?.group(1)) ?? '') ?? 0,
        items: items,
        image: image,
        cloud: cloud,
        categories: categories,
        skipDays: skipDays,
        skipHours: skipHours,
        atomLink: atomLink,
        dc: dc,
        itunes: itunes,
        syndication: syndication,
      );
    } catch (e) {
      throw ArgumentError(
          'Failed to parse RSS feed efficiently: ${e.toString()}');
    }
  }

  /// Parse items using regex for better performance
  static List<RssItem> _parseItemsEfficiently(String xmlString) {
    final items = <RssItem>[];
    final itemPattern =
        RegExp(r'<item(?![^<]*<!\[CDATA\[)[^>]*>(.*?)</item>', dotAll: true);

    for (final match in itemPattern.allMatches(xmlString)) {
      final itemXml = match.group(0)!;
      final item = _parseItemEfficiently(itemXml);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  /// Parse a single item efficiently
  static RssItem? _parseItemEfficiently(String itemXml) {
    try {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
          .firstMatch(itemXml);
      final descriptionMatch =
          RegExp(r'<description[^>]*>(.*?)</description>', dotAll: true)
              .firstMatch(itemXml);
      final linkMatch =
          RegExp(r'<link[^>]*>(.*?)</link>', dotAll: true).firstMatch(itemXml);
      final guidMatch =
          RegExp(r'<guid[^>]*>(.*?)</guid>', dotAll: true).firstMatch(itemXml);
      final pubDateMatch =
          RegExp(r'<pubDate[^>]*>(.*?)</pubDate>', dotAll: true)
              .firstMatch(itemXml);
      final authorMatch = RegExp(r'<author[^>]*>(.*?)</author>', dotAll: true)
          .firstMatch(itemXml);

      return RssItem(
        title: _decodeOrCdata(titleMatch?.group(1)),
        description: _decodeOrCdata(descriptionMatch?.group(1)),
        link: _decodeOrCdata(linkMatch?.group(1)),
        guid: _decodeOrCdata(guidMatch?.group(1)),
        pubDate: parseDateTime(_decodeOrCdata(pubDateMatch?.group(1))),
        author: _decodeOrCdata(authorMatch?.group(1)),
        categories: null,
        comments: null,
        source: null,
        content: null,
        media: null,
        enclosure: null,
        dc: null,
        itunes: null,
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

  /// Parse image efficiently using regex
  static RssImage? _parseImageEfficiently(String xmlString) {
    try {
      final imageMatch = RegExp(r'<image[^>]*>(.*?)</image>', dotAll: true)
          .firstMatch(xmlString);
      if (imageMatch == null) return null;

      final imageXml = imageMatch.group(0)!;
      final urlMatch =
          RegExp(r'<url[^>]*>(.*?)</url>', dotAll: true).firstMatch(imageXml);
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', dotAll: true)
          .firstMatch(imageXml);
      final linkMatch =
          RegExp(r'<link[^>]*>(.*?)</link>', dotAll: true).firstMatch(imageXml);
      final widthMatch = RegExp(r'<width[^>]*>(.*?)</width>', dotAll: true)
          .firstMatch(imageXml);
      final heightMatch = RegExp(r'<height[^>]*>(.*?)</height>', dotAll: true)
          .firstMatch(imageXml);

      return RssImage(
        url: _decodeOrCdata(urlMatch?.group(1)),
        title: _decodeOrCdata(titleMatch?.group(1)),
        link: _decodeOrCdata(linkMatch?.group(1)),
        width: int.tryParse(_decodeOrCdata(widthMatch?.group(1)) ?? '') ?? 0,
        height: int.tryParse(_decodeOrCdata(heightMatch?.group(1)) ?? '') ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse cloud efficiently using regex
  static RssCloud? _parseCloudEfficiently(String xmlString) {
    try {
      final cloudMatch = RegExp(r'<cloud[^>]*>(.*?)</cloud>', dotAll: true)
          .firstMatch(xmlString);
      if (cloudMatch == null) return null;

      final cloudXml = cloudMatch.group(0)!;
      final domainMatch = RegExp(r'domain="([^"]*)"').firstMatch(cloudXml);
      final portMatch = RegExp(r'port="([^"]*)"').firstMatch(cloudXml);
      final pathMatch = RegExp(r'path="([^"]*)"').firstMatch(cloudXml);
      final registerProcedureMatch =
          RegExp(r'registerProcedure="([^"]*)"').firstMatch(cloudXml);
      final protocolMatch = RegExp(r'protocol="([^"]*)"').firstMatch(cloudXml);

      return RssCloud(
        domainMatch?.group(1),
        portMatch?.group(1),
        pathMatch?.group(1),
        registerProcedureMatch?.group(1),
        protocolMatch?.group(1),
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse categories efficiently using regex
  static List<RssCategory> _parseCategoriesEfficiently(String xmlString) {
    final categories = <RssCategory>[];
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
  static RssCategory? _parseCategoryEfficiently(String categoryXml) {
    try {
      final domainMatch = RegExp(r'domain="([^"]*)"').firstMatch(categoryXml);
      final contentMatch =
          RegExp(r'<category[^>]*>(.*?)</category>', dotAll: true)
              .firstMatch(categoryXml);
      final content = _decodeOrCdata(contentMatch?.group(1));

      return RssCategory(
        domainMatch?.group(1),
        content ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse skipDays efficiently using regex
  static List<String> _parseSkipDaysEfficiently(String xmlString) {
    try {
      final skipDaysMatch =
          RegExp(r'<skipDays[^>]*>(.*?)</skipDays>', dotAll: true)
              .firstMatch(xmlString);
      if (skipDaysMatch == null) return [];

      final skipDaysXml = skipDaysMatch.group(0)!;
      final dayPattern = RegExp(r'<day[^>]*>(.*?)</day>', dotAll: true);
      final days = <String>[];

      for (final match in dayPattern.allMatches(skipDaysXml)) {
        final day = _decodeOrCdata(match.group(1));
        if (day != null && day.isNotEmpty) {
          days.add(day);
        }
      }

      return days;
    } catch (e) {
      return [];
    }
  }

  /// Parse skipHours efficiently using regex
  static List<int> _parseSkipHoursEfficiently(String xmlString) {
    try {
      final skipHoursMatch =
          RegExp(r'<skipHours[^>]*>(.*?)</skipHours>', dotAll: true)
              .firstMatch(xmlString);
      if (skipHoursMatch == null) return [];

      final skipHoursXml = skipHoursMatch.group(0)!;
      final hourPattern = RegExp(r'<hour[^>]*>(.*?)</hour>', dotAll: true);
      final hours = <int>[];

      for (final match in hourPattern.allMatches(skipHoursXml)) {
        final hour = int.tryParse(_decodeOrCdata(match.group(1)) ?? '') ?? -1;
        if (hour >= 0 && hour <= 23) {
          hours.add(hour);
        }
      }

      return hours;
    } catch (e) {
      return [];
    }
  }

  /// Parse atom link efficiently using regex
  static String? _parseAtomLinkEfficiently(String xmlString) {
    try {
      final atomLinkPattern = RegExp(r'<atom:link[^>]*>', dotAll: true);
      final matches = atomLinkPattern.allMatches(xmlString);

      for (final match in matches) {
        final linkXml = match.group(0)!;
        final relMatch = RegExp(r'rel="([^"]*)"').firstMatch(linkXml);
        final hrefMatch = RegExp(r'href="([^"]*)"').firstMatch(linkXml);

        if (relMatch?.group(1) == 'self' && hrefMatch != null) {
          return hrefMatch.group(1);
        }
      }

      // Fallback to any atom:link
      final firstAtomLink = atomLinkPattern.firstMatch(xmlString);
      if (firstAtomLink != null) {
        final linkXml = firstAtomLink.group(0)!;
        final hrefMatch = RegExp(r'href="([^"]*)"').firstMatch(linkXml);
        return hrefMatch?.group(1);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse Dublin Core efficiently using regex
  static DublinCore? _parseDublinCoreEfficiently(String xmlString) {
    try {
      // This is a simplified version - in practice, you'd want to parse all DC fields
      final creatorMatch =
          RegExp(r'<dc:creator[^>]*>(.*?)</dc:creator>', dotAll: true)
              .firstMatch(xmlString);
      final dateMatch = RegExp(r'<dc:date[^>]*>(.*?)</dc:date>', dotAll: true)
          .firstMatch(xmlString);

      if (creatorMatch == null && dateMatch == null) return null;

      return DublinCore(
        creator: _decodeOrCdata(creatorMatch?.group(1)),
        date: parseDateTime(_decodeOrCdata(dateMatch?.group(1))),
        // Add other DC fields as needed
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse iTunes efficiently using regex
  static Itunes? _parseItunesEfficiently(String xmlString) {
    try {
      // This is a simplified version - in practice, you'd want to parse all iTunes fields
      final authorMatch =
          RegExp(r'<itunes:author[^>]*>(.*?)</itunes:author>', dotAll: true)
              .firstMatch(xmlString);
      final summaryMatch =
          RegExp(r'<itunes:summary[^>]*>(.*?)</itunes:summary>', dotAll: true)
              .firstMatch(xmlString);

      if (authorMatch == null && summaryMatch == null) return null;

      return Itunes(
        author: _decodeOrCdata(authorMatch?.group(1)),
        summary: _decodeOrCdata(summaryMatch?.group(1)),
        // Add other iTunes fields as needed
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse Syndication efficiently using regex
  static Syndication? _parseSyndicationEfficiently(String xmlString) {
    try {
      // This is a simplified version - in practice, you'd want to parse all Syndication fields
      final updatePeriodMatch =
          RegExp(r'<sy:updatePeriod[^>]*>(.*?)</sy:updatePeriod>', dotAll: true)
              .firstMatch(xmlString);
      final updateFrequencyMatch = RegExp(
              r'<sy:updateFrequency[^>]*>(.*?)</sy:updateFrequency>',
              dotAll: true)
          .firstMatch(xmlString);

      if (updatePeriodMatch == null && updateFrequencyMatch == null)
        return null;

      SyndicationUpdatePeriod updatePeriod;
      switch (_decodeOrCdata(updatePeriodMatch?.group(1))) {
        case 'hourly':
          updatePeriod = SyndicationUpdatePeriod.hourly;
          break;
        case 'daily':
          updatePeriod = SyndicationUpdatePeriod.daily;
          break;
        case 'weekly':
          updatePeriod = SyndicationUpdatePeriod.weekly;
          break;
        case 'monthly':
          updatePeriod = SyndicationUpdatePeriod.monthly;
          break;
        case 'yearly':
          updatePeriod = SyndicationUpdatePeriod.yearly;
          break;
        default:
          updatePeriod = SyndicationUpdatePeriod.daily;
          break;
      }

      return Syndication(
        updatePeriod: updatePeriod,
        updateFrequency: int.tryParse(
                _decodeOrCdata(updateFrequencyMatch?.group(1)) ?? '') ??
            0,
        // Add other Syndication fields as needed
      );
    } catch (e) {
      return null;
    }
  }
}
