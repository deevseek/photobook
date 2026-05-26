import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundAsset =
      'assets/images/splash_kinesti_photobook.png';

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    final auth = context.read<AuthProvider>();

    await Future.wait([
      auth.bootstrap(),
      Future<void>.delayed(const Duration(milliseconds: 2500)),
    ]);

    if (!mounted) return;

    if (AppConfig.devBypassLogin) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      auth.user != null ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF120D08),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF2B1B10),
                        Color(0xFF120D08),
                        Color(0xFF050403),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 52),
                      Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFE8C878),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.18),
                        ),
                        child: const Text(
                          'KP',
                          style: TextStyle(
                            color: Color(0xFFF4D58D),
                            fontSize: 58,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -3,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kinesti Photobook',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFFF7E6),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 170,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0x33F4D58D), Color(0x00F4D58D)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 68,
                          color: Color(0xFFE8C878),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ubah Kenangan\nMenjadi Kisah Indah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFFF7E6),
                          fontSize: 34,
                          height: 1.18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Abadikan momen terbaikmu\ndalam photobook yang elegan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFEADCC3),
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 46),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.white.withOpacity(0.16),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF4D58D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
