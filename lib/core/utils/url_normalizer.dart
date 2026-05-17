String? normalizeImageUrl(String? url) {
  if (url == null) return null;

  final cleaned = url.trim();
  if (cleaned.isEmpty) return null;

  return cleaned.replaceAll('/storage/storage/', '/storage/');
}
