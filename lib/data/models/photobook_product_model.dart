class PhotobookProductModel {
  final int id;
  final String name;
  final String category;
  final String size;
  final int basePrice;
  final int defaultPages;
  final int additionalPagePrice;
  final String coverType;
  final String paperType;
  final int productionEstimateDays;
  final String? imageUrl;
  final int activeDesignsCount;
  final bool isActive;
  final String description;

  const PhotobookProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.basePrice,
    required this.defaultPages,
    required this.additionalPagePrice,
    required this.coverType,
    required this.paperType,
    required this.productionEstimateDays,
    required this.imageUrl,
    required this.activeDesignsCount,
    required this.isActive,
    required this.description,
  });

  factory PhotobookProductModel.fromJson(Map<String, dynamic> json) {
    return PhotobookProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '-').toString(),
      category: (json['category'] ?? '-').toString(),
      size: (json['size'] ?? '-').toString(),
      basePrice: (json['base_price'] as num?)?.toInt() ?? 0,
      defaultPages: (json['default_pages'] as num?)?.toInt() ?? 0,
      additionalPagePrice: (json['additional_page_price'] as num?)?.toInt() ?? 0,
      coverType: (json['cover_type'] ?? '-').toString(),
      paperType: (json['paper_type'] ?? '-').toString(),
      productionEstimateDays: (json['production_estimate_days'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url']?.toString(),
      activeDesignsCount: (json['active_designs_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      description: (json['description'] ?? '-').toString(),
    );
  }
}
