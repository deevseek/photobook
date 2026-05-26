import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_network_image.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF168CA0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class PhotobookAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  const PhotobookAppBar({super.key, required this.title, this.actions, this.centerTitle = false});
  @override
  Widget build(BuildContext context) => AppBar(title: Text(title), actions: actions, centerTitle: centerTitle);
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class LoadingState extends StatelessWidget { const LoadingState({super.key}); @override Widget build(BuildContext context)=>const Center(child:CircularProgressIndicator()); }
class EmptyState extends StatelessWidget { final String title; final String subtitle; const EmptyState({super.key, required this.title, required this.subtitle}); @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.photo_album_outlined,size:48,color:Colors.grey),const SizedBox(height:12),Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:18)),const SizedBox(height:6),Text(subtitle,textAlign:TextAlign.center,style:TextStyle(color:Colors.grey.shade600))]))); }
class ErrorState extends StatelessWidget { final String message; final VoidCallback? onRetry; const ErrorState({super.key, required this.message, this.onRetry}); @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline,size:48,color:Colors.redAccent),const SizedBox(height:12),Text(message,textAlign:TextAlign.center),const SizedBox(height:10),if(onRetry!=null) OutlinedButton(onPressed:onRetry, child:const Text('Coba Lagi'))]))); }

class ProductCard extends StatelessWidget {
  final String title; final String subtitle; final num price; final String? imageUrl; final VoidCallback? onTap;
  const ProductCard({super.key, required this.title, required this.subtitle, required this.price, this.imageUrl, this.onTap});
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 170, width: double.infinity, child: _Photo(url: imageUrl))),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            PriceText(price: price),
          ]),
        ),
      ));
}

class DesignCard extends StatelessWidget { final String name; final String? thumbnailUrl; final VoidCallback? onTap; const DesignCard({super.key, required this.name, this.thumbnailUrl, this.onTap}); @override Widget build(BuildContext context)=>ProductCard(title:name, subtitle:'Template desain', price:0, imageUrl:thumbnailUrl, onTap:onTap); }
class CheckoutSectionCard extends StatelessWidget { final String title; final Widget child; const CheckoutSectionCard({super.key, required this.title, required this.child}); @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(16), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:16)), const SizedBox(height:12), child]))); }
class PriceBreakdownCard extends StatelessWidget { final List<Widget> rows; const PriceBreakdownCard({super.key, required this.rows}); @override Widget build(BuildContext context)=>CheckoutSectionCard(title:'Rincian Pembayaran', child:Column(children:rows)); }

class PriceText extends StatelessWidget { final num price; final TextStyle? style; const PriceText({super.key, required this.price, this.style}); @override Widget build(BuildContext context)=>Text('Mulai Rp ${price.toStringAsFixed(0)}', style: style ?? const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)); }
class AppButton extends PrimaryButton { const AppButton({super.key, required super.label, required super.onPressed, super.icon}); }
class SectionHeader extends StatelessWidget { final String title; final String? actionText; final VoidCallback? onTap; const SectionHeader({super.key, required this.title, this.actionText, this.onTap}); @override Widget build(BuildContext context)=>Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:18)),if(actionText!=null) TextButton(onPressed:onTap, child:Text(actionText!))]); }

class _Photo extends StatelessWidget { final String? url; const _Photo({this.url}); @override Widget build(BuildContext context)=> (url==null||url!.isEmpty)? Container(color:AppColors.lightGrey, child:const Icon(Icons.photo,size:36,color:Colors.grey)):AppNetworkImage(url:url, fit:BoxFit.cover); }
