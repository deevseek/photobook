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
  final Uint8List? imageBytes;
  final String? fileName;
  final double scale;
  final Offset offset;
  final double rotation;

  const FramePhotoState({
    required this.frameId,
    this.imageBytes,
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

      final detail = widget.design.parsedDesignSchema != null
          ? widget.design
          : await _repo.getDesignDetail(widget.design.id);
      final schema = detail.parsedDesignSchema;

      if (schema == null) {
        setState(() {
          _error = 'Design schema tidak ditemukan.';
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
                ],
              ),
            ),
          ),
        );
      },
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
  }) {
    final state = _photoStateByFrameId[frame.id];
    final hasPhoto = state?.imageBytes != null;
    final isActive = _selectedFrameId == frame.id;

    final visualWidth = frame.width * scaleX;
    final visualHeight = frame.height * scaleY;

    final radius = BorderRadius.circular(
      frame.borderRadius * scaleX,
    );

    return Positioned(
      left: frame.x * scaleX,
      top: frame.y * scaleY,
      width: visualWidth,
      height: visualHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            _selectedFrameId = frame.id;
          });
          _openFrameEditor(frame);
        },
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
                ? Transform.translate(
                    offset: state!.offset,
                    child: Transform.scale(
                      scale: state.scale,
                      child: Transform.rotate(
                        angle: state.rotation,
                        child: Image.memory(
                          state.imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  )
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
    );
  }

  Future<void> _openFrameEditor(DesignFrameModel frame) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();

    setState(() {
      _photoStateByFrameId[frame.id] = FramePhotoState(
        frameId: frame.id,
        imageBytes: bytes,
        fileName: file.name,
      );
    });
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotobookPreviewScreen(
          design: widget.design,
          schema: schema,
          photoStateByFrameId: _photoStateByFrameId,
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

    final missingFrames = <String>[];

    for (final page in schema.pages) {
      for (final frame in page.frames) {
        final state = _photoStateByFrameId[frame.id];

        if (state == null || state.imageBytes == null) {
          missingFrames.add('Halaman ${page.pageNumber}: ${frame.placeholder}');
        }
      }
    }

    if (missingFrames.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Foto belum lengkap'),
          content: SingleChildScrollView(
            child: Text(
              'Lengkapi foto berikut sebelum checkout:\n\n${missingFrames.join('\n')}',
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
          product: widget.productId,
          photoStateByFrameId: _photoStateByFrameId,
        ),
      ),
    );
  }
}
