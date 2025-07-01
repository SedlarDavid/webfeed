import 'package:webfeed/domain/atom_category.dart';
import 'package:webfeed/domain/atom_generator.dart';
import 'package:webfeed/domain/atom_item.dart';
import 'package:webfeed/domain/atom_link.dart';
import 'package:webfeed/domain/atom_person.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/util/iterable.dart';
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

    return AtomFeed(
      id: feedElement.findElements('id').firstOrNull?.value?.trim() ??
          feedElement.findElements('id').firstOrNull?.text.trim() ??
          feedElement.findElements('id').firstOrNull?.innerText.trim(),
      title: feedElement.findElements('title').firstOrNull?.value?.trim() ??
          feedElement.findElements('title').firstOrNull?.text.trim() ??
          feedElement.findElements('title').firstOrNull?.innerText.trim(),
      updated: parseDateTime(feedElement
              .findElements('updated')
              .firstOrNull
              ?.value
              ?.trim() ??
          feedElement.findElements('updated').firstOrNull?.text.trim() ??
          feedElement.findElements('updated').firstOrNull?.innerText.trim()),
      items: withArticles
          ? feedElement
              .findElements('entry')
              .map((e) => AtomItem.parse(e))
              .toList()
          : null,
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
      icon: feedElement.findElements('icon').firstOrNull?.value?.trim() ??
          feedElement.findElements('icon').firstOrNull?.text.trim() ??
          feedElement.findElements('icon').firstOrNull?.innerText.trim(),
      logo: feedElement.findElements('logo').firstOrNull?.value?.trim() ??
          feedElement.findElements('logo').firstOrNull?.text.trim() ??
          feedElement.findElements('logo').firstOrNull?.innerText.trim(),
      rights: feedElement.findElements('rights').firstOrNull?.value?.trim() ??
          feedElement.findElements('rights').firstOrNull?.text.trim() ??
          feedElement.findElements('rights').firstOrNull?.innerText.trim(),
      subtitle: feedElement
              .findElements('subtitle')
              .firstOrNull
              ?.value
              ?.trim() ??
          feedElement.findElements('subtitle').firstOrNull?.text.trim() ??
          feedElement.findElements('subtitle').firstOrNull?.innerText.trim(),
    );
  }
}
