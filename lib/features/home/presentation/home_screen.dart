import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/providers/product_provider.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  @override void initState(){ super.initState(); WidgetsBinding.instance.addPostFrameCallback((_)=>context.read<ProductProvider>().fetchProducts()); }
  @override Widget build(BuildContext context) {
    final auth=context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFC),
      appBar: PhotobookAppBar(title: 'PhotoBook', actions:[IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none_rounded))]),
      body: Consumer<ProductProvider>(builder: (_,p,__){
        if(p.status==ViewStatus.loading) return const LoadingState();
        if(p.status==ViewStatus.error) return ErrorState(message:p.error??'Gagal memuat produk', onRetry:p.fetchProducts);
        return ListView(padding: const EdgeInsets.all(16), children:[
          Text('Halo, ${auth.user?.name ?? 'Customer'}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const Text('PhotoBook', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(child:Padding(padding:const EdgeInsets.all(16), child:Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Abadikan Momen Indahmu', style:TextStyle(fontWeight:FontWeight.w700,fontSize:18)), SizedBox(height:10)])), Expanded(child:PrimaryButton(label:'Buat Photobook Baru', onPressed: ()=>Navigator.pushNamed(context, AppRoutes.products), icon: Icons.add_photo_alternate_outlined))]))),
          const SizedBox(height: 16),
          const SectionHeader(title:'Kategori'),
          const SizedBox(height: 10),
          SizedBox(height:44, child:ListView(scrollDirection: Axis.horizontal, children:['Photobook Hardcover','Photobook Softcover','Cetak Foto', ...p.products.map((e)=>e.category).toSet()].map((e)=>Padding(padding:const EdgeInsets.only(right:8),child:Chip(label:Text(e)))).toList())),
          const SizedBox(height: 16),
          const SectionHeader(title:'Produk Pilihan', actionText:'Lihat semua'),
          const SizedBox(height: 8),
          ...p.products.take(3).map((product)=>ProductCard(title: product.name, subtitle: '${product.category} • ${product.size}', price: product.basePrice, imageUrl: product.imageUrl, onTap: ()=>Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product.id))),
        ]);
      }),
    );
  }
}
