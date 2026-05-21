import 'dart:math' as math;
import 'dart:typed_data';

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
  final _repo = PhotobookRepository();

  int _activePageIndex = 0;
  String? _selectedFrameId;
  final Map<String, FramePhotoState> _photoStateByFrameId = {};
  final Map<String, String> _editedTextById = {};

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

      setState(() {
        _schema = schema;
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: page.backgroundUrl != null &&
                            page.backgroundUrl!.isNotEmpty
                        ? Image.network(
                            page.backgroundUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(color: Colors.white);
                            },
                          )
                        : Container(color: Colors.white),
                  ),
                  ...page.frames.map(
                    (frame) => _buildFrame(
                      context: context,
                      frame: frame,
                      scaleX: scaleX,
                      scaleY: scaleY,
                    ),
                  ),
                  ...page.texts.map(
                    (text) => _buildTextLayer(
                      text: text,
                      scaleX: scaleX,
                      scaleY: scaleY,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextLayer({
    required DesignTextModel text,
    required double scaleX,
    required double scaleY,
  }) {
    final displayText = _editedTextById[text.id] ?? text.text;
    final placeholder = (text.placeholder?.trim().isNotEmpty ?? false)
        ? text.placeholder!.trim()
        : 'Ketuk untuk edit teks';
    final isEmptyText = displayText.trim().isEmpty;
    final textStyle = text.style.toTextStyle().copyWith(
          fontSize: (text.style.fontSize ?? 16) * scaleY,
        );

    return Positioned(
      left: text.x * scaleX,
      top: text.y * scaleY,
      width: text.width * scaleX,
      height: text.height * scaleY,
      child: Transform.rotate(
        angle: text.rotation * math.pi / 180,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openTextEditor(text),
          child: Align(
            alignment: _parseTextAlign(text.style.textAlign),
            child: Text(
              isEmptyText ? placeholder : displayText,
              textAlign: _parseFlutterTextAlign(text.style.textAlign),
              maxLines: null,
              overflow: TextOverflow.visible,
              style: isEmptyText
                  ? textStyle.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500,
                    )
                  : textStyle,
            ),
          ),
        ),
      ),
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

  Future<void> _openTextEditor(DesignTextModel text) async {
    final controller = TextEditingController(text: _editedTextById[text.id] ?? text.text);
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Teks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan teks album',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, ''),
                    child: const Text('Reset ke bawaan desain'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
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

    if (!mounted || result == null) return;
    setState(() {
      if (result.isEmpty) {
        _editedTextById.remove(text.id);
      } else {
        _editedTextById[text.id] = result;
      }
    });
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
          setState(() {
            _selectedFrameId = frame.id;
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
                      ? _buildPhotoInFrame(state!)
                      : Container(
                          color: Colors.white.withOpacity(0.20),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_a_photo_outlined),
                                const SizedBox(height: 4),
                                Text(
                                  frame.placeholder,
                                  style: const TextStyle(fontSize: 11),
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

  Widget _buildPhotoInFrame(FramePhotoState state) {
    return Transform.rotate(
      angle: state.rotation * math.pi / 180,
      child: Transform.translate(
        offset: state.offset,
        child: Transform.scale(
          scale: state.scale,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.memory(state.imageBytes),
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
      child: _buildPhotoInFrame(state),
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
        .expand((page) => page.frames)
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
          photoStateByFrameId: _photoStateByFrameId,
          editedTextById: _editedTextById,
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
      for (final frame in page.frames) {
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
          photoStateByFrameId: _photoStateByFrameId,
          editedTextById: _editedTextById,
        ),
      ),
    );
  }
}
