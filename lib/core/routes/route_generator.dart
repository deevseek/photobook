import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/checkout/presentation/checkout_placeholder_screen.dart';
import '../../features/designs/presentation/design_detail_screen.dart';
import '../../features/designs/presentation/design_list_screen.dart';
import '../../features/editor/presentation/editor_placeholder_screen.dart';
import '../../features/home/presentation/main_shell_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
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
        final designId = settings.arguments as int?;
        if (designId == null) return _fallbackRoute();
        return MaterialPageRoute(builder: (_) => DesignDetailScreen(designId: designId));
      case AppRoutes.editorPlaceholder:
        final designName = settings.arguments as String? ?? '-';
        return MaterialPageRoute(builder: (_) => EditorPlaceholderScreen(designName: designName));
      case AppRoutes.checkoutPlaceholder:
        return MaterialPageRoute(builder: (_) => const CheckoutPlaceholderScreen());
      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return _fallbackRoute();
    }
  }

  static MaterialPageRoute<dynamic> _fallbackRoute() {
    return MaterialPageRoute(builder: (_) => const SplashScreen());
  }
}
