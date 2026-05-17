class PhotobookProductModel {
  final int id;
  final String name;
  final String? description;
  final String? coverType;
  final num price;
  final String? imageUrl;

  const PhotobookProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.coverType,
    this.imageUrl,
  });

  factory PhotobookProductModel.fromJson(Map<String, dynamic> json) {
    return PhotobookProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['title'] ?? '-').toString(),
      description: json['description']?.toString(),
      coverType: (json['cover_type'] ?? json['subtitle'])?.toString(),
      price: num.tryParse('${json['price'] ?? 0}') ?? 0,
      imageUrl: (json['image_url'] ?? json['thumbnail_url'])?.toString(),
    );
  }
}
