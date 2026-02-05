class MediaItem {
  const MediaItem({
    required this.uri,
    required this.name,
    required this.sizeBytes,
    required this.raw,
  });

  final String uri;
  final String name;
  final int sizeBytes;
  final Map<String, Object?> raw;
}
