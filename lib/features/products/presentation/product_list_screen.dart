import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Produk PhotoBook')), body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(16), mainAxisSpacing: 12, crossAxisSpacing: 12, children: [ProductCard(title: 'A5', subtitle: 'Softcover', price: 99000, onTap: ()=>Navigator.pushNamed(context, AppRoutes.productDetail)), ProductCard(title: 'A4', subtitle: 'Hardcover', price: 189000, onTap: ()=>Navigator.pushNamed(context, AppRoutes.productDetail))]));
}
