import 'dart:core';

import 'package:webfeed/domain/dublin_core/dublin_core.dart';
import 'package:webfeed/domain/itunes/itunes.dart';
import 'package:webfeed/domain/rss_category.dart';
import 'package:webfeed/domain/rss_cloud.dart';
import 'package:webfeed/domain/rss_image.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/domain/syndication/syndication.dart';
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
      return FeedImage(
        url: image!.url!,
        title: image!.title,
        source: 'rss:image',
      );
    }
    
    // Try iTunes image
    if (itunes != null && itunes!.image != null && itunes!.image!.href != null) {
      return FeedImage(
        url: itunes!.image!.href!,
        source: 'itunes:image',
      );
    }
    
    // No feed-level image found
    return null;
  }

  factory RssFeed.parse(String xmlString) {
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
      return RssFeed(
        title: _getTextContent(channelElement, 'title'),
        author: _getTextContent(channelElement, 'author') ??
            _getTextContent(channelElement, 'creator'),
        description: _getTextContent(channelElement, 'description'),
        link: _getTextContent(channelElement, 'link'),

        // Look for atom:link with type application/rss+xml and rel=self
        atomLink: _findAtomLink(channelElement),

        items: itemContainer
            .findAllElements('item')
            .map((e) => RssItem.parse(e))
            .toList(),

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

        lastBuildDate: _getTextContent(channelElement, 'lastBuildDate'),
        language: _getTextContent(channelElement, 'language'),
        generator: _getTextContent(channelElement, 'generator'),
        copyright: _getTextContent(channelElement, 'copyright') ??
            _getTextContent(channelElement, 'rights'),
        docs: _getTextContent(channelElement, 'docs'),
        managingEditor: _getTextContent(channelElement, 'managingEditor'),
        rating: _getTextContent(channelElement, 'rating'),
        webMaster: _getTextContent(channelElement, 'webMaster'),
        ttl: int.tryParse(_getTextContent(channelElement, 'ttl') ?? '') ?? 0,

        // Parse additional namespaces
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
    final foundElement = findElementWithNamespace(element, tagName);
    return foundElement != null
        ? (foundElement.value?.trim() ??
            foundElement.text.trim() ??
            foundElement.innerText.trim())
        : null;
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
          .map((e) => e.value?.trim() ?? e.text.trim() ?? e.innerText.trim())
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
          .map((e) =>
              int.tryParse(
                  e.value?.trim() ?? e.text.trim() ?? e.innerText.trim()) ??
              -1)
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
}
