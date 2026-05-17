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
          'photo_name': selectedPhotoFilesByFrameId[frame.id]?.name,
          'crop': {'x': 0, 'y': 0, 'scale': 1, 'rotation': 0},
        }).toList(),
      }).toList(),
    };
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
                                    selectedBytes: selectedPhotoBytesByFrameId[f.id],
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
                onPressed: () {
                  final json = buildProjectJson();
                  showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Preview Project JSON'), content: SingleChildScrollView(child: Text(json.toString()))));
                },
                child: const Text('Preview'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siap lanjut checkout.'))), child: const Text('Lanjut Checkout'))),
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
  final Uint8List? selectedBytes;
  final VoidCallback onTap;
  final double scaleX;
  final double scaleY;

  const PhotoFrameWidget({super.key, required this.frame, required this.selectedBytes, required this.onTap, required this.scaleX, required this.scaleY});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(frame.borderRadius * ((scaleX + scaleY) / 2));
    return Positioned(
      left: frame.x * scaleX,
      top: frame.y * scaleY,
      width: frame.width * scaleX,
      height: frame.height * scaleY,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: selectedBytes == null ? Colors.white.withValues(alpha: 0.4) : null,
              borderRadius: radius,
              border: Border.all(color: Colors.white70),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: selectedBytes != null
                  ? Image.memory(selectedBytes!, fit: BoxFit.cover)
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_photo_alternate_outlined), Text(frame.placeholder, style: const TextStyle(fontSize: 12))]),
            ),
          ),
        ),
      ),
    );
  }
}
