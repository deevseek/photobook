import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/repositories/photobook_repository.dart';

class DesignDetailScreen extends StatefulWidget {
  final int designId;
  final int productId;

  const DesignDetailScreen({
    super.key,
    required this.designId,
    required this.productId,
  });

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  final _repo = PhotobookRepository();
  late Future<PhotobookDesignModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.getDesignDetail(widget.designId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PhotobookAppBar(title: 'Design Detail'),
      body: FutureBuilder<PhotobookDesignModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _future = _repo.getDesignDetail(widget.designId);
                });
              },
            );
          }

          final d = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 220,
                      child: AppNetworkImage(
                        url: d.thumbnailUrl ?? '',
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      d.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('Designer: ${d.contributorName ?? '-'}'),
                    Text('Total halaman: ${d.totalPages}'),
                    PriceText(price: d.designPrice),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (d.idmlAvailable) const Chip(label: Text('IDML')),
                        if (d.designSchemaAvailable)
                          const Chip(label: Text('Schema')),
                        if (d.previewStatus == 'ready')
                          const Chip(label: Text('PDF Preview')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(d.description ?? ''),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.all(16),
                child: PrimaryButton(
                  label: 'Gunakan Desain Ini',
                  onPressed: d.designSchemaAvailable
                      ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.photobookEditor,
                            arguments: {
                              'productId': widget.productId,
                              'design': d,
                            },
                          )
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
