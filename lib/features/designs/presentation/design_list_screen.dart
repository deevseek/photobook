import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../photobook/data/photobook_repository.dart';

class DesignListScreen extends StatefulWidget {
  final int productId;
  const DesignListScreen({super.key, required this.productId});

  @override
  State<DesignListScreen> createState() => _DesignListScreenState();
}

class _DesignListScreenState extends State<DesignListScreen> {
  final _repo = PhotobookRepository();
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getDesignsByProductId(widget.productId);
  }

  void _retry() => setState(() => _future = _repo.getDesignsByProductId(widget.productId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Desain')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          final items = snapshot.data as List;
          if (items.isEmpty) return const EmptyState(title: 'Desain kosong', subtitle: 'Belum ada desain untuk produk ini.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final d = items[i];
              return DesignCard(
                name: d.name,
                thumbnailUrl: d.thumbnailUrl,
                onTap: () => Navigator.pushNamed(context, AppRoutes.designDetail, arguments: d.id),
              );
            },
          );
        },
      ),
    );
  }
}
