import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  const AppButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.electricBlue,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;
  const SectionHeader({super.key, required this.title, this.actionText, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const Spacer(),
      if (actionText != null) TextButton(onPressed: onTap, child: Text(actionText!)),
    ]);
  }
}

class PriceText extends StatelessWidget {
  final int price;
  const PriceText({super.key, required this.price});
  @override
  Widget build(BuildContext context) => Text('Rp ${price.toString()}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy));
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox_outlined, size: 72), Text(title), Text(subtitle)]));
}
class LoadingState extends StatelessWidget { const LoadingState({super.key}); @override Widget build(BuildContext context) => const Center(child: CircularProgressIndicator()); }
class ErrorState extends StatelessWidget { final String message; const ErrorState({super.key, required this.message}); @override Widget build(BuildContext context) => Center(child: Text(message)); }

class ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int price;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.title, required this.subtitle, required this.price, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(height: 110, decoration: BoxDecoration(color: AppColors.softGray, borderRadius: BorderRadius.circular(16))), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle), PriceText(price: price)]))));
}

class DesignCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const DesignCard({super.key, required this.name, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.softGray, borderRadius: BorderRadius.circular(12))), title: Text(name), subtitle: const Text('Template siap pakai')));
}

class OrderCard extends StatelessWidget {
  final String orderNo;
  final String status;
  final Color color;
  const OrderCard({super.key, required this.orderNo, required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(title: Text(orderNo), subtitle: const Text('PhotoBook A4 Hardcover'), trailing: StatusBadge(text: status, color: color)));
}
