import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_order_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class OrdersScreen extends StatefulWidget { const OrdersScreen({super.key}); @override State<OrdersScreen> createState()=>_OrdersScreenState(); }
class _OrdersScreenState extends State<OrdersScreen>{
  final _repo=PhotobookRepository(); final _storage=TokenStorage(); late Future<List<PhotobookOrderModel>> _future;
  @override void initState(){super.initState(); _future=_load();}
  Future<List<PhotobookOrderModel>> _load() async { if(!await _storage.hasToken()) return []; return _repo.getOrders(); }
  @override Widget build(BuildContext c)=>FutureBuilder<List<PhotobookOrderModel>>(future:_future,builder:(c,s){ if(s.connectionState!=ConnectionState.done)return const LoadingState(); if(s.hasError)return ErrorState(message:s.error.toString(),onRetry:()=>setState(()=>_future=_load())); if((s.data??[]).isEmpty) return FutureBuilder<bool>(future:_storage.hasToken(),builder:(c,t)=>Center(child:Text(t.data==true?'Belum ada pesanan.':'Silakan login untuk melihat pesanan.'))); return ListView(padding:const EdgeInsets.all(16),children:[const SectionHeader(title:'Pesanan Saya'),const SizedBox(height:8),...s.data!.map((o)=>Card(child:ListTile(title:Text(o.orderNumber),subtitle:Text('${o.productName}\n${o.paymentStatus} • ${o.productionStatus} • ${o.shippingStatus}\n${o.createdAt??'-'}'),isThreeLine:true,trailing:Text('Rp ${o.totalAmount}'),onTap:()=>Navigator.pushNamed(c,AppRoutes.orderDetail,arguments:o.orderNumber))))]);});
}
