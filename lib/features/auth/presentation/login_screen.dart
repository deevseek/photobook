import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Masuk ke akun Anda', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 16), AppButton(label: 'Masuk', icon: Icons.login, onPressed: ()=>Navigator.pushReplacementNamed(context, AppRoutes.home)), const SizedBox(height: 8), const Text('TODO: Integrasi login API/auth provider')]))));
  }
}
