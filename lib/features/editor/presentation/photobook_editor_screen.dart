import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class PhotobookEditorScreen extends StatefulWidget {
  final int productId;
  final PhotobookDesignModel design;

  const PhotobookEditorScreen({super.key, required this.productId, required this.design});

  @override
  State<PhotobookEditorScreen> createState() => _PhotobookEditorScreenState();
}

class _PhotobookEditorScreenState extends State<PhotobookEditorScreen> {
  final _repo = PhotobookRepository();
  final _picker = ImagePicker();
  final Map<String, XFile> selectedPhotoFilesByFrameId = {};
  final Map<String, Uint8List> selectedPhotoBytesByFrameId = {};

  DesignSchemaModel? _schema;
  bool _loading = true;
  String? _error;
  int _activePageIndex = 0;

  @override
  void initState() {super.initState();_loadSchema();}

  Future<void> _loadSchema() async {
    try {
      setState(() {_loading = true; _error = null;});
      final detail = widget.design.parsedDesignSchema != null ? widget.design : await _repo.getDesignDetail(widget.design.id);
      final schema = detail.parsedDesignSchema;
      if (schema == null) { setState(() => _error = 'Design schema tidak ditemukan.'); return; }
      if (schema.pages.isEmpty) { setState(() => _error = 'Template tidak memiliki halaman'); return; }
      setState(() => _schema = schema);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickForFrame(DesignFrameModel frame) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        selectedPhotoFilesByFrameId[frame.id] = file;
        selectedPhotoBytesByFrameId[frame.id] = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memilih foto')));
    }
  }

  List<DesignFrameModel> _getMissingFrames() {
    final schema = _schema;
    if (schema == null) return const [];
    return schema.pages
        .expand((page) => page.frames)
        .where((frame) => !selectedPhotoFilesByFrameId.containsKey(frame.id))
        .toList();
  }

  Map<String, dynamic> buildProjectJson() {
    final schema = _schema!;
    return {
      'product_id': widget.productId,
      'design_id': widget.design.id,
      'design_schema_source': widget.design.designSchemaSource,
      'page_count': schema.pages.length,
      'pages': schema.pages.map((page) => {
        'page_number': page.pageNumber,
        'frames': page.frames.map((frame) => {
          'frame_id': frame.id,
          'photo_attached': selectedPhotoFilesByFrameId.containsKey(frame.id),
          'photo_file_name': selectedPhotoFilesByFrameId[frame.id]?.name,
          'crop': {'fit': 'cover', 'x': 0, 'y': 0, 'scale': 1, 'rotation': 0},
        }).toList(),
      }).toList(),
    };
  }

  void _openPreview() {
    final schema = _schema;
    if (schema == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotobookPreviewScreen(
        schema: schema,
        selectedPhotoBytesByFrameId: selectedPhotoBytesByFrameId,
      ),
    ));
  }

  Future<void> _onCheckoutPressed() async {
    final missingFrames = _getMissingFrames();
    if (missingFrames.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siap lanjut checkout.')));
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Masih ada frame foto yang belum diisi.'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: missingFrames
                .map((frame) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${frame.placeholder} belum diisi'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Lengkapi Foto')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lanjut checkout meski foto belum lengkap.')));
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Editor PhotoBook')), body: Center(child: Text(_error!)));

    final schema = _schema!;
    final page = schema.pages[_activePageIndex];
    return Scaffold(
      appBar: AppBar(title: Text(widget.design.title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (page.backgroundMissing || page.backgroundUrl == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text('Preview desain belum tersedia. Yang tampil hanya frame dari IDML.'),
              ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final schemaWidth = math.max(schema.pageWidth, 1);
                    final schemaHeight = math.max(schema.pageHeight, 1);
                    final scale = math.min(constraints.maxWidth / schemaWidth, constraints.maxHeight / schemaHeight);
                    final displayWidth = schemaWidth * scale;
                    final displayHeight = schemaHeight * scale;
                    final scaleX = displayWidth / schemaWidth;
                    final scaleY = displayHeight / schemaHeight;

                    return SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: page.backgroundUrl != null
                                    ? Image.network(
                                        page.backgroundUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: _parseColor(page.backgroundColor ?? '#FFFFFF')),
                                      )
                                    : Container(color: _parseColor(page.backgroundColor ?? '#FFFFFF')),
                              ),
                              ...page.assets.map((asset) => Positioned(
                                    left: asset.x * scaleX,
                                    top: asset.y * scaleY,
                                    width: asset.width * scaleX,
                                    height: asset.height * scaleY,
                                    child: Opacity(
                                      opacity: asset.opacity.clamp(0, 1),
                                      child: asset.url != null ? AppNetworkImage(url: asset.url, fit: BoxFit.cover) : const SizedBox.shrink(),
                                    ),
                                  )),
                              ...page.frames.map((f) => PhotoFrameWidget(
                                    frame: f,
                                    imageBytes: selectedPhotoBytesByFrameId[f.id],
                                    scaleX: scaleX,
                                    scaleY: scaleY,
                                    onTap: () => _pickForFrame(f),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: schema.pages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = schema.pages[i];
                  final active = i == _activePageIndex;
                  return InkWell(
                    onTap: () => setState(() => _activePageIndex = i),
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(border: Border.all(color: active ? Colors.blue : Colors.grey.shade400, width: active ? 2 : 1), borderRadius: BorderRadius.circular(8)),
                      clipBehavior: Clip.antiAlias,
                      child: p.previewUrl != null
                          ? AppNetworkImage(url: p.previewUrl, fit: BoxFit.cover)
                          : Center(child: Text('Page ${p.pageNumber}', style: const TextStyle(fontSize: 12))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openPreview,
                child: const Text('Preview'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: _onCheckoutPressed, child: const Text('Lanjut Checkout'))),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    if (normalized.length != 6) return Colors.white;
    return Color(int.parse('FF$normalized', radix: 16));
  }
}

class PhotoFrameWidget extends StatelessWidget {
  final DesignFrameModel frame;
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final double scaleX;
  final double scaleY;

  const PhotoFrameWidget({super.key, required this.frame, required this.imageBytes, required this.onTap, required this.scaleX, required this.scaleY});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(frame.borderRadius * ((scaleX + scaleY) / 2));
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: imageBytes == null ? Colors.white.withValues(alpha: 0.25) : null,
            borderRadius: radius,
            border: Border.all(color: Colors.white70),
          ),
          child: ClipRRect(
            borderRadius: radius,
            // TODO: support polygon clipping path from IDML points when backend sends polygon_points.
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_photo_alternate_outlined), Text(frame.placeholder, style: const TextStyle(fontSize: 12))]),
          ),
        ),
      ),
    );

    return Positioned(
      left: frame.x * scaleX,
      top: frame.y * scaleY,
      width: frame.width * scaleX,
      height: frame.height * scaleY,
      child: frame.rotation == 0 ? content : Transform.rotate(angle: frame.rotation * math.pi / 180, child: content),
    );
  }
}

class _PhotobookPreviewScreen extends StatelessWidget {
  final DesignSchemaModel schema;
  final Map<String, Uint8List> selectedPhotoBytesByFrameId;

  const _PhotobookPreviewScreen({required this.schema, required this.selectedPhotoBytesByFrameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: schema.pages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, pageIndex) {
          final page = schema.pages[pageIndex];
          return AspectRatio(
            aspectRatio: schema.pageWidth / schema.pageHeight,
            child: LayoutBuilder(builder: (context, constraints) {
              final scaleX = constraints.maxWidth / schema.pageWidth;
              final scaleY = constraints.maxHeight / schema.pageHeight;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: page.backgroundUrl != null
                          ? Image.network(page.backgroundUrl!, fit: BoxFit.cover)
                          : Container(color: Colors.white),
                    ),
                    ...page.assets.map((asset) => Positioned(
                          left: asset.x * scaleX,
                          top: asset.y * scaleY,
                          width: asset.width * scaleX,
                          height: asset.height * scaleY,
                          child: asset.url != null ? AppNetworkImage(url: asset.url, fit: BoxFit.cover) : const SizedBox.shrink(),
                        )),
                    ...page.frames.where((frame) => selectedPhotoBytesByFrameId.containsKey(frame.id)).map((frame) => PhotoFrameWidget(
                          frame: frame,
                          imageBytes: selectedPhotoBytesByFrameId[frame.id],
                          scaleX: scaleX,
                          scaleY: scaleY,
                          onTap: () {},
                        )),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
