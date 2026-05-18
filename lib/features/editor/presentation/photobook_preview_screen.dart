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
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: schema.pages.length,
        itemBuilder: (context, index) {
          final page = schema.pages[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halaman ${page.pageNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Background: ${page.backgroundUrl ?? '-'}'),
                  const SizedBox(height: 8),
                  ...page.frames.map((frame) {
                    final state = photoStateByFrameId[frame.id];
                    final hasImage = state?.imageBytes != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              frame.placeholder,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (hasImage)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
