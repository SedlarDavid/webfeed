import 'dart:convert';

import 'package:webfeed/domain/json_feed_author.dart';
import 'package:webfeed/domain/json_feed_hub.dart';
import 'package:webfeed/domain/json_feed_item.dart';
import 'package:webfeed/domain/rss_item.dart';

/// JSON Feed model following the 1.1 specification
///
/// See: https://jsonfeed.org/version/1.1
class JsonFeed {
  /// The URL of the version of the format the feed uses
  final String version;

  /// The name of the feed
  final String? title;

  /// The URL of the resource that the feed describes
  final String? homePageUrl;

  /// The URL of the feed
  final String? feedUrl;

  /// Description of the feed
  final String? description;

  /// Human-readable text that explains the feed
  final String? userComment;

  /// The URL of the feed's next page
  final String? nextUrl;

  /// The URL of an image for the feed
  final String? icon;

  /// The URL of an image for the feed suitable for use in a source list
  final String? favicon;

  /// The feed's authors (can be single author or list)
  final List<JsonFeedAuthor>? authors;

  /// Single author (for backward compatibility with version 1)
  final JsonFeedAuthor? author;

  /// The primary language for the feed
  final String? language;

  /// Whether the feed is expired
  final bool? expired;

  /// The feed's hubs
  final List<JsonFeedHub>? hubs;

  /// The feed's items
  final List<JsonFeedItem>? items;

  /// Custom extensions (not part of the spec but commonly used)
  final Map<String, dynamic>? extensions;

  JsonFeed({
    required this.version,
    this.title,
    this.homePageUrl,
    this.feedUrl,
    this.description,
    this.userComment,
    this.nextUrl,
    this.icon,
    this.favicon,
    this.authors,
    this.author,
    this.language,
    this.expired,
    this.hubs,
    this.items,
    this.extensions,
  });

  /// Creates a JsonFeed from a JSON string
  factory JsonFeed.fromJson(String json) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(json);
      return JsonFeed.fromMap(jsonMap);
    } catch (e) {
      throw FormatException('Failed to parse JSON Feed: $e');
    }
  }

  /// Creates a JsonFeed from a Map
  factory JsonFeed.fromMap(Map<String, dynamic> json) {
    return JsonFeed(
      version: json['version'] as String? ?? 'https://jsonfeed.org/version/1.1',
      title: json['title'] as String?,
      homePageUrl: json['home_page_url'] as String?,
      feedUrl: json['feed_url'] as String?,
      description: json['description'] as String?,
      userComment: json['user_comment'] as String?,
      nextUrl: json['next_url'] as String?,
      icon: json['icon'] as String?,
      favicon: json['favicon'] as String?,
      authors: json['authors'] != null
          ? (json['authors'] as List)
              .map((author) => JsonFeedAuthor.fromMap(author))
              .toList()
          : null,
      author: json['author'] != null
          ? JsonFeedAuthor.fromMap(json['author'])
          : null,
      language: json['language'] as String?,
      expired: json['expired'] as bool?,
      hubs: json['hubs'] != null
          ? (json['hubs'] as List)
              .map((hub) => JsonFeedHub.fromMap(hub))
              .toList()
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => JsonFeedItem.fromMap(item))
              .toList()
          : null,
      extensions: _extractExtensions(json),
    );
  }

  /// Converts the JsonFeed to a Map
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'version': version,
    };

    if (title != null) json['title'] = title;
    if (homePageUrl != null) json['home_page_url'] = homePageUrl;
    if (feedUrl != null) json['feed_url'] = feedUrl;
    if (description != null) json['description'] = description;
    if (userComment != null) json['user_comment'] = userComment;
    if (nextUrl != null) json['next_url'] = nextUrl;
    if (icon != null) json['icon'] = icon;
    if (favicon != null) json['favicon'] = favicon;
    if (authors != null) {
      json['authors'] = authors!.map((author) => author.toJson()).toList();
    }
    if (author != null) {
      json['author'] = author!.toJson();
    }
    if (language != null) json['language'] = language;
    if (expired != null) json['expired'] = expired;
    if (hubs != null) {
      json['hubs'] = hubs!.map((hub) => hub.toJson()).toList();
    }
    if (items != null) {
      json['items'] = items!.map((item) => item.toJson()).toList();
    }

    // Add extensions
    if (extensions != null) {
      json.addAll(extensions!);
    }

    return json;
  }

  /// Gets the best available image for the feed
  ///
  /// This attempts to find the most suitable feed image from these sources:
  /// - icon (primary feed image)
  /// - favicon (smaller, suitable for source lists)
  /// - author avatar (if available)
  ///
  /// Returns null if no feed-level image is found.
  FeedImage? get feedImage {
    // Try icon first (primary feed image)
    if (icon != null && icon!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(icon!) ?? (null, null);
      return FeedImage(
        url: icon!,
        width: width,
        height: height,
        source: 'json:icon',
      );
    }

    // Try favicon as fallback
    if (favicon != null && favicon!.isNotEmpty) {
      final (width, height) =
          _extractDimensionsFromUrl(favicon!) ?? (null, null);
      return FeedImage(
        url: favicon!,
        width: width,
        height: height,
        source: 'json:favicon',
      );
    }

    // Try author avatar as fallback
    if (author != null &&
        author!.avatar != null &&
        author!.avatar!.isNotEmpty) {
      final (width, height) =
          _extractDimensionsFromUrl(author!.avatar!) ?? (null, null);
      return FeedImage(
        url: author!.avatar!,
        width: width,
        height: height,
        source: 'json:author:avatar',
      );
    }

    // Try first author avatar from authors list
    if (authors != null &&
        authors!.isNotEmpty &&
        authors!.first.avatar != null) {
      final (width, height) =
          _extractDimensionsFromUrl(authors!.first.avatar!) ?? (null, null);
      return FeedImage(
        url: authors!.first.avatar!,
        width: width,
        height: height,
        source: 'json:authors:avatar',
      );
    }

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
        final width = int.parse(match1.group(1)!);
        final height = int.parse(match1.group(2)!);
        return (width, height);
      }

      // Pattern 2: filename-width-WIDTH-height-HEIGHT.ext
      final dimensionPattern2 = RegExp(r'-width-(\d+)-height-(\d+)\.');
      final match2 = dimensionPattern2.firstMatch(url);
      if (match2 != null) {
        final width = int.parse(match2.group(1)!);
        final height = int.parse(match2.group(2)!);
        return (width, height);
      }

      // Pattern 3: filename_wWIDTH_hHEIGHT.ext
      final dimensionPattern3 = RegExp(r'_w(\d+)_h(\d+)\.');
      final match3 = dimensionPattern3.firstMatch(url);
      if (match3 != null) {
        final width = int.parse(match3.group(1)!);
        final height = int.parse(match3.group(2)!);
        return (width, height);
      }

      // Pattern 4: query parameters w=WIDTH&h=HEIGHT
      final dimensionPattern4 = RegExp(r'[?&]w=(\d+).*[?&]h=(\d+)');
      final match4 = dimensionPattern4.firstMatch(url);
      if (match4 != null) {
        final width = int.parse(match4.group(1)!);
        final height = int.parse(match4.group(2)!);
        return (width, height);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts custom extensions from the JSON
  ///
  /// Extensions are any properties that are not part of the JSON Feed specification
  static Map<String, dynamic>? _extractExtensions(Map<String, dynamic> json) {
    final standardFields = <String>{
      'version',
      'title',
      'home_page_url',
      'feed_url',
      'description',
      'user_comment',
      'next_url',
      'icon',
      'favicon',
      'authors',
      'author',
      'language',
      'expired',
      'hubs',
      'items',
    };

    final extensions = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!standardFields.contains(entry.key)) {
        extensions[entry.key] = entry.value;
      }
    }

    return extensions.isNotEmpty ? extensions : null;
  }

  @override
  String toString() {
    return 'JsonFeed(version: $version, title: $title, items: ${items?.length ?? 0})';
  }
}
