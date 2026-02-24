class CastMedia {
  final String url;
  final String title;
  final String? subtitle;
  final String? posterUrl;
  final Map<String, String>? customData;
  final bool isLive;

  CastMedia({
    required this.url,
    required this.title,
    this.subtitle,
    this.posterUrl,
    this.customData,
    this.isLive = false,
  });
}
