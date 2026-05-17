import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';

class DesignDetailScreen extends StatelessWidget { const DesignDetailScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Detail Desain')), body: ListView(padding: const EdgeInsets.all(16), children: [Container(height: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))), const SizedBox(height: 12), const Text('Desain Minimal Clean', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), AppButton(label: 'Gunakan Desain', onPressed: ()=>Navigator.pushNamed(context, AppRoutes.editorPlaceholder)), const Text('TODO: Integrasi preview schema desain') ])); }
