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
          if (page.layers.isNotEmpty)
            for (final layer in page.layers)
              if (layer.type == 'text') layer.id: layer.content,
        for (final page in schema.pages)
          if (page.layers.isEmpty)
            for (final text in page.effectiveTexts) text.id: text.text,
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

  Widget _buildCanvas(BuildContext context, DesignSchemaModel schema) {
    final page = schema.pages[_activePageIndex];
    final photoLayers = page.layers.where((layer) => layer.type == 'photo').toList();
    final textLayers = page.layers.where((layer) => layer.type == 'text').toList();

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  debugPrint('CANVAS POINTER DOWN local=${event.localPosition}');
                },
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildPageBackground(page)),
                    if (page.layers.isNotEmpty) ...[
                      ...photoLayers.map(
                        (layer) => _buildPhotoLayer(
                          context: context,
                          layer: layer,
                          scaleX: scaleX,
                          scaleY: scaleY,
                        ),
                      ),
                      ...textLayers.map(
                        (layer) => _buildTextLayer(
                          layer: layer,
                          scaleX: scaleX,
                          scaleY: scaleY,
                        ),
                      ),
                    ] else ...[
                      ...page.effectiveFrames.map(
                        (frame) => _buildFrame(
                          context: context,
                          frame: frame,
                          scaleX: scaleX,
                          scaleY: scaleY,
                        ),
                      ),
                    ],
                    if (_selectedFrameId != null || _selectedTextLayerId != null)
                      IgnorePointer(
                        child: _buildSelectionOverlay(page: page, scaleX: scaleX, scaleY: scaleY),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoLayer({
    required BuildContext context,
    required DesignLayerModel layer,
    required double scaleX,
    required double scaleY,
  }) {
    return _buildFrame(
      context: context,
      frame: layer.frame!,
      scaleX: scaleX,
      scaleY: scaleY,
      layerId: layer.id,
    );
  }


  Widget _buildPageBackground(DesignPageModel page) {
    final candidates = <String?, String>{
      page.editorBackgroundUrl: 'editor_background_url',
      page.cleanBackgroundUrl: 'clean_background_url',
      page.backgroundUrl: 'background_url',
      page.previewUrl: 'preview_url',
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
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('Gagal memuat background template'),
      ),
    );
  }
  Widget _buildTextLayer({
    required DesignLayerModel layer,
    required double scaleX,
    required double scaleY,
  }) {
    final displayText = _editedTextById[layer.id] ?? layer.content;
    final fontSize = layer.fontSize <= 0 ? 24.0 : layer.fontSize;

    final renderedX = layer.x * scaleX;

    // Perluas hitbox ke atas karena font IDML besar bisa overflow dari frame.
    final renderedY = math.max(0, (layer.y - (fontSize * 1.2)) * scaleY);
    final renderedWidth = layer.width * scaleX;
    final renderedHeight = (layer.height + (fontSize * 1.8)) * scaleY;

    final visualOffsetY = fontSize * 1.2 * scaleY;
    final isSelected = _selectedTextLayerId == layer.id;
    final isEmptyText = displayText.trim().isEmpty;

    final textStyle = _textStyleFromLayer(layer, scaleY);

    debugPrint(
      'TEXT RENDER id=${layer.id} content=$displayText x=${layer.x} y=${layer.y} w=${layer.width} h=${layer.height}',
    );

    return Positioned(
      left: renderedX,
      top: renderedY,
      width: renderedWidth,
      height: renderedHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            debugPrint('TEXT OVERLAY CLICK id=${layer.id} text=$displayText');
            _openTextEditor(layer);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? Colors.redAccent
                    : Colors.redAccent.withOpacity(0.25),
                width: isSelected ? 1 : 0.5,
              ),
            ),
            alignment: _parseTextAlign(layer.textAlign),
            child: Transform.translate(
              offset: Offset(0, visualOffsetY),
              child: SizedBox(
                width: layer.width * scaleX,
                height: layer.height * scaleY,
                child: Text(
                  isEmptyText ? 'Ketuk untuk edit teks' : displayText,
                  style: isEmptyText
                      ? textStyle.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade500,
                        )
                      : textStyle,
                  textAlign: _parseFlutterTextAlign(layer.textAlign),
                  maxLines: null,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
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
    } else if (layer.lineHeight > 0) {
      height = layer.lineHeight;
    }

    final tracking = layer.letterSpacing;
    final flutterLetterSpacing = tracking / 1000 * scaledFontSize;

    return TextStyle(
      fontFamily: layer.fontFamily.trim().isEmpty ? null : layer.fontFamily,
      fontSize: scaledFontSize,
      fontWeight: _parseFontWeight(layer.fontWeight),
      fontStyle: layer.fontStyle.toLowerCase().contains('italic')
          ? FontStyle.italic
          : FontStyle.normal,
      color: _parseHexColor(layer.color),
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

  Color _parseHexColor(String? value) {
    final raw = (value ?? '#000000').replaceAll('#', '').trim();

    try {
      if (raw.length == 6) {
        return Color(int.parse('FF$raw', radix: 16));
      }

      if (raw.length == 8) {
        return Color(int.parse(raw, radix: 16));
      }
    } catch (_) {}

    return Colors.black;
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
    final selectedTextLayer = page.layers
        .where((layer) => layer.type == 'text' && layer.id == _selectedTextLayerId)
        .cast<DesignLayerModel?>()
        .firstWhere((layer) => layer != null, orElse: () => null);

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

  Alignment _parseTextAlign(String? value) {
    switch (value?.toLowerCase()) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
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

    for (final layer in page.layers) {
      if (layer.type == 'text' && layer.id == _selectedTextLayerId) {
        return layer;
      }
    }

    return null;
  }

  void _selectTextLayer(DesignLayerModel layer) {
    final currentText = _editedTextById[layer.id] ?? layer.content;

    debugPrint('SELECT TEXT LAYER id=${layer.id} current=$currentText');

    setState(() {
      _selectedTextLayerId = layer.id;
      _selectedFrameId = null;
      _inlineDraftText = currentText;
    });

    _openTextEditor(layer);
  }

  Future<void> _openTextEditor(DesignLayerModel layer) async {
    final currentText = _editedTextById[layer.id] ?? layer.content;
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

    debugPrint('SAVE TEXT id=${layer.id} value=$result');
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
    final hasPhoto = state != null;
    final isActive = _selectedFrameId == frame.id;

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
                      ? _buildCroppedPhoto(state!)
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
            if (hasPhoto)
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
