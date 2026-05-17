import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.photo_library_rounded, size: 120),
          const SizedBox(height: 16),
          const Text('Buat PhotoBook premium langsung dari ponsel.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          AppButton(label: 'Mulai', onPressed: ()=>Navigator.pushReplacementNamed(context, AppRoutes.login)),
        ]),
      ),
    );
  }
}
