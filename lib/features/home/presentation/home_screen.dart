import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductProvider>().fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<ProductProvider>(builder: (_, p, __) {
      if (p.status == ViewStatus.loading) return const LoadingState();
      if (p.status == ViewStatus.error) return ErrorState(message: p.error ?? 'Gagal memuat produk.', onRetry: p.fetchProducts);
      if (p.status == ViewStatus.empty) return const EmptyState(title: 'Produk kosong', subtitle: 'Belum ada produk PhotoBook tersedia.');
      return ListView(padding: const EdgeInsets.all(16), children: [
        if (AppConfig.devBypassLogin)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
            child: const Text('Mode Testing Aktif - Login Gmail dilewati sementara', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        Text('Halo, ${auth.user?.name ?? 'Customer'} 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        if (auth.user == null) ...[
          const SizedBox(height: 8),
          AppButton(label: 'Login untuk melanjutkan', onPressed: () => Navigator.pushNamed(context, AppRoutes.login)),
        ],
        const SizedBox(height: 16),
        const SectionHeader(title: 'Produk PhotoBook'),
        const SizedBox(height: 8),
        ...p.products.take(3).map((product) => ProductCard(
              title: product.name,
              subtitle: '${product.category} • ${product.size}',
              price: product.basePrice,
              imageUrl: product.imageUrl,
              onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id),
            )),
      ]);
    });
  }
}
