import 'package:flutter/material.dart';

import '../../editor/presentation/photobook_editor_screen.dart';

class PhotobookCheckoutScreen extends StatelessWidget {
  const PhotobookCheckoutScreen({
    super.key,
    required this.design,
    required this.photoStateByFrameId,
    this.product,
  });

  final dynamic design;
  final dynamic product;
  final Map<String, FramePhotoState> photoStateByFrameId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout PhotoBook'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Desain: ${design.title}\nFoto terisi: ${photoStateByFrameId.length}\nProduct: ${product ?? '-'}',
        ),
      ),
    );
  }
}
