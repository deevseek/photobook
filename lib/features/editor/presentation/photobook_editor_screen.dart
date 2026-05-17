import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/models/photobook_order_model.dart';
import '../../../data/repositories/photobook_repository.dart';

const double minTapSize = 44;

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
    this.scale = 1,
    this.offset = Offset.zero,
    this.rotation = 0,
  });

  bool get hasPhoto => imageBytes != null;

  FramePhotoState copyWith({Uint8List? imageBytes, String? fileName, double? scale, Offset? offset, double? rotation, bool clearImage = false}) {
    return FramePhotoState(
      frameId: frameId,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      fileName: clearImage ? null : (fileName ?? this.fileName),
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
    );
  }
}

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
  final Map<String, FramePhotoState> photoStateByFrameId = {};
  DesignSchemaModel? _schema;
  bool _loading = true;
  String? _error;
  int _activePageIndex = 0;
  String? _selectedFrameId;

  @override
  void initState() { super.initState(); _loadSchema(); }

  Future<void> _loadSchema() async { /* unchanged core */
    try { setState(() { _loading = true; _error = null; }); final detail = widget.design.parsedDesignSchema != null ? widget.design : await _repo.getDesignDetail(widget.design.id); final schema = detail.parsedDesignSchema; if (schema == null) { setState(() => _error = 'Design schema tidak ditemukan.'); return; } if (schema.pages.isEmpty) { setState(() => _error = 'Template tidak memiliki halaman'); return; } setState(() => _schema = schema);
    } catch (e) { setState(() => _error = e.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _openEditModal(DesignFrameModel frame) async {
    final result = await showModalBottomSheet<FramePhotoState>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PhotoFrameCropEditorModal(frame: frame, existing: photoStateByFrameId[frame.id], onPickImage: () => _picker.pickImage(source: ImageSource.gallery)),
    );
    if (result != null) {
      setState(() {
        photoStateByFrameId[frame.id] = result;
        if (result.fileName != null) {
          selectedPhotoFilesByFrameId[frame.id] = XFile(result.fileName!);
        }
      });
    }
  }

  List<({DesignFrameModel frame, int pageNumber})> _getMissingFrames() {
    final schema = _schema; if (schema == null) return const [];
    final output = <({DesignFrameModel frame, int pageNumber})>[];
    for (final page in schema.pages) {
      for (final frame in page.frames) {
        if (!(photoStateByFrameId[frame.id]?.hasPhoto ?? false)) output.add((frame: frame, pageNumber: page.pageNumber));
      }
    }
    return output;
  }

  Map<String, dynamic> buildProjectJson(Map<String, UploadedProjectPhoto> uploadedPhotosByFrameId) {
    final schema = _schema!;
    return {'product_id': widget.productId, 'design_id': widget.design.id, 'design_schema_source': widget.design.designSchemaSource, 'page_count': schema.pages.length, 'print_quantity': 1,
      'pages': schema.pages.map((page) => {'page_number': page.pageNumber, 'background_url': page.backgroundUrl, 'frames': page.frames.map((frame) {
        final uploaded = uploadedPhotosByFrameId[frame.id]; final photoState = photoStateByFrameId[frame.id];
        return {'frame_id': frame.id, 'placeholder': frame.placeholder, 'photo_attached': photoState?.hasPhoto ?? false, 'photo_file_name': photoState?.fileName, 'photo_id': uploaded?.photoId, 'photo_url': uploaded?.fileUrl, 'fit': 'cover', 'crop': {'scale': photoState?.scale ?? 1, 'offset_x': photoState?.offset.dx ?? 0, 'offset_y': photoState?.offset.dy ?? 0, 'rotation': photoState?.rotation ?? 0}};
      }).toList()}).toList()};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Editor PhotoBook')), body: Center(child: Text(_error!)));
    final schema = _schema!; final page = schema.pages[_activePageIndex];
    return Scaffold(appBar: AppBar(title: Text(widget.design.title)), body: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Expanded(child: Center(child: LayoutBuilder(builder: (context, c) {
      final scale = math.min(c.maxWidth / math.max(schema.pageWidth, 1), c.maxHeight / math.max(schema.pageHeight, 1));
      final dw = schema.pageWidth * scale; final dh = schema.pageHeight * scale; final sx = dw / schema.pageWidth; final sy = dh / schema.pageHeight;
      return SizedBox(width: dw, height: dh, child: ClipRRect(borderRadius: BorderRadius.circular(10), child: GestureDetector(
        onTapUp: (details) {
          final p = details.localPosition;
          final candidates = page.frames.where((f) {
            final vw = f.width * sx; final vh = f.height * sy; final tw = math.max(vw, minTapSize); final th = math.max(vh, minTapSize);
            final rect = Rect.fromCenter(center: Offset(f.x * sx + vw / 2, f.y * sy + vh / 2), width: tw, height: th);
            return rect.contains(p);
          }).toList();
          if (candidates.isEmpty) { setState(() => _selectedFrameId = null); return; }
          candidates.sort((a,b){final ca=Offset(a.x*sx+a.width*sx/2,a.y*sy+a.height*sy/2); final cb=Offset(b.x*sx+b.width*sx/2,b.y*sy+b.height*sy/2); return (ca-p).distance.compareTo((cb-p).distance);});
          setState(() => _selectedFrameId = candidates.first.id);
        },
        child: Stack(children: [Positioned.fill(child: page.backgroundUrl != null ? Image.network(page.backgroundUrl!, fit: BoxFit.cover) : Container(color: Colors.white)),
          ...page.frames.map((f) => PhotoFrameWidget(frame: f, state: photoStateByFrameId[f.id], scaleX: sx, scaleY: sy, isActive: _selectedFrameId == f.id)),
          if (_selectedFrameId != null)
            _FrameActionsOverlay(frame: page.frames.firstWhere((e)=>e.id==_selectedFrameId), scaleX: sx, scaleY: sy, hasPhoto: photoStateByFrameId[_selectedFrameId!]?.hasPhoto ?? false, onFill: () => _openEditModal(page.frames.firstWhere((e)=>e.id==_selectedFrameId)), onEdit: () => _openEditModal(page.frames.firstWhere((e)=>e.id==_selectedFrameId))),
        ]),
      )));
    }))), const SizedBox(height: 8), SizedBox(height: 72, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: schema.pages.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => InkWell(onTap: ()=>setState((){_activePageIndex=i; _selectedFrameId=null;}), child: Container(width: 90, decoration: BoxDecoration(border: Border.all(color: i==_activePageIndex?Colors.blue:Colors.grey.shade400, width: i==_activePageIndex?2:1), borderRadius: BorderRadius.circular(8)), clipBehavior: Clip.antiAlias, child: Center(child: Text('Page ${schema.pages[i].pageNumber}'))))))]))),
      bottomNavigationBar: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: OutlinedButton(onPressed: (){}, child: const Text('Preview'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: () async {
        final missing = _getMissingFrames(); if (missing.isNotEmpty) { await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Foto yang belum diisi'), content: SizedBox(width: 360, child: ListView(shrinkWrap: true, children: missing.map((m)=>ListTile(title: Text('Halaman ${m.pageNumber}: ${m.frame.placeholder}'), onTap: (){Navigator.pop(context); setState((){_activePageIndex = schema.pages.indexWhere((p)=>p.pageNumber==m.pageNumber); _selectedFrameId = m.frame.id;});})).toList())), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Tutup'))])); return; }
      }, child: const Text('Lanjut Checkout')))])));
  }
}

class PhotoFrameWidget extends StatelessWidget {
  final DesignFrameModel frame; final FramePhotoState? state; final double scaleX; final double scaleY; final bool isActive;
  const PhotoFrameWidget({super.key, required this.frame, required this.state, required this.scaleX, required this.scaleY, required this.isActive});
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(frame.borderRadius * ((scaleX + scaleY) / 2));
    final hasPhoto = state?.hasPhoto ?? false;
    return Positioned(left: frame.x * scaleX, top: frame.y * scaleY, width: frame.width * scaleX, height: frame.height * scaleY, child: DecoratedBox(decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: isActive ? Colors.blue : Colors.white70, width: isActive ? 2 : 1, style: hasPhoto ? BorderStyle.solid : BorderStyle.solid), boxShadow: isActive ? [BoxShadow(color: Colors.blue.withValues(alpha: .25), blurRadius: 8)] : null), child: ClipRRect(borderRadius: radius, child: hasPhoto ? Transform(transform: Matrix4.identity()..translate(state!.offset.dx, state!.offset.dy)..scale(state!.scale)..rotateZ(state!.rotation), alignment: Alignment.center, child: Image.memory(state!.imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)) : Container(color: Colors.white.withValues(alpha: .2), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo_outlined), Text(frame.placeholder, style: const TextStyle(fontSize: 11))]))))));
  }
}

class _FrameActionsOverlay extends StatelessWidget {
  final DesignFrameModel frame; final double scaleX; final double scaleY; final bool hasPhoto; final VoidCallback onFill; final VoidCallback onEdit;
  const _FrameActionsOverlay({required this.frame, required this.scaleX, required this.scaleY, required this.hasPhoto, required this.onFill, required this.onEdit});
  @override
  Widget build(BuildContext context) => Positioned(left: frame.x * scaleX, top: (frame.y * scaleY) - 46, child: Material(color: Colors.black87, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [TextButton(onPressed: onFill, child: Text(hasPhoto ? 'Ganti' : 'Isi Foto')), TextButton(onPressed: onEdit, child: const Text('Edit'))]))));
}

class PhotoFrameCropEditorModal extends StatefulWidget {
  final DesignFrameModel frame; final FramePhotoState? existing; final Future<XFile?> Function() onPickImage;
  const PhotoFrameCropEditorModal({super.key, required this.frame, required this.existing, required this.onPickImage});
  @override State<PhotoFrameCropEditorModal> createState() => _PhotoFrameCropEditorModalState();
}
class _PhotoFrameCropEditorModalState extends State<PhotoFrameCropEditorModal> {
  late TransformationController _controller; Uint8List? _bytes; String? _fileName;
  @override void initState() { super.initState(); _controller = TransformationController(); _bytes = widget.existing?.imageBytes; _fileName = widget.existing?.fileName; if (widget.existing != null) _controller.value = Matrix4.identity()..translate(widget.existing!.offset.dx, widget.existing!.offset.dy)..scale(widget.existing!.scale)..rotateZ(widget.existing!.rotation); }
  Future<void> _pick() async { final f = await widget.onPickImage(); if (f == null) return; final b = await f.readAsBytes(); setState(() { _bytes = b; _fileName = f.name; _controller.value = Matrix4.identity(); }); }
  void _zoom(double d) { final m = _controller.value.clone(); final c = m.getMaxScaleOnAxis(); final n = (c + d).clamp(0.5, 5.0); final ratio = n / c; m.scale(ratio); setState(() => _controller.value = m); }
  FramePhotoState _extract() { final v = _controller.value.storage; return FramePhotoState(frameId: widget.frame.id, imageBytes: _bytes, fileName: _fileName, scale: _controller.value.getMaxScaleOnAxis(), offset: Offset(v[12], v[13]), rotation: 0); }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: SizedBox(height: MediaQuery.of(context).size.height * .9, child: Column(children: [ListTile(title: Text('Edit ${widget.frame.placeholder}')), Expanded(child: Center(child: AspectRatio(aspectRatio: math.max(widget.frame.width,1)/math.max(widget.frame.height,1), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(color: Colors.black12, child: _bytes == null ? Center(child: FilledButton(onPressed: _pick, child: const Text('Pilih Foto'))) : InteractiveViewer(transformationController: _controller, minScale: 0.5, maxScale: 5, boundaryMargin: const EdgeInsets.all(200), child: Image.memory(_bytes!, fit: BoxFit.cover))))))), Wrap(spacing: 8, runSpacing: 8, children: [OutlinedButton(onPressed: _pick, child: Text(_bytes == null ? 'Pilih Foto' : 'Ganti Foto')), OutlinedButton(onPressed: ()=>_zoom(-0.1), child: const Text('Zoom -')), OutlinedButton(onPressed: ()=>_zoom(0.1), child: const Text('Zoom +')), OutlinedButton(onPressed: ()=>setState(()=>_controller.value = Matrix4.identity()), child: const Text('Reset'))]), const SizedBox(height: 10), Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: OutlinedButton(onPressed: ()=>Navigator.pop(context), child: const Text('Batal'))), const SizedBox(width: 8), Expanded(child: FilledButton(onPressed: _bytes == null ? null : ()=>Navigator.pop(context, _extract()), child: const Text('Simpan')))]))]))));
}
