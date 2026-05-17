import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../photobook/data/photobook_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _repo = PhotobookRepository();
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getProductById(widget.productId);
  }

  void _retry() => setState(() => _future = _repo.getProductById(widget.productId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final product = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: (product.imageUrl ?? '').toString().isEmpty ? Container(color: Colors.white) : Image.network(product.imageUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              PriceText(price: product.price),
              const SizedBox(height: 8),
              Text(product.description ?? '-'),
              const SizedBox(height: 12),
              AppButton(
                label: 'Pilih Desain',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.designs, arguments: product.id),
              ),
            ],
          );
        },
      ),
    );
  }
}
