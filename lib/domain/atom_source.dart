import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/util/iterable.dart';
import 'package:xml/xml.dart';

class AtomSource {
  final String? id;
  final String? title;
  final String? updated;
  final String? icon;
  final String? logo;

  AtomSource({
    this.id,
    this.title,
    this.updated,
    this.icon,
    this.logo,
  });

  /// Get the best available image from this source
  FeedImage? get image {
    // Try logo first
    if (logo != null && logo!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(logo!) ?? (null, null);
      return FeedImage(
        url: logo!,
        width: width,
        height: height,
        source: 'atom:source/logo',
      );
    }

    // Try icon as fallback
    if (icon != null && icon!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(icon!) ?? (null, null);
      return FeedImage(
        url: icon!,
        width: width,
        height: height,
        source: 'atom:source/icon',
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

  factory AtomSource.parse(XmlElement element) {
    return AtomSource(
      id: element.findElements('id').firstOrNull?.text,
      title: element.findElements('title').firstOrNull?.text,
      updated: element.findElements('updated').firstOrNull?.text,
      icon: element.findElements('icon').firstOrNull?.text,
      logo: element.findElements('logo').firstOrNull?.text,
    );
  }
}
