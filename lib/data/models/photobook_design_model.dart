import '../../core/utils/url_normalizer.dart';
import 'design_schema_model.dart';

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
  final String? designSchemaSource;
  final String? schemaStatus;
  final String? previewStatus;
  final String? idmlFileUrl;
  final String? description;
  final dynamic designSchema;
  final DesignSchemaModel? parsedDesignSchema;

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
    required this.designSchemaSource,
    required this.schemaStatus,
    required this.previewStatus,
    required this.idmlFileUrl,
    required this.description,
    required this.designSchema,
    required this.parsedDesignSchema,
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
      designSchemaSource: json['design_schema_source']?.toString(),
      schemaStatus: json['schema_status']?.toString(),
      previewStatus: json['preview_status']?.toString(),
      idmlFileUrl: normalizeFileUrl(json['idml_file_url']?.toString()),
      description: json['description']?.toString(),
      designSchema: json['design_schema'],
      parsedDesignSchema: json['design_schema'] is Map<String, dynamic>
          ? DesignSchemaModel.fromJson(json['design_schema'] as Map<String, dynamic>)
          : null,
    );
  }
}
