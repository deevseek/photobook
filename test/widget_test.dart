import 'package:flutter_test/flutter_test.dart';
import 'package:photobook/main.dart';

void main() {
  testWidgets('Splash screen title appears', (tester) async {
    await tester.pumpWidget(const PhotoBookApp());
    expect(find.text('PhotoBook Profesional Servis'), findsOneWidget);
  });
}
