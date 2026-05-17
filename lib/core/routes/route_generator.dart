import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/checkout/presentation/checkout_placeholder_screen.dart';
import '../../features/designs/presentation/design_detail_screen.dart';
import '../../features/designs/presentation/design_list_screen.dart';
import '../../features/editor/presentation/photobook_editor_screen.dart';
import '../../data/models/photobook_design_model.dart';
import '../../features/home/presentation/main_shell_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/tracking_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const MainShellScreen());
      case AppRoutes.products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case AppRoutes.productDetail:
        final productId = settings.arguments as int?;
        if (productId == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId));
      case AppRoutes.designs:
        final productId = settings.arguments as int?;
        if (productId == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => DesignListScreen(productId: productId));
      case AppRoutes.designDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final designId = args?['designId'] as int?;
        final productId = args?['productId'] as int?;
        if (designId == null || productId == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => DesignDetailScreen(designId: designId, productId: productId));
      case AppRoutes.photobookEditor:
        final args = settings.arguments as Map<String, dynamic>?;
        final design = args?['design'] as PhotobookDesignModel?;
        final productId = args?['productId'] as int? ?? 0;
        if (design == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => PhotobookEditorScreen(productId: productId, design: design));
      case AppRoutes.checkoutPlaceholder:
        return MaterialPageRoute(builder: (_) => const CheckoutPlaceholderScreen());
      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.orderDetail:
        final n = settings.arguments as String?;
        if (n == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => OrderDetailScreen(orderNumber: n));
      case AppRoutes.orderTracking:
        final n = settings.arguments as String?;
        if (n == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => TrackingScreen(orderNumber: n));
      default:
        return _fallbackRoute();
    }
  }

  static MaterialPageRoute<dynamic> _fallbackRoute() {
    return MaterialPageRoute(builder: (_) => const SplashScreen());
  }
}
