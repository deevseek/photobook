import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (_, auth, __) => Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Masuk ke akun Anda', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AppButton(
                label: auth.loading ? 'Memproses...' : 'Masuk dengan Gmail',
                icon: Icons.login,
                onPressed: auth.loading ? null : () async {
                  if (kIsWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Google belum dikonfigurasi untuk platform ini.')));
                    return;
                  }
                  final ok = await context.read<AuthProvider>().signInWithGoogle();
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Login gagal.')));
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
