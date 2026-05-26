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
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _future = _repo.getProductDetail(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PhotobookAppBar(title: 'Detail Produk'),
      body: FutureBuilder<PhotobookProductModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _future = _repo.getProductDetail(widget.productId);
                });
              },
            );
          }

          final p = snapshot.data!;
          final images = [p.imageUrl]
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        itemCount: images.isEmpty ? 1 : images.length,
                        onPageChanged: (value) {
                          setState(() {
                            _index = value;
                          });
                        },
                        itemBuilder: (_, i) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              color: Colors.white,
                              child: images.isEmpty
                                  ? const Icon(Icons.photo, size: 40)
                                  : Image.network(
                                      images[i],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.isEmpty ? 1 : images.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _index
                                ? const Color(0xFF168CA0)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('${p.coverType} • ${p.paperType} • ${p.size}'),
                    Text(
                      'Halaman ${p.defaultPages} | Estimasi ${p.productionEstimateDays} hari',
                    ),
                    const SizedBox(height: 10),
                    PriceText(price: p.basePrice),
                    const SizedBox(height: 12),
                    Text(p.description),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.all(16),
                child: PrimaryButton(
                  label: 'Pilih Produk',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.designs,
                    arguments: p.id,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
