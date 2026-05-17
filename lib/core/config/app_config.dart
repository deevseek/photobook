class AppConfig {
  static const bool devBypassLogin = true;

  // Isi token customer test dari Laravel kalau endpoint membutuhkan Bearer token.
  // Kalau produk/desain public, boleh kosong dulu.
  static const String devCustomerToken = '';

  static const Map<String, dynamic> devCustomer = {
    'id': 1,
    'name': 'Test Customer PhotoBook',
    'email': 'photobook-test@example.com',
    'avatar': null,
    'phone': '081234567890',
  };
}
