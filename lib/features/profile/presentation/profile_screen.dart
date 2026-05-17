import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Center(child: Text('Silakan login untuk melihat profil Anda.'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(radius: 36, backgroundImage: (user.avatar ?? '').isNotEmpty ? NetworkImage(user.avatar!) : null, child: (user.avatar ?? '').isEmpty ? const Icon(Icons.person, size: 36) : null),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            if (auth.isDevMode || AppConfig.devBypassLogin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(16)),
                child: const Text('Testing Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        Text(user.email),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splash, (route) => false);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}
