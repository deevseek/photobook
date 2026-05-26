import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class DesignListScreen extends StatefulWidget {
  final int productId;
  const DesignListScreen({super.key, required this.productId});

  @override
  State<DesignListScreen> createState() => _DesignListScreenState();
}

class _DesignListScreenState extends State<DesignListScreen> {
  final _repo = PhotobookRepository();
  late Future<List<PhotobookDesignModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getProductDesigns(widget.productId);
  }

  void _retry() => setState(() => _future = _repo.getProductDesigns(widget.productId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Desain')),
      body: FutureBuilder<List<PhotobookDesignModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(message: snapshot.error.toString(), onRetry: _retry);
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Desain kosong',
              subtitle: 'Belum ada desain untuk produk ini.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 410,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _DesignCard(design: items[i], productId: widget.productId),
          );
        },
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({required this.design, required this.productId});

  final PhotobookDesignModel design;
  final int productId;

  Future<void> _selectDesign(BuildContext context) async {
    debugPrint('BUTTON PILIH DESAIN CLICKED designId=${design.id}');
    debugPrint('Pilih desain tapped: ${design.id} - ${design.title}');

    if (design.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desain tidak valid')),
      );
      return;
    }

    if (!design.designSchemaAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template belum siap digunakan. Silakan pilih desain lain.')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.designDetail,
      arguments: {'designId': design.id, 'productId': productId, 'design': design},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: design.thumbnailUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 10),
            Text(design.title, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(design.contributorName, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${design.category} • ${design.theme}', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${design.size} • ${design.totalPages} halaman', maxLines: 1, overflow: TextOverflow.ellipsis),
            PriceText(price: design.designPrice),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: -8,
              children: [
                if (design.idmlAvailable) const Chip(label: Text('IDML tersedia')),
                Chip(label: Text(design.designSchemaAvailable ? 'Template siap' : 'Schema belum siap')),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF168CA0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _selectDesign(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Pilih Desain'),
              ),
            ),
            if (kDebugMode && !design.designSchemaAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Template belum siap digunakan.', style: TextStyle(fontSize: 12, color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }
}
