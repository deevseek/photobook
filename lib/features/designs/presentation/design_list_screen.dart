import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class DesignListScreen extends StatefulWidget {
  final int productId;
  const DesignListScreen({super.key, required this.productId});

  @override
  State<DesignListScreen> createState() => _DesignListScreenState();
}

class _DesignListScreenState extends State<DesignListScreen> {
  final _repo = PhotobookRepository();
  final _searchCtrl = TextEditingController();
  late Future<List<PhotobookDesignModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getDesignsByProduct(widget.productId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _retry() => setState(() => _future = _repo.getDesignsByProduct(widget.productId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Desain')),
      body: FutureBuilder<List<PhotobookDesignModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final allItems = snapshot.data ?? [];
          if (allItems.isEmpty) return const EmptyState(title: 'Desain kosong', subtitle: 'Belum ada desain untuk produk ini.');
          return StatefulBuilder(builder: (context, setInnerState) {
            final q = _searchCtrl.text.toLowerCase();
            final items = allItems.where((d) => d.title.toLowerCase().contains(q) || d.theme.toLowerCase().contains(q) || d.category.toLowerCase().contains(q)).toList();
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari judul, tema, kategori'),
                  onChanged: (_) => setInnerState(() {}),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(title: 'Tidak ditemukan', subtitle: 'Coba kata kunci lain.')
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final d = items[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: NetworkImageFallback(imageUrl: d.thumbnailUrl, width: double.infinity))),
                                const SizedBox(height: 8),
                                Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(d.contributorName, maxLines: 1),
                                Text('${d.category} • ${d.theme}'),
                                Text('${d.size} • ${d.totalPages} halaman'),
                                Wrap(spacing: 6, children: [const Chip(label: Text('Template Siap')), if (d.idmlAvailable) const Chip(label: Text('IDML tersedia'))]),
                                AppButton(label: 'Pilih Desain', onPressed: () => Navigator.pushNamed(context, AppRoutes.designDetail, arguments: d.id)),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]);
          });
        },
      ),
    );
  }
}
