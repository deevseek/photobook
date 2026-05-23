import 'package:flutter/material.dart';

import '../../core/utils/url_normalizer.dart';

class DesignSchemaModel {
  final String? version;
  final String? source;
  final String? parser;
  final double pageWidth;
  final double pageHeight;
  final String? pageOrientation;
  final double? pageAspectRatio;
  final List<DesignPageModel> pages;

  const DesignSchemaModel({
    required this.version,
    required this.source,
    required this.parser,
    required this.pageWidth,
    required this.pageHeight,
    required this.pageOrientation,
    required this.pageAspectRatio,
    required this.pages,
  });

  factory DesignSchemaModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final pagesRaw = data['pages'];

    return DesignSchemaModel(
      version: data['version']?.toString(),
      source: data['source']?.toString(),
      parser: data['parser']?.toString(),
      pageWidth: _toDouble(data['page_width'], fallback: 2000),
      pageHeight: _toDouble(data['page_height'], fallback: 2000),
      pageOrientation: data['page_orientation']?.toString(),
      pageAspectRatio: _toDoubleNullable(data['page_aspect_ratio']),
      pages: pagesRaw is List
          ? pagesRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignPageModel.fromJson)
              .toList()
          : const [],
    );
  }

  static double _toDouble(dynamic value, {double fallback = 0}) =>
      double.tryParse('${value ?? fallback}') ?? fallback;

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    return double.tryParse('$value');
  }
}

class DesignPageModel {
  final int pageNumber;
  final String? backgroundUrl;
  final String? previewUrl;
  final String? editorBackgroundUrl;
  final String? cleanBackgroundUrl;
  final bool backgroundMissing;
  final List<DesignFrameModel> frames;
  final List<DesignTextModel> texts;
  final List<DesignLayerModel> layers;

  const DesignPageModel({
    required this.pageNumber,
    required this.backgroundUrl,
    required this.previewUrl,
    required this.editorBackgroundUrl,
    required this.cleanBackgroundUrl,
    required this.backgroundMissing,
    required this.frames,
    required this.texts,
    this.layers = const [],
  });

  factory DesignPageModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final framesRaw = data['frames'];
    final textsRaw = data['texts'];
    final layersRaw = data['layers'];

    return DesignPageModel(
      pageNumber: int.tryParse('${data['page_number'] ?? 0}') ?? 0,
      backgroundUrl: normalizeFileUrl(data['background_url']?.toString()),
      previewUrl: normalizeFileUrl(data['preview_url']?.toString()),
      editorBackgroundUrl: normalizeFileUrl(data['editor_background_url']?.toString()),
      cleanBackgroundUrl: normalizeFileUrl(data['clean_background_url']?.toString()),
      backgroundMissing:
          data['background_missing'] == true || data['background_missing'] == 1,
      frames: framesRaw is List
          ? framesRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignFrameModel.fromJson)
              .toList()
          : const [],
      texts: textsRaw is List
          ? textsRaw
              .whereType<Map<String, dynamic>>()
              .map(DesignTextModel.fromJson)
              .toList()
          : const [],
      layers: layersRaw is List
          ? layersRaw
              .whereType<Map>()
              .map((e) => DesignLayerModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  List<DesignFrameModel> get effectiveFrames =>
      layers.isNotEmpty ? layers.where((l) => l.frame != null).map((l) => l.frame!).toList() : frames;

  List<DesignTextModel> get effectiveTexts => texts;
}



class DesignLayerModel {
  final String id;
  final String type;
  final String content;
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final String fontFamily;
  final double fontSize;
  final String fontWeight;
  final String fontStyle;
  final String color;
  final String textAlign;
  final double lineHeight;
  final double letterSpacing;
  final String? sourceStory;
  final String? sourceObjectId;
  final DesignFrameModel? frame;

  const DesignLayerModel({
    required this.id,
    required this.type,
    this.content = '',
    this.text = '',
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
    this.opacity = 1,
    this.fontFamily = '',
    this.fontSize = 14,
    this.fontWeight = 'normal',
    this.fontStyle = 'normal',
    this.color = '#000000',
    this.textAlign = 'left',
    this.lineHeight = 1.2,
    this.letterSpacing = 0,
    this.sourceStory,
    this.sourceObjectId,
    required this.frame,
  });

  factory DesignLayerModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final type = data['type']?.toString().toLowerCase() ?? '';

    double toDouble(dynamic value, [double fallback = 0]) =>
        double.tryParse('${value ?? fallback}') ?? fallback;

    return DesignLayerModel(
      id: (data['id'] ?? '').toString(),
      type: type,
      content: (data['content'] ?? data['text'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      x: toDouble(data['x']),
      y: toDouble(data['y']),
      width: toDouble(data['width']),
      height: toDouble(data['height']),
      rotation: toDouble(data['rotation']),
      opacity: toDouble(data['opacity'], 1),
      fontFamily: (data['fontFamily'] ?? data['font_family'] ?? '').toString(),
      fontSize: toDouble(data['fontSize'] ?? data['font_size'], 14),
      fontWeight: (data['fontWeight'] ?? data['font_weight'] ?? 'normal').toString(),
      fontStyle: (data['fontStyle'] ?? data['font_style'] ?? 'normal').toString(),
      color: (data['color'] ?? '#000000').toString(),
      textAlign: (data['textAlign'] ?? data['text_align'] ?? 'left').toString(),
      lineHeight: toDouble(data['lineHeight'] ?? data['line_height'], 1.2),
      letterSpacing: toDouble(data['letterSpacing'] ?? data['letter_spacing'], 0),
      sourceStory: data['source_story']?.toString(),
      sourceObjectId: data['source_object_id']?.toString(),
      frame: type == 'photo' ? DesignFrameModel.fromJson(data) : null,
    );
  }
}

class DesignFrameModel {
  final String id;
  final String type;
  final int pageNumber;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double borderRadius;
  final String placeholder;
  final String? sourceObject;
  final List<Offset>? polygonPoints;

  const DesignFrameModel({
    required this.id,
    required this.type,
    required this.pageNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.borderRadius,
    required this.placeholder,
    required this.sourceObject,
    required this.polygonPoints,
  });

  factory DesignFrameModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};

    return DesignFrameModel(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? 'photo',
      pageNumber: int.tryParse('${data['page_number'] ?? 0}') ?? 0,
      x: DesignSchemaModel._toDouble(data['x']),
      y: DesignSchemaModel._toDouble(data['y']),
      width: DesignSchemaModel._toDouble(data['width']),
      height: DesignSchemaModel._toDouble(data['height']),
      rotation: DesignSchemaModel._toDouble(data['rotation']),
      borderRadius: DesignSchemaModel._toDouble(data['border_radius']),
      placeholder: data['placeholder']?.toString() ?? 'Tambah Foto',
      sourceObject: data['source_object']?.toString(),
      polygonPoints: _parsePolygonPoints(data['polygon_points']),
    );
  }

  static List<Offset>? _parsePolygonPoints(dynamic raw) {
    if (raw is! List) {
      return null;
    }

    final points = raw
        .whereType<Map<String, dynamic>>()
        .map(
          (point) => Offset(
            DesignSchemaModel._toDouble(point['x']),
            DesignSchemaModel._toDouble(point['y']),
          ),
        )
        .toList();

    return points.isEmpty ? null : points;
  }
}

class DesignTextModel {
  final String id;
  final String type;
  final int pageNumber;
  final String? sourceStory;
  final String? sourceObjectId;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final String text;
  final bool editable;
  final String? placeholder;
  final TextStyleSchema style;

  const DesignTextModel({
    required this.id,
    required this.type,
    required this.pageNumber,
    required this.sourceStory,
    required this.sourceObjectId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.opacity,
    required this.text,
    required this.editable,
    required this.placeholder,
    required this.style,
  });

  factory DesignTextModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};

    return DesignTextModel(
      id: data['id']?.toString() ?? '',
      type: data['type']?.toString() ?? 'text',
      pageNumber: int.tryParse('${data['page_number'] ?? 0}') ?? 0,
      sourceStory: data['source_story']?.toString(),
      sourceObjectId: data['source_object_id']?.toString(),
      x: DesignSchemaModel._toDouble(data['x']),
      y: DesignSchemaModel._toDouble(data['y']),
      width: DesignSchemaModel._toDouble(data['width']),
      height: DesignSchemaModel._toDouble(data['height']),
      rotation: DesignSchemaModel._toDouble(data['rotation']),
      opacity: DesignSchemaModel._toDouble(data['opacity'], fallback: 1),
      text: data['text']?.toString() ?? '',
      editable: data['editable'] == true || data['editable'] == 1,
      placeholder: data['placeholder']?.toString(),
      style: TextStyleSchema.fromJson(data['style'] as Map<String, dynamic>?),
    );
  }
}

class TextStyleSchema {
  final String? fontFamily;
  final double? fontSize;
  final String? fontWeight;
  final String? fontStyle;
  final String? textAlign;
  final String? color;
  final double? lineHeight;
  final double? letterSpacing;

  const TextStyleSchema({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
    required this.textAlign,
    required this.color,
    required this.lineHeight,
    required this.letterSpacing,
  });

  factory TextStyleSchema.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};

    return TextStyleSchema(
      fontFamily: data['font_family']?.toString(),
      fontSize: double.tryParse('${data['font_size']}'),
      fontWeight: data['font_weight']?.toString(),
      fontStyle: data['font_style']?.toString(),
      textAlign: data['text_align']?.toString(),
      color: data['color']?.toString(),
      lineHeight: double.tryParse('${data['line_height']}'),
      letterSpacing: double.tryParse('${data['letter_spacing']}'),
    );
  }

  Color? get colorValue => parseColor(color);

  TextStyle toTextStyle({double? scaledFontSize}) {
    final resolvedFontSize = scaledFontSize ?? fontSize;
    return TextStyle(
      fontFamily: (fontFamily == null || fontFamily!.isEmpty) ? null : fontFamily,
      fontSize: resolvedFontSize,
      fontWeight: _parseFontWeight(fontWeight),
      fontStyle: (fontStyle?.toLowerCase() == 'italic') ? FontStyle.italic : FontStyle.normal,
      color: colorValue,
      height: _resolveLineHeightRatio(lineHeight, resolvedFontSize),
      letterSpacing: _resolveLetterSpacing(letterSpacing, resolvedFontSize),
    );
  }


  static double? _resolveLineHeightRatio(double? value, double? fontSize) {
    if (value == null || value <= 0) return null;
    if (value > 10 && fontSize != null && fontSize > 0) {
      return value / fontSize;
    }
    return value;
  }

  static double? _resolveLetterSpacing(double? value, double? fontSize) {
    if (value == null) return null;
    if (fontSize == null || fontSize <= 0) return value;
    return (value / 1000.0) * fontSize;
  }

  static FontWeight? _parseFontWeight(String? value) {
    final normalized = value?.toLowerCase().trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.contains('black') || normalized.contains('heavy') || normalized == '900' || normalized == '800') {
      return FontWeight.w800;
    }
    if (normalized.contains('bold') || normalized == '700') {
      return FontWeight.w700;
    }
    if (normalized.contains('semibold') || normalized.contains('semi-bold') || normalized.contains('demi') || normalized == '600') {
      return FontWeight.w600;
    }
    if (normalized.contains('medium') || normalized == '500') {
      return FontWeight.w500;
    }
    if (normalized == '400' || normalized == 'normal' || normalized == 'regular') {
      return FontWeight.w400;
    }
    if (normalized == '300' || normalized.contains('light')) {
      return FontWeight.w300;
    }
    return null;
  }

  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) {
      return null;
    }

    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      return parsed == null ? null : Color(parsed);
    }
    if (cleaned.length == 8) {
      final parsed = int.tryParse(cleaned, radix: 16);
      return parsed == null ? null : Color(parsed);
    }
    return null;
  }
}
