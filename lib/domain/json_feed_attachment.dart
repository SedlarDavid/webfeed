/// Represents an attachment in a JSON Feed item
class JsonFeedAttachment {
  /// The URL of the attachment
  final String url;

  /// The MIME type of the attachment
  final String mimeType;

  /// The title of the attachment
  final String? title;

  /// The size of the attachment in bytes
  final int? sizeInBytes;

  /// The duration of the attachment in seconds
  final int? durationInSeconds;

  JsonFeedAttachment({
    required this.url,
    required this.mimeType,
    this.title,
    this.sizeInBytes,
    this.durationInSeconds,
  });

  /// Creates a JsonFeedAttachment from a Map
  factory JsonFeedAttachment.fromMap(Map<String, dynamic> json) {
    return JsonFeedAttachment(
      url: json['url'] as String,
      mimeType: json['mime_type'] as String,
      title: json['title'] as String?,
      sizeInBytes: json['size_in_bytes'] as int?,
      durationInSeconds: json['duration_in_seconds'] as int?,
    );
  }

  /// Converts the JsonFeedAttachment to a Map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'url': url,
      'mime_type': mimeType,
    };

    if (title != null) json['title'] = title;
    if (sizeInBytes != null) json['size_in_bytes'] = sizeInBytes;
    if (durationInSeconds != null) json['duration_in_seconds'] = durationInSeconds;

    return json;
  }

  @override
  String toString() {
    return 'JsonFeedAttachment(url: $url, mimeType: $mimeType, title: $title)';
  }
}
