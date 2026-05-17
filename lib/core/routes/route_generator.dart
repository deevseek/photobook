import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/checkout/presentation/checkout_placeholder_screen.dart';
import '../../features/designs/presentation/design_detail_screen.dart';
import '../../features/designs/presentation/design_list_screen.dart';
import '../../features/editor/presentation/editor_placeholder_screen.dart';
import '../../features/home/presentation/main_shell_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/products/presentation/product_detail_screen.dart';
import '../../features/products/presentation/product_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash: return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.onboarding: return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.login: return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.home: return MaterialPageRoute(builder: (_) => const MainShellScreen());
      case AppRoutes.products: return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case AppRoutes.productDetail: return MaterialPageRoute(builder: (_) => const ProductDetailScreen());
      case AppRoutes.designs: return MaterialPageRoute(builder: (_) => const DesignListScreen());
      case AppRoutes.designDetail: return MaterialPageRoute(builder: (_) => const DesignDetailScreen());
      case AppRoutes.editorPlaceholder: return MaterialPageRoute(builder: (_) => const EditorPlaceholderScreen());
      case AppRoutes.checkoutPlaceholder: return MaterialPageRoute(builder: (_) => const CheckoutPlaceholderScreen());
      case AppRoutes.orders: return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case AppRoutes.profile: return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default: return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
