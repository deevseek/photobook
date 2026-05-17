import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
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

class PriceText extends StatelessWidget {
  final int price;
  const PriceText({super.key, required this.price});
  @override
  Widget build(BuildContext context) => Text('Rp $price', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy));
}

class NetworkImageFallback extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkImageFallback({super.key, this.imageUrl, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    if (!hasImage) return _fallback();
    return Image.network(imageUrl!, width: width, height: height, fit: fit, errorBuilder: (_, __, ___) => _fallback());
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.softGray,
        child: const Icon(Icons.image_outlined, size: 36, color: Colors.grey),
      );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.title, required this.subtitle, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_rounded, size: 72),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              AppButton(label: actionLabel!, onPressed: onAction, icon: Icons.refresh_rounded),
            ],
          ]),
        ),
      );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              AppButton(label: 'Coba Lagi', onPressed: onRetry, icon: Icons.refresh_rounded),
            ],
          ],
        ),
      ),
    );
  }
}
