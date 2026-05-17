import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _repo.getDesignDetail(widget.designId);
  }

  void _retry() => setState(() => _future = _repo.getDesignDetail(widget.designId));

  String _layoutLabel(PhotobookDesignModel d) {
    if (d.designSchemaSource == 'idml_package') return 'Layout dari Package';
    if (d.designSchemaSource == 'idml') return 'Layout dari IDML';
    return 'Layout default';
  }

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
          final ready = d.schemaStatus == 'ready';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(height: 220, child: AppNetworkImage(url: d.thumbnailUrl, borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 12),
              Text(d.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text('Kontributor: ${d.contributorName}'),
              Text('Total halaman: ${d.totalPages}'),
              Text('Harga desain: Rp ${d.designPrice}'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(label: Text(d.idmlAvailable ? 'IDML tersedia' : 'IDML tidak tersedia')),
                Chip(label: Text(d.designSchemaAvailable ? 'Schema tersedia' : 'Schema belum tersedia')),
                Chip(label: Text(_layoutLabel(d))),
                Chip(label: Text(d.previewStatus == 'ready' ? 'Preview PDF ready' : 'Preview PDF belum tersedia')),
              ]),
              if (!ready && d.designSchemaAvailable)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Template belum siap. Tunggu sampai status schema ready.', style: TextStyle(color: Colors.orange)),
                ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Gunakan Desain Ini',
                onPressed: d.designSchemaAvailable
                    ? () {
                        if (!ready) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Template belum siap'),
                              content: const Text('Template belum siap. Tunggu sampai status schema ready.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, AppRoutes.photobookEditor, arguments: {'productId': widget.productId, 'design': d});
                                  },
                                  child: const Text('Buka untuk debug'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        Navigator.pushNamed(context, AppRoutes.photobookEditor, arguments: {'productId': widget.productId, 'design': d});
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
