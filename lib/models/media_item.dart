enum MediaType { video, image, unknown }

/// Representa un archivo descargable extraído de un post de Facebook.
class MediaItem {
  final String url;
  final MediaType type;
  final String? quality; // p.ej. "HD", "SD"
  final String? thumbnailUrl;

  const MediaItem({
    required this.url,
    required this.type,
    this.quality,
    this.thumbnailUrl,
  });

  String get suggestedFileName {
    final ext = type == MediaType.video ? 'mp4' : 'jpg';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'fbmedia_$stamp.$ext';
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type.name,
        'quality': quality,
        'thumbnailUrl': thumbnailUrl,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        url: json['url'] as String,
        type: MediaType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MediaType.unknown,
        ),
        quality: json['quality'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}
