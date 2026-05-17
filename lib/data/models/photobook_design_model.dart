import '../../core/utils/url_normalizer.dart';

class PhotobookDesignModel {
  final int id;
  final String title;
  final String category;
  final String theme;
  final String size;
  final int totalPages;
  final String? pageSize;
  final String? thumbnailUrl;
  final String contributorName;
  final num designPrice;
  final bool idmlAvailable;
  final bool designSchemaAvailable;
  final String? description;
  final dynamic designSchema;

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
    required this.description,
    required this.designSchema,
  });

  factory PhotobookDesignModel.fromJson(Map<String, dynamic> json) {
    return PhotobookDesignModel(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      theme: json['theme']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      totalPages: int.tryParse('${json['total_pages'] ?? 0}') ?? 0,
      pageSize: json['page_size']?.toString(),
      thumbnailUrl: normalizeFileUrl(json['thumbnail_url']?.toString()),
      contributorName: json['contributor_name']?.toString() ?? '',
      designPrice: num.tryParse('${json['design_price'] ?? 0}') ?? 0,
      idmlAvailable: json['idml_available'] == true || json['idml_available'] == 1,
      designSchemaAvailable: json['design_schema_available'] == true || json['design_schema_available'] == 1,
      description: json['description']?.toString(),
      designSchema: json['design_schema'],
    );
  }
}
