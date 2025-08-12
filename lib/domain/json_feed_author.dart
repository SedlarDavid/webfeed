/// Represents an author in a JSON Feed
class JsonFeedAuthor {
  /// The author's name
  final String? name;

  /// The URL of a site owned by the author
  final String? url;

  /// The URL of an image for the author
  final String? avatar;

  JsonFeedAuthor({
    this.name,
    this.url,
    this.avatar,
  });

  /// Creates a JsonFeedAuthor from a Map
  factory JsonFeedAuthor.fromMap(Map<String, dynamic> json) {
    return JsonFeedAuthor(
      name: json['name'] as String?,
      url: json['url'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  /// Converts the JsonFeedAuthor to a Map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    if (name != null) json['name'] = name;
    if (url != null) json['url'] = url;
    if (avatar != null) json['avatar'] = avatar;

    return json;
  }

  @override
  String toString() {
    return 'JsonFeedAuthor(name: $name, url: $url, avatar: $avatar)';
  }
}
