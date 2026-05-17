import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const PhotoBookApp());
}

class BrandColors {
  static const navy = Color(0xFF0A2540);
  static const electricBlue = Color(0xFF1976FF);
  static const white = Colors.white;
  static const lightGray = Color(0xFFF3F6FA);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

class PhotoBookApp extends StatelessWidget {
  const PhotoBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhotoBook Profesional Servis',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BrandColors.lightGray,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.electricBlue,
          primary: BrandColors.electricBlue,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [BrandColors.navy, BrandColors.electricBlue]),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 42, backgroundColor: Colors.white, child: Icon(Icons.photo_album, color: BrandColors.navy, size: 44)),
              SizedBox(height: 16),
              Text('PhotoBook Profesional Servis', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  final slides = const ['Buat PhotoBook dari HP', 'Pilih Desain, Masukkan Foto', 'Cetak dan Kirim ke Rumah'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              onPageChanged: (v) => setState(() => page = v),
              itemCount: slides.length,
              itemBuilder: (_, i) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.collections_bookmark, size: 120, color: BrandColors.electricBlue),
                    const SizedBox(height: 24),
                    Text(slides[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              TextButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), child: const Text('Lewati')),
              const Spacer(),
              AppButton(
                label: page == 2 ? 'Mulai Sekarang' : 'Lanjut',
                onPressed: () {
                  if (page < 2) {
                    controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                  } else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                },
              ),
            ]),
          )
        ],
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.photo_camera_back_rounded, size: 120, color: BrandColors.navy),
            const SizedBox(height: 20),
            const Text('Masuk untuk mulai membuat PhotoBook', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            AppButton(label: 'Masuk dengan Gmail', icon: Icons.g_mobiledata, onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()))),
            const SizedBox(height: 12),
            const Text('Data Anda digunakan untuk menyimpan pesanan PhotoBook.', textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [HomeScreen(), ProductScreen(), OrdersScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen())), label: const Text('Buat PhotoBook')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Produk'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        onDestinationSelected: (v) => setState(() => index = v),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget { const HomeScreen({super.key}); @override Widget build(BuildContext context) => const GenericListScreen(title: 'Home', sections: ['Produk PhotoBook', 'Desain Populer', 'Pesanan Terakhir']); }
class ProductScreen extends StatelessWidget { const ProductScreen({super.key}); @override Widget build(BuildContext context) => const GenericListScreen(title: 'Produk PhotoBook', sections: ['Search + Filter Kategori + Ukuran', 'ProductCard grid']); }
class OrdersScreen extends StatelessWidget { const OrdersScreen({super.key}); @override Widget build(BuildContext context) => const GenericListScreen(title: 'Pesanan Saya', sections: ['OrderCard list', 'Payment status', 'Production status', 'Shipping status']); }
class ProfileScreen extends StatelessWidget { const ProfileScreen({super.key}); @override Widget build(BuildContext context) => const GenericListScreen(title: 'Profil', sections: ['Avatar Gmail', 'Nama, Email, Nomor HP', 'Alamat default', 'Logout']); }

class GenericListScreen extends StatelessWidget {
  final String title;
  final List<String> sections;
  const GenericListScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: BrandColors.navy)),
          const SizedBox(height: 16),
          ...sections.map((s) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(title: Text(s), subtitle: const Text('Modern clean premium card style'), trailing: const Icon(Icons.arrow_forward_ios, size: 16)),
              )),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: const [StatusBadge('Sukses', BrandColors.success), StatusBadge('Pending', BrandColors.warning), StatusBadge('Error', BrandColors.error)]),
        ],
      ),
    );
  }
}

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor PhotoBook')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          StepperHeader(step: 'Pilih Foto → Atur Halaman → Preview → Checkout'),
          SizedBox(height: 12),
          PhotoFrameWidget(),
          SizedBox(height: 12),
          PageThumbnail(),
          SizedBox(height: 12),
          UploadProgressModal.preview(),
          SizedBox(height: 12),
          CheckoutSummary(),
        ],
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  const AppButton({super.key, required this.label, required this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) => FilledButton.icon(
        icon: Icon(icon ?? Icons.check_circle),
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: BrandColors.electricBlue, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        label: Text(label),
      );
}

class StatusBadge extends StatelessWidget { final String text; final Color color; const StatusBadge(this.text, this.color, {super.key}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))); }
class StepperHeader extends StatelessWidget { final String step; const StepperHeader({super.key, required this.step}); @override Widget build(BuildContext context) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(16), child: Text(step, style: const TextStyle(fontWeight: FontWeight.bold)))); }
class PhotoFrameWidget extends StatelessWidget { const PhotoFrameWidget({super.key}); @override Widget build(BuildContext context) => Container(height: 240, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text('Canvas + Frame dari design_schema\n(tap untuk pilih/crop/zoom/rotate)'))); }
class PageThumbnail extends StatelessWidget { const PageThumbnail({super.key}); @override Widget build(BuildContext context) => SizedBox(height: 80, child: ListView.separated(scrollDirection: Axis.horizontal, itemBuilder: (_, i) => Container(width: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Center(child: Text('P${i + 1}'))), separatorBuilder: (_, __) => const SizedBox(width: 8), itemCount: 6)); }
class UploadProgressModal extends StatelessWidget { const UploadProgressModal.preview({super.key}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Menyiapkan file cetak', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('• Validasi frame\n• Membuat PDF\n• Upload PDF\n• PDF siap cetak')]))); }
class CheckoutSummary extends StatelessWidget { const CheckoutSummary({super.key}); @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Checkout Summary', style: TextStyle(fontWeight: FontWeight.bold)), const Text('Produk, desain, ongkir JNT, total bayar, status PDF siap cetak.'), const SizedBox(height: 8), AppButton(label: 'Bayar Sekarang', onPressed: () {})]))); }

class ApiEndpoints {
  static const authGoogle = '/api/v1/photobook/auth/google';
  static const me = '/api/v1/photobook/auth/me';
  static const products = '/api/v1/photobook/products';
  static String productDetail(int id) => '/api/v1/photobook/products/$id';
  static String productDesigns(int id) => '/api/v1/photobook/products/$id/designs';
  static String designDetail(int id) => '/api/v1/photobook/designs/$id';
  static String downloadIdml(int id) => '/api/v1/photobook/designs/$id/download-idml';
  static const calculatePrice = '/api/v1/photobook/calculate-price';
  static const orders = '/api/v1/photobook/orders';
  static String saveProject(String orderNumber) => '/api/v1/photobook/orders/$orderNumber/save-project';
  static String uploadFinalPdf(String orderNumber) => '/api/v1/photobook/orders/$orderNumber/upload-final-pdf';
  static const shippingRates = '/api/v1/photobook/shipping/rates';
  static const paymentCreate = '/api/v1/photobook/payment/create';
  static String orderDetail(String orderNumber) => '/api/v1/photobook/orders/$orderNumber';
  static String tracking(String orderNumber) => '/api/v1/photobook/orders/$orderNumber/tracking';
}
