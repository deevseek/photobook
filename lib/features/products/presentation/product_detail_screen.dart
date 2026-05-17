import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_product_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _repo = PhotobookRepository();
  late Future<PhotobookProductModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getProductDetail(widget.productId);
  }

  void _retry() => setState(() => _future = _repo.getProductDetail(widget.productId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: FutureBuilder<PhotobookProductModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final p = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 220, child: NetworkImageFallback(imageUrl: p.imageUrl))),
            const SizedBox(height: 12),
            Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text('${p.category} • ${p.size}'),
            PriceText(price: p.basePrice),
            Text('Default halaman: ${p.defaultPages}'),
            Text('Harga halaman tambahan: Rp ${p.additionalPagePrice}'),
            Text('Jenis cover: ${p.coverType}'),
            Text('Jenis kertas: ${p.paperType}'),
            Text('Estimasi produksi: ${p.productionEstimateDays} hari'),
            Text('Jumlah desain aktif: ${p.activeDesignsCount}'),
            const SizedBox(height: 12),
            Text(p.description),
            const SizedBox(height: 14),
            AppButton(label: 'Lihat Desain', onPressed: () => Navigator.pushNamed(context, AppRoutes.designs, arguments: p.id)),
          ]);
        },
      ),
    );
  }
}
