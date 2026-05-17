import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../photobook/data/photobook_repository.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _repo = PhotobookRepository();
  late Future<dynamic> _future;

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
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final items = snapshot.data as List;
          if (items.isEmpty) return const EmptyState(title: 'Produk kosong', subtitle: 'Belum ada produk PhotoBook tersedia.');
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return ProductCard(
                title: p.name,
                subtitle: p.coverType ?? '-',
                price: p.price,
                imageUrl: p.imageUrl,
                onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p.id),
              );
            },
          );
        },
      ),
    );
  }
}
