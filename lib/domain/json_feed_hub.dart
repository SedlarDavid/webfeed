/// Represents a hub in a JSON Feed
class JsonFeedHub {
  /// The type of the hub
  final String type;

  /// The URL of the hub
  final String url;

  JsonFeedHub({
    required this.type,
    required this.url,
  });

  /// Creates a JsonFeedHub from a Map
  factory JsonFeedHub.fromMap(Map<String, dynamic> json) {
    return JsonFeedHub(
      type: json['type'] as String,
      url: json['url'] as String,
    );
  }

  /// Converts the JsonFeedHub to a Map
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'url': url,
    };
  }

  @override
  String toString() {
    return 'JsonFeedHub(type: $type, url: $url)';
  }
}
