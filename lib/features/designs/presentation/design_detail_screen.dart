import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../photobook/data/photobook_repository.dart';

class DesignDetailScreen extends StatefulWidget {
  final int designId;
  const DesignDetailScreen({super.key, required this.designId});

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  final _repo = PhotobookRepository();
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getDesignById(widget.designId);
  }

  void _retry() => setState(() => _future = _repo.getDesignById(widget.designId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Desain')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final design = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 220,
                  child: design.thumbnailUrl.isEmpty ? Container(color: Colors.white) : Image.network(design.thumbnailUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Text(design.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(design.description ?? '-'),
              const SizedBox(height: 12),
              AppButton(label: 'Gunakan Desain', onPressed: () => Navigator.pushNamed(context, AppRoutes.editorPlaceholder)),
            ],
          );
        },
      ),
    );
  }
}
