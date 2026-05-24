import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';
import '../../checkout/presentation/photobook_checkout_screen.dart';
import 'photobook_preview_screen.dart';

class FramePhotoState {
  final String frameId;
  final Uint8List imageBytes;
  final String? fileName;
  final double scale;
  final Offset offset;
  final double rotation;

  const FramePhotoState({
    required this.frameId,
    required this.imageBytes,
    this.fileName,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.rotation = 0,
  });

  FramePhotoState copyWith({
    Uint8List? imageBytes,
    String? fileName,
    double? scale,
    Offset? offset,
    double? rotation,
  }) {
    return FramePhotoState(
      frameId: frameId,
      imageBytes: imageBytes ?? this.imageBytes,
      fileName: fileName ?? this.fileName,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
    );
  }
}

class PhotobookEditorScreen extends StatefulWidget {
  final int productId;
  final PhotobookDesignModel design;

  const PhotobookEditorScreen({
    super.key,
    required this.productId,
    required this.design,
  });

  @override
  State<PhotobookEditorScreen> createState() => _PhotobookEditorScreenState();
}

class _PhotobookEditorScreenState extends State<PhotobookEditorScreen> {
  static const bool _debugTextBounds = kDebugMode;
  final _repo = PhotobookRepository();

  int _activePageIndex = 0;
  String? _selectedFrameId;
  String? _selectedTextLayerId;
  final Map<String, FramePhotoState> _photoStateByFrameId = {};
  final Map<String, String> _editedTextById = {};
  final Map<String, String> _savedTextById = {};
  String _inlineDraftText = '';

  bool _loading = true;
  String? _error;
  DesignSchemaModel? _schema;

  String _layerDisplayText(DesignLayerModel layer) {
    final content = layer.content.trim();
    if (content.isNotEmpty) return content;
    final text = layer.text.trim();
    if (text.isNotEmpty) return text;
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadSchema();
  }

  Future<void> _loadSchema() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final detail = widget.design.designSchema != null
          ? widget.design
          : await _repo.getDesignDetail(widget.design.id);
      final schema = detail.designSchema ?? detail.parsedDesignSchema;

      if ((detail.schemaStatus ?? '').toLowerCase() != 'ready') {
        setState(() {
          _error = 'Template sedang diproses.';
        });
        return;
      }

      if (schema == null || schema.pages.isEmpty) {
        setState(() {
          _error = 'Template belum siap. Silakan coba lagi nanti.';
        });
        return;
      }

      final savedTexts = <String, String>{
        for (final page in schema.pages)
          for (final layer in page.layers)
            if (layer.type == 'text') layer.id: _layerDisplayText(layer),
      };

      setState(() {
        _schema = schema;
        _savedTextById
          ..clear()
          ..addAll(savedTexts);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor PhotoBook')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.design.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final schema = _schema;

    if (schema == null || schema.pages.isEmpty) {
      return const Center(
        child: Text('Template tidak memiliki halaman'),
      );
    }

    return Column(
      children: [
        if ((widget.design.previewStatus ?? '').toLowerCase() == 'failed')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Background preview belum tersedia. Frame dan teks tetap bisa diedit.',
            ),
          ),
        Expanded(
          child: _buildCanvas(context, schema),
        ),
        _buildInlineTextEditor(schema),
        const SizedBox(height: 8),
        _buildPageThumbnails(schema),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: _buildBottomActions(),
        ),
      ],
    );
  }

  void _logPageLayerStats({
    required DesignPageModel page,
    required int pageIndex,
    required double pageWidth,
    required double pageHeight,
    required int totalLayers,
    required int textLayers,
    required int photoLayers,
    required int shapeLayers,
    required int lineLayers,
    required int renderedText,
    required int renderedPhoto,
    required int skipped,
  }) {
    debugPrint(
      'PAGE RENDER pageIndex=$pageIndex page=${page.pageNumber} page_width=$pageWidth page_height=$pageHeight '
      'total_layers=$totalLayers text_layers=$textLayers photo_layers=$photoLayers shape_layers=$shapeLayers line_layers=$lineLayers '
      'rendered_text=$renderedText rendered_photo=$renderedPhoto skipped=$skipped',
    );
  }

  Widget _buildCanvas(BuildContext context, DesignSchemaModel schema) {
    final page = schema.pages[_activePageIndex];
    final layers = page.layers;
    final indexedLayers = layers.indexed.toList()
      ..sort((a, b) {
        final az = a.$2.zIndex ?? a.$1;
        final bz = b.$2.zIndex ?? b.$1;
        return az.compareTo(bz);
      });
    final sortedLayers = indexedLayers.map((e) => e.$2).toList();
    final photoLayers = sortedLayers.where((layer) => layer.type == 'photo' || layer.type == 'image' || layer.type == 'frame').toList();
    final textLayers = sortedLayers.where((layer) => layer.type == 'text').toList();
    final shapeLayers = sortedLayers.where((layer) => layer.type == 'shape').toList();
    final lineLayers = sortedLayers.where((layer) => layer.type == 'line').toList();

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
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  debugPrint('CANVAS POINTER DOWN local=${event.localPosition}');
                },
                child: Builder(
                  builder: (context) {
                    var renderedTextCount = 0;
                    var renderedPhotoCount = 0;
                    var skippedCount = 0;

                    final layerWidgets = <Widget>[];
                    for (final layer in sortedLayers) {
                      Widget? widget;
                      if (layer.type == 'text') {
                        widget = _buildTextLayer(layer: layer, scaleX: scaleX, scaleY: scaleY);
                        if (widget != null) renderedTextCount++;
                      } else if (layer.type == 'photo' || layer.type == 'image' || layer.type == 'frame') {
                        widget = _buildPhotoLayer(context: context, layer: layer, scaleX: scaleX, scaleY: scaleY);
                        if (widget != null) renderedPhotoCount++;
                      } else if (layer.type == 'shape') {
                        widget = _buildShapeLayer(layer: layer, scaleX: scaleX, scaleY: scaleY);
                      } else if (layer.type == 'line') {
                        widget = _buildLineLayer(layer: layer, scaleX: scaleX, scaleY: scaleY);
                      }
                      if (widget == null) {
                        skippedCount++;
                        continue;
                      }
                      layerWidgets.add(widget);
                    }

                    _logPageLayerStats(
                      page: page,
                      pageIndex: _activePageIndex,
                      pageWidth: schemaWidth,
                      pageHeight: schemaHeight,
                      totalLayers: layers.length,
                      textLayers: textLayers.length,
                      photoLayers: photoLayers.length,
                      shapeLayers: shapeLayers.length,
                      lineLayers: lineLayers.length,
                      renderedText: renderedTextCount,
                      renderedPhoto: renderedPhotoCount,
                      skipped: skippedCount,
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: _buildPageBackground(page)),
                        ...layerWidgets,
                        if (_selectedFrameId != null || _selectedTextLayerId != null)
                          IgnorePointer(
                            child: _buildSelectionOverlay(page: page, scaleX: scaleX, scaleY: scaleY),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildPhotoLayer({
    required BuildContext context,
    required DesignLayerModel layer,
    required double scaleX,
    required double scaleY,
  }) {
    if (layer.frame != null) {
      return _buildFrame(
        context: context,
        frame: layer.frame!,
        scaleX: scaleX,
        scaleY: scaleY,
        layerId: layer.id,
      );
    }

    final left = layer.x * scaleX;
    final top = layer.y * scaleY;
    final width = layer.width * scaleX;
    final height = layer.height * scaleY;

    if (width <= 0 || height <= 0) {
      debugPrint(
        'LAYER SKIPPED id=${layer.id} type=${layer.type} x=${layer.x} y=${layer.y} w=${layer.width} h=${layer.height} reason=invalid_photo_geometry',
      );
      return null;
    }

    final state = _photoStateByFrameId[layer.id];
    final fallbackImageSource = _resolveLayerImageSource(layer);
    final hasPhoto = state != null || fallbackImageSource != null;
    final isActive = _selectedFrameId == layer.id;
    _debugPhotoVisual(
      layer: layer,
      selectedUserImageUrl: state != null ? 'memory-bytes' : null,
      finalSource: state != null ? 'memory-bytes' : fallbackImageSource,
    );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          debugPrint('PHOTO LAYER TAP id=${layer.id} source=layer_geometry_fallback');
          setState(() {
            _selectedFrameId = layer.id;
            _selectedTextLayerId = null;
          });
        },
        child: Opacity(
          opacity: layer.opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: layer.rotation * math.pi / 180,
            alignment: Alignment.topLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? Colors.blue : Colors.white70,
                  width: isActive ? 2 : 1,
                ),
                color: hasPhoto ? null : Colors.black.withOpacity(0.03),
              ),
              child: hasPhoto
                  ? (state != null
                      ? _buildCroppedPhoto(state)
                      : _buildTemplateImage(fallbackImageSource!))
                  : Center(
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 18,
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }


  DesignLayerModel? _findLayerById(String layerId) {
    final schema = _schema;
    if (schema == null) return null;
    for (final page in schema.pages) {
      for (final layer in page.layers) {
        if (layer.id == layerId) return layer;
      }
    }
    return null;
  }

  String? _resolveLayerImageSourceById(String layerId) {
    final layer = _findLayerById(layerId);
    return layer == null ? null : _resolveLayerImageSource(layer);
  }

  String? _resolveLayerImageSource(DesignLayerModel layer) {
    final imageSource =
        layer.imageUrl ??
        layer.originalImageUrl ??
        layer.assetUrl ??
        layer.mediaUrl ??
        layer.previewUrl;
    if (imageSource == null || imageSource.trim().isEmpty) {
      return null;
    }
    return imageSource;
  }

  void _debugPhotoVisual({
    required DesignLayerModel layer,
    required String? selectedUserImageUrl,
    required String? finalSource,
  }) {
    debugPrint(
      'PHOTO VISUAL id=${layer.id} imageUrl=${layer.imageUrl ?? ''} originalImageUrl=${layer.originalImageUrl ?? ''} assetUrl=${layer.assetUrl ?? ''} mediaUrl=${layer.mediaUrl ?? ''} previewUrl=${layer.previewUrl ?? ''} selected=${selectedUserImageUrl ?? ''} finalSource=${finalSource ?? ''}',
    );
  }

  Widget _buildTemplateImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black.withOpacity(0.06),
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            size: 18,
            color: Colors.black.withOpacity(0.25),
          ),
        ),
      ),
    );
  }

  Widget _buildPageBackground(DesignPageModel page) {
    final candidates = <String?, String>{
      page.cleanBackgroundUrl: 'clean_background_url',
      page.editorBackgroundUrl: 'editor_background_url',
      page.backgroundUrl: 'background_url',
    };

    String? selectedUrl;
    String selectedSource = 'none';
    for (final entry in candidates.entries) {
      final url = entry.key;
      if (url != null && url.isNotEmpty) {
        selectedUrl = url;
        selectedSource = entry.value;
        break;
      }
    }

    debugPrint('PAGE BACKGROUND page=${page.pageNumber} using=$selectedSource url=${selectedUrl ?? ''}');

    if (selectedUrl == null || selectedUrl.isEmpty) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('Background template tidak tersedia'),
      );
    }

    return Image.network(
      selectedUrl,
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('Gagal memuat background template'),
      ),
    );
  }
  Widget? _buildTextLayer({
    required DesignLayerModel layer,
    required double scaleX,
    required double scaleY,
  }) {
    final displayText = _editedTextById[layer.id] ?? _layerDisplayText(layer);
    final left = (layer.x * scaleX).toDouble();
    final top = (layer.y * scaleY).toDouble();
    final width = (layer.width * scaleX).toDouble();
    final height = (layer.height * scaleY).toDouble();

    final textStyle = _textStyleFromLayer(layer, scaleY);

    debugPrint(
      'TEXT VISUAL id=${layer.id} content=$displayText x=${layer.x} y=${layer.y} w=${layer.width} h=${layer.height}',
    );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final oldContent = displayText;
          debugPrint('TEXT CLICK id=${layer.id} content=$oldContent');
          _openTextEditor(layer);
        },
        child: Opacity(
          opacity: layer.opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: layer.rotation * math.pi / 180,
            alignment: Alignment.topLeft,
            child: Text(
              displayText,
              style: textStyle,
              textAlign: _parseFlutterTextAlign(layer.textAlign),
              maxLines: null,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }
  Widget? _buildShapeLayer({
    required DesignLayerModel layer,
    required double scaleX,
    required double scaleY,
  }) {
    if (layer.width <= 0 || layer.height <= 0) return null;
    final resolvedColor = _parseHexColor(
          layer.fillColor ??
              layer.backgroundColor ??
              layer.color ??
              layer.meta['fill_color'] ??
              layer.meta['source_fill_color'],
        ) ??
        Colors.transparent;
    final resolvedOpacity = layer.opacity.clamp(0.0, 1.0);

    print(
      'SHAPE RENDER id=${layer.id} fill_color=${layer.fillColor} backgroundColor=${layer.backgroundColor} '
      'color=${layer.color} resolvedColor=$resolvedColor opacity=$resolvedOpacity',
    );

    return Positioned(
      left: layer.x * scaleX,
      top: layer.y * scaleY,
      width: layer.width * scaleX,
      height: layer.height * scaleY,
      child: Opacity(opacity: resolvedOpacity, child: ColoredBox(color: resolvedColor)),
    );
  }

  Widget? _buildLineLayer({
    required DesignLayerModel layer,
    required double scaleX,
    required double scaleY,
  }) {
    if (layer.width <= 0 || layer.height <= 0) return null;
    final isHorizontal = layer.width >= layer.height;
    final thickness = (isHorizontal ? layer.height : layer.width) * (isHorizontal ? scaleY : scaleX);
    final color = _parseHexColor(
          layer.strokeColor ?? layer.color ?? layer.meta['stroke_color'],
        ) ??
        const Color(0xFF000000);
    final effectiveThickness = thickness.clamp(1.0, 9999.0);
    return Positioned(
      left: layer.x * scaleX,
      top: layer.y * scaleY,
      width: layer.width * scaleX,
      height: layer.height * scaleY,
      child: Transform.rotate(
        angle: layer.rotation * math.pi / 180,
        alignment: Alignment.center,
        child: Align(
          alignment: Alignment.center,
          child: Container(
            width: isHorizontal ? double.infinity : effectiveThickness,
            height: isHorizontal ? effectiveThickness : double.infinity,
            color: color.withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
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

    final flutterLetterSpacing = layer.letterSpacing / 1000 * scaledFontSize;

    return TextStyle(
      fontFamily: layer.fontFamily.trim().isEmpty ? null : layer.fontFamily,
      fontSize: scaledFontSize,
      fontWeight: _parseFontWeight(layer.fontWeight),
      fontStyle: layer.fontStyle.toLowerCase().contains('italic')
          ? FontStyle.italic
          : FontStyle.normal,
      color: _parseHexColor(layer.color) ?? const Color(0xFF000000),
      height: height,
      letterSpacing: flutterLetterSpacing,
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

  Color? _parseHexColor(dynamic value) {
    final rawValue = value?.toString().trim();
    if (rawValue == null || rawValue.isEmpty) return null;

    final raw = rawValue.replaceAll('#', '');

    try {
      if (raw.length == 6) {
        return Color(int.parse('FF$raw', radix: 16));
      }

      if (raw.length == 8) {
        return Color(int.parse(raw, radix: 16));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Widget _buildSelectionOverlay({
    required DesignPageModel page,
    required double scaleX,
    required double scaleY,
  }) {
    DesignFrameModel? selectedFrame;
    for (final frame in page.effectiveFrames) {
      if (frame.id == _selectedFrameId) selectedFrame = frame;
    }
    DesignLayerModel? selectedTextLayer;
    for (final layer in page.effectiveTextLayers) {
      if (layer.id == _selectedTextLayerId) {
        selectedTextLayer = layer;
        break;
      }
    }

    return Stack(
      children: [
        if (selectedFrame != null)
          Positioned(
            left: selectedFrame.x * scaleX,
            top: selectedFrame.y * scaleY,
            width: selectedFrame.width * scaleX,
            height: selectedFrame.height * scaleY,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(selectedFrame.borderRadius * scaleX),
                ),
              ),
            ),
          ),
        if (selectedTextLayer != null)
          Positioned(
            left: selectedTextLayer.x * scaleX,
            top: selectedTextLayer.y * scaleY,
            width: selectedTextLayer.width * scaleX,
            height: selectedTextLayer.height * scaleY,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  TextAlign _parseFlutterTextAlign(String? value) {
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

  DesignLayerModel? _findSelectedTextLayer(DesignSchemaModel schema) {
    if (_selectedTextLayerId == null) return null;

    final page = schema.pages[_activePageIndex];

    for (final layer in page.effectiveTextLayers) {
      if (layer.id == _selectedTextLayerId) {
        return layer;
      }
    }

    return null;
  }

  void _selectTextLayer(DesignLayerModel layer) {
    final currentText = _editedTextById[layer.id] ?? _layerDisplayText(layer);

    debugPrint('SELECT TEXT LAYER id=${layer.id} current=$currentText');

    setState(() {
      _selectedTextLayerId = layer.id;
      _selectedFrameId = null;
      _inlineDraftText = currentText;
    });

    _openTextEditor(layer);
  }

  Future<void> _openTextEditor(DesignLayerModel layer) async {
    final currentText = _editedTextById[layer.id] ?? _layerDisplayText(layer);
    final controller = TextEditingController(text: currentText);

    debugPrint('OPEN TEXT EDITOR id=${layer.id} current=$currentText');

    if (!mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Teks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan teks',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, controller.text),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    setState(() {
      _editedTextById[layer.id] = result;
      _selectedTextLayerId = layer.id;
      _selectedFrameId = null;
    });

    debugPrint('EDIT TEXT layer_id=${layer.id} old="$currentText" new="$result"');
  }

  Widget _buildInlineTextEditor(DesignSchemaModel schema) {
    final selectedLayer = _findSelectedTextLayer(schema);

    if (selectedLayer == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Teks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('inline-editor-${selectedLayer.id}'),
            initialValue: _inlineDraftText,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Masukkan teks',
            ),
            onChanged: (value) {
              _inlineDraftText = value;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTextLayerId = null;
                    _inlineDraftText = '';
                  });
                },
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  debugPrint('SAVE INLINE TEXT id=${selectedLayer.id} value=$_inlineDraftText');

                  setState(() {
                    _editedTextById[selectedLayer.id] = _inlineDraftText;
                    _selectedTextLayerId = null;
                  });
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageThumbnails(DesignSchemaModel schema) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: schema.pages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final page = schema.pages[index];
          final isActive = index == _activePageIndex;

          return InkWell(
            onTap: () {
              setState(() {
                _activePageIndex = index;
                _selectedFrameId = null;
              });
            },
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? Colors.blue : Colors.grey.shade400,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: page.previewUrl != null && page.previewUrl!.isNotEmpty
                  ? Image.network(
                      page.previewUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Center(
                          child: Text('Page ${page.pageNumber}'),
                        );
                      },
                    )
                  : Center(
                      child: Text('Page ${page.pageNumber}'),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openPreview,
                child: const Text('Preview'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleCheckout,
                child: const Text('Lanjut Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrame({
    required BuildContext context,
    required DesignFrameModel frame,
    required double scaleX,
    required double scaleY,
    String? layerId,
  }) {
    final state = _photoStateByFrameId[frame.id];
    final fallbackImageSource = layerId != null ? _resolveLayerImageSourceById(layerId) : null;
    final hasPhoto = state != null || fallbackImageSource != null;
    final isActive = _selectedFrameId == frame.id;
    if (layerId != null) {
      final layer = _findLayerById(layerId);
      if (layer != null) {
        _debugPhotoVisual(
          layer: layer,
          selectedUserImageUrl: state != null ? 'memory-bytes' : null,
          finalSource: state != null ? 'memory-bytes' : fallbackImageSource,
        );
      }
    }

    final visualWidth = frame.width * scaleX;
    final visualHeight = frame.height * scaleY;

    final radius = BorderRadius.circular(
      frame.borderRadius * scaleX,
    );

    const minTapSize = 44.0;
    final tapWidth = math.max(visualWidth, minTapSize);
    final tapHeight = math.max(visualHeight, minTapSize);
    final tapInsetX = (tapWidth - visualWidth) / 2;
    final tapInsetY = (tapHeight - visualHeight) / 2;

    return Positioned(
      left: (frame.x * scaleX) - tapInsetX,
      top: (frame.y * scaleY) - tapInsetY,
      width: tapWidth,
      height: tapHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
          onTap: () {
            debugPrint('PHOTO LAYER TAP id=${layerId ?? frame.id}');
            setState(() {
              _selectedFrameId = frame.id;
              _selectedTextLayerId = null;
            });
            _openFrameEditor(frame);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: tapInsetX,
              top: tapInsetY,
              width: visualWidth,
              height: visualHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: isActive ? Colors.blue : Colors.white70,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: hasPhoto
                      ? (state != null
                          ? _buildCroppedPhoto(state)
                          : _buildTemplateImage(fallbackImageSource!))
                      : Container(
                          color: Colors.black.withOpacity(0.06),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: Colors.black.withOpacity(0.45)),
                                const SizedBox(height: 4),
                                Text(
                                  frame.placeholder,
                                  style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55)),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            if (state != null)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Terisi', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCroppedPhoto(FramePhotoState state) {
    return ClipRect(
      child: Transform.translate(
        offset: state.offset,
        child: Transform.scale(
          scale: state.scale,
          child: Transform.rotate(
            angle: state.rotation * math.pi / 180,
            child: SizedBox.expand(
              child: Image.memory(state.imageBytes, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoEditorCanvas({
    required FramePhotoState state,
    required ValueChanged<FramePhotoState> onChanged,
  }) {
    Offset startFocalPoint = Offset.zero;
    Offset startOffset = state.offset;
    double startScale = state.scale;

    return GestureDetector(
      onScaleStart: (details) {
        startFocalPoint = details.focalPoint;
        startOffset = state.offset;
        startScale = state.scale;
      },
      onScaleUpdate: (details) {
        final nextScale = (startScale * details.scale).clamp(0.5, 5.0);
        final nextOffset = startOffset + (details.focalPoint - startFocalPoint);
        onChanged(
          state.copyWith(
            scale: nextScale,
            offset: nextOffset,
          ),
        );
      },
      child: _buildCroppedPhoto(state),
    );
  }

  Future<FramePhotoState?> _pickPhotoForFrame(
    DesignFrameModel frame, {
    FramePhotoState? baseState,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final initial = baseState ?? FramePhotoState(frameId: frame.id, imageBytes: bytes);
    return initial.copyWith(
      imageBytes: bytes,
      fileName: file.name,
      scale: 1,
      offset: Offset.zero,
      rotation: 0,
    );
  }

  Future<void> _openFrameEditor(DesignFrameModel frame) async {
    // TODO: Use polygon clipper if frame.polygonPoints is available.
    var draftState = _photoStateByFrameId[frame.id];
    final result = await showModalBottomSheet<FramePhotoState?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Edit Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: math.max(frame.width, 1) / math.max(frame.height, 1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.black12,
                          child: draftState == null
                              ? const Center(child: Text('Belum ada foto'))
                              : _buildPhotoEditorCanvas(
                                  state: draftState!,
                                  onChanged: (value) => setSheetState(() => draftState = value),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await _pickPhotoForFrame(frame, baseState: draftState);
                            if (picked != null) setSheetState(() => draftState = picked);
                          },
                          child: Text(draftState == null ? 'Pilih Foto' : 'Ganti Foto'),
                        ),
                        OutlinedButton(
                          onPressed: draftState == null ? null : () => setSheetState(() => draftState = draftState!.copyWith(scale: 1, offset: Offset.zero, rotation: 0)),
                          child: const Text('Reset'),
                        ),
                        OutlinedButton(
                          onPressed: draftState == null ? null : () => setSheetState(() => draftState = null),
                          child: const Text('Hapus Foto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Batal')),
                        const Spacer(),
                        ElevatedButton(onPressed: draftState == null ? null : () => Navigator.pop(sheetContext, draftState), child: const Text('Simpan')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() => _photoStateByFrameId[result.frameId] = result);
  }

  void _openPreview() {
    debugPrint('PREVIEW BUTTON CLICKED');
    final schema = _schema;

    if (schema == null || schema.pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template tidak memiliki halaman.'),
        ),
      );
      return;
    }

    final missingFramesCount = schema.pages
        .expand((page) => page.effectiveFrames)
        .where((frame) => _photoStateByFrameId[frame.id] == null)
        .length;

    if (missingFramesCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$missingFramesCount frame foto belum diisi.'),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotobookPreviewScreen(
          design: widget.design,
          schema: schema,
          photoStateByFrameId: Map.of(_photoStateByFrameId),
          editedTextById: Map.of(_editedTextById),
          onBackToEdit: () => Navigator.pop(context),
          onContinueCheckout: _handleCheckout,
        ),
      ),
    );
  }

  void _handleCheckout() {
    debugPrint('CHECKOUT BUTTON CLICKED');
    final schema = _schema;

    if (schema == null || schema.pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template tidak memiliki halaman.'),
        ),
      );
      return;
    }

    final missingFrames = <Map<String, dynamic>>[];

    for (final page in schema.pages) {
      for (final frame in page.effectiveFrames) {
        final state = _photoStateByFrameId[frame.id];

        if (state == null) {
          missingFrames.add({
            'label': 'Halaman ${page.pageNumber}: ${frame.placeholder} belum diisi',
            'pageIndex': schema.pages.indexOf(page),
            'frameId': frame.id,
          });
        }
      }
    }

    if (missingFrames.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Foto belum lengkap'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: missingFrames
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['label'] as String),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _activePageIndex = item['pageIndex'] as int;
                          _selectedFrameId = item['frameId'] as String;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotobookCheckoutScreen(
          design: widget.design,
          productId: widget.productId,
          schema: schema,
          photoStateByFrameId: Map.of(_photoStateByFrameId),
          editedTextById: Map.of(_editedTextById),
        ),
      ),
    );
  }
}
