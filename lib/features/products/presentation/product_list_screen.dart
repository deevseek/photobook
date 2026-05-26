import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_product_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class ProductListScreen extends StatefulWidget { const ProductListScreen({super.key}); @override State<ProductListScreen> createState()=>_ProductListScreenState(); }
class _ProductListScreenState extends State<ProductListScreen>{ final _repo=PhotobookRepository(); late Future<List<PhotobookProductModel>> _future; @override void initState(){super.initState(); _future=_repo.getProducts();}
  @override Widget build(BuildContext context)=>Scaffold(appBar: const PhotobookAppBar(title:'Daftar Produk'), backgroundColor: const Color(0xFFF6FAFC), body: FutureBuilder<List<PhotobookProductModel>>(future:_future,builder:(c,s){if(s.connectionState!=ConnectionState.done)return const LoadingState(); if(s.hasError)return ErrorState(message:s.error.toString(), onRetry: ()=>setState(()=>_future=_repo.getProducts())); final items=s.data??[]; if(items.isEmpty)return const EmptyState(title:'Produk kosong', subtitle:'Belum ada produk.'); return ListView.builder(padding: const EdgeInsets.all(16), itemCount:items.length,itemBuilder:(_,i){final p=items[i]; return ProductCard(title:p.name, subtitle:'${p.description} • ${p.category}', price:p.basePrice, imageUrl:p.imageUrl, onTap: ()=>Navigator.pushNamed(context, AppRoutes.productDetail, arguments:p.id));});})); }
