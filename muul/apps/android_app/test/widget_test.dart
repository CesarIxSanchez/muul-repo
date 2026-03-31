import 'package:flutter_test/flutter_test.dart';
import 'package:android_app/main.dart';

void main() {
  testWidgets('Muul smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MuulApp());
    expect(find.byType(MuulApp), findsOneWidget);
  });
}