import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

class OrdersScreen extends StatelessWidget { const OrdersScreen({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [SectionHeader(title: 'Pesanan Saya'), SizedBox(height: 8), OrderCard(orderNo: '#PB-23001', status: 'Diproses', color: AppColors.warning), OrderCard(orderNo: '#PB-23002', status: 'Selesai', color: AppColors.success), SizedBox(height: 12), Text('TODO: Integrasi order list API + status realtime')]); }
