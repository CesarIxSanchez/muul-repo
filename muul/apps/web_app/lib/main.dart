import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:services/services.dart';

import 'app/app.dart';
import 'features/auth/state/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authRepository = LocalAuthRepository();
  final authService = AuthService(authRepository);
  final authController = AuthController(authService);

  runApp(MuulApp(authController: authController));
}
