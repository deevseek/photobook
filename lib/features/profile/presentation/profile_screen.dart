import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)), SizedBox(height: 12), Text('Nama Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text('email@contoh.com'), SizedBox(height: 20), ListTile(title: Text('Alamat'), subtitle: Text('TODO: Integrasi profil pengguna API')), ListTile(title: Text('Keluar'))]); }
