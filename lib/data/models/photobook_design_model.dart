import '../../core/utils/url_normalizer.dart';

class PhotobookDesignModel {
  final int id;
  final String title;
  final String category;
  final String theme;
  final String size;
  final int totalPages;
  final String pageSize;
  final String? thumbnailUrl;
  final String contributorName;
  final int designPrice;
  final bool idmlAvailable;
  final bool designSchemaAvailable;
  final dynamic designSchema;
  final String description;

  const PhotobookDesignModel({
    required this.id,
    required this.title,
    required this.category,
    required this.theme,
    required this.size,
    required this.totalPages,
    required this.pageSize,
    required this.thumbnailUrl,
    required this.contributorName,
    required this.designPrice,
    required this.idmlAvailable,
    required this.designSchemaAvailable,
    required this.designSchema,
    required this.description,
  });

  factory PhotobookDesignModel.fromJson(Map<String, dynamic> json) {
    return PhotobookDesignModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? json['name'] ?? '-').toString(),
      category: (json['category'] ?? '-').toString(),
      theme: (json['theme'] ?? '-').toString(),
      size: (json['size'] ?? '-').toString(),
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
      pageSize: (json['page_size'] ?? '-').toString(),
      thumbnailUrl: normalizeImageUrl(json['thumbnail_url']?.toString()),
      contributorName: (json['contributor_name'] ?? '-').toString(),
      designPrice: (json['design_price'] as num?)?.toInt() ?? 0,
      idmlAvailable: json['idml_available'] == true || json['idml_available'] == 1,
      designSchemaAvailable: json['design_schema_available'] == true || json['design_schema_available'] == 1,
      designSchema: json['design_schema'],
      description: (json['description'] ?? '-').toString(),
    );
  }
}
