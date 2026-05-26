import 'package:flutter/material.dart';

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import 'photobook_editor_screen.dart';

class PhotobookPreviewScreen extends StatefulWidget {
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

  @override
  State<PhotobookPreviewScreen> createState() => _PhotobookPreviewScreenState();
}

class _PhotobookPreviewScreenState extends State<PhotobookPreviewScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    final pages = widget.schema.pages;
    final spreads = _spreadItems();
    if (selected >= spreads.length) selected = 0;
    final spread = spreads[selected];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(title: const Text('Pratinjau Desain')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 3,
                      child: AspectRatio(
                        aspectRatio: orientation == Orientation.landscape ? 2.1 : 1.5,
                        child: _buildBookSpread(spread.leftIndex, spread.rightIndex),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: spreads.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selected = i;
                      });
                    },
                    child: Container(
                      width: 96,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: i == selected
                            ? const Color(0xFF168CA0)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          spreads[i].label,
                          style: TextStyle(
                            color: i == selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          widget.onBackToEdit ?? () => Navigator.pop(context),
                      child: const Text('Pratinjau'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onContinueCheckout,
                      child: const Text('Lanjut Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSpread(int? leftIndex, int? rightIndex) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: leftIndex == null ? _emptyPage() : _buildPage(widget.schema.pages[leftIndex])),
        Container(width: 12, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0x22000000), Color(0x08000000), Color(0x22000000)]))),
        Expanded(child: rightIndex == null ? _emptyPage() : _buildPage(widget.schema.pages[rightIndex])),
      ]),
    );
  }

  Widget _emptyPage() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE3E7ED))));

  Widget _buildPage(DesignPageModel page) {
    final bg = (page.previewUrl?.isNotEmpty == true) ? page.previewUrl : (page.backgroundUrl?.isNotEmpty == true) ? page.backgroundUrl : (page.editorBackgroundUrl?.isNotEmpty == true) ? page.editorBackgroundUrl : page.cleanBackgroundUrl;
    final width = widget.schema.pageWidth;
    final height = widget.schema.pageHeight;
    return AspectRatio(
      aspectRatio: width / height,
      child: LayoutBuilder(builder: (context, c) {
        final scaleX = c.maxWidth / width;
        final scaleY = c.maxHeight / height;
        return Stack(children: [
          Positioned.fill(
            child: bg == null ? const Center(child: Icon(Icons.image_not_supported)) : Image.network(bg, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
          ),
          ..._editedTextOverlays(page, scaleX, scaleY),
          ..._photoOverlays(page, scaleX, scaleY),
        ]);
      }),
    );
  }

  List<Widget> _editedTextOverlays(DesignPageModel page, double scaleX, double scaleY) {
    final out = <Widget>[];
    for (final layer in page.layers) {
      final value = widget.editedTextById[layer.id];
      if (value == null || value.trim().isEmpty) {
        continue;
      }

      out.add(
        Positioned(
          left: layer.x * scaleX,
          top: layer.y * scaleY,
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ),
      );
    }
    return out;
  }

  List<Widget> _photoOverlays(DesignPageModel page, double scaleX, double scaleY) {
    final out = <Widget>[];
    for (final layer in page.layers) {
      final frame = layer.frame;
      if (frame == null) continue;
      final photo = widget.photoStateByFrameId[frame.id];
      if (photo == null) continue;
      out.add(Positioned(left: frame.x * scaleX, top: frame.y * scaleY, width: frame.width * scaleX, height: frame.height * scaleY, child: Image.memory(photo.imageBytes, fit: BoxFit.cover)));
    }
    return out;
  }

  List<({int? leftIndex, int? rightIndex, String label})> _spreadItems() {
    final items = <({int? leftIndex, int? rightIndex, String label})>[];
    final pages = widget.schema.pages;
    if (pages.isEmpty) return items;
    items.add((leftIndex: null, rightIndex: 0, label: 'Cover'));
    for (int i = 1; i < pages.length; i += 2) {
      final right = i + 1 < pages.length ? i + 1 : null;
      final label = right == null ? 'Hal. ${pages[i].pageNumber}' : 'Hal. ${pages[i].pageNumber}-${pages[right].pageNumber}';
      items.add((leftIndex: i, rightIndex: right, label: label));
    }
    return items;
  }
}
