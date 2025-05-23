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
      return FeedImage(
        url: logo!,
        source: 'atom:logo',
      );
    }

    // Try Atom icon
    if (icon != null && icon!.isNotEmpty) {
      return FeedImage(
        url: icon!,
        source: 'atom:icon',
      );
    }

    // No feed-level image found
    return null;
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
      items: feedElement
          .findElements('entry')
          .map((e) => AtomItem.parse(e))
          .toList(),
      links: withArticles
          ? feedElement
              .findElements('link')
              .map((e) => AtomLink.parse(e))
              .toList()
          : null,
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
