class PhotobookProductModel {
  final int id;
  final String name;
  final String category;
  final String size;
  final num basePrice;
  final int defaultPages;
  final num additionalPagePrice;
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
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      basePrice: num.tryParse('${json['base_price'] ?? 0}') ?? 0,
      defaultPages: int.tryParse('${json['default_pages'] ?? 0}') ?? 0,
      additionalPagePrice: num.tryParse('${json['additional_page_price'] ?? 0}') ?? 0,
      coverType: json['cover_type']?.toString() ?? '',
      paperType: json['paper_type']?.toString() ?? '',
      productionEstimateDays: int.tryParse('${json['production_estimate_days'] ?? 0}') ?? 0,
      imageUrl: json['image_url']?.toString(),
      activeDesignsCount: int.tryParse('${json['active_designs_count'] ?? 0}') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      description: json['description']?.toString() ?? '',
    );
  }
}
