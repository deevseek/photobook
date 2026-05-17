class DesignSchemaModel {
  final String version;
  final String unit;
  final double pageWidth;
  final double pageHeight;
  final List<DesignPageModel> pages;

  const DesignSchemaModel({
    required this.version,
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
  final String backgroundColor;
  final List<DesignFrameModel> frames;
  final List<dynamic> texts;

  const DesignPageModel({
    required this.pageNumber,
    required this.backgroundColor,
    required this.frames,
    required this.texts,
  });

  factory DesignPageModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final framesRaw = data['frames'];
    return DesignPageModel(
      pageNumber: int.tryParse('${data['page_number'] ?? 0}') ?? 0,
      backgroundColor: data['background_color']?.toString() ?? '#FFFFFF',
      frames: framesRaw is List
          ? framesRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignFrameModel.fromJson)
              .toList()
          : const [],
      texts: data['texts'] is List ? List<dynamic>.from(data['texts'] as List) : const [],
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
    );
  }
}
