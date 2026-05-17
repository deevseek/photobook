import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Silakan login untuk melihat profil Anda.'));
    return ListView(padding: const EdgeInsets.all(16), children: [
      CircleAvatar(radius: 36, backgroundImage: (user.avatar ?? '').isNotEmpty ? NetworkImage(user.avatar!) : null, child: (user.avatar ?? '').isEmpty ? const Icon(Icons.person, size: 36) : null),
      const SizedBox(height: 12),
      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(user.email),
    ]);
  }
}
