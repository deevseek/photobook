import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> {
  @override void initState() { super.initState(); Timer(const Duration(seconds: 2), ()=>Navigator.pushReplacementNamed(context, AppRoutes.onboarding)); }
  @override Widget build(BuildContext context) => const Scaffold(body: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.navy, AppColors.electricBlue])), child: Center(child: Text('PhotoBook', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)))));
}
