import 'package:flutter/material.dart';

class EditorPlaceholderScreen extends StatelessWidget {
  final String designName;
  const EditorPlaceholderScreen({super.key, required this.designName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor PhotoBook')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(designName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Editor PhotoBook akan dibuat pada tahap berikutnya', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali')),
            ],
          ),
        ),
      ),
    );
  }
}
