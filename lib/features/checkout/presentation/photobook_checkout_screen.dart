import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/design_schema_model.dart';
import '../../../data/models/photobook_design_model.dart';
import '../../../data/models/photobook_product_model.dart';
import '../../../data/models/shipping_rate_model.dart';
import '../../../data/repositories/photobook_repository.dart';
import '../../editor/presentation/photobook_editor_screen.dart';

class PhotobookCheckoutScreen extends StatefulWidget {
  const PhotobookCheckoutScreen({
    super.key,
    required this.design,
    required this.productId,
    required this.schema,
    required this.photoStateByFrameId,
    required this.editedTextById,
  });

  final PhotobookDesignModel design;
  final int productId;
  final DesignSchemaModel schema;
  final Map<String, FramePhotoState> photoStateByFrameId;
  final Map<String, String> editedTextById;

  @override
  State<PhotobookCheckoutScreen> createState() => _PhotobookCheckoutScreenState();
}

class _PhotobookCheckoutScreenState extends State<PhotobookCheckoutScreen> {
  final _repo = PhotobookRepository();

  int printQuantity = 1;
  ShippingRateModel? selectedShippingRate;
  bool isCheckingShipping = false;
  bool isCreatingPayment = false;

  final recipientNameController = TextEditingController();
  final phoneController = TextEditingController();
  final provinceController = TextEditingController();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final postalCodeController = TextEditingController();
  final addressController = TextEditingController();

  PhotobookProductModel? _product;
  bool _isLoadingProduct = true;
  List<ShippingRateModel> _shippingRates = [];

  int get pageCount => widget.schema.pages.length;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    recipientNameController.dispose();
    phoneController.dispose();
    provinceController.dispose();
    cityController.dispose();
    districtController.dispose();
    postalCodeController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final detail = await _repo.getProductDetail(widget.productId);
      setState(() => _product = detail);
    } catch (e) {
      _showSnackbar('Gagal memuat produk: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final product = _product;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout PhotoBook')),
        body: const Center(child: Text('Produk tidak tersedia.')),
      );
    }

    final basePrice = product.basePrice.toInt();
    final designPrice = widget.design.designPrice.toInt();
    final defaultPages = product.defaultPages;
    final additionalPagePrice = product.additionalPagePrice.toInt();

    final extraPages = math.max(0, pageCount - defaultPages);
    final printSubtotal = (basePrice + (extraPages * additionalPagePrice)) * printQuantity;
    final shippingCost = selectedShippingRate?.cost ?? 0;
    final grandTotal = printSubtotal + designPrice + shippingCost;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout PhotoBook')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(product, basePrice, additionalPagePrice, extraPages, printSubtotal),
          const SizedBox(height: 12),
          _buildAddressCard(),
          const SizedBox(height: 12),
          _buildShippingCard(product),
          const SizedBox(height: 12),
          _buildTotalCard(printSubtotal, designPrice, shippingCost, grandTotal),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final reason = _payDisableReason();
              if (reason != null) _showSnackbar(reason);
            },
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _payDisableReason() == null
                    ? () => _createOrderAndPay(
                          product: product,
                          printSubtotal: printSubtotal,
                          designPrice: designPrice,
                          grandTotal: grandTotal,
                        )
                    : null,
                child: isCreatingPayment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Bayar Sekarang'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PhotobookProductModel product, int basePrice, int additionalPagePrice, int extraPages, int printSubtotal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ringkasan Order', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _kv('Produk', product.name),
          _kv('Desain', widget.design.title),
          _kv('Halaman', '$pageCount'),
          _kv('Jumlah cetak', '$printQuantity'),
          _kv('Harga dasar cetak', _idr(basePrice)),
          _kv('Harga tambahan halaman', '${_idr(additionalPagePrice)} x $extraPages'),
          _kv('Harga desain', _idr(widget.design.designPrice.toInt())),
          const Divider(),
          _kv('Subtotal cetak', _idr(printSubtotal)),
        ]),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _input(recipientNameController, 'Nama penerima'),
          _input(phoneController, 'No HP', keyboardType: TextInputType.phone),
          _input(provinceController, 'Provinsi'),
          _input(cityController, 'Kota/Kabupaten'),
          _input(districtController, 'Kecamatan'),
          _input(postalCodeController, 'Kode pos', keyboardType: TextInputType.number),
          _input(addressController, 'Alamat lengkap', maxLines: 3),
        ]),
      ),
    );
  }

  Widget _buildShippingCard(PhotobookProductModel product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pengiriman (JNT)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isCheckingShipping ? null : () => _checkShipping(product),
            child: isCheckingShipping ? const Text('Memproses...') : const Text('Cek Ongkir JNT'),
          ),
          if (_shippingRates.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._shippingRates.map((rate) => RadioListTile<ShippingRateModel>(
                  contentPadding: EdgeInsets.zero,
                  value: rate,
                  groupValue: selectedShippingRate,
                  onChanged: (v) => setState(() => selectedShippingRate = v),
                  title: Text('${rate.service} - ${rate.serviceName}'),
                  subtitle: Text('Estimasi ${rate.estimatedDays}'),
                  secondary: Text(_idr(rate.cost)),
                )),
          ],
        ]),
      ),
    );
  }

  Widget _buildTotalCard(int printSubtotal, int designPrice, int shippingCost, int grandTotal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _kv('Subtotal cetak', _idr(printSubtotal)),
          _kv('Harga desain', _idr(designPrice)),
          _kv('Ongkir', _idr(shippingCost)),
          const Divider(),
          _kv('Total bayar', _idr(grandTotal), isBold: true),
        ]),
      ),
    );
  }

  Future<void> _checkShipping(PhotobookProductModel product) async {
    if (!_isAddressComplete()) {
      _showSnackbar('Lengkapi alamat dulu sebelum cek ongkir.');
      return;
    }

    setState(() => isCheckingShipping = true);
    try {
      final rates = await _repo.getShippingRates({
        'destination': {
          'recipient_name': recipientNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'province': provinceController.text.trim(),
          'city': cityController.text.trim(),
          'district': districtController.text.trim(),
          'postal_code': postalCodeController.text.trim(),
          'address': addressController.text.trim(),
        },
        'items': [
          {
            'product_id': product.id,
            'quantity': printQuantity,
            'weight': 1000,
          }
        ]
      });
      setState(() {
        _shippingRates = rates;
        selectedShippingRate = rates.isNotEmpty ? rates.first : null;
      });
      if (rates.isEmpty) _showSnackbar('Layanan pengiriman tidak tersedia.');
    } catch (e) {
      _showSnackbar('Cek ongkir gagal: $e');
    } finally {
      if (mounted) setState(() => isCheckingShipping = false);
    }
  }

  Future<void> _createOrderAndPay({required PhotobookProductModel product, required int printSubtotal, required int designPrice, required int grandTotal}) async {
    final rate = selectedShippingRate;
    if (rate == null) return;

    setState(() => isCreatingPayment = true);
    try {
      final order = await _repo.createOrder({
        'product_id': product.id,
        'contributor_design_id': widget.design.id,
        'page_count': pageCount,
        'print_quantity': printQuantity,
        'recipient_name': recipientNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'shipping_address': addressController.text.trim(),
        'shipping_province': provinceController.text.trim(),
        'shipping_city': cityController.text.trim(),
        'shipping_district': districtController.text.trim(),
        'shipping_postal_code': postalCodeController.text.trim(),
        'shipping_courier': rate.courier,
        'shipping_service': rate.service,
        'shipping_cost': rate.cost,
        'shipping_etd': rate.estimatedDays,
        'subtotal_amount': printSubtotal,
        'design_price': designPrice,
        'total_amount': grandTotal,
      });

      await _repo.saveProject(order.orderNumber, _buildProjectJson(product));

      final payment = await _repo.createPayment(order.orderNumber, requirePrintFileReady: true);
      final redirectUrl = payment.redirectUrl;
      if (redirectUrl == null || redirectUrl.isEmpty) {
        _showSnackbar('Payment berhasil dibuat, tapi redirect URL tidak tersedia.');
        return;
      }

      final launched = await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSnackbar('Tidak bisa membuka halaman pembayaran.');
        return;
      }

      _showSnackbar('Menunggu konfirmasi pembayaran dari server...');
      final updatedOrder = await _pollPaidStatus(order.orderNumber);
      if (!mounted) return;
      if (updatedOrder != null && updatedOrder.paymentStatus.toLowerCase() == 'paid') {
        _showSnackbar('Pembayaran terkonfirmasi. Pesanan masuk proses produksi.');
      } else {
        _showSnackbar('Pembayaran belum terkonfirmasi. Silakan cek detail pesanan atau coba lagi beberapa saat.');
      }
    } catch (e) {
      _showSnackbar('Proses pembayaran gagal: $e');
    } finally {
      if (mounted) setState(() => isCreatingPayment = false);
    }
  }

  Future<dynamic> _pollPaidStatus(String orderNumber) async {
    const totalAttempts = 24; // 24 x 5 detik = 2 menit
    for (var i = 0; i < totalAttempts; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final order = await _repo.getOrderDetail(orderNumber);
        final status = order.paymentStatus.toLowerCase();
        if (status == 'paid' || status == 'failed' || status == 'cancel' || status == 'expire') {
          return order;
        }
      } catch (_) {
        // Abaikan error sementara saat polling dan lanjutkan retry.
      }
    }

    return null;
  }

  Map<String, dynamic> _buildProjectJson(PhotobookProductModel product) {
    return {
      'product_id': product.id,
      'design_id': widget.design.id,
      'design_schema_source': widget.design.designSchemaSource ?? 'idml_package',
      'page_count': pageCount,
      'print_quantity': printQuantity,
      'pages': widget.schema.pages.map((page) {
        return {
          'page_number': page.pageNumber,
          'background_url': page.editorBackgroundUrl ?? page.cleanBackgroundUrl ?? page.backgroundUrl ?? page.previewUrl,
          'frames': page.frames.map((frame) {
            final state = widget.photoStateByFrameId[frame.id];
            return {
              'frame_id': frame.id,
              'photo_file_name': state?.fileName,
              'photo_attached': state != null,
              'photo_url': null,
              'crop': {
                'fit': 'cover',
                'scale': state?.scale ?? 1,
                'offset_x': state?.offset.dx ?? 0,
                'offset_y': state?.offset.dy ?? 0,
                'rotation': state?.rotation ?? 0,
              }
            };
          }).toList(),
        };
      }).toList(),
      'texts': widget.schema.pages
          .expand((page) => page.effectiveTextLayers.map((textLayer) => (page: page, textLayer: textLayer)))
          .map((entry) {
            final page = entry.page;
            final textLayer = entry.textLayer;
            return {
              'id': textLayer.id,
              'source_story': textLayer.sourceStory,
              'source_object_id': textLayer.sourceObjectId,
              'page_number': page.pageNumber,
              'text': widget.editedTextById[textLayer.id] ?? textLayer.text,
            };
          })
          .toList(),
    };
  }

  String? _payDisableReason() {
    if (!_isAddressComplete()) return 'Alamat pengiriman belum lengkap.';
    if (selectedShippingRate == null) return 'Silakan cek ongkir dan pilih layanan pengiriman.';
    if (isCreatingPayment) return 'Order sedang diproses.';
    return null;
  }

  bool _isAddressComplete() {
    final values = [
      recipientNameController.text,
      phoneController.text,
      provinceController.text,
      cityController.text,
      districtController.text,
      postalCodeController.text,
      addressController.text,
    ];
    return values.every((v) => v.trim().isNotEmpty);
  }

  Widget _input(TextEditingController c, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _kv(String key, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(key)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }

  String _idr(int value) => 'Rp ${value.toString()}';

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
