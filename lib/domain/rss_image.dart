import 'package:webfeed/util/iterable.dart';
import 'package:xml/xml.dart';

class RssImage {
  final String? title;
  final String? url;
  final String? link;
  final int? width;
  final int? height;

  RssImage({this.title, this.url, this.link, this.width, this.height});

  factory RssImage.parse(XmlElement element) {
    return RssImage(
      title: element.findElements('title').firstOrNull?.text,
      url: element.findElements('url').firstOrNull?.text,
      link: element.findElements('link').firstOrNull?.text,
      width:
          int.tryParse(element.findElements('width').firstOrNull?.text ?? ''),
      height:
          int.tryParse(element.findElements('height').firstOrNull?.text ?? ''),
    );
  }
}
