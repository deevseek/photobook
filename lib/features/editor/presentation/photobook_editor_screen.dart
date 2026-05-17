import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

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
  final _picker = ImagePicker();
  final Map<String, XFile> selectedPhotosByFrameId = {};
  final Map<String, Uint8List> selectedPhotoBytesByFrameId = {};

  DesignSchemaModel? _schema;
  bool _loading = true;
  String? _error;
  int _activePageIndex = 0;

  @override
  void initState() { super.initState(); _loadSchema(); }

  Future<void> _loadSchema() async {
    try {
      setState(() { _loading = true; _error = null; });
      final detail = widget.design.parsedDesignSchema != null ? widget.design : await _repo.getDesignDetail(widget.design.id);
      final schema = detail.parsedDesignSchema;
      if (schema == null) { setState(() => _error = 'Design schema tidak ditemukan.'); return; }
      if (schema.pages.isEmpty) { setState(() => _error = 'Template tidak memiliki halaman.'); return; }
      setState(() => _schema = schema);
    } catch (_) {
      setState(() => _error = 'Design schema tidak ditemukan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickForFrame(DesignFrameModel frame) async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() { selectedPhotosByFrameId[frame.id] = file; selectedPhotoBytesByFrameId[frame.id] = bytes; });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memilih foto.')));
    }
  }

  Map<String, dynamic> buildProjectJson() {
    final schema = _schema!;
    return {
      'product_id': widget.productId,
      'design_id': widget.design.id,
      'page_count': schema.pages.length,
      'schema_version': schema.version,
      'pages': schema.pages.map((page) => {
        'page_number': page.pageNumber,
        'frames': page.frames.map((frame) => {
          'frame_id': frame.id,
          'photo_attached': selectedPhotosByFrameId.containsKey(frame.id),
          'photo_name': selectedPhotosByFrameId[frame.id]?.name,
          'crop': {'x': 0, 'y': 0, 'scale': 1, 'rotation': 0},
        }).toList(),
      }).toList(),
    };
  }

  bool _hasEmptyRequiredFrames() {
    final schema = _schema!;
    for (final p in schema.pages) {
      for (final f in p.frames) {
        if (!selectedPhotosByFrameId.containsKey(f.id)) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final navy = const Color(0xFF0A2540);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Editor PhotoBook')), body: Center(child: Text(_error!)));
    final schema = _schema!;
    final page = schema.pages[_activePageIndex];
    return Scaffold(
      appBar: AppBar(title: Text(widget.design.title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text('Desain → Isi Foto → Preview → Checkout', style: TextStyle(color: navy, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: schema.pageWidth / math.max(schema.pageHeight, 1),
                child: LayoutBuilder(builder: (context, c) {
                  final scaleX = c.maxWidth / math.max(schema.pageWidth, 1);
                  final scaleY = c.maxHeight / math.max(schema.pageHeight, 1);
                  return Container(
                    decoration: BoxDecoration(color: _hex(page.backgroundColor), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)], border: Border.all(color: Colors.black12)),
                    child: Stack(children: page.frames.map((f) => Positioned(left: f.x * scaleX, top: f.y * scaleY, width: f.width * scaleX, height: f.height * scaleY, child: PhotoFrameWidget(frame: f, bytes: selectedPhotoBytesByFrameId[f.id], onTap: () => _pickForFrame(f)))).toList()),
                  );
                }),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            OutlinedButton(onPressed: _activePageIndex > 0 ? ()=>setState(()=>_activePageIndex--) : null, child: const Text('Sebelumnya')),
            Text('Halaman ${_activePageIndex + 1} / ${schema.pages.length}'),
            OutlinedButton(onPressed: _activePageIndex < schema.pages.length - 1 ? ()=>setState(()=>_activePageIndex++) : null, child: const Text('Berikutnya')),
          ]),
          SizedBox(height: 64, child: ListView.separated(scrollDirection: Axis.horizontal, itemBuilder: (_, i) { final p=schema.pages[i]; final active=i==_activePageIndex; final empty=p.frames.any((f)=>!selectedPhotosByFrameId.containsKey(f.id)); return InkWell(onTap: ()=>setState(()=>_activePageIndex=i), child: Container(width: 90,padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: active?Colors.blue:Colors.grey.shade400, width: active?2:1), borderRadius: BorderRadius.circular(8)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[Text('Page ${i+1}', style: const TextStyle(fontSize: 12)), if (empty) const Icon(Icons.error, size: 12, color: Colors.orange)]))); }, separatorBuilder: (_, __)=>const SizedBox(width: 8), itemCount: schema.pages.length)),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: (){final json=buildProjectJson(); showDialog(context: context, builder: (_)=>AlertDialog(title: const Text('Preview Project JSON'), content: SingleChildScrollView(child: Text(json.toString())), actions:[TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Tutup'))]));}, child: const Text('Preview'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: () { if (_hasEmptyRequiredFrames()) { showDialog(context: context, builder: (_)=>AlertDialog(title: const Text('Belum lengkap'), content: const Text('Masih ada bingkai foto yang belum diisi.'), actions:[TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))])); return; } ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Siap lanjut checkout.'))); }, child: const Text('Lanjut Checkout'))),
          ])
        ]),
      ),
    );
  }

  Color _hex(String hex) {
    final normalized = hex.replaceAll('#', '');
    if (normalized.length != 6) return Colors.white;
    return Color(int.parse('FF$normalized', radix: 16));
  }
}

class PhotoFrameWidget extends StatelessWidget {
  final DesignFrameModel frame;
  final Uint8List? bytes;
  final VoidCallback onTap;

  const PhotoFrameWidget({super.key, required this.frame, required this.bytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(frame.borderRadius);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: radius,
            border: Border.all(color: Colors.blueGrey.shade300, style: BorderStyle.solid),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes != null
              ? Image.memory(bytes!, fit: BoxFit.cover)
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_photo_alternate_outlined, color: Colors.blueGrey), Text(frame.placeholder, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)]),
        ),
      ),
    );
  }
}
