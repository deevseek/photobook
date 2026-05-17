import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.bootstrap();
      if (!mounted) return;
      if (AppConfig.devBypassLogin) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }
      Navigator.pushReplacementNamed(context, auth.user != null ? AppRoutes.home : AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.navy, AppColors.electricBlue])),
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    ),
  );
}
