import 'package:flutter/material.dart';

import '../features/auth/state/auth_controller.dart';
import 'app_router.dart';

class MuulApp extends StatefulWidget {
  const MuulApp({super.key, required this.authController});

  final AuthController authController;

  @override
  State<MuulApp> createState() => _MuulAppState();
}

class _MuulAppState extends State<MuulApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(widget.authController);
    widget.authController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Muul',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D99FF)),
      ),
      routerConfig: _appRouter.router,
    );
  }
}
