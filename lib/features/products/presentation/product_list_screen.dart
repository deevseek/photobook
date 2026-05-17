import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_product_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repo = PhotobookRepository();
  late Future<List<PhotobookProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getProducts();
  }

  void _retry() => setState(() => _future = _repo.getProducts());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk PhotoBook')),
      body: FutureBuilder<List<PhotobookProductModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const EmptyState(title: 'Produk kosong', subtitle: 'Belum ada produk PhotoBook tersedia.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = items[i];
              debugPrint('PRODUCT IMAGE URL: ${p.imageUrl}');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 160, width: double.infinity, child: NetworkImageFallback(imageUrl: p.imageUrl))),
                    const SizedBox(height: 8),
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${p.category} • ${p.size}'),
                    PriceText(price: p.basePrice),
                    Text('Default halaman: ${p.defaultPages}'),
                    Text('Tambah halaman: Rp ${p.additionalPagePrice}'),
                    Text('Estimasi produksi: ${p.productionEstimateDays} hari'),
                    Text('Desain aktif: ${p.activeDesignsCount}'),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Pilih Produk',
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p.id),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
