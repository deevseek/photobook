import '../../../core/utils/url_normalizer.dart';

class PhotobookDesignModel {
  final int id;
  final int? productId;
  final String name;
  final String? description;
  final String thumbnailUrl;

  const PhotobookDesignModel({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.productId,
    this.description,
  });

  factory PhotobookDesignModel.fromJson(Map<String, dynamic> json) {
    return PhotobookDesignModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt(),
      name: (json['name'] ?? json['title'] ?? '-').toString(),
      description: json['description']?.toString(),
      thumbnailUrl: normalizeFileUrl((json['thumbnail_url'] ?? '').toString()) ?? '',
    );
  }
}
