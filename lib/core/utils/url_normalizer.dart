String? normalizeFileUrl(String? url) {
  if (url == null) return null;

  final cleaned = url.trim();
  if (cleaned.isEmpty) return null;

  return cleaned
      .replaceAll('/storage/storage/', '/storage/')
      .replaceAll('http://profesionalservis.my.id', 'https://profesionalservis.my.id');
}

String? normalizeImageUrl(String? url) => normalizeFileUrl(url);
