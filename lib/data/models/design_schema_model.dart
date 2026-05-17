import '../../core/utils/url_normalizer.dart';

class DesignSchemaModel {
  final String version;
  final String source;
  final String unit;
  final double pageWidth;
  final double pageHeight;
  final List<DesignPageModel> pages;

  const DesignSchemaModel({
    required this.version,
    required this.source,
    required this.unit,
    required this.pageWidth,
    required this.pageHeight,
    required this.pages,
  });

  factory DesignSchemaModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final pagesRaw = data['pages'];
    return DesignSchemaModel(
      version: data['version']?.toString() ?? '1.0',
      source: data['source']?.toString() ?? 'default',
      unit: data['unit']?.toString() ?? 'px',
      pageWidth: _toDouble(data['page_width']),
      pageHeight: _toDouble(data['page_height']),
      pages: pagesRaw is List
          ? pagesRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignPageModel.fromJson)
              .toList()
          : const [],
    );
  }

  static double _toDouble(dynamic value) =>
      double.tryParse('${value ?? 0}') ?? 0;
}

class DesignPageModel {
  final int pageNumber;
  final String? backgroundColor;
  final String? backgroundUrl;
  final String? previewUrl;
  final bool backgroundMissing;
  final List<DesignAssetModel> assets;
  final List<DesignFrameModel> frames;
  final List<dynamic> texts;

  const DesignPageModel({
    required this.pageNumber,
    required this.backgroundColor,
    required this.backgroundUrl,
    required this.previewUrl,
    required this.backgroundMissing,
    required this.assets,
    required this.frames,
    required this.texts,
  });

  factory DesignPageModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final framesRaw = data['frames'];
    final assetsRaw = data['assets'];
    return DesignPageModel(
      pageNumber: int.tryParse('${data['page_number'] ?? 0}') ?? 0,
      backgroundColor: data['background_color']?.toString(),
      backgroundUrl: normalizeFileUrl(data['background_url']?.toString()),
      previewUrl: normalizeFileUrl(data['preview_url']?.toString()),
      backgroundMissing:
          data['background_missing'] == true || data['background_missing'] == 1,
      assets: assetsRaw is List
          ? assetsRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignAssetModel.fromJson)
              .toList()
          : const [],
      frames: framesRaw is List
          ? framesRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignFrameModel.fromJson)
              .toList()
          : const [],
      texts:
          data['texts'] is List ? List<dynamic>.from(data['texts'] as List) : const [],
    );
  }
}

class DesignFrameModel {
  final String id;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double borderRadius;
  final String placeholder;
  final String? sourceObject;
  final Map<String, dynamic> meta;

  const DesignFrameModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.borderRadius,
    required this.placeholder,
    required this.sourceObject,
    required this.meta,
  });

  factory DesignFrameModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    return DesignFrameModel(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? 'photo',
      x: DesignSchemaModel._toDouble(data['x']),
      y: DesignSchemaModel._toDouble(data['y']),
      width: DesignSchemaModel._toDouble(data['width']),
      height: DesignSchemaModel._toDouble(data['height']),
      rotation: DesignSchemaModel._toDouble(data['rotation']),
      borderRadius: DesignSchemaModel._toDouble(data['border_radius']),
      placeholder: data['placeholder']?.toString() ?? 'Tambah Foto',
      sourceObject: data['source_object']?.toString(),
      meta: data['meta'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['meta'] as Map<String, dynamic>)
          : const {},
    );
  }
}

class DesignAssetModel {
  final String id;
  final String type;
  final String? url;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;

  const DesignAssetModel({
    required this.id,
    required this.type,
    required this.url,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
  });

  factory DesignAssetModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    return DesignAssetModel(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? 'image',
      url: normalizeFileUrl(data['url']?.toString()),
      x: DesignSchemaModel._toDouble(data['x']),
      y: DesignSchemaModel._toDouble(data['y']),
      width: DesignSchemaModel._toDouble(data['width']),
      height: DesignSchemaModel._toDouble(data['height']),
      rotation: DesignSchemaModel._toDouble(data['rotation']),
      opacity: DesignSchemaModel._toDouble(data['opacity'] ?? 1),
    );
  }
}
