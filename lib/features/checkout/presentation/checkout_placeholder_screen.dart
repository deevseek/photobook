import 'package:flutter/material.dart';

import '../../../core/widgets/common_widgets.dart';
import '../../../data/repositories/photobook_repository.dart';

class CheckoutPlaceholderScreen extends StatefulWidget { const CheckoutPlaceholderScreen({super.key}); @override State<CheckoutPlaceholderScreen> createState()=>_CheckoutPlaceholderScreenState(); }
class _CheckoutPlaceholderScreenState extends State<CheckoutPlaceholderScreen>{final _repo=PhotobookRepository(); String _result='Belum dihitung'; bool _loading=false;
  Future<void> _calculate() async {setState(()=>_loading=true); try{final r=await _repo.calculatePrice(productId: 1,pageCount:20,printQuantity:1); setState(()=>_result='Subtotal: Rp ${r.subtotalPrint} | Total: Rp ${r.totalBeforeShipping}');}catch(e){setState(()=>_result=e.toString());} finally{setState(()=>_loading=false);} }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Checkout Placeholder')),body:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Contoh integrasi calculate-price (sementara productId statis untuk demo).'),const SizedBox(height:12),AppButton(label:'Hitung Harga',onPressed:_loading?null:_calculate),const SizedBox(height:12),Text(_result)])));
}
