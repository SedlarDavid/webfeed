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
      return FeedImage(
        url: logo!,
        source: 'atom:source/logo',
      );
    }
    
    // Try icon as fallback
    if (icon != null && icon!.isNotEmpty) {
      return FeedImage(
        url: icon!,
        source: 'atom:source/icon',
      );
    }
    
    return null;
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
