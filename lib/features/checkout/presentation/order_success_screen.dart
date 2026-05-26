import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final String productName;
  final String designName;
  final String pages;
  final String subtotal;
  const OrderSuccessScreen({super.key, required this.orderId, required this.productName, required this.designName, required this.pages, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Berhasil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 24),
          const CircleAvatar(radius: 34, backgroundColor: Color(0xFFE7F8EE), child: Icon(Icons.check_rounded, size: 38, color: Colors.green)),
          const SizedBox(height: 16),
          const Text('Pesanan Berhasil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Order ID: $orderId'),
          const SizedBox(height: 16),
          Card(child: ListTile(title: Text(productName), subtitle: Text('$designName • $pages halaman'), trailing: Text(subtotal))),
          const Spacer(),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: ()=>Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r)=>false), child: const Text('Kembali ke Beranda')))
        ]),
      ),
    );
  }
}
