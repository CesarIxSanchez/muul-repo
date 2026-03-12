import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services/services.dart';

import 'package:web_app/app/app.dart';
import 'package:web_app/features/auth/state/auth_controller.dart';

void main() {
  testWidgets('shows splash screen while loading auth state', (WidgetTester tester) async {
    final authController = AuthController(
      AuthService(LocalAuthRepository()),
    );

    await tester.pumpWidget(MuulApp(authController: authController));

    expect(find.text('Muul esta cargando...'), findsOneWidget);
  });
}
