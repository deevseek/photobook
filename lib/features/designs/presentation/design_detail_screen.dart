import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class DesignDetailScreen extends StatefulWidget {
  final int designId;
  final int productId;
  const DesignDetailScreen({super.key, required this.designId, required this.productId});

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  final _repo = PhotobookRepository();
  late Future<PhotobookDesignModel> _future;

  String _displayText(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return value;
  }

  @override
  void initState() {
    super.initState();
    _future = _repo.getDesignDetail(widget.designId);
  }

  void _retry() => setState(() => _future = _repo.getDesignDetail(widget.designId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Desain')),
      body: FutureBuilder<PhotobookDesignModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final d = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            SizedBox(
              height: 220,
              child: AppNetworkImage(
                url: d.thumbnailUrl,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Text(d.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text('Kontributor: ${d.contributorName}'),
            Text(
              '${_displayText(d.category)} • ${_displayText(d.theme)} • ${_displayText(d.size)}',
            ),
            Text('Total halaman: ${d.totalPages}'),
            Text('Page size: ${_displayText(d.pageSize)}'),
            Text('Harga desain: Rp ${d.designPrice}'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              Chip(label: Text(d.idmlAvailable ? 'IDML tersedia' : 'IDML tidak tersedia')),
              Chip(label: Text(d.designSchemaAvailable ? 'Schema tersedia' : 'Schema belum tersedia')),
            ]),
            const SizedBox(height: 8),
            Text(
              _displayText(
                d.description,
                fallback: 'Tidak ada deskripsi desain.',
              ),
            ),
            if (!d.designSchemaAvailable) ...[
              const SizedBox(height: 10),
              const Text('Template belum memiliki schema editor. Desain ini belum bisa digunakan untuk editor PhotoBook.', style: TextStyle(color: Colors.orange)),
            ],
            const SizedBox(height: 14),
            AppButton(
              label: 'Gunakan Desain Ini',
              onPressed: d.designSchemaAvailable ? () => Navigator.pushNamed(context, AppRoutes.photobookEditor, arguments: {'productId': widget.productId, 'design': d}) : null,
            ),
          ]);
        },
      ),
    );
  }
}
