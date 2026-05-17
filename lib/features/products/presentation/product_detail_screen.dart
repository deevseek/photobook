import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Detail Produk')), body: ListView(padding: const EdgeInsets.all(16), children: [Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))), const SizedBox(height: 12), const Text('PhotoBook A4 Hardcover', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), const PriceText(price: 189000), const SizedBox(height: 12), AppButton(label: 'Pilih Desain', onPressed: ()=>Navigator.pushNamed(context, AppRoutes.designs)), const SizedBox(height: 12), const Text('TODO: Integrasi detail produk API') ]));
}
