import 'package:webfeed/domain/atom_category.dart';
import 'package:webfeed/domain/atom_link.dart';
import 'package:webfeed/domain/atom_person.dart';
import 'package:webfeed/domain/atom_source.dart';
import 'package:webfeed/domain/media/media.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/util/iterable.dart';
import 'package:xml/xml.dart';

class AtomItem {
  final String? id;
  final String? title;
  final DateTime? updated;

  final List<AtomPerson>? authors;
  final List<AtomLink>? links;
  final List<AtomCategory>? categories;
  final List<AtomPerson>? contributors;
  final AtomSource? source;
  final String? published;
  final String? content;
  final String? summary;
  final String? rights;
  final Media? media;

  AtomItem({
    this.id,
    this.title,
    this.updated,
    this.authors,
    this.links,
    this.categories,
    this.contributors,
    this.source,
    this.published,
    this.content,
    this.summary,
    this.rights,
    this.media,
  });
  
  /// Gets the best available image from the Atom item
  /// 
  /// This attempts to find the most suitable image from various possible sources:
  /// - media:content with medium="image" and largest available resolution
  /// - media:thumbnail with largest available resolution
  /// - links with rel="enclosure" and image type
  /// - image from the source if available
  /// 
  /// Returns null if no image is found.
  FeedImage? get image {
    // Try media:content items first (prefer those in media:group if available)
    if (media != null) {
      // First look for images in media:group
      if (media!.group != null && media!.group!.contents != null) {
        final mediaContents = media!.group!.contents!
            .where((content) => 
                content.medium == 'image' && 
                content.url != null &&
                content.url!.isNotEmpty)
            .toList();
            
        if (mediaContents.isNotEmpty) {
          // Sort by size (larger is better)
          mediaContents.sort((a, b) {
            final aSize = (a.width ?? 0) * (a.height ?? 0);
            final bSize = (b.width ?? 0) * (b.height ?? 0);
            return bSize.compareTo(aSize);
          });
          
          final bestContent = mediaContents.first;
          return FeedImage(
            url: bestContent.url!,
            width: bestContent.width,
            height: bestContent.height,
            type: bestContent.type,
            source: 'media:group/media:content',
          );
        }
      }
      
      // Then check standalone media:content
      if (media!.contents != null && media!.contents!.isNotEmpty) {
        final mediaContents = media!.contents!
            .where((content) => 
                content.medium == 'image' && 
                content.url != null &&
                content.url!.isNotEmpty)
            .toList();
            
        if (mediaContents.isNotEmpty) {
          // Sort by size (larger is better)
          mediaContents.sort((a, b) {
            final aSize = (a.width ?? 0) * (a.height ?? 0);
            final bSize = (b.width ?? 0) * (b.height ?? 0);
            return bSize.compareTo(aSize);
          });
          
          final bestContent = mediaContents.first;
          return FeedImage(
            url: bestContent.url!,
            width: bestContent.width,
            height: bestContent.height,
            type: bestContent.type,
            source: 'media:content',
          );
        }
      }
      
      // Check media:thumbnail
      if (media!.thumbnails != null && media!.thumbnails!.isNotEmpty) {
        final thumbnails = media!.thumbnails!
            .where((thumb) => thumb.url != null && thumb.url!.isNotEmpty)
            .toList();
            
        if (thumbnails.isNotEmpty) {
          // Sort by size (larger is better), but we need to parse string dimensions
          thumbnails.sort((a, b) {
            final aWidth = int.tryParse(a.width ?? '0') ?? 0;
            final aHeight = int.tryParse(a.height ?? '0') ?? 0;
            final bWidth = int.tryParse(b.width ?? '0') ?? 0;
            final bHeight = int.tryParse(b.height ?? '0') ?? 0;
            
            final aSize = aWidth * aHeight;
            final bSize = bWidth * bHeight;
            return bSize.compareTo(aSize);
          });
          
          final bestThumbnail = thumbnails.first;
          return FeedImage(
            url: bestThumbnail.url!,
            width: int.tryParse(bestThumbnail.width ?? ''),
            height: int.tryParse(bestThumbnail.height ?? ''),
            source: 'media:thumbnail',
          );
        }
      }
    }
    
    // Try enclosure links (links with rel="enclosure" and image type)
    if (links != null && links!.isNotEmpty) {
      final enclosureLinks = links!
          .where((link) => 
              link.rel == 'enclosure' && 
              link.href != null && 
              link.href!.isNotEmpty &&
              link.type != null &&
              (link.type!.startsWith('image/') || link.type == 'image'))
          .toList();
          
      if (enclosureLinks.isNotEmpty) {
        return FeedImage(
          url: enclosureLinks.first.href!,
          type: enclosureLinks.first.type,
          source: 'atom:link[rel=enclosure]',
        );
      }
    }
    
    // Try image from source if available
    if (source != null && source!.image != null) {
      return source!.image;
    }
    
    // No image found
    return null;
  }

  factory AtomItem.parse(XmlElement element) {
    return AtomItem(
      id: element.findElements('id').firstOrNull?.text,
      title: element.findElements('title').firstOrNull?.text,
      updated: parseDateTime(element.findElements('updated').firstOrNull?.text),
      authors: element
          .findElements('author')
          .map((e) => AtomPerson.parse(e))
          .toList(),
      links:
          element.findElements('link').map((e) => AtomLink.parse(e)).toList(),
      categories: element
          .findElements('category')
          .map((e) => AtomCategory.parse(e))
          .toList(),
      contributors: element
          .findElements('contributor')
          .map((e) => AtomPerson.parse(e))
          .toList(),
      source: element
          .findElements('source')
          .map((e) => AtomSource.parse(e))
          .firstOrNull,
      published: element.findElements('published').firstOrNull?.text,
      content: element.findElements('content').firstOrNull?.text,
      summary: element.findElements('summary').firstOrNull?.text,
      rights: element.findElements('rights').firstOrNull?.text,
      media: Media.parse(element),
    );
  }
}
