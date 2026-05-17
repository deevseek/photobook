import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/view_state.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().user != null) {
        context.read<OrderProvider>().fetchOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user == null) return const Center(child: Text('Silakan login untuk melihat pesanan Anda.'));
    return Consumer<OrderProvider>(builder: (_, o, __) {
      if (o.status == ViewStatus.loading) return const LoadingState();
      if (o.status == ViewStatus.error) return ErrorState(message: o.error ?? 'Gagal memuat pesanan.', onRetry: o.fetchOrders);
      if (o.status == ViewStatus.empty) return const EmptyState(title: 'Belum ada pesanan', subtitle: 'Pesanan Anda akan tampil di sini.');
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: o.orders.length,
        itemBuilder: (_, i) {
          final x = o.orders[i];
          return Card(child: ListTile(title: Text(x.orderNumber), subtitle: Text('${x.productName}\n${x.designTitle}\n${x.paymentStatus} • ${x.productionStatus} • ${x.shippingStatus}\n${x.createdAt ?? '-'}')));
        },
      );
    });
  }
}
