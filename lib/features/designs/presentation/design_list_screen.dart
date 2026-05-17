import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class DesignListScreen extends StatelessWidget { const DesignListScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Pilih Desain')), body: ListView(padding: const EdgeInsets.all(16), children: [DesignCard(name: 'Minimal Clean', onTap: ()=>Navigator.pushNamed(context, AppRoutes.designDetail)), DesignCard(name: 'Travel Story', onTap: ()=>Navigator.pushNamed(context, AppRoutes.designDetail)), const SizedBox(height: 12), const Text('TODO: Integrasi API daftar desain') ])); }
