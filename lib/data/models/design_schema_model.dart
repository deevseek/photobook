import 'package:flutter/material.dart';

import '../../core/utils/url_normalizer.dart';

class DesignSchemaModel {
  final String? version;
  final String? source;
  final String? parser;
  final double pageWidth;
  final double pageHeight;
  final List<DesignPageModel> pages;

  const DesignSchemaModel({
    required this.version,
    required this.source,
    required this.parser,
    required this.pageWidth,
    required this.pageHeight,
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
      pageHeight: _toDouble(data['page_height'], fallback: 3000),
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

  const DesignPageModel({
    required this.pageNumber,
    required this.backgroundUrl,
    required this.previewUrl,
    required this.editorBackgroundUrl,
    required this.cleanBackgroundUrl,
    required this.backgroundMissing,
    required this.frames,
    required this.texts,
  });

  factory DesignPageModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};
    final framesRaw = data['frames'];
    final textsRaw = data['texts'];

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

  const TextStyleSchema({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
    required this.textAlign,
    required this.color,
    required this.lineHeight,
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
    );
  }

  Color? get colorValue => parseColor(color);

  TextStyle toTextStyle() {
    return TextStyle(
      fontFamily: (fontFamily == null || fontFamily!.isEmpty) ? null : fontFamily,
      fontSize: fontSize,
      fontWeight: _parseFontWeight(fontWeight),
      fontStyle: (fontStyle?.toLowerCase() == 'italic') ? FontStyle.italic : FontStyle.normal,
      color: colorValue,
      height: lineHeight,
    );
  }

  static FontWeight? _parseFontWeight(String? value) {
    switch (value?.toLowerCase()) {
      case 'bold':
      case '700':
        return FontWeight.w700;
      case '600':
        return FontWeight.w600;
      case '500':
        return FontWeight.w500;
      case '300':
        return FontWeight.w300;
      default:
        return null;
    }
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
