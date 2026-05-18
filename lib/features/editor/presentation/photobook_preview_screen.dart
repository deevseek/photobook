import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import 'photobook_editor_screen.dart';

class PhotobookPreviewScreen extends StatelessWidget {
  const PhotobookPreviewScreen({
    super.key,
    required this.design,
    required this.schema,
    required this.photoStateByFrameId,
  });

  final PhotobookDesignModel design;
  final DesignSchemaModel schema;
  final Map<String, FramePhotoState> photoStateByFrameId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview - ${design.title}'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: schema.pages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final page = schema.pages[index];
          final missingFrames = page.frames
              .where((frame) => photoStateByFrameId[frame.id]?.imageBytes == null)
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
                        'Foto belum lengkap',
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
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewPageCanvas extends StatelessWidget {
  const _PreviewPageCanvas({
    required this.schema,
    required this.page,
    required this.photoStateByFrameId,
  });

  final DesignSchemaModel schema;
  final DesignPageModel page;
  final Map<String, FramePhotoState> photoStateByFrameId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final schemaWidth = schema.pageWidth.toDouble();
        final schemaHeight = schema.pageHeight.toDouble();

        final availableWidth = constraints.maxWidth;
        final scale = availableWidth / schemaWidth;

        final displayWidth = schemaWidth * scale;
        final displayHeight = schemaHeight * scale;

        final scaleX = displayWidth / schemaWidth;
        final scaleY = displayHeight / schemaHeight;

        return Center(
          child: Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: page.backgroundUrl != null && page.backgroundUrl!.isNotEmpty
                      ? Image.network(
                          page.backgroundUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.white),
                        )
                      : Container(color: Colors.white),
                ),
                ...page.frames.map((frame) {
                  final state = photoStateByFrameId[frame.id];

                  if (state == null || state.imageBytes == null) {
                    return const SizedBox.shrink();
                  }

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
                          Transform.translate(
                            offset: Offset(
                              state.offset.dx * scaleX,
                              state.offset.dy * scaleY,
                            ),
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
                          ),
                          if (kDebugMode)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey.shade200, width: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
