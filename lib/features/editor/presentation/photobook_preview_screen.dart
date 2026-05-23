import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import 'photobook_editor_screen.dart';

class PhotobookPreviewScreen extends StatelessWidget {
  const PhotobookPreviewScreen({
    super.key,
    required this.design,
    required this.schema,
    required this.photoStateByFrameId,
    required this.editedTextById,
    this.onBackToEdit,
    this.onContinueCheckout,
  });

  final PhotobookDesignModel design;
  final DesignSchemaModel schema;
  final Map<String, FramePhotoState> photoStateByFrameId;
  final Map<String, String> editedTextById;
  final VoidCallback? onBackToEdit;
  final VoidCallback? onContinueCheckout;


  Widget _buildPageBackground(DesignPageModel page) {
    final selectedUrl = page.cleanBackgroundUrl?.isNotEmpty == true
        ? page.cleanBackgroundUrl
        : page.editorBackgroundUrl?.isNotEmpty == true
            ? page.editorBackgroundUrl
            : page.backgroundUrl?.isNotEmpty == true
                ? page.backgroundUrl
                : page.previewUrl;

    if (selectedUrl == null || selectedUrl.isEmpty) {
      return Container(color: Colors.white);
    }

    return Image.network(
      selectedUrl,
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => Container(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview - ${design.title}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: schema.pages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final page = schema.pages[index];
                final pageFrames = page.layers.isNotEmpty
                    ? page.layers.where((layer) => layer.type == 'photo' && layer.frame != null).map((layer) => layer.frame!).toList()
                    : page.effectiveFrames;
                final missingFrames = pageFrames
                    .where((frame) => photoStateByFrameId[frame.id] == null)
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Halaman ${page.pageNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        if (missingFrames > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Foto belum diisi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _PreviewPageCanvas(
                      schema: schema,
                      page: page,
                      photoStateByFrameId: photoStateByFrameId,
                      editedTextById: editedTextById,
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBackToEdit ?? () => Navigator.pop(context),
                    child: const Text('Kembali Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinueCheckout,
                    child: const Text('Lanjut Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPageCanvas extends StatelessWidget {
  const _PreviewPageCanvas({
    required this.schema,
    required this.page,
    required this.photoStateByFrameId,
    required this.editedTextById,
  });

  final DesignSchemaModel schema;
  final DesignPageModel page;
  final Map<String, FramePhotoState> photoStateByFrameId;
  final Map<String, String> editedTextById;

  String _layerDisplayText(DesignLayerModel layer) {
    final content = layer.content.trim();
    if (content.isNotEmpty) return content;
    final text = layer.text.trim();
    if (text.isNotEmpty) return text;
    return '';
  }

  Widget _buildPageBackground(DesignPageModel page) {
    String? selectedUrl;
    String selectedSource = 'none';

    if ((page.cleanBackgroundUrl ?? '').isNotEmpty) {
      selectedUrl = page.cleanBackgroundUrl;
      selectedSource = 'clean_background_url';
    } else if ((page.editorBackgroundUrl ?? '').isNotEmpty) {
      selectedUrl = page.editorBackgroundUrl;
      selectedSource = 'editor_background_url';
    } else if ((page.backgroundUrl ?? '').isNotEmpty) {
      selectedUrl = page.backgroundUrl;
      selectedSource = 'background_url';
    } else if ((page.previewUrl ?? '').isNotEmpty) {
      selectedUrl = page.previewUrl;
      selectedSource = 'preview_url';
    } else {
      final dynamic pageDynamic = page;
      if (pageDynamic is Map) {
        final editorBg = pageDynamic['editor_background_url']?.toString();
        final cleanBg = pageDynamic['clean_background_url']?.toString();
        final background = pageDynamic['background_url']?.toString();
        final preview = pageDynamic['preview_url']?.toString();

        if ((editorBg ?? '').isNotEmpty) {
          selectedUrl = editorBg;
          selectedSource = 'editor_background_url';
        } else if ((cleanBg ?? '').isNotEmpty) {
          selectedUrl = cleanBg;
          selectedSource = 'clean_background_url';
        } else if ((background ?? '').isNotEmpty) {
          selectedUrl = background;
          selectedSource = 'background_url';
        } else if ((preview ?? '').isNotEmpty) {
          selectedUrl = preview;
          selectedSource = 'preview_url';
        }
      }
    }

    debugPrint(
      'PAGE BACKGROUND page=${page.pageNumber} using=$selectedSource url=${selectedUrl ?? ''}',
    );

    if ((selectedUrl ?? '').isEmpty) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('Background template tidak tersedia'),
      );
    }

    return Image.network(
      selectedUrl!,
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('Gagal memuat background template'),
      ),
    );
  }

  TextAlign _parseTextAlign(String? value) {
    switch (value?.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  TextStyle _textStyleFromLayer(DesignLayerModel layer, double scaleY) {
    final rawFontSize = layer.fontSize <= 0 ? 24.0 : layer.fontSize;
    final scaledFontSize = rawFontSize * scaleY;
    double? height;

    if (layer.lineHeight > 10 && rawFontSize > 0) {
      height = layer.lineHeight / rawFontSize;
    } else if (layer.lineHeight > 0 && layer.lineHeight <= 5) {
      height = layer.lineHeight;
    }

    return TextStyle(
      fontFamily: layer.fontFamily.trim().isEmpty ? null : layer.fontFamily,
      fontSize: scaledFontSize,
      fontWeight: _parseFontWeight(layer.fontWeight),
      fontStyle: layer.fontStyle.toLowerCase().contains('italic')
          ? FontStyle.italic
          : FontStyle.normal,
      color: _parseHexColor(layer.color),
      height: height,
      letterSpacing: layer.letterSpacing / 1000 * scaledFontSize,
    );
  }

  FontWeight _parseFontWeight(String? value) {
    switch (value?.toLowerCase()) {
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w500;
      case 'semibold':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.w700;
      case 'heavy':
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }

  Color _parseHexColor(String? value) {
    final raw = (value ?? '#000000').replaceAll('#', '').trim();
    try {
      if (raw.length == 6) return Color(int.parse('FF$raw', radix: 16));
      if (raw.length == 8) return Color(int.parse(raw, radix: 16));
    } catch (_) {}
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final schemaWidth = schema.pageWidth.toDouble();
        final schemaHeight = schema.pageHeight.toDouble();

        final scale = math.min(
          constraints.maxWidth / schemaWidth,
          constraints.maxHeight / schemaHeight,
        );

        final displayWidth = schemaWidth * scale;
        final displayHeight = schemaHeight * scale;

        final scaleX = displayWidth / schemaWidth;
        final scaleY = displayHeight / schemaHeight;

        return Center(
          child: SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                Positioned.fill(child: _buildPageBackground(page)),
                ...page.layers.where((layer) => layer.type == 'photo' && layer.frame != null).map((layer) {
                  final frame = layer.frame!;
                  final state = photoStateByFrameId[frame.id];

                  return Positioned(
                    left: frame.x * scaleX,
                    top: frame.y * scaleY,
                    width: frame.width * scaleX,
                    height: frame.height * scaleY,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        frame.borderRadius * scaleX,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (state != null)
                            Transform.translate(
                              offset: Offset(
                                state.offset.dx * scaleX,
                                state.offset.dy * scaleY,
                              ),
                              child: Transform.scale(
                                scale: state.scale,
                                child: Transform.rotate(
                                  angle: state.rotation * math.pi / 180,
                                  child: Image.memory(
                                    state.imageBytes,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          if (state == null)
                            Container(
                              color: Colors.black.withOpacity(0.06),
                              child: Center(
                                child: Icon(Icons.add_a_photo_outlined, color: Colors.black.withOpacity(0.45)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                ...page.layers.where((layer) => layer.type == 'text').map((layer) {
                  final displayText = editedTextById[layer.id] ?? _layerDisplayText(layer);
                  debugPrint(
                    'TEXT VISUAL id=${layer.id} content=$displayText x=${layer.x} y=${layer.y} w=${layer.width} h=${layer.height}',
                  );
                  return Positioned(
                    left: layer.x * scaleX,
                    top: layer.y * scaleY,
                    width: layer.width * scaleX,
                    height: layer.height * scaleY,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: layer.opacity.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: layer.rotation * math.pi / 180,
                          alignment: Alignment.topLeft,
                          child: Text(
                            displayText,
                            textAlign: _parseTextAlign(layer.textAlign),
                            style: _textStyleFromLayer(layer, scaleY),
                            maxLines: null,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
