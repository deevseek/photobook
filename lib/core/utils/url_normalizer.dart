String? normalizeFileUrl(String? url) {
  if (url == null || url.trim().isEmpty) return null;

  var value = url.trim();

  value = value.replaceAll('/storage/storage/', '/storage/');

  if (value.startsWith('http://profesionalservis.my.id')) {
    value = value.replaceFirst('http://', 'https://');
  }

  if (value.startsWith('/storage/')) {
    value = 'https://profesionalservis.my.id$value';
  }

  if (value.startsWith('storage/')) {
    value = 'https://profesionalservis.my.id/$value';
  }

  return value;
}

String? normalizeImageUrl(String? url) => normalizeFileUrl(url);
