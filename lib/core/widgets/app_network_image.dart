import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/url_normalizer.dart';

class AppNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = normalizeFileUrl(url);

    if (imageUrl == null) {
      return _fallback();
    }

    if (kDebugMode) {
      debugPrint('LOAD IMAGE URL: $imageUrl');
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        headers: const {
          'Accept': 'image/png,image/jpeg,image/webp,image/*,*/*',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: width,
            height: height,
            color: AppColors.softGray,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('IMAGE LOAD ERROR: $imageUrl');
          debugPrint('ERROR: $error');
          return _fallback();
        },
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      ),
    );
  }
}
