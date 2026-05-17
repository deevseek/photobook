import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Halo, Customer 👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      const SectionHeader(title: 'Produk PhotoBook'),
      const SizedBox(height: 8),
      ProductCard(title: 'A4 Landscape', subtitle: 'Hardcover 20 halaman', price: 189000, onTap: ()=>Navigator.pushNamed(context, AppRoutes.productDetail)),
      const SizedBox(height: 16),
      SectionHeader(title: 'Desain Populer', actionText: 'Lihat semua', onTap: ()=>Navigator.pushNamed(context, AppRoutes.designs)),
      DesignCard(name: 'Minimal White', onTap: ()=>Navigator.pushNamed(context, AppRoutes.designDetail)),
      const SizedBox(height: 8),
      const Text('TODO: Integrasi API produk/desain beranda')
    ]);
  }
}
